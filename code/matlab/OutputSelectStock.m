function [] = OutputSelectStock(SelectStockCell, xlsName)
%OutputSelectStock Êä³öSelectStockCell
%   SelectStockCell: date codeInfoCell(30*3)
    date = '';
    
    [SelectStockCellCount,~]=size(SelectStockCell);
    
    dateNum = 1;
    dateColumnName = 'A';
    codeInfoColumnName = 'B';
    for i = 1 : SelectStockCellCount
        date = SelectStockCell(i, 1);
        codeInfoCell = SelectStockCell{i, 2};
        str = strcat(dateColumnName, num2str(dateNum));
        xlswrite(xlsName, date, 1, strcat(str, ':', str));
        xlswrite(xlsName, codeInfoCell, 1, strcat(codeInfoColumnName, num2str(dateNum+1)));
        dateNum = dateNum + 31;
    end

end

