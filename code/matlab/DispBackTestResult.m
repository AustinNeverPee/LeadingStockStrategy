function [] = DispBackTestResult(pmsName, beginDay, endDay)
%DispBackTestResult 显示pmsName回测名称
%
    global w;
    strstartdate = strcat('startdate=', datestr(beginDay, 'yyyymmdd'));
    strenddate = strcat(';enddate=', datestr(endDay, 'yyyymmdd'));
    [w_wpf_data,w_wpf_codes,w_wpf_fields,w_wpf_times,w_wpf_errorid,w_wpf_reqid]=w.wpf(pmsName,'PMS.PortfolioDaily', strcat(strstartdate, strenddate, ';reportcurrency=CNY;'));
    
    %取出日期和total_asset(总资产)
    dateIndex = 0;
    total_assetIndex = 0;
    for k=1:length(w_wpf_fields)
        if strcmp(w_wpf_fields{k}, 'trade_date')
            dateIndex = k;
        elseif strcmp(w_wpf_fields{k}, 'total_asset')
            total_assetIndex = k;
        end
    end
        
    datecell = w_wpf_data(:,dateIndex);
    total_assetMat = cell2mat(w_wpf_data(:,total_assetIndex));
    dateList = zeros(length(datecell),1);
    for k=1:length(datecell)
        dateList(k) = datenum(num2str(datecell{k,1}),'yyyymmdd');
    end
    
    %取工作日
    [~,~,~,w_tdays_times,w_tdays_errorid,~]=w.tdays(datestr(beginDay, 'yyyymmdd'),datestr(endDay, 'yyyymmdd'));
    %[c1,ia1,ib1] = intersect(w_tdays_times,w_tdays_times2);
    [tradeDateList, ia1,~] = intersect(dateList, w_tdays_times);
    tradeDateTotal_assetMat = total_assetMat(ia1,:);
    
    %绘图
    plot(tradeDateList, tradeDateTotal_assetMat);
    datetick('x','yyyymmdd');
    grid;
    xlabel('日期');
    ylabel('总资产');
    minDate = tradeDateList(1);
    maxDate = tradeDateList(length(tradeDateList));
    xlim([minDate-3, maxDate+3]);
end

