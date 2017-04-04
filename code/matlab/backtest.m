function [] = backtest(MoenyAssignStock, SelectStockCell, pmsName, moneyAmount)
%backtest �ز�
%   ʹ��PMS���ز�
%   MoenyAssignStock: �ʽ����function
%   SelectStockCell: date codeInfoCell(30*3)
%   pmsName:    PMS�������
%   moneyAmount:�ܹ��ʽ�

    global w;

    %�����PMS����
    
    %PMS�ز�
    
    %�����ֽ�
    if isempty(SelectStockCell)
        return;
    end
    strDate = SelectStockCell{1, 1};%���ڸ�ʽyyyymmdd
    %w.wupf(pmsName,strDate,'CNY',num2str(moneyAmount),'1','Owner=;Direction=Long;HedgeType=Spec;');
    
    %����Ȩ�ز�
    strSelectStockCodes = '';
    [SelectStockCellCount,~] = size(SelectStockCell);
    for k=1:SelectStockCellCount
        if isempty(SelectStockCell{k, 2})
            continue;
        end
        %��ʾ��������
        disp(SelectStockCell{k, 1});
        
        strSelectStockCodes = SelectStockCell{k, 2}(1,1);
        for l=2:length(SelectStockCell{k,2})
            strSelectStockCodes = strcat(strSelectStockCodes, ',', SelectStockCell{k, 2}(l,1));
        end
        
        [averagePriceData,~,~,~,w_wss_errorid,~] = w.wss(strSelectStockCodes,'vwap', strcat('tradeDate=', SelectStockCell{k, 1}),'cycle=D','priceAdj=U');
        if 0 ~= w_wss_errorid
            disp(averagePriceData);
        end
        
        strCurDate = SelectStockCell{k, 1};%���ڸ�ʽyyyymmdd
        
        %��ȡ�ʽ����
        curAccountMoney = 0;
        if k==1 %ֱ�Ӱ�ԭʼ�ʽ����
            curAccountMoney = moneyAmount;
        else
            %�Ȼ�ȡ��ǰ���ʲ�(��ֵ+��ǰ�ֽ�)��Ȼ�������ʽ����
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
        remainderMoney = curAccountMoney;%ʣ���ֽ�
        for m = 2:length(averagePriceData)
            strPrices = strcat(strPrices, ',', num2str(averagePriceData(m)));
            strCounts = strcat(strCounts, ',', num2str(stockCountList(m)*100));
            remainderMoney = remainderMoney - averagePriceData(m) * stockCountList(m)*100;%����ʣ���ֽ�
        end
        
        %����ʣ���ʽ�
        strSelectStockCodes = strcat(strSelectStockCodes, ',', 'CNY');
        strCounts = strcat(strCounts, ',', num2str(remainderMoney));
        strPrices = strcat(strPrices, ',1');
        pause(5); % Pause for 5 seconds
        [w_wupf_data,~,~,~,w_wupf_errorid,~]=w.wupf(pmsName,strCurDate,strSelectStockCodes,strCounts,strPrices,'Direction=Long;HedgeType=Spec;');
        %����ʱ�鿴
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

