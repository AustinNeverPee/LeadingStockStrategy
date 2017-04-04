function SelectStockCell = backtestSelectStock(SelectStockStrategy, beginDay, endDay, period)
%backtest 回测函数
%   根据起始日期和终止日期计算出每个周期的选股cell
%   SelectStockCell: date codeInfoCell(30*3)
    
    global w;
    w = windmatlab;
    strPeriodOption = '';
    strPeriodBeginDay = '';
    switch (period)
        case 'W'
            strPeriodOption = 'Period=W';
            strPeriodBeginDay = 'ED-1W';
        case 'Y'
            strPeriodOption = 'Period=Y';
            strPeriodBeginDay = 'ED-1Y';
        case 'D'
            strPeriodOption = 'Period=TD';
            strPeriodBeginDay = 'ED-1TD';
        otherwise
            strPeriodOption = 'Period=M';
            strPeriodBeginDay = 'ED-1M';
    end
    strBeginDay = datestr(beginDay,  'yyyy-mm-dd');
    strEndDay = datestr(endDay,  'yyyy-mm-dd');
    w_tdays_data=w.tdays(strBeginDay,strEndDay,strPeriodOption);
    
    codeInfoCell = cell(30, 3);
    SelectStockCell = cell(length(w_tdays_data), 2);
    for i = 1 : length(w_tdays_data)
        codeInfoCell = SelectStockStrategy(w_tdays_data(i), period);
        SelectStockCell{i, 1} = datestr(datenum(w_tdays_data{i}), 'yyyymmdd');
        SelectStockCell{i, 2} = codeInfoCell;
    end
end

