function codeInfoCell = SelectStockStrategy(day, period)
%选取股票策略
% 返回日期和CodeinfoList(code name weight)
    global w;

    strCurDay = datestr(day,  'yyyy-mm-dd');

    %前一个交易日
    w_tdays_data = w.tdaysoffset(-1,strCurDay);
    strPreDay = datestr(w_tdays_data, 'yyyy-mm-dd');
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

    %前推一周期交易日
    w_tdays_data2 = w.tdaysoffset(-1,strCurDay, strPeriodOption);
    strPre1MonthDay = datestr(w_tdays_data2, 'yyyy-mm-dd');

    %取沪深300的成分及权重
    strOption = strcat('date=', strCurDay, ';windcode=000300.SH');
    HS300Stock=w.wset('IndexConstituent',strOption);
    strHS300Codes = HS300Stock(1,2);
    [HS300StockCount,~]=size(HS300Stock);
    for i=2:HS300StockCount
        strHS300Codes = strcat(strHS300Codes, ',', HS300Stock(i,2));
    end

    %取近一个月的涨跌幅
    w_wss_data0=w.wss(strHS300Codes,'chg_per,pct_chg_per', strcat('startDate=', strPeriodBeginDay), strcat('endDate=', strCurDay));

    %取昨天涨停
    preMaxupordownData=w.wss(strHS300Codes,'maxupordown',strcat('tradeDate=', strPreDay));
    HS300StockData = [HS300Stock,num2cell(w_wss_data0),num2cell(preMaxupordownData)];

    %取今天停牌的股票
    stopStock=w.wset('TradeSuspend',strcat('startdate=', strCurDay, ';enddate=',strCurDay));
    stopStockList = stopStock(:,2);

    %按跌幅从大到小排序
    temp=cell2mat(HS300StockData(:,6));
    [newtemp ind] = sort(temp);
    sortHS300StockData=HS300StockData(ind,:);

    %取跌幅最大的30支股票（过滤掉停牌、昨天涨停的）
    codeInfoCell = cell(30,3);
    count = 1;
    maxupStatus=0;
    code = {''};
    name = {''};
    weight={0};
    [sortHS300StockDataRowCount, ~] = size(sortHS300StockData);
    for i = 1:sortHS300StockDataRowCount
        maxupStatus = sortHS300StockData(i,7);
        if 1 == maxupStatus{1}
            continue;
        elseif (any(strcmp(sortHS300StockData(i,2), stopStockList)))
            continue;
        else
            code = sortHS300StockData(i,2);
            name = sortHS300StockData(i,3);
            weight = sortHS300StockData(i,4);
            codeInfoCell{count,1} = code{1};
            codeInfoCell{count,2} = name{1};
            codeInfoCell{count,3} = weight{1};
            count = count + 1;
            if (count > 30)
                break;
            end
        end
    end
end

