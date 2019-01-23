clear all
clc
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

%% Cut
CombineF = figure;
Cz = []; Cf = [];Count = 0;
for num = 1:file_num
    file_name = file_f(num).name;
%     FID = fopen(file_name,'r');
%     A = fscanf(FID,'%f %f',[2 Inf]);
%     fclose(FID);
    [A(:,1),ZZ,A(:,2)] = Nanoscope_reader(file_name);    
    A = A';
    H = figure;
    plot(A(:,1),A(:,2));
    k = waitforbuttonpress;
    if k
        close(H);   
        continue;
    else
    [B_x,B_y]=ginput(2);
    [~,Bs_index]=min(abs(A(:,1)-B_x(1)));
    [~,Be_index]=min(abs(A(:,1)-B_x(2)));
    close(H);
    Z = A(Bs_index:Be_index,1) ;
    F = A(Bs_index:Be_index,2) ;
    %Record  data
    Z = Z - Z(1);
    F = F - F(1);
    F = 1+F/abs(F(end));
    hold on
    plot(Z,F);
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
    C = [Z F];
    newname = strcat(dir_out,'Cut',file_name,'.dat');
    fid = fopen(newname,'w+');
    fprintf(fid,'%13.8f\t  %13.8f\n', C.');
    fclose(fid);
    end
end
saveas(CombineF,[dir_out strcat('Combine',...
       '.jpg')]);
close(CombineF);
Cf = Cf/Count;
H = figure;
plot(Cz,Cf);
saveas(H,[dir_out strcat('Averaged',...
       '.jpg')]);
close(H);