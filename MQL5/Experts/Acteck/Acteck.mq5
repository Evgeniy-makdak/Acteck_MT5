//+------------------------------------------------------------------+
//|                                                       Acteck.mq5 |
//|                          Copyright 2026, Evgeniy Acteck          |
//|                    Ported from MT4 to MT5 with parity focus      |
//+------------------------------------------------------------------+
#property copyright "Evgeniy Acteck"
#property link      "https://github.com/Evgeniy-makdak/acteck_qa5"
#property version   "5.00"
#property strict

struct REPORT
{
   string number;
   string trend;
   string start_tr_pr;
   string end_tr_pr;
   string start_tr_tm;
   string end_tr_tm;
   string mins;
   string hourmins;
   int    pips;
};

enum REPORT_TYPE
{
   AUTO,    // report symbol is current chart symbol
   MANUAL   // report symbol is Symb input
};

enum VIEW_MODE
{
   MODE_PROBABILITY = 0,
   MODE_DURATION    = 1,
   MODE_SPEED       = 2
};

input REPORT_TYPE     RepType      = AUTO;                      // Report symbol source
input string          Symb         = "EURUSD";                  // Manual report symbol
input ENUM_TIMEFRAMES Timeframe    = PERIOD_H1;                 // Report timeframe
input datetime        StartDate    = D'2020.10.01 00:00';       // Report start datetime
input bool            UseCurrentEndDate = true;                 // Use current date as report end
input datetime        EndDate      = D'2020.12.01 00:00';       // Manual report end datetime
input int             MinPips      = 1000;                      // Volatility filter (points in old MT4 logic)
input string          NameSet      = "forex";                   // Symbol set filename (without .set)
input int             FontSize     = 11;                        // UI font size
input int             Level1       = 500;                       // Filter column 1
input ENUM_TIMEFRAMES Timeframe1   = PERIOD_H1;                 // Timeframe column 1
input int             Level2       = 1000;                      // Filter column 2
input ENUM_TIMEFRAMES Timeframe2   = PERIOD_H4;                 // Timeframe column 2
input int             Level3       = 1500;                      // Filter column 3
input ENUM_TIMEFRAMES Timeframe3   = PERIOD_D1;                 // Timeframe column 3
input int             Level4       = 0;                         // Filter column 4 (0 = disabled by default)
input ENUM_TIMEFRAMES Timeframe4   = PERIOD_W1;                 // Timeframe column 4
input int             Level5       = 0;                         // Filter column 5 (0 = disabled by default)
input ENUM_TIMEFRAMES Timeframe5   = PERIOD_MN1;                // Timeframe column 5
input int             Updater      = 1;                         // Update interval (sec)
input int             ATRPeriod    = 14;                        // ATR period
input int             Indent       = 100;                       // Chart labels indent
input bool            EnableAlerts = true;                      // Alert on probability >= 60
input bool            ShowOnlyCurrentSymbol = true;             // Render table for current chart symbol only
input bool            ShowDebugDetails = true;                  // Show debug probability details line

REPORT report[];
string g_symbols[];
string g_view_symbols[];
bool   g_alerts[];
int    g_prob[];

int               g_levels[5];
ENUM_TIMEFRAMES   g_tfs[5];
int               g_current_filter;
ENUM_TIMEFRAMES   g_current_tf;
string            g_current_symbol;
int               g_last_filter = -1;
ENUM_TIMEFRAMES   g_last_tf = PERIOD_CURRENT;
string            g_last_symbol = "";
datetime          g_next_update = 0;
VIEW_MODE         g_view_mode = MODE_PROBABILITY;
string            g_last_trend_name = "";
string            g_last_up_name = "";
string            g_last_dn_name = "";
int               g_cnt = 0;
bool              g_show_debug_details = true;

// UI constants
string UI_PREFIX      = "acteck5_";
int    UI_X           = 24;
int    UI_Y           = 98;
int    UI_ROW_H       = 50;
int    UI_COL_W       = 220;
int    UI_SYM_W       = 180;
int    UI_ATR_W       = 90;
int    UI_TOP_PAD     = 78;
int    g_ui_panel_top = 0;
int    g_ui_row_start_y = 0;
int    g_ui_debug_y = 0;
int    g_ui_debug_text_x = 0;
int    g_ui_debug_text_w = 0;
int    g_ui_panel_right = 0;
int    g_last_chart_w = 0;
int    g_last_chart_h = 0;
int    g_active_cols[5];
int    g_active_count = 0;
int    g_active_visual_row = 0;
int    g_active_visual_col = 0;

string NormalizeSymbolCode(string s)
{
   StringToUpper(s);
   StringReplace(s, " ", "");
   StringReplace(s, "/", "");
   return s;
}

string FitTextByPixels(const string text, const int width_px, const int char_px = 7)
{
   if(width_px <= 0)
      return "";
   int max_chars = width_px / MathMax(5, char_px);
   if(max_chars < 8)
      max_chars = 8;
   int len = StringLen(text);
   if(len <= max_chars)
      return text;
   if(max_chars <= 3)
      return StringSubstr(text, 0, max_chars);
   return StringSubstr(text, 0, max_chars - 3) + "...";
}

string ResolveSymbolName(string requested)
{
   string req = NormalizeSymbolCode(requested);
   if(req == "")
      return "";

   // exact
   if(SymbolInfoDouble(req, SYMBOL_POINT) > 0.0)
      return req;
   if(SymbolInfoDouble(requested, SYMBOL_POINT) > 0.0)
      return requested;

   // try to find by prefix with broker suffixes, e.g. EURUSDpf
   string best = "";
   int best_extra = 1000;
   int total = SymbolsTotal(false); // all symbols
   for(int i = 0; i < total; i++)
   {
      string name = SymbolName(i, false);
      string norm = NormalizeSymbolCode(name);
      if(StringLen(norm) < StringLen(req))
         continue;
      if(StringSubstr(norm, 0, StringLen(req)) == req)
      {
         int extra = StringLen(norm) - StringLen(req);
         if(extra < best_extra)
         {
            best = name;
            best_extra = extra;
         }
      }
   }
   return best;
}

string BaseSymbol6(const string symbol_name)
{
   string norm = NormalizeSymbolCode(symbol_name);
   if(StringLen(norm) >= 6)
      return StringSubstr(norm, 0, 6);
   return norm;
}

bool IsMajorUsdPair(const string symbol_name)
{
   string base6 = BaseSymbol6(symbol_name);
   if(StringLen(base6) < 6)
      return false;
   string a = StringSubstr(base6, 0, 3);
   string b = StringSubstr(base6, 3, 3);
   // Majors in current strategy context: pairs where one side is USD.
   return (a == "USD" || b == "USD");
}

int ProbabilityEntryThreshold(const string symbol_name)
{
   // Entry filter from instruction:
   // majors >70%, crosses >85%.
   return (IsMajorUsdPair(symbol_name) ? 71 : 86);
}

void BuildViewSymbols()
{
   ArrayResize(g_view_symbols, 0);
   if(ShowOnlyCurrentSymbol)
   {
      string cur = ResolveSymbolName(_Symbol);
      if(cur == "")
         cur = _Symbol;
      ArrayResize(g_view_symbols, 1);
      g_view_symbols[0] = cur;
      return;
   }

   int n = ArraySize(g_symbols);
   ArrayResize(g_view_symbols, n);
   for(int i = 0; i < n; i++)
      g_view_symbols[i] = g_symbols[i];
}

void BuildActiveColumns()
{
   g_active_count = 0;
   for(int i = 0; i < 5; i++)
   {
      if(g_levels[i] > 0)
      {
         g_active_cols[g_active_count] = i;
         g_active_count++;
      }
   }
}

void SyncActiveVisualSelection()
{
   g_active_visual_row = 0;
   g_active_visual_col = 0;

   int rows = ArraySize(g_view_symbols);
   for(int r = 0; r < rows; r++)
   {
      if(g_view_symbols[r] == g_current_symbol)
      {
         g_active_visual_row = r;
         break;
      }
   }
   for(int c = 0; c < g_active_count; c++)
   {
      int real_col = g_active_cols[c];
      if(g_levels[real_col] == g_current_filter && g_tfs[real_col] == g_current_tf)
      {
         g_active_visual_col = c;
         return;
      }
   }
   g_active_visual_col = 0;
}

double PointValue(const string sym)
{
   double p = 0.0;
   if(!SymbolInfoDouble(sym, SYMBOL_POINT, p))
      return(0.0);
   return(p);
}

int DigitsValue(const string sym)
{
   long d = 0;
   if(!SymbolInfoInteger(sym, SYMBOL_DIGITS, d))
      return(5);
   return((int)d);
}

string TFToString(ENUM_TIMEFRAMES tf)
{
   if(tf == PERIOD_CURRENT)
      tf = (ENUM_TIMEFRAMES)_Period;
   switch(tf)
   {
      case PERIOD_M1:  return "M1";
      case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";
      case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN";
   }
   return "TF";
}

int BarsShiftSafe(const string sy, ENUM_TIMEFRAMES tf, datetime t)
{
   int s = iBarShift(sy, tf, t, false);
   if(s < 0)
      return(-1);
   return s;
}

bool IsCrossingWeekend(datetime st, datetime en)
{
   MqlDateTime a, b;
   TimeToStruct(st, a);
   TimeToStruct(en, b);
   int wa = (int)MathFloor((a.day_of_year + 1) / 7.0);
   int wb = (int)MathFloor((b.day_of_year + 1) / 7.0);
   return (wa < wb);
}

int GetChance(const int level, const int all)
{
   if(all <= 0)
      return 0;
   int chance = (int)MathFloor(100.0 - ((all - level) / (double)all * 100.0));
   if(chance < 0) chance = 0;
   if(chance > 100) chance = 100;
   return chance;
}

datetime EffectiveEndDate()
{
   if(UseCurrentEndDate)
      return TimeCurrent();
   return EndDate;
}

void EnsureDrawPath()
{
   FolderCreate("Acteck");
}

string TrimString(string s)
{
   StringTrimLeft(s);
   StringTrimRight(s);
   return s;
}

bool LoadSymbolsSet(const string name, string &arr[])
{
   string path = "Acteck\\" + name + ".set";
   if(!FileIsExist(path))
   {
      Print("Symbols set not found: ", path);
      return false;
   }
   int h = FileOpen(path, FILE_READ | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE)
   {
      Print("Unable to open symbols set: ", path, " err=", GetLastError());
      return false;
   }

   ArrayResize(arr, 0);
   while(!FileIsEnding(h))
   {
      string line = TrimString(FileReadString(h));
      if(line == "")
         continue;
      string resolved = ResolveSymbolName(line);
      if(resolved == "")
         resolved = line;
      int n = ArraySize(arr);
      ArrayResize(arr, n + 1);
      arr[n] = resolved;
      SymbolSelect(resolved, true);
   }
   FileClose(h);
   return(ArraySize(arr) > 0);
}

void WriteReport1(const string sy, REPORT &rep[])
{
   EnsureDrawPath();
   string file = "Acteck\\Table_1_" + sy + ".csv";
   int h = FileOpen(file, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return;
   FileWrite(h, "N", "Trend", "StartPrice", "EndPrice", "StartTime", "EndTime", "DurationMin", "DurationHourMin");
   for(int i = 0; i < ArraySize(rep); i++)
      FileWrite(h, rep[i].number, rep[i].trend, rep[i].start_tr_pr, rep[i].end_tr_pr, rep[i].start_tr_tm, rep[i].end_tr_tm, rep[i].mins, rep[i].hourmins);
   FileClose(h);
}

void WriteReport2(const string sy, REPORT &rep[], int &arr[])
{
   EnsureDrawPath();
   string file = "Acteck\\Table_2_" + sy + ".csv";
   int h = FileOpen(file, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return;
   FileWrite(h, "AsFound", "SortedDesc");

   int l = ArraySize(rep);
   ArrayResize(arr, l);
   for(int i = 0; i < l; i++)
      arr[i] = rep[i].pips;
   ArraySort(arr);
   ArrayReverse(arr);
   for(int i = 0; i < l; i++)
      FileWrite(h, rep[i].pips, arr[i]);
   FileClose(h);
}

int GetDirection(const string sy, ENUM_TIMEFRAMES tf, int s, int e, int pips)
{
   double pt = PointValue(sy);
   if(pt <= 0.0) return 0;
   for(int i = s - 1; i >= e; i--)
   {
      int dt_up = (int)((iHigh(sy, tf, i) - iLow(sy, tf, s)) / pt);
      int dt_dn = (int)((iHigh(sy, tf, s) - iLow(sy, tf, i)) / pt);
      if(dt_up >= pips) return 1;
      if(dt_dn >= pips) return -1;
   }
   return 0;
}

int CheckUp(const string sy, ENUM_TIMEFRAMES tf, int s, int e, int pips, int &res, bool draw_mode)
{
   int new_ext = -1;
   int delta = 0;
   bool all = false;
   double pt = PointValue(sy);
   double st_price = iLow(sy, tf, s);

   for(int i = s - 1; i >= e; i--)
   {
      int dt = (int)((iHigh(sy, tf, i) - st_price) / pt);
      if(dt >= delta)
      {
         delta = dt;
         new_ext = i;
      }
      else if(new_ext >= 0)
      {
         dt = (int)((iHigh(sy, tf, new_ext) - iLow(sy, tf, i)) / pt);
         if(dt >= pips)
            break;
      }
      if(i == e)
         all = true;
   }
   if(new_ext < 0)
      return 0;

   double s_ext = iLow(sy, tf, s);
   datetime s_time = iTime(sy, tf, s);
   double l_ext = iHigh(sy, tf, new_ext);
   datetime l_time = iTime(sy, tf, new_ext);
   if(new_ext == 0)
      l_time = TimeCurrent();
   int weekend = IsCrossingWeekend(s_time, l_time) ? 2880 : 0;

   if(draw_mode)
   {
      string nm = UI_PREFIX + "trend_up_" + IntegerToString(new_ext);
      ObjectDelete(0, nm);
      ObjectCreate(0, nm, OBJ_TREND, 0, s_time, s_ext, l_time, l_ext);
      ObjectSetInteger(0, nm, OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(0, nm, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, nm, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, nm, OBJPROP_BACK, true);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      g_last_trend_name = nm;
      g_last_up_name = nm;
   }
   else
   {
      report[g_cnt - 1].number = IntegerToString(g_cnt);
      report[g_cnt - 1].trend = "buy";
      report[g_cnt - 1].start_tr_pr = DoubleToString(s_ext, DigitsValue(sy));
      report[g_cnt - 1].end_tr_pr = DoubleToString(l_ext, DigitsValue(sy));
      report[g_cnt - 1].start_tr_tm = TimeToString(s_time);
      report[g_cnt - 1].end_tr_tm = TimeToString(l_time);
      report[g_cnt - 1].mins = IntegerToString((int)((l_time - s_time) / 60 - weekend)) + " m";
      report[g_cnt - 1].hourmins = IntegerToString((int)MathFloor((l_time - s_time) / 3600 - weekend / 60)) + " h " + IntegerToString((int)MathMod((l_time - s_time), 3600) / 60) + " m";
      report[g_cnt - 1].pips = (int)((l_ext - s_ext) / pt);
   }

   res = new_ext;
   if(all) return 0;
   return 1;
}

int CheckDn(const string sy, ENUM_TIMEFRAMES tf, int s, int e, int pips, int &res, bool draw_mode)
{
   int new_ext = -1;
   int delta = 0;
   bool all = false;
   double pt = PointValue(sy);
   double st_price = iHigh(sy, tf, s);

   for(int i = s - 1; i >= e; i--)
   {
      int dt = (int)((st_price - iLow(sy, tf, i)) / pt);
      if(dt >= delta)
      {
         delta = dt;
         new_ext = i;
      }
      else if(new_ext >= 0)
      {
         dt = (int)((iHigh(sy, tf, i) - iLow(sy, tf, new_ext)) / pt);
         if(dt >= pips)
            break;
      }
      if(i == e)
         all = true;
   }
   if(new_ext < 0)
      return 0;

   double s_ext = iHigh(sy, tf, s);
   datetime s_time = iTime(sy, tf, s);
   double l_ext = iLow(sy, tf, new_ext);
   datetime l_time = iTime(sy, tf, new_ext);
   if(new_ext == 0)
      l_time = TimeCurrent();
   int weekend = IsCrossingWeekend(s_time, l_time) ? 2880 : 0;

   if(draw_mode)
   {
      string nm = UI_PREFIX + "trend_dn_" + IntegerToString(new_ext);
      ObjectDelete(0, nm);
      ObjectCreate(0, nm, OBJ_TREND, 0, s_time, s_ext, l_time, l_ext);
      ObjectSetInteger(0, nm, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, nm, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, nm, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, nm, OBJPROP_BACK, true);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      g_last_trend_name = nm;
      g_last_dn_name = nm;
   }
   else
   {
      report[g_cnt - 1].number = IntegerToString(g_cnt);
      report[g_cnt - 1].trend = "sell";
      report[g_cnt - 1].start_tr_pr = DoubleToString(s_ext, DigitsValue(sy));
      report[g_cnt - 1].end_tr_pr = DoubleToString(l_ext, DigitsValue(sy));
      report[g_cnt - 1].start_tr_tm = TimeToString(s_time);
      report[g_cnt - 1].end_tr_tm = TimeToString(l_time);
      report[g_cnt - 1].mins = IntegerToString((int)((l_time - s_time) / 60 - weekend)) + " m";
      report[g_cnt - 1].hourmins = IntegerToString((int)MathFloor((l_time - s_time) / 3600 - weekend / 60)) + " h " + IntegerToString((int)MathMod((l_time - s_time), 3600) / 60) + " m";
      report[g_cnt - 1].pips = (int)((s_ext - l_ext) / pt);
   }

   res = new_ext;
   if(all) return 0;
   return -1;
}

void SearchTrends(const string sy, ENUM_TIMEFRAMES tf, datetime end_time, int pips, bool draw_mode)
{
   ArrayResize(report, 0);
   int star_date = BarsShiftSafe(sy, tf, StartDate);
   int end_date  = BarsShiftSafe(sy, tf, end_time);
   int bars = iBars(sy, tf);
   if(star_date < 0)
      star_date = bars - 1;
   if(end_date < 0)
      end_date = 0;
   if(star_date <= end_date || bars < 10)
   {
      g_cnt = 0;
      return;
   }

   int pos = star_date;
   g_cnt = 1;
   ArrayResize(report, g_cnt);
   int st_dir = GetDirection(sy, tf, pos, end_date, pips);
   int dir = 0;
   if(st_dir > 0) dir = CheckUp(sy, tf, pos, end_date, pips, pos, draw_mode);
   if(st_dir < 0) dir = CheckDn(sy, tf, pos, end_date, pips, pos, draw_mode);

   while(dir != 0)
   {
      g_cnt++;
      ArrayResize(report, g_cnt);
      if(dir < 0) dir = CheckUp(sy, tf, pos, end_date, pips, pos, draw_mode);
      else if(dir > 0) dir = CheckDn(sy, tf, pos, end_date, pips, pos, draw_mode);
   }
}

void ReportTrends(const string sy, int pips, ENUM_TIMEFRAMES tf, int &arr[])
{
   SearchTrends(sy, tf, EffectiveEndDate(), pips, false);
   WriteReport1(sy, report);
   WriteReport2(sy, report, arr);
}

int CalcProbabilityDetailed(const string sy, double s, double e, int &sample_count, double &dist_points, int &rank_index)
{
   int l = ArraySize(report);
   sample_count = l;
   rank_index = -1;
   dist_points = 0.0;
   if(l <= 0)
      return 0;
   int prob1[];
   ArrayResize(prob1, l);
   for(int k = 0; k < l; k++)
      prob1[k] = report[k].pips;
   ArraySort(prob1);
   ArrayReverse(prob1);

   double pt = PointValue(sy);
   if(pt <= 0.0)
      return 0;
   double dist = MathAbs(e - s);
   dist_points = dist / pt;
   for(int i = 0; i < l; i++)
   {
      double level_dist = prob1[i] * pt;
      if(level_dist <= dist)
      {
         rank_index = i;
         return GetChance(l - i, l);
      }
   }
   return 0;
}

int CalcProbability(const string sy, double s, double e)
{
   int n, r;
   double d;
   return CalcProbabilityDetailed(sy, s, e, n, d, r);
}

int TFMinutes(const ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return 1;
      case PERIOD_M5:  return 5;
      case PERIOD_M15: return 15;
      case PERIOD_M30: return 30;
      case PERIOD_H1:  return 60;
      case PERIOD_H4:  return 240;
      case PERIOD_D1:  return 1440;
      case PERIOD_W1:  return 10080;
      case PERIOD_MN1: return 43200;
   }
   return 60;
}

int ChanceFromWaveLength(const int &sorted_lengths[], const int n, const int wave_len_points)
{
   for(int i = 0; i < n; i++)
   {
      if(sorted_lengths[i] <= wave_len_points)
         return GetChance(n - i, n);
   }
   return 0;
}

bool EstimateReversalTarget(const string sy, const ENUM_TIMEFRAMES tf, const int filter_points, const int curr_prob,
                           const double cur_price, const int curr_direction,
                           double &target_price, double &avg_next_pips10, double &avg_next_bars, int &samples)
{
   samples = 0;
   avg_next_pips10 = 0.0;
   avg_next_bars = 0.0;
   target_price = 0.0;

   SearchTrends(sy, tf, EffectiveEndDate(), filter_points, false);
   int n = g_cnt;
   if(n < 4)
      return false;

   int lens[];
   ArrayResize(lens, n);
   for(int i = 0; i < n; i++)
      lens[i] = report[i].pips;
   ArraySort(lens);
   ArrayReverse(lens);

   const int band = 10; // +/-10% probability neighborhood
   double sum_next_points = 0.0;
   double sum_next_mins = 0.0;
   for(int i = 0; i < n - 1; i++)
   {
      int p_i = ChanceFromWaveLength(lens, n, report[i].pips);
      if(MathAbs(p_i - curr_prob) > band)
         continue;

      int next_points = report[i + 1].pips;
      int next_mins = (int)StringToInteger(report[i + 1].mins);
      if(next_points <= 0 || next_mins <= 0)
         continue;

      sum_next_points += (double)next_points;
      sum_next_mins += (double)next_mins;
      samples++;
   }

   if(samples <= 0)
      return false;

   double avg_next_points = sum_next_points / (double)samples;
   double pt = PointValue(sy);
   if(pt <= 0.0)
      return false;

   // Reversal target: project opposite move from current price.
   if(curr_direction > 0)
      target_price = cur_price - avg_next_points * pt;
   else
      target_price = cur_price + avg_next_points * pt;

   avg_next_pips10 = avg_next_points / 10.0;
   int tf_mins = TFMinutes(tf);
   avg_next_bars = (tf_mins > 0 ? (sum_next_mins / (double)samples) / (double)tf_mins : 0.0);
   return true;
}

void DrawHorizontal(const string name, const double price, const color clr, const string text)
{
   ObjectDelete(0, name);
   ObjectDelete(0, name + "_lbl");
   datetime t1 = iTime(_Symbol, PERIOD_CURRENT, 30);
   datetime t2 = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(t1 <= 0 || t2 <= 0)
      return;
   ObjectCreate(0, name, OBJ_TREND, 0, t1, price, t2, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetString(0, name, OBJPROP_TEXT, text);

   // Visible probability label near the right edge
   if(text != "")
   {
      ObjectCreate(0, name + "_lbl", OBJ_TEXT, 0, t2, price);
      ObjectSetString(0, name + "_lbl", OBJPROP_TEXT, text);
      ObjectSetInteger(0, name + "_lbl", OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name + "_lbl", OBJPROP_FONTSIZE, FontSize - 1);
      ObjectSetInteger(0, name + "_lbl", OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0, name + "_lbl", OBJPROP_SELECTABLE, false);
   }
}

void DrawTrendsAndProbability(const string sy, int pips)
{
   SearchTrends(sy, g_current_tf, iTime(sy, g_current_tf, 0), pips, true);
   if(g_cnt <= 0 || g_last_trend_name == "")
      return;

   double st_tr = ObjectGetDouble(0, g_last_trend_name, OBJPROP_PRICE, 0);
   double end_tr = ObjectGetDouble(0, g_last_trend_name, OBJPROP_PRICE, 1);
   double cur_tr = iClose(sy, g_current_tf, 0);
   double pt = PointValue(sy);
   double tp = (end_tr > st_tr) ? (end_tr - pips * pt) : (end_tr + pips * pt);

   if(g_view_mode == MODE_PROBABILITY)
   {
      ObjectDelete(0, UI_PREFIX + "mode_stat_1");
      ObjectDelete(0, UI_PREFIX + "mode_stat_2");
      ObjectDelete(0, UI_PREFIX + "dur_tmax");
      ObjectDelete(0, UI_PREFIX + "dur_lmax");
      int n = 0, rank = -1;
      double dist_pts = 0.0;
      int curr_prob = CalcProbabilityDetailed(sy, st_tr, cur_tr, n, dist_pts, rank);
      int curr_dir = (st_tr < end_tr ? 1 : -1);
      double dyn_target_price = 0.0;
      double dyn_target_pips10 = 0.0;
      double dyn_target_bars = 0.0;
      int dyn_samples = 0;
      bool has_dyn_target = EstimateReversalTarget(sy, g_current_tf, pips, curr_prob, cur_tr, curr_dir,
                                                   dyn_target_price, dyn_target_pips10, dyn_target_bars, dyn_samples);
      DrawHorizontal(UI_PREFIX + "price_now", cur_tr, clrLime, "Current " + IntegerToString(curr_prob) + "%");
      if(has_dyn_target)
         DrawHorizontal(UI_PREFIX + "price_tp", dyn_target_price, clrLime, "Target dyn " + DoubleToString(dyn_target_pips10, 0) + "p");
      else
         DrawHorizontal(UI_PREFIX + "price_tp", tp, clrLime, "Target static");
      if(g_show_debug_details)
      {
         int dbg_x = g_ui_debug_text_x;
         int dbg_w = g_ui_debug_text_w;
         if(dbg_w < 120)
            dbg_w = 120;
         string dbg_text = "Pcur=" + IntegerToString(curr_prob) + "%, Dist=" + DoubleToString(dist_pts, 0) +
                           "pt, N=" + IntegerToString(n) + ", idx=" + IntegerToString(rank);
         if(has_dyn_target)
            dbg_text += ", Tdyn=" + DoubleToString(dyn_target_pips10, 0) + "p (" + DoubleToString(dyn_target_bars, 1) + " bars),";
         else
            dbg_text += ", Tdyn=NA";
         SetLabel(UI_PREFIX + "prob_details", dbg_x, g_ui_debug_y,
                  FitTextByPixels(dbg_text, dbg_w, 7),
                  C'80,80,80');
         if(has_dyn_target)
            SetLabel(UI_PREFIX + "prob_details_2", dbg_x, g_ui_debug_y + 24, "Ns=" + IntegerToString(dyn_samples), C'80,80,80');
         else
            ObjectDelete(0, UI_PREFIX + "prob_details_2");
      }
      else
      {
         ObjectDelete(0, UI_PREFIX + "prob_details");
         ObjectDelete(0, UI_PREFIX + "prob_details_2");
      }
   }
   else
   {
      ObjectDelete(0, UI_PREFIX + "price_now");
      ObjectDelete(0, UI_PREFIX + "price_tp");
      ObjectDelete(0, UI_PREFIX + "prob_details");
      ObjectDelete(0, UI_PREFIX + "prob_details_2");
      ObjectsDeleteAll(0, UI_PREFIX + "line_prob_");

      SearchTrends(sy, g_current_tf, EffectiveEndDate(), pips, false);
      if(g_view_mode == MODE_DURATION)
      {
         int tmax = 0, lmax = 0;
         for(int i = 0; i < g_cnt; i++)
         {
            int mins_i = (int)StringToInteger(report[i].mins);
            if(mins_i > tmax) tmax = mins_i;
            if(report[i].pips > lmax) lmax = report[i].pips;
         }
         int stat2_x = g_ui_debug_text_x + MathMax(260, g_ui_debug_text_w / 2);
         SetLabel(UI_PREFIX + "mode_stat_1", g_ui_debug_text_x, g_ui_debug_y, "Tmax=" + IntegerToString(tmax) + "m", clrLime);
         SetLabel(UI_PREFIX + "mode_stat_2", stat2_x, g_ui_debug_y, "Lmax=" + IntegerToString(lmax / 10) + "p", clrLime);
      }
      else if(g_view_mode == MODE_SPEED)
      {
         double sum_speed = 0.0;
         int n_speed = 0;
         for(int i = 0; i < g_cnt; i++)
         {
            int mins_i = (int)StringToInteger(report[i].mins);
            if(mins_i <= 0) continue;
            sum_speed += (report[i].pips / 10.0) / (double)mins_i;
            n_speed++;
         }
         double avg_speed = (n_speed > 0 ? sum_speed / n_speed : 0.0);
         int cur_mins = (g_cnt > 0 ? (int)StringToInteger(report[g_cnt - 1].mins) : 0);
         double cur_speed = (cur_mins > 0 ? (report[g_cnt - 1].pips / 10.0) / (double)cur_mins : 0.0);
         int stat2_x = g_ui_debug_text_x + MathMax(260, g_ui_debug_text_w / 2);
         SetLabel(UI_PREFIX + "mode_stat_1", g_ui_debug_text_x, g_ui_debug_y, "Vcur=" + DoubleToString(cur_speed, 3), clrLime);
         SetLabel(UI_PREFIX + "mode_stat_2", stat2_x, g_ui_debug_y, "Vavg=" + DoubleToString(avg_speed, 3), clrLime);
      }
   }

   int all = ArraySize(g_prob);
   if(all <= 0 || g_view_mode != MODE_PROBABILITY)
      return;

   int direct = (st_tr < end_tr) ? 1 : -1;
   for(int i = all - 1; i >= 0; i--)
   {
      int p = GetChance(all - i, all);
      if(p < 60) continue;
      double lvl = (direct > 0) ? (st_tr + g_prob[i] * pt) : (st_tr - g_prob[i] * pt);
      DrawHorizontal(UI_PREFIX + "line_prob_" + IntegerToString(i), lvl, clrOlive, IntegerToString(p) + "%");
      break;
   }
   double max_lvl = (direct > 0) ? (st_tr + g_prob[0] * pt) : (st_tr - g_prob[0] * pt);
   DrawHorizontal(UI_PREFIX + "line_prob_100", max_lvl, clrOlive, "100%");
   // Remove custom "live probability" label: it was not part of original MT4 logic and caused confusion.
   ObjectDelete(0, UI_PREFIX + "prob_live");
}

void SetLabel(const string name, const int x, const int y, const string text, const color clr, const int corner = CORNER_LEFT_UPPER)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Segoe UI");
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void SetButton(const string name, const int x, const int y, const int w, const int h, const string text, const color bg, const color fg)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, fg);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, FontSize);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, C'70,70,70');
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void DrawTablePanel(const int rows, const int panel_top, const int panel_h)
{
   string name = UI_PREFIX + "panel";
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   int cols = MathMax(1, g_active_count);
   int w = UI_SYM_W + UI_ATR_W + (cols * UI_COL_W) + 44;
   int h = panel_h;
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, UI_X - 14);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, panel_top);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'245,245,245');
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, C'90,90,90');
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, -1);
}

void DrawDebugPanel(const int panel_top, const int panel_h)
{
   string panel = UI_PREFIX + "debug_panel";
   string title = UI_PREFIX + "debug_title";
   if(!g_show_debug_details)
   {
      ObjectDelete(0, panel);
      ObjectDelete(0, title);
      ObjectDelete(0, UI_PREFIX + "prob_details");
      ObjectDelete(0, UI_PREFIX + "prob_details_2");
      ObjectDelete(0, UI_PREFIX + "mode_stat_1");
      ObjectDelete(0, UI_PREFIX + "mode_stat_2");
      g_ui_debug_text_x = 0;
      g_ui_debug_text_w = 0;
      return;
   }

   int x = UI_X - 14;
   int y = panel_top + panel_h + 8;
   int w = g_ui_panel_right - x;
   int h = 116;
   if(w < 360) w = 360;

   if(ObjectFind(0, panel) < 0)
      ObjectCreate(0, panel, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, panel, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, panel, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, panel, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, panel, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, panel, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, panel, OBJPROP_BGCOLOR, C'248,250,255');
   ObjectSetInteger(0, panel, OBJPROP_BORDER_COLOR, C'120,140,180');
   ObjectSetInteger(0, panel, OBJPROP_BACK, false);
   ObjectSetInteger(0, panel, OBJPROP_SELECTABLE, false);

   SetLabel(title, x + 12, y + 18, "Диагностика", C'70,90,130');
   g_ui_debug_y = y + 18;
   g_ui_debug_text_x = x + 220;
   g_ui_debug_text_w = w - 234;
}

void BuildUI()
{
   int rows = ArraySize(g_view_symbols);
   BuildActiveColumns();
   SyncActiveVisualSelection();

   // Keep columns inside chart area to avoid clipping on the right edge.
   long chart_w = 0;
   long chart_h = 0;
   if(ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0, chart_w))
   {
      int cols = MathMax(1, g_active_count);
      int available = (int)chart_w - UI_X - 24 - UI_SYM_W - UI_ATR_W - 40;
      int dynamic_w = (cols > 0 ? available / cols : 220);
      if(dynamic_w < 170) dynamic_w = 170;
      if(dynamic_w > 260) dynamic_w = 260;
      UI_COL_W = dynamic_w;
   }
   ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0, chart_h);

   int panel_top = UI_Y - UI_TOP_PAD;
   if(panel_top < 8)
      panel_top = 8;
   int min_panel_h = 320 + rows * UI_ROW_H;
   if((int)chart_h > 0 && panel_top + min_panel_h > (int)chart_h - 10)
      panel_top = MathMax(8, (int)chart_h - min_panel_h - 10);

   int title_y = panel_top + 12;
   int active_y = panel_top + 50;
   int hint_active_y = panel_top + 82;
   int debug_y = panel_top + 114;
   int header_y = panel_top + 148;
   int row_start_y = panel_top + 198;
   int panel_w = UI_SYM_W + UI_ATR_W + (MathMax(1, g_active_count) * UI_COL_W) + 44;
   int panel_h = (row_start_y + rows * UI_ROW_H + 122) - panel_top;
   DrawTablePanel(rows, panel_top, panel_h);

   g_ui_panel_top = panel_top;
   g_ui_row_start_y = row_start_y;
   g_ui_debug_y = debug_y;
   g_ui_panel_right = (UI_X - 14) + panel_w;

   int mode_w = 304;
   int mode_x = g_ui_panel_right - mode_w - 16;
   if(mode_x < UI_X + 330)
      mode_x = UI_X + 330;
   int dbg_toggle_w = 220;
   int dbg_toggle_x = g_ui_panel_right - dbg_toggle_w - 16;
   if(dbg_toggle_x < UI_X + 10)
      dbg_toggle_x = UI_X + 10;
   string mode_text = "Режим: Вероятность";
   color mode_bg = clrForestGreen;
   if(g_view_mode == MODE_DURATION)
   {
      mode_text = "Режим: Длительность";
      mode_bg = clrDeepSkyBlue;
   }
   else if(g_view_mode == MODE_SPEED)
   {
      mode_text = "Режим: Скорость";
      mode_bg = clrTomato;
   }
   SetLabel(UI_PREFIX + "title", UI_X, title_y, "Acteck QA5 | Author: Evgeniy Acteck", C'0,8,127');
   SetButton(UI_PREFIX + "mode", mode_x, title_y - 2, mode_w, 36, mode_text, mode_bg, clrWhite);
   SetLabel(UI_PREFIX + "active", UI_X + 10, active_y, "Активный график: " + IntegerToString(g_current_filter) + " - " + TFToString(g_current_tf), C'0,120,0');
   ObjectDelete(0, UI_PREFIX + "active_hint");
   color dbg_bg = (g_show_debug_details ? C'52,152,219' : C'170,170,170');
   SetButton(UI_PREFIX + "debug_toggle", dbg_toggle_x, debug_y - 3, dbg_toggle_w, 30,
             (g_show_debug_details ? "Отладка: ON" : "Отладка: OFF"), dbg_bg, clrWhite);
   ObjectDelete(0, UI_PREFIX + "debug_label");
   DrawDebugPanel(panel_top, panel_h);
   SetLabel(UI_PREFIX + "h_sym", UI_X + 10, header_y, "Символ", C'0,8,127');
   SetLabel(UI_PREFIX + "h_atr", UI_X + UI_SYM_W + 8, header_y, "ATR", C'0,8,127');
   string hint_text = "Формат ячейки: Вероятность % | Макс коррекция | Тек. отклонение";
   if(g_view_mode == MODE_DURATION)
      hint_text = "Формат ячейки: Длительность % от средней | Макс коррекция | Тек. отклонение";
   else if(g_view_mode == MODE_SPEED)
      hint_text = "Формат ячейки: Скорость % от средней | Макс коррекция | Тек. отклонение";
   SetLabel(UI_PREFIX + "hint", UI_X + 10, row_start_y + rows * UI_ROW_H + 44, hint_text, C'80,80,80');

   for(int c = 0; c < g_active_count; c++)
   {
      int real_col = g_active_cols[c];
      string txt = IntegerToString(g_levels[real_col]) + " - " + TFToString(g_tfs[real_col]);
      color hc = (c == g_active_visual_col ? C'0,140,0' : C'0,8,127');
      string header_btn = UI_PREFIX + "col_" + IntegerToString(c);
      SetButton(header_btn,
                UI_X + UI_SYM_W + UI_ATR_W + 14 + c * UI_COL_W,
                header_y - 8,
                UI_COL_W - 22,
                34,
                txt,
                (c == g_active_visual_col ? C'220,240,220' : clrWhite),
                hc);
   }

   int total_signals = rows * MathMax(1, g_active_count);
   if(ArraySize(g_alerts) != total_signals)
   {
      ArrayResize(g_alerts, total_signals);
      ArrayInitialize(g_alerts, false);
   }

   int idx = 0;
   for(int r = 0; r < rows; r++)
   {
      int y = row_start_y + r * UI_ROW_H;
      SetLabel(UI_PREFIX + "sym_" + IntegerToString(r), UI_X + 10, y, g_view_symbols[r], C'0,8,127');

      int atr_handle = iATR(g_view_symbols[r], PERIOD_CURRENT, ATRPeriod);
      string atr_text = "-";
      if(atr_handle != INVALID_HANDLE)
      {
         double buf[];
         if(CopyBuffer(atr_handle, 0, 0, 1, buf) > 0)
         {
            double pt = PointValue(g_view_symbols[r]);
            if(pt > 0.0)
               atr_text = DoubleToString(buf[0] / pt / 10.0, 0);
         }
         IndicatorRelease(atr_handle);
      }
      SetLabel(UI_PREFIX + "atr_" + IntegerToString(r), UI_X + UI_SYM_W + 8, y, atr_text, C'0,8,127');

      for(int c = 0; c < g_active_count; c++)
      {
         string btn = UI_PREFIX + "btn_" + IntegerToString(r) + "_" + IntegerToString(c);
         string txt = "...";
         SetButton(btn, UI_X + UI_SYM_W + UI_ATR_W + 14 + c * UI_COL_W, y - 8, UI_COL_W - 22, 42, txt, clrWhite, C'0,8,127');
         idx++;
      }
   }
}

void SetCell(const int row, const int col, const string text, const int trend,
             const bool blocked = false, const bool ready_signal = false,
             const bool prob_alert = false, const bool corr_alert = false, const bool dev_alert = false)
{
   string btn = UI_PREFIX + "btn_" + IntegerToString(row) + "_" + IntegerToString(col);
   int row_y = g_ui_row_start_y + row * UI_ROW_H;
   int x = UI_X + UI_SYM_W + UI_ATR_W + 14 + col * UI_COL_W;
   int y = row_y - 8;
   int w = UI_COL_W - 22;
   int h = 42;

   // Main clickable frame.
   SetButton(btn, x, y, w, h, "", C'250,250,250', C'0,8,127');
   ObjectSetInteger(0, btn, OBJPROP_BORDER_COLOR, (row == g_active_visual_row && col == g_active_visual_col) ? C'0,150,0' : C'120,120,120');

   string parts[];
   int n = StringSplit(text, '|', parts);
   string v1 = (n > 0 ? TrimString(parts[0]) : text);
   string v2 = (n > 1 ? TrimString(parts[1]) : "");
   string v3 = (n > 2 ? TrimString(parts[2]) : "");

   int gap = 4;
   int inner_w = w - 2 * gap;
   int part_w = inner_w / 3;
   int part_y = y + 5;
   int part_h = h - 10;

   color p1bg = C'250,250,250', p2bg = C'250,250,250', p3bg = C'250,250,250';
   color p1fg = C'0,8,127', p2fg = C'0,8,127', p3fg = C'0,8,127';

   if(ready_signal && trend > 0) { p1bg = C'61,122,224';  p1fg = clrWhite; }   // buy-ready
   if(ready_signal && trend < 0) { p1bg = C'242,153,74';  p1fg = clrWhite; }   // sell-ready
   if(prob_alert) { p1bg = C'185,45,45'; p1fg = clrWhite; }
   if(corr_alert) { p2bg = C'185,45,45'; p2fg = clrWhite; }
   if(dev_alert)  { p3bg = C'185,45,45'; p3fg = clrWhite; }

   SetButton(btn + "_p1", x + gap,               part_y, part_w - 2, part_h, v1, p1bg, p1fg);
   SetButton(btn + "_p2", x + gap + part_w,      part_y, part_w - 2, part_h, v2, p2bg, p2fg);
   SetButton(btn + "_p3", x + gap + part_w * 2,  part_y, part_w - 2, part_h, v3, p3bg, p3fg);
   ObjectSetInteger(0, btn + "_p1", OBJPROP_BORDER_COLOR, C'170,170,170');
   ObjectSetInteger(0, btn + "_p2", OBJPROP_BORDER_COLOR, C'170,170,170');
   ObjectSetInteger(0, btn + "_p3", OBJPROP_BORDER_COLOR, C'170,170,170');
   ObjectSetInteger(0, btn + "_p1", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, btn + "_p2", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, btn + "_p3", OBJPROP_SELECTABLE, false);
}

string FormatCellValue(const int p, const int mx, const string dev)
{
   return StringFormat("%d%% | %d | %s", p, mx, dev);
}

int ToDisplayPoints(const double raw_points)
{
   return (int)MathRound(raw_points / 10.0);
}

int CalcMaxTrendCorrection(const string sy, const ENUM_TIMEFRAMES tf, const int start_idx, const int end_idx, const bool is_buy)
{
   double pt = PointValue(sy);
   if(pt <= 0.0 || start_idx < 0 || end_idx < 0 || start_idx <= end_idx)
      return 0;

   double peak = iHigh(sy, tf, start_idx);
   double trough = iLow(sy, tf, start_idx);
   double max_corr_raw = 0.0;

   for(int j = start_idx; j >= end_idx; j--)
   {
      double h = iHigh(sy, tf, j);
      double l = iLow(sy, tf, j);
      if(is_buy)
      {
         if(h > peak)
            peak = h;
         double corr = (peak - l) / pt;
         if(corr > max_corr_raw)
            max_corr_raw = corr;
      }
      else
      {
         if(l < trough)
            trough = l;
         double corr = (h - trough) / pt;
         if(corr > max_corr_raw)
            max_corr_raw = corr;
      }
   }

   return ToDisplayPoints(max_corr_raw);
}

bool IsProbabilitySignalBlocked(const int filter_raw, const int max_corr_trend, const int max_corr_ext, const int curr_dev)
{
   if(filter_raw <= 0)
      return false;
   double filter_pts = filter_raw / 10.0;
   int max_corr_trend_limit = (int)MathFloor(filter_pts * 0.80);
   int max_corr_ext_limit   = (int)MathFloor(filter_pts * 0.60);
   int curr_dev_limit       = (int)MathFloor(filter_pts * 0.40);

   return (max_corr_trend >= max_corr_trend_limit ||
           max_corr_ext   >= max_corr_ext_limit ||
           curr_dev       >= curr_dev_limit);
}

void CallAlert(const int lvl, const int index, const int threshold)
{
   if(!EnableAlerts) return;
   if(lvl >= threshold && !g_alerts[index])
   {
      PlaySound("alert.wav");
      g_alerts[index] = true;
   }
   if(lvl < threshold && g_alerts[index])
      g_alerts[index] = false;
}

void UpdateTable()
{
   int rows = ArraySize(g_view_symbols);
   if(g_active_count <= 0)
      return;
   int idx = 0;
   for(int r = 0; r < rows; r++)
   {
      string sy = g_view_symbols[r];
      for(int c = 0; c < g_active_count; c++)
      {
         int real_col = g_active_cols[c];
         int filter = g_levels[real_col];
         ENUM_TIMEFRAMES tf = g_tfs[real_col];
         if(filter == 0)
         {
            SetCell(r, c, "", 0);
            idx++;
            continue;
         }

         MqlRates preload[];
         CopyRates(sy, tf, 0, 3000, preload);
         SearchTrends(sy, tf, iTime(sy, tf, 0), filter, false);
         if(g_cnt <= 0)
         {
            SetCell(r, c, "--", 0);
            idx++;
            continue;
         }
         int perc = 0;
         if(g_view_mode == MODE_PROBABILITY)
         {
            // Cell probability must represent the probability of the reached (max) point
            // on the current trend segment, not the temporary live rollback value.
            double st_pr = StringToDouble(report[g_cnt - 1].start_tr_pr);
            double en_pr = StringToDouble(report[g_cnt - 1].end_tr_pr);
            SearchTrends(sy, tf, EffectiveEndDate(), filter, false);
            perc = CalcProbability(sy, st_pr, en_pr);
            CallAlert(perc, idx, ProbabilityEntryThreshold(sy));
         }
         else
         {
            SearchTrends(sy, tf, EffectiveEndDate(), filter, false);
            if(g_view_mode == MODE_DURATION)
            {
               int average = 0;
               for(int m = 0; m < g_cnt; m++)
                  average += (int)StringToInteger(report[m].mins);
               average = (g_cnt > 0 ? (int)(average / (double)g_cnt) : 0);
               SearchTrends(sy, tf, iTime(sy, tf, 0), filter, false);
               int cur_mins = (g_cnt > 0 ? (int)StringToInteger(report[g_cnt - 1].mins) : 0);
               perc = (average > 0 ? (int)MathAbs(cur_mins / (double)average * 100.0) : 0);
            }
            else // MODE_SPEED
            {
               double avg_speed = 0.0;
               int n_speed = 0;
               for(int m = 0; m < g_cnt; m++)
               {
                  int mins_m = (int)StringToInteger(report[m].mins);
                  if(mins_m <= 0) continue;
                  avg_speed += (report[m].pips / 10.0) / (double)mins_m;
                  n_speed++;
               }
               avg_speed = (n_speed > 0 ? avg_speed / n_speed : 0.0);
               SearchTrends(sy, tf, iTime(sy, tf, 0), filter, false);
               int cur_mins = (g_cnt > 0 ? (int)StringToInteger(report[g_cnt - 1].mins) : 0);
               double cur_speed = (cur_mins > 0 ? (report[g_cnt - 1].pips / 10.0) / (double)cur_mins : 0.0);
               perc = (avg_speed > 0.0 ? (int)MathAbs(cur_speed / avg_speed * 100.0) : 0);
            }
         }

         SearchTrends(sy, tf, iTime(sy, tf, 0), filter, false);
         if(g_cnt <= 0)
         {
            SetCell(r, c, "--", 0);
            idx++;
            continue;
         }
         int st_ext = BarsShiftSafe(sy, tf, StringToTime(report[g_cnt - 1].start_tr_tm));
         int en_ext = BarsShiftSafe(sy, tf, StringToTime(report[g_cnt - 1].end_tr_tm));
         int max_corr = 0;
         bool is_buy = (report[g_cnt - 1].trend == "buy");
         if(en_ext >= 0)
         {
            for(int j = en_ext; j >= 0; j--)
            {
               int d = 0;
               double pt = PointValue(sy);
               if(is_buy)
                  d = (int)((iHigh(sy, tf, en_ext) - iLow(sy, tf, j)) / 10.0 / pt);
               else
                  d = (int)((iHigh(sy, tf, j) - iLow(sy, tf, en_ext)) / 10.0 / pt);
               if(d > max_corr) max_corr = d;
            }
         }
         int max_corr_trend = CalcMaxTrendCorrection(sy, tf, st_ext, en_ext, is_buy);
         int curr_dev_val = ToDisplayPoints(MathAbs(StringToDouble(report[g_cnt - 1].end_tr_pr) - iClose(sy, tf, 0)) / PointValue(sy));
         string curr_dev = IntegerToString(curr_dev_val);
         // "Max correction on the whole trend segment" must include rollback after the last extremum too.
         int max_corr_whole = MathMax(max_corr_trend, max_corr);
         int clr = 0;
         int prob_threshold = ProbabilityEntryThreshold(sy);
         if(perc >= prob_threshold)
            clr = (is_buy ? 1 : -1);
         double filter_pts = filter / 10.0;
         int max_corr_trend_limit = (int)MathFloor(filter_pts * 0.80);
         int max_corr_ext_limit   = (int)MathFloor(filter_pts * 0.60);
         int curr_dev_limit       = (int)MathFloor(filter_pts * 0.40); // updated limit for current rollback
         bool corr_whole_alert = (max_corr_whole >= max_corr_trend_limit);
         bool corr_ext_alert   = (max_corr >= max_corr_ext_limit);
         bool dev_alert        = (curr_dev_val >= curr_dev_limit);
         bool corr_alert       = (corr_whole_alert || corr_ext_alert);
         bool blocked = (g_view_mode == MODE_PROBABILITY && (corr_alert || dev_alert));
         bool ready_signal = (g_view_mode == MODE_PROBABILITY && perc >= prob_threshold && !blocked);
         bool prob_alert = (g_view_mode == MODE_PROBABILITY && blocked && perc >= prob_threshold);
         SetCell(r, c, FormatCellValue(perc, max_corr_whole, curr_dev), clr, blocked, ready_signal, prob_alert, corr_alert, dev_alert);
         idx++;
      }
   }
}

void CleanupObjects()
{
   ObjectsDeleteAll(0, UI_PREFIX);
}

int OnInit()
{
   g_levels[0] = Level1; g_levels[1] = Level2; g_levels[2] = Level3; g_levels[3] = Level4; g_levels[4] = Level5;
   g_tfs[0] = Timeframe1; g_tfs[1] = Timeframe2; g_tfs[2] = Timeframe3; g_tfs[3] = Timeframe4; g_tfs[4] = Timeframe5;

   g_current_filter = MinPips;
   g_current_tf = PERIOD_CURRENT;
   g_current_symbol = _Symbol;
   g_show_debug_details = ShowDebugDetails;

   if(!LoadSymbolsSet(NameSet, g_symbols))
      return INIT_FAILED;
   BuildViewSymbols();

   string rep_sym = (RepType == AUTO ? _Symbol : Symb);
   ReportTrends(rep_sym, MinPips, Timeframe, g_prob);

   BuildUI();
   long w = 0, h = 0;
   if(ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0, w))
      g_last_chart_w = (int)w;
   if(ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0, h))
      g_last_chart_h = (int)h;
   EventSetTimer(MathMax(1, Updater));
   g_next_update = TimeLocal();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   CleanupObjects();
}

void DoPeriodicUpdate()
{
   if(ShowOnlyCurrentSymbol)
   {
      string cur = ResolveSymbolName(_Symbol);
      if(cur == "")
         cur = _Symbol;
      if(ArraySize(g_view_symbols) != 1 || g_view_symbols[0] != cur)
      {
         BuildViewSymbols();
         BuildActiveColumns();
         SyncActiveVisualSelection();
         CleanupObjects();
         BuildUI();
      }
      g_current_symbol = cur;
   }

   if(TimeLocal() < g_next_update)
      return;
   g_next_update = TimeLocal() + MathMax(1, Updater);

   if(g_current_filter != g_last_filter || g_current_tf != g_last_tf || g_current_symbol != g_last_symbol)
   {
      ObjectsDeleteAll(0, UI_PREFIX + "trend_");
      ObjectsDeleteAll(0, UI_PREFIX + "line_prob_");
      g_last_filter = g_current_filter;
      g_last_tf = g_current_tf;
      g_last_symbol = g_current_symbol;
      ReportTrends(g_current_symbol, g_current_filter, g_current_tf, g_prob);
   }

   DrawTrendsAndProbability(g_current_symbol, g_current_filter);
   UpdateTable();
   ChartRedraw();
}

void OnTick()
{
   DoPeriodicUpdate();
}

void OnTimer()
{
   DoPeriodicUpdate();
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK)
      return;
   if(sparam == UI_PREFIX + "debug_toggle")
   {
      g_show_debug_details = !g_show_debug_details;
      CleanupObjects();
      BuildUI();
      return;
   }
   if(sparam == UI_PREFIX + "mode")
   {
      if(g_view_mode == MODE_PROBABILITY) g_view_mode = MODE_DURATION;
      else if(g_view_mode == MODE_DURATION) g_view_mode = MODE_SPEED;
      else g_view_mode = MODE_PROBABILITY;
      ObjectsDeleteAll(0, UI_PREFIX + "line_prob_");
      ObjectsDeleteAll(0, UI_PREFIX + "price_");
      ObjectDelete(0, UI_PREFIX + "mode_stat_1");
      ObjectDelete(0, UI_PREFIX + "mode_stat_2");
      CleanupObjects();
      BuildUI();
      return;
   }

   string col_pfx = UI_PREFIX + "col_";
   if(StringFind(sparam, col_pfx) != 0)
      return;
   int c = (int)StringToInteger(StringSubstr(sparam, StringLen(col_pfx)));
   if(c < 0 || c >= g_active_count)
      return;
   int real_col = g_active_cols[c];

   // Keep symbol selection deterministic: prefer current chart symbol if available.
   string cur = ResolveSymbolName(_Symbol);
   if(cur == "")
      cur = _Symbol;
   int r = 0;
   for(int i = 0; i < ArraySize(g_view_symbols); i++)
   {
      if(g_view_symbols[i] == cur)
      {
         r = i;
         break;
      }
   }

   g_current_filter = g_levels[real_col];
   g_current_tf = g_tfs[real_col];
   g_current_symbol = g_view_symbols[r];
   g_active_visual_row = r;
   g_active_visual_col = c;
   // Repaint header highlight immediately after changing active column.
   BuildUI();
   SetLabel(UI_PREFIX + "active", UI_X + 10, g_ui_panel_top + 50, "Активный график: " + IntegerToString(g_current_filter) + " - " + TFToString(g_current_tf), C'0,120,0');
   ChartSetSymbolPeriod(ChartID(), g_current_symbol, g_current_tf);
}
//+------------------------------------------------------------------+
