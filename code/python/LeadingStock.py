# -*- coding: utf-8 -*-
''' 龙头板块与龙头股策略（选股+回测）
@version: 2.0
@author: Austin Yang
@date: 2016-4-7
'''

from WindPy import *
import os, datetime
import pandas as pd
import numpy as np
import math
import matplotlib.pyplot as plt
import xlrd
import xlwt
import operator

# 对股票打分并排名，获得龙头股
def Rank(stocks_info):
    # 对股票打分
    score = {}
    for stock_name in stocks_info:
        score[stock_name] = 0
        for i in range(0, len(stocks_info[stock_name][0]) - 1):
            if stocks_info[stock_name][0][i] < stocks_info[stock_name][0][i + 1]:
                if stocks_info[stock_name][1][i] < stocks_info[stock_name][1][i + 1]:
                    # 价格上升，同时成交量上升，加2分
                    score[stock_name] += 2
                else:
                    # 价格上升，同时成交两下降，加1分
                    score[stock_name] += 1
            else:
                if stocks_info[stock_name][1][i] < stocks_info[stock_name][1][i + 1]:
                    # 价格下降，同时成交量上升，减1分
                    score[stock_name] -= 1
                else:
                    # 价格下降，同时成交量下降，减2分
                    score[stock_name] -= 2
    # 对得分排序
    rank = sorted(score.items(), key=operator.itemgetter(1), reverse=True)

    # 取前五支股票返回
    select_stocks = []
    weights = []
    for i in range(0, 5):
        select_stocks.append(rank[i][0])
        weights.append(20)

    return (select_stocks, weights)

# 将选出的股票保存
def SaveStocks(cs_interval, select_stocks, weights):
    wbk = xlwt.Workbook()
    sheet = wbk.add_sheet('sheet1')
    sheet.write(0, 0, 'stock')
    sheet.write(0, 1, 'weight')
    for i in range(0, len(select_stocks)):
        sheet.write(i + 1, 0, select_stocks[i])
        sheet.write(i + 1, 1, weights[i])
    wbk_path = "../../Data/hold_stocks/" + cs_interval + "PicskStocks_Weight.xlsx"
    wbk.save(wbk_path)

def GetPickStock(trade_day):
    #tday = w.tdaysoffset(-1, trade_day).Data[0][0].strftime('%Y-%m-%d')
    tday = trade_day
    filename = '../../Data/hold_stocks/' + tday + 'PicskStocks_Weight.xlsx'
    pddata = pd.read_excel(filename, 'sheet1', index_col = None)
    stocks = pddata['stock']
    sweight = pddata['weight']

    SelectStocks = []
    weight = []
    for i in range(0, len(stocks)):
        SelectStocks.append(str(stocks.iloc[i]))
        weight.append(float(sweight.iloc[i]))

    return (SelectStocks, weight)

# 配股函数
def MoneyAssignStock(index, AccountMoney, SelectStocks, PriceData, weight):
    if index * 300 > AccountMoney:
        print 'not enough money to buy index!!!!!!!!!!'
        usable_money = AccountMoney - 5000
    else:
        usable_money = index * 300
    # usable_money = AccountMoney - 50000
    print 'usable_money: ', usable_money

    stocksCountList = []
    stocks_num = len(SelectStocks)
    if stocks_num != len(PriceData):
        print 'nums of SelectStocks doesn\'t match averagePriceData: ', stocks_num, len(PriceData)
        return stocksCountList

    # # 每个股票可用金额
    # 配股
    for i in range(0, stocks_num):
        price = PriceData[i]
        assign_money = usable_money * weight[i] * 0.01
        if math.isnan(price):
            count = 0
        else:
            count = int(round(assign_money / price / 100))
        stocksCountList.append(count)
        # print usable_money, weight[i], assign_money, price, count

    return stocksCountList
    
if __name__ == "__main__":
    w.start()


    
#     '''
#     ******************** 选股 ********************
#     '''
#     cs_start_date = '2014-11-28'
#     cs_end_date = '2015-12-31'
# 
#     # 根据调仓周期分割区间
#     cs_tdays_data = w.tdays(cs_start_date, cs_end_date, 'Period=M')
#     if cs_tdays_data.ErrorCode != 0:
#         print "回测区间出错"
#         print cs_tdays_data.Data[0]
#     cs_tdays_data = cs_tdays_data.Data[0]
# 
#     # 计算区间里每个月的第一个交易日
#     cs_intervals = []
#     for cs_tday in cs_tdays_data:
#         cs_intervals.append(cs_tday.strftime('%Y-%m-%d'))
#     print cs_intervals
#     
#     # 获取热点板块内股票代码
#     tables = xlrd.open_workbook('../../Data/Table.xls')
#     table_1 = tables.sheets()[0]
#     stock_names = table_1.col_values(0)
#     print(stock_names)
# 
#     for i in range(1, len(cs_intervals)):
#         print(cs_intervals[i])
#         # 保存股票信息
#         stocks_info = {}
#         for stock_name in stock_names:
#             # 根据股票代码从wind中获取相应数据
#             cs_data = w.wsd(stock_name, "close, volume", cs_intervals[i - 1], cs_intervals[i])
#             stocks_info[stock_name] = cs_data.Data
# 
#         (select_stocks, weights) = Rank(stocks_info)
#         print(select_stocks, weights)
# 
#         SaveStocks(cs_intervals[i], select_stocks, weights)
#     '''
#     ******************** 选股 ********************
#     '''


    
    '''
    ******************** 回测 ********************
    '''
    # 调整初始资金和pms名称
    moneyAmount = 1100000
    pmsName = 'LeadingStock'

    bt_start_date = '2014-12-31'
    bt_end_date = '2015-12-31'

    # 根据调仓周期分割回测区间
    w_tdays_data = w.tdays(bt_start_date, bt_end_date, 'Period=M')
    if w_tdays_data.ErrorCode != 0:
        print "回测区间出错"
        print w_tdays_data.Data[0]
    w_tdays_data = w_tdays_data.Data[0]

    # 计算区间里每个月的第一个交易日
    intervals = []
    for tdays in w_tdays_data:
        intervals.append(tdays.strftime('%Y-%m-%d'))
    print intervals
    
    # 回测开始，PMS回测
    for trade_day in intervals:
        # 显示调仓日期
        print trade_day
        # 转换成%Y%m%d格式（去掉中间的两横）
        str_trade_day = trade_day[0:4] + trade_day[5:7] + trade_day[8:10]

        # 获取当前月选股结果
        (SelectStocks, weight) = GetPickStock(trade_day)

        # 获取每支股票的日内均价vwap
        strSelectStocks = SelectStocks[0]
        for i in range(1, len(SelectStocks)):
            strSelectStocks += ',' + SelectStocks[i]
        averagePriceData = w.wss(strSelectStocks, 'vwap', 'tradeDate='+trade_day, 'cycle=D', 'priceAdj=U')
        if averagePriceData.ErrorCode != 0:
            print averagePriceData.Data[0]
        averagePriceData = averagePriceData.Data[0]

        # 获取资金配比
        curAccountMoney = 0
        if trade_day == intervals[0]:
            curAccountMoney = moneyAmount
        else:
            curAccountMoney = w.wpf(pmsName,'PMS.PortfolioDaily','startdate='+str_trade_day+';enddate='+str_trade_day+';reportcurrency=CNY;field=Total_Asset')
            if curAccountMoney.ErrorCode == 0:
                curAccountMoney = curAccountMoney.Data[0][0]
                print 'curAccountMoney:', curAccountMoney
            else:
                print curAccountMoney.Data[0]

        # 计算配股
        index = w.wss('000300.SH','open','tradeDate='+trade_day,'priceAdj=U','cycle=D').Data[0][0]
        print 'HS300', trade_day, index
        # stocksCountList = MoneyAssignStock(curAccountMoney, SelectStocks, averagePriceData, industryWeight, rnt_stocks)
        stocksCountList = MoneyAssignStock(index, curAccountMoney, SelectStocks, averagePriceData, weight)

        buyWeight = 0.0
        buyStocksCount = 0
        # 将各个股票价格和购买手数转换成str，并且计算剩余现金
        if math.isnan(averagePriceData[0]):
            strPrices = '0'
            remainderMoney = curAccountMoney
        else:
            buyWeight += weight[0]
            buyStocksCount += 1
            strPrices = str(averagePriceData[0])
            remainderMoney = curAccountMoney - averagePriceData[0]*stocksCountList[0]*100
        strCounts = str(stocksCountList[0]*100)
        for i in range(1, len(averagePriceData)):
            strCounts += ',' + str(stocksCountList[i]*100)
            if math.isnan(averagePriceData[i]):
                strPrices = strPrices + ',0'
                continue
            else:
                buyWeight += weight[i]
                buyStocksCount += 1
                strPrices = strPrices + ',' + str(averagePriceData[i])
                remainderMoney = remainderMoney - averagePriceData[i]*stocksCountList[i]*100
        # 加入剩余现金
        strSelectStocks = strSelectStocks + ',CNY'
        strCounts = strCounts + ',' + str(remainderMoney)
        strPrices = strPrices + ',1'
        print 'remainderMoney: ', remainderMoney
        print 'buyWeight: ', buyWeight
        print 'buyStocksCount: ', buyStocksCount

        # print strSelectStocks
        # print strCounts
        # print strPrices
        # print len(strSelectStocks.split(',')), len(strCounts.split(',')), len(strPrices.split(','))
        # 上传本月的组合
        w_wupf = w.wupf(pmsName,str_trade_day,strSelectStocks,strCounts,strPrices,'Direction=Long;HedgeType=Hedge;')

        # 如果出错输出错误信息
        if w_wupf.ErrorCode != 0:
            print 'WUPF ERROR!!!!!!!!!!'
            print pmsName
            print strSelectStocks
            print strCounts
            print strPrices
            print w_wupf.Data[0][0].encode('gbk')
    '''
    ******************** 回测 ********************
    '''

    w.stop()
