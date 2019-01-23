%% This function was written by Xin He for lab use 
% E-mail : xh19@rice.edu
% Kiang's Group, Rice University , Aug. 2018
%--------------------------------------------------------------------------
% Input agreements
% Origindata: Original force curve data read by function 'nanocope_read'
% Sorteddata: Cutted and sorted data from the orginal one
% rulerwidth: The width of the scaner, recommend double type
% Outputfolder: Path of the output, should be string type
% filename: Name of current operated file, should be string type
% User_sight: Determine if the figures are visible, should be 'on' or 'off'
%--------------------------------------------------------------------------
% Output agreements
% Steps: a list of all the force steps detected 
% locs: a list of the loction of each step
%--------------------------------------------------------------------------
% This function uses a new way to automaticly detect force steps. However,
% since it's totally automatic, error can't be avoid. Thus manually review
% is necessary, please do not skip the review part provided in the end of
% the function.
% The algrithm is parameter senstive, please determine all the parameters
% carefully depending on different situations.
%--------------------------------------------------------------------------
%% ------------------------------------------------------------------------
function [Steps,locs] = Stepseeker(Origindata,Sorteddata,rulerwidth,...
    Outputfolder,filename,User_Sight,Functype,CheckR,CheckChi,R_threshold,...
    Minstepforce,Maxstepforce,Minstepwid,MinRes)
    
%% Scan the sorted force curve to transfer the curve
    %Initialize parameters
    Xseeker = Sorteddata(:,1);
    datalen = length(Xseeker);
    Seekupper = max(Sorteddata(:,2)) - (rulerwidth/2);
    Seeklower = min(Sorteddata(:,2)) + (rulerwidth/2);
    Seekstep = max([MinRes,min(abs(diff(Sorteddata(:,2))))]);
    Trashpeak = 6000;   
    Numstep = ceil((Seekupper-Seeklower)/Seekstep);
    rulercenter = Seekupper;
    stepwid = [];
    switch Functype
        case 3
            FitFunc = 'fourier8';
        case 2
            FitFunc = 'sin8';
        case 1
            FitFunc = 'gauss8';
        case 4
            FitFunc = 'spline';
    end
    %Scan the curve by moving the ruler from the top of the figure
    for index1 = 1:Numstep
        
        Xindex = 0;
        rightend = 0;
        leftend = 0;
        stepwid(index1,1) = 0;
        stepwid(index1,2) = rulercenter;
        rulerupper = rulercenter + (rulerwidth/2);
        rulerlower = rulercenter - (rulerwidth/2);
        %Detect the longest continuous curve inside the ruler
        for index2 = 1:datalen
            
            if ( (Sorteddata(index2,2)<=rulerupper)&&...
                    (Sorteddata(index2,2)>rulerlower) )
                switch Xindex
                    case 1
                    rightend = Xseeker(index2);
                    case 0
                    rightend = Xseeker(index2);
                    leftend = Xseeker(index2);
                    Xindex = 1;
                end
            else
                Xindex = 0;
                if (rightend - leftend ~= 0)
                    stepwid(index1,1) = max([stepwid(index1,1),...
                        rightend - leftend]);
                end
            end              
            
        end
        
        rulercenter = rulercenter - Seekstep;
        
    end
    
    %Reverse the transfered curve for gaussion fitting
    Wids = stepwid(end:-1:1,1);
    Mids = stepwid(end:-1:1,2);
    %Save the transfered and fitted figure 
    H3 = figure('Visible',User_Sight);
    gfit = fit(Mids,Wids,FitFunc);
    plot(gfit,Mids,Wids);
    ylabel('Number');
    xlabel('Force (pN)');
    saveas(H3,[pwd strcat('/',Outputfolder,'/Transfered/','Transfered_', filename,...
        '.jpg')]);
    close(H3);
    
    %Fourier transfer 
%     Wids = gfit(Mids);
%     Fs = 1000;
%     FF = ifft(Wids);
%     FF = fft(FF);
%     L = (Mids(end)/3000)*1000;
%     P2 = abs(FF/L);
% %    P1 = P2(1:L/2+1);
%     P1 = P2;
%     P1(2:end-1) = 2*P1(2:end-1);
% %    f = Fs*(0:(L/2))/L;
%     f = (0:L/length(Mids):L);
%     f(1)=[];
%     
%     Hfourier0 = figure('Visible','off');
%     plot(f,P1);
%     title('Single-Sided Amplitude Spectrum of F(t)');
%     xlabel('f (Hz)');
%     ylabel('|P1(f)|');
%     saveas(Hfourier0,[pwd strcat('/',Outputfolder,'/','Fourier_',...
%            filename, '.jpg')]); 
%     close(Hfourier0);
    
    

%% Record the fitting curve and analyze for the peaks    
    %Find the peaks of the fitting curve
    Wids = [];
    Wids = gfit(Mids);
    OWid = stepwid(end:-1:1,1);
    [widpeaks,locs] = findpeaks(Wids,Mids);
    %Set a boundary of the array
    lennnn = length(locs);
    locs(lennnn+1) = Trashpeak;
    widpeaks(lennnn+1) = 51;
    %Eliminate the fitting peaks which are too small to analyze  
    Notapeak = [];m=1;
    Notapeak = find(50 > widpeaks);
    widpeaks(Notapeak) = widpeaks(Notapeak+1);
    locs(Notapeak) = locs(Notapeak+1);

%% Fitting Goodness Check /Chi2gof
    if CheckChi
       Notapeak = [];m=1;
%      disp(filename);
       for index1 = 1:length(locs)
           [~,start_index]=min(abs(Mids-locs(index1)+3*rulerwidth/4));
           [~,end_index]=min(abs(Mids-locs(index1)-3*rulerwidth/4));
           CheckMids =  [];
           CheckWids =  [];        
           CheckMids =  Mids(start_index:end_index);
           CheckWids =  OWid(start_index:end_index);    
           [Checkh,Checkp] = chi2gof(CheckWids,'alpha',0.001);
%         disp(locs(index1));
%         disp(CheckMids(1));
%         disp(widpeaks(index1));
%         disp(Checkp);
           if Checkh
              Notapeak(m) = index1;
              m = m+1;
           end
       end
       locs(Notapeak) = Trashpeak;
    end
%--------------------------------------------------------------------------
%% Fitting Goodness Check /R-square
    if CheckR
       Notapeak = [];m=1;
       %Fit each peak again for the R-square of the fitting
       for index1 = 1:length(locs)
           [~,start_index]=min(abs(Mids-locs(index1)+rulerwidth/2));
           [~,end_index]=min(abs(Mids-locs(index1)-rulerwidth/2));
           CheckMids =  [];
           CheckWids =  [];        
           CheckMids =  Mids(start_index:end_index);
           CheckWids =  OWid(start_index:end_index); 
           if length(CheckMids)>3 
               %This step may cause crash because of the fitting process
               %Thus 'try' and 'catch' have been used here
               try
                  [SGfit,gof] = fit(CheckMids,CheckWids,'gauss1');
               catch
                  gof.rsquare = 0; 
               end
               if gof.rsquare < R_threshold
                  Notapeak(m) = index1;
                  m = m+1;
               end
           end
       end
    %Mark all the peaks with bad fitting goodness as trash peaks
       locs(Notapeak) = Trashpeak;
    end
%% Remove peaks lower than the Minstepwidth     
    Notapeak = [];m=1;
    Notapeak = find(50 <widpeaks & widpeaks<Minstepwid);
    locs(Notapeak) = Trashpeak;
    
% %% Compare with the original Curve for double check
%     Notapeak = [];m=1;
% %    Scan the original curve with the determined location 
%     for index1 = 1:length(locs)        
%         rulercenter = locs(index1);
%         Xindex = 0;
%         rightend = 0;
%         leftend = 0;
%         Widthchecker = 0;
%         rulerupper = rulercenter + 15;
%         rulerlower = rulercenter - 15;
%   %      Check if the curve fluctuates too much 
%         for index2 = 1:datalen            
%             if ( (Origindata(index2,2)<=rulerupper)&&...
%                     (Origindata(index2,2)>rulerlower) )
%                 switch Xindex
%                     case 1
%                     rightend = Xseeker(index2);
%                     case 0
%                     rightend = Xseeker(index2);
%                     leftend = Xseeker(index2);
%                     Xindex = 1;
%                 end
%             else
%                 Xindex = 0;
%                 if (rightend - leftend ~= 0)
%                     Widthchecker = max([Widthchecker,rightend - leftend]);
%                 end
%             end              
%             
%         end
%    %     If not stable enough, eliminate this peak
%         if Widthchecker < 100
%            Notapeak(m) = index1;
%            m = m+1;
%         end
%                
%     end
%     locs(Notapeak) = Trashpeak;
    
%% Eliminate the abnormal steps and the relative peaks
    %Set markers on each peaks
    index_del(1:length(locs)) = 2;
    index_del(1) = 1;
    index_del(length(locs)) = 1;
    %Calculate the steps and find the abnormal steps    
    Steps = abs(diff(locs));
    Notastep = find(Steps<Minstepforce | Steps>Maxstepforce);
    Steps(Notastep) = [];
    %Remove the markers on the abnormal peaks
    for ii = 1:length(Notastep)
        index_del(Notastep(ii)) = index_del(Notastep(ii)) - 1;
        index_del(Notastep(ii)+1) = index_del(Notastep(ii)+1) - 1;
    end    
    Notapeak = [];m=1;
    %Eliminate the abnormal peaks
    for ii = 1:length(locs)
        if index_del(ii) == 0
            Notapeak(m) = ii;
            m = m+1;
        end
    end    
    locs(Notapeak) = [];
 %% 
    
   
    

    
    
    

    
    
    
    

