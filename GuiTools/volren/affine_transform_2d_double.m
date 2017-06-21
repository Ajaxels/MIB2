function Iout=affine_transform_2d_double(Iin,M,mode,ImageSize)
% Affine transformation function (Rotation, Translation, Resize)
% This function transforms a volume with a 3x3 transformation matrix 
%
% Iout=affine_transform_2d_double(Iin,Minv,mode,ImagSize)
%
% inputs,
%   Iin: The input image
%   Minv: The (inverse) 3x3 transformation matrix
%   mode: If 0: linear interpolation and outside pixels set to nearest pixel
%            1: linear interpolation and outside pixels set to zero
%            (cubic interpolation only support by compiled mex file)
%            2: cubic interpolation and outsite pixels set to nearest pixel
%            3: cubic interpolation and outside pixels set to zero
%            4: nearest interpolation and outsite pixels set to nearest pixel
%            5: nearest interpolation and outside pixels set to zero
%   (optional) 
%	ImageSize: Size of output imgage
%
% output,
%   Iout: The transformed image
%
% example,
%   % Read image
%   I=im2double(imread('lenag2.png'))
%   % Make a transformation matrix
%   M=make_transformation_matrix([2 3],2,[1.0 1.1]);
%   % Transform the image
%   Iout=affine_transform_2d_double(I,M,0)
%   % Show the image
%   figure, imshow(Iout);
%
% Function is written by D.Kroon University of Twente (February 2009)

% Set output image size
if(nargin<4), ImageSize=[size(Iin,1) size(Iin,2)]; end  

% Make all x,y indices
[x,y]=ndgrid(0:ImageSize(1)-1,0:ImageSize(2)-1);

% Calculate center of the output image
mean_out=ImageSize/2;

% Calculate center of the input image
mean_in=size(Iin)/2;

% Make center of the image coordinates 0,0
xd=x-mean_out(1);
yd=y-mean_out(2);

% Calculate the Transformed coordinates
Tlocalx = mean_in(1) + M(1,1) * xd + M(1,2) *yd + M(1,3) * 1;
Tlocaly = mean_in(2) + M(2,1) * xd + M(2,2) *yd + M(2,3) * 1;

switch(mode)
	case 0
		Interpolation='bilinear';
		Boundary='replicate';
	case 1
		Interpolation='bilinear';
		Boundary='zero';
	case 2
		Interpolation='bicubic';
		Boundary='replicate';
	case 3
		Interpolation='bicubic';
		Boundary='zero';
	case 4
		Interpolation='nearest';
		Boundary='replicate';
	case 5
		Interpolation='nearest';
		Boundary='zero';		
end
Iout=image_interpolation(Iin,Tlocalx,Tlocaly,Interpolation,Boundary,ImageSize);
