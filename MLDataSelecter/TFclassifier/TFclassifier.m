clear all
clc

source_dir = uigetdir;
cd(source_dir)

AnswerStr = inputdlg({'Name of the Cell:'},'Setting');
CellName = strcat(AnswerStr{1},'*');

file_f = dir(CellName);
file_num = length(file_f);

dir_posout = fullfile(source_dir,'\Positive\',filesep);
dir_negout = fullfile(source_dir,'\Negative\',filesep);
dir_PTout = fullfile(source_dir,'\PTdata\',filesep);
mkdir(dir_posout);
mkdir(dir_negout);
mkdir(dir_PTout);

hhwait=waitbar(0,'Please wait');
load svmModel
load cutpos

Counterpos = 0;
Counterneg = 0;

for num = 1:file_num
    
    hogt = []; 
    file_name = file_f(num).name;
    resolution=5;
    [z_ex,z_rt,F_ex,F_rt,k] = nanoscope_read(file_name,resolution);

    % Flips the extension to be positive and converts to units to nm
    z_ex = -z_ex*1000; 
    z_rt = -z_rt*1000;
    % Flips the force data to be positive (units are pN)
    F_ex = -F_ex;
    F_rt = -F_rt;

    dataa = [z_rt F_rt];
    cd(source_dir);

    h = figure('visible','off');
    plot(dataa(:,1), dataa(:,2), 'r');
    title(strcat(file_name));
    xlabel('Extension (nm)');
    ylabel('Force (pN)');
    saveas(h,[source_dir strcat('\','RGB_',file_name,'.jpg')]);
    close(h);
    
    Indextest = 0;
    imfile_name = strcat('RGB_',file_name, '.jpg');
    test = imread(imfile_name);    
    testCp = imcrop( test, cutpos );
    imm=imresize(testCp,[64,128]); 
    imgg=rgb2gray(imm);  
    hogt = hogcalculator(imgg);
    
    hhh = figure('visible','off');
    imshow(imgg);
    saveas(hhh,strcat(dir_PTout,imfile_name));
    close(hhh);
    
    [Indextest,score]= predict(svmModel,hogt);
    
    
    if (Indextest > 0.00)
        copyfile(file_name,dir_posout); 
        copyfile(imfile_name,dir_posout); 
        delete(imfile_name);
        Counterpos = Counterpos +1 ;
    else
        copyfile(file_name,dir_negout); 
        copyfile(imfile_name,dir_negout); 
        delete(imfile_name);
        Counterneg = Counterneg + 1 ;
    end        
    
    strww=['Checking...',num2str(num/file_num*100),'%'];
    waitbar(num/file_num,hhwait,strww);
    
    
end   

delete(hhwait);

disp(['Counterpos = ',num2str(Counterpos)]);
disp(['Counterneg = ',num2str(Counterneg)]);
disp(['Pickrate = ',num2str(Counterpos/(Counterpos+Counterneg)*100),'%']);
answer1 = questdlg('All data in this folder has been checked','Completed','Ok','');

close all

