%% Subroutine that opens the raw nanoscope data file and extracts the needed values
function [z_ex,z_rt,F_ex,F_rt,k,D,dt_rt] = nanoscope_read(fname,resolution)

%% First checks the version of the nanoscope file

% Nanoscope version
version_line = get_line(fname,'\Version');
% Nanoscope version
fid = fopen(fname,'r');
fseek(fid,version_line,-1);
line = fgets(fid);
version = get_value(line,3);
if strcmp(version, '0x07200000') | strcmp(version, '0x08150200')
    sr_line_i = 1;
    z_sensor_string = '\@4:Z scale: V [Sens. ZPicoSens]';
else
    sr_line_i = 2;
    z_sensor_string = '\@4:Z scale: V [Sens. ZSensorSens]';
end
fclose(fid);

%% Calls the get_find subroutine to find the specified line in the nanoscope data file 

% Number of samples per line
samples_line = get_line(fname,'\Samps/line');
% Location of the data of interest
data_line = get_line(fname,'\Data offset');
% Number of data points
length_line = get_line(fname,'\Data length');
% Z scale factor (deflection)
z_scale_d_line = get_line(fname,'\@4:Z scale: V [Sens. Input2]');
% Z scale factor (Z sensor)
z_scale_z_line = get_line(fname,z_sensor_string);
% Spring constant
k_line = get_line(fname,'\Spring Constant');
% Deflection Sensitivity (nm/V)
D_line = get_line(fname,'\@Sens. DeflSens');
% Forward pulling velocity
forward_v_line = get_line(fname,'\Forward vel.');
% Reverse pulling velocity
reverse_v_line = get_line(fname,'\Reverse vel.');
% Z sensor sensitivity
z_sensor_line = get_line(fname,'\@Sens. Zsens');
% Ramp size
ramp_size_line = get_line(fname,'\@4:Ramp size: V [Sens. Zsens]');
% Scan rate
scan_rate_line = get_line(fname,'\Scan rate');

%% Opens the nanoscope file, goes to the given line, and reads the above values

% Number of samples per line
fid = fopen(fname,'r');
fseek(fid,samples_line(2),-1);
line = fgets(fid);
samples = get_value(line,1);
% Location of the data of interest
fseek(fid,data_line(1),-1);
line = fgets(fid);
data = get_value(line);
% Number of data points
fseek(fid,length_line(2),-1);
line = fgets(fid);
length = get_value(line);
% Z scale factor (deflection)
fseek(fid,z_scale_d_line(1),-1);
line = fgets(fid);
z_scale_d = get_value(line);
% Z scale factor (deflection)
fseek(fid,z_scale_z_line(1),-1);
line = fgets(fid);
z_scale_z = get_value(line);
% Spring constant
fseek(fid,k_line(1),-1);
line = fgets(fid);
k = get_value(line)*1000;
% Deflection Sensitivity (nm/V)
fseek(fid,D_line,-1);
line = fgets(fid);
D = get_value(line);
% Z sensor sensitivity
fseek(fid,z_sensor_line(1),-1);
line = fgets(fid);
z_sensor = get_value(line);
% Forward pulling velocity
fseek(fid,forward_v_line,-1);
line = fgets(fid);
forward_v = get_value(line)*z_sensor;
% Reverse pulling velocity
fseek(fid,reverse_v_line,-1);
line = fgets(fid);
reverse_v = get_value(line)*z_sensor;
% Ramp size
fseek(fid,ramp_size_line(1),-1);
line = fgets(fid);
ramp_size = get_value(line,2)*z_sensor;
% Scan rate
fseek(fid,scan_rate_line(sr_line_i),-1);
line = fgets(fid);
scan_rate = get_value(line);

%% Extracts the extend and retract curves from the binary data file

% Calculates the number of points that will be averaged to give data with the user defined resolution 
av_pnts = round(resolution/(ramp_size/samples(1)));

% Goes to the location of the data in the file
fseek(fid,data,-1);
% Extracts the data and scales it porperly
dat = fread(fid,[length/2 2] ,'int16');
% Separates the extend and retract curves
z_ex = dat(1:samples(2),2)*z_scale_z;
F_ex = dat(1:samples(2),1)*D*k*z_scale_d;
z_rt = dat(length/4+1:length/2,2)*z_scale_z;
F_rt = dat(length/4+1:length/2,1)*D*k*z_scale_d;
% Finds the constant time step at which the data was collected
dt_rt = forward_v/(scan_rate*samples(1)*(forward_v+reverse_v));
fclose(fid);

% Averages data with a higher resolution than the user defiend resolution
z_ex_temp = zeros(size(z_ex(1:av_pnts:end),1)-1,1);
F_ex_temp = zeros(size(z_ex(1:av_pnts:end),1)-1,1);
z_rt_temp = zeros(size(z_rt(1:av_pnts:end),1)-1,1);
F_rt_temp = zeros(size(z_rt(1:av_pnts:end),1)-1,1);
if av_pnts > 1
    start = 1;
    for count = 1:size(z_ex(1:av_pnts:end),1)-1
        z_ex_temp(count) = mean(z_ex(start:start+av_pnts-1));
        F_ex_temp(count) = mean(F_ex(start:start+av_pnts-1));
        start = start+av_pnts;
    end
    start = 1;
    for count = 1:size(z_rt(1:av_pnts:end),1)-1
        z_rt_temp(count) = mean(z_rt(start:start+av_pnts-1));
        F_rt_temp(count) = mean(F_rt(start:start+av_pnts-1));
        start = start+av_pnts;
    end
    z_ex = z_ex_temp;
    F_ex = F_ex_temp;
    z_rt = z_rt_temp;
    F_rt = F_rt_temp;
    dt_rt = dt_rt*av_pnts;
end

%% Subfunction that goes into a nanoscope data file and finds the line number associated with the input header
function line_num = get_line(fname,header_string)

fid = fopen(fname,'r');

header_end=0;
eof = 0;
counter = 1;
byte_location = 0;

while and(~eof,~header_end) 
   byte_location = ftell(fid);
   line = fgets(fid); 
   if line == -1
      eof = 1;
      break
   end  
   if length(findstr(line,header_string))
      line_num(counter) = byte_location;
      counter = counter + 1;
   end   
   if length(findstr(line,'\*File list end'))
      header_end = 1;
   end
end

fclose(fid);

%% Subfunction that goes into a nanoscope data file and gets the value for a specified line
function value = get_value(line,opt)

%Ascii table of relevant numbers
%character    ascii code
%    e            101
%    E            69
%    0            48
%    1            49
%    2            50
%    3            51 
%    4            52
%    5            53
%    6            54 
%    7            55 
%    8            56
%    9            57

% Sets default for the optional input intervals
if nargin < 2
    opt = [];
end

eos = 0;
R = line;

if opt == 2
    count = 0;
else
    count = 1;
end

while ~eos
    [T,R] = strtok(line);
    if isempty(R) == 1
        eos = 1;
    end
    I = find( (T>=48) & (T<=57) | 101==T | 69==T | T==173 | T== 45 | T==46 | T==40 | T==120);
    LT = length(T);
    LI = length(I);
    if LI == LT
        count = count + 1;
        if count == 2
            J = find(T~='(');
            if opt == 3
                value = T;
            else
                value = str2double(T(J));
            end
            if opt == 1
                value(2) = str2double(R);
            end
            break
        end
    end
    line = R;
end