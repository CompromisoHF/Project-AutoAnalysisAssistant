clear all
clc

fid = fopen('Steptime.txt','r');
dat = textscan(fid,'%f');
[StepTime] = dat{:};
Maxtimelength = max(StepTime);

C = zeros(ceil(Maxtimelength*50)+1,2);
k=0;
for t=0:0.02:((ceil(Maxtimelength*50))/50)
    k=k+1;
    for i=1:length(StepTime)
        if StepTime(i)> t
            C(k,2) = C(k,2)+1;
        end
        C(k,1)=t;
    end
end

C(:,2)= C(:,2)/C(1,2);

fclose(fid);
fid = fopen('Count.txt','w+');
fprintf(fid,'%13.8f %13.8f\n',C.');
fclose(fid);
