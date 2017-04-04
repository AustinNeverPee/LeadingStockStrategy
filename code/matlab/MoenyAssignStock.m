function stockCountList = MoenyAssignStock(moneyAmount, codeInfoCell, priceCell)
%MoenyAssignStock ���
%   moneyAmount ���ʽ�
%   codeInfoPriceCell��code name weight price
%   stockCountList[return]:����ÿ����Ʊ�������

    [codeInfoCellCount,~]=size(codeInfoCell);
    [priceCellCount,~]=size(priceCell);
    stockCountList = zeros(codeInfoCellCount, 1);
    if priceCellCount ~= codeInfoCellCount
        disp(strcat(num2str(priceCellCount), ',', num2str(codeInfoPriceCellCount)));
        return;
    end

    %����Ȩ���
    if isempty(codeInfoCell)
        return;
    end
    averageMoneyAmount = moneyAmount / codeInfoCellCount;
    for k = 1:codeInfoCellCount
        price = priceCell{k, 1};
        if isnan(price)
            disp(price);
            continue;
        end
        count = fix(averageMoneyAmount / price / 100);
        stockCountList(k,1) = count;
    end
end

