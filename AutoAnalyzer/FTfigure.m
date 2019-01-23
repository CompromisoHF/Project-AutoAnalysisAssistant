clear all
clc

fid = fopen('Steptime.txt','r');
dat = textscan(fid,'%f');
[ST] = dat{:}';
fclose(fid);

fid = fopen('Stepforce.txt','r');
dat = textscan(fid,'%f');
[SF] = dat{:}';
fclose(fid);

fid = fopen('StepMarker.txt','r');
dat = textscan(fid,'%f');
[SMarker] = dat{:}';
fclose(fid);

T=zeros(5,1)+0;
N=zeros(5,1)+0;
T=T';
N=N';

for i = 1:length(SF)

    for k = 1:5
        upper = 20*k;
        lower = 20*(k-1);
        if ((lower<SF(i))&&(SF(i)<=upper))
           T(k)=T(k)+ST(SMarker(i));
           N(k)=N(k)+1;
        end
    end
end

for k = 1:5
  T(k) = T(k)/N(k);
end

Fbin = 10:20:90;
H = figure;
plot(Fbin,T);
ylabel('Averaged Time(s)');
xlabel('Tether Force(pN)');
saveas(H,[pwd '\TvsF.tif']);
saveas(H,[pwd '\TvsF.fig']);
close(H);
save FT20pN;







