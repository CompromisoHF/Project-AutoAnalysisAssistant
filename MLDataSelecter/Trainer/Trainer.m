
clc; 
clear ;  
close all;

source_direc = uigetdir;
cd(source_direc);

%% Training process 

ReadList1  = textread('pos_list.txt','%s','delimiter','\n');%load pos_list  
sz1=size(ReadList1);    
label1=ones(sz1(1),1); %label the position sample 
ReadList2  = textread('neg_list.txt','%s','delimiter','\n');%load neg_list  
sz2=size(ReadList2);  
label2=zeros(sz2(1),1);%label the negative sample  

label=[label1',label2']';%generate the label  
total_num=length(label);  
data=zeros(total_num,64);  %1764 8100 34596 142884

hwait=waitbar(0,'Please wait');


%postive feature
for i=1:sz1(1)  
    
   name= char(ReadList1(i,1));  
   image=imread(strcat(source_direc,'\pos\',name));
   
   im=imresize(image,[64,128]);  
   img =rgb2gray(im);  
   
   hog =hogcalculator(img);  
   data(i,:)=hog;  
   
   strw=['Positive Group HOG Calculating...',num2str(i/sz1(1)*100),'%'];
   waitbar(i/sz1(1),hwait,strw);
   
end  
delete(hwait);

hwait=waitbar(0,'Please wait');
%negative feature
for j=1:sz2(1)  
   name= char(ReadList2(j,1));  
   image=imread(strcat(source_direc,'\neg\',name));  
   
   im=imresize(image,[64,128]);  
   img=rgb2gray(im);  
   
   hog =hogcalculator(img);  
   data(sz1(1)+j,:)=hog;  
   
   strw=['Negative Group HOG Calculating...',num2str(j/sz2(1)*100),'%'];
   waitbar(j/sz2(1),hwait,strw);
   
end  
delete(hwait);

% [train, test] = crossvalind('holdOut',label,0.001);  
% cp = classperf(label);  

rng default
svmModel = fitcsvm(data,label,'OptimizeHyperparameters','auto',...
    'HyperparameterOptimizationOptions',struct('AcquisitionFunctionName',...
    'expected-improvement-plus'));
save svmModel svmModel

svmModel 

CVSVMModel = crossval(svmModel);
classLoss = kfoldLoss(CVSVMModel);

CVSVMModel
classLoss


% [classes,score] = predict(svmModel,data(test,:));  
% [Labelresult,scorePred] = kfoldPredict(CVSVMModel);
% classperf(cp,classes,test);  
% cp.CorrectRate   

%% Training result saved in svmStruct
% load svmStruct  
% test=imread('test.jpg');  
%      
% im=imresize(test,[64,64]);  
% figure;  
% imshow(im);  
% img=rgb2gray(im);  
% hogt =hogcalculator(img);
% classes = svmclassify(svgt);