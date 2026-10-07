//+------------------------------------------------------------------+
//|  ASmart 2.13                                                      |
//|  Copyright Evgeniy Acteck — All rights reserved                    |
//|  Sniper-style liquidity EA: sessions, sight, probability HUD      |
//+------------------------------------------------------------------+
#property copyright "Evgeniy Acteck"
#property description "ASmart 2.13 — SL/Сейф-линии у стрелки, спред POINT"
#property version   "2.13"

#define EA_VERSION "2.13"


//=========================
// Enums (inputs)
//=========================
enum ENUM_CONFIRM_PATTERN
{
   CP_OFF = 0,          // без свечного фильтра
   CP_ENGULFING = 1,    // поглощение
   CP_OUTSIDEBAR = 2,   // внешний бар
   CP_PINBAR = 3,       // пин-бар (отбой / снятие стопов)
   CP_SNIPER = 4        // пин-бар ИЛИ поглощение ИЛИ внешний бар (рекомендуется)
};

enum ENUM_EMA_FILTER_MODE
{
   EMA_MODE_PRICE = 0,
   EMA_MODE_CLOSE = 1,
   EMA_MODE_BARCLOSE = 2
};

enum ENUM_LOT_MODE
{
   LOT_FIXED = 0,
   LOT_PERCENT_RISK = 1
};

enum ENUM_SL_MODE
{
   SL_FIXED = 0,
   SL_FROM_ZONE = 1
};

enum ENUM_TP_MODE
{
   TP_FIXED = 0,
   TP_FROM_ZONE = 1
};

enum ENUM_SWING_MODE
{
   SWING_ZIGZAG = 0,
   SWING_FRACTALS = 1
};

enum ENUM_ALERTS_MODE
{
   ALERTS_OFF = 0,
   ALERTS_ONSCREEN = 1,
   ALERTS_PUSH = 2
};

// Built-in per-pair presets (statistics-driven). CUSTOM = use EnableSignal* / filters inputs as-is.
enum ENUM_SYMBOL_PROFILE
{
   PROFILE_AUTO = 0,    // detect EURUSD/GBPUSD/USDJPY/USDCHF from chart symbol name
   PROFILE_CUSTOM = 1,
   PROFILE_EURUSD = 2,
   PROFILE_GBPUSD = 3,
   PROFILE_USDJPY = 4,
   PROFILE_USDCHF = 5
};

// Скорость индикатора — одинаково для ЛЮБОГО символа (смена в Inputs → OK → полный пересчёт)
enum ENUM_SPEED_PRESET
{
   SPEED_SCALP  = 3,   // скальп: глубина 3 (быстрая реакция)
   SPEED_CALM   = 8,   // спокойный: глубина 8 (по умолчанию)
   SPEED_SWING  = 60,  // крупные свинги: глубина 60 (обычно H1)
   SPEED_CUSTOM = 0    // вручную: значение IndicatorSpeed
};

//=========================
// Inputs (according to TZ v1.0)
//=========================
input ENUM_SYMBOL_PROFILE  SymbolStrategyProfile = PROFILE_AUTO; // AUTO: match chart; CUSTOM: inputs below; else force named profile
input ENUM_TIMEFRAMES      Timeframe            = PERIOD_M5;
input bool                 SyncChartFromPreset  = true;  // OK в свойствах → сменить символ/ТФ графика под пресет
input string               PreferredSymbol      = "";    // база символа из пресета: EURUSD / GBPUSD / … (суффикс брокера подберётся)
input int                  DayStartHour         = 0;
input bool                 UsePrevDayLevels     = true;
input int                  ShowLevelsLenBars    = 500;
input bool                 BalanceUseOpenPrice  = false; // optional

// Zones
input int                  CZ_LookbackN         = 20;
input int                  CZ_ATR_Period        = 14;
input double               CZ_ATR_K             = 1.0;
input int                  BreakCloseOffset     = 5;      // points
input int                  RetestDepth          = 5;      // points
input double               WickRatio            = 2.0;
input ENUM_CONFIRM_PATTERN ConfirmPattern       = CP_SNIPER; // по умолчанию свечное подтверждение
input bool                 EnableSignalA        = true;
input bool                 EnableSignalB        = true;
input bool                 EnableSignalC        = true;

// Filters
input int                  EMA_Period           = 200;
input ENUM_EMA_FILTER_MODE EMA_FilterMode       = EMA_MODE_CLOSE;
input int                  ATR_Period           = 14;
input int                  ATR_Min              = 10;     // points
input double               RangeMinATR_Mult     = 0.0;    // 0 = off

// Extra quality filters (v1.09)
input double               MinRewardToRisk      = 0.0;    // 0 = off; TP_distance/SL_distance >= value (both SL/TP must be set)
input bool                 UseServerSession     = false; // limit entries to server-time window (TimeCurrent)
input int                  SessionStartHour     = 7;     // inclusive; see SessionEndHour
input int                  SessionEndHour       = 22;    // if Start<End: hour in [Start, End); if Start>End: overnight window

// Time-based exit (optional; reduces overnight/news gap risk on manual review feedback)
input bool                 CloseBeforeWeekend   = false; // close EA positions on Friday from FridayCloseHourServer
input int                  FridayCloseHourServer = 20;   // server time hour (e.g. 20 = 20:00)
input int                  MaxPositionLifetimeHours = 0;  // 0 = off; force close after N hours in position

// Trading / risk
input bool                 TradeEnabled         = true;   // "signals only" when false
input ENUM_LOT_MODE        LotMode              = LOT_PERCENT_RISK;
input double               Lot                  = 0.10;
input double               Percent              = 2.0;
input ENUM_SL_MODE         SL_Mode              = SL_FIXED;
input int                  SL_Points            = 200;    // points
input int                  SL_Offset            = 0;      // points (for FromZone)
input ENUM_TP_MODE         TP_Mode              = TP_FIXED;
input int                  TP_Points            = 200;    // points
input int                  TP_Offset            = 0;      // points (for FromZone)

input bool                 UseBE                = true;
input int                  BE_Trigger           = 5;      // additional points after PartialClose step1 (only if PartialClose_On=true)
input int                  BE_Offset            = 5;      // points

input bool                 UseTS                = true;
input int                  TS_Start             = 0;      // пунктов до старта трейла; 0 = после сейфа
input int                  TS_Step              = 50;     // запас, если TrailATR=0
input double               TrailATR             = 0.25;   // шаг трейла в ATR (0 = TS_Step пункты)

input bool                 PartialClose_On      = true;
input int                  PC_Step1             = 150;    // points
input double               PC_Vol1              = 0.50;   // fraction of initial volume
input int                  PC_Step2             = 300;    // points
input double               PC_Vol2              = 0.50;   // fraction of initial volume

input bool                 OnlyOneTradePerBar   = true;
input int                  ReEntries            = 0;      // additional entries per zone (0 => 1 trade/zone)
input int                  MaxPositions         = 1;
input int                  MaxSpread            = 20;     // points
input int                  Slippage             = 10;     // points
input long                 MagicNumber          = 240117;
input string               CommentPrefix        = "ASmart";

// Swing / "pro-torgovka"
input ENUM_SWING_MODE      SwingMode            = SWING_FRACTALS;
input int                  ZZ_Depth             = 12;
input int                  ZZ_Deviation         = 5;      // points
input int                  ZZ_Backstep          = 3;
input bool                 ShowSwingLine        = false; // UI: меньше линий

// Graphics / alerts
input bool                 ShowZones            = true;
input bool                 ShowEntryMarker      = true;
input bool                 ShowEntrySLTPLines   = true;   // при стрелке: гориз. SL + ТП по Сейфу
input bool                 KeepSignalHistory    = false; // UI: не копить старые маркеры
input bool                 FadeOldMarkings      = true;  // старая разметка бледнеет и исчезает
input int                  MarkFadeAfterHours   = 18;    // после этого контур бледнеет
input int                  MarkHideAfterHours   = 48;    // старше — скрыть (позавчера)
input bool                 ShowArrows           = true;
input ENUM_ALERTS_MODE     AlertsMode           = ALERTS_ONSCREEN;

input color                ColorZoneActive      = clrSilver;
input color                ColorZoneBroken      = clrDarkGray;
input color                ColorReactLine       = clrDodgerBlue;
input ENUM_LINE_STYLE      ReactLineStyle       = STYLE_SOLID;
input int                  ReactLineWidth       = 2;
input color                ColorHOD             = clrRed;
input color                ColorLOD             = clrBlue;
input color                ColorBalance          = clrGray;
input color                ColorSwingLine       = clrDodgerBlue;
input int                  SwingLineWidth       = 2;
input ENUM_LINE_STYLE      SwingLineStyle       = STYLE_DASH;
input color                ColorBuyMarker       = clrLimeGreen;
input color                ColorSellMarker      = clrTomato;

//=========================
// Sniper modules (v2.0)
//=========================
input group "=== Sniper: Sessions ==="
input bool                 ShowSessionLevels    = true;
input int                  SessionLookbackDays  = 1;      // UI: меньше сессионных линий
input int                  AsiaStartHour        = 0;      // server time
input int                  AsiaEndHour          = 8;
input int                  LondonStartHour      = 8;
input int                  LondonEndHour        = 16;
input int                  NYStartHour          = 13;
input int                  NYEndHour            = 22;
input bool                 ShowSessionShading   = false;
input color                ColorAsia            = clrSeaGreen;
input color                ColorLondon          = clrDodgerBlue;
input color                ColorNY              = clrTomato;

input group "=== Sniper: Liquidity zones ==="
input bool                 ShowLiquidityZones   = true;  // Спрос / Предложение (как на эталонном скрине)
input int                  LiqPivotDepth        = 3;   // глубина пивотов зон ликвидности (не зависит от SpeedPreset)
input double               LiqZoneATR_Mult      = 0.35;   // zone height = mult * ATR
input int                  MaxLiquidityZones    = 3;
input int                  LiqLookbackBars      = 250;
input color                ColorSupplyZone      = clrMistyRose;
input color                ColorDemandZone      = clrPowderBlue;

input group "=== Sniper: Sight (Прицел) ==="
input bool                 ShowSight            = true;
input bool                 RequireSightForEntry = false;
input bool                 SightShowFrame       = false;  // рамка ВЫКЛ по умолчанию — только чёрточки
input bool                 SightShowDashes      = true;   // RGB-чёрточки Hi/Mid/Lo (по умолчанию)
input double               SightATR_Height      = 1.2;
input int                  SightBarsWidth       = 14;     // ширина рамки прицела (баров)
input int                  SightDashBars        = 5;      // длина RGB-чёрточек (баров)
input double               SightNearATR         = 1.5;
input bool                 SightLevelsLive      = true;
input color                ColorSightBuy        = clrDodgerBlue;  // голубой BUY
input color                ColorSightSell       = clrMaroon;      // бордовый SELL
input color                ColorSightDashHi     = clrRed;
input color                ColorSightDashMid    = clrLimeGreen;
input color                ColorSightDashLo     = clrDodgerBlue;

input group "=== Sniper: Fear Index (индекс страха) ==="
input bool                 ShowFearIndexHUD     = true;   // число справа сверху = индекс страха 0..100
input int                  FearIndexPeriod      = 14;     // период RSI-базы индекса
input bool                 FilterByFearIndex    = true;   // на страхе не продаём, на жадности не покупаем
input bool                 AutoTPByFearIndex    = true;   // TP = SL × множитель зоны индекса
input bool                 UseSafeRule          = true;   // сейф: 50% на min(1R, 0.30×импульс) + BE
input double               SafeImpulseK         = 0.30;   // доля импульса для сейфа (не дальше 1R)
input bool                 ScaleLotBySetupQuality = false; // старый масштаб лота по «зрелости» сетапа (не индекс)
input int                  SetupQualityMinToTrade = 0;    // 0 = выкл.; порог зрелости сетапа (не индекс страха)
input int                  FearHistoryLen       = 24;     // точки истории для ломаной
input color                ColorFearExtreme     = clrIndianRed;     // 0–30 и 70–100
input color                ColorFearTransition  = clrDarkGoldenrod; // 30–35 и 65–70
input color                ColorFearNeutral     = clrSeaGreen;      // 35–65

// совместимость со старыми пресетами (.set): те же слоты, другие имена не ломают Load
input bool                 ShowProbabilityHUD   = true;   // устар.: синоним ShowFearIndexHUD
input bool                 ScaleLotByProbability = false; // устар.: синоним ScaleLotBySetupQuality
input int                  ProbMinToTrade       = 0;      // устар.: синоним SetupQualityMinToTrade
input int                  ProbHistoryLen       = 24;     // устар.: синоним FearHistoryLen
input color                ColorProbHigh        = clrSeaGreen;
input color                ColorProbMid         = clrDarkGoldenrod;
input color                ColorProbLow         = clrIndianRed;

input group "=== Sniper: Signal quality ==="
input bool                 PreferLiquidityFade  = true;   // boost B near stop pools / session extremes
input bool                 BlockWeakBreakouts   = true;   // filter weak Signal A without momentum
input double               BreakoutBodyATR_Min  = 0.35;   // min body/ATR for Signal A when BlockWeakBreakouts
input int                  BrokenZoneMaxBars    = 80;     // expire retest window earlier than v1
input bool                 AlignBreakoutWithSight = true; // Signal A: не входить против активного прицела
input bool                 MarkPreciseArrows    = true;   // крупные стрелки точного входа на закрытии бара

input group "=== Sniper: Structures (ЗУ / ПД / Каскад / РМ) ==="
input bool                 ShowDecisionZones    = true;   // ЗУ
input bool                 ShowPullbackZones    = true;   // ПД
input bool                 ShowCascadeMarks     = false;
input bool                 ShowReversalMoments  = true;   // РМ: рамка Price Action на свече остановки
input bool                 ShowGUDLevels        = true;   // ГУД: глобальный уровень дисбаланса (М/W)
input bool                 ShowZoneFill         = false;  // заливка ЗУ/ПД ВЫКЛ — только контур
input bool                 ShowFib30            = true;   // тонкая линия «30» как в Sniper-PRO (без заливки)
input bool                 ShowContinuedMoveZ   = true;   // Z-контур хода: 2 горизонтали + косая пунктиром
input color                ColorFib30           = clrDodgerBlue; // сплошная «30» (актуальная, справа)
input color                ColorFib30Old        = clrOrange;     // «30» прошлого хода (память до след. дня)
input color                ColorContinuedMove   = clrSilver;     // цвет пунктира каркаса хода
input int                  WidthContinuedMove   = 2;      // толщина пунктира Z (1..4)
input ENUM_SPEED_PRESET    SpeedPreset          = SPEED_CALM; // скальп / спокойный / свинги — для ЛЮБОЙ пары
input int                  IndicatorSpeed       = 8;      // глубина, если SpeedPreset=CUSTOM (2..60)
input int                  StructureLookbackBars = 250;    // баров истории для структур
input double               PD_MinCorrectionPct  = 30.0;   // зона поиска / вход: откат ≥ этого % ширины
input double               PD_CompletePullbackPct = 20.0; // первый значимый откат — фиксация хода, %
input double               PD_CancelRetracePct  = 50.0;   // глубже — сетап снят
input double               PD_MinImpulseATR     = 2.5;    // мин. высота всего импульса в ATR
input int                  PD_MinImpulseBars    = 6;      // мин. баров в импульсе
input int                  PD_MinImpulsePoints  = 0;      // доп. пол в пунктах; 0 = только ATR+бары
input double               SL_AtrPad            = 0.15;   // SL за зоной, доли ATR
input double               TP_ImpulseK          = 1.00;   // TP = вход ± доля ширины импульса (если не AutoTP)
input int                  PD_RetestMaxHours    = 6;      // макс. часов до ретеста ПД
input double               CascadeMaxBreakoutPct = 100.0; // каскад: пробой > этого % от X — отмена
input double               ZU_HeightATR_Mult    = 0.35;   // высота ЗУ в долях ATR
input int                  RM_ImpulseBars       = 4;      // баров импульса для РМ
input double               RM_ImpulseATR_Mult   = 1.2;    // мин. импульс в ATR
input double               RM_StallBodyATR_Max  = 0.35;   // макс. тело свечи "остановки"
input double               RM_PeakATR_Pad       = 0.15;   // допуск «на вершине/дне»: доли ATR (не 1 пункт)
input int                  MaxStructureZones    = 4;
input color                ColorZU_Buy          = clrPaleTurquoise;
input color                ColorZU_Sell         = clrBurlyWood;
input color                ColorPD_Zone         = clrPowderBlue;
input color                ColorRM_Buy          = clrDodgerBlue; // синий — покупка
input color                ColorRM_Sell         = clrRed;        // красный — продажа

input group "=== Sniper: Frankfurt session ==="
input bool                 ShowFrankfurt        = true;
input int                  FrankfurtStartHour   = 9;
input int                  FrankfurtEndHour     = 10;
input color                ColorFrankfurt       = clrPaleGreen;

input group "=== Sniper: 12 Patterns ==="
input bool                 ShowAll12Patterns    = false;  // UI: не рисовать все 12
input bool                 ShowPatternPercents  = false;
input bool                 ShowStructureLabels  = false;  // подписи ЗУ/ПД/каскад (шум)
input double               PD_BreakoutPct       = 123.0;  // ПД: выход ≥% ширины диапазона
input double               ZU_SizePctOfMove     = 30.0;   // размер ЗУ = % от движения
input double               CascadeRetrace50Pct  = 50.0;   // каскад 3: откат ≤%
input double               CascadeRetrace70Pct  = 70.0;   // каскад 4: откат ≥%
input double               CascadeDeep150Pct    = 150.0;  // каскад 6: глубина ~
input color                ColorPatternBuy      = clrDodgerBlue;
input color                ColorPatternSell     = clrOrangeRed;

input group "=== Sniper: Dual TF (M1+M15) ==="
input bool                 UseVirtualTF         = true;   // как в Sniper-Pro
input ENUM_TIMEFRAMES      FastTF               = PERIOD_M1;
input ENUM_TIMEFRAMES      SlowTF               = PERIOD_M15;
input bool                 ShowSlowTFStructures = false;  // UI: M15-разметка выкл.
input bool                 RequireMTFConfluence = false;  // вход только при совпадении направлений
input color                ColorSlowTF          = clrGold;

input group "=== Sniper: Balance RSI ==="
input bool                 ShowBalanceRSI       = false;
input int                  BalanceRSI_Period    = 14;
input double               BalanceRSI_OB        = 70.0;   // перекупленность
input double               BalanceRSI_OS        = 30.0;   // перепроданность
input bool                 FilterByBalanceRSI   = false;  // фильтр входа по RSI
input color                ColorBalanceRSI      = clrWhite;

input group "=== Sniper: Boundaries channel ==="
input bool                 ShowBoundariesChannel = false;
input int                  BoundariesLookback   = 48;     // баров для high/low канала
input color                ColorBoundaries      = clrSilver;
input bool                 PreferEntryInChannel = false;  // мягкий приоритет входа у границ

input group "=== Sniper: 10 Alerts ==="
input bool                 Alert_RM             = false;
input bool                 Alert_Pattern        = false;
input bool                 Alert_ZU             = false;
input bool                 Alert_PD             = false;
input bool                 Alert_Cascade        = false;
input bool                 Alert_Sight          = false;
input bool                 Alert_Session        = false;
input bool                 Alert_Entry          = true;  // ЕДИНСТВЕННЫЙ алерт по умолчанию
input bool                 Alert_Cancel         = false;
input bool                 Alert_MTF            = false;
input int                  AlertCooldownSec     = 30;     // антиспам

// Recalc mode (оптимально): % живой, сторона прицела — на закрытии бара
input bool                 DynamicProbability   = true;  // вероятность обновляется внутри бара
input bool                 SightRecalcOnBarCloseOnly = true; // сторона прицела не мигает внутри свечи
input double               SightCancelATR       = 2.5;   // снять прицел на CLOSE, если цена ушла > N*ATR (не внутри бара)
input int                  ContextUpdateSeconds = 1;     // период обновления вероятности (сек)
input bool                 SignalsOnlyOnBarClose = true; // стрелки A/B/C только по закрытию
input bool                 IntrabarMode         = false;
input int                  IntrabarSeconds      = 5;

//=========================
// Globals
//=========================

int      g_hEMA = INVALID_HANDLE;
int      g_hATR_Filter = INVALID_HANDLE;
int      g_hATR_Zone = INVALID_HANDLE;

datetime g_lastBarTime = 0;
datetime g_lastTradeBarTime = 0;
datetime g_lastSigA_time = 0;
datetime g_lastSigB_time = 0;
datetime g_lastSigC_time = 0;
datetime g_lastZoneInvalidationTime = 0;
uint     g_lastIntrabarExecMs = 0;
uint     g_lastContextExecMs = 0;
int      g_zoneSeq = 0;
bool     g_intrabarTimerSet = false; // timer for context and/or intrabar
bool     g_contextTimerOnly = false;

// Account environment (TZ 1.8): hedging is the target account type
bool     g_isHedging = true;

// Effective params after SymbolStrategyProfile / AUTO resolution (inputs are defaults for CUSTOM)
bool     g_EnableSignalA = true;
bool     g_EnableSignalB = true;
bool     g_EnableSignalC = true;
int      g_ATR_Min_Eff = 10;
int      g_MaxSpread_Eff = 20;
double   g_WickRatio_Eff = 2.0;
double   g_RangeMinATR_Mult_Eff = 0.0;
string   g_ProfileLogLine = "";

// Sniper runtime state (v2.0)
int      g_probHistory[];
int      g_lastProbability = 50; // история HUD: теперь индекс страха 0..100
int      g_lastFearIndex = 50;
int      g_lastSetupQuality = 50;
int      g_sightDirection = 0;   // 1 buy sight, -1 sell sight, 0 none
double   g_sightHigh = 0.0;
double   g_sightLow = 0.0;
double   g_sightAnchor = 0.0;    // якорь уровня; сторона не прыгает внутри бара
bool     g_sightActive = false;
int      g_sightDrawnDirection = 0; // что реально нарисовано (чтобы не мигать)
datetime g_sightUpdateBar = 0;

struct SSessionLevel
{
   string   name;
   datetime t_start;
   datetime t_end;
   datetime t_high;
   datetime t_low;
   double   high;
   double   low;
   color    clr;
   bool     valid;
};

struct SLiquidityZone
{
   bool     active;
   int      type;      // 1 supply (sell), -1 demand (buy)
   datetime t1;
   datetime t2;
   double   high;
   double   low;
   int      id;
};

SSessionLevel  g_sessions[];
SLiquidityZone g_liqZones[];
int            g_liqSeq = 0;

enum ENUM_STRUCT_KIND
{
   SK_NONE = 0,
   SK_ZU = 1,      // зона принятия решения (расширение)
   SK_PD = 2,      // зона отката (продолженное движение)
   SK_CASCADE = 3, // каскад
   SK_RM = 4,      // разворотный момент
   SK_GUD = 5      // глобальный уровень дисбаланса
};

// 12 именованных паттернов Снайпера (зеркала BUY/SELL через direction)
enum ENUM_SNIPER_PATTERN
{
   PAT_NONE = 0,
   PAT_PD_T1 = 1,            // 01 ПД тип 1 (≥30% коррекция + ретест)
   PAT_PD_T2 = 2,            // 02 ПД тип 2 (тест синего ≤6ч, без диапазонов)
   PAT_EXP_AFTER_PD = 3,     // 03 Расширение после ПД
   PAT_EXP_THROUGH_PD = 4,   // 04 Расширение через ПД
   PAT_EXP_THROUGH_LP = 5,   // 05 Расширение через ПД с ЛП
   PAT_EXP_CASCADE = 6,      // 06 Каскадное расширение
   PAT_CASC_1 = 7,           // 07 Каскад 1 (ретест верхней границы)
   PAT_CASC_2 = 8,           // 08 Каскад 2 (недоход до границы)
   PAT_CASC_3 = 9,           // 09 Каскад 3 (откат ≤50%, 2-й РМ)
   PAT_CASC_4 = 10,          // 10 Каскад 4 (откат ≥70%, продолжение)
   PAT_CASC_5 = 11,          // 11 Каскад 5 (второй бокс)
   PAT_CASC_6 = 12           // 12 Каскад 6 (глубокий ~150%)
};

enum ENUM_ALERT_TYPE
{
   ALT_RM = 1,        // Разворотный момент
   ALT_PATTERN = 2,   // Найден паттерн
   ALT_ZU = 3,        // Зона принятия решения
   ALT_PD = 4,        // Зона отката / ПД
   ALT_CASCADE = 5,   // Каскад
   ALT_SIGHT = 6,     // Прицел
   ALT_SESSION = 7,   // Сессионный уровень
   ALT_ENTRY = 8,     // Сигнал входа A/B/C
   ALT_CANCEL = 9,    // Паттерн отменён
   ALT_MTF = 10       // Совпадение M1+M15
};

struct SStructureZone
{
   bool     active;
   int      kind;       // ENUM_STRUCT_KIND
   int      pattern;    // ENUM_SNIPER_PATTERN
   int      direction;  // 1 buy, -1 sell
   datetime t1;
   datetime t2;
   double   high;
   double   low;
   double   range_x;    // длина импульса / движения (для %)
   double   pct;        // точный % (коррекция / пробой / откат)
   double   imp_start;  // начало импульса (Sniper Fib 100%)
   double   imp_end;    // конец импульса / экстремум (Sniper Fib 0%)
   string   label;
   string   tf_tag;     // "" | "M1" | "M15"
   int      id;
   bool     valid;      // false = отменён (напр. каскад >100%)
};

SStructureZone g_structZones[];
int            g_structSeq = 0;

// Безоткатный / продолженный ход (одна сторона, пока откат < 30% диапазона)
struct SContinuedMove
{
   bool     valid;
   bool     retraced_30; // откат ≥ 30% — можно искать вход
   bool     cancelled_50;
   int      dir;         // +1 рост → BUY на откате; -1 падение → SELL
   double   origin;      // 100% — начало хода
   double   tip;         // 0%  — экстремум, откуда пошёл откат
   datetime t_origin;
   datetime t_tip;
   int      i_tip;
   double   range;
   double   retrace_pct;
};

double g_lastImpulseRange = 0.0;
int    g_lastImpulseDir   = 0;

double MinContinuedMoveRange();
bool   FindContinuedMove(const MqlRates &rates[], SContinuedMove &m);
bool   BarHasReversalMoment(const datetime t, const int direction);
bool   PassPriceAction(const int direction, const MqlRates &bar, const MqlRates &prev);
bool   BarExtendsContinuedTip(const int dir, const MqlRates &bar, const MqlRates &prev, const double old_tip, const double atr);

int      g_pdT1Trades = 0;
datetime g_pdT1SpentTip = 0; // один сигнал/алерт тип1 на кончик Z

// Dual-TF / Balance RSI / alerts runtime
int      g_hRSI = INVALID_HANDLE;
double   g_boundHigh = 0.0;
double   g_boundLow = 0.0;
bool     g_boundActive = false;
int      g_lastSightDirAlert = 0;
datetime g_lastSessionAlertDay = 0;
string   g_alertLastKey = "";
datetime g_alertLastTime = 0;

datetime g_fib30_origin_t = 0;
double   g_fib30_price    = 0.0;
datetime g_fib30_t1       = 0;
datetime g_fib30_t2       = 0;
bool     g_fib30_have     = false;
bool     g_fib30_retraced = false;

// Forward declarations (MQL5: call sites before definitions)
string ShortTFName(const ENUM_TIMEFRAMES tf);
string PatternName(const int pat);
string AlertTypeName(const int t);
bool   AlertTypeEnabled(const int t);
void   FireSniperAlert(const int alert_type, const string detail);
bool   BalanceRSIAllows(const int direction);
bool   HasMTFConfluence(const int direction);
bool   DetectMTFConfluence(const int direction);
int    EffectiveSwingDepth();
int    EffectiveSafeStep1Points(const double entry, const double sl);
double ComputeSafeTpPrice(const int direction, const double entry, const double sl);
void   UpdateSniperStructures(const MqlRates &rates[]);
void   UpdateBalanceRSIPanel();
void   UpdateBoundariesChannel(const MqlRates &rates[]);

//=========================
// Structures
//=========================
struct SConsolidationZone
{
   bool     active;
   datetime start;
   datetime last_update;
   double   high;
   double   low;
   int      id;
   int      trades_done;
};

struct SBrokenZone
{
   bool     active;
   datetime start;
   datetime end;      // breakout close time (next bar open)
   double   high;
   double   low;
   int      id;
   int      direction; // 1 buy, -1 sell
   bool     retest_touched;
   datetime retest_touch_time;
   int      trades_done;
   int      bars_after_break;
};

struct SPCState
{
   ulong    ticket;
   double   initial_volume;
   int      flags; // bit0 = step1 done, bit1 = step2 done
};

SConsolidationZone g_zone;
SBrokenZone        g_broken;
SPCState           g_pc_states[];

//=========================
// Utilities
//=========================
string Prefix()
{
   return (CommentPrefix + "_");
}

// Convert datetime to a stable numeric string for object names.
// Using 64-bit formatting avoids potential warnings/overflows when casting datetime to int.
string TimeToObjectId(const datetime t)
{
   return StringFormat("%I64d", (long)t);
}

double PointValue()
{
   return SymbolInfoDouble(_Symbol, SYMBOL_POINT);
}

int DigitsValue()
{
   return (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
}

double NormalizePrice(const double price)
{
   return NormalizeDouble(price, DigitsValue());
}

int VolumeDigits()
{
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   int digits = 0;
   double tmp = step;
   while(digits < 8)
   {
      double r = MathRound(tmp);
      if(MathAbs(tmp - r) < 0.0000001)
         break;
      tmp *= 10.0;
      digits++;
   }
   return digits;
}

double NormalizeVolume(const double vol)
{
   int vd = VolumeDigits();
   return NormalizeDouble(vol, vd);
}

// alpha: 0..255 (int, чтобы не было warning int→uchar на вызовах с тернарником)
color ToARGB(const color c, const int alpha)
{
   uint a = (uint)MathMax(0, MathMin(255, alpha));
   uint r = (uint)c & 0xFF;
   uint g = ((uint)c >> 8) & 0xFF;
   uint b = ((uint)c >> 16) & 0xFF;
   return (color)((a << 24) | (b << 16) | (g << 8) | r);
}

// ink: 1 = свежая разметка, ~0.15 = едва заметный контур. false = уже не рисовать.
bool MarkInk(const datetime born, double &ink)
{
   ink = 1.0;
   if(!FadeOldMarkings || born <= 0)
      return true;
   datetime now = TimeCurrent();
   if(now <= born)
      return true;
   double hours = (double)(now - born) / 3600.0;
   if(MarkHideAfterHours > 0 && hours >= (double)MarkHideAfterHours)
      return false;
   if(MarkFadeAfterHours > 0 && hours > (double)MarkFadeAfterHours)
   {
      int span_h = MarkHideAfterHours - MarkFadeAfterHours;
      if(span_h < 1) span_h = 24;
      double t = (hours - (double)MarkFadeAfterHours) / (double)span_h;
      if(t < 0.0) t = 0.0;
      if(t > 1.0) t = 1.0;
      ink = 1.0 - 0.85 * t;
   }
   return true;
}

color InkColor(const color c, const double ink)
{
   if(ink >= 0.98)
      return c;
   int a = (int)(255.0 * ink);
   if(a < 22) a = 22;
   return ToARGB(c, a);
}

datetime DayFloor(const datetime t)
{
   MqlDateTime st;
   TimeToStruct(t, st);
   st.hour = 0;
   st.min  = 0;
   st.sec  = 0;
   return StructToTime(st);
}

color MixContrast50(const color c)
{
   color bg = (color)ChartGetInteger(0, CHART_COLOR_BACKGROUND);
   int r = ((int)((uint)c & 0xFF) + (int)((uint)bg & 0xFF)) / 2;
   int g = ((int)(((uint)c >> 8) & 0xFF) + (int)(((uint)bg >> 8) & 0xFF)) / 2;
   int b = ((int)(((uint)c >> 16) & 0xFF) + (int)(((uint)bg >> 16) & 0xFF)) / 2;
   return (color)((uint)r | ((uint)g << 8) | ((uint)b << 16));
}

// Spread in points
int CurrentSpreadPoints()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(ask <= 0 || bid <= 0)
      return 0;
   return (int)MathRound((ask - bid) / PointValue());
}

// База символа без суффикса брокера (EURUSD / XAUUSD / BTCUSD …)
string ChartSymbolBase()
{
   string s = _Symbol;
   StringToUpper(s);
   string majors[] = {"EURUSD","GBPUSD","USDJPY","USDCHF","XAUUSD","XAGUSD","BTCUSD","BTCUSDT","ETHUSD"};
   for(int i = 0; i < ArraySize(majors); i++)
   {
      if(StringFind(s, majors[i]) == 0)
         return majors[i];
   }
   if(StringFind(s, "GOLD") == 0)
      return "XAUUSD";
   if(StringFind(s, "BITCOIN") >= 0 || (StringLen(s) >= 3 && StringFind(s, "BTC") == 0))
      return "BTCUSD";
   // PreferredSymbol из пресета (если график ещё с суффиксом)
   string pref = PreferredSymbol;
   StringToUpper(pref);
   if(StringLen(pref) >= 6)
      return pref;
   return s;
}

// Размер «пункта» брокера POINT: 5/3 знака → pip=10×Point; иначе Point
double BrokerPipSize()
{
   double point = PointValue();
   int digits = DigitsValue();
   if(digits == 3 || digits == 5)
      return point * 10.0;
   return point;
}

// Типичный спред из docs/specifications-POINT.pdf (цена).
// FX/металлы — в пунктах брокера; BTC — 0,06% от цены.
double SpecTypicalSpreadPrice()
{
   string b = ChartSymbolBase();
   double pip = BrokerPipSize();
   double point = PointValue();
   if(b == "EURUSD") return 1.4 * pip;
   if(b == "GBPUSD") return 2.1 * pip;
   if(b == "USDJPY") return 2.0 * pip;
   if(b == "USDCHF") return 2.0 * pip;
   if(b == "XAUUSD") return 45.0 * point; // «другие инструменты»: 1 пункт = Point
   if(b == "XAGUSD") return 90.0 * point;
   if(b == "BTCUSD" || b == "BTCUSDT")
   {
      double px = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(px <= 0.0) px = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      return MathMax(point, px * 0.0006); // 0,06%
   }
   if(b == "ETHUSD")
   {
      double px = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(px <= 0.0) px = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      return MathMax(point, px * 0.0009); // 0,09%
   }
   return 0.0;
}

// Уровень limit&stop из спецификации POINT → цена
double SpecStopsLevelPrice()
{
   string b = ChartSymbolBase();
   double pip = BrokerPipSize();
   double point = PointValue();
   if(b == "EURUSD") return 0.7 * pip;
   if(b == "GBPUSD") return 1.1 * pip;
   if(b == "USDJPY") return 0.9 * pip;
   if(b == "USDCHF") return 1.0 * pip;
   if(b == "XAUUSD") return 25.0 * point;
   if(b == "XAGUSD") return 75.0 * point;
   return 0.0; // BTC и пр. в спеке = 0
}

// Рабочий спред для уровней: max(живой, типичный из POINT)
double EffectiveSpreadPrice()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double live = (ask > bid && bid > 0.0) ? (ask - bid) : 0.0;
   double spec = SpecTypicalSpreadPrice();
   return MathMax(live, spec);
}

void Log(const string msg)
{
   Print(CommentPrefix, ": ", msg);
}

void Notify(const string msg)
{
   Log(msg);

   if(AlertsMode == ALERTS_ONSCREEN)
      Alert(msg);
   else if(AlertsMode == ALERTS_PUSH)
      SendNotification(msg);
}

//=========================
// Init info (for audit / acceptance)
//=========================
void LogEnvironment()
{
   long term_build = TerminalInfoInteger(TERMINAL_BUILD);
   // NOTE: Some MT5/MetaEditor builds do not expose MQL_PROGRAM_BUILD via MQLInfoInteger.
   // To keep compilation portable and still log the compiler build, use __MQL5BUILD__ when available.
   long prog_build = 0;
#ifdef __MQL5BUILD__
   prog_build = (long)__MQL5BUILD__;
#endif

   ENUM_ACCOUNT_MARGIN_MODE mm = (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   g_isHedging = (mm == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);

   int digits = DigitsValue();
   double point = PointValue();

   double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vmax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double vstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   int stopLevel   = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   int freezeLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);

   Log(StringFormat("Init v%s | TerminalBuild=%I64d | ProgramBuild=%I64d | MarginMode=%s | Hedging=%s | Symbol=%s | TF=%s | Digits=%d | Point=%g | Vol(min/max/step)=%.2f/%.2f/%.2f | StopLevel=%d | FreezeLevel=%d",
                    EA_VERSION, term_build, prog_build, EnumToString(mm), (g_isHedging ? "true" : "false"), _Symbol, EnumToString(Timeframe), digits, point, vmin, vmax, vstep, stopLevel, freezeLevel));
   Log(StringFormat("POINT spread: live=%d pts | typical=%.5f | stopsSpec=%.5f | base=%s",
                    CurrentSpreadPoints(), SpecTypicalSpreadPrice(), SpecStopsLevelPrice(), ChartSymbolBase()));

   if(!g_isHedging)
      Log("WARNING: Account margin mode is not RETAIL_HEDGING. The EA is designed for hedging accounts (TZ 1.8). Trading/partial close behaviour may differ on netting accounts.");
}

//=========================
// Symbol strategy profile (Portfolio v1.09)
//=========================
string SymbolBaseOf(const string sym)
{
   string s = sym;
   StringToUpper(s);
   // типовые majors — сначала длинные совпадения
   string majors[] = {"EURUSD","GBPUSD","USDJPY","USDCHF","EURGBP","AUDUSD","USDCAD","NZDUSD","USDTRY","XAUUSD","XAGUSD","BTCUSDT","BTCUSD"};
   for(int i = 0; i < ArraySize(majors); i++)
   {
      if(StringFind(s, majors[i]) == 0)
         return majors[i];
   }
   int p = StringFind(s, ".");
   if(p > 0)
      return StringSubstr(s, 0, p);
   return s;
}

string GetSymbolBaseName()
{
   return SymbolBaseOf(_Symbol);
}

string PreferredSymbolBase()
{
   string pref = PreferredSymbol;
   StringTrimLeft(pref);
   StringTrimRight(pref);
   if(StringLen(pref) > 0)
      return SymbolBaseOf(pref);

   // если PreferredSymbol пуст — из профиля пресета
   if(SymbolStrategyProfile == PROFILE_EURUSD) return "EURUSD";
   if(SymbolStrategyProfile == PROFILE_GBPUSD) return "GBPUSD";
   if(SymbolStrategyProfile == PROFILE_USDJPY) return "USDJPY";
   if(SymbolStrategyProfile == PROFILE_USDCHF) return "USDCHF";

   // AUTO/CUSTOM без PreferredSymbol — не меняем инструмент
   return "";
}

bool SymbolMatchesPreferredBase(const string name, const string base)
{
   if(SymbolBaseOf(name) == base)
      return true;
   string u = name;
   StringToUpper(u);
   // Часть брокеров называет золото GOLD, а не XAUUSD.
   if(base == "XAUUSD" && StringFind(u, "GOLD") == 0)
      return true;
   return false;
}

string FindBrokerSymbolByBase(const string base_in)
{
   string base = SymbolBaseOf(base_in);
   if(StringLen(base) == 0)
      return "";

   // точное имя
   if(SymbolInfoInteger(base, SYMBOL_EXIST))
   {
      SymbolSelect(base, true);
      return base;
   }

   // текущий график уже тот же base
   if(SymbolMatchesPreferredBase(_Symbol, base))
      return _Symbol;

   // поиск среди символов терминала (с суффиксами брокера: EURUSDrfd, XAUUSDm, GOLD)
   int total = SymbolsTotal(false);
   for(int i = 0; i < total; i++)
   {
      string name = SymbolName(i, false);
      if(SymbolMatchesPreferredBase(name, base))
      {
         SymbolSelect(name, true);
         return name;
      }
   }
   return "";
}

// Подтянуть график под Timeframe + PreferredSymbol из пресета.
// ChartSetSymbolPeriod асинхронен → EA переинициализируется; на втором заходе уже совпадает.
bool TrySyncChartFromPreset()
{
   if(!SyncChartFromPreset)
      return false;

   ENUM_TIMEFRAMES want_tf = Timeframe;
   if(want_tf == PERIOD_CURRENT)
      want_tf = (ENUM_TIMEFRAMES)Period();

   string want_base = PreferredSymbolBase();
   string want_sym = _Symbol;
   if(StringLen(want_base) > 0)
   {
      string found = FindBrokerSymbolByBase(want_base);
      if(StringLen(found) == 0)
      {
         Log(StringFormat("SyncChart: символ базы %s не найден у брокера — ТФ сменим, инструмент оставим %s",
                          want_base, _Symbol));
      }
      else
         want_sym = found;
   }

   string cur_sym = ChartSymbol(0);
   ENUM_TIMEFRAMES cur_tf = (ENUM_TIMEFRAMES)ChartPeriod(0);

   bool same_sym = (SymbolBaseOf(cur_sym) == SymbolBaseOf(want_sym)) || (cur_sym == want_sym);
   bool same_tf = (cur_tf == want_tf);
   if(same_sym && same_tf)
      return false; // уже ок

   Log(StringFormat("SyncChart: %s %s → %s %s (из пресета)",
                    cur_sym, EnumToString(cur_tf), want_sym, EnumToString(want_tf)));

   ResetLastError();
   if(!ChartSetSymbolPeriod(0, want_sym, want_tf))
   {
      Log(StringFormat("SyncChart FAILED err=%d", GetLastError()));
      return false;
   }
   // Успех: терминал пересоздаст график/переинит EA — дальше тяжёлый OnInit не нужен
   return true;
}


ENUM_SYMBOL_PROFILE DetectProfileFromSymbol()
{
   string b = GetSymbolBaseName();
   if(b == "EURUSD")
      return PROFILE_EURUSD;
   if(b == "GBPUSD")
      return PROFILE_GBPUSD;
   if(b == "USDJPY")
      return PROFILE_USDJPY;
   if(b == "USDCHF")
      return PROFILE_USDCHF;
   return PROFILE_CUSTOM;
}

// v1.11: built-in profiles no longer hard-code filter values.
// All numeric filters (ATR_Min, MaxSpread, WickRatio, RangeMinATR_Mult)
// are taken from the .set input parameters so the user can tune them freely.
// The profile only selects which signal types (A/B/C) are enabled per pair.
void InitSymbolStrategyEffective()
{
   ENUM_SYMBOL_PROFILE prof = SymbolStrategyProfile;
   if(prof == PROFILE_AUTO)
      prof = DetectProfileFromSymbol();

   // Base values always come from the preset (.set) inputs — no hidden constants.
   g_EnableSignalA = EnableSignalA;
   g_EnableSignalB = EnableSignalB;
   g_EnableSignalC = EnableSignalC;
   g_ATR_Min_Eff = ATR_Min;
   g_MaxSpread_Eff = MaxSpread;
   g_WickRatio_Eff = WickRatio;
   g_RangeMinATR_Mult_Eff = RangeMinATR_Mult;

   switch(prof)
   {
      case PROFILE_EURUSD:
         g_EnableSignalA = true;
         g_EnableSignalB = true;
         g_EnableSignalC = true;
         g_ProfileLogLine = "profile=EURUSD (A+B+C; filters from .set)";
         break;
      case PROFILE_GBPUSD:
         g_EnableSignalA = true;
         g_EnableSignalB = true;
         g_EnableSignalC = true;
         g_ProfileLogLine = "profile=GBPUSD (A+B+C; filters from .set)";
         break;
      case PROFILE_USDJPY:
         g_EnableSignalA = true;
         g_EnableSignalB = false;
         g_EnableSignalC = true;
         g_ProfileLogLine = "profile=USDJPY (A+C, no B; filters from .set)";
         break;
      case PROFILE_USDCHF:
         g_EnableSignalA = true;
         g_EnableSignalB = false;
         g_EnableSignalC = true;
         g_ProfileLogLine = "profile=USDCHF (A+C, no B; filters from .set)";
         break;
      default:
         g_ProfileLogLine = "profile=CUSTOM/FALLBACK (all from .set)";
         break;
   }

   if(SymbolStrategyProfile == PROFILE_AUTO && prof != PROFILE_CUSTOM)
      g_ProfileLogLine = "AUTO " + g_ProfileLogLine;
}

//=========================
// Objects helpers
//=========================
void DeleteObjectsByPrefix(const string pfx)
{
   // Встроенный API надёжнее ручного цикла: все подокна и типы объектов.
   if(StringLen(pfx) > 0)
      ObjectsDeleteAll(0, pfx);
}

bool ObjExists(const string name)
{
   return (ObjectFind(0, name) >= 0);
}

// Create or update a horizontal line as OBJ_TREND (segment)
void DrawHLineSegment(const string name, datetime t1, datetime t2, double price, color clr, ENUM_LINE_STYLE style, int width, const string label)
{
   if(!ObjExists(name))
   {
      ObjectCreate(0, name, OBJ_TREND, 0, t1, price, t2, price);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, name, OBJPROP_RAY_LEFT, false);
   }
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);

   ObjectSetInteger(0, name, OBJPROP_TIME, 0, t1);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price);
   ObjectSetInteger(0, name, OBJPROP_TIME, 1, t2);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 1, price);

   if(label != "")
      ObjectSetString(0, name, OBJPROP_TEXT, label);
}

void DrawTrendSegment(const string name, datetime t1, double p1, datetime t2, double p2,
                      color clr, ENUM_LINE_STYLE style, int width)
{
   if(!ObjExists(name))
   {
      ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, name, OBJPROP_RAY_LEFT, false);
   }
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_TIME, 0, t1);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 0, p1);
   ObjectSetInteger(0, name, OBJPROP_TIME, 1, t2);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 1, p2);
}

void DrawText(const string name, datetime t, double price, const string text, color clr, ENUM_ANCHOR_POINT anchor)
{
   if(!ObjExists(name))
      ObjectCreate(0, name, OBJ_TEXT, 0, t, price);

   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);

   ObjectMove(0, name, 0, t, price);
}

void DrawArrow(const string name, datetime t, double price, bool isBuy, color clr)
{
   int arrow_code = isBuy ? 233 : 234; // Wingdings up/down
   if(!ObjExists(name))
      ObjectCreate(0, name, OBJ_ARROW, 0, t, price);

   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, arrow_code);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, MarkPreciseArrows ? 3 : 2);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, isBuy ? ANCHOR_TOP : ANCHOR_BOTTOM);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);

   ObjectMove(0, name, 0, t, price);
}

void DrawRect(const string name, datetime t1, double p1, datetime t2, double p2, color clr, bool back, bool fill)
{
   if(!ObjExists(name))
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, p1, t2, p2);

   ObjectSetInteger(0, name, OBJPROP_BACK, back);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_FILL, fill);

   ObjectMove(0, name, 0, t1, p1);
   ObjectMove(0, name, 1, t2, p2);
}

//=========================
// Indicator helpers
//=========================
bool GetBufferValue(const int handle, const int shift, double &value)
{
   if(handle == INVALID_HANDLE)
      return false;

   double buf[];
   ArraySetAsSeries(buf, true);
   int copied = CopyBuffer(handle, 0, shift, 1, buf);
   if(copied != 1)
      return false;

   value = buf[0];
   return true;
}

double MinContinuedMoveRange()
{
   double atr = 0.0;
   GetBufferValue(g_hATR_Filter, 1, atr);
   double by_atr = (atr > 0.0 && PD_MinImpulseATR > 0.0) ? PD_MinImpulseATR * atr : 0.0;
   double by_pts = (PD_MinImpulsePoints > 0) ? (double)PD_MinImpulsePoints * PointValue() : 0.0;
   double m = MathMax(by_atr, by_pts);
   if(m <= 0.0)
      m = 50.0 * PointValue();
   return m;
}

double SeedContinuedMoveRange()
{
   double atr = 0.0;
   GetBufferValue(g_hATR_Filter, 1, atr);
   double seed = (atr > 0.0) ? 0.40 * atr : 10.0 * PointValue();
   return MathMax(5.0 * PointValue(), seed);
}

bool ImpulseQualified(const double range, const int bars)
{
   if(range <= MinContinuedMoveRange())
      return false;
   if(bars < MathMax(2, PD_MinImpulseBars))
      return false;
   return true;
}

bool FindContinuedMove(const MqlRates &rates[], SContinuedMove &m)
{
   m.valid = false;
   m.retraced_30 = false;
   m.cancelled_50 = false;
   m.dir = 0;
   m.origin = 0.0;
   m.tip = 0.0;
   m.t_origin = 0;
   m.t_tip = 0;
   m.i_tip = 0;
   m.range = 0.0;
   m.retrace_pct = 0.0;
   g_lastImpulseRange = 0.0;
   g_lastImpulseDir   = 0;

   const int nr = ArraySize(rates);
   if(nr < 30)
      return false;

   const double complete_need = MathMax(0.08, PD_CompletePullbackPct / 100.0);
   const double retrace_on = MathMax(complete_need, PD_MinCorrectionPct / 100.0);
   const double cancel_at = MathMax(retrace_on + 0.05, PD_CancelRetracePct / 100.0);
   const int look = MathMin(nr, MathMax(50, StructureLookbackBars));
   const int oldest = look - 1;
   const double seed = SeedContinuedMoveRange();

   int dir = 0;
   double origin = 0.0, tip = 0.0;
   datetime t_origin = 0, t_tip = 0;
   int i_origin = oldest, i_tip = oldest;
   double run_hi = rates[oldest].high, run_lo = rates[oldest].low;
   datetime t_run_hi = rates[oldest].time, t_run_lo = rates[oldest].time;
   int i_run_hi = oldest, i_run_lo = oldest;

   bool have = false;
   double show_o = 0.0, show_t = 0.0;
   datetime show_ot = 0, show_tt = 0;
   double show_range = 0.0;
   int show_dir = 0, show_itip = 0;

   for(int i = oldest - 1; i >= 1; i--)
   {
      const double h = rates[i].high;
      const double l = rates[i].low;
      const datetime tm = rates[i].time;

      if(dir == 0)
      {
         if(h > run_hi) { run_hi = h; t_run_hi = tm; i_run_hi = i; }
         if(l < run_lo) { run_lo = l; t_run_lo = tm; i_run_lo = i; }
         if(run_hi - run_lo <= seed)
            continue;
         if(t_run_hi >= t_run_lo)
         {
            dir = 1;
            origin = run_lo; t_origin = t_run_lo; i_origin = i_run_lo;
            tip = run_hi;    t_tip = t_run_hi;    i_tip = i_run_hi;
         }
         else
         {
            dir = -1;
            origin = run_hi; t_origin = t_run_hi; i_origin = i_run_hi;
            tip = run_lo;    t_tip = t_run_lo;    i_tip = i_run_lo;
         }
         continue;
      }

      // Внутри ещё идущего импульса tip едет по high/low. Фильтр close —
      // только после фиксации кончика (см. цикл продления ниже).
      if(dir < 0)
      {
         if(l < tip)
         {
            tip = l; t_tip = tm; i_tip = i;
            continue;
         }
      }
      else
      {
         if(h > tip)
         {
            tip = h; t_tip = tm; i_tip = i;
            continue;
         }
      }

      const double size = MathAbs(origin - tip);
      if(size < seed * 0.5)
         continue;
      const double pb = (dir > 0) ? ((tip - l) / size) : ((h - tip) / size);
      if(pb < complete_need)
         continue;

      const bool qual = ImpulseQualified(size, MathAbs(i_origin - i_tip) + 1);
      if(qual)
      {
         bool take = true;
         if(have && dir != show_dir && show_range > PointValue())
         {
            const double parent_retrace = (show_dir > 0)
                                          ? ((show_t - tip) / show_range)
                                          : ((tip - show_t) / show_range);
            // Встречный кусок внутри 50% родителя — коррекция, не новый ход.
            if(parent_retrace + 1.0e-8 < cancel_at)
               take = false;
         }
         if(take)
         {
            show_o = origin; show_ot = t_origin;
            show_t = tip;    show_tt = t_tip;
            show_range = size;
            show_dir = dir;
            show_itip = i_tip;
            have = true;
         }
      }
      else if(pb < cancel_at)
      {
         // Откат 20% от ещё не импульса — не разворачивать: иначе большой ход
         // режется на шум, а на графике остаётся предыдущий (уже отменённый) кусок.
         continue;
      }

      if(dir < 0)
      {
         dir = 1;
         origin = tip; t_origin = t_tip; i_origin = i_tip;
         tip = h;      t_tip = tm;       i_tip = i;
      }
      else
      {
         dir = -1;
         origin = tip; t_origin = t_tip; i_origin = i_tip;
         tip = l;      t_tip = tm;       i_tip = i;
      }
   }

   bool live_ok = (dir != 0 && ImpulseQualified(MathAbs(origin - tip), MathAbs(i_origin - i_tip) + 1));

   if(have)
   {
      m.valid = true;
      m.dir = show_dir;
      m.origin = show_o;
      m.tip = show_t;
      m.t_origin = show_ot;
      m.t_tip = show_tt;
      m.i_tip = show_itip;
      m.range = show_range;
   }
   else if(live_ok)
   {
      m.valid = true;
      m.dir = dir;
      m.origin = origin;
      m.tip = tip;
      m.t_origin = t_origin;
      m.t_tip = t_tip;
      m.i_tip = i_tip;
      m.range = MathAbs(origin - tip);
   }
   else
      return false;

   // После кончика: закрытие за экстремумом или сильная свеча по ходу — продлить.
   // Хвост у доджи/разворота — ложный пробой, tip и «30» не двигаем.
   for(int i = m.i_tip - 1; i >= 1; i--)
   {
      double atr_i = 0.0;
      GetBufferValue(g_hATR_Filter, i, atr_i);
      MqlRates prevb = rates[(i + 1 < nr) ? (i + 1) : i];
      if(m.dir > 0 && rates[i].high > m.tip && BarExtendsContinuedTip(1, rates[i], prevb, m.tip, atr_i))
      {
         m.tip = rates[i].high;
         m.i_tip = i;
         m.t_tip = rates[i].time;
         m.range = MathAbs(m.origin - m.tip);
      }
      else if(m.dir < 0 && rates[i].low < m.tip && BarExtendsContinuedTip(-1, rates[i], prevb, m.tip, atr_i))
      {
         m.tip = rates[i].low;
         m.i_tip = i;
         m.t_tip = rates[i].time;
         m.range = MathAbs(m.origin - m.tip);
      }
   }

   double ext_h = m.tip, ext_l = m.tip;
   for(int i = m.i_tip - 1; i >= 1; i--)
   {
      if(rates[i].high > ext_h) ext_h = rates[i].high;
      if(rates[i].low  < ext_l) ext_l = rates[i].low;
   }
   if(m.range > PointValue())
   {
      if(m.dir > 0)
         m.retrace_pct = 100.0 * (m.tip - ext_l) / m.range;
      else
         m.retrace_pct = 100.0 * (ext_h - m.tip) / m.range;
   }
   m.retraced_30 = (m.retrace_pct + 1.0e-8 >= retrace_on * 100.0);
   m.cancelled_50 = (m.retrace_pct + 1.0e-8 >= cancel_at * 100.0);

   // Отменённый 50% ход нельзя оставлять «рабочим», даже если новый live ещё без 20%.
   if(m.cancelled_50)
   {
      if(!live_ok || t_origin == show_ot)
         return false;
      m.dir = dir;
      m.origin = origin;
      m.tip = tip;
      m.t_origin = t_origin;
      m.t_tip = t_tip;
      m.i_tip = i_tip;
      m.range = MathAbs(origin - tip);
      m.retraced_30 = false;
      m.cancelled_50 = false;
      m.retrace_pct = 0.0;
      ext_h = m.tip;
      ext_l = m.tip;
      for(int i = m.i_tip - 1; i >= 1; i--)
      {
         if(rates[i].high > ext_h) ext_h = rates[i].high;
         if(rates[i].low  < ext_l) ext_l = rates[i].low;
      }
      if(m.range > PointValue())
      {
         if(m.dir > 0)
            m.retrace_pct = 100.0 * (m.tip - ext_l) / m.range;
         else
            m.retrace_pct = 100.0 * (ext_h - m.tip) / m.range;
      }
      m.retraced_30 = (m.retrace_pct + 1.0e-8 >= retrace_on * 100.0);
      m.cancelled_50 = (m.retrace_pct + 1.0e-8 >= cancel_at * 100.0);
      if(m.cancelled_50)
         return false;
   }

   g_lastImpulseRange = m.range;
   g_lastImpulseDir   = m.dir;
   return true;
}

//=========================
// Partial close tracking
//=========================

// Resolve the initial position volume using trade history.
//
// Motivation:
// - MT5 Position properties provide current volume (POSITION_VOLUME), but there is no POSITION_VOLUME_INITIAL.
// - To keep PartialClose (2 steps) stable on hedging accounts after EA restart, we restore the initial
//   volume from the first entry deal of the position (DEAL_ENTRY_IN / DEAL_ENTRY_INOUT).
//
// IMPORTANT: This function is called only when the EA needs to initialize partial-close state for an
//            already existing position (no cached state). It should not be executed on every tick.
double GetPositionInitialVolumeByHistory(const ulong position_id,
                                        const datetime position_time,
                                        const double fallback_current_volume)
{
   if(position_id == 0)
      return fallback_current_volume;

   datetime to = TimeCurrent();
   datetime from = 0;
   if(position_time > 0)
   {
      // Narrow the selected range to reduce HistorySelect overhead.
      // We only need the earliest entry deal for the given position id.
      from = position_time - 86400 * 7; // 7 days back from open time
      if(from < 0)
         from = 0;
   }

   if(!HistorySelect(from, to))
      return fallback_current_volume;

   int deals = HistoryDealsTotal();
   double best_vol = 0.0;
   datetime best_time = 0;

   for(int i = 0; i < deals; i++)
   {
      ulong dt = HistoryDealGetTicket(i);
      if(dt == 0)
         continue;

      long pid = HistoryDealGetInteger(dt, DEAL_POSITION_ID);
      if((ulong)pid != position_id)
         continue;

      long entry = HistoryDealGetInteger(dt, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_IN && entry != DEAL_ENTRY_INOUT)
         continue;

      double vol = HistoryDealGetDouble(dt, DEAL_VOLUME);
      if(vol <= 0.0)
         continue;

      datetime t = (datetime)HistoryDealGetInteger(dt, DEAL_TIME);
      if(best_time == 0 || t < best_time)
      {
         best_time = t;
         best_vol = vol;
      }
   }

   if(best_vol > 0.0)
      return best_vol;

   return fallback_current_volume;
}
int FindPCIndex(const ulong ticket)
{
   int total = ArraySize(g_pc_states);
   for(int i = 0; i < total; i++)
      if(g_pc_states[i].ticket == ticket)
         return i;
   return -1;
}

// Ensure partial-close state for a position.
// Returns the state index.
//
// NOTE (TZ 1.8 / 4.5): to keep hedging + partial close behaviour robust,
// we also try to restore PC step flags when EA is (re)attached and positions already exist.
int EnsurePCState(const ulong ticket, const double initial_volume, const double current_volume)
{
   int idx = FindPCIndex(ticket);
   if(idx >= 0)
      return idx;

   int n = ArraySize(g_pc_states);
   ArrayResize(g_pc_states, n + 1);
   g_pc_states[n].ticket = ticket;
   g_pc_states[n].initial_volume = initial_volume;
   g_pc_states[n].flags = 0;

   // Restore step flags if the position is already partially closed (e.g., EA restart).
   // This prevents double partial-closing the remaining volume.
   double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(vmin > 0.0 && step > 0.0 && current_volume > 0.0 && initial_volume > 0.0)
   {
      // Restore only if volume is materially smaller than initial.
      if((current_volume + step * 0.25) < initial_volume)
      {
         double eps = step * 0.5001;

         // expected remaining after step1
         double remain_after1 = initial_volume;
         if(PC_Vol1 > 0.0)
         {
            double close1 = initial_volume * PC_Vol1;
            close1 = MathMin(close1, initial_volume - vmin);
            close1 = MathFloor(close1 / step) * step;
            close1 = NormalizeVolume(close1);
            remain_after1 = initial_volume - close1;

            if(current_volume <= remain_after1 + eps)
               g_pc_states[n].flags |= 1;
         }

         // expected remaining after step2 (using the same logic as ManagePositions)
         double base_vol = ((g_pc_states[n].flags & 1) != 0) ? remain_after1 : initial_volume;
         if(PC_Vol2 > 0.0 && base_vol > (vmin + step * 0.25))
         {
            double close2 = initial_volume * PC_Vol2;
            close2 = MathMin(close2, base_vol - vmin);
            close2 = MathFloor(close2 / step) * step;
            close2 = NormalizeVolume(close2);
            double remain_after2 = base_vol - close2;

            if(current_volume <= remain_after2 + eps)
               g_pc_states[n].flags |= 2;
         }
      }
   }

   return n;
}

void RemovePCStateByIndex(const int idx)
{
   int n = ArraySize(g_pc_states);
   if(idx < 0 || idx >= n)
      return;

   for(int i = idx; i < n - 1; i++)
      g_pc_states[i] = g_pc_states[i + 1];

   ArrayResize(g_pc_states, n - 1);
}

//=========================
// Trading (raw requests to support hedging)
//=========================
ENUM_ORDER_TYPE_FILLING GetFillingMode()
{
   long mode = 0;
   if(SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE, mode))
      return (ENUM_ORDER_TYPE_FILLING)mode;
   return ORDER_FILLING_FOK;
}

// OrderSend helper: try to recover from broker-specific filling mode restrictions.
// This is a точечная (non-architectural) reliability fix for MT5 execution.
bool OrderSendWithFillingFallback(MqlTradeRequest &req, MqlTradeResult &res)
{
   // Try requested filling mode first, then common alternatives.
   ENUM_ORDER_TYPE_FILLING candidates[4] = { req.type_filling, ORDER_FILLING_FOK, ORDER_FILLING_IOC, ORDER_FILLING_RETURN };

   for(int i = 0; i < 4; i++)
   {
      // Skip duplicates to avoid redundant OrderSend calls.
      bool dup = false;
      for(int j = 0; j < i; j++)
      {
         if(candidates[j] == candidates[i])
         {
            dup = true;
            break;
         }
      }
      if(dup)
         continue;

      req.type_filling = candidates[i];
      ZeroMemory(res);
      ResetLastError();
      bool ok = OrderSend(req, res);
      if(!ok)
         continue;

      // If the broker rejects the filling mode, try the next one.
      if(res.retcode == TRADE_RETCODE_INVALID_FILL)
         continue;

      return true;
   }

   return false;
}

bool SendDeal(const int direction, const double volume, const double sl, const double tp, const string comment, ulong &deal_out)
{
   if(volume <= 0)
      return false;

   MqlTradeRequest req;
   MqlTradeResult  res;
   ZeroMemory(req);
   ZeroMemory(res);

   req.action      = TRADE_ACTION_DEAL;
   req.symbol      = _Symbol;
   req.magic       = MagicNumber;
   req.volume      = volume;
   req.deviation   = (uint)Slippage;
   req.type_time   = ORDER_TIME_GTC;
   req.type_filling= GetFillingMode();
   req.comment     = comment;

   req.type = (direction > 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

   req.sl = sl;
   req.tp = tp;

   // Startup reliability: the first signal after terminal launch may hit transient trade context/price readiness issues.
   // Retry several times on temporary errors so a valid first signal is not lost as "no deal".
   const int max_attempts = 6;
   for(int attempt = 1; attempt <= max_attempts; attempt++)
   {
      // Environmental checks INSIDE the retry loop: terminal connection and trade permissions
      // may not be ready on the very first tick after a cold start, but will stabilise quickly.
      if(!TerminalInfoInteger(TERMINAL_CONNECTED) ||
         !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) ||
         !MQLInfoInteger(MQL_TRADE_ALLOWED))
      {
         Log(StringFormat("Trade environment not ready (attempt %d/%d): "
                          "connected=%d trade_allowed=%d mql_allowed=%d, retrying",
                          attempt, max_attempts,
                          (int)TerminalInfoInteger(TERMINAL_CONNECTED),
                          (int)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED),
                          (int)MQLInfoInteger(MQL_TRADE_ALLOWED)));
         if(attempt < max_attempts)
            Sleep(400);
         continue;
      }

      req.price = (direction > 0) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(req.price <= 0.0)
      {
         MqlTick t;
         if(SymbolInfoTick(_Symbol, t))
            req.price = (direction > 0) ? t.ask : t.bid;
      }
      req.price = NormalizePrice(req.price);
      if(req.price <= 0.0)
      {
         Log(StringFormat("OrderSend attempt %d/%d skipped: no valid market price yet", attempt, max_attempts));
         if(attempt < max_attempts)
            Sleep(200);
         continue;
      }

      bool ok = OrderSendWithFillingFallback(req, res);
      if(ok && (res.retcode == TRADE_RETCODE_DONE || res.retcode == TRADE_RETCODE_DONE_PARTIAL))
      {
         deal_out = res.deal;
         return true;
      }

      bool transient =
         (res.retcode == TRADE_RETCODE_REQUOTE ||
          res.retcode == TRADE_RETCODE_PRICE_CHANGED ||
          res.retcode == TRADE_RETCODE_PRICE_OFF ||
          res.retcode == TRADE_RETCODE_CONNECTION ||
          res.retcode == TRADE_RETCODE_TIMEOUT ||
          res.retcode == TRADE_RETCODE_TOO_MANY_REQUESTS ||
          res.retcode == TRADE_RETCODE_SERVER_DISABLES_AT ||
          res.retcode == TRADE_RETCODE_CLIENT_DISABLES_AT ||
          res.retcode == TRADE_RETCODE_LOCKED);

      // Retry both transient OrderSend return codes AND complete OrderSend failures.
      // A complete failure (ok==false) is common right after terminal startup when the
      // trade context is still initialising (no valid connection/symbol yet).
      if(attempt < max_attempts && (transient || !ok))
      {
         string reason = !ok ? "OrderSend() failed" : StringFormat("retcode=%d (%s)", (int)res.retcode, res.comment);
         Log(StringFormat("OrderSend transient issue (attempt %d/%d): %s, retrying",
                          attempt, max_attempts, reason));
         Sleep(400);
         continue;
      }

      if(!ok)
      {
         string extra = (res.retcode != 0 ? StringFormat(", retcode=%d (%s)", (int)res.retcode, res.comment) : "");
         Log("OrderSend() failed" + extra + ", error=" + IntegerToString(GetLastError()));
      }
      else
      {
         Log(StringFormat("Deal rejected retcode=%d (%s)", (int)res.retcode, res.comment));
      }
      return false;
   }

   return false;
}

bool SendPositionSLTP(const ulong position_ticket, const double sl, const double tp)
{
   MqlTradeRequest req;
   MqlTradeResult  res;
   ZeroMemory(req);
   ZeroMemory(res);

   req.action   = TRADE_ACTION_SLTP;
   req.symbol   = _Symbol;
   req.position = position_ticket;
   req.magic    = MagicNumber;
   req.sl       = sl;
   req.tp       = tp;

   bool ok = OrderSend(req, res);
   if(!ok)
   {
      Log("SLTP OrderSend() failed, error=" + IntegerToString(GetLastError()));
      return false;
   }

   if(res.retcode != TRADE_RETCODE_DONE)
   {
      Log(StringFormat("SLTP rejected retcode=%d (%s)", (int)res.retcode, res.comment));
      return false;
   }

   return true;
}

bool ClosePositionPartial(const ulong position_ticket, const int position_type, const double volume, const string comment)
{
   if(volume <= 0)
      return false;

   MqlTradeRequest req;
   MqlTradeResult  res;
   ZeroMemory(req);
   ZeroMemory(res);

   req.action      = TRADE_ACTION_DEAL;
   req.symbol      = _Symbol;
   req.position    = position_ticket;
   req.magic       = MagicNumber;
   req.volume      = volume;
   req.deviation   = (uint)Slippage;
   req.type_time   = ORDER_TIME_GTC;
   req.type_filling= GetFillingMode();
   req.comment     = comment;

   if(position_type == POSITION_TYPE_BUY)
   {
      req.type  = ORDER_TYPE_SELL;
      req.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   }
   else
   {
      req.type  = ORDER_TYPE_BUY;
      req.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   }

   bool ok = OrderSendWithFillingFallback(req, res);
   if(!ok)
   {
      string extra = (res.retcode != 0 ? StringFormat(", retcode=%d (%s)", (int)res.retcode, res.comment) : "");
      Log("Partial close OrderSend() failed" + extra + ", error=" + IntegerToString(GetLastError()));
      return false;
   }

   if(res.retcode != TRADE_RETCODE_DONE && res.retcode != TRADE_RETCODE_DONE_PARTIAL)
   {
      Log(StringFormat("Partial close rejected retcode=%d (%s)", (int)res.retcode, res.comment));
      return false;
   }

   return true;
}

//=========================
// Risk / volume
//=========================
double ClampVolume(const double vol)
{
   double v = vol;
   double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vmax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   // Cold-start protection: symbol specification may not be loaded yet.
   // Retry once with a small delay before giving up.
   if(vmin <= 0.0 || vmax <= 0.0 || step <= 0.0)
   {
      Log(StringFormat("ClampVolume: symbol volume limits not ready (min=%.5f max=%.5f step=%.5f), retrying...", vmin, vmax, step));
      Sleep(500);
      vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      vmax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   }

   if(vmin <= 0.0 || vmax <= 0.0 || step <= 0.0)
   {
      Log(StringFormat("ClampVolume: invalid symbol volume limits (min=%.5f max=%.5f step=%.5f)", vmin, vmax, step));
      return 0.0;
   }

   if(v <= 0)
      return 0.0;

   v = MathMax(vmin, MathMin(vmax, v));
   v = MathFloor(v / step) * step;
   v = NormalizeVolume(v);

   if(v < vmin)
      v = vmin;

   return v;
}

double CalcLotByRiskPercent(const double risk_percent, const double sl_points)
{
   if(risk_percent <= 0.0 || sl_points <= 0.0)
      return 0.0;

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(balance <= 0.0)
      return 0.0;

   double risk_money = balance * risk_percent / 100.0;

   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   // Cold-start protection: symbol trade properties may not be loaded yet.
   if(tick_value <= 0.0 || tick_size <= 0.0)
   {
      Log(StringFormat("CalcLotByRiskPercent: tick data not ready (tick_value=%.5f tick_size=%.5f), retrying...", tick_value, tick_size));
      Sleep(500);
      tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   }

   if(tick_value <= 0.0 || tick_size <= 0.0)
   {
      Log(StringFormat("CalcLotByRiskPercent: invalid tick data (tick_value=%.5f tick_size=%.5f)", tick_value, tick_size));
      return 0.0;
   }

   double value_per_point_per_lot = (tick_value / tick_size) * PointValue();
   double risk_per_lot = sl_points * value_per_point_per_lot;

   if(risk_per_lot <= 0.0)
      return 0.0;

   double lot = risk_money / risk_per_lot;
   return ClampVolume(lot);
}

//=========================
// Filters / patterns
//=========================
bool IsEngulfingPattern(const int direction, const MqlRates &bar, const MqlRates &prev)
{
   bool is_buy = (direction > 0);
   if(is_buy)
   {
      bool bullish = (bar.close > bar.open);
      bool prev_bear = (prev.close < prev.open);
      bool engulf = (bar.open <= prev.close && bar.close >= prev.open);
      return (bullish && prev_bear && engulf);
   }
   bool bearish = (bar.close < bar.open);
   bool prev_bull = (prev.close > prev.open);
   bool engulf = (bar.open >= prev.close && bar.close <= prev.open);
   return (bearish && prev_bull && engulf);
}

bool IsOutsideBarPattern(const int direction, const MqlRates &bar, const MqlRates &prev)
{
   bool outside = (bar.high > prev.high && bar.low < prev.low);
   if(!outside)
      return false;
   if(direction > 0)
      return (bar.close > bar.open && bar.close >= prev.high);
   return (bar.close < bar.open && bar.close <= prev.low);
}

bool IsPinBarPattern(const int direction, const MqlRates &bar)
{
   double p = PointValue();
   double range = bar.high - bar.low;
   if(range < p * 3.0)
      return false;

   double body = MathAbs(bar.close - bar.open);
   if(body < p)
      body = p;

   double upper = bar.high - MathMax(bar.open, bar.close);
   double lower = MathMin(bar.open, bar.close) - bar.low;

   // Pin-bar / rejection: длинная тень в сторону ложного пробоя, маленькое тело
   if(direction > 0)
   {
      // бычий пин: длинная нижняя тень, закрытие в верхней половине
      bool long_wick = (lower >= 2.0 * body) && (lower >= 0.55 * range);
      bool close_high = (bar.close >= (bar.low + 0.55 * range));
      return (long_wick && close_high);
   }
   bool long_wick = (upper >= 2.0 * body) && (upper >= 0.55 * range);
   bool close_low = (bar.close <= (bar.high - 0.55 * range));
   return (long_wick && close_low);
}

bool BarLooksLikeStopOrReversalAgainst(const int impulse_dir, const MqlRates &bar, const MqlRates &prev, const double atr)
{
   const int fade = (impulse_dir > 0) ? -1 : 1;
   const double body = MathAbs(bar.close - bar.open);
   const double stall_max = MathMax(0.0, RM_StallBodyATR_Max) * MathMax(atr, 8.0 * PointValue());
   if(body <= stall_max)
      return true;
   if(IsPinBarPattern(fade, bar))
      return true;
   if(IsEngulfingPattern(fade, bar, prev))
      return true;
   if(IsOutsideBarPattern(fade, bar, prev))
      return true;
   return false;
}

bool BarExtendsContinuedTip(const int dir, const MqlRates &bar, const MqlRates &prev, const double old_tip, const double atr)
{
   // Продлеваем tip только подтверждённым закрытием за экстремумом.
   // Хвост за tip при close внутри/обратно — ложный пробой, Z не двигаем
   // (раньше «не доджи по ATR» ошибочно продлевал tip, как на close 1.32121 при tip 1.32115).
   if(dir > 0)
      return (bar.close > old_tip);
   return (bar.close < old_tip);
}

string DetectPatternName(const int direction, const MqlRates &bar, const MqlRates &prev)
{
   if(IsPinBarPattern(direction, bar))
      return "Пин-бар";
   if(IsEngulfingPattern(direction, bar, prev))
      return "Поглощение";
   if(IsOutsideBarPattern(direction, bar, prev))
      return "Внешний бар";
   return "";
}

bool ConfirmCandlePattern(const int direction, const MqlRates &bar, const MqlRates &prev)
{
   if(ConfirmPattern == CP_OFF)
      return true;

   if(ConfirmPattern == CP_ENGULFING)
      return IsEngulfingPattern(direction, bar, prev);

   if(ConfirmPattern == CP_OUTSIDEBAR)
      return IsOutsideBarPattern(direction, bar, prev);

   if(ConfirmPattern == CP_PINBAR)
      return IsPinBarPattern(direction, bar);

   if(ConfirmPattern == CP_SNIPER)
      return (IsPinBarPattern(direction, bar) ||
              IsEngulfingPattern(direction, bar, prev) ||
              IsOutsideBarPattern(direction, bar, prev));

   return true;
}

bool BarHasReversalMoment(const datetime t, const int direction)
{
   if(t <= 0)
      return false;
   for(int i = 0; i < ArraySize(g_structZones); i++)
   {
      if(g_structZones[i].kind != SK_RM || !g_structZones[i].valid)
         continue;
      if(g_structZones[i].t1 != t)
         continue;
      if(direction != 0 && g_structZones[i].direction != direction)
         continue;
      return true;
   }
   return false;
}

bool PassPriceAction(const int direction, const MqlRates &bar, const MqlRates &prev)
{
   if(BarHasReversalMoment(bar.time, direction))
      return true;
   return ConfirmCandlePattern(direction, bar, prev);
}

bool PassSightAlignmentForBreakout(const int direction, string &why)
{
   why = "";
   if(!AlignBreakoutWithSight)
      return true;
   if(!g_sightActive || g_sightDirection == 0)
      return true;
   if(g_sightDirection != direction)
   {
      why = "blocked: A против прицела";
      return false;
   }
   return true;
}

bool PassEMAFiltro(const int direction, const MqlRates &signal_bar)
{
   if(EMA_Period <= 0)
      return true;

   if(g_hEMA == INVALID_HANDLE)
      return true;

   // Base mode: use the last closed bar (shift=1).
   // Intrabar mode: if the signal bar is the current forming bar, shift=0 is allowed.
   // EMA_MODE_BARCLOSE must stay deterministic even in IntrabarMode (use shift=1).
   datetime cur_bar_time = iTime(_Symbol, Timeframe, 0);
   const bool is_current_bar = (cur_bar_time > 0 && signal_bar.time == cur_bar_time);

   int shift_for_ema = 1;
   if(IntrabarMode && is_current_bar && EMA_FilterMode != EMA_MODE_BARCLOSE)
      shift_for_ema = 0;

   double ema = 0.0;
   if(!GetBufferValue(g_hEMA, shift_for_ema, ema))
      return true; // fail-open (no block)

   double price_check = signal_bar.close;

   if(EMA_FilterMode == EMA_MODE_PRICE)
   {
      // Current price (for intrabar discretionary style)
      price_check = (direction > 0) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                                    : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   }
   else if(EMA_FilterMode == EMA_MODE_BARCLOSE)
   {
      // Deterministic meaning: use the close of the last completed bar when working intrabar
      if(IntrabarMode && is_current_bar)
      {
         double last_close = iClose(_Symbol, Timeframe, 1);
         if(last_close > 0.0)
            price_check = last_close;
      }
      else
      {
         price_check = signal_bar.close;
      }
   }
   else // EMA_MODE_CLOSE
   {
      // Close of the signal bar (in intrabar mode - the current close so far)
      price_check = signal_bar.close;
   }

   if(direction > 0)
      return (price_check > ema);
   else
      return (price_check < ema);
}

bool PassATRFiltro(const MqlRates &signal_bar)
{
   if(g_hATR_Filter == INVALID_HANDLE)
      return true;

   bool use_atr_min = (g_ATR_Min_Eff > 0);
   bool use_range_min = (g_RangeMinATR_Mult_Eff > 0.0);

   if(!use_atr_min && !use_range_min)
      return true;

   int shift_for_atr = 1; // base mode: last closed bar
   datetime cur_bar_time = iTime(_Symbol, Timeframe, 0);
   if(IntrabarMode && cur_bar_time > 0 && signal_bar.time == cur_bar_time)
      shift_for_atr = 0;

   double atr = 0.0;
   if(!GetBufferValue(g_hATR_Filter, shift_for_atr, atr))
      return true; // fail-open

   if(use_atr_min)
   {
      double atr_min_price = g_ATR_Min_Eff * PointValue();
      if(atr < atr_min_price)
         return false;
   }

   if(use_range_min)
   {
      double range = signal_bar.high - signal_bar.low;
      double min_range = g_RangeMinATR_Mult_Eff * atr;
      if(range < min_range)
         return false;
   }

   return true;
}

//=========================
// Session / reward-risk (v1.09)
//=========================
bool PassServerSession()
{
   if(!UseServerSession)
      return true;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int h = dt.hour;

   if(SessionStartHour == SessionEndHour)
      return true;

   if(SessionStartHour < SessionEndHour)
      return (h >= SessionStartHour && h < SessionEndHour);

   return (h >= SessionStartHour || h < SessionEndHour);
}

double SlDistancePoints(const int direction, const double entry, const double sl)
{
   if(sl <= 0.0)
      return 0.0;

   double d = (direction > 0) ? (entry - sl) : (sl - entry);
   if(d <= 0.0)
      return 0.0;

   return d / PointValue();
}

double TpDistancePoints(const int direction, const double entry, const double tp)
{
   if(tp <= 0.0)
      return 0.0;

   double d = (direction > 0) ? (tp - entry) : (entry - tp);
   if(d <= 0.0)
      return 0.0;

   return d / PointValue();
}

bool PassMinRewardToRisk(const int direction, const double entry, const double sl, const double tp)
{
   if(MinRewardToRisk <= 0.0)
      return true;

   if(sl <= 0.0 || tp <= 0.0)
      return true;

   double sl_pts = SlDistancePoints(direction, entry, sl);
   double tp_pts = TpDistancePoints(direction, entry, tp);
   if(sl_pts <= 0.0 || tp_pts <= 0.0)
      return false;

   return ((tp_pts / sl_pts) >= MinRewardToRisk);
}

//=========================
// Position helpers
//=========================
int CountMyPositions()
{
   int count = 0;
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      if((long)PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;

      count++;
   }
   return count;
}

//=========================
// Stops validation
//=========================
void AdjustStopsToBroker(const int direction, double entry_price, double &sl, double &tp)
{
   double point = PointValue();
   int stops_level = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double min_dist = stops_level * point;
   // Спека POINT (limit&stop) — нижняя граница, если брокер в терминале отдаёт 0
   double spec_min = SpecStopsLevelPrice();
   if(spec_min > min_dist)
      min_dist = spec_min;
   // + спред: стоп/тейк не ближе, чем спред + stops
   double spr = EffectiveSpreadPrice();
   if(spr > 0.0)
      min_dist = MathMax(min_dist, spr);

   // Safety: even if broker reports 0 StopLevel, keep at least 1 point distance to avoid invalid SL/TP
   if(min_dist < point)
      min_dist = point;

   // Note: if stops_level==0 broker may still have freeze levels, we ignore for base.

   if(direction > 0)
   {
      if(sl > 0.0 && (entry_price - sl) < min_dist)
         sl = entry_price - min_dist;
      if(tp > 0.0 && (tp - entry_price) < min_dist)
         tp = entry_price + min_dist;
   }
   else
   {
      if(sl > 0.0 && (sl - entry_price) < min_dist)
         sl = entry_price + min_dist;
      if(tp > 0.0 && (entry_price - tp) < min_dist)
         tp = entry_price - min_dist;
   }

   sl = (sl > 0.0) ? NormalizePrice(sl) : 0.0;
   tp = (tp > 0.0) ? NormalizePrice(tp) : 0.0;
}

//=========================
// Day levels
//=========================
datetime DayStartTime(const datetime t)
{
   MqlDateTime dt;
   TimeToStruct(t, dt);

   // shift day start
   dt.hour = DayStartHour;
   dt.min = 0;
   dt.sec = 0;
   datetime start = StructToTime(dt);

   // if current time is before the start hour, start is previous day
   if(t < start)
      start -= 24 * 60 * 60;

   return start;
}

bool CalcDayHighLow(const datetime day_start, const datetime day_end, double &high, double &low, double &open_price)
{
   high = -DBL_MAX;
   low = DBL_MAX;
   open_price = 0.0;

   MqlRates rates[];
   ArraySetAsSeries(rates, false);

   int copied = CopyRates(_Symbol, Timeframe, day_start, day_end, rates);
   if(copied <= 0)
      return false;

   open_price = rates[0].open;

   for(int i = 0; i < copied; i++)
   {
      if(rates[i].high > high) high = rates[i].high;
      if(rates[i].low < low) low = rates[i].low;
   }

   return (high > -DBL_MAX && low < DBL_MAX);
}

void DrawDayLevels(const datetime now_time)
{
   datetime today_start = DayStartTime(now_time);
   datetime today_end   = now_time;

   double hod=0, lod=0, openp=0;
   bool have_today = false;

   // In deterministic (bar-close) processing, day levels should be based on completed bars.
   // now_time is the open time of the current bar; exclude it from the CopyRates time window.
   // Special case: first bar of the day (now_time == today_start) has no completed bars yet.
   // In this case set HOD/LOD to the day open to keep determinism (TZ 1.2 / 4.1).
   if(today_end > today_start)
   {
      today_end = (datetime)(today_end - 1);
      have_today = CalcDayHighLow(today_start, today_end, hod, lod, openp);
   }
   else
   {
      openp = iOpen(_Symbol, Timeframe, 0);
      hod = openp;
      lod = openp;
      have_today = (openp > 0.0);
   }

   if(have_today)
   {
      double bal = BalanceUseOpenPrice ? openp : (hod + lod) / 2.0;

      int sec = PeriodSeconds(Timeframe);
      datetime t2 = today_start + (ShowLevelsLenBars > 0 ? (datetime)(ShowLevelsLenBars * sec) : (datetime)(sec * 500));

      datetime lbl_t = t2;
      datetime near_right = now_time + (datetime)(sec * 2);
      if(t2 > now_time && near_right < t2)
         lbl_t = near_right;

      string n1 = Prefix() + "HOD_CUR";
      string n2 = Prefix() + "LOD_CUR";
      string n3 = Prefix() + "BAL_CUR";

      DrawHLineSegment(n1, today_start, t2, hod, ColorHOD, STYLE_DOT, 1, "Макс дня");
      DrawHLineSegment(n2, today_start, t2, lod, ColorLOD, STYLE_DOT, 1, "Мин дня");
      DrawHLineSegment(n3, today_start, t2, bal, ColorBalance, STYLE_SOLID, 1, "Баланс");

      // visible labels near the right edge
      DrawText(Prefix() + "LBL_HOD_CUR", lbl_t, hod + 3*PointValue(), "Макс дня", ColorHOD, ANCHOR_LEFT_LOWER);
      DrawText(Prefix() + "LBL_LOD_CUR", lbl_t, lod - 3*PointValue(), "Мин дня", ColorLOD, ANCHOR_LEFT_UPPER);
      DrawText(Prefix() + "LBL_BAL_CUR", lbl_t, bal + 3*PointValue(), "Баланс", ColorBalance, ANCHOR_LEFT_LOWER);
   }

   if(UsePrevDayLevels)
   {
      datetime prev_start = today_start - 24*60*60;
      // Exclude the first bar of the current day from the previous day window.
      datetime prev_end = (datetime)(today_start - 1);

      double ph=0, pl=0, pop=0;
      if(CalcDayHighLow(prev_start, prev_end, ph, pl, pop))
      {
         double pbal = BalanceUseOpenPrice ? pop : (ph + pl) / 2.0;
         int sec = PeriodSeconds(Timeframe);
         datetime t2 = prev_start + (ShowLevelsLenBars > 0 ? (datetime)(ShowLevelsLenBars * sec) : (datetime)(sec * 500));

         datetime lbl_t = t2;

         // Try to keep labels near the current chart right edge when the line extends into the present
         datetime near_right = now_time + (datetime)(sec * 2);
         if(t2 > now_time && near_right < t2)
            lbl_t = near_right;

         string n1 = Prefix() + "HOD_PREV";
         string n2 = Prefix() + "LOD_PREV";
         string n3 = Prefix() + "BAL_PREV";
         double ink = 1.0;
         if(!MarkInk(prev_start, ink))
         {
            if(ObjExists(n1)) ObjectDelete(0, n1);
            if(ObjExists(n2)) ObjectDelete(0, n2);
            if(ObjExists(n3)) ObjectDelete(0, n3);
            if(ObjExists(Prefix() + "LBL_HOD_PREV")) ObjectDelete(0, Prefix() + "LBL_HOD_PREV");
            if(ObjExists(Prefix() + "LBL_LOD_PREV")) ObjectDelete(0, Prefix() + "LBL_LOD_PREV");
            if(ObjExists(Prefix() + "LBL_BAL_PREV")) ObjectDelete(0, Prefix() + "LBL_BAL_PREV");
         }
         else
         {
            DrawHLineSegment(n1, prev_start, t2, ph, InkColor(ColorHOD, ink), STYLE_DOT, 1, "");
            DrawHLineSegment(n2, prev_start, t2, pl, InkColor(ColorLOD, ink), STYLE_DOT, 1, "");
            DrawHLineSegment(n3, prev_start, t2, pbal, InkColor(ColorBalance, ink), STYLE_DOT, 1, "");
            if(ink >= 0.45)
            {
               DrawText(Prefix() + "LBL_HOD_PREV", lbl_t, ph + 3*PointValue(), "Макс вчера", InkColor(ColorHOD, ink), ANCHOR_LEFT_LOWER);
               DrawText(Prefix() + "LBL_LOD_PREV", lbl_t, pl - 3*PointValue(), "Мин вчера", InkColor(ColorLOD, ink), ANCHOR_LEFT_UPPER);
               DrawText(Prefix() + "LBL_BAL_PREV", lbl_t, pbal + 3*PointValue(), "Баланс вчера", InkColor(ColorBalance, ink), ANCHOR_LEFT_LOWER);
            }
            else
            {
               if(ObjExists(Prefix() + "LBL_HOD_PREV")) ObjectDelete(0, Prefix() + "LBL_HOD_PREV");
               if(ObjExists(Prefix() + "LBL_LOD_PREV")) ObjectDelete(0, Prefix() + "LBL_LOD_PREV");
               if(ObjExists(Prefix() + "LBL_BAL_PREV")) ObjectDelete(0, Prefix() + "LBL_BAL_PREV");
            }
         }
      }
   }
}

//=========================
// Consolidation zone detection
//=========================
bool CalcHighLowWindow(const MqlRates &rates[], const int start_shift, const int bars, double &high, double &low)
{
   high = -DBL_MAX;
   low = DBL_MAX;

   int total = ArraySize(rates);
   if(start_shift + bars > total)
      return false;

   for(int i = start_shift; i < start_shift + bars; i++)
   {
      if(rates[i].high > high) high = rates[i].high;
      if(rates[i].low < low) low = rates[i].low;
   }

   return (high > -DBL_MAX && low < DBL_MAX);
}

bool IsConsolidation(const MqlRates &rates[], double &zone_high, double &zone_low)
{
   if(CZ_LookbackN <= 1)
      return false;

   if(!CalcHighLowWindow(rates, 1, CZ_LookbackN, zone_high, zone_low))
      return false;

   double range = zone_high - zone_low;

   double atr = 0.0;
   if(!GetBufferValue(g_hATR_Zone, 1, atr))
      return false;

   if(atr <= 0.0)
      return false;

   return (range <= CZ_ATR_K * atr);
}

void DrawZoneObject(const SConsolidationZone &z, const bool broken, const datetime right_time)
{
   if(!ShowZones)
      return;

   string name = Prefix() + "CZ_" + IntegerToString(z.id);

   datetime t1 = z.start;
   datetime t2 = right_time;

   if(broken)
      t2 = right_time; // end at breakout time

   double ink = 1.0;
   if(broken && !MarkInk(z.start, ink))
   {
      if(ObjExists(name)) ObjectDelete(0, name);
      string rn_old = Prefix() + "CZ_REACT_" + IntegerToString(z.id);
      if(ObjExists(rn_old)) ObjectDelete(0, rn_old);
      return;
   }
   color clr = broken ? ColorZoneBroken : ColorZoneActive;
   color fill = ToARGB(clr, (int)(40.0 * (broken ? ink : 1.0)));

   DrawRect(name, t1, z.high, t2, z.low, fill, true, true);

   // Reaction line: nearest boundary to current price
   string rn = Prefix() + "CZ_REACT_" + IntegerToString(z.id);

   if(broken)
   {
      // For compliance with TZ 1.1 (highlight only active zone), do not keep reaction line on broken zones
      if(ObjExists(rn))
         ObjectDelete(0, rn);
      return;
   }
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double react = 0.0;
   if(price > z.high) react = z.high;
   else if(price < z.low) react = z.low;
   else
   {
      // inside: show nearest boundary (expected reaction)
      double dist_high = z.high - price;
      double dist_low  = price - z.low;
      react = (dist_high <= dist_low) ? z.high : z.low;
   }

   datetime rl_t2 = t2;
   if(!broken)
   {
      int sec = PeriodSeconds(Timeframe);
      rl_t2 = t2 + (datetime)(sec * 50);
   }

   DrawHLineSegment(rn, t1, rl_t2, react, ColorReactLine, ReactLineStyle, ReactLineWidth, "");
}

//=========================
// Swing line
//=========================
struct SPivot
{
   datetime t;
   double   p;
   int      type; // 1 high, -1 low
};

string SpeedPresetName()
{
   if(SpeedPreset == SPEED_SCALP)  return "SCALP";
   if(SpeedPreset == SPEED_CALM)   return "CALM";
   if(SpeedPreset == SPEED_SWING)  return "SWING";
   return "CUSTOM";
}

int EffectiveSwingDepth()
{
   // Sniper-Pro: глубина max/min = скорость. Работает на ЛЮБОМ символе одинаково.
   // Смена SpeedPreset / IndicatorSpeed в Inputs → OK → OnInit → полная перерисовка.
   int d = (SpeedPreset == SPEED_CUSTOM) ? IndicatorSpeed : (int)SpeedPreset;
   if(d < 2) d = 2;
   if(d > 60) d = 60;
   return d;
}

bool IsPivotHigh(const MqlRates &rates[], const int shift, const int depth)
{
   double h = rates[shift].high;
   for(int i = shift - depth; i <= shift + depth; i++)
   {
      if(i < 0 || i >= ArraySize(rates))
         continue;
      if(rates[i].high > h)
         return false;
   }
   return true;
}

bool IsPivotLow(const MqlRates &rates[], const int shift, const int depth)
{
   double l = rates[shift].low;
   for(int i = shift - depth; i <= shift + depth; i++)
   {
      if(i < 0 || i >= ArraySize(rates))
         continue;
      if(rates[i].low < l)
         return false;
   }
   return true;
}

int BuildPivotsFractals(const MqlRates &rates[], SPivot &out_pivots[], const int max_pivots)
{
   int total = ArraySize(rates);
   if(total < 10)
      return 0;


   SPivot pivots_tmp[];
   ArrayResize(pivots_tmp, 0);

   // scan from old to new: shift decreases
   for(int shift = total - 3; shift >= 2; shift--)
   {
      bool high = true;
      bool low  = true;
      double h = rates[shift].high;
      double l = rates[shift].low;
      for(int k = -2; k <= 2; k++)
      {
         if(k == 0) continue;
         int s = shift + k;
         if(s < 0 || s >= total) continue;
         if(rates[s].high > h) high = false;
         if(rates[s].low < l)  low = false;
      }

      if(high)
      {
         int n = ArraySize(pivots_tmp);
         ArrayResize(pivots_tmp, n + 1);
         pivots_tmp[n].t = rates[shift].time;
         pivots_tmp[n].p = h;
         pivots_tmp[n].type = 1;
      }
      if(low)
      {
         int n = ArraySize(pivots_tmp);
         ArrayResize(pivots_tmp, n + 1);
         pivots_tmp[n].t = rates[shift].time;
         pivots_tmp[n].p = l;
         pivots_tmp[n].type = -1;
      }
   }

   // sort by time ascending (old -> new)
   int nall = ArraySize(pivots_tmp);
   if(nall <= 0)
      return 0;

   for(int i = 0; i < nall - 1; i++)
      for(int j = i + 1; j < nall; j++)
         if(pivots_tmp[i].t > pivots_tmp[j].t)
         {
            SPivot tmp = pivots_tmp[i];
            pivots_tmp[i] = pivots_tmp[j];
            pivots_tmp[j] = tmp;
         }

   // reduce consecutive same-type pivots
   SPivot reduced[];
   ArrayResize(reduced, 0);
   for(int i = 0; i < nall; i++)
   {
      int rn = ArraySize(reduced);
      if(rn == 0)
      {
         ArrayResize(reduced, 1);
         reduced[0] = pivots_tmp[i];
         continue;
      }

      if(reduced[rn - 1].type == pivots_tmp[i].type)
      {
         // keep more extreme
         if(pivots_tmp[i].type == 1)
         {
            if(pivots_tmp[i].p >= reduced[rn - 1].p)
               reduced[rn - 1] = pivots_tmp[i];
         }
         else
         {
            if(pivots_tmp[i].p <= reduced[rn - 1].p)
               reduced[rn - 1] = pivots_tmp[i];
         }
      }
      else
      {
         ArrayResize(reduced, rn + 1);
         reduced[rn] = pivots_tmp[i];
      }
   }

   // take last max_pivots
   int rn = ArraySize(reduced);
   int start = MathMax(0, rn - max_pivots);
   int out_n = 0;
   for(int i = start; i < rn; i++)
   {
      if(out_n >= max_pivots)
         break;
      out_pivots[out_n] = reduced[i];
      out_n++;
   }

   return out_n;
}

int BuildPivotsZigZagLike(const MqlRates &rates[], SPivot &out_pivots[], const int max_pivots)
{
   int total = ArraySize(rates);
   if(total < (ZZ_Depth * 2 + 10))
      return 0;

   int depth = MathMax(2, MathMax(ZZ_Depth, EffectiveSwingDepth()));
   double dev = ZZ_Deviation * PointValue();
   int back = MathMax(1, ZZ_Backstep);

   // candidates
   int candHigh[];
   int candLow[];
   ArrayResize(candHigh, 0);
   ArrayResize(candLow, 0);

   for(int shift = total - depth - 1; shift >= depth; shift--)
   {
      if(IsPivotHigh(rates, shift, depth))
      {
         int n = ArraySize(candHigh);
         ArrayResize(candHigh, n + 1);
         candHigh[n] = shift;
      }
      if(IsPivotLow(rates, shift, depth))
      {
         int n = ArraySize(candLow);
         ArrayResize(candLow, n + 1);
         candLow[n] = shift;
      }
   }

   // apply backstep: for highs
   for(int i = 0; i < ArraySize(candHigh); i++)
   {
      int s1 = candHigh[i];
      for(int j = i + 1; j < ArraySize(candHigh); j++)
      {
         int s2 = candHigh[j];
         if(MathAbs(s1 - s2) <= back)
         {
            if(rates[s2].high >= rates[s1].high)
            {
               // drop s1
               candHigh[i] = -1;
               break;
            }
            else
            {
               candHigh[j] = -1;
            }
         }
      }
   }

   // apply backstep: for lows
   for(int i = 0; i < ArraySize(candLow); i++)
   {
      int s1 = candLow[i];
      for(int j = i + 1; j < ArraySize(candLow); j++)
      {
         int s2 = candLow[j];
         if(MathAbs(s1 - s2) <= back)
         {
            if(rates[s2].low <= rates[s1].low)
            {
               candLow[i] = -1;
               break;
            }
            else
            {
               candLow[j] = -1;
            }
         }
      }
   }

   // merge to pivots list, ordered by time (old -> new)
   SPivot pivots_tmp[];
   ArrayResize(pivots_tmp, 0);

   for(int i = 0; i < ArraySize(candHigh); i++)
   {
      if(candHigh[i] < 0) continue;
      int s = candHigh[i];
      int n = ArraySize(pivots_tmp);
      ArrayResize(pivots_tmp, n + 1);
      pivots_tmp[n].t = rates[s].time;
      pivots_tmp[n].p = rates[s].high;
      pivots_tmp[n].type = 1;
   }
   for(int i = 0; i < ArraySize(candLow); i++)
   {
      if(candLow[i] < 0) continue;
      int s = candLow[i];
      int n = ArraySize(pivots_tmp);
      ArrayResize(pivots_tmp, n + 1);
      pivots_tmp[n].t = rates[s].time;
      pivots_tmp[n].p = rates[s].low;
      pivots_tmp[n].type = -1;
   }

   int nall = ArraySize(pivots_tmp);
   if(nall <= 0)
      return 0;

   // sort by time ascending
   for(int i = 0; i < nall - 1; i++)
      for(int j = i + 1; j < nall; j++)
         if(pivots_tmp[i].t > pivots_tmp[j].t)
         {
            SPivot tmp = pivots_tmp[i];
            pivots_tmp[i] = pivots_tmp[j];
            pivots_tmp[j] = tmp;
         }

   // enforce alternating pivots + deviation
   SPivot reduced[];
   ArrayResize(reduced, 0);

   for(int i = 0; i < nall; i++)
   {
      int rn = ArraySize(reduced);
      if(rn == 0)
      {
         ArrayResize(reduced, 1);
         reduced[0] = pivots_tmp[i];
         continue;
      }

      SPivot last = reduced[rn - 1];

      if(last.type == pivots_tmp[i].type)
      {
         // replace by more extreme
         if(last.type == 1)
         {
            if(pivots_tmp[i].p >= last.p)
               reduced[rn - 1] = pivots_tmp[i];
         }
         else
         {
            if(pivots_tmp[i].p <= last.p)
               reduced[rn - 1] = pivots_tmp[i];
         }
      }
      else
      {
         // deviation check
         if(MathAbs(pivots_tmp[i].p - last.p) >= dev)
         {
            ArrayResize(reduced, rn + 1);
            reduced[rn] = pivots_tmp[i];
         }
      }
   }

   int rn = ArraySize(reduced);
   int start = MathMax(0, rn - max_pivots);
   int out_n = 0;
   for(int i = start; i < rn; i++)
   {
      if(out_n >= max_pivots)
         break;
      out_pivots[out_n] = reduced[i];
      out_n++;
   }

   return out_n;
}

void UpdateSwingLine(const MqlRates &rates[])
{
   if(!ShowSwingLine)
      return;

   // remove previous swing objects
   string pfx = Prefix() + "SWL_";
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, pfx) == 0)
         ObjectDelete(0, name);
   }

   SPivot pivots[200];
   int max_piv = 60;
   int piv_n = 0;

   if(SwingMode == SWING_FRACTALS)
      piv_n = BuildPivotsFractals(rates, pivots, max_piv);
   else
      piv_n = BuildPivotsZigZagLike(rates, pivots, max_piv);

   if(piv_n < 2)
      return;

   // draw last segments
   for(int i = 0; i < piv_n - 1; i++)
   {
      string name = pfx + IntegerToString(i);
      double ink = 1.0;
      if(!MarkInk(pivots[i + 1].t, ink))
         continue;
      ObjectCreate(0, name, OBJ_TREND, 0, pivots[i].t, pivots[i].p, pivots[i + 1].t, pivots[i + 1].p);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, name, OBJPROP_RAY_LEFT, false);
      ObjectSetInteger(0, name, OBJPROP_COLOR, InkColor(ColorSwingLine, ink));
      ObjectSetInteger(0, name, OBJPROP_STYLE, SwingLineStyle);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, SwingLineWidth);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   }
}

//=========================
// Signal visualization
//=========================
void ClearSignalObjectsIfNeeded()
{
   if(KeepSignalHistory)
      return;

   string pfx = Prefix() + "SIG_";
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, pfx) == 0)
         ObjectDelete(0, name);
   }
}

void VisualizeSignal(const string sig, const int direction, const MqlRates &bar, const double entry, const double sl, const double tp, const string status, const string chart_note)
{
   if(!ShowEntryMarker)
      return;

   ClearSignalObjectsIfNeeded();

   color c = (direction > 0) ? ColorBuyMarker : ColorSellMarker;
   color fill = ToARGB(c, 40);
   // Текст крупнее и темнее маркера — на белом фоне Lime/Tomato плохо читаются.
   const bool warn = (StringFind(chart_note, "против") >= 0 || StringFind(chart_note, "запрещает") >= 0);
   color title_c = (direction > 0) ? clrDarkGreen : clrMaroon;
   color note_c = warn ? clrFireBrick : ((direction > 0) ? clrNavy : clrDarkRed);

   double atr = 0.0;
   GetBufferValue(g_hATR_Filter, 1, atr);
   const double pad = MathMax(12.0 * PointValue(), (atr > 0.0 ? 0.12 * atr : 20.0 * PointValue()));

   int sec = PeriodSeconds(Timeframe);
   datetime t1 = bar.time;
   datetime t2 = bar.time + (datetime)sec;

   string base = Prefix() + "SIG_" + TimeToObjectId(bar.time) + "_" + sig;

   DrawRect(base + "_R", t1, bar.high, t2, bar.low, fill, true, true);
   ObjectSetString(0, base + "_R", OBJPROP_TOOLTIP, "ink:" + IntegerToString((int)c));

   string tip = (direction > 0) ? ("▲ " + sig + " BUY") : ("▼ " + sig + " SELL");
   double text_price = (direction > 0) ? (bar.low - pad) : (bar.high + pad);
   DrawText(base + "_T", t1, text_price, tip, title_c,
            (direction > 0) ? ANCHOR_UPPER : ANCHOR_LOWER);
   ObjectSetString(0, base + "_T", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, base + "_T", OBJPROP_FONTSIZE, 13);
   ObjectSetInteger(0, base + "_T", OBJPROP_ZORDER, 92);
   ObjectSetString(0, base + "_T", OBJPROP_TOOLTIP, "ink:" + IntegerToString((int)title_c));

   if(ShowArrows)
   {
      double arrow_price = (direction > 0)
         ? (bar.low - 1.6 * pad)
         : (bar.high + 1.6 * pad);
      DrawArrow(base + "_A", t1, arrow_price, (direction > 0), c);
      ObjectSetInteger(0, base + "_A", OBJPROP_WIDTH, 4);
      ObjectSetInteger(0, base + "_A", OBJPROP_ZORDER, 93);
      ObjectSetString(0, base + "_A", OBJPROP_TOOLTIP, "ink:" + IntegerToString((int)c));
   }

   if(StringLen(chart_note) > 0)
   {
      double note_price = (direction > 0) ? (bar.low - 2.8 * pad) : (bar.high + 2.8 * pad);
      DrawText(base + "_N", t1, note_price, chart_note, note_c,
               (direction > 0) ? ANCHOR_UPPER : ANCHOR_LOWER);
      ObjectSetString(0, base + "_N", OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, base + "_N", OBJPROP_FONTSIZE, 11);
      ObjectSetInteger(0, base + "_N", OBJPROP_ZORDER, 92);
      ObjectSetString(0, base + "_N", OBJPROP_TOOLTIP, "ink:" + IntegerToString((int)note_c));
   }

   // Горизонтали SL и ТП по Сейфу сразу со стрелкой (спред уже в BuildSLTP / ComputeSafeTpPrice)
   if(ShowEntrySLTPLines)
   {
      datetime ray = t1 + (datetime)(sec * MathMax(12, SightBarsWidth));
      double safe_tp = ComputeSafeTpPrice(direction, entry, sl);
      if(sl > 0.0)
      {
         DrawHLineSegment(base + "_SL", t1, ray, sl, clrCrimson, STYLE_DASH, 2, "SL");
         DrawText(base + "_SL_T", ray, sl, "SL", clrCrimson, ANCHOR_LEFT_UPPER);
         ObjectSetInteger(0, base + "_SL_T", OBJPROP_FONTSIZE, 9);
         ObjectSetInteger(0, base + "_SL_T", OBJPROP_ZORDER, 94);
      }
      if(safe_tp > 0.0)
      {
         DrawHLineSegment(base + "_SAFE", t1, ray, safe_tp, clrForestGreen, STYLE_DASH, 2, "Сейф");
         DrawText(base + "_SAFE_T", ray, safe_tp, "Сейф ТП", clrForestGreen, ANCHOR_LEFT_UPPER);
         ObjectSetInteger(0, base + "_SAFE_T", OBJPROP_FONTSIZE, 9);
         ObjectSetInteger(0, base + "_SAFE_T", OBJPROP_ZORDER, 94);
      }
   }
}

void PrunePastDecisionMarks()
{
   if(KeepSignalHistory)
      return;
   datetime keep_from = iTime(_Symbol, Timeframe, 1);
   if(keep_from <= 0)
      keep_from = iTime(_Symbol, Timeframe, 0);
   if(keep_from <= 0)
      return;
   const string pfx = Prefix() + "SIG_";
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, pfx) != 0)
         continue;
      datetime t = (datetime)ObjectGetInteger(0, name, OBJPROP_TIME, 0);
      if(t > 0 && t < keep_from)
         ObjectDelete(0, name);
   }
}

void AgeSignalObjects()
{
   if(!FadeOldMarkings)
      return;
   string pfx = Prefix() + "SIG_";
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, pfx) != 0)
         continue;
      datetime t = (datetime)ObjectGetInteger(0, name, OBJPROP_TIME, 0);
      double ink = 1.0;
      if(!MarkInk(t, ink))
      {
         ObjectDelete(0, name);
         continue;
      }
      if(ink >= 0.98)
         continue;
      if((StringFind(name, "_T") >= 0 || StringFind(name, "_N") >= 0) && ink < 0.45)
      {
         ObjectDelete(0, name);
         continue;
      }
      string tip = ObjectGetString(0, name, OBJPROP_TOOLTIP);
      color base = ColorBuyMarker;
      if(StringFind(tip, "ink:") == 0)
         base = (color)StringToInteger(StringSubstr(tip, 4));
      ObjectSetInteger(0, name, OBJPROP_COLOR, InkColor(base, ink));
   }
}


//=========================
// Sniper v2.0: helpers
//=========================
void DeleteObjectsWithPrefix(const string pfx)
{
   DeleteObjectsByPrefix(pfx);
}

void CleanupChartGraphics()
{
   // Текущий префикс + запасной «Acteck_» (если CommentPrefix меняли в Inputs).
   DeleteObjectsByPrefix(Prefix());
   if(Prefix() != "Acteck_")
      DeleteObjectsByPrefix("Acteck_");
   Comment("");
   ChartRedraw(0);
}

int NormalizeHour(const int h)
{
   int x = h % 24;
   if(x < 0) x += 24;
   return x;
}

int SessionDurationSeconds(const int start_h, const int end_h)
{
   int s = NormalizeHour(start_h);
   int e = NormalizeHour(end_h);
   if(s == e) return 24 * 3600;
   if(s < e) return (e - s) * 3600;
   return (24 - s + e) * 3600;
}

datetime SessionEndFromStart(const datetime t_start, const int start_h, const int end_h)
{
   return t_start + (datetime)SessionDurationSeconds(start_h, end_h);
}


bool HourInWindow(const int hour, const int start_h, const int end_h)
{
   int s = NormalizeHour(start_h);
   int e = NormalizeHour(end_h);
   int h = NormalizeHour(hour);
   if(s == e) return true; // full day
   if(s < e) return (h >= s && h < e);
   return (h >= s || h < e); // overnight
}

datetime SessionWindowStart(const datetime ref_time, const int start_h, const int end_h)
{
   MqlDateTime dt;
   TimeToStruct(ref_time, dt);
   dt.min = 0; dt.sec = 0;
   int h = dt.hour;
   int s = NormalizeHour(start_h);
   int e = NormalizeHour(end_h);

   // Find the most recent session start that has already begun relative to ref_time.
   datetime day0 = ref_time - (datetime)(dt.hour * 3600 + dt.min * 60 + dt.sec);
   datetime cand = day0 + (datetime)(s * 3600);

   if(s < e)
   {
      if(h < s)
         cand -= 86400; // previous day session
      return cand;
   }

   // overnight window, e.g. 22-06: if before end hour, session started previous day
   if(h < e)
      cand -= 86400;
   else if(h < s)
      cand -= 86400;
   return cand;
}

bool CalcSessionHL(const datetime t_start, const datetime t_end,
                   datetime &t_high, datetime &t_low, double &hi, double &lo)
{
   MqlRates r[];
   ArraySetAsSeries(r, true);
   int copied = CopyRates(_Symbol, Timeframe, t_start, t_end, r);
   if(copied < 2)
      return false;

   hi = -DBL_MAX;
   lo = DBL_MAX;
   t_high = 0;
   t_low = 0;
   for(int i = 0; i < copied; i++)
   {
      // CopyRates with from/to may include bars outside exact window; filter by time.
      if(r[i].time < t_start || r[i].time >= t_end)
         continue;
      if(r[i].high > hi) { hi = r[i].high; t_high = r[i].time; }
      if(r[i].low < lo)  { lo = r[i].low;  t_low  = r[i].time; }
   }
   return (hi > -DBL_MAX && lo < DBL_MAX && t_high > 0 && t_low > 0);
}

void PushSession(const string name, const color clr,
                 const datetime t_start, const datetime t_end,
                 const datetime t_high, const datetime t_low,
                 const double hi, const double lo)
{
   int n = ArraySize(g_sessions);
   ArrayResize(g_sessions, n + 1);
   g_sessions[n].name = name;
   g_sessions[n].clr = clr;
   g_sessions[n].t_start = t_start;
   g_sessions[n].t_end = t_end;
   g_sessions[n].t_high = t_high;
   g_sessions[n].t_low = t_low;
   g_sessions[n].high = hi;
   g_sessions[n].low = lo;
   g_sessions[n].valid = true;
}

int TimeHour(const datetime t)
{
   MqlDateTime dt;
   TimeToStruct(t, dt);
   return dt.hour;
}

void RebuildSessions(const datetime now_time)
{
   ArrayResize(g_sessions, 0);
   if(!ShowSessionLevels)
      return;

   const int days = MathMax(1, SessionLookbackDays);
   // For each day lookback, build Asia/London/NY sessions that ended before "now".
   for(int d = 0; d < days; d++)
   {
      datetime day_ref = now_time - (datetime)(d * 86400);

      datetime a0 = SessionWindowStart(day_ref, AsiaStartHour, AsiaEndHour);
      datetime a1 = SessionEndFromStart(a0, AsiaStartHour, AsiaEndHour);
      if(a1 <= now_time)
      {
         datetime th=0, tl=0; double hi=0, lo=0;
         if(CalcSessionHL(a0, a1, th, tl, hi, lo))
            PushSession("Asia", ColorAsia, a0, a1, th, tl, hi, lo);
      }

      datetime l0 = SessionWindowStart(day_ref, LondonStartHour, LondonEndHour);
      datetime l1 = SessionEndFromStart(l0, LondonStartHour, LondonEndHour);
      if(l1 <= now_time)
      {
         datetime th=0, tl=0; double hi=0, lo=0;
         if(CalcSessionHL(l0, l1, th, tl, hi, lo))
            PushSession("London", ColorLondon, l0, l1, th, tl, hi, lo);
      }

      datetime n0 = SessionWindowStart(day_ref, NYStartHour, NYEndHour);
      datetime n1 = SessionEndFromStart(n0, NYStartHour, NYEndHour);
      if(n1 <= now_time)
      {
         datetime th=0, tl=0; double hi=0, lo=0;
         if(CalcSessionHL(n0, n1, th, tl, hi, lo))
            PushSession("New York", ColorNY, n0, n1, th, tl, hi, lo);
      }

      if(ShowFrankfurt)
      {
         datetime f0 = SessionWindowStart(day_ref, FrankfurtStartHour, FrankfurtEndHour);
         datetime f1 = SessionEndFromStart(f0, FrankfurtStartHour, FrankfurtEndHour);
         if(f1 <= now_time)
         {
            datetime th=0, tl=0; double hi=0, lo=0;
            if(CalcSessionHL(f0, f1, th, tl, hi, lo))
               PushSession("Frankfurt", ColorFrankfurt, f0, f1, th, tl, hi, lo);
         }
      }
   }

   // Currently forming sessions (partial) for live levels
   {
      int hour_now = TimeHour(now_time);

      datetime a0 = SessionWindowStart(now_time, AsiaStartHour, AsiaEndHour);
      datetime a1 = now_time;
      if(a1 < a0) a1 = a0;
      if(HourInWindow(hour_now, AsiaStartHour, AsiaEndHour))
      {
         datetime th=0, tl=0; double hi=0, lo=0;
         if(CalcSessionHL(a0, a1, th, tl, hi, lo))
            PushSession("Asia", ColorAsia, a0, a1, th, tl, hi, lo);
      }

      datetime l0 = SessionWindowStart(now_time, LondonStartHour, LondonEndHour);
      datetime l1 = now_time;
      if(l1 < l0) l1 = l0;
      if(HourInWindow(hour_now, LondonStartHour, LondonEndHour))
      {
         datetime th=0, tl=0; double hi=0, lo=0;
         if(CalcSessionHL(l0, l1, th, tl, hi, lo))
            PushSession("London", ColorLondon, l0, l1, th, tl, hi, lo);
      }

      datetime n0 = SessionWindowStart(now_time, NYStartHour, NYEndHour);
      datetime n1 = now_time;
      if(n1 < n0) n1 = n0;
      if(HourInWindow(hour_now, NYStartHour, NYEndHour))
      {
         datetime th=0, tl=0; double hi=0, lo=0;
         if(CalcSessionHL(n0, n1, th, tl, hi, lo))
            PushSession("New York", ColorNY, n0, n1, th, tl, hi, lo);
      }

      if(ShowFrankfurt && HourInWindow(hour_now, FrankfurtStartHour, FrankfurtEndHour))
      {
         datetime f0 = SessionWindowStart(now_time, FrankfurtStartHour, FrankfurtEndHour);
         datetime f1 = now_time;
         if(f1 < f0) f1 = f0;
         datetime th=0, tl=0; double hi=0, lo=0;
         if(CalcSessionHL(f0, f1, th, tl, hi, lo))
            PushSession("Frankfurt", ColorFrankfurt, f0, f1, th, tl, hi, lo);
      }
   }
}

string SessionObjKey(const string name, const datetime t_start)
{
   // Стабильное имя (не индекс массива) — иначе при пересборке объекты «прыгают».
   string s = name;
   StringReplace(s, " ", "");
   return Prefix() + "SES_" + s + "_" + TimeToObjectId(t_start) + "_";
}

void DrawSessionLevels()
{
   if(!ShowSessionLevels)
   {
      DeleteObjectsWithPrefix(Prefix() + "SES_");
      return;
   }

   // Drop exact duplicates (same name + start) created by lookback overlap
   for(int i = ArraySize(g_sessions) - 1; i >= 0; i--)
   {
      for(int j = 0; j < i; j++)
      {
         if(g_sessions[i].name == g_sessions[j].name && g_sessions[i].t_start == g_sessions[j].t_start)
         {
            if(g_sessions[i].t_end >= g_sessions[j].t_end)
               g_sessions[j] = g_sessions[i];
            int last = ArraySize(g_sessions) - 1;
            if(i != last)
               g_sessions[i] = g_sessions[last];
            ArrayResize(g_sessions, last);
            break;
         }
      }
   }

   int sec = PeriodSeconds(Timeframe);
   datetime now_t = iTime(_Symbol, Timeframe, 0);
   if(now_t <= 0) now_t = TimeCurrent();
   datetime ray_right = now_t + (datetime)(sec * MathMax(30, ShowLevelsLenBars / 10));

   int n = ArraySize(g_sessions);
   MqlDateTime dt; TimeToStruct(now_t, dt);
   datetime day_key = StringToTime(StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day));
   bool session_alert_today = (g_lastSessionAlertDay == day_key);

   // Без Delete-all: ObjectMove/upsert. Потом убираем только «сироты».
   string keep[];
   ArrayResize(keep, 0);

   for(int i = 0; i < n; i++)
   {
      if(!g_sessions[i].valid) continue;
      double ink = 1.0;
      if(!MarkInk(g_sessions[i].t_end, ink))
         continue;
      color sc = InkColor(g_sessions[i].clr, ink);
      string base = SessionObjKey(g_sessions[i].name, g_sessions[i].t_start);

      string nH  = base + "H";
      string nHT = base + "HT";
      string nHL = base + "HL";
      string nL  = base + "L";
      string nLT = base + "LT";
      string nLL = base + "LL";
      string nSH = base + "SH";

      int k = ArraySize(keep);
      ArrayResize(keep, k + 2);
      keep[k] = nH;
      keep[k + 1] = nL;

      DrawHLineSegment(nH, g_sessions[i].t_high, ray_right, g_sessions[i].high,
                       sc, STYLE_DOT, 1, "");
      datetime tick2 = g_sessions[i].t_high + (datetime)sec;
      if(ink >= 0.45)
      {
         DrawHLineSegment(nHT, g_sessions[i].t_high, tick2, g_sessions[i].high,
                          sc, STYLE_SOLID, (ink < 0.75 ? 1 : 3), "");
         DrawText(nHL, g_sessions[i].t_high, g_sessions[i].high + 4 * PointValue(),
                  g_sessions[i].name, sc, ANCHOR_LEFT_LOWER);
         int kk = ArraySize(keep);
         ArrayResize(keep, kk + 2);
         keep[kk] = nHT;
         keep[kk + 1] = nHL;
      }

      DrawHLineSegment(nL, g_sessions[i].t_low, ray_right, g_sessions[i].low,
                       sc, STYLE_DOT, 1, "");
      datetime tick2l = g_sessions[i].t_low + (datetime)sec;
      if(ink >= 0.45)
      {
         DrawHLineSegment(nLT, g_sessions[i].t_low, tick2l, g_sessions[i].low,
                          sc, STYLE_SOLID, (ink < 0.75 ? 1 : 3), "");
         DrawText(nLL, g_sessions[i].t_low, g_sessions[i].low - 4 * PointValue(),
                  g_sessions[i].name, sc, ANCHOR_LEFT_UPPER);
         int kk = ArraySize(keep);
         ArrayResize(keep, kk + 2);
         keep[kk] = nLT;
         keep[kk + 1] = nLL;
      }

      if(ShowSessionShading)
      {
         color fill = ToARGB(g_sessions[i].clr, (int)(18.0 * ink));
         DrawRect(nSH, g_sessions[i].t_start, g_sessions[i].high,
                  g_sessions[i].t_end, g_sessions[i].low, fill, true, true);
         int kk = ArraySize(keep);
         ArrayResize(keep, kk + 1);
         keep[kk] = nSH;
      }
   }

   // Удалить только SES_* которых больше нет в keep
   const string pfx = Prefix() + "SES_";
   int total = ObjectsTotal(0, 0, -1);
   for(int oi = total - 1; oi >= 0; oi--)
   {
      string on = ObjectName(0, oi, 0, -1);
      if(StringFind(on, pfx) != 0)
         continue;
      bool found = false;
      for(int ki = 0; ki < ArraySize(keep); ki++)
      {
         if(keep[ki] == on) { found = true; break; }
      }
      if(!found)
         ObjectDelete(0, on);
   }

   if(!session_alert_today && n > 0)
   {
      g_lastSessionAlertDay = day_key;
      FireSniperAlert(ALT_SESSION, StringFormat("сессии обновлены (%d уровней)", n));
   }
}

bool NearPrice(const double price, const double level, const double atr_dist)
{
   return (MathAbs(price - level) <= atr_dist);
}

int CountTouches(const MqlRates &rates[], const double level, const int from_shift, const int bars, const double tol)
{
   int c = 0;
   int total = ArraySize(rates);
   for(int i = from_shift; i < from_shift + bars && i < total; i++)
   {
      if(rates[i].high >= level - tol && rates[i].low <= level + tol)
         c++;
   }
   return c;
}

void UpdateLiquidityZones(const MqlRates &rates[])
{
   DeleteObjectsWithPrefix(Prefix() + "LIQ_");
   ArrayResize(g_liqZones, 0);
   if(!ShowLiquidityZones)
      return;

   double atr = 0.0;
   if(!GetBufferValue(g_hATR_Filter, 1, atr) || atr <= 0.0)
      return;

   // Только LiqPivotDepth: SpeedPreset (CALM=8 / SWING=60) не должен глушить зоны
   // и RGB-прицел на M5. Паттерны/свинги по-прежнему берут EffectiveSwingDepth().
   const int depth = MathMax(2, LiqPivotDepth);
   const int look = MathMin(ArraySize(rates) - depth - 2, MathMax(50, LiqLookbackBars));
   const double zh = MathMax(PointValue() * 5.0, LiqZoneATR_Mult * atr);
   const double tol = MathMax(PointValue() * 3.0, 0.15 * atr);

   SLiquidityZone tmp[];
   ArrayResize(tmp, 0);

   for(int shift = depth; shift < look; shift++)
   {
      if(IsPivotHigh(rates, shift, depth))
      {
         // supply / stop pool above swing high
         double level = rates[shift].high;
         // require at least one more touch nearby (liquidity cluster)
         int touches = CountTouches(rates, level, shift, MathMin(40, look - shift), tol);
         if(touches < 2)
            continue;
         // still relevant if not closed far through
         bool invalidated = false;
         for(int j = 1; j < shift; j++)
         {
            if(rates[j].close > level + 0.5 * atr)
            {
               invalidated = true;
               break;
            }
         }
         if(invalidated) continue;

         int n = ArraySize(tmp);
         ArrayResize(tmp, n + 1);
         tmp[n].active = true;
         tmp[n].type = 1;
         tmp[n].t1 = rates[shift].time;
         tmp[n].t2 = rates[0].time + (datetime)(PeriodSeconds(Timeframe) * 20);
         tmp[n].high = level + zh * 0.25;
         tmp[n].low = level - zh;
         tmp[n].id = ++g_liqSeq;
      }

      if(IsPivotLow(rates, shift, depth))
      {
         double level = rates[shift].low;
         int touches = CountTouches(rates, level, shift, MathMin(40, look - shift), tol);
         if(touches < 2)
            continue;
         bool invalidated = false;
         for(int j = 1; j < shift; j++)
         {
            if(rates[j].close < level - 0.5 * atr)
            {
               invalidated = true;
               break;
            }
         }
         if(invalidated) continue;

         int n = ArraySize(tmp);
         ArrayResize(tmp, n + 1);
         tmp[n].active = true;
         tmp[n].type = -1;
         tmp[n].t1 = rates[shift].time;
         tmp[n].t2 = rates[0].time + (datetime)(PeriodSeconds(Timeframe) * 20);
         tmp[n].high = level + zh;
         tmp[n].low = level - zh * 0.25;
         tmp[n].id = ++g_liqSeq;
      }
   }

   // keep nearest MaxLiquidityZones by distance to price
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   int nall = ArraySize(tmp);
   for(int i = 0; i < nall - 1; i++)
      for(int j = i + 1; j < nall; j++)
      {
         double mi = MathMin(MathAbs(price - tmp[i].high), MathAbs(price - tmp[i].low));
         double mj = MathMin(MathAbs(price - tmp[j].high), MathAbs(price - tmp[j].low));
         if(mj < mi)
         {
            SLiquidityZone sw = tmp[i];
            tmp[i] = tmp[j];
            tmp[j] = sw;
         }
      }

   int keep = MathMin(MaxLiquidityZones, nall);
   ArrayResize(g_liqZones, keep);
   for(int i = 0; i < keep; i++)
   {
      g_liqZones[i] = tmp[i];
      double ink = 1.0;
      if(!MarkInk(tmp[i].t1, ink))
         continue;
      color base = (tmp[i].type > 0) ? ColorSupplyZone : ColorDemandZone;
      string name = Prefix() + "LIQ_" + IntegerToString(tmp[i].id);
      if(ink >= 0.45)
      {
         color fill = ToARGB(base, (int)(55.0 * ink));
         DrawRect(name, tmp[i].t1, tmp[i].high, tmp[i].t2, tmp[i].low, fill, true, true);
         string lbl = (tmp[i].type > 0) ? "Предложение" : "Спрос";
         color lc = InkColor((tmp[i].type > 0) ? ColorNY : ColorLondon, ink);
         DrawText(name + "_T", tmp[i].t1, (tmp[i].type > 0) ? tmp[i].high : tmp[i].low,
                  lbl, lc, (tmp[i].type > 0) ? ANCHOR_LEFT_LOWER : ANCHOR_LEFT_UPPER);
      }
      else
      {
         ObjectCreate(0, name, OBJ_RECTANGLE, 0, tmp[i].t1, tmp[i].high, tmp[i].t2, tmp[i].low);
         ObjectSetInteger(0, name, OBJPROP_COLOR, InkColor(base, ink));
         ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, name, OBJPROP_FILL, false);
         ObjectSetInteger(0, name, OBJPROP_BACK, true);
         ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
         if(ObjExists(name + "_T")) ObjectDelete(0, name + "_T");
      }
   }
}

bool FindNearestLiquidity(const int want_type, double &z_high, double &z_low, double &dist)
{
   dist = DBL_MAX;
   bool found = false;
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   for(int i = 0; i < ArraySize(g_liqZones); i++)
   {
      if(!g_liqZones[i].active) continue;
      if(want_type != 0 && g_liqZones[i].type != want_type) continue;
      double mid = 0.5 * (g_liqZones[i].high + g_liqZones[i].low);
      double d = MathAbs(price - mid);
      if(d < dist)
      {
         dist = d;
         z_high = g_liqZones[i].high;
         z_low = g_liqZones[i].low;
         found = true;
      }
   }
   return found;
}

bool PriceInsideSight(const double price)
{
   if(!g_sightActive)
      return false;
   return (price <= g_sightHigh && price >= g_sightLow);
}

void ClearSight()
{
   DeleteObjectsWithPrefix(Prefix() + "SIGHT_");
   g_sightActive = false;
   g_sightDirection = 0;
   g_sightDrawnDirection = 0;
   g_sightHigh = 0.0;
   g_sightLow = 0.0;
   g_sightAnchor = 0.0;
   g_sightDrawnDirection = 0;
   g_sightUpdateBar = 0;
}

void SightDash(const string name, datetime t1, datetime t2, const double price, const color clr, const int width)
{
   if(!ObjExists(name))
   {
      ObjectCreate(0, name, OBJ_TREND, 0, t1, price, t2, price);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, name, OBJPROP_RAY_LEFT, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
   }
   ObjectMove(0, name, 0, t1, price);
   ObjectMove(0, name, 1, t2, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 100);
}

void NudgeSightLevelsLive()
{
   if(!SightLevelsLive || !g_sightActive || g_sightAnchor <= 0.0)
      return;
   double atr = 0.0;
   if(!GetBufferValue(g_hATR_Filter, 0, atr) || atr <= 0.0)
      if(!GetBufferValue(g_hATR_Filter, 1, atr) || atr <= 0.0)
         return;
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   const double h = MathMax(8 * PointValue(), SightATR_Height * atr);
   // Полоса вокруг якоря; лёгкий сдвиг к цене — «дыхание» как в Sniper-PRO
   double hi, lo;
   if(g_sightDirection < 0)
   {
      hi = g_sightAnchor + h * 0.35;
      lo = g_sightAnchor - h * 0.65;
   }
   else
   {
      hi = g_sightAnchor + h * 0.65;
      lo = g_sightAnchor - h * 0.35;
   }
   double mid = 0.5 * (hi + lo);
   double shift = 0.12 * (price - mid);
   g_sightHigh = hi + shift;
   g_sightLow  = lo + shift;
}

// Прицел (эталонный скрин): пустая пунктирная рамка + RGB-чёрточки + подпись.
// BUY = голубая рамка, SELL = бордовая. Без заливки.
void SyncSightObjects(const MqlRates &rates[], const bool force_recreate)
{
   if(!ShowSight || !g_sightActive)
      return;

   int sec = PeriodSeconds(Timeframe);
   datetime t1 = rates[0].time;
   datetime t2 = rates[0].time + (datetime)(sec * MathMax(4, SightBarsWidth));
   // Короткие чёрточки у правого края рамки
   datetime td2 = t2;
   datetime td1 = t2 - (datetime)(sec * MathMax(3, SightDashBars));
   double mid = 0.5 * (g_sightHigh + g_sightLow);
   string label = (g_sightDirection > 0) ? "▶ ПРИЦЕЛ BUY" : "▶ ПРИЦЕЛ SELL";
   color border = (g_sightDirection > 0) ? ColorSightBuy : ColorSightSell;

   const string tl  = Prefix() + "SIGHT_TL";
   const string d1  = Prefix() + "SIGHT_D1";
   const string d2  = Prefix() + "SIGHT_D2";
   const string d3  = Prefix() + "SIGHT_D3";
   const string txt = Prefix() + "SIGHT_TXT";

   if(ObjExists(Prefix() + "SIGHT_BOX"))
      ObjectDelete(0, Prefix() + "SIGHT_BOX");

   const bool need_rebuild = force_recreate
      || (g_sightDrawnDirection != g_sightDirection)
      || (SightShowFrame && !ObjExists(tl))
      || (SightShowDashes && (!ObjExists(d1) || !ObjExists(d2) || !ObjExists(d3)))
      || !ObjExists(txt);

   if(need_rebuild)
   {
      DeleteObjectsWithPrefix(Prefix() + "SIGHT_");
      g_sightDrawnDirection = g_sightDirection;
   }

   if(SightShowFrame)
   {
      if(!ObjExists(tl))
         ObjectCreate(0, tl, OBJ_RECTANGLE, 0, t1, g_sightHigh, t2, g_sightLow);
      ObjectMove(0, tl, 0, t1, g_sightHigh);
      ObjectMove(0, tl, 1, t2, g_sightLow);
      ObjectSetInteger(0, tl, OBJPROP_COLOR, border);
      ObjectSetInteger(0, tl, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, tl, OBJPROP_WIDTH, 3);
      ObjectSetInteger(0, tl, OBJPROP_FILL, false);
      ObjectSetInteger(0, tl, OBJPROP_BACK, false);
      ObjectSetInteger(0, tl, OBJPROP_ZORDER, 101);
      ObjectSetInteger(0, tl, OBJPROP_SELECTABLE, false);
   }
   else if(ObjExists(tl))
      ObjectDelete(0, tl);

   if(SightShowDashes)
   {
      SightDash(d1, td1, td2, g_sightHigh, ColorSightDashHi, 3);
      SightDash(d2, td1, td2, mid,         ColorSightDashMid, 3);
      SightDash(d3, td1, td2, g_sightLow,  ColorSightDashLo, 3);
   }
   else
   {
      if(ObjExists(d1)) ObjectDelete(0, d1);
      if(ObjExists(d2)) ObjectDelete(0, d2);
      if(ObjExists(d3)) ObjectDelete(0, d3);
   }

   DrawText(txt, t1, g_sightHigh + 10 * PointValue(), label, border, ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, txt, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, txt, OBJPROP_ZORDER, 102);
}

// Внутри бара: сторона sticky; уровни чёрточек могут дышать с ценой
void MaintainSightIntrabar(const MqlRates &rates[])
{
   if(!g_sightActive)
      return;
   NudgeSightLevelsLive();
   SyncSightObjects(rates, false);
}

void UpdateSight(const MqlRates &rates[])
{
   // Пересчёт на закрытии бара. Важно: не очищаем UI до готовности нового состояния
   // (иначе кадр «пустого» прицела при смене BUY↔SELL).

   if(!ShowSight && !RequireSightForEntry)
      return;

   double atr = 0.0;
   if(!GetBufferValue(g_hATR_Filter, 1, atr) || atr <= 0.0)
      return;

   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   const double near = SightNearATR * atr;
   const double h = MathMax(8 * PointValue(), SightATR_Height * atr);

   const bool had = g_sightActive;
   const int old_dir = g_sightDirection;
   const double old_anchor = g_sightAnchor;
   const double old_high = g_sightHigh;
   const double old_low = g_sightLow;
   const datetime old_t0 = g_sightUpdateBar;

   double best_level = 0.0;
   int best_anchor_dir = 0; // -1 demand, +1 supply
   double best_score = -1.0;

   for(int i = 0; i < ArraySize(g_sessions); i++)
   {
      if(!g_sessions[i].valid) continue;
      if(NearPrice(price, g_sessions[i].low, near))
      {
         double score = 1.0 - MathAbs(price - g_sessions[i].low) / near;
         if(score > best_score) { best_score = score; best_level = g_sessions[i].low; best_anchor_dir = -1; }
      }
      if(NearPrice(price, g_sessions[i].high, near))
      {
         double score = 1.0 - MathAbs(price - g_sessions[i].high) / near;
         if(score > best_score) { best_score = score; best_level = g_sessions[i].high; best_anchor_dir = 1; }
      }
   }

   for(int i = 0; i < ArraySize(g_liqZones); i++)
   {
      if(!g_liqZones[i].active) continue;
      double mid = 0.5 * (g_liqZones[i].high + g_liqZones[i].low);
      if(!NearPrice(price, mid, near * 1.2))
         continue;
      double score = 1.15 - MathAbs(price - mid) / (near * 1.2);
      if(score > best_score)
      {
         best_score = score;
         best_level = mid;
         best_anchor_dir = g_liqZones[i].type;
      }
   }

   if(g_zone.active)
   {
      if(NearPrice(price, g_zone.low, near))
      {
         double score = 1.05 - MathAbs(price - g_zone.low) / near;
         if(score > best_score) { best_score = score; best_level = g_zone.low; best_anchor_dir = -1; }
      }
      if(NearPrice(price, g_zone.high, near))
      {
         double score = 1.05 - MathAbs(price - g_zone.high) / near;
         if(score > best_score) { best_score = score; best_level = g_zone.high; best_anchor_dir = 1; }
      }
   }

   // Нет уверенного якоря → сохраняем прежний прицел (sticky), не гасим UI
   if(best_score < 0.15 || best_anchor_dir == 0)
   {
      if(had)
      {
         bool far = false;
         if(atr > 0.0 && SightCancelATR > 0.0 && old_anchor != 0.0)
            far = (MathAbs(price - old_anchor) > SightCancelATR * atr);
         if(far)
            ClearSight();
         else
         {
            // оставляем сторону/уровни, только продлеваем рамку
            g_sightActive = true;
            g_sightDirection = old_dir;
            g_sightHigh = old_high;
            g_sightLow = old_low;
            g_sightAnchor = old_anchor;
            if(old_t0 > 0)
               g_sightUpdateBar = old_t0;
            SyncSightObjects(rates, false);
         }
      }
      return;
   }

   const int new_dir = (best_anchor_dir > 0) ? -1 : 1; // supply→SELL, demand→BUY

   // Гистерезис смены стороны: не переворачиваем при слабом перевесе
   if(had && old_dir != 0 && new_dir != old_dir && best_score < 0.45)
   {
      g_sightActive = true;
      g_sightDirection = old_dir;
      g_sightHigh = old_high;
      g_sightLow = old_low;
      g_sightAnchor = old_anchor;
      if(old_t0 > 0)
         g_sightUpdateBar = old_t0;
      SyncSightObjects(rates, false);
      return;
   }

   // Атомарно ставим новое состояние, затем один sync (без промежуточного Clear)
   double new_high, new_low;
   if(best_anchor_dir > 0)
   {
      new_high = best_level + h * 0.35;
      new_low  = best_level - h * 0.65;
   }
   else
   {
      new_high = best_level + h * 0.65;
      new_low  = best_level - h * 0.35;
   }

   const bool side_changed = (had && old_dir != new_dir);
   g_sightActive = true;
   g_sightDirection = new_dir;
   g_sightHigh = new_high;
   g_sightLow = new_low;
   g_sightAnchor = best_level;
   g_sightUpdateBar = rates[0].time;
   SyncSightObjects(rates, side_changed || !had);

   if((!had || side_changed) && new_dir != 0 && new_dir != g_lastSightDirAlert)
   {
      g_lastSightDirAlert = new_dir;
      FireSniperAlert(ALT_SIGHT, (new_dir > 0) ? "прицел BUY" : "прицел SELL");
   }
}

bool PassSightFilter(const int direction, string &why)
{
   why = "";
   if(!RequireSightForEntry)
      return true;
   if(!g_sightActive)
   {
      why = "blocked: no sight";
      return false;
   }
   double price = (direction > 0) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(!PriceInsideSight(price))
   {
      why = "blocked: outside sight";
      return false;
   }
   // Sight direction is the expected trade direction
   if(g_sightDirection != 0 && g_sightDirection != direction)
   {
      why = "blocked: sight opposite";
      return false;
   }
   return true;
}

int ComputeProbability(const string sig, const int direction, const MqlRates &bar)
{
   int score = 40;

   // Signal type weighting (Sniper prefers liquidity fade / false break)
   if(sig == "B") score += 18;
   else if(sig == "C") score += 12;
   else if(sig == "A") score += 4;

   // Sight confluence
   double px = (direction > 0) ? bar.close : bar.close;
   if(g_sightActive && PriceInsideSight(px))
      score += 16;
   if(g_sightActive && g_sightDirection == direction)
      score += 8;

   // 12 patterns / ЗУ / ПД confluence
   for(int i = 0; i < ArraySize(g_structZones); i++)
   {
      if(!g_structZones[i].active || !g_structZones[i].valid) continue;
      if(g_structZones[i].direction != direction) continue;
      if(bar.low <= g_structZones[i].high && bar.high >= g_structZones[i].low)
      {
         if(g_structZones[i].pattern != PAT_NONE) score += 10;
         else if(g_structZones[i].kind == SK_ZU || g_structZones[i].kind == SK_PD) score += 8;
         else if(g_structZones[i].kind == SK_RM) score += 12;
         else if(g_structZones[i].kind == SK_GUD) score += 14;
         break;
      }
   }
   if(g_boundActive)
   {
      double atr_b = 0.0;
      GetBufferValue(g_hATR_Filter, 1, atr_b);
      if(atr_b > 0.0)
      {
         bool at_bound = (direction > 0 && NearPrice(bar.low, g_boundLow, 0.5 * atr_b))
                      || (direction < 0 && NearPrice(bar.high, g_boundHigh, 0.5 * atr_b));
         if(at_bound)
            score += (PreferEntryInChannel ? 10 : 5);
      }
   }
   if(UseVirtualTF && DetectMTFConfluence(direction))
      score += 8;

   // Session extreme proximity
   double atr = 0.0;
   GetBufferValue(g_hATR_Filter, 1, atr);
   if(atr > 0.0)
   {
      double near = 1.0 * atr;
      for(int i = 0; i < ArraySize(g_sessions); i++)
      {
         if(!g_sessions[i].valid) continue;
         if(direction < 0 && NearPrice(bar.high, g_sessions[i].high, near)) { score += 10; break; }
         if(direction > 0 && NearPrice(bar.low,  g_sessions[i].low,  near)) { score += 10; break; }
      }

      // Liquidity zone alignment
      double zh=0, zl=0, dist=0;
      if(FindNearestLiquidity(direction < 0 ? 1 : -1, zh, zl, dist))
      {
         if(dist <= 1.2 * atr)
            score += 12;
      }

      // Momentum quality for A
      double body = MathAbs(bar.close - bar.open);
      if(sig == "A")
      {
         if(body >= BreakoutBodyATR_Min * atr) score += 8;
         else score -= 12;
      }

      // Wick quality for B (stop-run)
      if(sig == "B")
      {
         double wick = (direction < 0) ? (bar.high - MathMax(bar.open, bar.close))
                                       : (MathMin(bar.open, bar.close) - bar.low);
         if(wick >= 0.5 * atr) score += 8;
      }
   }

   // EMA alignment bonus (soft)
   if(EMA_Period > 0 && g_hEMA != INVALID_HANDLE)
   {
      double ema = 0.0;
      if(GetBufferValue(g_hEMA, 1, ema))
      {
         if(direction > 0 && bar.close >= ema) score += 6;
         if(direction < 0 && bar.close <= ema) score += 6;
         if(direction > 0 && bar.close < ema) score -= 6;
         if(direction < 0 && bar.close > ema) score -= 6;
      }
   }

   // Spread penalty
   int spread = CurrentSpreadPoints();
   if(g_MaxSpread_Eff > 0 && spread > g_MaxSpread_Eff / 2)
      score -= 8;

   if(score < 5) score = 5;
   if(score > 95) score = 95;
   return score;
}

void PushProbability(const int value)
{
   int hist_len = MathMax(8, MathMax(FearHistoryLen, ProbHistoryLen));
   int n = ArraySize(g_probHistory);
   if(n < hist_len)
   {
      ArrayResize(g_probHistory, n + 1);
      g_probHistory[n] = value;
   }
   else
   {
      for(int i = 0; i < n - 1; i++)
         g_probHistory[i] = g_probHistory[i + 1];
      g_probHistory[n - 1] = value;
   }
   g_lastProbability = value;
   g_lastFearIndex = value;
}

void HudLabelEx(const string name, const int x, const int y,
                const string text, const color clr, const int font_size,
                const ENUM_ANCHOR_POINT anchor, const string font = "Arial")
{
   if(!ObjExists(name))
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
   ObjectSetString(0, name, OBJPROP_FONT, font);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 200);
}

void HudLabel(const string name, const int x, const int y,
              const string text, const color clr, const int font_size,
              const string font = "Arial")
{
   HudLabelEx(name, x, y, text, clr, font_size, ANCHOR_RIGHT_UPPER, font);
}

// Индекс страха/жадности 0..100 (база — RSI). Зоны как в методичке МИР ТРЕЙДИНГА.
int ComputeFearIndex()
{
   if(g_hRSI == INVALID_HANDLE)
      return g_lastFearIndex;
   double rsi = 0.0;
   if(!GetBufferValue(g_hRSI, 0, rsi) && !GetBufferValue(g_hRSI, 1, rsi))
      return g_lastFearIndex;
   int v = (int)MathRound(rsi);
   if(v < 0) v = 0;
   if(v > 100) v = 100;
   return v;
}

color FearIndexColor(const int fear)
{
   if(fear <= 30 || fear >= 70)
      return (ColorFearExtreme != clrNONE ? ColorFearExtreme : ColorProbLow);
   if(fear <= 35 || fear >= 65)
      return (ColorFearTransition != clrNONE ? ColorFearTransition : ColorProbMid);
   return (ColorFearNeutral != clrNONE ? ColorFearNeutral : ColorProbHigh);
}

// Рекомендуемый R:R по зоне индекса: страх/жадность → 1:1; переход → 1:2; нейтраль → 1:3.
double FearIndexRewardMult(const int fear)
{
   if(fear <= 30 || fear >= 70) return 1.0;
   if(fear <= 35 || fear >= 65) return 2.0;
   return 3.0;
}

string FearIndexZoneName(const int fear)
{
   if(fear <= 30) return "страх";
   if(fear <= 35) return "давление продаж";
   if(fear < 65)  return "нейтраль";
   if(fear < 70)  return "давление покупок";
   return "жадность";
}

bool FearIndexAllows(const int direction, string &why)
{
   why = "";
   if(!FilterByFearIndex)
      return true;
   int fear = ComputeFearIndex();
   // 0–30: сильный страх после падения — ищем покупки, не продажи
   if(fear <= 30 && direction < 0)
   {
      why = StringFormat("blocked: fear %d (страх) — не SELL", fear);
      return false;
   }
   // 70–100: жадность/перегрев — ищем продажи, не покупки
   if(fear >= 70 && direction > 0)
   {
      why = StringFormat("blocked: fear %d (жадность) — не BUY", fear);
      return false;
   }
   return true;
}

bool ShowFearHudEnabled()
{
   return (ShowFearIndexHUD || ShowProbabilityHUD);
}

int HistoryLenFear()
{
   return MathMax(8, MathMax(FearHistoryLen, ProbHistoryLen));
}

void UpdateFearIndexHUD(const int display_value)
{
   if(!ShowFearHudEnabled())
   {
      DeleteObjectsWithPrefix(Prefix() + "PROB_");
      return;
   }

   if(ObjExists(Prefix() + "PROB_PCT"))    ObjectDelete(0, Prefix() + "PROB_PCT");
   if(ObjExists(Prefix() + "PROB_TITLE"))  ObjectDelete(0, Prefix() + "PROB_TITLE");
   if(ObjExists(Prefix() + "PROB_SPARK"))  ObjectDelete(0, Prefix() + "PROB_SPARK");
   if(ObjExists(Prefix() + "PROB_BAR0"))
      DeleteObjectsWithPrefix(Prefix() + "PROB_BAR");
   if(ObjExists(Prefix() + "PROB_CTX"))    ObjectDelete(0, Prefix() + "PROB_CTX");

   color c = FearIndexColor(display_value);

   // Как на эталоне: одно число без «%» — это индекс страха, не вероятность профита.
   HudLabel(Prefix() + "PROB_NUM", 14, 44,
            IntegerToString(display_value), c, 24, "Arial Bold");
}

void UpdateProbabilityHUD(const int display_value)
{
   UpdateFearIndexHUD(display_value);
}

// Зрелость сетапа (внутренняя): для опционального масштаба лота. НЕ индекс страха.
int ComputeContextProbability()
{
   int score = 30;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double atr = 0.0;
   GetBufferValue(g_hATR_Filter, 1, atr);

   if(g_sightActive)
   {
      score += 12;
      if(PriceInsideSight(bid))
         score += 18;
      else if(atr > 0.0)
      {
         double mid = 0.5 * (g_sightHigh + g_sightLow);
         double dist = MathAbs(bid - mid);
         if(dist <= 1.5 * atr)
            score += 8;
      }
   }

   if(atr > 0.0)
   {
      int want = 0;
      if(g_sightDirection > 0) want = -1;
      else if(g_sightDirection < 0) want = 1;
      double zh=0, zl=0, dist=0;
      if(FindNearestLiquidity(want, zh, zl, dist))
      {
         if(dist <= 0.6 * atr) score += 14;
         else if(dist <= 1.2 * atr) score += 8;
      }

      double near = 1.0 * atr;
      for(int i = 0; i < ArraySize(g_sessions); i++)
      {
         if(!g_sessions[i].valid) continue;
         if(NearPrice(bid, g_sessions[i].high, near) || NearPrice(bid, g_sessions[i].low, near))
         {
            score += 10;
            break;
         }
      }
   }

   if(g_zone.active)
      score += 6;

   // Бонус за близость к ГУД
   for(int i = 0; i < ArraySize(g_structZones); i++)
   {
      if(!g_structZones[i].active || !g_structZones[i].valid) continue;
      if(g_structZones[i].kind != SK_GUD) continue;
      if(atr > 0.0 && bid <= g_structZones[i].high + 0.4 * atr && bid >= g_structZones[i].low - 0.4 * atr)
      {
         score += 14;
         break;
      }
   }

   int spread = CurrentSpreadPoints();
   if(g_MaxSpread_Eff > 0)
   {
      if(spread > g_MaxSpread_Eff) score -= 15;
      else if(spread > g_MaxSpread_Eff / 2) score -= 6;
   }

   if(g_sightDirection != 0 && EMA_Period > 0 && g_hEMA != INVALID_HANDLE)
   {
      double ema = 0.0;
      if(GetBufferValue(g_hEMA, 0, ema) || GetBufferValue(g_hEMA, 1, ema))
      {
         if(g_sightDirection > 0 && bid >= ema) score += 5;
         if(g_sightDirection < 0 && bid <= ema) score += 5;
         if(g_sightDirection > 0 && bid < ema) score -= 4;
         if(g_sightDirection < 0 && bid > ema) score -= 4;
      }
   }

   if(score < 5) score = 5;
   if(score > 95) score = 95;
   g_lastSetupQuality = score;
   return score;
}


//=========================
// Sniper structures v4.0: 12 patterns + ЗУ/ПД/каскад/РМ
//=========================
string ShortTFName(const ENUM_TIMEFRAMES tf)
{
   if(tf == PERIOD_M1) return "M1";
   if(tf == PERIOD_M5) return "M5";
   if(tf == PERIOD_M15) return "M15";
   if(tf == PERIOD_M30) return "M30";
   if(tf == PERIOD_H1) return "H1";
   if(tf == PERIOD_H4) return "H4";
   string s = EnumToString(tf);
   StringReplace(s, "PERIOD_", "");
   return s;
}

string PatternName(const int pat)
{
   switch(pat)
   {
      case PAT_PD_T1:          return "01 ПД тип1";
      case PAT_PD_T2:          return "02 ПД тип2";
      case PAT_EXP_AFTER_PD:   return "03 Расшир.послеПД";
      case PAT_EXP_THROUGH_PD: return "04 Расшир.черезПД";
      case PAT_EXP_THROUGH_LP: return "05 Расшир.+ЛП";
      case PAT_EXP_CASCADE:    return "06 Каск.расшир.";
      case PAT_CASC_1:         return "07 Каскад1";
      case PAT_CASC_2:         return "08 Каскад2";
      case PAT_CASC_3:         return "09 Каскад3";
      case PAT_CASC_4:         return "10 Каскад4";
      case PAT_CASC_5:         return "11 Каскад5";
      case PAT_CASC_6:         return "12 Каскад6";
   }
   return "Паттерн";
}

string AlertTypeName(const int t)
{
   switch(t)
   {
      case ALT_RM:       return "РМ";
      case ALT_PATTERN:  return "ПАТТЕРН";
      case ALT_ZU:       return "ЗУ";
      case ALT_PD:       return "ПД/ОТКАТ";
      case ALT_CASCADE:  return "КАСКАД";
      case ALT_SIGHT:    return "ПРИЦЕЛ";
      case ALT_SESSION:  return "СЕССИЯ";
      case ALT_ENTRY:    return "ВХОД";
      case ALT_CANCEL:   return "ОТМЕНА";
      case ALT_MTF:      return "MTF";
   }
   return "ALERT";
}

bool AlertTypeEnabled(const int t)
{
   switch(t)
   {
      case ALT_RM:       return Alert_RM;
      case ALT_PATTERN:  return Alert_Pattern;
      case ALT_ZU:       return Alert_ZU;
      case ALT_PD:       return Alert_PD;
      case ALT_CASCADE:  return Alert_Cascade;
      case ALT_SIGHT:    return Alert_Sight;
      case ALT_SESSION:  return Alert_Session;
      case ALT_ENTRY:    return Alert_Entry;
      case ALT_CANCEL:   return Alert_Cancel;
      case ALT_MTF:      return Alert_MTF;
   }
   return false;
}

void FireSniperAlert(const int alert_type, const string detail)
{
   if(AlertsMode == ALERTS_OFF)
      return;
   if(!AlertTypeEnabled(alert_type))
      return;
   string key = IntegerToString(alert_type) + "|" + detail;
   datetime now = TimeCurrent();
   const long cooldown = (long)MathMax(5, AlertCooldownSec);
   if(key == g_alertLastKey && (long)(now - g_alertLastTime) < cooldown)
      return;
   g_alertLastKey = key;
   g_alertLastTime = now;
   string msg = StringFormat("[%s] %s | %s %s", AlertTypeName(alert_type), _Symbol, EA_VERSION, detail);
   Notify(msg);
}

void ClearStructureObjects()
{
   DeleteObjectsWithPrefix(Prefix() + "STR_");
   DeleteObjectsWithPrefix(Prefix() + "PAT_");
   DeleteObjectsWithPrefix(Prefix() + "BND_");
   DeleteObjectsWithPrefix(Prefix() + "RSI_");
   DeleteObjectsWithPrefix(Prefix() + "FIB30_");
}

void Fib30HistoryPurge(const bool have_live)
{
   if(!have_live)
      return;
   const datetime today = DayFloor(TimeCurrent());
   const string hp = Prefix() + "FIB30H_";
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string nm = ObjectName(0, i, 0, -1);
      if(StringFind(nm, hp) != 0)
         continue;
      datetime marked = (datetime)StringToInteger(ObjectGetString(0, nm, OBJPROP_TOOLTIP));
      if(marked > 0 && marked < today)
         ObjectDelete(0, nm);
   }
}

void Fib30ArchiveCurrent()
{
   if(!g_fib30_have || g_fib30_t1 == 0 || g_fib30_t2 == 0)
      return;
   const string name = Prefix() + "FIB30H_" + TimeToObjectId(g_fib30_origin_t) + "_" + TimeToObjectId(g_fib30_t2);
   const string txt  = name + "_T";
   const color faded = MixContrast50(ColorFib30Old);
   const string day  = IntegerToString((long)DayFloor(TimeCurrent()));
   DrawHLineSegment(name, g_fib30_t1, g_fib30_t2, g_fib30_price, faded, STYLE_SOLID, 1, "");
   ObjectSetString(0, name, OBJPROP_TOOLTIP, day);
   DrawText(txt, g_fib30_t2, g_fib30_price, "30", faded, ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, txt, OBJPROP_FONTSIZE, 8);
   ObjectSetString(0, txt, OBJPROP_TOOLTIP, day);
}

void DrawFib30Line(const MqlRates &rates[])
{
   // Z пунктиром по импульсу. Актуальная «30» только справа у новых свечей.
   // Новый ход → прежняя «30» оранжевая, контраст 50%; на следующий день — удалить.
   const string pfx  = Prefix() + "FIB30";
   const string live = pfx + "_";
   if(!ShowFib30)
   {
      DeleteObjectsWithPrefix(live);
      DeleteObjectsWithPrefix(pfx + "H_");
      g_fib30_have = false;
      g_fib30_retraced = false;
      return;
   }

   SContinuedMove mv;
   const bool have_mv = FindContinuedMove(rates, mv) && mv.range > MinContinuedMoveRange()
                        && MathAbs(mv.origin - mv.tip) > MinContinuedMoveRange()
                        && mv.t_origin != mv.t_tip;

   if(g_fib30_have && have_mv)
   {
      const double new30 = mv.tip + (PD_MinCorrectionPct / 100.0) * (mv.origin - mv.tip);
      const bool origin_chg = (mv.t_origin != g_fib30_origin_t);
      const bool spent_30 = g_fib30_retraced && MathAbs(new30 - g_fib30_price) > 3.0 * PointValue();
      if(origin_chg || spent_30)
         Fib30ArchiveCurrent();
   }

   Fib30HistoryPurge(have_mv);

   if(!have_mv)
   {
      DeleteObjectsWithPrefix(live);
      g_fib30_retraced = false;
      return;
   }

   const double price_100 = mv.origin;
   const double price_0   = mv.tip;
   const datetime time_100 = mv.t_origin;
   const datetime time_0   = mv.t_tip;
   const double price_30 = price_0 + (PD_MinCorrectionPct / 100.0) * (price_100 - price_0);

   const int sec = PeriodSeconds(Timeframe);
   datetime t_left = time_100;
   datetime t_right = time_0;
   if(t_right < t_left)
   {
      datetime sw = t_left; t_left = t_right; t_right = sw;
   }
   long span = (long)(t_right - t_left);
   long wing = (long)sec * 8;
   if(span / 6 > wing) wing = span / 6;
   if(wing < (long)sec * 4) wing = (long)sec * 4;

   datetime h0a = (datetime)((long)time_100 - wing);
   datetime h0b = (datetime)((long)time_100 + wing);
   if(h0b > t_right) h0b = t_right;
   if(h0a >= h0b) h0a = (datetime)((long)h0b - (long)sec * 4);

   const datetime t_now = rates[0].time;
   datetime h1a = time_0;
   datetime h1b = t_now;
   if(h1b < h1a) h1b = (datetime)((long)h1a + (long)sec * 4);
   h1b = (datetime)((long)h1b + (long)sec * 2);
   if((long)(h1b - h1a) < (long)sec * 6)
      h1b = (datetime)((long)h1a + (long)sec * 8);

   if(ShowContinuedMoveZ)
   {
      int zw = WidthContinuedMove;
      if(zw < 1) zw = 1;
      if(zw > 4) zw = 4;
      // STYLE_DOT в MT5 почти всегда 1px; тире уважает толщину.
      ENUM_LINE_STYLE zs = (zw > 1) ? STYLE_DASH : STYLE_DOT;
      DrawHLineSegment(live + "Z0", h0a, h0b, price_100, ColorContinuedMove, zs, zw, "");
      DrawHLineSegment(live + "Z1", h1a, h1b, price_0, ColorContinuedMove, zs, zw, "");
      DrawTrendSegment(live + "ZD", time_100, price_100, time_0, price_0, ColorContinuedMove, zs, zw);
   }
   else
   {
      if(ObjExists(live + "Z0")) ObjectDelete(0, live + "Z0");
      if(ObjExists(live + "Z1")) ObjectDelete(0, live + "Z1");
      if(ObjExists(live + "ZD")) ObjectDelete(0, live + "ZD");
   }

   datetime t30a = time_0;
   datetime t30b = h1b;
   if(t30b <= t30a)
      t30b = (datetime)((long)t30a + (long)sec * 8);

   DrawHLineSegment(live + "30", t30a, t30b, price_30, ColorFib30, STYLE_SOLID, 2, "");
   DrawText(live + "T", t30b, price_30, "30", ColorFib30, ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, live + "T", OBJPROP_FONTSIZE, 9);

   g_fib30_origin_t = mv.t_origin;
   g_fib30_price    = price_30;
   g_fib30_t1       = t30a;
   g_fib30_t2       = t30b;
   g_fib30_have     = true;
   g_fib30_retraced = mv.retraced_30;

   if(ObjExists(pfx)) ObjectDelete(0, pfx);
   if(ObjExists(pfx + "_BAND")) ObjectDelete(0, pfx + "_BAND");
}

void DrawStructureZone(const SStructureZone &z)
{
   if(!z.active)
      return;
   if(!z.valid && z.kind != SK_ZU && z.kind != SK_CASCADE)
      return;
   if(z.kind == SK_ZU && !ShowDecisionZones && z.valid) return;
   if(z.kind == SK_ZU && !z.valid && !ShowCascadeMarks) return;
   if(z.kind == SK_PD && !ShowPullbackZones) return;
   if(z.kind == SK_CASCADE && !ShowCascadeMarks) return;
   if(z.kind == SK_RM && !ShowReversalMoments) return;
   if(z.kind == SK_GUD && !ShowGUDLevels) return;
   double ink = 1.0;
   if(!MarkInk(z.t1, ink))
      return;
   // Паттерн-only метки (без ЗУ/ПД/каскад) — только при ShowAll12Patterns
   if(z.pattern != PAT_NONE && z.kind != SK_ZU && z.kind != SK_PD && z.kind != SK_CASCADE && z.kind != SK_RM
      && !ShowAll12Patterns)
      return;

   string base = Prefix() + "STR_" + IntegerToString(z.id);

   // Разворотный момент: узкая рамка на свече остановки. Красный — продажа, синий — покупка.
   if(z.kind == SK_RM)
   {
      const color rm = InkColor((z.direction > 0) ? ColorRM_Buy : ColorRM_Sell, ink);
      ObjectCreate(0, base + "_OL", OBJ_RECTANGLE, 0, z.t1, z.high, z.t2, z.low);
      ObjectSetInteger(0, base + "_OL", OBJPROP_COLOR, rm);
      ObjectSetInteger(0, base + "_OL", OBJPROP_STYLE, (ink < 0.65) ? STYLE_DOT : STYLE_SOLID);
      ObjectSetInteger(0, base + "_OL", OBJPROP_WIDTH, (ink < 0.65) ? 1 : 2);
      ObjectSetInteger(0, base + "_OL", OBJPROP_FILL, false);
      ObjectSetInteger(0, base + "_OL", OBJPROP_BACK, false);
      ObjectSetInteger(0, base + "_OL", OBJPROP_ZORDER, 20);
      ObjectSetInteger(0, base + "_OL", OBJPROP_SELECTABLE, false);
      return;
   }

   // ГУД: тонкая горизонтальная зона дисбаланса (М/W)
   if(z.kind == SK_GUD)
   {
      const color gc = InkColor((z.direction > 0) ? ColorRM_Buy : ColorRM_Sell, ink);
      ObjectCreate(0, base + "_OL", OBJ_RECTANGLE, 0, z.t1, z.high, z.t2, z.low);
      ObjectSetInteger(0, base + "_OL", OBJPROP_COLOR, gc);
      ObjectSetInteger(0, base + "_OL", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, base + "_OL", OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, base + "_OL", OBJPROP_FILL, false);
      ObjectSetInteger(0, base + "_OL", OBJPROP_BACK, true);
      ObjectSetInteger(0, base + "_OL", OBJPROP_ZORDER, 15);
      ObjectSetInteger(0, base + "_OL", OBJPROP_SELECTABLE, false);
      if(ShowStructureLabels && ink >= 0.45)
      {
         DrawText(base + "_LBL", z.t1, z.high + 3 * PointValue(),
                  (StringLen(z.label) > 0 ? z.label : "ГУД"), gc, ANCHOR_LEFT_LOWER);
         ObjectSetInteger(0, base + "_LBL", OBJPROP_FONTSIZE, 7);
      }
      return;
   }

   color fill_c = ColorPD_Zone;
   if(z.kind == SK_ZU)
      fill_c = (z.direction > 0) ? ColorZU_Buy : ColorZU_Sell;
   else if(z.kind == SK_RM)
      fill_c = (z.direction > 0) ? ColorRM_Buy : ColorRM_Sell;
   else if(z.kind == SK_CASCADE)
      fill_c = (z.direction > 0) ? ColorZU_Buy : ColorZU_Sell;
   else if(z.pattern != PAT_NONE)
      fill_c = (z.direction > 0) ? ColorPatternBuy : ColorPatternSell;
   if(!z.valid)
      fill_c = clrDarkGray;
   color edge = InkColor(fill_c, ink);

   // Зона: по умолчанию ТОЛЬКО контур (без заливки) — иначе коричневое «пятно» перекрывает график
   if(ShowZoneFill && ink >= 0.45)
   {
      color fill = ToARGB(fill_c, (int)(((z.kind == SK_RM) ? 25 : (z.valid ? 28 : 18)) * ink));
      DrawRect(base + "_BOX", z.t1, z.high, z.t2, z.low, fill, true, true);
      ObjectSetInteger(0, base + "_BOX", OBJPROP_ZORDER, 1);
   }
   else if(ObjExists(base + "_BOX"))
      ObjectDelete(0, base + "_BOX");

   ObjectCreate(0, base + "_OL", OBJ_RECTANGLE, 0, z.t1, z.high, z.t2, z.low);
   ObjectSetInteger(0, base + "_OL", OBJPROP_COLOR, edge);
   ObjectSetInteger(0, base + "_OL", OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, base + "_OL", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, base + "_OL", OBJPROP_FILL, false);
   ObjectSetInteger(0, base + "_OL", OBJPROP_BACK, true);
   ObjectSetInteger(0, base + "_OL", OBJPROP_ZORDER, 1);
   ObjectSetInteger(0, base + "_OL", OBJPROP_SELECTABLE, false);

   // линия «30» рисуется один раз в DrawFib30Line() после всех зон

   if(ShowStructureLabels && ink >= 0.45)
   {
      string lbl = z.label;
      if(ShowPatternPercents && z.pct > 0.0)
         lbl = StringFormat("%s | %.0f%%", z.label, z.pct);
      if(StringLen(z.tf_tag) > 0)
         lbl = z.tf_tag + " " + lbl;
      DrawText(base + "_LBL", z.t1, z.high + 3 * PointValue(), lbl, edge, ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0, base + "_LBL", OBJPROP_FONTSIZE, 7);
   }
   else if(ObjExists(base + "_LBL"))
      ObjectDelete(0, base + "_LBL");
}

void PushStructureZoneEx(const int kind, const int pattern, const int direction,
                         const datetime t1, const datetime t2,
                         const double hi, const double lo,
                         const double range_x, const double pct,
                         const string label, const bool valid, const string tf_tag,
                         const double imp_start = 0.0, const double imp_end = 0.0)
{
   int n = ArraySize(g_structZones);
   if(n >= MaxStructureZones)
   {
      for(int i = 0; i < n - 1; i++)
         g_structZones[i] = g_structZones[i + 1];
      ArrayResize(g_structZones, n - 1);
      n = ArraySize(g_structZones);
   }
   ArrayResize(g_structZones, n + 1);
   g_structZones[n].active = true;
   g_structZones[n].kind = kind;
   g_structZones[n].pattern = pattern;
   g_structZones[n].direction = direction;
   g_structZones[n].t1 = t1;
   g_structZones[n].t2 = t2;
   g_structZones[n].high = hi;
   g_structZones[n].low = lo;
   g_structZones[n].range_x = range_x;
   g_structZones[n].pct = pct;
   g_structZones[n].imp_start = imp_start;
   g_structZones[n].imp_end = imp_end;
   g_structZones[n].label = label;
   g_structZones[n].tf_tag = tf_tag;
   g_structZones[n].id = ++g_structSeq;
   g_structZones[n].valid = valid;

   // алерты на появление
   if(valid)
   {
      if(kind == SK_RM)
         FireSniperAlert(ALT_RM, label);
      else if(kind == SK_ZU)
         FireSniperAlert(ALT_ZU, label);
      else if(kind == SK_PD)
         FireSniperAlert(ALT_PD, label);
      else if(kind == SK_CASCADE)
         FireSniperAlert(ALT_CASCADE, label);
      if(pattern != PAT_NONE)
         FireSniperAlert(ALT_PATTERN, PatternName(pattern) + " " + label);
   }
   else
      FireSniperAlert(ALT_CANCEL, label);
}

void PushStructureZone(const int kind, const int direction,
                       const datetime t1, const datetime t2,
                       const double hi, const double lo,
                       const double range_x, const string label, const bool valid)
{
   PushStructureZoneEx(kind, PAT_NONE, direction, t1, t2, hi, lo, range_x, 0.0, label, valid, "");
}

bool BuildSwingPointsTF(const MqlRates &rates[], SPivot &swings[], const int max_n, const int depth_in)
{
   ArrayResize(swings, 0);
   const int depth = MathMax(2, depth_in);
   const int total = ArraySize(rates);
   const int look = MathMin(total - depth - 2, MathMax(50, StructureLookbackBars));
   if(look < depth * 3)
      return false;

   SPivot tmp[];
   ArrayResize(tmp, 0);
   for(int shift = depth; shift < look; shift++)
   {
      if(IsPivotHigh(rates, shift, depth))
      {
         int k = ArraySize(tmp);
         ArrayResize(tmp, k + 1);
         tmp[k].t = rates[shift].time;
         tmp[k].p = rates[shift].high;
         tmp[k].type = 1;
      }
      if(IsPivotLow(rates, shift, depth))
      {
         int k = ArraySize(tmp);
         ArrayResize(tmp, k + 1);
         tmp[k].t = rates[shift].time;
         tmp[k].p = rates[shift].low;
         tmp[k].type = -1;
      }
   }

   int nall = ArraySize(tmp);
   for(int i = 0; i < nall - 1; i++)
      for(int j = i + 1; j < nall; j++)
         if(tmp[i].t > tmp[j].t)
         {
            SPivot sw = tmp[i]; tmp[i] = tmp[j]; tmp[j] = sw;
         }

   for(int i = 0; i < nall; i++)
   {
      int rn = ArraySize(swings);
      if(rn == 0)
      {
         ArrayResize(swings, 1);
         swings[0] = tmp[i];
         continue;
      }
      if(swings[rn - 1].type == tmp[i].type)
      {
         if(tmp[i].type == 1 && tmp[i].p >= swings[rn - 1].p)
            swings[rn - 1] = tmp[i];
         if(tmp[i].type == -1 && tmp[i].p <= swings[rn - 1].p)
            swings[rn - 1] = tmp[i];
      }
      else
      {
         ArrayResize(swings, rn + 1);
         swings[rn] = tmp[i];
      }
   }

   int rn = ArraySize(swings);
   if(rn > max_n)
   {
      SPivot keep[];
      ArrayResize(keep, max_n);
      for(int i = 0; i < max_n; i++)
         keep[i] = swings[rn - max_n + i];
      ArrayResize(swings, max_n);
      for(int i = 0; i < max_n; i++)
         swings[i] = keep[i];
   }
   return (ArraySize(swings) >= 4);
}

bool BuildSwingPoints(const MqlRates &rates[], SPivot &swings[], const int max_n)
{
   return BuildSwingPointsTF(rates, swings, max_n, EffectiveSwingDepth());
}

bool RangeHadConsolidation(const MqlRates &rates[], const datetime t_from, const datetime t_to, const double atr)
{
   // «диапазон» = узкий боковик до ретеста — запрет для ПД тип2
   if(atr <= 0.0) return false;
   double hi = -1e100, lo = 1e100;
   int cnt = 0;
   for(int i = 0; i < ArraySize(rates); i++)
   {
      if(rates[i].time < t_from || rates[i].time > t_to) continue;
      hi = MathMax(hi, rates[i].high);
      lo = MathMin(lo, rates[i].low);
      cnt++;
   }
   if(cnt < 5) return false;
   return ((hi - lo) <= 0.9 * atr && cnt >= 8);
}

// --- PAT 01: ПД тип 1 ---
// Скрины Снайпера: после ПД и отката ≥30% коррекционная зона НА экстремуме хода
// (дно нисходящего ПД = поддержка BUY; верх восходящего = сопротивление SELL).
// Вход — ретест этой зоны + РМ, не касание линии «30» и не пробой «за кончик».
void DetectPattern_PD_T1(const MqlRates &rates[], const SPivot &swings[], const string tf_tag)
{
   if(!ShowPullbackZones && !ShowAll12Patterns) return;
   SContinuedMove mv;
   if(!FindContinuedMove(rates, mv) || !mv.valid || !mv.retraced_30 || mv.cancelled_50)
      return;
   if(mv.range < MinContinuedMoveRange())
      return;

   int sec = PeriodSeconds(Timeframe);
   datetime now_t = rates[0].time;
   double atr = 0.0;
   GetBufferValue(g_hATR_Filter, 1, atr);

   datetime deadline = mv.t_tip + (datetime)(MathMax(1, PD_RetestMaxHours) * 3600);
   if(now_t > deadline)
      return;

   double zh = MathMax(PointValue() * 8.0, (atr > 0.0 ? MathMax(0.50, ZU_HeightATR_Mult) * atr : mv.range * 0.15));
   datetime t2a = now_t + (datetime)(sec * 30);
   datetime t2b = deadline + (datetime)(sec * 10);
   datetime t2 = (t2a < t2b ? t2a : t2b);
   double corr_pct = PD_MinCorrectionPct;

   if(mv.dir > 0)
   {
      PushStructureZoneEx(SK_PD, PAT_PD_T1, -1, mv.t_tip, t2,
                          mv.tip + zh * 0.25, mv.tip - zh, mv.range, corr_pct,
                          StringFormat("%s SELL КЗ верха", PatternName(PAT_PD_T1)), true, tf_tag,
                          mv.origin, mv.tip);
   }
   else
   {
      PushStructureZoneEx(SK_PD, PAT_PD_T1, 1, mv.t_tip, t2,
                          mv.tip + zh, mv.tip - zh * 0.25, mv.range, corr_pct,
                          StringFormat("%s BUY КЗ дна", PatternName(PAT_PD_T1)), true, tf_tag,
                          mv.origin, mv.tip);
   }
}

// --- PAT 02: ПД тип 2 (синий уровень, ≤6ч, без диапазонов, только 1-е ПД) ---
void DetectPattern_PD_T2(const MqlRates &rates[], const SPivot &swings[], const string tf_tag)
{
   if(!ShowPullbackZones && !ShowAll12Patterns) return;
   int n = ArraySize(swings);
   if(n < 4) return;
   int sec = PeriodSeconds(Timeframe);
   datetime now_t = rates[0].time;
   double atr = 0.0;
   GetBufferValue(g_hATR_Filter, 1, atr);

   // ищем первое ПД после смены тренда: диапазон -> выход ≥ PD_BreakoutPct% от X
   for(int i = 1; i < n - 2; i++)
   {
      double range_hi, range_lo;
      datetime t_hi, t_lo;
      if(swings[i].type == 1 && swings[i-1].type == -1)
      { range_hi = swings[i].p; t_hi = swings[i].t; range_lo = swings[i-1].p; t_lo = swings[i-1].t; }
      else if(swings[i].type == -1 && swings[i-1].type == 1)
      { range_lo = swings[i].p; t_lo = swings[i].t; range_hi = swings[i-1].p; t_hi = swings[i-1].t; }
      else continue;

      double X = range_hi - range_lo;
      if(X <= PointValue() * 5.0) continue;

      // следующее движение после диапазона
      SPivot nxt = swings[i + 1];
      double beyond = 0.0;
      int dir = 0;
      double blue = 0.0; // «синий» уровень
      if(nxt.type == 1 && nxt.p > range_hi)
      {
         beyond = nxt.p - range_hi;
         dir = 1;
         blue = range_hi; // ретест верхней границы диапазона снизу вверх после ПД вверх → для BUY тип2 часто тест синего
      }
      else if(nxt.type == -1 && nxt.p < range_lo)
      {
         beyond = range_lo - nxt.p;
         dir = -1;
         blue = range_lo;
      }
      else continue;

      double brk_pct = 100.0 * beyond / X;
      if(brk_pct < PD_BreakoutPct) continue; // ещё не ПД (нужно ≥123%)

      // после ПД ищем ретест blue в окне 6ч без диапазона
      datetime pd_t = nxt.t;
      datetime deadline = pd_t + (datetime)(MathMax(1, PD_RetestMaxHours) * 3600);
      if(now_t > deadline) continue;
      if(RangeHadConsolidation(rates, pd_t, (now_t < deadline ? now_t : deadline), atr))
         continue; // появились диапазоны — отмена тип2

      bool tested = false;
      for(int s = 0; s < ArraySize(rates); s++)
      {
         if(rates[s].time <= pd_t) break;
         if(rates[s].time > deadline) continue;
         if(dir > 0 && rates[s].low <= blue + 0.15 * atr)
            tested = true;
         if(dir < 0 && rates[s].high >= blue - 0.15 * atr)
            tested = true;
      }
      // зона у синего уровня даже до теста (ожидание)
      double zh = MathMax(PointValue() * 8.0, (atr > 0 ? ZU_HeightATR_Mult * atr : X * 0.2));
      double z_hi, z_lo;
      if(dir > 0) { z_hi = blue + zh; z_lo = blue - zh * 0.3; }
      else { z_hi = blue + zh * 0.3; z_lo = blue - zh; }

      // Sniper Fib: 0% = экстремум пробоя (nxt), 100% = противоположная граница диапазона
      double imp_start = (dir > 0) ? range_lo : range_hi;
      double imp_end   = nxt.p;
      double move_full = MathAbs(imp_end - imp_start);

      string lab = StringFormat("%s %s blue%s", PatternName(PAT_PD_T2), (dir>0?"BUY":"SELL"),
                                tested ? " TEST" : " wait");
      datetime t2_pd = now_t + (datetime)(sec*20);
      if(deadline < t2_pd) t2_pd = deadline;
      PushStructureZoneEx(SK_PD, PAT_PD_T2, dir, pd_t, t2_pd,
                          z_hi, z_lo, move_full, brk_pct, lab, true, tf_tag,
                          imp_start, imp_end);
      break; // только 1-е ПД
   }
}

// Классификация расширения: after PD / through PD / through LP / cascade
int ClassifyExpansion(const MqlRates &rates[], const SPivot &swings[],
                      const int idx_range, const datetime range_end,
                      const double range_hi, const double range_lo, const double X,
                      const datetime t_last, const int dir)
{
   // cascade expansion: несколько пробоев подряд в одну сторону до разворота
   int sweeps = 0;
   for(int i = MathMax(0, idx_range - 4); i <= idx_range; i++)
   {
      if(i + 1 >= ArraySize(swings)) break;
      if(dir > 0 && swings[i].type == -1 && swings[i+1].type == 1 && swings[i+1].p > swings[i].p)
         sweeps++;
      if(dir < 0 && swings[i].type == 1 && swings[i+1].type == -1 && swings[i+1].p < swings[i].p)
         sweeps++;
   }
   if(sweeps >= 3)
      return PAT_EXP_CASCADE;

   // through PD: после диапазона был вынос ≥ PD_BreakoutPct% затем разворот на другую сторону
   double max_up = 0, max_dn = 0;
   bool first_up = false, first_dn = false;
   datetime t_first_up = 0, t_first_dn = 0;
   for(int s = ArraySize(rates) - 1; s >= 0; s--)
   {
      if(rates[s].time <= range_end) continue;
      if(rates[s].high > range_hi)
      {
         if(!first_up) { first_up = true; t_first_up = rates[s].time; }
         max_up = MathMax(max_up, rates[s].high - range_hi);
      }
      if(rates[s].low < range_lo)
      {
         if(!first_dn) { first_dn = true; t_first_dn = rates[s].time; }
         max_dn = MathMax(max_dn, range_lo - rates[s].low);
      }
   }
   double first_leg = (t_first_up > 0 && (t_first_dn == 0 || t_first_up < t_first_dn)) ? max_up : max_dn;
   bool first_was_pd = (X > 0 && 100.0 * first_leg / X >= PD_BreakoutPct);

   // LP: ложный пробой до финального — wick за границу с возвратом
   bool had_lp = false;
   for(int s = 0; s < ArraySize(rates); s++)
   {
      if(rates[s].time <= range_end) break;
      double body = MathAbs(rates[s].close - rates[s].open);
      if(body <= 0) body = PointValue();
      if(dir > 0)
      {
         // до финального роста был ложный пробой вниз
         if(rates[s].time < t_last && rates[s].low < range_lo && rates[s].close > range_lo)
            if((range_lo - rates[s].low) > 0.5 * body) had_lp = true;
      }
      else
      {
         if(rates[s].time < t_last && rates[s].high > range_hi && rates[s].close < range_hi)
            if((rates[s].high - range_hi) > 0.5 * body) had_lp = true;
      }
   }

   if(had_lp && first_was_pd)
      return PAT_EXP_THROUGH_LP;
   if(first_was_pd)
      return PAT_EXP_THROUGH_PD;
   return PAT_EXP_AFTER_PD;
}

void DetectPattern_Expansions(const MqlRates &rates[], const SPivot &swings[], const string tf_tag)
{
   if(!ShowDecisionZones && !ShowAll12Patterns) return;
   int n = ArraySize(swings);
   if(n < 4) return;
   int sec = PeriodSeconds(Timeframe);
   datetime now_t = rates[0].time;
   double atr = 0.0;
   GetBufferValue(g_hATR_Filter, 1, atr);

   for(int i = 1; i < n - 1; i++)
   {
      double range_hi, range_lo;
      datetime t_hi, t_lo;
      if(swings[i].type == 1 && swings[i - 1].type == -1)
      { range_hi = swings[i].p; t_hi = swings[i].t; range_lo = swings[i - 1].p; t_lo = swings[i - 1].t; }
      else if(swings[i].type == -1 && swings[i - 1].type == 1)
      { range_lo = swings[i].p; t_lo = swings[i].t; range_hi = swings[i - 1].p; t_hi = swings[i - 1].t; }
      else continue;

      double X = range_hi - range_lo;
      if(X <= PointValue() * 5.0) continue;
      if(atr > 0.0 && X < 0.5 * atr) continue;
      datetime range_end = (t_hi > t_lo ? t_hi : t_lo);

      bool swept_high = false, swept_low = false;
      datetime t_sweep_h = 0, t_sweep_l = 0;
      double max_beyond_h = 0, max_beyond_l = 0;
      for(int s = 0; s < ArraySize(rates); s++)
      {
         if(rates[s].time <= range_end) break;
         if(rates[s].high > range_hi)
         {
            swept_high = true;
            if(t_sweep_h == 0 || rates[s].time > t_sweep_h) t_sweep_h = rates[s].time;
            max_beyond_h = MathMax(max_beyond_h, rates[s].high - range_hi);
         }
         if(rates[s].low < range_lo)
         {
            swept_low = true;
            if(t_sweep_l == 0 || rates[s].time > t_sweep_l) t_sweep_l = rates[s].time;
            max_beyond_l = MathMax(max_beyond_l, range_lo - rates[s].low);
         }
      }
      if(!(swept_high && swept_low)) continue;

      int dir = (t_sweep_h >= t_sweep_l) ? 1 : -1;
      datetime t_last = (dir > 0) ? t_sweep_h : t_sweep_l;
      double beyond = (dir > 0) ? max_beyond_h : max_beyond_l;
      double beyond_pct = (X > 0) ? (100.0 * beyond / X) : 0.0;
      bool valid = !(CascadeMaxBreakoutPct > 0.0 && beyond_pct > CascadeMaxBreakoutPct);

      int pat = ClassifyExpansion(rates, swings, i, range_end, range_hi, range_lo, X, t_last, dir);

      // Sniper-PRO: бокс ЗУ — компактный tip у экстремума; линия «30» рисуется отдельно от импульса.
      double move = X + beyond;
      double tip_h = MathMax(PointValue() * 8.0, (atr > 0 ? ZU_HeightATR_Mult * atr : move * 0.08));
      double extremum = (dir > 0) ? (range_hi + beyond) : (range_lo - beyond);
      double imp_start = (dir > 0) ? range_lo : range_hi;
      double z_hi, z_lo;
      if(dir > 0) { z_hi = extremum; z_lo = extremum - tip_h; }
      else        { z_lo = extremum; z_hi = extremum + tip_h; }

      string lab = valid
         ? StringFormat("%s %s ЗУ", PatternName(pat), (dir>0?"BUY":"SELL"))
         : StringFormat("%s %s ОТМЕНА", PatternName(pat), (dir>0?"BUY":"SELL"));
      if(valid || ShowCascadeMarks || ShowAll12Patterns)
         PushStructureZoneEx(SK_ZU, pat, dir, t_last, now_t + (datetime)(sec * MathMax(20, SightBarsWidth)),
                             z_hi, z_lo, move, beyond_pct, lab, valid, tf_tag,
                             imp_start, extremum);
   }
}

// --- Cascade patterns 1..6 ---
void DetectPattern_Cascades(const MqlRates &rates[], const SPivot &swings[], const string tf_tag)
{
   if(!ShowCascadeMarks && !ShowAll12Patterns) return;
   int n = ArraySize(swings);
   if(n < 6) return;
   int sec = PeriodSeconds(Timeframe);
   datetime now_t = rates[0].time;
   double atr = 0.0;
   GetBufferValue(g_hATR_Filter, 1, atr);

   for(int i = 3; i < n - 1; i++)
   {
      double b1_hi = MathMax(swings[i - 3].p, swings[i - 2].p);
      double b1_lo = MathMin(swings[i - 3].p, swings[i - 2].p);
      double b2_hi = MathMax(swings[i - 1].p, swings[i].p);
      double b2_lo = MathMin(swings[i - 1].p, swings[i].p);
      double X1 = b1_hi - b1_lo;
      double X2 = b2_hi - b2_lo;
      if(X1 <= 0 || X2 <= 0) continue;

      int dir = 0;
      if(b2_hi < b1_lo) dir = -1;      // каскад вниз
      else if(b2_lo > b1_hi) dir = 1;  // каскад вверх
      else continue;

      double breakout = (dir < 0) ? (b1_lo - b2_lo) : (b2_hi - b1_hi);
      double brk_pct = 100.0 * breakout / X1;
      bool valid = (brk_pct <= CascadeMaxBreakoutPct + 1e-9);

      // глубина отката во второй бокс относительно X1
      double reentry = 0.0;
      if(dir < 0)
      {
         // откат вверх в сторону b1
         reentry = MathMax(0.0, b2_hi - b1_lo);
      }
      else
      {
         reentry = MathMax(0.0, b1_hi - b2_lo);
      }
      // лучше: насколько цена зашла обратно в исходный бокс
      double pull_into = 0.0;
      if(dir < 0) // после пробоя вниз, откат вверх
         pull_into = MathMax(0.0, MathMin(b1_hi, b2_hi) - b1_lo);
      else
         pull_into = MathMax(0.0, b1_hi - MathMax(b1_lo, b2_lo));
      double pull_pct = 100.0 * pull_into / X1;

      int pat = PAT_CASC_5;
      if(brk_pct >= CascadeDeep150Pct * 0.9)
         pat = PAT_CASC_6;
      else if(pull_pct >= CascadeRetrace70Pct)
         pat = PAT_CASC_4; // продолжение
      else if(pull_pct > 0.0 && pull_pct <= CascadeRetrace50Pct)
         pat = PAT_CASC_3;
      else if(dir < 0 && b2_hi >= b1_hi - 0.05 * X1)
         pat = PAT_CASC_1; // ретест верхней границы
      else if(dir > 0 && b2_lo <= b1_lo + 0.05 * X1)
         pat = PAT_CASC_1;
      else if(pull_pct > CascadeRetrace50Pct && pull_pct < CascadeRetrace70Pct)
         pat = PAT_CASC_2;
      else
         pat = PAT_CASC_5;

      // для каскада 4 направление входа = продолжение каскада; 1-3 = разворот
      int entry_dir = dir;
      if(pat == PAT_CASC_1 || pat == PAT_CASC_2 || pat == PAT_CASC_3)
         entry_dir = -dir; // разворот каскада
      // 4,5,6 — по контексту: 4 продолжение, 5-6 структура

      datetime t1 = swings[i - 1].t;
      datetime t2 = now_t + (datetime)(sec * 25);
      string lab = valid
         ? StringFormat("%s %s", PatternName(pat), (entry_dir>0?"BUY":"SELL"))
         : StringFormat("%s ОТМЕНА (%.0f%%>%.0f%%)", PatternName(pat), brk_pct, CascadeMaxBreakoutPct);

      PushStructureZoneEx(SK_CASCADE, pat, entry_dir, t1, t2, b2_hi, b2_lo, X1,
                          (pat == PAT_CASC_4 || pat == PAT_CASC_3) ? pull_pct : brk_pct,
                          lab, valid, tf_tag);
   }
}

void DetectReversalMoments(const MqlRates &rates[], const string tf_tag)
{
   // Только последняя закрытая свеча. Исторические рамки не рисуем и не пересчитываем
   // от текущего ATR — иначе квадрат вспыхивает задним числом.
   const int n = ArraySize(rates);
   const int bars = MathMax(2, RM_ImpulseBars);
   const int shift = 1;
   if(n < shift + bars + 2) return;

   double atr = 0.0;
   if(!GetBufferValue(g_hATR_Filter, shift, atr) || atr <= 0.0) return;

   double up_move = 0.0, dn_move = 0.0;
   double win_hi = rates[shift].high, win_lo = rates[shift].low;
   for(int i = shift + 1; i <= shift + bars; i++)
   {
      up_move += MathMax(0.0, rates[i].close - rates[i].open);
      dn_move += MathMax(0.0, rates[i].open - rates[i].close);
      if(rates[i].high > win_hi) win_hi = rates[i].high;
      if(rates[i].low < win_lo) win_lo = rates[i].low;
   }

   MqlRates stall = rates[shift];
   const double body = MathAbs(stall.close - stall.open);
   if(body > RM_StallBodyATR_Max * atr) return;

   int dir = 0;
   if(up_move >= RM_ImpulseATR_Mult * atr && up_move > dn_move) dir = -1;
   else if(dn_move >= RM_ImpulseATR_Mult * atr && dn_move > up_move) dir = 1;
   else return;

   const double peak_pad = MathMax(8.0 * PointValue(), MathMax(0.0, RM_PeakATR_Pad) * atr);
   if(dir < 0 && stall.high + peak_pad < win_hi) return;
   if(dir > 0 && stall.low - peak_pad > win_lo) return;

   const int sec = PeriodSeconds(Timeframe);
   PushStructureZoneEx(SK_RM, PAT_NONE, dir, stall.time, stall.time + (datetime)sec,
                       stall.high, stall.low, 0.0, 0.0,
                       (dir > 0) ? "РМ ПОКУПКА" : "РМ ПРОДАЖА", true, tf_tag);
}

void DetectReversalMoments(const MqlRates &rates[])
{
   DetectReversalMoments(rates, "");
}

void UpdateBoundariesChannel(const MqlRates &rates[])
{
   DeleteObjectsWithPrefix(Prefix() + "BND_");
   g_boundActive = false;
   if(!ShowBoundariesChannel) return;
   int n = MathMin(ArraySize(rates), MathMax(10, BoundariesLookback));
   if(n < 10) return;
   double hi = rates[1].high, lo = rates[1].low;
   for(int i = 1; i < n; i++)
   {
      hi = MathMax(hi, rates[i].high);
      lo = MathMin(lo, rates[i].low);
   }
   g_boundHigh = hi;
   g_boundLow = lo;
   g_boundActive = true;
   int sec = PeriodSeconds(Timeframe);
   datetime t1 = rates[n - 1].time;
   datetime t2 = rates[0].time + (datetime)(sec * 5);
   ObjectCreate(0, Prefix() + "BND_HI", OBJ_TREND, 0, t1, hi, t2, hi);
   ObjectSetInteger(0, Prefix() + "BND_HI", OBJPROP_COLOR, ColorBoundaries);
   ObjectSetInteger(0, Prefix() + "BND_HI", OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, Prefix() + "BND_HI", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, Prefix() + "BND_HI", OBJPROP_RAY_RIGHT, true);
   ObjectSetInteger(0, Prefix() + "BND_HI", OBJPROP_SELECTABLE, false);
   ObjectCreate(0, Prefix() + "BND_LO", OBJ_TREND, 0, t1, lo, t2, lo);
   ObjectSetInteger(0, Prefix() + "BND_LO", OBJPROP_COLOR, ColorBoundaries);
   ObjectSetInteger(0, Prefix() + "BND_LO", OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, Prefix() + "BND_LO", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, Prefix() + "BND_LO", OBJPROP_RAY_RIGHT, true);
   ObjectSetInteger(0, Prefix() + "BND_LO", OBJPROP_SELECTABLE, false);
   DrawText(Prefix() + "BND_LBL", t2, hi, "границы", ColorBoundaries, ANCHOR_LEFT_LOWER);
}

void UpdateBalanceRSIPanel()
{
   DeleteObjectsWithPrefix(Prefix() + "RSI_");
   if(!ShowBalanceRSI || g_hRSI == INVALID_HANDLE) return;
   double rsi = 0.0;
   if(!GetBufferValue(g_hRSI, 0, rsi) && !GetBufferValue(g_hRSI, 1, rsi))
      return;

   string state = "БАЛАНС";
   color c = ColorBalanceRSI;
   if(rsi >= BalanceRSI_OB) { state = "ПЕРЕКУП"; c = ColorProbLow; }
   else if(rsi <= BalanceRSI_OS) { state = "ПЕРЕПРОД"; c = ColorProbHigh; }
   else if(rsi >= 55.0) { state = "бычий"; c = ColorProbHigh; }
   else if(rsi <= 45.0) { state = "медвежий"; c = ColorProbLow; }

   string name = Prefix() + "RSI_PANEL";
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 110);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 78);
   ObjectSetString(0, name, OBJPROP_TEXT, StringFormat("Balance RSI %.1f | %s", rsi, state));
   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

bool BalanceRSIAllows(const int direction)
{
   if(!FilterByBalanceRSI || g_hRSI == INVALID_HANDLE)
      return true;
   double rsi = 0.0;
   if(!GetBufferValue(g_hRSI, 1, rsi))
      return true;
   // BUY не в сильной перекупленности; SELL не в сильной перепроданности
   if(direction > 0 && rsi >= BalanceRSI_OB) return false;
   if(direction < 0 && rsi <= BalanceRSI_OS) return false;
   return true;
}

void DetectGUDLevels(const MqlRates &rates[], const SPivot &swings[], const string tf_tag)
{
   // ГУД по гайду: опора → ложный пробой / М(W) → уровень дисбаланса на минимуме M / максимуме W.
   if(!ShowGUDLevels) return;
   const int n = ArraySize(swings);
   if(n < 5) return;

   double atr = 0.0;
   GetBufferValue(g_hATR_Filter, 1, atr);
   const double min_move = MathMax(50.0 * PointValue(), (atr > 0.0 ? 0.8 * atr : 50.0 * PointValue()));
   const double tol = MathMax(10.0 * PointValue(), (atr > 0.0 ? 0.25 * atr : 10.0 * PointValue()));
   const int sec = PeriodSeconds(Timeframe);
   const datetime now_t = rates[0].time;
   const double zh = MathMax(PointValue() * 5.0, (atr > 0.0 ? 0.12 * atr : PointValue() * 5.0));

   // Ищем самые свежие конструкции справа налево
   for(int i = n - 1; i >= 4; i--)
   {
      // SELL: high - low - high - low(M trough≈support) - high  →  GUD на trough, dir=-1
      // упрощённо по последним 5 свингам с чередованием
      SPivot p0 = swings[i - 4];
      SPivot p1 = swings[i - 3];
      SPivot p2 = swings[i - 2];
      SPivot p3 = swings[i - 1];
      SPivot p4 = swings[i];

      // М наверху: H L H L H, где p3.low ≈ p0.high (опорный сегмент)
      if(p0.type > 0 && p1.type < 0 && p2.type > 0 && p3.type < 0 && p4.type > 0)
      {
         double support_high = p0.p;
         double move = p0.p - p1.p;
         if(move < min_move) continue;
         // минимум M (p3) около максимума опоры
         if(MathAbs(p3.p - support_high) > tol) continue;
         if(p2.p < support_high + 0.5 * min_move) continue; // М должна быть выше опоры

         double gud = p3.p;
         // уже пробит вниз?
         bool broken = false;
         for(int k = 0; k < ArraySize(rates); k++)
         {
            if(rates[k].time <= p4.t) break;
            if(rates[k].close < gud - 0.1 * (atr > 0 ? atr : PointValue() * 20))
            { broken = true; break; }
         }
         datetime t1 = p3.t;
         datetime t2 = now_t + (datetime)(sec * 30);
         string lab = broken ? "ГУД SELL (ретест)" : "ГУД SELL";
         PushStructureZoneEx(SK_GUD, PAT_NONE, -1, t1, t2,
                             gud + zh * 0.5, gud - zh * 0.5, move, 0.0, lab, true, tf_tag);
         break;
      }

      // W внизу: L H L H L → GUD на peak (p3), dir=+1
      if(p0.type < 0 && p1.type > 0 && p2.type < 0 && p3.type > 0 && p4.type < 0)
      {
         double support_low = p0.p;
         double move = p1.p - p0.p;
         if(move < min_move) continue;
         if(MathAbs(p3.p - support_low) > tol) continue;

         double gud = p3.p;
         bool broken = false;
         for(int k = 0; k < ArraySize(rates); k++)
         {
            if(rates[k].time <= p4.t) break;
            if(rates[k].close > gud + 0.1 * (atr > 0 ? atr : PointValue() * 20))
            { broken = true; break; }
         }
         datetime t1 = p3.t;
         datetime t2 = now_t + (datetime)(sec * 30);
         string lab = broken ? "ГУД BUY (ретест)" : "ГУД BUY";
         PushStructureZoneEx(SK_GUD, PAT_NONE, 1, t1, t2,
                             gud + zh * 0.5, gud - zh * 0.5, move, 0.0, lab, true, tf_tag);
         break;
      }
   }
}

void RunPatternEngineOnRates(const MqlRates &rates[], const string tf_tag, const int depth)
{
   SPivot swings[];
   if(!BuildSwingPointsTF(rates, swings, 48, depth))
   {
      DetectReversalMoments(rates, tf_tag);
      return;
   }
   DetectPattern_PD_T1(rates, swings, tf_tag);
   DetectPattern_PD_T2(rates, swings, tf_tag);
   DetectPattern_Expansions(rates, swings, tf_tag);
   DetectPattern_Cascades(rates, swings, tf_tag);
   DetectGUDLevels(rates, swings, tf_tag);
   DetectReversalMoments(rates, tf_tag);
}

void UpdateDualTFStructures()
{
   if(!UseVirtualTF)
      return;

   int need = MathMax(400, StructureLookbackBars + 50);
   int depth = EffectiveSwingDepth();

   if(FastTF != Timeframe)
   {
      MqlRates fast[];
      ArraySetAsSeries(fast, true);
      if(CopyRates(_Symbol, FastTF, 0, need, fast) >= 80)
         RunPatternEngineOnRates(fast, ShortTFName(FastTF), MathMax(2, depth / 2));
   }

   if(SlowTF == Timeframe)
      return;
   MqlRates slow[];
   ArraySetAsSeries(slow, true);
   if(CopyRates(_Symbol, SlowTF, 0, need, slow) < 80)
      return;
   RunPatternEngineOnRates(slow, ShortTFName(SlowTF), depth);
}

bool DetectMTFConfluence(const int direction)
{
   if(!UseVirtualTF || direction == 0)
      return false;
   string slow_tag = ShortTFName(SlowTF);
   string fast_tag = ShortTFName(FastTF);
   bool fast_ok = false, slow_ok = false;
   for(int i = 0; i < ArraySize(g_structZones); i++)
   {
      if(!g_structZones[i].valid || g_structZones[i].direction != direction) continue;
      if(g_structZones[i].kind == SK_RM) continue;
      if(g_structZones[i].tf_tag == fast_tag || (FastTF == Timeframe && (StringLen(g_structZones[i].tf_tag) == 0 || g_structZones[i].tf_tag == ShortTFName(Timeframe))))
         fast_ok = true;
      if(g_structZones[i].tf_tag == slow_tag)
         slow_ok = true;
   }
   return (fast_ok && slow_ok);
}

bool HasMTFConfluence(const int direction)
{
   if(!RequireMTFConfluence)
      return true;
   return DetectMTFConfluence(direction);
}

void CheckMTFConfluenceAlert()
{
   if(!UseVirtualTF || !Alert_MTF) return;
   int chart_dir = 0, slow_dir = 0;
   string slow_tag = ShortTFName(SlowTF);
   string fast_tag = ShortTFName(FastTF);
   for(int i = 0; i < ArraySize(g_structZones); i++)
   {
      if(!g_structZones[i].valid) continue;
      if(g_structZones[i].tf_tag == fast_tag || (StringLen(g_structZones[i].tf_tag) == 0 && FastTF == Timeframe) || g_structZones[i].tf_tag == ShortTFName(Timeframe))
      {
         if(chart_dir == 0 && g_structZones[i].direction != 0 && g_structZones[i].kind != SK_RM)
            chart_dir = g_structZones[i].direction;
      }
      if(g_structZones[i].tf_tag == slow_tag)
      {
         if(slow_dir == 0 && g_structZones[i].direction != 0 && g_structZones[i].kind != SK_RM)
            slow_dir = g_structZones[i].direction;
      }
   }
   if(chart_dir != 0 && chart_dir == slow_dir)
      FireSniperAlert(ALT_MTF, StringFormat("совпадение %s+%s%s", fast_tag, slow_tag, (chart_dir>0?" BUY":" SELL")));
}

void UpdateSniperStructures(const MqlRates &rates[])
{
   ClearStructureObjects();
   ArrayResize(g_structZones, 0);

   UpdateBoundariesChannel(rates);
   UpdateBalanceRSIPanel();

   if(!ShowDecisionZones && !ShowPullbackZones && !ShowCascadeMarks && !ShowReversalMoments && !ShowAll12Patterns && !ShowGUDLevels)
   {
      if(UseVirtualTF) UpdateDualTFStructures();
      return;
   }

   // основной ТФ графика (Fast / chart)
   string tag = UseVirtualTF ? ShortTFName(Timeframe) : "";
   RunPatternEngineOnRates(rates, tag, EffectiveSwingDepth());

   // Slow TF (M15) поверх
   UpdateDualTFStructures();
   CheckMTFConfluenceAlert();

   string chart_tag = ShortTFName(Timeframe);
   for(int i = 0; i < ArraySize(g_structZones); i++)
   {
      if(!g_structZones[i].valid && g_structZones[i].kind != SK_CASCADE && g_structZones[i].kind != SK_ZU)
         continue;
      // не рисовать чужие ТФ, если ShowSlowTFStructures=false
      if(!ShowSlowTFStructures && StringLen(g_structZones[i].tf_tag) > 0
         && g_structZones[i].tf_tag != chart_tag)
         continue;
      DrawStructureZone(g_structZones[i]);
   }
   // Fib30 — после UpdateSight (см. RefreshSniperContext), здесь не рисуем
}


void ApplyProbabilityHUD(const bool push_history)
{
   int fear = ComputeFearIndex();
   ComputeContextProbability(); // обновляет g_lastSetupQuality для опционального лота
   if(push_history)
   {
      if(MathAbs(fear - g_lastFearIndex) >= 1 || ArraySize(g_probHistory) == 0)
         PushProbability(fear);
      else
         g_lastFearIndex = fear;
   }
   else
   {
      g_lastFearIndex = fear;
      g_lastProbability = fear;
      static int s_live_push_counter = 0;
      s_live_push_counter++;
      if(s_live_push_counter >= 5)
      {
         s_live_push_counter = 0;
         PushProbability(fear);
      }
   }
   UpdateFearIndexHUD(g_lastFearIndex);
}

// Закрытие бара: можно сменить сторону прицела
void RefreshSniperContext(const MqlRates &rates[])
{
   RebuildSessions(rates[0].time);
   DrawSessionLevels();
   UpdateLiquidityZones(rates);
   UpdateSniperStructures(rates); // ЗУ / ПД / каскад / РМ (на закрытии бара)
   UpdateSight(rates);            // сторона прицела ДО Fib30
   DrawFib30Line(rates);          // актуальная «30» справа у новых свечей
   ApplyProbabilityHUD(true);
}

// Внутри бара: % динамический; сторона прицела зафиксирована.
// Сессии/ликвидность/структуры — ТОЛЬКО на закрытии бара (иначе мигание надписей).
void RefreshContextLive()
{
   if(!DynamicProbability)
      return;

   const int sec_wait = MathMax(1, ContextUpdateSeconds);
   const uint now_ms = GetTickCount();
   if(g_lastContextExecMs != 0 && (uint)(now_ms - g_lastContextExecMs) < (uint)(sec_wait * 1000))
      return;
   g_lastContextExecMs = now_ms;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int need = MathMax(400, CZ_LookbackN + 30);
   int copied = CopyRates(_Symbol, Timeframe, 0, need, rates);
   if(copied < (CZ_LookbackN + 10))
      return;

   if(SightRecalcOnBarCloseOnly)
      MaintainSightIntrabar(rates);
   else
      UpdateSight(rates);

   DrawFib30Line(rates); // подтянуть «30» к актуальному свингу

   ApplyProbabilityHUD(false);
}

bool PassProbabilityGate(const int setup_quality, string &why)
{
   why = "";
   int min_q = MathMax(SetupQualityMinToTrade, ProbMinToTrade);
   if(min_q <= 0)
      return true;
   if(setup_quality < min_q)
   {
      why = StringFormat("blocked: setup %d < %d", setup_quality, min_q);
      return false;
   }
   return true;
}

double ApplyProbabilityToVolume(const double volume, const int setup_quality)
{
   if(!(ScaleLotBySetupQuality || ScaleLotByProbability))
      return volume;
   double scaled = volume * (MathMax(5, setup_quality) / 100.0);
   return ClampVolume(scaled);
}

int EffectiveSafeStep1Points(const double entry, const double sl)
{
   if(!UseSafeRule)
      return PC_Step1;
   double p = PointValue();
   if(p <= 0.0)
      return PC_Step1;
   int one_r = (int)MathRound(MathAbs(entry - sl) / p);
   if(one_r < 1)
      one_r = PC_Step1;
   if(g_lastImpulseRange > p && SafeImpulseK > 0.0)
   {
      int by_imp = (int)MathRound(SafeImpulseK * g_lastImpulseRange / p);
      if(by_imp > 0 && by_imp < one_r)
         one_r = by_imp;
   }
   // минимум — типичный/живой спред в пунктах MT5
   double spr = EffectiveSpreadPrice();
   int spr_pts = (p > 0.0) ? (int)MathRound(spr / p) : 0;
   if(spr_pts > 0 && one_r < spr_pts)
      one_r = spr_pts;
   return one_r;
}

double ComputeSafeTpPrice(const int direction, const double entry, const double sl)
{
   double p = PointValue();
   if(p <= 0.0 || entry <= 0.0)
      return 0.0;
   int step_pts = EffectiveSafeStep1Points(entry, sl);
   if(!UseSafeRule && PC_Step1 > 0)
      step_pts = PC_Step1;
   double dist = (double)MathMax(1, step_pts) * p;
   double spr = EffectiveSpreadPrice();
   if(dist < spr + p)
      dist = spr + p;
   if(direction > 0)
      return NormalizePrice(entry + dist);
   return NormalizePrice(entry - dist);
}

bool PassBreakoutQuality(const MqlRates &bar, string &why)
{
   why = "";
   if(!BlockWeakBreakouts)
      return true;
   double atr = 0.0;
   if(!GetBufferValue(g_hATR_Filter, 1, atr) || atr <= 0.0)
      return true;
   double body = MathAbs(bar.close - bar.open);
   if(body < BreakoutBodyATR_Min * atr)
   {
      why = "blocked: weak breakout body";
      return false;
   }
   return true;
}


//=========================
// Core logic: signal evaluation + trade execution
//=========================
int MaxTradesPerZone()
{
   return (1 + MathMax(0, ReEntries));
}

bool CanEnterNow(const datetime signal_bar_time, string &reason)
{
   reason = "";

   if(MaxPositions > 0)
   {
      int pos = CountMyPositions();
      if(pos >= MaxPositions)
      {
         Log("Entry blocked: MaxPositions reached");
         reason = "blocked: MaxPositions";
         return false;
      }
   }

   if(g_MaxSpread_Eff > 0)
   {
      int spread = CurrentSpreadPoints();
      if(spread > g_MaxSpread_Eff)
      {
         Log(StringFormat("Entry blocked: spread %d > MaxSpread %d", spread, g_MaxSpread_Eff));
         reason = StringFormat("blocked: spread %d > %d", spread, g_MaxSpread_Eff);
         return false;
      }
   }

   if(OnlyOneTradePerBar)
   {
      if(g_lastTradeBarTime == signal_bar_time)
      {
         Log("Entry blocked: OnlyOneTradePerBar");
         reason = "blocked: OnlyOneTradePerBar";
         return false;
      }
   }

   return true;
}

void MarkTradeInBar(const datetime signal_bar_time)
{
   g_lastTradeBarTime = signal_bar_time;
}

void BuildSLTP(const int direction, const double entry, const double zone_high, const double zone_low, double &sl, double &tp)
{
   double p = PointValue();
   double spr = EffectiveSpreadPrice();

   // SL
   if(SL_Mode == SL_FIXED)
   {
      sl = (direction > 0) ? (entry - SL_Points * p) : (entry + SL_Points * p);
   }
   else
   {
      sl = (direction > 0) ? (zone_low - SL_Offset * p) : (zone_high + SL_Offset * p);
   }
   double atr_sl = 0.0;
   GetBufferValue(g_hATR_Filter, 1, atr_sl);
   if(atr_sl > 0.0 && SL_AtrPad > 0.0)
   {
      if(direction > 0)
         sl -= SL_AtrPad * atr_sl;
      else
         sl += SL_AtrPad * atr_sl;
   }
   // Спред POINT/живой: отодвигаем SL от цены входа (реальный риск с учётом ask/bid)
   if(spr > 0.0)
   {
      if(direction > 0)
         sl -= spr;
      else
         sl += spr;
   }

   // TP: импульс (полное продолжение) или индекс страха 1R/2R/3R
   if(AutoTPByFearIndex && TP_Mode == TP_FIXED)
   {
      double rr = FearIndexRewardMult(ComputeFearIndex());
      double sl_dist = MathAbs(entry - sl);
      if(sl_dist <= 0.0)
         sl_dist = SL_Points * p;
      tp = (direction > 0) ? (entry + rr * sl_dist) : (entry - rr * sl_dist);
   }
   else if(g_lastImpulseRange > p && TP_ImpulseK > 0.0)
   {
      tp = (direction > 0) ? (entry + TP_ImpulseK * g_lastImpulseRange)
                           : (entry - TP_ImpulseK * g_lastImpulseRange);
   }
   else if(TP_Mode == TP_FIXED)
   {
      tp = (direction > 0) ? (entry + TP_Points * p) : (entry - TP_Points * p);
   }
   else
   {
      tp = (direction > 0) ? (zone_high + TP_Offset * p) : (zone_low - TP_Offset * p);
   }

   sl = NormalizePrice(sl);
   tp = NormalizePrice(tp);

   AdjustStopsToBroker(direction, entry, sl, tp);
}

bool ExecuteSignal(const string sig, const int direction, const MqlRates &signal_bar, const double zone_high, const double zone_low, int &trades_done)
{
   datetime last_closed = iTime(_Symbol, Timeframe, 1);
   datetime cur_open = iTime(_Symbol, Timeframe, 0);
   if(signal_bar.time != last_closed && signal_bar.time != cur_open)
      return false;

   const bool reentries_ok = (trades_done < MaxTradesPerZone());

   // entry at market (current)
   double entry = (direction > 0) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double sl=0.0, tp=0.0;
   BuildSLTP(direction, entry, zone_high, zone_low, sl, tp);

   // Filters must not change the fact of signal formation; they only block the entry (TZ 1.4 / 4.4).
   bool ema_ok = PassEMAFiltro(direction, signal_bar);
   bool atr_ok = PassATRFiltro(signal_bar);
   bool session_ok = PassServerSession();
   bool rr_ok = PassMinRewardToRisk(direction, entry, sl, tp);

   // Индекс страха на HUD; зрелость сетапа — только для опционального лота/гейта
   int fear = ComputeFearIndex();
   int setup_q = ComputeProbability(sig, direction, signal_bar);
   g_lastSetupQuality = setup_q;
   PushProbability(fear);
   UpdateFearIndexHUD(fear);

   string sight_why = "";
   bool sight_ok = PassSightFilter(direction, sight_why);
   string prob_why = "";
   bool prob_ok = PassProbabilityGate(setup_q, prob_why);
   string fear_why = "";
   bool fear_ok = FearIndexAllows(direction, fear_why);

   string breakout_why = "";
   bool breakout_ok = true;
   if(sig == "A")
      breakout_ok = PassBreakoutQuality(signal_bar, breakout_why);

   string align_why = "";
   bool align_ok = true;
   if(sig == "A")
      align_ok = PassSightAlignmentForBreakout(direction, align_why);

   string rsi_why = "";
   bool rsi_ok = BalanceRSIAllows(direction);
   if(!rsi_ok) rsi_why = "Balance RSI filter";

   string mtf_why = "";
   bool mtf_ok = HasMTFConfluence(direction);
   if(!mtf_ok) mtf_why = "нет совпадения M1/M15";

   string pattern_name = "";
   {
      MqlRates prev_arr[];
      ArraySetAsSeries(prev_arr, true);
      int sh = iBarShift(_Symbol, Timeframe, signal_bar.time, true);
      if(sh >= 0 && CopyRates(_Symbol, Timeframe, sh, 2, prev_arr) >= 2)
         pattern_name = DetectPatternName(direction, prev_arr[0], prev_arr[1]);
   }

   // Build a human-readable status for marker/alerts (TZ 4.9: reasons for blocks must be visible in logs).
   // NOTE: status is for user-facing marker/alerts; Log() is still the primary source of truth.
   string status = "";

   bool can_enter = true;
   string enter_block_reason = "";

   if(!TradeEnabled)
   {
      status = "signals only";
      can_enter = false;
   }
   else
   {
      if(!reentries_ok)
      {
         status = "blocked: ReEntries limit";
         can_enter = false;
         Log("Entry blocked: ReEntries limit reached for zone");
      }
      else if(!ema_ok && !atr_ok)
      {
         status = "blocked: EMA+ATR";
         can_enter = false;
      }
      else if(!ema_ok)
      {
         status = "blocked: EMA";
         can_enter = false;
      }
      else if(!atr_ok)
      {
         status = "blocked: ATR";
         can_enter = false;
      }
      else if(!session_ok)
      {
         status = "blocked: session";
         can_enter = false;
      }
      else if(!rr_ok)
      {
         status = "blocked: MinRR";
         can_enter = false;
      }
      else if(!breakout_ok)
      {
         status = breakout_why;
         can_enter = false;
         Log("Entry blocked: " + breakout_why);
      }
      else if(!align_ok)
      {
         status = align_why;
         can_enter = false;
         Log("Entry blocked: " + align_why);
      }
      else if(!sight_ok)
      {
         status = sight_why;
         can_enter = false;
         Log("Entry blocked: " + sight_why);
      }
      else if(!prob_ok)
      {
         status = prob_why;
         can_enter = false;
         Log("Entry blocked: " + prob_why);
      }
      else if(!fear_ok)
      {
         status = fear_why;
         can_enter = false;
         Log("Entry blocked: " + fear_why);
      }
      else if(!rsi_ok)
      {
         status = "blocked: " + rsi_why;
         can_enter = false;
         Log("Entry blocked: " + rsi_why);
      }
      else if(!mtf_ok)
      {
         status = "blocked: " + mtf_why;
         can_enter = false;
         Log("Entry blocked: " + mtf_why);
      }
      else
      {
         // Protections (spread/limits) must block entry but keep the signal.
         if(!CanEnterNow(signal_bar.time, enter_block_reason))
         {
            status = enter_block_reason;
            can_enter = false;
         }
      }
   }

   if(status == "" && TradeEnabled)
      status = StringFormat("Fear=%d %s RR=1:%.0f", fear, FearIndexZoneName(fear), FearIndexRewardMult(fear));
   else if(status != "" && StringFind(status, "Fear=") < 0)
      status = status + StringFormat(" | Fear=%d", fear);

   if(pattern_name != "" && StringFind(status, pattern_name) < 0)
      status = (status == "" ? pattern_name : (pattern_name + " | " + status));

   // Visual marker must be placed on the entry candle (TZ 1.7 / 4.7).
   // In bar-close mode, signal_bar is the last closed bar (shift=1), while entry occurs on the next bar (shift=0).
   // To preserve existing signal logic, we keep signal_bar for checks but draw the marker on the entry bar.
   MqlRates vis_bar = signal_bar;
   datetime cur_bar_time = iTime(_Symbol, Timeframe, 0);
   if(cur_bar_time > 0 && vis_bar.time != cur_bar_time)
   {
      vis_bar.time = cur_bar_time;
      double pad = MathMax(3, BreakCloseOffset) * PointValue();
      vis_bar.high = entry + pad;
      vis_bar.low  = entry - pad;
   }

   string chart_note = (direction > 0) ? "покупка" : "продажа";
   if(g_lastImpulseDir != 0)
      chart_note += (direction == g_lastImpulseDir) ? " | по ходу" : " | против хода";
   if(g_sightActive && g_sightDirection != 0 && g_sightDirection != direction)
      chart_note += " | против прицела";
   if(!fear_ok)
      chart_note += " | индекс страха запрещает";
   else
      chart_note += StringFormat(" | страх %d", fear);

   VisualizeSignal(sig, direction, vis_bar, entry, sl, tp, status, chart_note);

   // Алерт ТОЛЬКО при появлении стрелки входа (не на зоны/прицел/сессии/блокировки)
   string msg = sig + " " + (direction > 0 ? "BUY" : "SELL") + " " + _Symbol;
   if(ShowArrows)
      FireSniperAlert(ALT_ENTRY, msg);
   else
      Log(msg + (status != "" ? (" [" + status + "]") : ""));

   if(!TradeEnabled)
      return true;

   // Block entry if filters fail (but keep signal visuals/logs)
   if(!ema_ok)
      Log("Entry blocked by EMA filter");
   if(!atr_ok)
      Log("Entry blocked by ATR filter");
   if(!ema_ok || !atr_ok)
      return false;

   if(!session_ok)
      Log("Entry blocked by session filter");
   if(!rr_ok)
      Log("Entry blocked by MinRewardToRisk");
   if(!session_ok || !rr_ok)
      return false;

   // Block entry by protections (spread/limits)
   if(!can_enter)
      return false;

   double volume = 0.0;

   if(LotMode == LOT_FIXED)
   {
      volume = ClampVolume(Lot);
   }
   else
   {
      double sl_points = MathAbs(entry - sl) / PointValue();
      volume = CalcLotByRiskPercent(Percent, sl_points);
      // Fallback to fixed lot if dynamic calculation fails (cold-start / missing symbol data)
      if(volume <= 0.0 && Lot > 0.0)
      {
         Log(StringFormat("Dynamic lot calc failed (sl_pts=%.1f), falling back to fixed Lot=%.2f", sl_points, Lot));
         volume = ClampVolume(Lot);
      }
   }

   // Sniper probability scales recommended relative volume (percent HUD).
   double vol_before = volume;
   volume = ApplyProbabilityToVolume(volume, setup_q);
   if((ScaleLotBySetupQuality || ScaleLotByProbability) && volume != vol_before)
      Log(StringFormat("Setup volume scale: Q=%d  %.2f -> %.2f | Fear=%d", setup_q, vol_before, volume, fear));

   if(volume <= 0.0)
   {
      Log("Volume is zero, cannot trade");
      return false;
   }

   ulong deal = 0;
   string comment = CommentPrefix + " " + sig + " F" + IntegerToString(fear);
   if(SendDeal(direction, volume, sl, tp, comment, deal))
   {
      trades_done++;
      MarkTradeInBar(signal_bar.time);
      Log(StringFormat("Trade opened %s vol=%.2f deal=%I64u Fear=%d RR=1:%.0f",
                       (direction > 0 ? "BUY" : "SELL"), volume, deal, fear, FearIndexRewardMult(fear)));

      // Стрелочный алерт уже отправлен выше; здесь только лог сделки
      Log(StringFormat("Deal OK %s", msg));
      return true;
   }

   // If SendDeal failed despite passing all filters, notify the user
   // so the lost trade is visible. (v2.0: fixed undefined `res` from v1.11)
   if(TradeEnabled)
   {
      int err = GetLastError();
      Log(StringFormat("SendDeal failed: last_error=%d", err));
      Notify(msg + " [SendDeal failed last_error=" + IntegerToString(err) + "]");
   }
   return false;
}

void TryPDT1EntryFromRM(const MqlRates &rates[])
{
   if(ArraySize(rates) <= 2)
      return;
   const MqlRates bar = rates[1];
   const MqlRates prev = rates[2];

   SContinuedMove mv;
   if(!FindContinuedMove(rates, mv) || !mv.valid || !mv.retraced_30 || mv.cancelled_50)
      return;
   if(bar.time <= mv.t_tip)
      return;
   // Один алерт/стрелка на этот кончик, пока tip не продлён подтверждённо.
   if(g_pdT1SpentTip != 0 && g_pdT1SpentTip == mv.t_tip)
      return;

   const int want = (mv.dir > 0) ? -1 : 1;
   if(!BarHasReversalMoment(bar.time, want))
      return;
   if(!PassPriceAction(want, bar, prev))
      return;

   double atr = 0.0;
   GetBufferValue(g_hATR_Filter, 1, atr);
   const double band = MathMax(8.0 * PointValue(), (atr > 0.0 ? MathMax(0.50, ZU_HeightATR_Mult) * atr : mv.range * 0.15));
   const double fib30 = mv.tip + (PD_MinCorrectionPct / 100.0) * (mv.origin - mv.tip);
   // Возврат к экстремуму (после касания «30»):
   // A) тень в зоне tip±40% пути tip→«30» + разворотная свеча (ложный пробой, Z не продлён);
   // B) либо закрытие в той же полосе без выноса за tip.
   const double near = 0.40 * MathAbs(mv.tip - fib30);
   if(near < PointValue())
      return;
   if(mv.dir > 0)
   {
      if(bar.close > mv.tip)
         return;
      const bool close_in = (bar.close + PointValue() >= mv.tip - near);
      const bool wick_in = (bar.high + PointValue() >= mv.tip - near);
      const bool rev = BarLooksLikeStopOrReversalAgainst(1, bar, prev, atr);
      if(!close_in && !(wick_in && rev))
         return;
   }
   else
   {
      if(bar.close < mv.tip)
         return;
      const bool close_in = (bar.close - PointValue() <= mv.tip + near);
      const bool wick_in = (bar.low - PointValue() <= mv.tip + near);
      const bool rev = BarLooksLikeStopOrReversalAgainst(-1, bar, prev, atr);
      if(!close_in && !(wick_in && rev))
         return;
   }

   double z_hi = (mv.dir > 0) ? (mv.tip + band * 0.25) : (mv.tip + band);
   double z_lo = (mv.dir > 0) ? (mv.tip - band) : (mv.tip - band * 0.25);
   ExecuteSignal("B", want, bar, z_hi, z_lo, g_pdT1Trades);
   g_pdT1SpentTip = mv.t_tip;
}

//=========================
// Active zone: evaluate A/B
//=========================
void ProcessActiveZone(const MqlRates &rates[])
{
   if(!g_zone.active)
      return;

   const int shift = 1; // last closed bar
   if(ArraySize(rates) <= shift + 2)
      return;

   MqlRates bar = rates[shift];
   MqlRates prev = rates[shift + 1];

   double p = PointValue();
   double offset = BreakCloseOffset * p;

   // Breakout / invalidation (by close with offset) + optional Signal A
   bool breakout_up = (bar.close >= (g_zone.high + offset));
   bool breakout_dn = (bar.close <= (g_zone.low - offset));

   if(breakout_up || breakout_dn)
   {
      int dir = breakout_up ? 1 : -1;

      // Execute Signal A only when enabled; zone invalidation is independent from signal toggles
      if(g_EnableSignalA)
      {
         if(PassPriceAction(dir, bar, prev))
            ExecuteSignal("A", dir, bar, g_zone.high, g_zone.low, g_zone.trades_done);
      }

      // finalize zone drawing (end at breakout close / next bar open)
      datetime break_time = rates[0].time;
      g_lastZoneInvalidationTime = break_time;
      DrawZoneObject(g_zone, true, break_time);

      // move to broken zone for retest scenario (Signal C may be enabled even if A is disabled)
      g_broken.active = g_EnableSignalC;
      if(g_broken.active)
      {
         g_broken.start = g_zone.start;
         g_broken.end = break_time;
         g_broken.high = g_zone.high;
         g_broken.low  = g_zone.low;
         g_broken.id   = g_zone.id;
         g_broken.direction = dir;
         g_broken.retest_touched = false;
         g_broken.retest_touch_time = 0;
         // Important: keep the total trades-per-zone limit across A/B/C
         g_broken.trades_done = g_zone.trades_done;
         g_broken.bars_after_break = 0;
      }
      else
      {
         // Ensure old broken state is not left active when C is disabled
         g_broken.active = false;
      }

      // deactivate active zone
      g_zone.active = false;
      return;
   }

   // B) false breakout / stop-run: wick beyond level, close inside (Sniper fade)
   if(g_EnableSignalB)
   {
      bool close_inside = (bar.close <= g_zone.high && bar.close >= g_zone.low);
      if(close_inside)
      {
         double body = MathAbs(bar.close - bar.open);
         if(body < p)
            body = p;

         double wick_up = 0.0;
         double wick_dn = 0.0;

         if(bar.high > g_zone.high)
            wick_up = bar.high - g_zone.high;
         if(bar.low < g_zone.low)
            wick_dn = g_zone.low - bar.low;

         bool up_ok = (wick_up > 0.0 && wick_up > g_WickRatio_Eff * body);
         bool dn_ok = (wick_dn > 0.0 && wick_dn > g_WickRatio_Eff * body);

         int dir = 0;
         if(up_ok && dn_ok)
            dir = (wick_up >= wick_dn) ? -1 : 1; // only stronger liquidity grab
         else if(up_ok)
            dir = -1;
         else if(dn_ok)
            dir = 1;

         // Optional: prefer fades aligned with sight / session liquidity
         if(dir != 0 && PreferLiquidityFade && g_sightActive && g_sightDirection != 0 && g_sightDirection != dir)
         {
            Log("Signal B skipped: opposite to active sight direction");
            dir = 0;
         }

         if(dir != 0 && PassPriceAction(dir, bar, prev))
            ExecuteSignal("B", dir, bar, g_zone.high, g_zone.low, g_zone.trades_done);
      }
   }
}

//=========================
// Broken zone: evaluate C retest
//=========================
void ProcessBrokenZone(const MqlRates &rates[])
{
   if(!g_broken.active)
      return;

   const int shift = 1;
   if(ArraySize(rates) <= shift + 2)
      return;

   MqlRates bar = rates[shift];
   MqlRates prev = rates[shift + 1];

   double p = PointValue();
   double depth = RetestDepth * p;
   double offset = BreakCloseOffset * p;

   g_broken.bars_after_break++;

   if(!g_EnableSignalC)
      return;

   // limit trades per broken zone
   if(g_broken.trades_done >= MaxTradesPerZone())
      return;

   if(!g_broken.retest_touched)
   {
      if(g_broken.direction > 0)
      {
         // breakout up => retest inside zone by depth
         bool touch = (bar.close <= (g_broken.high - depth) && bar.close >= g_broken.low);
         if(touch)
         {
            g_broken.retest_touched = true;
            g_broken.retest_touch_time = bar.time;
         }
      }
      else
      {
         // breakout down
         bool touch = (bar.close >= (g_broken.low + depth) && bar.close <= g_broken.high);
         if(touch)
         {
            g_broken.retest_touched = true;
            g_broken.retest_touch_time = bar.time;
         }
      }
      return;
   }

   // confirmation: close back outside in breakout direction
   if(g_broken.direction > 0)
   {
      bool confirm = (bar.close >= (g_broken.high + offset));
      if(confirm)
      {
         if(PassPriceAction(1, bar, prev))
         {
            ExecuteSignal("C", 1, bar, g_broken.high, g_broken.low, g_broken.trades_done);
            g_broken.retest_touched = false;
         }
      }
   }
   else
   {
      bool confirm = (bar.close <= (g_broken.low - offset));
      if(confirm)
      {
         if(PassPriceAction(-1, bar, prev))
         {
            ExecuteSignal("C", -1, bar, g_broken.high, g_broken.low, g_broken.trades_done);
            g_broken.retest_touched = false;
         }
      }
   }

   // optional expiry: tighter window in v2.0 (Sniper retests are timely)
   int max_bars = MathMax(20, BrokenZoneMaxBars);
   if(g_broken.bars_after_break > max_bars)
      g_broken.active = false;
}

//=========================
// Zone update on new bar
//=========================
void UpdateZones(const MqlRates &rates[])
{
   // Update / create active zone
   if(!g_zone.active)
   {
   /* guard: avoid creating a new zone in the same bar where the previous zone was invalidated */
   if(g_lastZoneInvalidationTime == rates[0].time)
      return;

      double zh=0, zl=0;
      if(IsConsolidation(rates, zh, zl))
      {
         g_zoneSeq++;
         g_zone.active = true;
         g_zone.id = g_zoneSeq;
         g_zone.high = zh;
         g_zone.low  = zl;
         g_zone.trades_done = 0;
         g_zone.last_update = rates[0].time;
         // start at oldest bar of window
         int start_shift = 1 + CZ_LookbackN - 1;
         g_zone.start = rates[start_shift].time;

         // extend drawing to the right
         int sec = PeriodSeconds(Timeframe);
         datetime t2 = rates[0].time + (datetime)(sec * 50);
         DrawZoneObject(g_zone, false, t2);
         Log(StringFormat("New zone #%d created: [%.5f..%.5f]", g_zone.id, g_zone.low, g_zone.high));
      }
   }
   else
   {
      // update bounds only if consolidation still holds
      double zh=0, zl=0;
      if(IsConsolidation(rates, zh, zl))
      {
         g_zone.high = zh;
         g_zone.low  = zl;
      }

      g_zone.last_update = rates[0].time;

      // extend drawing to the right
      int sec = PeriodSeconds(Timeframe);
      datetime t2 = rates[0].time + (datetime)(sec * 50);
      DrawZoneObject(g_zone, false, t2);
   }
}

//=========================
// Position management (BE / TS / PartialClose)
//=========================
void ManagePositions()
{
   // TradeEnabled=false ("signals only") must disable ALL trade operations,
   // including position management (BE/TS/PartialClose). TZ 1.5.
   if(!TradeEnabled)
      return;

   int total = PositionsTotal();
   double point = PointValue();

   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      if((long)PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;

      int type = (int)PositionGetInteger(POSITION_TYPE);
      double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      double volume = PositionGetDouble(POSITION_VOLUME);

      if(volume <= 0)
         continue;

      // Time-based full close (optional)
      if(CloseBeforeWeekend || MaxPositionLifetimeHours > 0)
      {
         MqlDateTime dtc;
         TimeToStruct(TimeCurrent(), dtc);

         bool do_close = false;
         string why = "";

         if(CloseBeforeWeekend && dtc.day_of_week == 5 && dtc.hour >= FridayCloseHourServer)
         {
            do_close = true;
            why = "FriClose";
         }

         if(!do_close && MaxPositionLifetimeHours > 0)
         {
            datetime open_time = (datetime)PositionGetInteger(POSITION_TIME);
            if(open_time > 0 && (TimeCurrent() - open_time) >= (long)MaxPositionLifetimeHours * 3600)
            {
               do_close = true;
               why = "MaxHours";
            }
         }

         if(do_close)
         {
            if(ClosePositionPartial(ticket, type, volume, CommentPrefix + " " + why))
            {
               Log(StringFormat("Position closed (%s): ticket=%I64u", why, ticket));
               continue;
            }
            Log(StringFormat("Failed to close position (%s): ticket=%I64u", why, ticket));
         }
      }

	     // Ensure PC state (hedging + partial close)
	     // NOTE: MT5 Position properties do not include POSITION_VOLUME_INITIAL.
	     //       For PartialClose stability after EA restart we restore initial volume from trade history
	     //       (first entry deal) only when PartialClose is enabled.
	     int pc_idx = -1;
	     if(PartialClose_On)
	     {
	        int existing = FindPCIndex(ticket);
	        double init_volume = volume;
	        if(existing >= 0)
	           init_volume = g_pc_states[existing].initial_volume;
	        else
	        {
	           ulong pos_id = (ulong)PositionGetInteger(POSITION_IDENTIFIER);
	           datetime pos_time = (datetime)PositionGetInteger(POSITION_TIME);
	           init_volume = GetPositionInitialVolumeByHistory(pos_id, pos_time, volume);
	           if(init_volume <= 0.0)
	              init_volume = volume;
	        }
	        pc_idx = EnsurePCState(ticket, init_volume, volume);
	     }

      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double cur_price = (type == POSITION_TYPE_BUY) ? bid : ask;

      double profit_points = 0.0;
      if(type == POSITION_TYPE_BUY)
         profit_points = (cur_price - open_price) / point;
      else
         profit_points = (open_price - cur_price) / point;

      // Правило сейфа: первая фиксация, когда профит = величине стопа (1R)
      int safe_pc1 = EffectiveSafeStep1Points(open_price, (sl > 0.0 ? sl : open_price));
      if(UseSafeRule && sl <= 0.0)
         safe_pc1 = PC_Step1;
      else if(UseSafeRule && sl > 0.0)
      {
         // 1R от фактического стопа позиции
         safe_pc1 = (int)MathRound(MathAbs(open_price - sl) / point);
         if(safe_pc1 < 1) safe_pc1 = PC_Step1;
      }

      // Breakeven (v1.11): BE only after PartialClose step1 is completed, then after BE_Trigger additional points.
      // If PartialClose_On=false, classic BE logic is used (profit_points >= BE_Trigger).
      if(UseBE)
      {
         bool be_allowed = false;
         if(PartialClose_On)
         {
            int pc_idx_be = FindPCIndex(ticket);
            if(pc_idx_be >= 0 && (g_pc_states[pc_idx_be].flags & 1) != 0)
            {
               if(profit_points >= safe_pc1 + BE_Trigger)
                  be_allowed = true;
            }
         }
         else
         {
            if(profit_points >= BE_Trigger)
               be_allowed = true;
         }

         if(be_allowed)
         {
            double new_sl = sl;
            if(type == POSITION_TYPE_BUY)
               new_sl = open_price + BE_Offset * point;
            else
               new_sl = open_price - BE_Offset * point;

            new_sl = NormalizePrice(new_sl);

            // Broker StopLevel protection for SLTP modification (TZ 4.5):
            // keep SL at least StopLevel away from current price to avoid TRADE_RETCODE_INVALID_STOPS.
            double __tmp_tp = 0.0;
            AdjustStopsToBroker((type == POSITION_TYPE_BUY) ? 1 : -1, cur_price, new_sl, __tmp_tp);

            bool need = false;
            if(sl <= 0.0)
               need = true;
            else
            {
               if(type == POSITION_TYPE_BUY && new_sl > sl + point)
                  need = true;
               if(type == POSITION_TYPE_SELL && new_sl < sl - point)
                  need = true;
            }

            if(need)
            {
               if(SendPositionSLTP(ticket, new_sl, tp))
                  Log(StringFormat("BE applied: ticket=%I64u newSL=%s", ticket, DoubleToString(new_sl, DigitsValue())));
               else
                  Log(StringFormat("BE failed: ticket=%I64u attemptSL=%s", ticket, DoubleToString(new_sl, DigitsValue())));
            }
         }
      }

      // Trailing: после сейфа (или TS_Start пунктов) шаг TrailATR × ATR
      bool trail_ok = UseTS;
      if(trail_ok && UseSafeRule && PartialClose_On)
      {
         int pc_idx_tr = FindPCIndex(ticket);
         trail_ok = (pc_idx_tr >= 0 && (g_pc_states[pc_idx_tr].flags & 1) != 0);
      }
      else if(trail_ok && TS_Start > 0)
         trail_ok = (profit_points >= TS_Start);

      if(trail_ok)
      {
         double atr_tr = 0.0;
         GetBufferValue(g_hATR_Filter, 1, atr_tr);
         double step_tr = (TrailATR > 0.0 && atr_tr > 0.0) ? (TrailATR * atr_tr) : (TS_Step * point);
         double new_sl = sl;
         if(type == POSITION_TYPE_BUY)
         {
            new_sl = bid - step_tr;
            if(UseSafeRule)
               new_sl = MathMax(new_sl, open_price);
         }
         else
         {
            new_sl = ask + step_tr;
            if(UseSafeRule)
               new_sl = MathMin(new_sl, open_price);
         }

         new_sl = NormalizePrice(new_sl);

         // Broker StopLevel protection for trailing SL (TZ 4.5):
         // keep SL at least StopLevel away from current price to avoid TRADE_RETCODE_INVALID_STOPS.
         double __tmp_tp2 = 0.0;
         AdjustStopsToBroker((type == POSITION_TYPE_BUY) ? 1 : -1, cur_price, new_sl, __tmp_tp2);

         bool need = false;
         if(sl <= 0.0)
            need = true;
         else
         {
            if(type == POSITION_TYPE_BUY && new_sl > sl + point)
               need = true;
            if(type == POSITION_TYPE_SELL && new_sl < sl - point)
               need = true;
         }

         if(need)
         {
            if(SendPositionSLTP(ticket, new_sl, tp))
               Log(StringFormat("TS applied: ticket=%I64u newSL=%s", ticket, DoubleToString(new_sl, DigitsValue())));
            else
               Log(StringFormat("TS failed: ticket=%I64u attemptSL=%s", ticket, DoubleToString(new_sl, DigitsValue())));
         }
      }

      // Partial close
      if(PartialClose_On)
      {
         int idx = pc_idx;
         if(idx >= 0)
         {
            double init_vol = g_pc_states[idx].initial_volume;
            int flags = g_pc_states[idx].flags;

            double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
            double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

            // step1 — правило сейфа: половина на расстоянии 1R
            if(!(flags & 1) && profit_points >= safe_pc1)
            {
               double to_close = init_vol * PC_Vol1;
               to_close = MathMin(to_close, volume - vmin);
               to_close = MathFloor(to_close / step) * step;
               to_close = NormalizeVolume(to_close);

               if(to_close >= vmin && to_close < volume)
               {
                  if(ClosePositionPartial(ticket, type, to_close, CommentPrefix + " PC1"))
                  {
                     g_pc_states[idx].flags |= 1;
                     Log(StringFormat("PartialClose PC1 done: ticket=%I64u closeVol=%s", ticket, DoubleToString(to_close, VolumeDigits())));
                  }
                  else
                  {
                     Log(StringFormat("PartialClose PC1 failed: ticket=%I64u closeVol=%s", ticket, DoubleToString(to_close, VolumeDigits())));
                  }
               }
               else
               {
                  g_pc_states[idx].flags |= 1;
               }
            }

            int pc2_pts = PC_Step2;
            if(g_lastImpulseRange > point && TP_ImpulseK > 0.0)
            {
               int by_h = (int)MathRound(0.50 * g_lastImpulseRange / point);
               if(by_h > pc2_pts)
                  pc2_pts = by_h;
            }
            if(!(flags & 2) && profit_points >= pc2_pts)
            {
               // refresh volume
               if(PositionSelectByTicket(ticket))
                  volume = PositionGetDouble(POSITION_VOLUME);

               double to_close = init_vol * PC_Vol2;
               to_close = MathMin(to_close, volume - vmin);
               to_close = MathFloor(to_close / step) * step;
               to_close = NormalizeVolume(to_close);

               if(to_close >= vmin && to_close < volume)
               {
                  if(ClosePositionPartial(ticket, type, to_close, CommentPrefix + " PC2"))
                  {
                     g_pc_states[idx].flags |= 2;
                     Log(StringFormat("PartialClose PC2 done: ticket=%I64u closeVol=%s", ticket, DoubleToString(to_close, VolumeDigits())));
                  }
                  else
                  {
                     Log(StringFormat("PartialClose PC2 failed: ticket=%I64u closeVol=%s", ticket, DoubleToString(to_close, VolumeDigits())));
                  }
               }
               else
               {
                  g_pc_states[idx].flags |= 2;
               }
            }
         }
      }
   }

   // cleanup partial-close states for tickets that are no longer present
   for(int k = ArraySize(g_pc_states) - 1; k >= 0; k--)
   {
      ulong t = g_pc_states[k].ticket;
      if(!PositionSelectByTicket(t))
         RemovePCStateByIndex(k);
   }

}

//=========================
// Recalc
//=========================
bool IsNewBar()
{
   datetime t = iTime(_Symbol, Timeframe, 0);
   if(t <= 0)
      return false;

   if(g_lastBarTime == 0)
   {
      g_lastBarTime = t;
      return false;
   }

   if(t != g_lastBarTime)
   {
      g_lastBarTime = t;
      return true;
   }

   return false;
}

void ProcessOnBarClose()
{
   // rates for logic + drawing
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   int life_bars = 600;
   int sec_tf = PeriodSeconds(Timeframe);
   if(sec_tf > 0 && MarkHideAfterHours > 0)
      life_bars = MarkHideAfterHours * 3600 / sec_tf + 120;
   if(life_bars < 600) life_bars = 600;
   if(life_bars > 4000) life_bars = 4000;
   int need = MathMax(life_bars, MathMax(CZ_LookbackN + 50, LiqLookbackBars + 50));
   int copied = CopyRates(_Symbol, Timeframe, 0, need, rates);
   if(copied < (CZ_LookbackN + 10))
      return;

   DrawDayLevels(rates[0].time);

   // Sniper context first: sessions / liquidity / sight / probability HUD
   RefreshSniperContext(rates);

   // IMPORTANT: process signals/invalidation BEFORE updating zone bounds to avoid absorbing the breakout bar into zone boundaries.
   ProcessActiveZone(rates);
   ProcessBrokenZone(rates);
   TryPDT1EntryFromRM(rates);
   UpdateZones(rates);
   UpdateSwingLine(rates);
   AgeSignalObjects();
   PrunePastDecisionMarks();
}

void ProcessIntrabar()
{
   if(SignalsOnlyOnBarClose)
      return;
   if(!IntrabarMode)
      return;

   // Intrabar mode must be recalculated strictly "once per N seconds" (TZ 1.9).
   // IMPORTANT: do not use TimeCurrent() for throttling because in Strategy Tester
   // (and sometimes in low-tick environments) server time may not advance between timer events.
   // GetTickCount() is monotonic wall-clock time and works reliably for OnTimer/OnTick.
   const int sec_wait = MathMax(1, IntrabarSeconds);
   const uint now_ms = GetTickCount();
   if(g_lastIntrabarExecMs != 0 && (uint)(now_ms - g_lastIntrabarExecMs) < (uint)(sec_wait * 1000))
      return;
   g_lastIntrabarExecMs = now_ms;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   int need = MathMax(600, CZ_LookbackN + 50);
   int copied = CopyRates(_Symbol, Timeframe, 0, need, rates);
   if(copied < (CZ_LookbackN + 10))
      return;

   // Active zone: A/B on current forming bar (shift=0)
   if(g_zone.active)
   {
      const int shift = 0;
      if(ArraySize(rates) > shift + 2)
      {
         MqlRates bar  = rates[shift];
         MqlRates prev = rates[shift + 1];

         double p = PointValue();
         double offset = BreakCloseOffset * p;

         // A) breakout (intrabar)
         bool breakout_up = (bar.close >= (g_zone.high + offset));
         bool breakout_dn = (bar.close <= (g_zone.low - offset));

         if(g_EnableSignalA && (breakout_up || breakout_dn))
         {
            if(g_lastSigA_time != bar.time)
            {
               int dir = breakout_up ? 1 : -1;
               if(PassPriceAction(dir, bar, prev))
                  ExecuteSignal("A", dir, bar, g_zone.high, g_zone.low, g_zone.trades_done);
               g_lastSigA_time = bar.time;
            }
         }

         // B) false breakout (intrabar)
         if(g_EnableSignalB)
         {
            bool close_inside = (bar.close <= g_zone.high && bar.close >= g_zone.low);
            if(close_inside)
            {
               double body = MathAbs(bar.close - bar.open);
               if(body < p)
                  body = p;

               double wick_up = 0.0;
               double wick_dn = 0.0;
               if(bar.high > g_zone.high)
                  wick_up = bar.high - g_zone.high;
               if(bar.low < g_zone.low)
                  wick_dn = g_zone.low - bar.low;

               if(wick_up > 0.0 && (wick_up > g_WickRatio_Eff * body))
               {
                  if(g_lastSigB_time != bar.time)
                  {
                     int dir = -1;
                     if(PassPriceAction(dir, bar, prev))
                        ExecuteSignal("B", dir, bar, g_zone.high, g_zone.low, g_zone.trades_done);
                     g_lastSigB_time = bar.time;
                  }
               }
               else if(wick_dn > 0.0 && (wick_dn > g_WickRatio_Eff * body))
               {
                  if(g_lastSigB_time != bar.time)
                  {
                     int dir = 1;
                     if(PassPriceAction(dir, bar, prev))
                        ExecuteSignal("B", dir, bar, g_zone.high, g_zone.low, g_zone.trades_done);
                     g_lastSigB_time = bar.time;
                  }
               }
            }
         }
      }
   }

   // Broken zone: C retest (intrabar)
   if(g_broken.active && g_EnableSignalC)
   {
      const int shift = 0;
      if(ArraySize(rates) > shift + 2)
      {
         MqlRates bar  = rates[shift];
         MqlRates prev = rates[shift + 1];

         double p = PointValue();
         double depth  = RetestDepth * p;
         double offset = BreakCloseOffset * p;

         if(!g_broken.retest_touched)
         {
            if(g_broken.direction > 0)
            {
               bool touch = (bar.close <= (g_broken.high - depth) && bar.close >= g_broken.low);
               if(touch)
               {
                  g_broken.retest_touched = true;
                  g_broken.retest_touch_time = bar.time;
               }
            }
            else
            {
               bool touch = (bar.close >= (g_broken.low + depth) && bar.close <= g_broken.high);
               if(touch)
               {
                  g_broken.retest_touched = true;
                  g_broken.retest_touch_time = bar.time;
               }
            }
         }
         else
         {
            if(g_broken.direction > 0)
            {
               bool confirm = (bar.close >= (g_broken.high + offset));
               if(confirm && g_lastSigC_time != bar.time)
               {
                  if(PassPriceAction(1, bar, prev))
                     ExecuteSignal("C", 1, bar, g_broken.high, g_broken.low, g_broken.trades_done);
                  g_lastSigC_time = bar.time;
                  g_broken.retest_touched = false;
               }
            }
            else
            {
               bool confirm = (bar.close <= (g_broken.low - offset));
               if(confirm && g_lastSigC_time != bar.time)
               {
                  if(PassPriceAction(-1, bar, prev))
                     ExecuteSignal("C", -1, bar, g_broken.high, g_broken.low, g_broken.trades_done);
                  g_lastSigC_time = bar.time;
                  g_broken.retest_touched = false;
               }
            }
         }
      }
   }
}


//=========================
// Init / deinit
//=========================
int OnInit()
{
   // Пресет загружен → OK: подогнать символ и период графика под Inputs
   if(TrySyncChartFromPreset())
      return INIT_SUCCEEDED; // ждём переинит на новом символе/ТФ

   // Снять хвосты прошлой сессии (если OnDeinit раньше не дочистил)
   CleanupChartGraphics();

   // reset
   g_zone.active = false;
   g_broken.active = false;

   g_lastBarTime = 0;
   g_lastTradeBarTime = 0;
   g_lastSigA_time = 0;
   g_lastSigB_time = 0;
   g_lastSigC_time = 0;
   g_lastIntrabarExecMs = 0;
   g_lastContextExecMs = 0;
   g_lastZoneInvalidationTime = 0;
   g_zoneSeq = 0;
   g_liqSeq = 0;
   g_contextTimerOnly = false;
   g_lastProbability = 50;
   g_sightActive = false;
   g_sightDirection = 0;
   g_sightHigh = 0.0;
   g_sightLow = 0.0;
   g_sightAnchor = 0.0;
   g_sightDrawnDirection = 0;
   g_sightUpdateBar = 0;
   g_fib30_origin_t = 0;
   g_fib30_price    = 0.0;
   g_fib30_t1       = 0;
   g_fib30_t2       = 0;
   g_fib30_have     = false;
   g_fib30_retraced = false;
   g_lastImpulseRange = 0.0;
   g_lastImpulseDir   = 0;
   g_pdT1Trades = 0;
   g_pdT1SpentTip = 0;

   ArrayResize(g_pc_states, 0);
   ArrayResize(g_probHistory, 0);
   ArrayResize(g_sessions, 0);
   ArrayResize(g_liqZones, 0);
   ArrayResize(g_structZones, 0);
   g_structSeq = 0;

   InitSymbolStrategyEffective();

   // indicators
   if(EMA_Period > 0)
      g_hEMA = iMA(_Symbol, Timeframe, EMA_Period, 0, MODE_EMA, PRICE_CLOSE);

   g_hATR_Filter = iATR(_Symbol, Timeframe, ATR_Period);
   g_hATR_Zone   = iATR(_Symbol, Timeframe, CZ_ATR_Period);
   g_hRSI = INVALID_HANDLE;
   // RSI — база индекса страха; при панели Balance RSI можно взять её период
   int rsi_period = MathMax(2, FearIndexPeriod);
   if((ShowBalanceRSI || FilterByBalanceRSI) && !(ShowFearHudEnabled() || FilterByFearIndex || AutoTPByFearIndex))
      rsi_period = MathMax(2, BalanceRSI_Period);
   if(ShowFearHudEnabled() || ShowBalanceRSI || FilterByBalanceRSI || FilterByFearIndex || AutoTPByFearIndex)
      g_hRSI = iRSI(_Symbol, Timeframe, rsi_period, PRICE_CLOSE);

   if(g_hATR_Filter == INVALID_HANDLE || g_hATR_Zone == INVALID_HANDLE)
   {
      Log("Failed to create ATR handles");
      return INIT_FAILED;
   }
   if((ShowFearHudEnabled() || ShowBalanceRSI || FilterByBalanceRSI || FilterByFearIndex) && g_hRSI == INVALID_HANDLE)
      Log("WARNING: RSI handle failed — индекс страха/фильтр недоступны до перезапуска");

   g_intrabarTimerSet = false;
   g_contextTimerOnly = false;
   g_lastContextExecMs = 0;

   if(SignalsOnlyOnBarClose)
      Log("SignalsOnlyOnBarClose=true: стрелки A/B/C только после ЗАКРЫТИЯ свечи.");
   Log(StringFormat("Speed=%s depth=%d | symbol=%s | 12pat=%d | virtualTF=%d (%s+%s) | RSI=%d | bounds=%d",
                    SpeedPresetName(), EffectiveSwingDepth(), _Symbol,
                    (int)ShowAll12Patterns, (int)UseVirtualTF,
                    ShortTFName(FastTF), ShortTFName(SlowTF),
                    (int)ShowBalanceRSI, (int)ShowBoundariesChannel));
   Log(StringFormat("Sniper structures: PD_corr>=%.0f%%, PD_break>=%.0f%%, ZU_size=%.0f%%, cascade_max=%.0f%%",
                    PD_MinCorrectionPct, PD_BreakoutPct, ZU_SizePctOfMove, CascadeMaxBreakoutPct));

   // Таймер для динамического прицела/% и/или intrabar-сигналов
   int timer_sec = 0;
   if(DynamicProbability)
      timer_sec = MathMax(1, ContextUpdateSeconds);
   if(!SignalsOnlyOnBarClose && IntrabarMode)
   {
      Log("WARNING: IntrabarMode=true — сигналы могут появиться ДО закрытия свечи.");
      int sec = MathMax(1, IntrabarSeconds);
      if(timer_sec <= 0 || sec < timer_sec)
         timer_sec = sec;
   }

   if(timer_sec > 0)
   {
      if(EventSetTimer(timer_sec))
      {
         g_intrabarTimerSet = true;
         g_contextTimerOnly = (DynamicProbability && (SignalsOnlyOnBarClose || !IntrabarMode));
         Log(StringFormat("Timer %d sec: dynamic probability=%s, intrabar signals=%s",
                          timer_sec,
                          (DynamicProbability ? "ON" : "OFF"),
                          ((!SignalsOnlyOnBarClose && IntrabarMode) ? "ON" : "OFF")));
      }
      else
      {
         g_intrabarTimerSet = false;
         Log("Failed to set timer; dynamic context will use OnTick throttling");
      }
   }


   LogEnvironment();

   Log(StringFormat("%s | symBase=%s | A=%d B=%d C=%d | eff ATRmin=%d effMaxSpread=%d",
                    g_ProfileLogLine,
                    GetSymbolBaseName(),
                    (int)g_EnableSignalA, (int)g_EnableSignalB, (int)g_EnableSignalC,
                    g_ATR_Min_Eff, g_MaxSpread_Eff));

   // Warm start: process the latest closed bar immediately after attach/restart.
   // This prevents missing the first valid setup until the next bar appears.
   g_lastBarTime = iTime(_Symbol, Timeframe, 0);
   if(g_lastBarTime > 0)
      ProcessOnBarClose();

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(g_intrabarTimerSet)
      EventKillTimer();

   if(g_hEMA != INVALID_HANDLE)
      IndicatorRelease(g_hEMA);
   if(g_hATR_Filter != INVALID_HANDLE)
      IndicatorRelease(g_hATR_Filter);
   if(g_hATR_Zone != INVALID_HANDLE)
      IndicatorRelease(g_hATR_Zone);
   if(g_hRSI != INVALID_HANDLE)
      IndicatorRelease(g_hRSI);

   g_hEMA = INVALID_HANDLE;
   g_hATR_Filter = INVALID_HANDLE;
   g_hATR_Zone = INVALID_HANDLE;
   g_hRSI = INVALID_HANDLE;

   CleanupChartGraphics();
}

//=========================
// Tick / timer
//=========================
void OnTick()
{
   ManagePositions();

   if(IsNewBar())
      ProcessOnBarClose();

   // Динамический прицел/% (fallback если таймер не встал)
   if(DynamicProbability && !g_intrabarTimerSet)
      RefreshContextLive();

   // Intrabar signals only if explicitly allowed
   if(!SignalsOnlyOnBarClose && IntrabarMode && !g_intrabarTimerSet)
      ProcessIntrabar();
}

void OnTimer()
{
   if(DynamicProbability)
      RefreshContextLive();

   if(!SignalsOnlyOnBarClose && IntrabarMode)
      ProcessIntrabar();
}