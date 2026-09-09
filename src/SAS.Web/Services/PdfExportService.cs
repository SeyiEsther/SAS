using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using SAS.Web.Models;

namespace SAS.Web.Services;

public class PdfExportService
{
    public byte[] Export(ChecklistSubmission submission, TaskList taskList, List<TaskItem> items, Area area, Shift shift, Department department)
    {
        var (answered, total) = ChecklistService.ComputeProgress(items, submission);
        var issueCount = ChecklistService.CountIssues(items, submission);

        var document = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(28);
                page.DefaultTextStyle(x => x.FontSize(9));

                page.Header().Column(col =>
                {
                    col.Item().Row(row =>
                    {
                        row.RelativeItem().Column(c =>
                        {
                            c.Item().Text("RITTAL — Support Audit System").FontSize(14).Bold();
                            c.Item().Text("Safe Start Checklist — SHEF014").FontSize(9).FontColor(Colors.Grey.Darken1);
                        });
                        row.ConstantItem(160).AlignRight().Column(c =>
                        {
                            c.Item().Text($"{department.Name} — {area.Name}").Bold();
                            c.Item().Text($"{shift.Name}");
                            c.Item().Text($"{submission.ChecklistDate:dddd dd MMM yyyy}");
                        });
                    });
                    col.Item().PaddingTop(6).LineHorizontal(1).LineColor(Colors.Grey.Lighten1);
                });

                page.Content().PaddingTop(10).Column(col =>
                {
                    col.Item().Row(row =>
                    {
                        row.RelativeItem().Text($"Auditor(s): {submission.AuditorNames}");
                        row.RelativeItem().AlignRight().Text($"Location: {submission.Location}");
                    });
                    col.Item().PaddingTop(2).Row(row =>
                    {
                        row.RelativeItem().Text($"Completed: {(submission.CompletedAt.HasValue ? submission.CompletedAt.Value.ToLocalTime().ToString("g") : "In progress")}");
                        row.RelativeItem().AlignRight().Text($"Signed off by: {submission.CompletedBy ?? "—"}");
                    });
                    col.Item().PaddingTop(2).Text($"Progress: {answered} of {total} answered — {issueCount} issue(s) raised").FontColor(issueCount > 0 ? Colors.Red.Medium : Colors.Green.Darken1).Bold();

                    col.Item().PaddingTop(10).Table(table =>
                    {
                        table.ColumnsDefinition(c =>
                        {
                            c.RelativeColumn(4);
                            c.ConstantColumn(60);
                            c.RelativeColumn(3);
                        });

                        table.Header(header =>
                        {
                            header.Cell().Element(HeaderCell).Text("Task");
                            header.Cell().Element(HeaderCell).Text("Status");
                            header.Cell().Element(HeaderCell).Text("Notes");
                        });

                        string? currentCategory = null;
                        foreach (var item in items.OrderBy(i => i.Category).ThenBy(i => i.SortOrder))
                        {
                            if (item.Category != currentCategory)
                            {
                                currentCategory = item.Category;
                                if (currentCategory is not null)
                                {
                                    table.Cell().ColumnSpan(3).Background(Colors.Grey.Darken3)
                                        .Padding(4).Text(currentCategory).FontColor(Colors.White).Bold();
                                }
                            }

                            var response = submission.TaskResponses.FirstOrDefault(r => r.TaskItemId == item.Id);

                            if (item.IsTimeBoxed && item.Checkpoints.Count > 0)
                            {
                                var summary = string.Join("  ", item.Checkpoints.OrderBy(c => c.SortOrder).Select(cp =>
                                {
                                    var cr = response?.CheckpointResponses.FirstOrDefault(x => x.TaskCheckpointId == cp.Id);
                                    return $"{cp.Label}:{cr?.Status ?? "-"}";
                                }));
                                table.Cell().Element(BodyCell).Text(item.Text);
                                table.Cell().Element(BodyCell).Text(summary).FontSize(7);
                                table.Cell().Element(BodyCell).Text(response?.Notes ?? "");
                            }
                            else
                            {
                                table.Cell().Element(BodyCell).Text(item.Text);
                                table.Cell().Element(BodyCell).Text(response?.Status ?? "—")
                                    .FontColor(response?.Status == ResponseStatus.Issue ? Colors.Red.Medium : Colors.Green.Darken1).Bold();
                                table.Cell().Element(BodyCell).Text(response?.Notes ?? "");
                            }
                        }
                    });
                });

                page.Footer().AlignCenter().Text(x =>
                {
                    x.Span("Generated ").FontSize(7);
                    x.Span(DateTime.Now.ToString("g")).FontSize(7);
                    x.Span(" — page ").FontSize(7);
                    x.CurrentPageNumber().FontSize(7);
                    x.Span(" of ").FontSize(7);
                    x.TotalPages().FontSize(7);
                });
            });
        });

        return document.GeneratePdf();
    }

    private static IContainer HeaderCell(IContainer container) =>
        container.Background(Colors.Grey.Lighten3).Padding(4).DefaultTextStyle(x => x.Bold());

    private static IContainer BodyCell(IContainer container) =>
        container.BorderBottom(1).BorderColor(Colors.Grey.Lighten2).Padding(4);
}
