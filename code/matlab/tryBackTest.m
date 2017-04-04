function []=tryBackTest()
    clc;
    clear;
    global w;
    w = windmatlab;
    
    %回测时间
    beginDay = now - 100;
    endDay = now-10;
    %回测周期
    period = 'M';
    
    %回测资金
    moneyAmount = 1000000;
    %回测组合名称
    pmsName = 'test';
    
    %选股
    SelectStockCell = backtestSelectStock(@SelectStockStrategy, beginDay, endDay, period);
    %回测
    backtest(@MoenyAssignStock,SelectStockCell,pmsName,moneyAmount);
    
    %输出回测结果
    DispBackTestResult(pmsName,beginDay,endDay);
end

