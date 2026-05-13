//+------------------------------------------------------------------+
//|  Acteck v 1.09                                                    |
//|  Copyright Evgeniy Acteck — All rights reserved                    |
//|  Hedging MT5; per-symbol profiles; quality filters                 |
//+------------------------------------------------------------------+
#property copyright "Evgeniy Acteck"
#property description "Acteck v 1.09 — Expert Advisor for MetaTrader 5 (hedging)."
#property version   "1.09"
#property strict

#define EA_VERSION "1.09"


//=========================
// Enums (inputs)
//=========================
enum ENUM_CONFIRM_PATTERN
{
   CP_OFF = 0,
   CP_ENGULFING = 1,
   CP_OUTSIDEBAR = 2
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

//=========================
// Inputs (according to TZ v1.0)
//=========================
input ENUM_SYMBOL_PROFILE  SymbolStrategyProfile = PROFILE_AUTO; // AUTO: match chart; CUSTOM: inputs below; else force named profile
input ENUM_TIMEFRAMES      Timeframe            = PERIOD_M5;
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
input ENUM_CONFIRM_PATTERN ConfirmPattern       = CP_OFF;
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
input ENUM_LOT_MODE        LotMode              = LOT_FIXED;
input double               Lot                  = 0.10;
input double               Percent              = 1.0;
input ENUM_SL_MODE         SL_Mode              = SL_FIXED;
input int                  SL_Points            = 200;    // points
input int                  SL_Offset            = 0;      // points (for FromZone)
input ENUM_TP_MODE         TP_Mode              = TP_FIXED;
input int                  TP_Points            = 200;    // points
input int                  TP_Offset            = 0;      // points (for FromZone)

input bool                 UseBE                = false;
input int                  BE_Trigger           = 100;    // points
input int                  BE_Offset            = 5;      // points

input bool                 UseTS                = false;
input int                  TS_Start             = 150;    // points
input int                  TS_Step              = 50;     // points

input bool                 PartialClose_On      = false;
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
input string               CommentPrefix        = "Acteck";

// Swing / "pro-torgovka"
input ENUM_SWING_MODE      SwingMode            = SWING_FRACTALS;
input int                  ZZ_Depth             = 12;
input int                  ZZ_Deviation         = 5;      // points
input int                  ZZ_Backstep          = 3;
input bool                 ShowSwingLine        = true;

// Graphics / alerts
input bool                 ShowZones            = true;
input bool                 ShowEntryMarker      = true;
input bool                 KeepSignalHistory    = true;
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

// Recalc mode
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
int      g_zoneSeq = 0;
bool     g_intrabarTimerSet = false; // Intrabar timer successfully set

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

color ToARGB(const color c, const uchar alpha)
{
   uint r = (uint)c & 0xFF;
   uint g = ((uint)c >> 8) & 0xFF;
   uint b = ((uint)c >> 16) & 0xFF;
   return (color)(((uint)alpha << 24) | (b << 16) | (g << 8) | r);
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

   Log(StringFormat("Init v%s | TerminalBuild=%d | ProgramBuild=%d | MarginMode=%s | Hedging=%s | Symbol=%s | TF=%s | Digits=%d | Point=%g | Vol(min/max/step)=%.2f/%.2f/%.2f | StopLevel=%d | FreezeLevel=%d",
                    EA_VERSION, (int)term_build, (int)prog_build, EnumToString(mm), (g_isHedging ? "true" : "false"), _Symbol, EnumToString(Timeframe), digits, point, vmin, vmax, vstep, stopLevel, freezeLevel));

   if(!g_isHedging)
      Log("WARNING: Account margin mode is not RETAIL_HEDGING. The EA is designed for hedging accounts (TZ 1.8). Trading/partial close behaviour may differ on netting accounts.");
}

//=========================
// Symbol strategy profile (Portfolio v1.09)
//=========================
string GetSymbolBaseName()
{
   string s = _Symbol;
   int p = StringFind(s, ".");
   if(p > 0)
      return StringSubstr(s, 0, p);
   return s;
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

void InitSymbolStrategyEffective()
{
   ENUM_SYMBOL_PROFILE prof = SymbolStrategyProfile;
   if(prof == PROFILE_AUTO)
      prof = DetectProfileFromSymbol();

   if(prof == PROFILE_CUSTOM)
   {
      g_EnableSignalA = EnableSignalA;
      g_EnableSignalB = EnableSignalB;
      g_EnableSignalC = EnableSignalC;
      g_ATR_Min_Eff = ATR_Min;
      g_MaxSpread_Eff = MaxSpread;
      g_WickRatio_Eff = WickRatio;
      g_RangeMinATR_Mult_Eff = RangeMinATR_Mult;
      g_ProfileLogLine = "profile=CUSTOM (inputs)";
      return;
   }

   g_EnableSignalA = true;
   g_EnableSignalB = true;
   g_EnableSignalC = true;
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
         g_ATR_Min_Eff = 12;
         g_MaxSpread_Eff = 22;
         g_WickRatio_Eff = 2.0;
         g_RangeMinATR_Mult_Eff = 0.0;
         g_ProfileLogLine = "profile=EURUSD (A+B+C, ATR>=12, spread<=22)";
         break;
      case PROFILE_GBPUSD:
         g_EnableSignalA = true;
         g_EnableSignalB = true;
         g_EnableSignalC = true;
         g_ATR_Min_Eff = 10;
         g_MaxSpread_Eff = 25;
         g_WickRatio_Eff = 2.0;
         g_RangeMinATR_Mult_Eff = 0.0;
         g_ProfileLogLine = "profile=GBPUSD (A+B+C, ATR>=10, spread<=25)";
         break;
      case PROFILE_USDJPY:
         g_EnableSignalA = true;
         g_EnableSignalB = false;
         g_EnableSignalC = true;
         g_ATR_Min_Eff = 20;
         g_MaxSpread_Eff = 30;
         g_WickRatio_Eff = 2.5;
         g_RangeMinATR_Mult_Eff = 0.12;
         g_ProfileLogLine = "profile=USDJPY (A+C, no B; ATR>=20; range>=0.12*ATR; spread<=30)";
         break;
      case PROFILE_USDCHF:
         g_EnableSignalA = true;
         g_EnableSignalB = false;
         g_EnableSignalC = true;
         g_ATR_Min_Eff = 14;
         g_MaxSpread_Eff = 24;
         g_WickRatio_Eff = 2.2;
         g_RangeMinATR_Mult_Eff = 0.08;
         g_ProfileLogLine = "profile=USDCHF (A+C, no B; ATR>=14; range>=0.08*ATR; spread<=24)";
         break;
      default:
         g_EnableSignalA = EnableSignalA;
         g_EnableSignalB = EnableSignalB;
         g_EnableSignalC = EnableSignalC;
         g_ATR_Min_Eff = ATR_Min;
         g_MaxSpread_Eff = MaxSpread;
         g_WickRatio_Eff = WickRatio;
         g_RangeMinATR_Mult_Eff = RangeMinATR_Mult;
         g_ProfileLogLine = "profile=FALLBACK (inputs)";
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
   const long chart_id = 0;
   int total = ObjectsTotal(chart_id, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(chart_id, i, 0, -1);
      if(StringFind(name, pfx) == 0)
         ObjectDelete(chart_id, name);
   }
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
   int arrow_code = isBuy ? 233 : 234; // Wingdings arrows
   if(!ObjExists(name))
      ObjectCreate(0, name, OBJ_ARROW, 0, t, price);

   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, arrow_code);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);

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
bool ConfirmCandlePattern(const int direction, const MqlRates &bar, const MqlRates &prev)
{
   if(ConfirmPattern == CP_OFF)
      return true;

   bool is_buy = (direction > 0);

   if(ConfirmPattern == CP_ENGULFING)
   {
      // Simple body engulfing
      if(is_buy)
      {
         bool bullish = (bar.close > bar.open);
         bool prev_bear = (prev.close < prev.open);
         bool engulf = (bar.open < prev.close && bar.close > prev.open);
         return (bullish && prev_bear && engulf);
      }
      else
      {
         bool bearish = (bar.close < bar.open);
         bool prev_bull = (prev.close > prev.open);
         bool engulf = (bar.open > prev.close && bar.close < prev.open);
         return (bearish && prev_bull && engulf);
      }
   }

   if(ConfirmPattern == CP_OUTSIDEBAR)
   {
      bool outside = (bar.high > prev.high && bar.low < prev.low);
      if(!outside)
         return false;
      if(is_buy)
         return (bar.close > bar.open);
      else
         return (bar.close < bar.open);
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

      DrawHLineSegment(n1, today_start, t2, hod, ColorHOD, STYLE_DOT, 1, "HOD");
      DrawHLineSegment(n2, today_start, t2, lod, ColorLOD, STYLE_DOT, 1, "LOD");
      DrawHLineSegment(n3, today_start, t2, bal, ColorBalance, STYLE_SOLID, 1, "BAL");

      // visible labels near the right edge
      DrawText(Prefix() + "LBL_HOD_CUR", lbl_t, hod + 3*PointValue(), "HOD", ColorHOD, ANCHOR_LEFT_LOWER);
      DrawText(Prefix() + "LBL_LOD_CUR", lbl_t, lod - 3*PointValue(), "LOD", ColorLOD, ANCHOR_LEFT_UPPER);
      DrawText(Prefix() + "LBL_BAL_CUR", lbl_t, bal + 3*PointValue(), "BAL", ColorBalance, ANCHOR_LEFT_LOWER);
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

         DrawHLineSegment(n1, prev_start, t2, ph, ColorHOD, STYLE_DOT, 1, "HOD prev");
         DrawHLineSegment(n2, prev_start, t2, pl, ColorLOD, STYLE_DOT, 1, "LOD prev");
         DrawHLineSegment(n3, prev_start, t2, pbal, ColorBalance, STYLE_DOT, 1, "BAL prev");

         // visible labels near the right edge
         DrawText(Prefix() + "LBL_HOD_PREV", lbl_t, ph + 3*PointValue(), "HOD prev", ColorHOD, ANCHOR_LEFT_LOWER);
         DrawText(Prefix() + "LBL_LOD_PREV", lbl_t, pl - 3*PointValue(), "LOD prev", ColorLOD, ANCHOR_LEFT_UPPER);
         DrawText(Prefix() + "LBL_BAL_PREV", lbl_t, pbal + 3*PointValue(), "BAL prev", ColorBalance, ANCHOR_LEFT_LOWER);
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

   color clr = broken ? ColorZoneBroken : ColorZoneActive;
   color fill = ToARGB(clr, 40);

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

   int depth = MathMax(2, ZZ_Depth);
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
      ObjectCreate(0, name, OBJ_TREND, 0, pivots[i].t, pivots[i].p, pivots[i + 1].t, pivots[i + 1].p);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, name, OBJPROP_RAY_LEFT, false);
      ObjectSetInteger(0, name, OBJPROP_COLOR, ColorSwingLine);
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

void VisualizeSignal(const string sig, const int direction, const MqlRates &bar, const double entry, const double sl, const double tp, const string status)
{
   if(!ShowEntryMarker)
      return;

   ClearSignalObjectsIfNeeded();

   color c = (direction > 0) ? ColorBuyMarker : ColorSellMarker;
   color fill = ToARGB(c, 40);

   int sec = PeriodSeconds(Timeframe);
   datetime t1 = bar.time;
   datetime t2 = bar.time + (datetime)sec;

	// For object names we need a stable unique id.
	string base = Prefix() + "SIG_" + TimeToObjectId(bar.time) + "_" + sig;

   // rectangle highlight
   DrawRect(base + "_R", t1, bar.high, t2, bar.low, fill, true, true);

   // text label
   string head = sig + " " + (direction > 0 ? "BUY" : "SELL");
   if(status != "")
      head += " [" + status + "]";

   string txt = head + "\n" +
                "Entry: " + DoubleToString(entry, DigitsValue()) + "\n" +
                "SL: " + DoubleToString(sl, DigitsValue()) + "\n" +
                "TP: " + DoubleToString(tp, DigitsValue());

   double text_price = (direction > 0) ? (bar.low - 5*PointValue()) : (bar.high + 5*PointValue());
   ENUM_ANCHOR_POINT anch = (direction > 0) ? ANCHOR_RIGHT_UPPER : ANCHOR_RIGHT_LOWER;
   DrawText(base + "_T", t2, text_price, txt, c, anch);

   if(ShowArrows)
   {
      DrawArrow(base + "_A", t1, entry, (direction > 0), c);
   }
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

   // SL
   if(SL_Mode == SL_FIXED)
   {
      sl = (direction > 0) ? (entry - SL_Points * p) : (entry + SL_Points * p);
   }
   else
   {
      sl = (direction > 0) ? (zone_low - SL_Offset * p) : (zone_high + SL_Offset * p);
   }

   // TP
   if(TP_Mode == TP_FIXED)
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

   VisualizeSignal(sig, direction, vis_bar, entry, sl, tp, status);

   string msg = sig + " " + (direction > 0 ? "BUY" : "SELL") + " on " + _Symbol + " " + EnumToString(Timeframe);
   if(status != "")
      msg += " [" + status + "]";

   // Notify blocked/disabled signals immediately (with reason in status).
   // For clean (unblocked) trade signals the notification is deferred until
   // the deal is confirmed open — otherwise the alert fires before SendDeal
   // and a silent failure would show a "buy/sell" alert with no real position.
   if(status != "" || !TradeEnabled)
   {
      Notify(msg);
   }

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

   if(volume <= 0.0)
   {
      Log("Volume is zero, cannot trade");
      return false;
   }

   ulong deal = 0;
   string comment = CommentPrefix + " " + sig;
   if(SendDeal(direction, volume, sl, tp, comment, deal))
   {
      trades_done++;
      MarkTradeInBar(signal_bar.time);
      Log(StringFormat("Trade opened %s vol=%.2f deal=%I64u", (direction > 0 ? "BUY" : "SELL"), volume, deal));

      // Notify success only after the deal is confirmed open.
      Notify(msg);
      return true;
   }

   // If SendDeal failed despite passing all filters, notify the user
   // so the lost trade is visible.
   if(status == "" && TradeEnabled)
      Notify(msg + " [SendDeal failed]");
   return false;
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
         if(ConfirmCandlePattern(dir, bar, prev))
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

   // B) false breakout: wick beyond level, close inside
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
            int dir = -1; // return down
            if(ConfirmCandlePattern(dir, bar, prev))
               ExecuteSignal("B", dir, bar, g_zone.high, g_zone.low, g_zone.trades_done);
         }
         else if(wick_dn > 0.0 && (wick_dn > g_WickRatio_Eff * body))
         {
            int dir = 1; // return up
            if(ConfirmCandlePattern(dir, bar, prev))
               ExecuteSignal("B", dir, bar, g_zone.high, g_zone.low, g_zone.trades_done);
         }
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
         if(ConfirmCandlePattern(1, bar, prev))
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
         if(ConfirmCandlePattern(-1, bar, prev))
         {
            ExecuteSignal("C", -1, bar, g_broken.high, g_broken.low, g_broken.trades_done);
            g_broken.retest_touched = false;
         }
      }
   }

   // optional expiry (basic): if too old, deactivate
   if(g_broken.bars_after_break > 500)
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

      // Breakeven
      if(UseBE && profit_points >= BE_Trigger)
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

      // Trailing stop
      if(UseTS && profit_points >= TS_Start)
      {
         double new_sl = sl;
         if(type == POSITION_TYPE_BUY)
            new_sl = bid - TS_Step * point;
         else
            new_sl = ask + TS_Step * point;

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

            // step1
            if(!(flags & 1) && profit_points >= PC_Step1)
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

            // step2
            if(!(flags & 2) && profit_points >= PC_Step2)
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

   int need = MathMax(600, CZ_LookbackN + 50);
   int copied = CopyRates(_Symbol, Timeframe, 0, need, rates);
   if(copied < (CZ_LookbackN + 10))
      return;

   DrawDayLevels(rates[0].time);

   // IMPORTANT: process signals/invalidation BEFORE updating zone bounds to avoid absorbing the breakout bar into zone boundaries.
   ProcessActiveZone(rates);
   ProcessBrokenZone(rates);
   UpdateZones(rates);
   UpdateSwingLine(rates);
}

void ProcessIntrabar()
{
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
               if(ConfirmCandlePattern(dir, bar, prev))
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
                     if(ConfirmCandlePattern(dir, bar, prev))
                        ExecuteSignal("B", dir, bar, g_zone.high, g_zone.low, g_zone.trades_done);
                     g_lastSigB_time = bar.time;
                  }
               }
               else if(wick_dn > 0.0 && (wick_dn > g_WickRatio_Eff * body))
               {
                  if(g_lastSigB_time != bar.time)
                  {
                     int dir = 1;
                     if(ConfirmCandlePattern(dir, bar, prev))
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
                  if(ConfirmCandlePattern(1, bar, prev))
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
                  if(ConfirmCandlePattern(-1, bar, prev))
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
   // reset
   g_zone.active = false;
   g_broken.active = false;

   g_lastBarTime = 0;
   g_lastTradeBarTime = 0;
   g_lastSigA_time = 0;
   g_lastSigB_time = 0;
   g_lastSigC_time = 0;
   g_lastIntrabarExecMs = 0;
   g_lastZoneInvalidationTime = 0;
   g_zoneSeq = 0;

   ArrayResize(g_pc_states, 0);

   InitSymbolStrategyEffective();

   // indicators
   if(EMA_Period > 0)
      g_hEMA = iMA(_Symbol, Timeframe, EMA_Period, 0, MODE_EMA, PRICE_CLOSE);

   g_hATR_Filter = iATR(_Symbol, Timeframe, ATR_Period);
   g_hATR_Zone   = iATR(_Symbol, Timeframe, CZ_ATR_Period);

   if(g_hATR_Filter == INVALID_HANDLE || g_hATR_Zone == INVALID_HANDLE)
   {
      Log("Failed to create ATR handles");
      return INIT_FAILED;
   }

   g_intrabarTimerSet = false;

   if(IntrabarMode)
   {
      int sec = MathMax(1, IntrabarSeconds);
      if(EventSetTimer(sec))
      {
         g_intrabarTimerSet = true;
      }
      else
      {
         g_intrabarTimerSet = false;
         Log(StringFormat("IntrabarMode: failed to set timer for %d sec, fallback to OnTick throttling", sec));
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

   DeleteObjectsByPrefix(Prefix());
}

//=========================
// Tick / timer
//=========================
void OnTick()
{
   ManagePositions();

   if(IsNewBar())
      ProcessOnBarClose();

   // Intrabar mode is executed via OnTimer to guarantee "once per N seconds" (TZ 1.9).
   // Fallback to OnTick only if the timer was not set for some reason.
   if(IntrabarMode && !g_intrabarTimerSet)
      ProcessIntrabar();
}

void OnTimer()
{
   ProcessIntrabar();
}