function rot = filterImageWithMembraneTemplateRotated(im, d, noRotations)
% function rot = filterImageWithMembraneTemplateRotated(im, d, noRotations)
% filter image with a rotated template 
%
% Paramters:
% im: image to be analyzed
% d: a bitmap template
% noRotations: [optional] number of rotations in 180 degrees, default = 8;
%
% Return values: 
% rot: a matrix with filtered results [size(im,1) size(im,2) noRotations]
%
% normxcorr2 was updated in R2014a, should be faster

% original function is written by Verena Kaynig, vkaynig [at] seas.harvard.edu
% modified: Ilya Belevich, ilya.belevich @ helsinki.fi

if nargin < 3;    noRotations = 8;  end;

a = pi / noRotations;   % calculate rotation angle
im = double(im);    % convert image to doubles
rot = zeros([size(im,1), size(im,2), noRotations], 'single');   % memory allocation

parfor i=1:noRotations
    dt = centeredRotate(d, (i-1)*a);  % rotate template
    rot(:,:,i) = single(normxcorr2_mex(double(dt), im, 'same'));
end
