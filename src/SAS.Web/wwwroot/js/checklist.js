(function () {
    var root = document.querySelector('[data-checklist-root]');
    if (!root) return;

    var readOnly = root.dataset.readonly === '1';
    var submissionId = parseInt(root.dataset.submissionId, 10);
    var tokenInput = document.querySelector('input[name="__RequestVerificationToken"]');
    var token = tokenInput ? tokenInput.value : '';

    var urls = {
        task: root.dataset.saveTaskUrl,
        checkpoint: root.dataset.saveCheckpointUrl,
        notes: root.dataset.saveNotesUrl,
        meta: root.dataset.saveMetaUrl,
        complete: root.dataset.completeUrl
    };

    var answered = {};
    var total = parseInt(root.dataset.total, 10) || 0;
    root.querySelectorAll('[data-item]').forEach(function (el) {
        answered[el.dataset.itemId] = el.dataset.itemAnswered === '1';
    });

    function actorName() {
        var el = document.getElementById('auditorNames');
        return (el && el.value.trim()) || 'Unknown';
    }

    function post(url, body) {
        return fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': token
            },
            body: JSON.stringify(body)
        }).then(function (res) {
            if (!res.ok) {
                return res.json().catch(function () { return {}; }).then(function (data) {
                    throw new Error(data.error || 'Save failed.');
                });
            }
            return res.json();
        });
    }

    function markAnswered(itemEl, isAnswered) {
        answered[itemEl.dataset.itemId] = isAnswered;
        itemEl.classList.toggle('is-answered', isAnswered);
        var tick = itemEl.querySelector('[data-task-tick]');
        if (tick) tick.textContent = isAnswered ? '\u2713' : '';
        updateProgress();
    }

    function updateProgress() {
        var count = 0;
        for (var k in answered) { if (answered[k]) count++; }
        var text = document.getElementById('progress-text');
        var fill = document.getElementById('progress-fill');
        if (text) text.textContent = count + ' of ' + total;
        if (fill) fill.style.width = (total === 0 ? 0 : Math.round(count * 100 / total)) + '%';
    }

    function setSaveState(itemEl, state, message) {
        var el = itemEl.querySelector('[data-save-state]');
        if (!el) return;
        el.className = 'save-state' + (state ? ' ' + state : '');
        el.textContent = message || '';
        if (state === 'saved') {
            setTimeout(function () { if (el.textContent === message) el.textContent = ''; }, 1500);
        }
    }

    function findNoteBlock(itemEl) {
        var inline = itemEl.querySelector('[data-note-block]');
        if (inline) return inline.querySelector('textarea');
        var next = itemEl.nextElementSibling;
        if (next && next.hasAttribute('data-note-row')) {
            return next.querySelector('textarea');
        }
        return null;
    }

    function showNoteBlock(itemEl, show) {
        var inline = itemEl.querySelector('[data-note-block]');
        if (inline) inline.style.display = show ? 'block' : 'none';
    }

    root.querySelectorAll('[data-item][data-timeboxed="0"]').forEach(function (itemEl) {
        var itemId = parseInt(itemEl.dataset.itemId, 10);
        var buttons = itemEl.querySelectorAll('.task-actions button, .wide-toggle button');

        buttons.forEach(function (btn) {
            btn.addEventListener('click', function () {
                if (readOnly) return;
                var status = btn.dataset.action;
                var isIssue = status === 'Issue';

                buttons.forEach(function (b) { b.classList.remove('active'); });
                btn.classList.add('active');
                showNoteBlock(itemEl, isIssue);

                var textarea = findNoteBlock(itemEl);
                var notes = textarea ? textarea.value.trim() : '';

                if (isIssue && !notes) {
                    setSaveState(itemEl, 'pending', 'Add notes to save this Issue.');
                    markAnswered(itemEl, false);
                    if (textarea) textarea.focus();
                    return;
                }

                setSaveState(itemEl, 'pending', 'Saving…');
                post(urls.task, { submissionId: submissionId, itemId: itemId, status: status, notes: notes || null, actor: actorName() })
                    .then(function () {
                        setSaveState(itemEl, 'saved', 'Saved');
                        markAnswered(itemEl, true);
                    })
                    .catch(function (err) { setSaveState(itemEl, 'pending', err.message); });
            });
        });

        var textarea = findNoteBlock(itemEl);
        if (textarea) {
            var debounce;
            textarea.addEventListener('input', function () {
                clearTimeout(debounce);
                debounce = setTimeout(function () {
                    var notes = textarea.value.trim();
                    var activeBtn = itemEl.querySelector('.task-actions button.active, .wide-toggle button.active');
                    var status = activeBtn ? activeBtn.dataset.action : 'Issue';
                    if (status === 'Issue' && !notes) {
                        setSaveState(itemEl, 'pending', 'Notes are required for an Issue.');
                        markAnswered(itemEl, false);
                        return;
                    }
                    setSaveState(itemEl, 'pending', 'Saving…');
                    post(urls.task, { submissionId: submissionId, itemId: itemId, status: status, notes: notes, actor: actorName() })
                        .then(function () {
                            setSaveState(itemEl, 'saved', 'Saved');
                            markAnswered(itemEl, true);
                        })
                        .catch(function (err) { setSaveState(itemEl, 'pending', err.message); });
                }, 500);
            });
        }
    });

    root.querySelectorAll('[data-item][data-timeboxed="1"]').forEach(function (itemEl) {
        var itemId = parseInt(itemEl.dataset.itemId, 10);
        var checkpointCells = itemEl.querySelectorAll('[data-checkpoint-id]');

        function anyIssue() {
            var issue = false;
            checkpointCells.forEach(function (cell) {
                if (cell.querySelector('.active-issue, button.n.active')) issue = true;
            });
            return issue;
        }

        function allAnswered() {
            var ok = true;
            checkpointCells.forEach(function (cell) {
                if (!cell.querySelector('.active, .active-issue, .active-done')) ok = false;
            });
            return ok;
        }

        checkpointCells.forEach(function (cell) {
            var checkpointId = parseInt(cell.dataset.checkpointId, 10);
            var buttons = cell.querySelectorAll('button');
            buttons.forEach(function (btn) {
                btn.addEventListener('click', function () {
                    if (readOnly) return;
                    var status = btn.dataset.action;

                    buttons.forEach(function (b) {
                        b.classList.remove('active', 'active-done', 'active-issue');
                    });
                    if (btn.classList.contains('cp-btn')) {
                        btn.classList.add(status === 'Done' ? 'active-done' : 'active-issue');
                    } else {
                        btn.classList.add('active');
                    }

                    showNoteBlock(itemEl, anyIssue());

                    setSaveState(itemEl, 'pending', 'Saving…');
                    post(urls.checkpoint, { submissionId: submissionId, itemId: itemId, checkpointId: checkpointId, status: status, actor: actorName() })
                        .then(function () {
                            setSaveState(itemEl, 'saved', 'Saved');
                            markAnswered(itemEl, allAnswered());
                        })
                        .catch(function (err) { setSaveState(itemEl, 'pending', err.message); });
                });
            });
        });

        var textarea = findNoteBlock(itemEl);
        if (textarea) {
            var debounce;
            textarea.addEventListener('input', function () {
                clearTimeout(debounce);
                debounce = setTimeout(function () {
                    post(urls.notes, { submissionId: submissionId, itemId: itemId, notes: textarea.value.trim(), actor: actorName() })
                        .then(function () { setSaveState(itemEl, 'saved', 'Notes saved'); })
                        .catch(function (err) { setSaveState(itemEl, 'pending', err.message); });
                }, 500);
            });
        }
    });

    updateProgress();

    ['auditorNames', 'location'].forEach(function (id) {
        var el = document.getElementById(id);
        if (!el || readOnly) return;
        var debounce;
        el.addEventListener('input', function () {
            clearTimeout(debounce);
            debounce = setTimeout(function () {
                post(urls.meta, {
                    submissionId: submissionId,
                    auditorNames: document.getElementById('auditorNames').value,
                    location: document.getElementById('location').value,
                    actor: actorName()
                }).catch(function () {});
            }, 600);
        });
    });

    var completeBtn = document.getElementById('complete-btn');
    if (completeBtn) {
        completeBtn.addEventListener('click', function () {
            var completedByEl = document.getElementById('completedBy');
            var completedBy = completedByEl ? completedByEl.value.trim() : '';
            if (!completedBy) {
                alert('Enter the HOD who is signing off this checklist before completing it.');
                if (completedByEl) completedByEl.focus();
                return;
            }
            completeBtn.disabled = true;
            completeBtn.textContent = 'Completing…';
            post(urls.complete, { submissionId: submissionId, completedBy: completedBy })
                .then(function () {
                    window.location.reload();
                })
                .catch(function (err) {
                    alert(err.message);
                    completeBtn.disabled = false;
                    completeBtn.textContent = 'Complete checklist';
                });
        });
    }
})();
