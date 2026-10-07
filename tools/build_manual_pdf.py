#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Сборка актуального краткого руководства ASmart 2.07 (RU).

Не дублирует UserGuide_Snayper_Pricel_EA_RU.txt: там карточка решения у графика.
Здесь — установка, объекты, ход, РМ, тип 1 и A/B/C. Детектор подробно — README.md.
"""

from pathlib import Path

from reportlab.lib.colors import Color, HexColor, white
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
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
        "CoverTitle", fontName="ArialU", fontSize=22, leading=28,
        textColor=white, alignment=TA_CENTER, spaceAfter=6,
    ))
    ss.add(ParagraphStyle(
        "CoverSub", fontName="ArialU", fontSize=12, leading=16,
        textColor=HexColor("#E8E0D0"), alignment=TA_CENTER, spaceAfter=4,
    ))
    ss.add(ParagraphStyle(
        "H1", fontName="ArialU", fontSize=14, leading=18,
        textColor=NAVY, spaceBefore=14, spaceAfter=8,
    ))
    ss.add(ParagraphStyle(
        "H2", fontName="ArialU", fontSize=11.5, leading=15,
        textColor=TEAL, spaceBefore=10, spaceAfter=5,
    ))
    ss.add(ParagraphStyle(
        "Body", fontName="ArialU", fontSize=9.5, leading=13.2,
        textColor=INK, alignment=TA_JUSTIFY, spaceAfter=6,
    ))
    ss.add(ParagraphStyle(
        "BulletBody", fontName="ArialU", fontSize=9.5, leading=13.0,
        textColor=INK, leftIndent=2, spaceAfter=2,
    ))
    ss.add(ParagraphStyle(
        "Cell", fontName="ArialU", fontSize=8.5, leading=11.5, textColor=INK,
    ))
    ss.add(ParagraphStyle(
        "CellHead", fontName="ArialU", fontSize=8.5, leading=11.5, textColor=white,
    ))
    ss.add(ParagraphStyle(
        "Footer", fontName="ArialU", fontSize=8, leading=10,
        textColor=MUTED, alignment=TA_CENTER,
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
    canvas.drawString(18 * mm, h - 10 * mm, "ASmart 2.07  ·  ACTECK MT5  ·  Снайпер")
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
    canvas.drawCentredString(w / 2, h * 0.52, "ASmart 2.07")
    canvas.setFont("ArialU", 13)
    canvas.drawCentredString(w / 2, h * 0.46, "Краткое руководство трейдера")
    canvas.setFillColor(HexColor("#E8E0D0"))
    canvas.setFont("ArialU", 10)
    canvas.drawCentredString(w / 2, h * 0.36, "Продолженное движение  ·  линия 30%  ·  разворотный момент")
    canvas.drawCentredString(w / 2, h * 0.32, "Сигналы A / B / C  ·  индекс страха  ·  сейф и трейл")
    canvas.setFont("ArialU", 8.5)
    canvas.drawCentredString(w / 2, 22 * mm, "Актуально на 6 октября 2026")
    canvas.restoreState()


def build():
    ss = style_sheet()

    story = []
    story.append(Spacer(1, 190 * mm))
    story.append(PageBreak())

    story.append(Paragraph("1. Что это и чем файлы отличаются", ss["H1"]))
    story.append(Paragraph(
        "ASmart 2.07 — советник MetaTrader 5 по логике Снайпера: безоткатное (продолженное) "
        "движение, откат 30%, разворотный момент, зона консолидации и стрелки A/B/C. "
        "Продукт тот же ACTECK MT5; имя советника — ASmart.",
        ss["Body"]))
    story.append(Paragraph(
        "Этот PDF <b>не копирует</b> UserGuide. UserGuide — короткая карточка у графика (открывать / не открывать / сейф). "
        "PDF — печатное how-to: установка, что нарисовано, как считается ход, когда рамка, когда стрелка тип 1. "
        "Полный детектор и пороги — README.md.",
        ss["Note"]))
    story.append(table(ss,
        ["Файл", "Зачем"],
        [
            ["MQL5/Experts/ASmart 2.07.mq5", "Исходник. Собрать в MetaEditor клавишей F7."],
            ["UserGuide_Snayper_Pricel_EA_RU.txt", "Карточка трейдера: шаги 1–7, вход и ведение. Не этот PDF."],
            ["README.md", "Как детектируется ход, 20/30/50%, сигналы, сейф."],
            ["README_INSTALL_RU.txt", "Установка и пресеты."],
            ["MQL5/Presets/Acteck_v4.1_*.set", "Пресеты: EUR, GBP, JPY, CHF, золото, биткоин."],
        ],
        [70 * mm, 110 * mm]))

    story.append(Paragraph("2. Установка", ss["H1"]))
    story.append(bullets(ss, [
        "MetaEditor → открыть <b>ASmart 2.07.mq5</b> → F7. Должен появиться ASmart 2.07.ex5.",
        "С графика снять старую версию (2.06 и ниже). Перетащить на график <b>ASmart 2.07</b>.",
        "Inputs → Загрузить: Acteck_v4.1_&lt;инструмент&gt;_calm|scalp|swing_H1.set → OK.",
        "Сначала TradeEnabled=false: только разметка, без ордеров.",
        "SpeedPreset: SCALP (3) · CALM (8) · SWING (60). Смена → OK → перерисовка.",
        "Инструменты: EURUSD, GBPUSD, USDJPY, USDCHF, XAUUSD, BTCUSD.",
    ]))

    story.append(Paragraph("3. Что смотреть на графике", ss["H1"]))
    story.append(table(ss,
        ["Объект", "Смысл"],
        [
            ["Пунктир Z", "Есть продолженное движение. Нет пунктира — нет хода, ждать."],
            ["Синяя линия «30»", "Рабочий откат текущего хода. Не уровень разворота."],
            ["Жёлтая / оранжевая «30»", "Старая, не рабочая. По ней не входить. Обычно пропадает на следующий день."],
            ["Прицел", "Надпись ПРИЦЕЛ BUY или ПРИЦЕЛ SELL и цветные чёрточки."],
            ["Синяя рамка на свече", "РМ на покупку. Только последняя закрытая свеча."],
            ["Красная рамка на свече", "РМ на продажу. Только последняя закрытая свеча."],
            ["Стрелка вверх / вниз", "Сигнал на закрытии. В прошлое не дорисовывается."],
            ["Подпись у стрелки", "покупка/продажа; по ходу или против хода; против прицела; индекс страха."],
            ["Число справа сверху", "Индекс страха 0–100. Это не шанс профита."],
            ["Спрос / Предложение", "Зоны ликвидности. Не зона консолидации и не стрелка."],
        ],
        [48 * mm, 132 * mm]))

    story.append(Paragraph("4. Как торговать", ss["H1"]))
    story.append(Paragraph(
        "Пошаговое решение (ход → «30» → сторона → страх → вход → сейф → когда не открывать) — только в "
        "<b>UserGuide_Snayper_Pricel_EA_RU.txt</b>. Здесь шаги не повторяем.",
        ss["Body"]))
    story.append(Paragraph(
        "Решение только после закрытия свечи. TradeEnabled=false — разметка без ордеров. "
        "Если откат съел половину хода и больше, пунктир Z и синяя «30» исчезают (линию 50% не рисуем).",
        ss["Note"]))

    story.append(Paragraph("5. Как считается ход (кратко)", ss["H1"]))
    story.append(Paragraph(
        "Это не «N свечей одного цвета» и не пробой дня. На закрытии свечи советник ищет один свинг: начало хода → кончик. "
        "Импульс, если высота всего хода ≥ 2.5×ATR и длина ≥ 6 баров. Ход живёт, пока откат от кончика меньше 20%. "
        "Откат ≥ 20% фиксирует ход. Откат ≥ 30% — зона поиска (синяя «30»). "
        "Кончик продлевается, если следующая свеча <b>закрылась</b> за экстремумом или это сильная свеча по ходу. "
        "Хвост доджи/пина за кончиком — ложный пробой: Z и «30» не перестраиваются. "
        "Встречный кусок внутри 50% родителя — коррекция, не новый ход.",
        ss["Body"]))
    story.append(Paragraph(
        "Полные правила и пороги — README.md.",
        ss["Note"]))

    story.append(Paragraph("6. Рамка и стрелка — не одно и то же", ss["H1"]))
    story.append(Paragraph(
        "Красная или синяя рамка — разворотный момент на <b>последней закрытой</b> свече: "
        "за 4 бара слева импульс ≥ 1,2×ATR, маленькое тело в зоне вершины/дна "
        "(допуск <b>RM_PeakATR_Pad</b> 0,15×ATR). Исторические рамки не рисуются и не вспыхивают позже. "
        "Стрелка тоже только в момент закрытия сетапа, не на прошедших свечах.",
        ss["Body"]))
    story.append(Paragraph(
        "Стрелка тип 1: кончик → касание «30» без отмены 50% → рамка на закрытой свече <b>после</b> кончика, "
        "закрытие не за кончиком и не глубже рабочей «30» (зона от кончика до «30», не совпадение хая с кончиком). "
        "Касание «30» само по себе — не вход. Хвост за кончиком у доджи Z не отменяет сетап.",
        ss["Body"]))

    story.append(Paragraph("7. Откуда стрелка A / B / C", ss["H1"]))
    story.append(table(ss,
        ["Сигнал", "Когда"],
        [
            ["A", "Закрытие свечи за край зоны консолидации (пробой)."],
            ["B", "Тень вышла за край, закрытие внутри (ложный пробой). Также ретест коррекционной зоны + разворотный момент."],
            ["C", "После пробоя цена вернулась в зону, затем снова закрылась наружу в сторону пробоя."],
        ],
        [28 * mm, 152 * mm]))
    story.append(Paragraph(
        "Зона консолидации — узкий прямоугольник: последние N свечей не шире K×ATR. "
        "Фиолетовое «Предложение» и рамка разворотного момента — не эта зона. "
        "Разворотный момент на закрытой свече считается подтверждением Price Action (импульс → остановка в зоне экстремума → вход). "
        "Продолженное движение тип 1: см. раздел 6.",
        ss["Body"]))
    story.append(Paragraph(
        "M1 и M15 считаются вместе (UseVirtualTF). Разметка старшего ТФ на графике по умолчанию скрыта (ShowSlowTFStructures=false).",
        ss["Body"]))

    story.append(Paragraph("8. Что включено по умолчанию", ss["H1"]))
    story.append(Paragraph(
        "Включено: прицел, синяя «30», разворотный момент, ГУД, сессии, спрос/предложение, контуры зон, индекс страха, стрелки. "
        "Выключено: имена 12 паттернов, каскад, подписи паттернов, заливка зон, Balance RSI, канал «границы», разметка M15. "
        "Старая разметка бледнеет примерно через 18 часов и скрывается через 48 часов.",
        ss["Body"]))

    story.append(Paragraph("Карточка у графика", ss["H1"]))
    story.append(Paragraph(
        "Пять вопросов перед входом — в конце UserGuide_Snayper_Pricel_EA_RU.txt, не здесь.",
        ss["Body"]))

    def first_page(c, d):
        cover_first(c, d)

    def later(c, d):
        header_footer(c, d)

    dest = ROOT / "ASmart_2.07_Manual_RU.pdf"
    doc = SimpleDocTemplate(
        str(dest),
        pagesize=A4,
        leftMargin=18 * mm,
        rightMargin=18 * mm,
        topMargin=22 * mm,
        bottomMargin=16 * mm,
        title="ASmart 2.07 — краткое руководство",
        author="ACTECK",
    )
    doc.build(story, onFirstPage=first_page, onLaterPages=later)
    print("wrote", dest)


if __name__ == "__main__":
    build()
