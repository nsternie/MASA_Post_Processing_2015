%% PostProcessScript.m
% Michigan Aeronautical Science Association
% Script to post-process a batch of hot fire data

clear
close all


%% Inputs

filename = 'CF_10112015_1743.csv';

force_in_newtons = 1;       % set this to 1 if you want the thrust data in Newtons
pressure_in_pascals = 0;    % set this to 1 if you want the pressure data in Pascals
use_absolute_pressure = 0;  % use absolute pressures (add atmospheric pressure to pressure values)
time_step = 0.001;          % this is the period between each DAQ sampling (in seconds)
expected_test_duration = 1; % this is how long we expect the test to last (in seconds)
left_test_buffer = 5;       % this is the buffer on the left that is added to the test (in seconds)
right_test_buffer = 15;     % this is the buffer on the right that is added to the test (in seconds)
servo_lag_time = 1.35;      % this is the lag time in the servo signal to the DAQ due to the filter (in seconds)

% Note that an additional input is in the import data section for channels.
% Consider using that if channels change or remain unused

%% Calibration data

% Load Cell - form: F = a*V + b [V to lbf]
load_cell.a = 75.239;
load_cell.b = 546.41;
% Pressure Transducers - form: p = a*V (linear, 0-5V to 0-2000psi)
pressure_transducer.a = 2000/5;
% Thermistors - form (Steinhart-Hart Equation): 
%       T[K] = 1/(a+b*ln(R[ohm])+c*ln(R[ohm])^3)
% These were calibrated in March 2015, in the MXL thermal chamber
%%%%%% Note to Abhi - voltage is not the same as resistance
tank_top_thermistor.a = 1.58e-3;
tank_top_thermistor.b = 2.20e-4;
tank_top_thermistor.c = 1.90e-7;
tank_bottom_thermistor.a = 1.57e-3;
tank_bottom_thermistor.b = 2.2e-4;
tank_bottom_thermistor.c = 1.9e-7;

% Conversion data
lbf_to_N = 4.44822162;          % 1 lbf in N
add_atm_pressure_psi = 14.696;  % 1 atm in psi
psi_to_Pa = 6894.75729;         % 1 psi in Pa
K_to_degC = 273.15;             % add to any K value to convert to deg C


%% Import data

[TIME,CH0,CH1,CH2,CH3,CH4,CH5,CH6,CH7] = importfile(filename);

% Save channel numbers as actual data variables (edit this if channels
% change)
raw_force_thrust = CH0;
raw_tank_top_pressure = CH1;
raw_tank_top_temperature = CH2;
raw_tank_bottom_pressure = CH3;
raw_tank_bottom_temperature = CH4;
raw_combustion_chamber_pressure = CH5;
raw_servo_signal = CH4;
use_force_thrust = 1;
use_tank_top_pressure = 1;
use_tank_top_temperature = 1;
use_tank_bottom_pressure = 1;
use_tank_bottom_temperature = 0;
use_combustion_chamber_pressure = 1;
use_servo_signal = 1;


%% Create conversion functions

% Load Cell
load_cell_conv = @(x) load_cell.a*x + load_cell.b;
% Pressure Transducers
pressure_transducer_conv = @(x) pressure_transducer.a*x;
% Top Tank Thermistor
tank_top_thermistor_conv = @(R) 1/(tank_top_thermistor.a+...
    tank_top_thermistor.b*log(R)+tank_top_thermistor.c*log(R).^3);
% Bottom Tank Thermistor
tank_bottom_thermistor_conv = @(R) 1/(tank_bottom_thermistor.a+...
    tank_bottom_thermistor.b*log(R)+tank_bottom_thermistor.c*log(R).^3);

%% Housekeeping for unit options
force_caption = 'lbf';
pressure_caption = 'psi';
if force_in_newtons==1
    force_caption = 'N';
end
if pressure_in_pascals==1
    pressure_caption = 'Pa';
end

%% Convert data and plot

% Identify start and end times of test
[test_duration, test_start_index, test_end_index, real_start_index, real_end_index] =...
    IDtest(TIME, time_step, expected_test_duration, left_test_buffer, right_test_buffer, CH0);
test_time = TIME(test_start_index:test_end_index);

figure(1)
% LOAD CELL
% Get data
force_thrust = load_cell_conv(raw_force_thrust);
% Housekeeping (lbf v N option)
if force_in_newtons==1
    force_thrust = force_thrust*lbf_to_N;
end
% Remove the initial offset from the load cell
force_thrust = force_thrust - mean(force_thrust(1:test_start_index));
% Remove any initial offset slope from the load cell
load_cell_initial_offset = fit(TIME(1:test_start_index),force_thrust(1:test_start_index),'poly1');
force_thrust = force_thrust - load_cell_initial_offset(force_thrust);
% Correct for the offset before and after the test
[force_thrust] = CorrectLoadCell(test_start_index,test_end_index,real_start_index,real_end_index,force_thrust);
full_force_thrust = force_thrust;
% Find the thrust from the actual test time
[actual_force_thrust] = DataToTestTime(real_start_index,real_end_index,force_thrust);
average_thrust = mean(actual_force_thrust)-mean(force_thrust);
maximum_thrust = max(actual_force_thrust)-mean(force_thrust);
fprintf(sprintf('Average thrust force is %f %s\n',average_thrust,force_caption));
fprintf(sprintf('Maximum thrust force is %f %s\n',maximum_thrust,force_caption));
if use_force_thrust == 1
    % Plot the load cell data for the full test
    subplot(3,1,1)
    plot(TIME, force_thrust)
    title('Thrust Force over Time (full data acquisition)');
    xlabel('Time (s)');
    ylabel(sprintf('Thrust force (%s)',force_caption));
    % Plot the thrust over the full test duration (with a couple seconds on
    % each side)
    subplot(3,1,2)
    [force_thrust] = DataToTestTime(test_start_index,test_end_index,force_thrust);
    plot(test_time, force_thrust)
    title('Thrust Force over Time (test duration)');
    xlabel('Time (s)');
    ylabel(sprintf('Thrust force (%s)',force_caption));
    % Plot the thrust over the actual burn
    [burn_start_index, burn_end_index] = IDburn(test_start_index, test_end_index, real_start_index, real_end_index, average_thrust, full_force_thrust, time_step);
    [burn_force_thrust] = DataToTestTime(burn_start_index,burn_end_index,full_force_thrust);
    subplot(3,1,3)
    plot(TIME(burn_start_index:burn_end_index), burn_force_thrust)
    title('Thrust Force over Time (burn duration)');
    xlabel('Time (s)');
    ylabel(sprintf('Thrust force (%s)',force_caption));
end
% Output the burn times
fprintf(sprintf('Burn begins at %f seconds\n',TIME(burn_start_index)));
fprintf(sprintf('Burn ends at %f seconds\n',TIME(burn_end_index)));
fprintf(sprintf('Burn duration is %f seconds\n',TIME(burn_end_index)-TIME(burn_start_index)));
% Calculate and output the total impulse
total_impulse = trapz(TIME(burn_start_index:burn_end_index),burn_force_thrust);
fprintf(sprintf('Total impulse is %f %s.s\n',total_impulse,force_caption));

figure(2)
% TANK TOP PRESSURE
tank_top_pressure = pressure_transducer_conv(raw_tank_top_pressure);
if use_absolute_pressure==1
    tank_top_pressure = tank_top_pressure + add_atm_pressure_psi;
end
if pressure_in_pascals==1
    tank_top_pressure = tank_top_pressure*psi_to_Pa;
end
if use_tank_top_pressure == 1
    subplot(3,2,1)
    plot(TIME, tank_top_pressure);
    title('Nitrous Tank Top Pressure over Time (full data acquisition)');
    xlabel('Time (s)');
    ylabel(sprintf('Pressure (%s)',pressure_caption));
    subplot(3,2,2)
    [tank_top_pressure] = DataToTestTime(test_start_index,test_end_index,tank_top_pressure);
    plot(test_time, tank_top_pressure);
    title('Nitrous Tank Top Pressure over Time (test duration)');
    xlabel('Time (s)');
    ylabel(sprintf('Pressure (%s)',pressure_caption));
end
% TANK BOTTOM PRESSURE
tank_bottom_pressure = pressure_transducer_conv(raw_tank_bottom_pressure);
if use_absolute_pressure==1
    tank_bottom_pressure = tank_bottom_pressure + add_atm_pressure_psi;
end
if pressure_in_pascals==1
    tank_bottom_pressure = tank_bottom_pressure*psi_to_Pa;
end
if use_tank_bottom_pressure == 1
    subplot(3,2,3)
    plot(TIME, tank_bottom_pressure);
    title('Nitrous Tank Bottom Pressure over Time (full data acquisition)');
    xlabel('Time (s)');
    ylabel(sprintf('Pressure (%s)',pressure_caption));
    subplot(3,2,4)
    [tank_bottom_pressure] = DataToTestTime(test_start_index,test_end_index,tank_bottom_pressure);
    plot(test_time, tank_bottom_pressure);
    title('Nitrous Tank Bottom Pressure over Time (test duration)');
    xlabel('Time (s)');
    ylabel(sprintf('Pressure (%s)',pressure_caption));
end
% COMBUSTION CHAMBER PRESSURE
combustion_chamber_pressure = pressure_transducer_conv(raw_combustion_chamber_pressure);
if use_absolute_pressure==1
    combustion_chamber_pressure = combustion_chamber_pressure + add_atm_pressure_psi;
end
if pressure_in_pascals==1
    combustion_chamber_pressure = combustion_chamber_pressure*psi_to_Pa;
end
subplot(3,2,5)
if use_combustion_chamber_pressure == 1
    plot(TIME, combustion_chamber_pressure);
    title('Combustion Chamber Pressure over Time (full data acquisition)');
    xlabel('Time (s)');
    ylabel(sprintf('Pressure (%s)',pressure_caption));
    subplot(3,2,6)
    [combustion_chamber_pressure] = DataToTestTime(test_start_index,test_end_index,combustion_chamber_pressure);
    plot(test_time, combustion_chamber_pressure);
    title('Combustion Chamber Pressure over Time (test duration)');
    xlabel('Time (s)');
    ylabel(sprintf('Pressure (%s)',pressure_caption));
end

figure(3)
% TANK TOP TEMPERATURE
tank_top_temperature = tank_top_thermistor_conv(raw_tank_top_temperature) + K_to_degC;
if use_tank_top_temperature == 1
    subplot(2,2,1)
    plot(TIME, tank_top_temperature);
    title('Nitrous Tank Top Temperature over Time (full data acquisition)');
    xlabel('Time (s)');
    ylabel('Temperature (deg C)');
    subplot(2,2,2)
    [tank_top_temperature] = DataToTestTime(test_start_index,test_end_index,tank_top_temperature);
    plot(test_time, tank_top_temperature);
    title('Nitrous Tank Top Temperature over Time (test duration)');
    xlabel('Time (s)');
    ylabel('Temperature (deg C)');
end
% TANK BOTTOM TEMPERATURE
tank_bottom_temperature = tank_bottom_thermistor_conv(raw_tank_bottom_temperature) + K_to_degC;
if use_tank_bottom_temperature == 1
    subplot(2,2,3)
    plot(TIME, tank_bottom_temperature);
    title('Nitrous Tank Bottom Temperature over Time (full data acquisition)');
    xlabel('Time (s)');
    ylabel('Temperature (deg C)');
    subplot(2,2,4)
    [tank_bottom_temperature] = DataToTestTime(test_start_index,test_end_index,tank_bottom_temperature);
    plot(test_time, tank_bottom_temperature);
    title('Nitrous Tank Bottom Temperature over Time (test duration)');
    xlabel('Time (s)');
    ylabel('Temperature (deg C)');
end

figure(4)
% PRESSURE DROP ACROSS INJECTOR
pressure_drop = tank_bottom_pressure-combustion_chamber_pressure;
subplot(2,1,1)
plot(test_time, pressure_drop);
title('Pressure Drop over Injector over Time (test duration)');
xlabel('Time (s)');
ylabel(sprintf('Pressure Difference (%s)',pressure_caption));
subplot(2,1,2)
pressure_drop = pressure_drop./tank_bottom_pressure.*100;
plot(test_time, pressure_drop);
title('Pressure Drop over Injector over Time (test duration)');
xlabel('Time (s)');
ylabel('Percentage of Nitrous Tank Pressure (%)');

figure(5)
% SIGNAL SENT BY ARDUINO TO SERVO
[servo_time, servo_signal] = ServoShiftFilter(TIME, raw_servo_signal, servo_lag_time, time_step);
if use_servo_signal == 1
    subplot(2,1,1);
    plot(servo_time, servo_signal);
    title('Signal sent by Arduino to Servo Over Time (full data acquisition)');
    xlabel('Time (s)');
    ylabel('Signal (V)');
    subplot(2,1,2)
    [servo_signal] = DataToTestTime(test_start_index,test_end_index,servo_signal);
    plot(test_time, servo_signal);
    title('Signal sent by Arduino to Servo Over Time (test duration)');
    xlabel('Time (s)');
    ylabel('Signal (V)');    
end

