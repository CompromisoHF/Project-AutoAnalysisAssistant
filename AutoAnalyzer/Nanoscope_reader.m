%% This code was written by Xin He for lab use 
% E-mail : xh19@rice.edu
% Kiang's Group, Rice University , Jul. 2018
%--------------------------------------------------------------------------
%Subroutine that opens the raw nanoscope data file and extracts the needed values
%Need to export data from nanoscope analysis first. Please do it in ASCII
%and do not export the header.

function [T_rt,Z_rt,F_rt] = Nanoscope_reader(fname)

fid = fopen(fname,'r');
dat = textscan(fid,'%f %f %f %f %f','headerlines',1);
[T_rt,DEZ_rt,DEF_rt,ZS_rt,V_rt] = dat{:};


T_rt = T_rt - T_rt(1);
Z_rt = -ZS_rt;
F_rt = -DEF_rt;
fclose(fid);
