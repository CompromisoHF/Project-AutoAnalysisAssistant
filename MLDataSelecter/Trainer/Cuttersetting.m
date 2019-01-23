clc;
clear;
close all;


[filename, pathname] = uigetfile({'*.jpg'; '*.bmp'; '*.gif'; '*.png' }, 'Choose image');

if filename == 0
    return;
end

src = imread([pathname, filename]);
[m, n, z] = size(src);
figure(1)
imshow(src)

h=imrect;
cutpos=getPosition(h);

imCp = imcrop( src, cutpos );
figure(2)
imshow(imCp);

save cutpos