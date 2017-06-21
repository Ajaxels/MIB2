%function [gx, gy, mag] = gradientImg(im, s)
function [gx, gy, mag] = gradientImg(im, s)


% $$$ fg = fspecial('gaussian',4*s,s);
% $$$ fs = fspecial('sobel');
% $$$ 
% $$$ fgy = filter2(fs,fg);
% $$$ fgx = filter2(fs',fg);
% $$$ 
% $$$ fgm = sqrt(fgx.^2 + fgy.^2);
% $$$ 
% $$$ gy = filter2(fgy,im);
% $$$ gx = filter2(fgx,im);


im = imsmooth(double(im),s);
[gx,gy] = gradient(im);
mag = sqrt(gx.^2 + gy.^2);