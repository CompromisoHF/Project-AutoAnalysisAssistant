function [Startpoint,Steplen] = Steplength(Ori_Z,Ori_F,Stairs,Noise,filename,dirout)

datalen = length(Ori_Z);
for i = 1:length(Stairs)
    rulercenter = Stairs(i);
    rulerupper = rulercenter + 1.5*Noise;
    rulerlower = rulercenter - 1.5*Noise;    
    Zindex = 0;
    rightend = 0;
    leftend = 0;
    maxWidth = 0;
    for j = 1:datalen
        if ((Ori_F(j)<=rulerupper)&&(Ori_F(j)>=rulerlower))
            switch Zindex
                case 1
                rightend = j;
                case 0
                rightend = j;
                leftend = j;
                Zindex = 1;
            end 
        else
            Zindex = 0;
            if (rightend - leftend ~=0)
                if (maxWidth < (rightend - leftend))
                    maxWidth = rightend - leftend;
                    R_end(i) = rightend;
                    L_end(i) = leftend;
                end
            end
        end
    end
    if (rightend - leftend ~=0)
         if (maxWidth < (rightend - leftend))
             maxWidth = rightend - leftend;
             R_end(i) = rightend;
             L_end(i) = leftend;
         end
    end 
end
Steplen = [];
Startpoint = R_end(end);
DD = pwd;
cd(strcat(dirout,'\Ends\'));

Name = strcat('Ends_',filename,'.txt');
Fid = fopen(Name,'w+');

for i = 2:(length(Stairs))
    fprintf(Fid,'%13.8f %13.8f\n',L_end(i),R_end(i));
    Steplen(i-1) = abs(Ori_Z(R_end(i))-Ori_Z(L_end(end)));
end

fclose(Fid);
cd(DD);








