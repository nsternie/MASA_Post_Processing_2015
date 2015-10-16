%% CorrectLoadCell.m
% Michigan Aeronautical Science Association

function [data] = CorrectLoadCell(test_start_index, test_end_index, real_start_index, real_end_index, data)

initial_value = mean(data(1:test_start_index-1));
final_value = mean(data(test_end_index+1:length(data)));
slope = (final_value-initial_value) / (test_end_index-test_start_index);
offsets = (initial_value + (1:real_end_index-real_start_index+1).*slope)';
test = data(real_start_index:real_end_index);
data = [data(1:real_start_index-1)-initial_value; test-offsets; data(real_end_index+1:length(data))-final_value];

end
