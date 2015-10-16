%% ServoShift.m
% Michigan Aeronautical Science Association

function [servo_time, servo_signal] = ServoShiftFilter(TIME, raw_servo_signal, servo_lag_time, time_step)

index_offset = servo_lag_time / time_step;

i = 1:length(TIME);
j = index_offset:length(TIME);
j = [j, ones(1,length(i)-length(j))*length(TIME)];

servo_time(i) = TIME(j);
servo_signal(i) = raw_servo_signal(j);

window_size = 50;
window = 1/window_size*ones(1,window_size);
servo_signal = filter(window,1,servo_signal);

end
