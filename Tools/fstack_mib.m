function imOut = fstack_mib(I, options)
% function imOut = fstack_mib(I, options)
% Extended depth-of-field focus stacking based on fstack function by Said Pertuz
% https://se.mathworks.com/matlabcentral/fileexchange/55115-extended-depth-of-field
% Generate extended depth-of-field image from focus sequence using noise-robust selective all-in-focus algorithm [1]. 
%
% Parameters:
% I - a stack of images in format I(1:height, 1:width, 1:colors, 1:depth)
% options - an optional structure with parameters
% .nhsize - size of focus measure window (9).
% .focus - a vector with the focus of each frame.
% .alpha - a scalar in (0,1]. Default is 0.2. See [1] for details.
% .sth - a scalar. Default is 13. See [1] for details.   
% .showWaitbar - show or not the waitbar
%
% Return values:
% imOut: a single plane image with an extended depth-of-field

%For further details, see:
% [1] Pertuz et. al. "Generation of all-in-focus images by
%   noise-robust selective fusion of limited depth-of-field
%   images" IEEE Trans. Image Process, 22(3):1242 - 1251, 2013.
%
% S. Pertuz, Jan/2016
% adapted for MIB by Ilya Belevich, 08.02.2019

if nargin < 2; options = struct(); end
if ~isfield(options, 'nhsize'); options.nhsize = 9; end
if ~isfield(options, 'focus'); options.focus = 1:size(I, 4); end
if ~isfield(options, 'alpha'); options.alpha = 0.2; end
if ~isfield(options, 'sth'); options.sth = 13; end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = 1; end

if options.showWaitbar; wb = waitbar(0, 'Initializing...', 'Name', 'Extended depth-of-field focus stacking'); end
tic;
height = size(I, 1);
width = size(I, 2);
colors = size(I, 3);
depth = size(I, 4);

m = zeros([height, width, depth]);

if options.showWaitbar; waitbar(0.1, wb, 'Calculating F-measure...'); end
for p = 1:depth
    im = mean(I(:,:,:,p), 3);   % take an average of all color channels, should be double
    fm(:,:,p) = gfocus(im, options.nhsize);
end

%********** Compute Smeasure ******************
if options.showWaitbar; waitbar(0.35, wb, 'Calculating S-measure...'); end
[u, s, A, fmax] = gauss3P(options.focus, fm);

%Aprox. RMS of error signal as sum|Signal-Noise|
%instead of sqrt(sum(Signal-noise)^2):
err = zeros(height, width);
for p = 1:depth
    err = err + abs( fm(:,:,p) - ...
        A.*exp(-(options.focus(p)-u).^2./(2*s.^2)));
    fm(:,:,p) = fm(:,:,p)./fmax;
end
h = fspecial('average', options.nhsize);
inv_psnr = imfilter(err./(depth*fmax), h, 'replicate');

S = 20*log10(1./inv_psnr);
S(isnan(S))=min(S(:));

if options.showWaitbar; waitbar(0.65, wb, 'Calculating weights...'); end
phi = 0.5*(1+tanh(options.alpha*(S-options.sth)))/options.alpha;
phi = medfilt2(phi, [3 3]);

%********** Compute weights: ********************
fun = @(phi,fm) 0.5 + 0.5*tanh(phi.*(fm-1));
for p = 1:depth    
    fm(:,:,p) = feval(fun, phi, fm(:,:,p));
end

%********* Fuse images: *****************
if options.showWaitbar; waitbar(0.85, wb, 'Fusing images...'); end
fmn = sum(fm, 3); %(Normalization factor)
imOut = zeros([height, width, colors], class(I));
for colCh = 1:colors
    imOut(:,:,colCh) = sum((squeeze(double(I(:,:,colCh, :))).*fm), 3)./fmn;
end

if options.showWaitbar; waitbar(1, wb); delete(wb); end
toc;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [u, s, A, Ymax] = gauss3P(x, Y)
% Fast 3-point gaussian interpolation

[height,width,depth] = size(Y);
if depth < 5
    STEP = 1; % Internal parameter
else
    STEP = 2; % Internal parameter
end
[Ymax, I] = max(Y,[ ], 3);
[IN,IM] = meshgrid(1:width,1:height);
Ic = I(:);
Ic(Ic<=STEP)=STEP+1;
Ic(Ic>=depth-STEP)=depth-STEP;
Index1 = sub2ind([height,width,depth], IM(:), IN(:), Ic-STEP);
Index2 = sub2ind([height,width,depth], IM(:), IN(:), Ic);
Index3 = sub2ind([height,width,depth], IM(:), IN(:), Ic+STEP);
Index1(I(:)<=STEP) = Index3(I(:)<=STEP);
Index3(I(:)>=STEP) = Index1(I(:)>=STEP);
x1 = reshape(x(Ic(:)-STEP),height,width);
x2 = reshape(x(Ic(:)),height,width);
x3 = reshape(x(Ic(:)+STEP),height,width);
y1 = reshape(log(Y(Index1)),height,width);
y2 = reshape(log(Y(Index2)),height,width);
y3 = reshape(log(Y(Index3)),height,width);
c = ( (y1-y2).*(x2-x3)-(y2-y3).*(x1-x2) )./...
    ( (x1.^2-x2.^2).*(x2-x3)-(x2.^2-x3.^2).*(x1-x2) );
b = ( (y2-y3)-c.*(x2-x3).*(x2+x3) )./(x2-x3);
s = sqrt(-1./(2*c));
u = b.*s.^2;
a = y1 - b.*x1 - c.*x1.^2;
A = exp(a + u.^2./(2*s.^2));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function FM = gfocus(im, WSize)
% Compute focus measure using graylevel local variance
MEANF = fspecial('average',[WSize WSize]);
U = imfilter(im, MEANF, 'replicate');
FM = (im-U).^2;
FM = imfilter(FM, MEANF, 'replicate');
end
