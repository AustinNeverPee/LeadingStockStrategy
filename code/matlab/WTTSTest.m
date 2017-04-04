function [ output_args ] = WTTSTest(userName, password, SelectStockStrategy, MoenyAssignStock)
%WTTSTest WTTS交易
%   
    global w;
    w=windmatlab;
    global period;
    period = 'W'; %设置周期，替换成自己想要的,支持D、W、M
    
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
    
    %是否为每周第一个交易日
    isFirstDay = IsCurPeriodFirstTradeDay(period);
    if ~isFirstDay %不是第一天
        return;
    end
    
    %超过9：30，执行操作
    curTime = 0;
    destTime = datenum('09::30::00');
    while(1)
        curTime = datenum(datestr(now, 'HH:MM:SS'));
        if curTime >= destTime
            break;
        else
            pause(10); %停顿十秒
        end
    end
    runWTTS(logonId, SelectStockStrategy);
end

function is = IsCurPeriodFirstTradeDay(period)
%是否为当前周期第一个交易日
    if strcmp(period, 'D') %周期为日，则直接返回
        is = true;
        return;
    end
    
    global w;
    
    is = false;
    CurDay = floor(now); %today
    %最近交易日
    tradeDay = datenum(w.tdaysoffset(0,datestr(CurDay, 'yyyy-mm-dd')));
    if (CurDay ~= tradeDay) %当前日期非交易日
        is = false;
        return;
    end
    
    if strcmp(period, 'W')
        %取前一个交易日
        pretradeDay = datenum(w.tdaysoffset(-1,datestr(CurDay, 'yyyy-mm-dd')));
        if CurDay == pretradeDay + 1 %当前日期刚好等于前一个交易日+1，则当前日期和前一个日期在同一周
            is = false;
            return;
        end
        curDayofMonth = day(CurDay);
        preDayofMonth = day(pretradeDay);
        curWeekIndex = 1;
        preWeekIndex = 1;
        curMonthCalendar = calendar(year(CurDay), month(CurDay));%获取当月的日历
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
        if preWeekIndex ~= curWeekIndex %是否为同一周
            is = true;
        else
            is = false;
        end
    elseif strcmp(period, 'M')
        %取前一个交易日
        pretradeDay = datenum(w.tdaysoffset(-1,datestr(CurDay, 'yyyy-mm-dd')));
        preDayMonth = month(pretradeDay);
        curDayMonth = month(CurDay);
        if preDayMonth ~= curDayMonth %是否在同一个月
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
    
    %查询全部资金
    [CapitalData,CapitalFields,ErrorCode]=w.tquery('Capital', strcat('LogonId=', logonId));
    [~, moneyAmount] = GetDataByField(CapitalData, CapitalFields, 'TotalAsset');

    %当前持仓情况
    [PositionData,PositionFields,ErrorCode]=w.tquery('Position', strcat('LogonId=', logonId));
    [PositionDataCount,~] = size(PositionData);
    
    %codeInfoCell(code name weight)
    codeInfoCell = SelectStockStrategy(curDay, period);
    %取现价
    strSelectStockCodes = codeInfoCell{1, 1};
    [codeInfoCellCount,~] = size(codeInfoCell);
    for m=2:codeInfoCellCount
        strSelectStockCodes = strcat(strSelectStockCodes, ',', codeInfoCell{m, 1});
    end
    curPriceData=w.wsq(strSelectStockCodes,'rt_latest');
    priceCell = num2cell(curPriceData);
    
    %目标股票数量
    stockCountList = MoenyAssignStock(moneyAmount, codeInfoCell, priceCell);
    
    %卖出股票 code price count
    SellStockData = cell(PositionDataCount,3);
    %买入股票 code price count
    BuyStockData = cell(codeInfoCellCount,3);
    SellStockIndex = 1;
    BuyStockIndex = 1;
    for k = 1: PositionDataCount
        [find, code] = GetDataByField(PositionData(k,:), PositionFields, 'SecurityCode');
        if ~find
            continue;
        end
        [~, curStockCount] = GetDataByField(PositionData(k,:), PositionFields, 'SecurityBalance'); %这里单位是股
        [~, curStockForzenCount] = GetDataByField(PositionData(k,:), PositionFields, 'SecurityForzen'); %这里单位是股
        curStockCount = curStockCount - curStockForzenCount;
        bFind = false;
        for m=1:codeInfoCellCount
            if strcmp(code, codeInfoCell{m,1})%在目标持仓里
                %目前持仓数量
                destStockCount = stockCountList(m) * 100; %这里单位是手
                curPrice = priceCell{m, 1};
                if destStockCount >= curStockCount %目标持仓比当前持仓数量多，需买入
                    BuyStockData{BuyStockIndex,1} = code;
                    BuyStockData{BuyStockIndex,2} = curPrice;
                    BuyStockData{BuyStockIndex,3} = destStockCount - curStockCount;
                    BuyStockIndex = BuyStockIndex + 1;
                elseif destStockCount < curStockCount %目标持仓比当前持仓数量少，需卖出
                    SellStockData{SellStockIndex,1} = code;
                    SellStockData{SellStockIndex,2} = curPrice;
                    SellStockData{SellStockIndex,3} = curStockCount - destStockCount;
                    SellStockIndex = SellStockIndex + 1;
                end
                bFind = true;
            end
        end
        if ~bFind
            %不在目标持仓里,则全部卖出
            SellStockData{SellStockIndex,1} = code;
            [~, curPrice] = GetDataByField(PositionData(k,:), PositionFields, 'LastPrice'); %这里单位是股
            SellStockData{SellStockIndex,2} = curPrice;
            SellStockData{SellStockIndex,3} = curStockCount;
            SellStockIndex = SellStockIndex + 1;   
        end
    end
    
    %处理买入下单
    for m = 1: codeInfoCellCount
        code = codeInfoCell{m,1};
        if any(strcmp(BuyStockData(:,1), code))
            continue;
        elseif any(strcmp(SellStockData(:,1), code))
            continue;
        end
        destStockCount = stockCountList(m) * 100; %这里单位是手
        BuyStockData{BuyStockIndex,1} = code;
        BuyStockData{BuyStockIndex,2} = priceCell{m,1}; %price
        BuyStockData{BuyStockIndex,3} = destStockCount;
        BuyStockIndex = BuyStockIndex + 1;
    end
    
   %下单
   %先卖出
   for k = 1: SellStockIndex - 1
        %此处应考虑拆单
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
   %再买入
   for k = 1: BuyStockIndex - 1
       totalBuyCount = BuyStockData{k,3};
       if totalBuyCount > 0
            %此处应考虑拆单
            %假如每次下单一万股
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
%                 %查询下单结果
%                 [~,ReqId] = GetDataByField(BuyData, BuyFields, 'RequestID');
%                 [Data2,Fields,ErrorCode]=w.tquery('Order', strcat('LogonId=', logonId, ';RequestID=', num2str(ReqId)));
%                 disp(Data2);
            end
       end
   end
end

