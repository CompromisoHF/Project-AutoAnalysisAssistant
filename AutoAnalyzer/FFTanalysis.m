clear all
clc

source_direc = uigetdir;
cd(source_direc);

AnswerStr = inputdlg({'Name of the Cell:','Set the name of output folder(Folder name should not contain / or \ .Please do not use existent name).'},...
    'Setting');

CellName = strcat(AnswerStr{1},'*');
file_f = dir(CellName);
C = [];
file_num = length(file_f);
dir_out = fullfile(source_direc,strcat( AnswerStr{2}),filesep);
mkdir(dir_out);

for num = 1:file_num
      
    file_name = file_f(num).name;
    [T_rt,z_rt,F_rt] = Nanoscope_reader(file_name);
    
    N = length(F_rt);
    Timescale = T_rt(end)-T_tr(1);
    Sampling_rate = N/Timescale;
    
    [Fre,Amp] = frequencySpectrum(F_rt,Sampling_rate);
    
    H = figure;
    hold on;
    
    subplot(2,2,1)
    plot(Fre,Amp);
    set(gcf,'color','w');
    title('amp');

    subplot(2,2,2)
    [Fre,Amp] = frequencySpectrum(waveData,Fs,'scale','ampdb');
    plot(Fre,Amp);
    set(gcf,'color','w');
    title('ampDB');
    
    subplot(2,2,3)
    [Fre,Amp] = frequencySpectrum(waveData,Fs,'scale','mag');
    plot(Fre,Amp);
    set(gcf,'color','w');
    title('mag');
 
    subplot(2,2,4)
    [Fre,Amp] = frequencySpectrum(waveData,Fs,'scale','magdb');
    plot(Fre,Amp);
    set(gcf,'color','w');
    title('magDB');
    
    hold off;
    
    saveas(H,[pwd strcat('\',AnswerStr{2},'\','FFT_',filename,'.tif')]);
    close(H);
    
end

close all