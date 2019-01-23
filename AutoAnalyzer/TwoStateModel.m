clear all
clc

fid = fopen('Steptime.txt','r');
dat = textscan(fid,'%f');
[StepTime] = dat{:};
Mintimelength = min(StepTime);
StepTime = StepTime - Mintimelength;

f=fittype('1-exp(-k*(t-t0))','independent','t','coefficients',{'k','t0'});

S = sort(StepTime);
N = length(StepTime);
X = zeros(2*N-1,1);
Y = zeros(2*N-1,1);

for i=1:(N-1)
    X(2*i-1)=S(i);
    Y(2*i-1)=(i-1)/(N-1);
    X(2*i)=S(i); 
    Y(2*i)=i/(N-1);       
end
X(2*N-1)=S(N);
Y(2*N-1)=1;

save XY;
[EXfit,gof] = fit(X,Y,f);

M=mean(StepTime);

H1=figure;
plot(X,Y);
hold on;
plot(EXfit);
hold off;
xlabel('Time(s)');
ylabel('Fraction');
title({'k = ' EXfit.k 't0 = ' EXfit.t0 'M = ' M});
saveas(H1,[pwd '\Twostatemodel.jpg']);
saveas(H1,[pwd '\Twostatemodel.fig']);
close(H1);

close all

