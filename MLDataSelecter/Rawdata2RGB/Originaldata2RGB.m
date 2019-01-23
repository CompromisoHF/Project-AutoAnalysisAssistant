clear all
clc

source_direc = uigetdir;
cd(source_direc)

AnswerStr = inputdlg({'Name of the Cell:'},'Setting');
CellName = strcat(AnswerStr{1},'*');

file_f = dir(CellName);

file_num = length(file_f);
dir_out = fullfile(source_direc,'/RGB/',filesep);
mkdir(dir_out);
flist = fopen('neg_list.txt','w+');

%Iterate through each file
for num = 1:file_num
    
  
    file_name = file_f(num).name;
    resolution=5;
    [z_ex,z_rt,F_ex,F_rt,k] = nanoscope_read(file_name,resolution);

    % Flips the extension to be positive and converts to units to nm
    z_ex = -z_ex*1000; 
    z_rt = -z_rt*1000;
    % Flips the force data to be positive (units are pN)
    F_ex = -F_ex;
    F_rt = -F_rt;

    data = [z_rt F_rt];
    cd(source_direc);

    h = figure('visible','on');
    plot(data(:,1), data(:,2), 'r');
    title(strcat(file_name));
    xlabel('Extension (nm)');
    ylabel('Force (pN)');
    saveas(h,[pwd strcat('/RGB/', file_name, '.jpg')]);
    fprintf(flist,[file_name '.jpg' '\n']);
    close(h);
    
      
       
end   

answer1 = questdlg('All data in this folder has been transfered','Completed','Ok','');
close all
clear all
clc
