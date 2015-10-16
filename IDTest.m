%% IDtest.m
% Michigan Aeronautical Science Association

%% Declarations!
function [test_duration, start_index, end_index, real_start_index, real_end_index] = IDtest(times, time_step, expected_test_duration, left_buffer, right_buffer, data)

%% Initializations
data_average = mean(data);
data_stddev  = std(data);

optimized_steps = expected_test_duration/time_step;
location = 1;

%% Identify the test duration

% Find a location where the data is more than two standard deviations from average
start_index = -1;
while(start_index==-1)
    if(2*data_stddev < abs(data(location)-data_average))
        start_index = location;
    end
    location = location+optimized_steps;
    if length(data) < location
        start_index = -2;
    end
end
if start_index == -2
    [max_value,start_index] = max(data);
end
end_index = start_index;

% Identify the start and end of the test
threshold = 2*data_stddev;
while(threshold<abs(data(start_index)-data_average) && 1<start_index)
    start_index = start_index-1;
end
real_start_index = start_index;
while(threshold<abs(data(end_index)-data_average) && end_index<length(times))
    end_index = end_index+1;
end
real_end_index = end_index;
test_duration = times(end_index)-times(start_index);

% Provide a buffer for both the start and end of test (make sure we see all
% the data)
counter = left_buffer/time_step;
while(0<counter && 1<start_index)
    start_index = start_index-1;
    counter = counter-1;
end
counter = right_buffer/time_step;
while(0<counter && end_index<length(times))
    end_index = end_index+1;
    counter = counter-1;
end

%% Outputs
fprintf(sprintf('Test begins at %f seconds\n',times(start_index)));
fprintf(sprintf('Test ends at %f seconds\n',times(end_index)));
fprintf(sprintf('Test duration is %f seconds\n',test_duration));

end
