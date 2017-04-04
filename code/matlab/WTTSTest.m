function [ output_args ] = WTTSTest(userName, password, SelectStockStrategy, MoenyAssignStock)
%WTTSTest WTTS����
%   
    global w;
    w=windmatlab;
    global period;
    period = 'W'; %�������ڣ��滻���Լ���Ҫ��,֧��D��W��M
    
    [Data,Fields,ErrorCode]=w.tlogon('0000', '0', userName, password, 'SHSZ');
    [find,logonId] = GetDataByField(Data, Fields, 'LogonID');
    if ~find
        return;
    end
    logonId = num2str(logonId);
    
    PeriodNum = 60*60*24;
    T = timer('Name', 'WindTradeSample', 'TimerFcn', {@WindWTTSFunc, logonId, SelectStockStrategy},...
            'ExecutionMode', 'fixedRate','Period', PeriodNum);
    start(T);
end

function WindWTTSFunc(obj,events,logonId,SelectStockStrategy)
    global w;
    global period;
    
    %�Ƿ�Ϊÿ�ܵ�һ��������
    isFirstDay = IsCurPeriodFirstTradeDay(period);
    if ~isFirstDay %���ǵ�һ��
        return;
    end
    
    %����9��30��ִ�в���
    curTime = 0;
    destTime = datenum('09::30::00');
    while(1)
        curTime = datenum(datestr(now, 'HH:MM:SS'));
        if curTime >= destTime
            break;
        else
            pause(10); %ͣ��ʮ��
        end
    end
    runWTTS(logonId, SelectStockStrategy);
end

function is = IsCurPeriodFirstTradeDay(period)
%�Ƿ�Ϊ��ǰ���ڵ�һ��������
    if strcmp(period, 'D') %����Ϊ�գ���ֱ�ӷ���
        is = true;
        return;
    end
    
    global w;
    
    is = false;
    CurDay = floor(now); %today
    %���������
    tradeDay = datenum(w.tdaysoffset(0,datestr(CurDay, 'yyyy-mm-dd')));
    if (CurDay ~= tradeDay) %��ǰ���ڷǽ�����
        is = false;
        return;
    end
    
    if strcmp(period, 'W')
        %ȡǰһ��������
        pretradeDay = datenum(w.tdaysoffset(-1,datestr(CurDay, 'yyyy-mm-dd')));
        if CurDay == pretradeDay + 1 %��ǰ���ڸպõ���ǰһ��������+1����ǰ���ں�ǰһ��������ͬһ��
            is = false;
            return;
        end
        curDayofMonth = day(CurDay);
        preDayofMonth = day(pretradeDay);
        curWeekIndex = 1;
        preWeekIndex = 1;
        curMonthCalendar = calendar(year(CurDay), month(CurDay));%��ȡ���µ�����
        [x,y]= size(curMonthCalendar);
        for k = 1: x
            for m = 1: y
                if preDayofMonth == curMonthCalendar(k, m)
                    preWeekIndex = k;
                elseif curDayofMonth == curMonthCalendar(k, m)
                    curWeekIndex = k;
                end
            end
        end
        if preWeekIndex ~= curWeekIndex %�Ƿ�Ϊͬһ��
            is = true;
        else
            is = false;
        end
    elseif strcmp(period, 'M')
        %ȡǰһ��������
        pretradeDay = datenum(w.tdaysoffset(-1,datestr(CurDay, 'yyyy-mm-dd')));
        preDayMonth = month(pretradeDay);
        curDayMonth = month(CurDay);
        if preDayMonth ~= curDayMonth %�Ƿ���ͬһ����
            is = true;
        else
            is = false;
        end
    end
end

function runWTTS(logonId, SelectStockStrategy)
    
    global w;
    global period;

    curDay = now;
    
    %��ѯȫ���ʽ�
    [CapitalData,CapitalFields,ErrorCode]=w.tquery('Capital', strcat('LogonId=', logonId));
    [~, moneyAmount] = GetDataByField(CapitalData, CapitalFields, 'TotalAsset');

    %��ǰ�ֲ����
    [PositionData,PositionFields,ErrorCode]=w.tquery('Position', strcat('LogonId=', logonId));
    [PositionDataCount,~] = size(PositionData);
    
    %codeInfoCell(code name weight)
    codeInfoCell = SelectStockStrategy(curDay, period);
    %ȡ�ּ�
    strSelectStockCodes = codeInfoCell{1, 1};
    [codeInfoCellCount,~] = size(codeInfoCell);
    for m=2:codeInfoCellCount
        strSelectStockCodes = strcat(strSelectStockCodes, ',', codeInfoCell{m, 1});
    end
    curPriceData=w.wsq(strSelectStockCodes,'rt_latest');
    priceCell = num2cell(curPriceData);
    
    %Ŀ���Ʊ����
    stockCountList = MoenyAssignStock(moneyAmount, codeInfoCell, priceCell);
    
    %������Ʊ code price count
    SellStockData = cell(PositionDataCount,3);
    %�����Ʊ code price count
    BuyStockData = cell(codeInfoCellCount,3);
    SellStockIndex = 1;
    BuyStockIndex = 1;
    for k = 1: PositionDataCount
        [find, code] = GetDataByField(PositionData(k,:), PositionFields, 'SecurityCode');
        if ~find
            continue;
        end
        [~, curStockCount] = GetDataByField(PositionData(k,:), PositionFields, 'SecurityBalance'); %���ﵥλ�ǹ�
        [~, curStockForzenCount] = GetDataByField(PositionData(k,:), PositionFields, 'SecurityForzen'); %���ﵥλ�ǹ�
        curStockCount = curStockCount - curStockForzenCount;
        bFind = false;
        for m=1:codeInfoCellCount
            if strcmp(code, codeInfoCell{m,1})%��Ŀ��ֲ���
                %Ŀǰ�ֲ�����
                destStockCount = stockCountList(m) * 100; %���ﵥλ����
                curPrice = priceCell{m, 1};
                if destStockCount >= curStockCount %Ŀ��ֱֲȵ�ǰ�ֲ������࣬������
                    BuyStockData{BuyStockIndex,1} = code;
                    BuyStockData{BuyStockIndex,2} = curPrice;
                    BuyStockData{BuyStockIndex,3} = destStockCount - curStockCount;
                    BuyStockIndex = BuyStockIndex + 1;
                elseif destStockCount < curStockCount %Ŀ��ֱֲȵ�ǰ�ֲ������٣�������
                    SellStockData{SellStockIndex,1} = code;
                    SellStockData{SellStockIndex,2} = curPrice;
                    SellStockData{SellStockIndex,3} = curStockCount - destStockCount;
                    SellStockIndex = SellStockIndex + 1;
                end
                bFind = true;
            end
        end
        if ~bFind
            %����Ŀ��ֲ���,��ȫ������
            SellStockData{SellStockIndex,1} = code;
            [~, curPrice] = GetDataByField(PositionData(k,:), PositionFields, 'LastPrice'); %���ﵥλ�ǹ�
            SellStockData{SellStockIndex,2} = curPrice;
            SellStockData{SellStockIndex,3} = curStockCount;
            SellStockIndex = SellStockIndex + 1;   
        end
    end
    
    %���������µ�
    for m = 1: codeInfoCellCount
        code = codeInfoCell{m,1};
        if any(strcmp(BuyStockData(:,1), code))
            continue;
        elseif any(strcmp(SellStockData(:,1), code))
            continue;
        end
        destStockCount = stockCountList(m) * 100; %���ﵥλ����
        BuyStockData{BuyStockIndex,1} = code;
        BuyStockData{BuyStockIndex,2} = priceCell{m,1}; %price
        BuyStockData{BuyStockIndex,3} = destStockCount;
        BuyStockIndex = BuyStockIndex + 1;
    end
    
   %�µ�
   %������
   for k = 1: SellStockIndex - 1
        %�˴�Ӧ���ǲ�
        totalSellCount = SellStockData{k,3};
        orderCount = floor(totalSellCount/10000);
        if (orderCount * 10000) < totalSellCount
            orderCount = orderCount + 1;
        end
        for m = 1 : orderCount
            SellCount = 10000;
            if m==orderCount
                SellCount = totalSellCount-10000*(orderCount-1);
            end
            w.torder(SellStockData{k,1}, 'Sell', num2str(SellStockData{k,2}), num2str(SellCount), strcat('LogonId=', logonId));
        end
   end
   %������
   for k = 1: BuyStockIndex - 1
       totalBuyCount = BuyStockData{k,3};
       if totalBuyCount > 0
            %�˴�Ӧ���ǲ�
            %����ÿ���µ�һ���
            orderCount = floor(totalBuyCount/10000);
            if (orderCount * 10000) < totalBuyCount
                orderCount = orderCount + 1;
            end
            for m = 1 : orderCount
                BuyCount = 10000;
                if m==orderCount
                    BuyCount = totalBuyCount-10000*(orderCount-1);
                end
                [BuyData,BuyFields,ErrorCode] = w.torder(BuyStockData{k,1}, 'Buy', num2str(BuyStockData{k,2}), num2str(BuyCount), strcat('OrderType=LMT;LogonId=', logonId));
%                 %��ѯ�µ����
%                 [~,ReqId] = GetDataByField(BuyData, BuyFields, 'RequestID');
%                 [Data2,Fields,ErrorCode]=w.tquery('Order', strcat('LogonId=', logonId, ';RequestID=', num2str(ReqId)));
%                 disp(Data2);
            end
       end
   end
end

