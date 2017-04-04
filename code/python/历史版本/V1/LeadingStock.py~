# -*- coding: utf-8 -*-
''' 龙头板块与龙头股策略选股
@version: 1.0
@author: Austin Yang
@date: 2016-4-3
'''

from datetime import *
from WindPy import *
import xlrd
import operator

# 对股票打分并排名，获得龙头股
def rank(stocks_info):
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

    print(score)
    print(rank)

if __name__ == "__main__":
    # 获取热点板块内股票代码
    tables = xlrd.open_workbook('Data/Table.xls')
    table_1 = tables.sheets()[0]
    stock_names = table_1.col_values(0)
    print(stock_names)

    # 从wind中获取数据
    w.start()

    # 保存股票信息
    stocks_info = {}
    for stock_name in stock_names:
        # 根据股票代码从wind中获取相应数据
        data = w.wsd(stock_name, "close, volume", "2016-03-20", "2016-03-31")
        stocks_info[stock_name] = data.Data

    rank(stocks_info)
    w.stop()
