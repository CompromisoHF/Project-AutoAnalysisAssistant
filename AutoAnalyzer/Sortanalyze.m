%% This code was written by Xin He for lab use 
% E-mail : xh19@rice.edu
% Kiang's Group, Rice University , Jul. 2018
%--------------------------------------------------------------------------
% Need function 'Stepseeker.m','Startanalyze.m'and 'nanoscope_read.m' 
% Before using the code, please paste all the relative source code into the
% data folder.
%--------------------------------------------------------------------------
%% ------------------------------------------------------------------------
clear all
clc

global Badway
[Functype,Cuttype,CheckR,CheckChi,R_Threshold,MinTF,MaxTF,MinWidth,MinRes] = Startanalyze;
delete(Badway);

source_direc = uigetdir;
cd(source_direc);
%% Path and folder setting
%User input for the file and folder name
AnswerStr = inputdlg({'Name of the Cell:','Set the name of output folder(Folder name should not contain / or \ .Please do not use existent name).'},...
    'Setting');

CellName = strcat(AnswerStr{1},'*');
file_f = dir(CellName);
C = [];
file_num = length(file_f);
dir_out = fullfile(source_direc,strcat( AnswerStr{2}),filesep);
mkdir(dir_out);
mkdir(strcat(dir_out,'\Sorted\'));
mkdir(strcat(dir_out,'\Origin\'));
mkdir(strcat(dir_out,'\Fitted\'));
mkdir(strcat(dir_out,'\Transfered\'));
mkdir(strcat(dir_out,'\Molecular event\'));
mkdir(strcat(dir_out,'\Ends\'));
%Create the txt file for result recording 
fstep = fopen('Stepforce.txt','w+');

%% Determine the baseline fitting method 
%Users choose to do it manually or automaticly
IndexMOA = 0;
answer000 = questdlg('Select the method to choose baseline',...
                     'Step 1: Preliminary Fitting','Manual','Auto','');
switch answer000
    case 'Manual'
        IndexMOA = 1;
        UserSight = 'on';
    case 'Auto'
        IndexMOA = 2;
        UserSight = 'off';
end
%Creat the visible waiting bar
if IndexMOA == 2
    hwait=waitbar(0,'Please wait');
end

%% Analyze each choosen data file
for num = 1:file_num
    
try
    k = 1;
    %Show and change the waiting bar
    if IndexMOA == 2
       strw=['Processing Data...',' ( ' ,num2str(num) ,'/',...
                            num2str(file_num) ,') ','......'];
       waitbar(num/file_num,hwait,strw);
    end
    
    while k == 1    
      file_name = file_f(num).name;
      [T_rt,z_rt,F_rt] = Nanoscope_reader(file_name);

      %Selects baseline
      H0 = figure('Visible',UserSight);
      plot(z_rt,F_rt);
      set(gcf,'outerposition',get(0,'screensize'));
      
      if IndexMOA == 1
         plot(z_rt,F_rt);
         set(gcf,'outerposition',get(0,'screensize'));
         answer0 = questdlg([strcat('Data', ' ( ' ,num2str(num) ,'/',...
                            num2str(file_num) ,') ',' is ready to be normalized')],...
                            'Step 1: Preliminary Fitting','Go','Skip','');
      else
         %Automaticly choose the baseline by scan from the bottom
         Basesize = 1500.00;
         MaxNoise = 15.00;
         answer0 = 'Skip';
         [~,scansize] = min(abs(z_rt-(z_rt(length(z_rt))-Basesize)));
         for scannum = scansize:-1:1
             Noisewidth = 0;
             Bs_index = scannum;
             [~,Be_index] = min(abs(z_rt-(z_rt(scannum)+Basesize)));
             STDwidth = std(F_rt(Bs_index:Be_index));
             if STDwidth < MaxNoise
                 Noisewidth = min(20,max(F_rt(Bs_index:Be_index)) - mean(F_rt(Bs_index:Be_index)));
                 answer0 = 'Go';
                 break;
             end
          end
      end
      
      switch answer0
             case 'Skip'
             k = 0;
             case 'Go'
             %Manually choose the baseline    
             if IndexMOA == 1
                title_string = sprintf('Step 1A:Click on both sides of the chosen baseline, right side first');
                title(title_string,'fontsize', 14);
                [B_x,B_y]=ginput(2);
                %Fits and corrects baseline
                [~,Bs_index]=min(abs(z_rt-B_x(1)));
                [~,Be_index]=min(abs(z_rt-B_x(2)));
                Noisewidth = min(20,max(F_rt(Bs_index:Be_index)) - mean(F_rt(Bs_index:Be_index)));
             end
             %Use the choosen baseline to normalize the curve
             baseline_fit_rt = polyfit(z_rt(Bs_index:Be_index),F_rt(Bs_index:Be_index),1);
             baseline_rt = polyval(baseline_fit_rt,z_rt);
             F_rt = F_rt - baseline_rt;
             contact_index = find(F_rt > 0,1,'first');
             zero = z_rt(contact_index);
             z_rt = z_rt - zero; 
          
             %Waits for user to select or ignore normalized graph
             plot(z_rt, F_rt);
             answer = 'Next';
             
             if IndexMOA == 1
             answer = questdlg('Data has been normalized. go to next step or do it again?',...
                               'Step 1: Preliminary Fitting','Next','Try again','');    
             end
             
             switch answer
                    case 'Try again'
                    k = 1;
                    case 'Next' 
                    k = 0;
                    close all;
                    %Determine the cutpoint by finding the maximum
                    %[~,cutpoint] = max(F_rt);   
                    switch Cuttype
                        case 2
                           [~,cutpoint] = min(abs(z_rt-1000));
                        case 1
                           [~,cutpoint] = max(F_rt);
                        case 3
                           cutpoint = -1;
                    end
                    
                    Backupdata = [z_rt F_rt];
                    OData = [z_rt F_rt];
                    %Save the figure of the original curve
                    H1 = figure('Visible',UserSight);
                    plot(OData(:,1),OData(:,2));
                    title(strcat('Original Data_', file_name));
                    xlabel('Extension (nm)');
                    ylabel('Force (pN)');
                    saveas(H1,[pwd strcat('\',AnswerStr{2},'\Origin\','Original_',...
                        file_name, '.jpg')]);
                    saveas(H1,[pwd strcat('\',AnswerStr{2},'\Molecular event\','M_',...
                    file_name, '.fig')]);
                    close(H1);
                    %Cut the curve to get the anaylsable part
                    OData = []; 
                    if cutpoint ~= -1
                       z_rt(1:cutpoint)=[];
                       F_rt(1:cutpoint)=[];
                       z_rt(length(z_rt)+1)=z_rt(length(z_rt))+1;
                       F_rt(length(F_rt)+1)=-100;
                    end
                    OData = [z_rt F_rt];
                    SData = [z_rt,sort(F_rt,'descend')];
                    %Save the figure of sorted curve
                    H2 = figure('Visible',UserSight);
                    plot(SData(:,1),SData(:,2));
                    title(strcat('Sorted Data_', file_name));
                    xlabel('Extension (nm)');
                    ylabel('Force (pN)');
                    saveas(H2,[pwd strcat('\',AnswerStr{2},'\Sorted\','Sorted_',...
                        file_name, '.jpg')]);
                    close(H2);
                    
                    cd(source_direc);
                    %Record normalized data
                    A = [Backupdata(:,1) Backupdata(:,2)];
                    newname = strcat(dir_out,'\Origin\',file_name,'.dat');
                    fid = fopen(newname,'w+');
                    fprintf(fid,'%13.8f\t  %13.8f\n', A.');
                    fclose(fid);
                    %Record sorted data
                    B = [SData(:,1) SData(:,2)];
                    newname = strcat(dir_out,'\Sorted\Sorted Data_',file_name,'.dat');
                    fid = fopen(newname,'w+');
                    fprintf(fid,'%13.8f\t  %13.8f\n', B.');
                    fclose(fid);
                    
%                     %Fourier transfer 
%                     Fs = 1000;
%                     FF = fft(Backupdata(:,2));
%                     FF = fft(FF);
%                     L = ((Backupdata(length(Backupdata(:,1)),1)-2000)/3000)*1000;
%                     P2 = abs(FF/L);
%                     P1 = P2(1:L/2+1);
%                     P1(2:end-1) = 2*P1(2:end-1);
%                     f = Fs*(0:(L/2))/L;
%                     Hfourier = figure('Visible',UserSight);
%                     plot(f,P1);
%                     title('Single-Sided Amplitude Spectrum of F(t)');
%                     xlabel('f (Hz)');
%                     ylabel('|P1(f)|');
%                     saveas(Hfourier,[pwd strcat('/',AnswerStr{2},'/','Fourier_',...
%                         file_name, '.jpg')]); 
%                     close(Hfourier);
                     
                    %Use stepseeker to detech the force steps and locations
                    [NewC,Peaks] = Stepseeker(OData,SData,Noisewidth,AnswerStr{2},...
                        file_name,UserSight,Functype,CheckR,CheckChi,R_Threshold,MinTF,...
                        MaxTF,MinWidth,MinRes);
                    
                    RePeaks{num} = Peaks;
                    ReSteps{num} = NewC;
                    if ~isempty(NewC) 
                        C = cat(1,C,NewC);
                    end
                    %Mark each accepted steps on the curve and save 
                    H5 = figure('Visible',UserSight);
                    plot(Backupdata(:,1),Backupdata(:,2));
                    hold on;
                    title(strcat('Fitted Data_', file_name));
                    xlabel('Extension (nm)');
                    ylabel('Force (pN)');
                    scansize = length(Backupdata(:,1));
                    for index_CC = 1: length(Peaks)
                        PeaksY = [];
                        PeaksY(1:scansize) = Peaks(index_CC);
                        plot(Backupdata(:,1),PeaksY);
                        text(Backupdata(end,1),PeaksY(end),strcat('Stair',num2str(index_CC)),'FontSize',4);
                    end
                    saveas(H5,[pwd strcat('\',AnswerStr{2},'\Fitted\','Fitted_',...
                        file_name, '.jpg')]);
                    hold off;
                    close(H5);
                    Peaks = [];
                    NewC = [];
%                     %Output the accepted step forces

             end 
      end   
    end
catch
end
end
%Close the waitting bar
if IndexMOA == 2
   delete(hwait);
end

SMarker = zeros(length(C),1);
%% Maunal Review System
try
answerRe = questdlg('Start manual review?',...
                     'Review System','Yes','Skip','');
FinalSteps = [];
StepLen = [];
Steptime = [];
ReSteps{num+1} = [];
RePeaks{num+1} = [];
Cz = [];
Cf = [];
Count = 0;
index_S = 0;
index_L = 0;
switch answerRe
    case 'Yes'
       for num = 1:file_num
           try
           a = 0;
           if ~isempty(ReSteps{num}) 
              file_name = file_f(num).name;
              Backupdata = [];
              [Backupdata(:,1),Backupdata(:,2)] = ...
                  textread(strcat(dir_out,'\Origin\',file_name,'.dat'),'%f\t  %f\n');
              %Display curve and provide delete option
              HRe = figure('Visible','on');
              title('Select stages you don not want (form button to top)');
              imshow([pwd strcat('\',AnswerStr{2},'\Fitted\','Fitted_',...
                          file_name, '.jpg')]);
              for i = 1:length(RePeaks{num})         
                 UserChoice(i) = uicontrol(HRe,'Style','radiobutton','String',...
                        strcat('Stair',num2str(i)),...
                       'Position',[20+980*i/(length(RePeaks{num})+1),40,80,20]);

              end
              Btn = uicontrol('Style','pushbutton','String','Next',...
                  'Position',[500,0,40,20],'Callback','uiresume(gcbf)');
              uiwait(gcf);
              RemovePeak = [];
              m = 0;
              %Compare with previous result
              for i = 1:length(RePeaks{num}) 
                 DoNotWant = get(UserChoice(i),'Value'); 
                 if DoNotWant
                     m = m+1;
                     RemovePeak(m) = i;                 
                 end
              end 
              TempPeaks = RePeaks{num};
              TempPeaks(RemovePeak) = [];
              DelSteps = [];
              if ~isempty(TempPeaks)
                  DelSteps = abs(diff(TempPeaks));
              end
              AcSteps = intersect(DelSteps,ReSteps{num});
              if ~isempty(TempPeaks)
                for i=length(TempPeaks):-1:2
                    Tempans = abs(TempPeaks(i)-TempPeaks(i-1));
                    if  ismember(Tempans,AcSteps)
                        index_S = index_S+1;
                        SMarker(index_S) = i-1+index_L;                     
                    end
                end
                index_L = index_L+length(TempPeaks)-1;
              end
              
              FinalSteps = cat(1,FinalSteps,AcSteps);
              close(HRe);
              
              %Mark each accepted steps on the curve and save 
              H6 = figure('Visible','off');
              plot(Backupdata(:,1),Backupdata(:,2));
              hold on;
              title(strcat('Fitted Data_', file_name));
              xlabel('Extension (nm)');
              ylabel('Force (pN)');
              scansize = length(Backupdata(:,1));
              for index_CC = 1: length(TempPeaks)
                  PeaksY = [];
                  PeaksY(1:scansize) = TempPeaks(index_CC);
                  plot(Backupdata(:,1),PeaksY);
                  text(Backupdata(end,1),PeaksY(end),strcat('Stair',num2str(index_CC)),'FontSize',4);
              end
              saveas(H6,[pwd strcat('\',AnswerStr{2},'\Fitted\','Fitted_',...
                    file_name, '.jpg')]);
              hold off;
              close(H6);  
              Deldata = [];
              if isempty(TempPeaks) 
                  continue;
              end
              %% Delete steps in the curve
              [Bs_index,AddLen] = Steplength(Backupdata(:,1),Backupdata(:,2),TempPeaks,Noisewidth,file_name,dir_out);
              [~,AddTime] = Steplength(T_rt,Backupdata(:,2),TempPeaks,Noisewidth,file_name,dir_out);
              StepLen = cat(1,StepLen,AddLen');
              Steptime = cat(1,Steptime,AddTime');
              %% Combine all the step part
              Z = T_rt(Bs_index:end);
              F = Backupdata(Bs_index:end,2);
              Z = Z - Z(1);
              F = F - F(end);
              if length(Cz)<length(Z)
                   if  length(Cz) == 0
                     Cf=F;
                     Cz=Z;
                   else
                     Cf = Cf + F(1:length(Cf));
                     Cz = cat(1,Cz,Z(length(Cz)+1:end));
                     Cf = cat(1,Cf,F(length(Cf)+1:end));    
                   end
              else
                 Cf(1:length(F)) = Cf(1:length(F))+F;
              end
              Count = Count+1;
           end
           catch
           end
       end
       C = FinalSteps;
    case 'Skip'
        for num = 1:file_num
              try
              if ~isempty(ReSteps{num})
                file_name = file_f(num).name;
                Backupdata = [];
                [Backupdata(:,1),Backupdata(:,2)] = ...
                textread(strcat(dir_out,'\Origin\',file_name,'.dat'),'%f\t  %f\n');
                TempPeaks = RePeaks{num};
                [Bs_index,AddLen] = Steplength(Backupdata(:,1),Backupdata(:,2),TempPeaks,Noisewidth,file_name,dir_out);
                [~,AddTime] = Steplength(T_rt,Backupdata(:,2),TempPeaks,Noisewidth,file_name,dir_out);
                StepLen = cat(1,StepLen,AddLen');
                Steptime = cat(1,Steptime,AddTime');
                Z = T_rt(Bs_index:end);
                F = Backupdata(Bs_index:end,2);
                Z = Z - Z(1);
                F = F - F(end);
                if length(Cz)<length(Z)
                     if  length(Cz) == 0
                       Cf=F;
                       Cz=Z;
                     else
                       Cf = Cf + F(1:length(Cf));
                       Cz = cat(1,Cz,Z(length(Cz)+1:end));
                       Cf = cat(1,Cf,F(length(Cf)+1:end));    
                     end
                else
                   Cf(1:length(F)) = Cf(1:length(F))+F;
                end
                Count = Count+1;
            
              end
             catch
             end
        end
end

v=3;
%% Generate the histogram and do gaussion fitting
fprintf(fstep,'%13.8f\n', C);
flength = fopen('Steplength.txt','w+');
fprintf(flength,'%13.8f\n',StepLen);
fclose(flength);
flength = fopen('Steptime.txt','w+');
fprintf(flength,'%13.8f\n',Steptime);
fclose(flength);
fmarker = fopen('StepMarker.txt','w+');
fprintf(fmarker,'%13.8f\n',SMarker);
fclose(fmarker);
try
   H4 = figure('Visible',UserSight);
   histfit(C,[],'normal');
   title(strcat('Histogram'));
   xlabel('Tether Force (pN)');
   ylabel('Number');
   saveas(H4,[pwd strcat('\',AnswerStr{2},'\','Histogram_Stepforce.jpg')]);
   close(H4);
catch
   disp('Do not have enough data!');
end
try
   H4 = figure('Visible',UserSight);
   histfit(StepLen,[],'normal');
   title(strcat('Length Histogram'));
   xlabel('Steplength(nm)');
   ylabel('Number');
   saveas(H4,[pwd strcat('\',AnswerStr{2},'\','Histogram_Length.jpg')]);
   close(H4);
catch
   disp('Do not have enough data!');
end
try
   H4 = figure('Visible',UserSight);
   histfit(Steptime,[],'normal');
   title(strcat('Time Histogram'));
   xlabel('Steptime(s)');
   ylabel('Number');
   saveas(H4,[pwd strcat('\',AnswerStr{2},'\','Histogram_Time.jpg')]);
   close(H4);
catch
   disp('Do not have enough data!');
end
Cf = Cf/Count;
try
   H4 = figure('Visible',UserSight);
   plot(Cz,Cf);
   title(strcat('Combined Curve(Averaged)'));
   xlabel('Steptime(s)');
   ylabel('Force(pN)');
   saveas(H4,[pwd strcat('\',AnswerStr{2},'\','Combined.jpg')]);
   close(H4);
catch
   disp('Do not have enough data!');
end
save Cz
save Cf
%%
fclose(fstep);
movefile('Cz.mat',AnswerStr{2});
movefile('Cf.mat',AnswerStr{2});
movefile('Steptime.txt',AnswerStr{2});
movefile('Steplength.txt',AnswerStr{2});
movefile('Stepforce.txt',AnswerStr{2});
movefile('StepMarker.txt',AnswerStr{2});
close all;
%clear all;
catch
end

