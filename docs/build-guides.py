#!/usr/bin/env python3
"""Renders the guides in docs/*.md to PDF, so the PDFs never drift from the
markdown that is the actual source.

    python3 docs/build-guides.py
"""
import os
import re
import sys

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (BaseDocTemplate, Frame, HRFlowable, ListFlowable,
                                ListItem, PageBreak, PageTemplate, Paragraph,
                                Spacer, Table, TableStyle)

RED = colors.HexColor("#CC1F2C")
INK = colors.HexColor("#0f1117")
MUTED = colors.HexColor("#6b7280")
BORDER = colors.HexColor("#d1d5db")
SURFACE = colors.HexColor("#f8f9fa")

DOCS = os.path.dirname(os.path.abspath(__file__))


def styles():
    ss = getSampleStyleSheet()
    base = dict(fontName="Helvetica", textColor=INK, leading=14.5)
    return {
        "title": ParagraphStyle("t", parent=ss["Title"], fontName="Helvetica-Bold",
                                fontSize=24, leading=28, textColor=INK, spaceAfter=2,
                                alignment=TA_LEFT),
        "subtitle": ParagraphStyle("st", fontName="Helvetica", fontSize=10.5,
                                   textColor=MUTED, leading=15, spaceAfter=16),
        "h1": ParagraphStyle("h1", fontName="Helvetica-Bold", fontSize=15, leading=19,
                             textColor=INK, spaceBefore=20, spaceAfter=8),
        "h2": ParagraphStyle("h2", fontName="Helvetica-Bold", fontSize=12, leading=16,
                             textColor=INK, spaceBefore=14, spaceAfter=6),
        "h3": ParagraphStyle("h3", fontName="Helvetica-Bold", fontSize=10.5, leading=14,
                             textColor=MUTED, spaceBefore=10, spaceAfter=4),
        "body": ParagraphStyle("b", fontSize=9.8, spaceAfter=7, **base),
        "bullet": ParagraphStyle("bu", fontSize=9.8, spaceAfter=3, **base),
        "quote": ParagraphStyle("q", fontSize=9.3, leading=14, fontName="Helvetica",
                                textColor=colors.HexColor("#7c2d12"), leftIndent=9,
                                borderPadding=(7, 7, 7, 7), backColor=colors.HexColor("#fff7ed"),
                                spaceBefore=6, spaceAfter=9),
        "code": ParagraphStyle("c", fontName="Courier", fontSize=8.1, leading=11.4,
                               textColor=INK, backColor=SURFACE, leftIndent=7,
                               borderPadding=(7, 7, 7, 7), spaceBefore=5, spaceAfter=9),
        "cell": ParagraphStyle("cell", fontName="Helvetica", fontSize=8.5, leading=11.5,
                               textColor=INK),
        "cellh": ParagraphStyle("cellh", fontName="Helvetica-Bold", fontSize=8.5,
                                leading=11.5, textColor=INK),
    }


def inline(text):
    """Markdown inline -> reportlab markup. Escape first, then re-add tags."""
    text = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    text = re.sub(r"`([^`]+)`",
                  r'<font face="Courier" size="8.6" color="#1e3a5f">\1</font>', text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<i>\1</i>", text)
    return text


def split_row(line):
    return [c.strip() for c in line.strip().strip("|").split("|")]


def render(md, st):
    flow = []
    lines = md.split("\n")
    i = 0
    first_h1 = True

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # fenced code
        if stripped.startswith("```"):
            i += 1
            buf = []
            while i < len(lines) and not lines[i].strip().startswith("```"):
                buf.append(lines[i].replace("&", "&amp;").replace("<", "&lt;")
                           .replace(">", "&gt;").replace(" ", "&nbsp;"))
                i += 1
            i += 1
            flow.append(Paragraph("<br/>".join(buf) or "&nbsp;", st["code"]))
            continue

        # table
        if stripped.startswith("|") and i + 1 < len(lines) and \
                set(lines[i + 1].strip()) <= set("|-: "):
            header = split_row(stripped)
            i += 2
            rows = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                rows.append(split_row(lines[i]))
                i += 1
            data = [[Paragraph(inline(c), st["cellh"]) for c in header]] + \
                   [[Paragraph(inline(c), st["cell"]) for c in r] for r in rows]
            ncols = len(header)
            avail = 170 * mm
            first = avail * (0.34 if ncols > 2 else 0.4)
            widths = [first] + [(avail - first) / (ncols - 1)] * (ncols - 1) \
                if ncols > 1 else [avail]
            t = Table(data, colWidths=widths, repeatRows=1, hAlign="LEFT")
            t.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, 0), SURFACE),
                ("LINEBELOW", (0, 0), (-1, 0), 1, BORDER),
                ("LINEBELOW", (0, 1), (-1, -2), 0.4, colors.HexColor("#eceef1")),
                ("BOX", (0, 0), (-1, -1), 0.6, BORDER),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]))
            flow += [Spacer(1, 3), t, Spacer(1, 10)]
            continue

        # bullets / numbered
        if re.match(r"^\s*[-*]\s+", line) or re.match(r"^\s*\d+\.\s+", line):
            numbered = bool(re.match(r"^\s*\d+\.\s+", line))
            items = []
            # A wrapped bullet continues on an indented line; treat any indented
            # non-empty line as part of the item above rather than a new paragraph.
            while i < len(lines) and (re.match(r"^\s*[-*]\s+", lines[i])
                                      or re.match(r"^\s*\d+\.\s+", lines[i])
                                      or (items and lines[i].strip()
                                          and lines[i][:1].isspace())):
                cur = lines[i]
                if re.match(r"^\s*[-*]\s+", cur) or re.match(r"^\s*\d+\.\s+", cur):
                    items.append(re.sub(r"^\s*(?:[-*]|\d+\.)\s+", "", cur).strip())
                else:
                    items[-1] += " " + cur.strip()
                i += 1
            flow.append(ListFlowable(
                [ListItem(Paragraph(inline(x), st["bullet"]), leftIndent=14)
                 for x in items],
                bulletType="1" if numbered else "bullet",
                bulletFontSize=8, leftIndent=14, bulletColor=RED if not numbered else INK,
                start="1" if numbered else None))
            flow.append(Spacer(1, 5))
            continue

        # blockquote
        if stripped.startswith(">"):
            buf = []
            while i < len(lines) and lines[i].strip().startswith(">"):
                buf.append(lines[i].strip().lstrip(">").strip())
                i += 1
            flow.append(Paragraph(inline(" ".join(b for b in buf if b)), st["quote"]))
            continue

        # rule
        if stripped in ("---", "***", "___"):
            flow.append(Spacer(1, 3))
            flow.append(HRFlowable(width="100%", thickness=0.6, color=BORDER,
                                   spaceBefore=2, spaceAfter=8))
            i += 1
            continue

        # headings
        m = re.match(r"^(#{1,4})\s+(.*)$", stripped)
        if m:
            level, text = len(m.group(1)), m.group(2)
            if level == 1 and first_h1:
                first_h1 = False
                flow.append(Paragraph(inline(text), st["title"]))
                # the italic line straight after the title is the subtitle
                if i + 2 < len(lines) and lines[i + 2].strip():
                    flow.append(Paragraph(inline(lines[i + 2].strip()), st["subtitle"]))
                    i += 2
            else:
                flow.append(Paragraph(inline(text), st[f"h{min(level, 3)}"]))
            i += 1
            continue

        if not stripped:
            i += 1
            continue

        # paragraph
        buf = []
        while i < len(lines) and lines[i].strip() and \
                not re.match(r"^\s*(#{1,4}\s|[-*]\s|\d+\.\s|>|\||```)", lines[i]) and \
                lines[i].strip() not in ("---", "***", "___"):
            buf.append(lines[i].strip())
            i += 1
        if buf:
            flow.append(Paragraph(inline(" ".join(buf)), st["body"]))

    return flow


def build(md_path, pdf_path, footer):
    st = styles()
    with open(md_path, encoding="utf-8") as f:
        md = f.read()

    doc = BaseDocTemplate(pdf_path, pagesize=A4,
                          leftMargin=20 * mm, rightMargin=20 * mm,
                          topMargin=18 * mm, bottomMargin=18 * mm,
                          title=footer, author="Rittal")

    def decorate(canvas, d):
        canvas.saveState()
        # Rittal stripe mark, top right
        x, y = A4[0] - 20 * mm, A4[1] - 12 * mm
        for w, col in ((7, "#CC1F2C"), (5.4, "#9B1E8E"), (3.8, "#0066B2"), (2.8, "#00A651")):
            canvas.setFillColor(colors.HexColor(col))
            canvas.rect(x - w * mm, y, w * mm, 1.1 * mm, stroke=0, fill=1)
            y -= 1.9 * mm
        canvas.setFont("Helvetica", 7.5)
        canvas.setFillColor(MUTED)
        canvas.drawString(20 * mm, 11 * mm, footer)
        canvas.drawRightString(A4[0] - 20 * mm, 11 * mm, str(d.page))
        canvas.setStrokeColor(BORDER)
        canvas.setLineWidth(0.4)
        canvas.line(20 * mm, 14 * mm, A4[0] - 20 * mm, 14 * mm)
        canvas.restoreState()

    frame = Frame(20 * mm, 18 * mm, A4[0] - 40 * mm, A4[1] - 36 * mm, id="f")
    doc.addPageTemplates([PageTemplate(id="p", frames=[frame], onPage=decorate)])
    doc.build(render(md, st))
    print(f"{pdf_path}  ({os.path.getsize(pdf_path) // 1024} KB)")


if __name__ == "__main__":
    build(os.path.join(DOCS, "UserGuide.md"),
          os.path.join(DOCS, "SAS-User-Guide.pdf"),
          "Support Audit System — User Guide")
    build(os.path.join(DOCS, "DeveloperGuide.md"),
          os.path.join(DOCS, "SAS-Developer-Guide.pdf"),
          "Support Audit System — Developer Guide")
