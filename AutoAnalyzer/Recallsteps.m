clear all
clc

source_direc = uigetdir;
cd(source_direc);

CellName = strcat('Ends','*');
file_f = dir(CellName);
file_num = length(file_f);
Counter = zeros(1,8);

for num = 1:file_num
    
    fname = file_f(num).name;
    fid = fopen(fname,'r');
    dat = textscan(fid,'%f %f');
    [Lend,Rend] = dat{:};
    if ~isempty(Lend)
       len = length(Lend);
       Counter(len) = Counter(len)+1;
    end
    fclose(fid);

end

% SUM = sum(Counter);
% Counter = Counter/SUM;

fid = fopen('Stepnumber.txt','w+');
fprintf(fid,'%13.8f\n',Counter);
fclose(fid);

