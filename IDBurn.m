%% IDburn.m
% Michigan Aeronautical Science Association

function [burn_start_index, burn_end_index] = IDburn(test_start_index, test_end_index, real_start_index, real_end_index, average_thrust, data, time_step)

burn_start_index = real_start_index;
burn_end_index = real_end_index;

% Find the start of the burn
pre_test_average = mean(data(test_start_index:real_start_index));
pre_test_stddev = std(data(test_start_index:real_start_index));
while abs(data(burn_start_index)) > abs(pre_test_average+pre_test_stddev/10)
    burn_start_index = burn_start_index-1;
end
%burn_start_index = burn_start_index-0.25/time_step;
% Find the end of the burn (50% of average thrust)
while data(burn_end_index) < average_thrust/2
    burn_end_index = burn_end_index-1;
end

end
