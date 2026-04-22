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
   MODE_DURATION    = 1
};

input REPORT_TYPE     RepType      = AUTO;                      // Report symbol source
input string          Symb         = "EURUSD";                  // Manual report symbol
input ENUM_TIMEFRAMES Timeframe    = PERIOD_H1;                 // Report timeframe
input datetime        StartDate    = D'2020.10.01 00:00';       // Report start datetime
input datetime        EndDate      = D'2020.12.01 00:00';       // Report end datetime
input int             MinPips      = 1000;                      // Volatility filter (points in old MT4 logic)
input string          NameSet      = "forex";                   // Symbol set filename (without .set)
input int             FontSize     = 11;                        // UI font size
input int             Level1       = 500;                       // Filter column 1
input ENUM_TIMEFRAMES Timeframe1   = PERIOD_H1;                 // Timeframe column 1
input int             Level2       = 1000;                      // Filter column 2
input ENUM_TIMEFRAMES Timeframe2   = PERIOD_H4;                 // Timeframe column 2
input int             Level3       = 1500;                      // Filter column 3
input ENUM_TIMEFRAMES Timeframe3   = PERIOD_D1;                 // Timeframe column 3
input int             Level4       = 2000;                      // Filter column 4
input ENUM_TIMEFRAMES Timeframe4   = PERIOD_W1;                 // Timeframe column 4
input int             Level5       = 2500;                      // Filter column 5
input ENUM_TIMEFRAMES Timeframe5   = PERIOD_MN1;                // Timeframe column 5
input int             Updater      = 1;                         // Update interval (sec)
input int             ATRPeriod    = 14;                        // ATR period
input int             Indent       = 100;                       // Chart labels indent
input bool            EnableAlerts = true;                      // Alert on probability >= 60

REPORT report[];
string g_symbols[];
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

// UI constants
string UI_PREFIX      = "acteck5_";
int    UI_X           = 15;
int    UI_Y           = 35;
int    UI_ROW_H       = 22;
int    UI_COL_W       = 130;
int    UI_SYM_W       = 85;
int    UI_ATR_W       = 50;

double PointValue(const string sym)
{
   double p = 0.0;
   if(!SymbolInfoDouble(sym, SYMBOL_POINT, p))
      return(0.0);
   return(p);
}

int DigitsValue(const string sym)
{
   int d = 0;
   if(!SymbolInfoInteger(sym, SYMBOL_DIGITS, d))
      return(5);
   return(d);
}

string TFToString(ENUM_TIMEFRAMES tf)
{
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

void EnsureDrawPath()
{
   FolderCreate("Acteck");
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
      string line = StringTrim(FileReadString(h));
      if(line == "")
         continue;
      int n = ArraySize(arr);
      ArrayResize(arr, n + 1);
      arr[n] = line;
      SymbolSelect(line, true);
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
   ArraySort(arr, WHOLE_ARRAY, 0, MODE_DESCEND);
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
   if(star_date < 0 || end_date < 0 || star_date <= end_date)
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
   SearchTrends(sy, tf, EndDate, pips, false);
   WriteReport1(sy, report);
   WriteReport2(sy, report, arr);
}

int CalcProbability(const string sy, double s, double e)
{
   int l = ArraySize(report);
   if(l <= 0)
      return 0;
   int prob1[];
   ArrayResize(prob1, l);
   for(int k = 0; k < l; k++)
      prob1[k] = report[k].pips;
   ArraySort(prob1, WHOLE_ARRAY, 0, MODE_DESCEND);

   int direct = (s < e) ? 1 : -1;
   double pt = PointValue(sy);
   for(int i = 0; i < l; i++)
   {
      double new_lvl = (direct > 0) ? (s + prob1[i] * pt) : (s - prob1[i] * pt);
      if((new_lvl <= e && direct > 0) || (new_lvl >= e && direct < 0))
         return GetChance(l - i, l);
   }
   return 0;
}

void DrawHorizontal(const string name, const double price, const color clr, const string text)
{
   ObjectDelete(0, name);
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
}

void DrawTrendsAndProbability(const string sy, int pips)
{
   SearchTrends(sy, g_current_tf, iTime(sy, g_current_tf, 0), pips, true);
   if(g_cnt <= 0 || g_last_trend_name == "")
      return;

   double st_tr = ObjectGetDouble(0, g_last_trend_name, OBJPROP_PRICE, 0);
   double end_tr = ObjectGetDouble(0, g_last_trend_name, OBJPROP_PRICE, 1);
   double pt = PointValue(sy);
   double tp = (end_tr > st_tr) ? (end_tr - pips * pt) : (end_tr + pips * pt);

   if(g_view_mode == MODE_PROBABILITY)
   {
      DrawHorizontal(UI_PREFIX + "price_now", end_tr, clrLime, "Current");
      DrawHorizontal(UI_PREFIX + "price_tp", tp, clrLime, "Target");
   }
   else
   {
      ObjectDelete(0, UI_PREFIX + "price_now");
      ObjectDelete(0, UI_PREFIX + "price_tp");
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
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, FontSize - 1);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}

void BuildUI()
{
   SetLabel(UI_PREFIX + "title", UI_X, UI_Y - 18, "Acteck QA5 | Author: Evgeniy Acteck", C'0,8,127');
   SetButton(UI_PREFIX + "mode", UI_X + 530, UI_Y - 22, 120, 20, (g_view_mode == MODE_PROBABILITY ? "Вероятность" : "Длительность"), clrForestGreen, clrWhite);
   SetLabel(UI_PREFIX + "h_sym", UI_X + 10, UI_Y, "Символ", C'0,8,127');
   SetLabel(UI_PREFIX + "h_atr", UI_X + UI_SYM_W, UI_Y, "ATR", C'0,8,127');

   for(int c = 0; c < 5; c++)
   {
      string txt = IntegerToString(g_levels[c]) + " - " + TFToString(g_tfs[c]);
      SetLabel(UI_PREFIX + "h_f_" + IntegerToString(c), UI_X + UI_SYM_W + UI_ATR_W + 10 + c * UI_COL_W, UI_Y, txt, C'0,8,127');
   }

   int rows = ArraySize(g_symbols);
   int total_signals = rows * 5;
   if(ArraySize(g_alerts) != total_signals)
   {
      ArrayResize(g_alerts, total_signals);
      ArrayInitialize(g_alerts, false);
   }

   int idx = 0;
   for(int r = 0; r < rows; r++)
   {
      int y = UI_Y + 22 + r * UI_ROW_H;
      SetLabel(UI_PREFIX + "sym_" + IntegerToString(r), UI_X + 10, y, g_symbols[r], C'0,8,127');

      double atr_handle = iATR(g_symbols[r], PERIOD_CURRENT, ATRPeriod);
      string atr_text = "-";
      if(atr_handle != INVALID_HANDLE)
      {
         double buf[];
         if(CopyBuffer((int)atr_handle, 0, 0, 1, buf) > 0)
         {
            double pt = PointValue(g_symbols[r]);
            atr_text = DoubleToString(buf[0] / pt / 10.0, 0);
         }
         IndicatorRelease((int)atr_handle);
      }
      SetLabel(UI_PREFIX + "atr_" + IntegerToString(r), UI_X + UI_SYM_W, y, atr_text, C'0,8,127');

      for(int c = 0; c < 5; c++)
      {
         string btn = UI_PREFIX + "btn_" + IntegerToString(r) + "_" + IntegerToString(c);
         string txt = (g_levels[c] == 0 ? "" : "Loading...");
         SetButton(btn, UI_X + UI_SYM_W + UI_ATR_W + c * UI_COL_W, y - 2, UI_COL_W - 6, 20, txt, clrWhite, C'0,8,127');
         idx++;
      }
   }
}

void SetCell(const int row, const int col, const string text, const int trend)
{
   string btn = UI_PREFIX + "btn_" + IntegerToString(row) + "_" + IntegerToString(col);
   color bg = clrWhite, fg = C'0,8,127';
   if(trend > 0) { bg = clrBlue; fg = clrWhite; }
   if(trend < 0) { bg = clrRed;  fg = clrWhite; }
   SetButton(btn, UI_X + UI_SYM_W + UI_ATR_W + col * UI_COL_W, UI_Y + 22 + row * UI_ROW_H - 2, UI_COL_W - 6, 20, text, bg, fg);
}

void CallAlert(const int lvl, const int index)
{
   if(!EnableAlerts) return;
   if(lvl >= 60 && !g_alerts[index])
   {
      PlaySound("alert.wav");
      g_alerts[index] = true;
   }
   if(lvl < 60 && g_alerts[index])
      g_alerts[index] = false;
}

void UpdateTable()
{
   int rows = ArraySize(g_symbols);
   int idx = 0;
   for(int r = 0; r < rows; r++)
   {
      string sy = g_symbols[r];
      for(int c = 0; c < 5; c++)
      {
         int filter = g_levels[c];
         ENUM_TIMEFRAMES tf = g_tfs[c];
         if(filter == 0)
         {
            SetCell(r, c, "", 0);
            idx++;
            continue;
         }

         SearchTrends(sy, tf, iTime(sy, tf, 0), filter, false);
         if(g_cnt <= 0)
         {
            SetCell(r, c, "N/A", 0);
            idx++;
            continue;
         }
         double st_pr = StringToDouble(report[g_cnt - 1].start_tr_pr);
         double en_pr = StringToDouble(report[g_cnt - 1].end_tr_pr);
         SearchTrends(sy, tf, EndDate, filter, false);
         int perc = CalcProbability(sy, st_pr, en_pr);
         CallAlert(perc, idx);

         SearchTrends(sy, tf, iTime(sy, tf, 0), filter, false);
         if(g_cnt <= 0)
         {
            SetCell(r, c, "N/A", 0);
            idx++;
            continue;
         }
         int en_ext = BarsShiftSafe(sy, tf, StringToTime(report[g_cnt - 1].end_tr_tm));
         int max_corr = 0;
         if(en_ext >= 0)
         {
            for(int j = en_ext; j >= 0; j--)
            {
               int d = 0;
               double pt = PointValue(sy);
               if(report[g_cnt - 1].trend == "buy")
                  d = (int)((iHigh(sy, tf, en_ext) - iLow(sy, tf, j)) / 10.0 / pt);
               else
                  d = (int)((iHigh(sy, tf, j) - iLow(sy, tf, en_ext)) / 10.0 / pt);
               if(d > max_corr) max_corr = d;
            }
         }
         string curr_dev = DoubleToString(MathAbs(StringToDouble(report[g_cnt - 1].end_tr_pr) - iClose(sy, tf, 0)) / 10.0 / PointValue(sy), 0);
         int clr = 0;
         if(perc >= 60)
            clr = (report[g_cnt - 1].trend == "buy" ? 1 : -1);
         SetCell(r, c, IntegerToString(perc) + "%/" + IntegerToString(max_corr) + "/" + curr_dev, clr);
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

   if(!LoadSymbolsSet(NameSet, g_symbols))
      return INIT_FAILED;

   string rep_sym = (RepType == AUTO ? _Symbol : Symb);
   ReportTrends(rep_sym, MinPips, Timeframe, g_prob);

   BuildUI();
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
   if(sparam == UI_PREFIX + "mode")
   {
      g_view_mode = (g_view_mode == MODE_PROBABILITY ? MODE_DURATION : MODE_PROBABILITY);
      SetButton(UI_PREFIX + "mode", UI_X + 530, UI_Y - 22, 120, 20, (g_view_mode == MODE_PROBABILITY ? "Вероятность" : "Длительность"), clrForestGreen, clrWhite);
      ObjectsDeleteAll(0, UI_PREFIX + "line_prob_");
      ObjectsDeleteAll(0, UI_PREFIX + "price_");
      return;
   }

   string pfx = UI_PREFIX + "btn_";
   if(StringFind(sparam, pfx) != 0)
      return;
   string rrcc = StringSubstr(sparam, StringLen(pfx));
   string parts[];
   int n = StringSplit(rrcc, '_', parts);
   if(n != 2)
      return;
   int r = (int)StringToInteger(parts[0]);
   int c = (int)StringToInteger(parts[1]);
   if(r < 0 || r >= ArraySize(g_symbols) || c < 0 || c >= 5)
      return;
   if(g_levels[c] == 0)
      return;

   g_current_filter = g_levels[c];
   g_current_tf = g_tfs[c];
   g_current_symbol = g_symbols[r];
   ChartSetSymbolPeriod(ChartID(), g_current_symbol, g_current_tf);
}
//+------------------------------------------------------------------+
