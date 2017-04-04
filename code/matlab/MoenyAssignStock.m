function stockCountList = MoenyAssignStock(moneyAmount, codeInfoCell, priceCell)
%MoenyAssignStock 配股
%   moneyAmount 总资金
%   codeInfoPriceCell：code name weight price
%   stockCountList[return]:返回每个股票配多少手

    [codeInfoCellCount,~]=size(codeInfoCell);
    [priceCellCount,~]=size(priceCell);
    stockCountList = zeros(codeInfoCellCount, 1);
    if priceCellCount ~= codeInfoCellCount
        disp(strcat(num2str(priceCellCount), ',', num2str(codeInfoPriceCellCount)));
        return;
    end

    %按等权配比
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

