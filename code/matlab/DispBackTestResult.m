function [] = DispBackTestResult(pmsName, beginDay, endDay)
%DispBackTestResult ��ʾpmsName�ز�����
%
    global w;
    strstartdate = strcat('startdate=', datestr(beginDay, 'yyyymmdd'));
    strenddate = strcat(';enddate=', datestr(endDay, 'yyyymmdd'));
    [w_wpf_data,w_wpf_codes,w_wpf_fields,w_wpf_times,w_wpf_errorid,w_wpf_reqid]=w.wpf(pmsName,'PMS.PortfolioDaily', strcat(strstartdate, strenddate, ';reportcurrency=CNY;'));
    
    %ȡ�����ں�total_asset(���ʲ�)
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
    
    %ȡ������
    [~,~,~,w_tdays_times,w_tdays_errorid,~]=w.tdays(datestr(beginDay, 'yyyymmdd'),datestr(endDay, 'yyyymmdd'));
    %[c1,ia1,ib1] = intersect(w_tdays_times,w_tdays_times2);
    [tradeDateList, ia1,~] = intersect(dateList, w_tdays_times);
    tradeDateTotal_assetMat = total_assetMat(ia1,:);
    
    %��ͼ
    plot(tradeDateList, tradeDateTotal_assetMat);
    datetick('x','yyyymmdd');
    grid;
    xlabel('����');
    ylabel('���ʲ�');
    minDate = tradeDateList(1);
    maxDate = tradeDateList(length(tradeDateList));
    xlim([minDate-3, maxDate+3]);
end

