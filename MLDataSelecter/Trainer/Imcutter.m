
clc; 
clear ;  
close all;

source_direc = uigetdir;
cd(source_direc);

ReadList1  = textread('pos_list.txt','%s','delimiter','\n');%load pos_list  
sz1=size(ReadList1);    
% label1=ones(sz1(1),1); %label the position sample 
ReadList2  = textread('neg_list.txt','%s','delimiter','\n');%load neg_list  
sz2=size(ReadList2);  
% label2=zeros(sz2(1),1);%label the negative sample  

% label=[label1',label2']';%generate the label  
% total_num=length(label);  

load cutpos
hwait=waitbar(0,'Please wait');
for i=1:sz1(1)  
    
   name = char(ReadList1(i,1));  
   src = imread(strcat(source_direc,'\newpos\',name));
   imCp = imcrop( src, cutpos );
   hh = figure('visible','off');
   imshow(imCp);
   saveas(hh,strcat(source_direc,'\pos\',name));
   close(hh);
   strw=['Processing Positive Group...',num2str(i/sz1(1)*100),'%'];
   waitbar(i/sz1(1),hwait,strw);
end  
delete(hwait);

hwait=waitbar(0,'Please wait');
for j=1:sz2(1)  
    
   name = char(ReadList2(j,1));  
   src = imread(strcat(source_direc,'\newneg\',name));  
   imCp = imcrop( src, cutpos );
   hh = figure('visible','off');
   imshow(imCp);
   saveas(hh,strcat(source_direc,'\neg\',name));
   close(hh);
   strw=['Processing Negative Group...',num2str(j/sz2(1)*100),'%'];
   waitbar(j/sz2(1),hwait,strw);
   
end  
delete(hwait);

close all

