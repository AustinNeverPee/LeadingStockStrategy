function [] = backtest(MoenyAssignStock, SelectStockCell, pmsName, moneyAmount)
%backtest 回测
%   使用PMS做回测
%   MoenyAssignStock: 资金配比function
%   SelectStockCell: date codeInfoCell(30*3)
%   pmsName:    PMS组合名称
%   moneyAmount:总共资金

    global w;

    %先清除PMS内容
    
    %PMS回测
    
    %调整现金
    if isempty(SelectStockCell)
        return;
    end
    strDate = SelectStockCell{1, 1};%日期格式yyyymmdd
    %w.wupf(pmsName,strDate,'CNY',num2str(moneyAmount),'1','Owner=;Direction=Long;HedgeType=Spec;');
    
    %按等权回测
    strSelectStockCodes = '';
    [SelectStockCellCount,~] = size(SelectStockCell);
    for k=1:SelectStockCellCount
        if isempty(SelectStockCell{k, 2})
            continue;
        end
        %显示调仓日期
        disp(SelectStockCell{k, 1});
        
        strSelectStockCodes = SelectStockCell{k, 2}(1,1);
        for l=2:length(SelectStockCell{k,2})
            strSelectStockCodes = strcat(strSelectStockCodes, ',', SelectStockCell{k, 2}(l,1));
        end
        
        [averagePriceData,~,~,~,w_wss_errorid,~] = w.wss(strSelectStockCodes,'vwap', strcat('tradeDate=', SelectStockCell{k, 1}),'cycle=D','priceAdj=U');
        if 0 ~= w_wss_errorid
            disp(averagePriceData);
        end
        
        strCurDate = SelectStockCell{k, 1};%日期格式yyyymmdd
        
        %获取资金配比
        curAccountMoney = 0;
        if k==1 %直接按原始资金配股
            curAccountMoney = moneyAmount;
        else
            %先获取当前总资产(市值+当前现金)，然后按照总资金配比
            %[w_wupf_data,w_wupf_codes,w_wupf_fields,w_wupf_times,w_wupf_errorid,w_wupf_reqid]=w.wupf('3','20150104','600000.SH','1000','10','Direction=Long;HedgeType=Spec;')
            pause(5); % Pause for 5 seconds
            [curAccountMoneyCell,~,~,~,w_wupf_errorid,~]=w.wpf(pmsName,'PMS.PortfolioDaily',strcat('startdate=',strCurDate, ';enddate=',strCurDate,';reportcurrency=CNY;field=Total_Asset'));
            if (0 == w_wupf_errorid)
                curAccountMoney = curAccountMoneyCell{1};
            else
                disp(w_wupf_errorid);
            end
        end
        PriceCell = num2cell(averagePriceData);
        stockCountList = MoenyAssignStock(curAccountMoney, SelectStockCell{k, 2}, PriceCell);

        %[w_wupf_data,w_wupf_codes,w_wupf_fields,w_wupf_times,w_wupf_errorid,w_wupf_reqid]=w.wupf('test1','20141225','600000.SH,601377.SH','2000,500','13.8,14.06','Direction=Long,Long;HedgeType=Spec,Spec;')
        strPrices = num2str(averagePriceData(1));
        strCounts = num2str(stockCountList(1)*100);
        remainderMoney = curAccountMoney;%剩余现金
        for m = 2:length(averagePriceData)
            strPrices = strcat(strPrices, ',', num2str(averagePriceData(m)));
            strCounts = strcat(strCounts, ',', num2str(stockCountList(m)*100));
            remainderMoney = remainderMoney - averagePriceData(m) * stockCountList(m)*100;%计算剩余现金
        end
        
        %加入剩余资金
        strSelectStockCodes = strcat(strSelectStockCodes, ',', 'CNY');
        strCounts = strcat(strCounts, ',', num2str(remainderMoney));
        strPrices = strcat(strPrices, ',1');
        pause(5); % Pause for 5 seconds
        [w_wupf_data,~,~,~,w_wupf_errorid,~]=w.wupf(pmsName,strCurDate,strSelectStockCodes,strCounts,strPrices,'Direction=Long;HedgeType=Spec;');
        %出错时查看
%         if 0 ~= w_wupf_errorid
%             disp(pmsName);
%             disp(strCurDate);
%             disp(strSelectStockCodes);
%             disp(strCounts);
%             disp(strPrices);
%             disp(w_wupf_data);
%         end
    end
end

