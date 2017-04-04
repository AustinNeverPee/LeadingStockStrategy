function [find,data] = GetDataByField(WindData, Fields, strFieldName)
%GetDataByField 通过strFieldName获取Data
%
    find = false;
    data = {};
    if length(WindData) ~= length(Fields)
        return;
    end
    for k = 1 : length(Fields)
        if strcmp(strFieldName, Fields{k})
            find = true;
            if iscell(WindData)
                data = WindData{k};
            else
                data = WindData(k);
            end
            break;
        end
    end
end

