function codeInfoCell = SelectStockStrategy(day, period)
%ѡȡ��Ʊ����
% �������ں�CodeinfoList(code name weight)
    global w;

    strCurDay = datestr(day,  'yyyy-mm-dd');

    %ǰһ��������
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

    %ǰ��һ���ڽ�����
    w_tdays_data2 = w.tdaysoffset(-1,strCurDay, strPeriodOption);
    strPre1MonthDay = datestr(w_tdays_data2, 'yyyy-mm-dd');

    %ȡ����300�ĳɷּ�Ȩ��
    strOption = strcat('date=', strCurDay, ';windcode=000300.SH');
    HS300Stock=w.wset('IndexConstituent',strOption);
    strHS300Codes = HS300Stock(1,2);
    [HS300StockCount,~]=size(HS300Stock);
    for i=2:HS300StockCount
        strHS300Codes = strcat(strHS300Codes, ',', HS300Stock(i,2));
    end

    %ȡ��һ���µ��ǵ���
    w_wss_data0=w.wss(strHS300Codes,'chg_per,pct_chg_per', strcat('startDate=', strPeriodBeginDay), strcat('endDate=', strCurDay));

    %ȡ������ͣ
    preMaxupordownData=w.wss(strHS300Codes,'maxupordown',strcat('tradeDate=', strPreDay));
    HS300StockData = [HS300Stock,num2cell(w_wss_data0),num2cell(preMaxupordownData)];

    %ȡ����ͣ�ƵĹ�Ʊ
    stopStock=w.wset('TradeSuspend',strcat('startdate=', strCurDay, ';enddate=',strCurDay));
    stopStockList = stopStock(:,2);

    %�������Ӵ�С����
    temp=cell2mat(HS300StockData(:,6));
    [newtemp ind] = sort(temp);
    sortHS300StockData=HS300StockData(ind,:);

    %ȡ��������30֧��Ʊ�����˵�ͣ�ơ�������ͣ�ģ�
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

