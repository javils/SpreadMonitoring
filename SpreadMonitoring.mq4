//+------------------------------------------------------------------+
//|                                             SpreadMonitoring.mq4 |
//|                            Copyright 2024, Javier Luque Sanabria |
//+------------------------------------------------------------------+
#property copyright "Javier Luque Sanabria"
#property link      ""
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_plots 4
#property indicator_buffers 4

#property indicator_label1 "Max Spread"
#property indicator_type1 DRAW_HISTOGRAM
#property indicator_width1 4
#property indicator_color1 Red

#property indicator_label2 "Min Spread"
#property indicator_type2 DRAW_HISTOGRAM
#property indicator_width2 4
#property indicator_color2 Blue

#property indicator_label3 "Avg Spread Bar"
#property indicator_type3 DRAW_LINE
#property indicator_width3 4
#property indicator_color3 Yellow

#property indicator_label4 "PeriodAverage"
#property indicator_type4 DRAW_LINE
#property indicator_width4 2
#property indicator_color4 LimeGreen

double maxSpread[];
double minSpread[];
double avgSpread[];
double periodAvgSpread[];
double sumSpread = 0;
int numTicks = 0;
double totalAvgSpreads = 0;
int numOfSpreads = 0;

string fileName;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
    SetIndexBuffer(0, maxSpread, INDICATOR_DATA);
    SetIndexBuffer(1, minSpread, INDICATOR_DATA);
    SetIndexBuffer(2, avgSpread, INDICATOR_DATA);
    SetIndexBuffer(3, periodAvgSpread, INDICATOR_DATA);

    fileName = StringFormat("%s_%d.csv", _Symbol, _Period);

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[]) {

    if (prev_calculated == 0) {
        readData();
        updateSpread();
        return rates_total;
    }
    
    updateSpread();

    if (prev_calculated != rates_total) {
        totalAvgSpreads += avgSpread[1];
        numOfSpreads++;
        periodAvgSpread[1] = totalAvgSpreads / numOfSpreads;
        writeData();
        numTicks = 0;
        sumSpread = 0;

    }


    return rates_total;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void readData() {
    int fileHandle = FileOpen(fileName, FILE_TXT | FILE_READ | FILE_ANSI, ",");
    if (fileHandle == INVALID_HANDLE) return;

    datetime time;
    int bar;

    while(!FileIsEnding(fileHandle)) {
        string rowCols[];
        StringSplit(FileReadString(fileHandle), ',', rowCols); 
       
        
        time = StringToTime(rowCols[0]);
        bar = iBarShift(_Symbol, _Period, time, true);
        maxSpread[bar] = StringToDouble(rowCols[1]);
        minSpread[bar] = StringToDouble(rowCols[2]);
        avgSpread[bar] = StringToDouble(rowCols[3]);
        totalAvgSpreads += avgSpread[bar];
        numOfSpreads++;
       
        periodAvgSpread[bar] = totalAvgSpreads / numOfSpreads;
        
    }
    FileClose(fileHandle);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void updateSpread() {
    if (maxSpread[0] == EMPTY_VALUE) maxSpread[0] = 0;
    if (minSpread[0] == EMPTY_VALUE) minSpread[0] = DBL_MAX;
    if (avgSpread[0] == EMPTY_VALUE) avgSpread[0] = 0;
    if (periodAvgSpread[0] == EMPTY_VALUE) periodAvgSpread[0] = 0;
    
    double spread = MathAbs(Ask - Bid) / _Point;

    if (spread > maxSpread[0]) {
        maxSpread[0] = spread;
    }
    if (spread < minSpread[0]) {
        minSpread[0] = spread;
    }

    sumSpread += spread;
    numTicks++;
    avgSpread[0] = sumSpread / numTicks;

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void writeData() {
    int fileHandle = FileOpen(fileName, FILE_TXT | FILE_WRITE | FILE_READ | FILE_ANSI, ",");
    if (fileHandle == INVALID_HANDLE) return;

    FileSeek(fileHandle, 0, SEEK_END);
    FileWrite(fileHandle, TimeToString(Time[1]), DoubleToString(maxSpread[1]), DoubleToString(minSpread[1]), DoubleToString(avgSpread[1]));
    FileClose(fileHandle);
}
//+------------------------------------------------------------------+
