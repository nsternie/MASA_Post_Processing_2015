%%  Given the start and end times of a test, return the...
%   data that appears within that time
function [new_data] = DataToTestTime(start_time, end_time, data)
new_data = data(start_time:end_time);
end
