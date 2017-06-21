% featureMatrix  = membraneFeatures(image, contextSize,
% membraneThickness, contextSizeHistogram, hessianSigma)
%author: Verena Kaynig
function [fm]  = membraneFeatures(im, cs, ms, csHist)
%normalize image contrast
im = norm01(im);

d = zeros(cs,cs);
s = round(cs / 2);
d(:,s-ms:s+ms) = 1;      % a membrane profile template
d = single(d);

% % test of double membrane pattern for context size = 11 pixels
% d = zeros(11,11);
% d(:,[3 4 8 9]) = 1;      % a membrane profile template
% d = single(d);

fm = single(zeros(size(im,1), size(im,2), 14));
fm(:,:,1) = im;

im = adapthisteq(im);

rot = filterImageWithMembraneTemplateRotated(im, d);
im = single(im);

fm(:,:,2) = rot(:,:,1);
fm(:,:,3) = rot(:,:,2);
fm(:,:,4) = rot(:,:,3);
fm(:,:,5) = rot(:,:,4);
fm(:,:,11) = rot(:,:,5);
fm(:,:,12) = rot(:,:,6);
fm(:,:,13) = rot(:,:,7);
fm(:,:,14) = rot(:,:,8);

rot = shiftdim(rot,2);  % switch dimensions
fm(:,:,6) = squeeze(min(rot));
fm(:,:,7) = squeeze(max(rot));
fm(:,:,8) = squeeze(mean(rot));
fm(:,:,9) = squeeze(var(rot));
fm(:,:,10) = squeeze(median(rot));
clear rot;

% disp('histogram');
csHalf = floor(csHist/2);
for i=1:length(im(:))
    [r,c] = ind2sub(size(im),i);
    if r < cs | c < cs | r > size(im,1)-cs | c > size(im,2)-cs % skip points at the border
        continue;
    else
        sub = im(r-csHalf:r+csHalf, c-csHalf:c+csHalf); % get fragment of the image
        sub = norm01(sub) * 100;
        [m,v,h] = meanvar(sub);     % get mean value (m), var and histogram
        fm(r,c,17:26) = h;
        fm(r,c,27) = m;
        fm(r,c,28) = v;
    end
end

%rotMax - rotMin
fm(:,:,end+1) = fm(:,:,7) - fm(:,:,6);

[eig1, eig2, cw] = structureTensorImage2(im, 1, 1);
[gx,gy,mag] = gradientImg(im,1);
% clear gx
% clear gy

% disp('for loop');

%used to be 20
for i=1:2:4
    ims = imsmooth(double(im),i);
    fm(:,:,end+1) = ims;
    fm(:,:,end+1) = imsmooth(eig1./eig2,i);
    fm(:,:,end+1) = imsmooth(mag,i);
    [gx,gy,mags] = gradientImg(im,i);
    fm(:,:,end+1) = mags;
    
    for j=1:2:i-2
        fm(:,:,end+1) = ims - single(imsmooth(double(im),j));
    end
end
smoothFM = fm(:,:,end-9:end);
fm(:,:,end+1) = shiftdim(var(shiftdim(smoothFM,2)),1);
fm(:,:,end+1) = norm01(imsmooth(double(im),2) - imsmooth(double(im),50));
fm(:,:,end+1) = im;

%disp('Feature extraction finished')

