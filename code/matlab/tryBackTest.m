function []=tryBackTest()
    clc;
    clear;
    global w;
    w = windmatlab;
    
    %�ز�ʱ��
    beginDay = now - 100;
    endDay = now-10;
    %�ز�����
    period = 'M';
    
    %�ز��ʽ�
    moneyAmount = 1000000;
    %�ز��������
    pmsName = 'test';
    
    %ѡ��
    SelectStockCell = backtestSelectStock(@SelectStockStrategy, beginDay, endDay, period);
    %�ز�
    backtest(@MoenyAssignStock,SelectStockCell,pmsName,moneyAmount);
    
    %����ز���
    DispBackTestResult(pmsName,beginDay,endDay);
end

