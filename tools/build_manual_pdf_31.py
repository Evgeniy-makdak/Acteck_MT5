#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Сборка краткого руководства ASmart 3.1 (RU).

Карточка у графика: UserGuide_ASmart_3.1_RU.txt
Для 2.14: ASmart_2.14_Manual_RU.pdf + UserGuide_Snayper_Pricel_EA_RU.txt
"""

from pathlib import Path

from reportlab.lib.colors import HexColor, white
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    ListFlowable,
    ListItem,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

ROOT = Path(__file__).resolve().parents[1]
FONT_REG = "/System/Library/Fonts/Supplemental/Arial Unicode.ttf"
pdfmetrics.registerFont(TTFont("ArialU", FONT_REG))

NAVY = HexColor("#1B3A4B")
TEAL = HexColor("#2A6F7F")
GOLD = HexColor("#C4A35A")
INK = HexColor("#222222")
MUTED = HexColor("#555555")
BG_ROW = HexColor("#F4F1EA")
LINE = HexColor("#D9D2C5")


def style_sheet():
    ss = getSampleStyleSheet()
    ss.add(ParagraphStyle(
        "H1", fontName="ArialU", fontSize=14, leading=18,
        textColor=NAVY, spaceBefore=14, spaceAfter=8,
    ))
    ss.add(ParagraphStyle(
        "Body", fontName="ArialU", fontSize=9.5, leading=13.2,
        textColor=INK, alignment=TA_JUSTIFY, spaceAfter=6,
    ))
    ss.add(ParagraphStyle(
        "BulletBody", fontName="ArialU", fontSize=9.5, leading=13.1,
        textColor=INK, leftIndent=2, spaceAfter=2,
    ))
    ss.add(ParagraphStyle(
        "Cell", fontName="ArialU", fontSize=8.5, leading=11.5, textColor=INK,
    ))
    ss.add(ParagraphStyle(
        "CellHead", fontName="ArialU", fontSize=8.5, leading=11.5, textColor=white,
    ))
    ss.add(ParagraphStyle(
        "Note", fontName="ArialU", fontSize=9, leading=12.5,
        textColor=NAVY, backColor=BG_ROW, borderPadding=6, spaceAfter=8, spaceBefore=4,
    ))
    return ss


def bullets(ss, items):
    flow = []
    for it in items:
        flow.append(ListItem(Paragraph(it, ss["BulletBody"]), leftIndent=14, bulletColor=TEAL))
    return ListFlowable(flow, bulletType="bullet", start="•", leftIndent=16, spaceAfter=8)


def table(ss, header, rows, col_widths):
    h = [Paragraph(x, ss["CellHead"]) for x in header]
    data = [h]
    for row in rows:
        data.append([Paragraph(c, ss["Cell"]) for c in row])
    t = Table(data, colWidths=col_widths, repeatRows=1)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), NAVY),
        ("TEXTCOLOR", (0, 0), (-1, 0), white),
        ("BACKGROUND", (0, 1), (-1, -1), white),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [white, BG_ROW]),
        ("GRID", (0, 0), (-1, -1), 0.3, LINE),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    return t


def header_footer(canvas, doc):
    canvas.saveState()
    w, h = A4
    canvas.setFillColor(NAVY)
    canvas.rect(0, h - 16 * mm, w, 16 * mm, fill=1, stroke=0)
    canvas.setFillColor(GOLD)
    canvas.rect(0, h - 16.8 * mm, w, 1.2 * mm, fill=1, stroke=0)
    canvas.setFillColor(white)
    canvas.setFont("ArialU", 9)
    canvas.drawString(18 * mm, h - 10 * mm, "ASmart 3.1  ·  ACTECK MT5  ·  Снайпер PDF")
    canvas.drawRightString(w - 18 * mm, h - 10 * mm, "Краткое руководство")
    canvas.setFillColor(NAVY)
    canvas.rect(0, 0, w, 12 * mm, fill=1, stroke=0)
    canvas.setFillColor(HexColor("#E8E0D0"))
    canvas.setFont("ArialU", 8)
    canvas.drawString(18 * mm, 5 * mm, "Решения только после закрытия свечи")
    canvas.drawRightString(w - 18 * mm, 5 * mm, "стр. %d" % doc.page)
    canvas.restoreState()


def cover_first(canvas, doc):
    w, h = A4
    canvas.saveState()
    canvas.setFillColor(NAVY)
    canvas.rect(0, 0, w, h, fill=1, stroke=0)
    canvas.setFillColor(GOLD)
    canvas.rect(0, h * 0.42, w, 3, fill=1, stroke=0)
    canvas.setFillColor(white)
    canvas.setFont("ArialU", 11)
    canvas.drawCentredString(w / 2, h * 0.62, "ACTECK  ·  MetaTrader 5")
    canvas.setFont("ArialU", 26)
    canvas.drawCentredString(w / 2, h * 0.52, "ASmart 3.1")
    canvas.setFont("ArialU", 13)
    canvas.drawCentredString(w / 2, h * 0.46, "Краткое руководство трейдера")
    canvas.setFillColor(HexColor("#E8E0D0"))
    canvas.setFont("ArialU", 10)
    canvas.drawCentredString(w / 2, h * 0.36, "Базовые свечи  ·  ИКИ → КЗ  ·  38.2 / 23.6")
    canvas.drawCentredString(w / 2, h * 0.32, "Линия 30%  ·  РМ  ·  A/B/C  ·  индекс страха")
    canvas.setFont("ArialU", 8.5)
    canvas.drawCentredString(w / 2, 22 * mm, "Актуально на 12 октября 2026 ")
    canvas.restoreState()


def build():
    ss = style_sheet()
    story = []
    story.append(Spacer(1, 190 * mm))
    story.append(PageBreak())

    story.append(Paragraph("1. Версии и файлы", ss["H1"]))
    story.append(Paragraph(
        "ASmart 3.1 приводит логику к правилам методичек Снайпер (базовые свечи, ИКИ, коррекционные зоны, "
        "базовая и каскадная модели расширения), сохраняя UX ASmart: «30», прицел, стрелки, алерты.",
        ss["Body"]))
    story.append(Paragraph(
        ": снять 3.1 с графика, повесить <b>ASmart 3.1</b>. ",
        ss["Note"]))
    story.append(table(ss,
        ["Файл", "Зачем"],
        [
            ["MQL5/Experts/ASmart 3.1.mq5", "Исходник 3.1. F7 → ASmart 3.1.ex5"],
            ["MQL5/Experts/ASmart 3.1.mq5", "Исходник (без изменений 3.1)"],
            ["UserGuide_ASmart_3.1_RU.txt", "Шпаргалка у графика для 3.1"],
            ["UserGuide_Snayper_Pricel_EA_RU.txt", "Шпаргалка для 2.14"],
            ["README.md", "Детектор 3.1, пороги, объекты"],
            ["Sniper/*.pdf", "Методички: механика, КЗ, базовая/каскадная модели"],
        ],
        [70 * mm, 110 * mm]))

    story.append(Paragraph("2. Установка", ss["H1"]))
    story.append(bullets(ss, [
        "MetaEditor → <b>ASmart 3.1.mq5</b> → F7.",
        "Снять с графика старую версию. Навесить <b>ASmart 3.1</b> (префикс объектов ASmart3_).",
        "Сначала TradeEnabled=false: только разметка.",
        "SpeedPreset: SCALP (3) · CALM (8) · SWING (60).",
        "Решения — по UserGuide_ASmart_3.1_RU.txt.",
    ]))

    story.append(Paragraph("3. Что на графике (3.1)", ss["H1"]))
    story.append(table(ss,
        ["Объект", "Смысл"],
        [
            ["Синий пунктир Z + «-0.00»", "Импульс по базовым свечам (не внутренние бары)."],
            ["Синяя «30»", "Вспомогательный откат UX ASmart — зона поиска входа."],
            ["«38.2»", "Разворотная зона базовой модели расширения (методичка)."],
            ["«23.6»", "Разворотная зона каскадной модели."],
            ["КЗ", "Коррекционная зона из ИКИ (экстремум действительной коррекции)."],
            ["ЗУ / бокс модели", "Зона принятия решения у 38.2 / каскада."],
            ["Рамка РМ", "Остановка (stall) или длинный хвост (rejection). Только last closed."],
            ["Прицел / стрелка / страх", "Как в 2.14: сторона, вход на закрытии, индекс 0–100."],
        ],
        [52 * mm, 128 * mm]))

    story.append(Paragraph("4. Грамматика Снайпер в коде", ss["H1"]))
    story.append(Paragraph(
        "<b>Механика:</b> импульс и коррекция считаются по базовым свечам. "
        "Внутренние бары пропускаются. <b>Внешний бар</b> (обновил high и low): два узла пути — сначала коррекция, затем продолжение в сторону выхода (как на уроке Снайпер).",
        ss["Body"]))
    story.append(Paragraph(
        "<b>КЗ (ИКИ):</b> импульс → действительная коррекция → второй импульс, обновляющий первый → "
        "зона на экстремуме коррекции. Новые КЗ ограничиваются MaxActiveKZ.",
        ss["Body"]))
    story.append(Paragraph(
        "<b>Базовая модель:</b> диапазон между КЗ, пробой в обе стороны → поиск входа в области 38.2% "
        "последнего импульса. <b>Каскад:</b> продолжение с пробоем КЗ → зона 23.6% первого импульса каскада.",
        ss["Body"]))
    story.append(Paragraph(
        "Пороги импульса по умолчанию мягче, чем в 2.14: ≥ 1.0×ATR и ≥ 3 базовых свечей "
        "(PD_MinImpulseATR / PD_MinImpulseBars). Снятие хода при откате ≥ 50% сохранено.",
        ss["Note"]))

    story.append(Paragraph("5. Как торговать", ss["H1"]))
    story.append(Paragraph(
        "Пошаговое решение — только в <b>UserGuide_ASmart_3.1_RU.txt</b>. "
        "Логика входа A/B/C, сейф min(1R, 0.30×импульс), трейл — как в 2.14.",
        ss["Body"]))
    story.append(Paragraph(
        "Линия «30» — рабочий UX отката. Линии 38.2 / 23.6 — разметка моделей; "
        "жёсткий фильтр «вход только от 38.2» в коде не включён — ориентир анализа + confluence ЗУ.",
        ss["Note"]))

    story.append(Paragraph("6. Рамка РМ", ss["H1"]))
    story.append(Paragraph(
        "Stall: маленькое тело после импульса у вершины/дна (как 2.14). "
        "Опционально RM_AllowRejection: длинный хвост ≥ N× тело — визуальная рамка отклонения (как у Pro). "
        "Подтверждение входа по Price Action / стрелке не заменяется одним только rejection.",
        ss["Body"]))

    story.append(Paragraph("7. Старение разметки", ss["H1"]))
    story.append(Paragraph(
        "FadeOldMarkings: бледнеет после MarkFadeAfterHours (18), скрывается после MarkHideAfterHours (48). "
        "Старая «30» оранжевая и удаляется на следующий день. Неактуальные объекты не копятся бесконечно.",
        ss["Body"]))

    story.append(Paragraph("Карточка у графика", ss["H1"]))
    story.append(Paragraph(
        "Пять вопросов перед входом — в конце UserGuide_ASmart_3.1_RU.txt.",
        ss["Body"]))

    dest = ROOT / "ASmart_3.1_Manual_RU.pdf"
    doc = SimpleDocTemplate(
        str(dest),
        pagesize=A4,
        leftMargin=18 * mm,
        rightMargin=18 * mm,
        topMargin=22 * mm,
        bottomMargin=16 * mm,
        title="ASmart 3.1 — краткое руководство",
        author="ACTECK",
    )
    doc.build(story, onFirstPage=cover_first, onLaterPages=header_footer)
    print("wrote", dest)


if __name__ == "__main__":
    build()
