function T = th_moments(I,n)
% T =  th_moments(I,n)
%
% Find a global threshold for a grayscale image using moment preserving
% thresholding method.
%
% In:
%  I    grayscale image
%  n    maximum graylevel (defaults to 255)
%
% Out:
%  T    threshold
%
% References: 
%
% W. Tsai, "Moment-preserving thresholding: a new approach," Computer
% Vision, Graphics, and Image Processing, vol. 29, pp. 377-393, 1985.
%
% C. A. Glasbey, "An analysis of histogram-based thresholding algorithms,"
% CVGIP: Graphical Models and Image Processing, vol. 55, pp. 532-537, 1993.
%
%% Copyright (C) 2004-2013 Antti Niemistö
%%
%% This file is part of HistThresh toolbox.
%%
%% HistThresh toolbox is free software: you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation, either version 3 of the License, or
%% (at your option) any later version.
%%
%% HistThresh toolbox is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with HistThresh toolbox.  If not, see <http://www.gnu.org/licenses/>.

if nargin == 1
  n = 255;
end

I = double(I);

% Calculate the histogram.
y = hist(I(:),0:n);

% The threshold is chosen such that A(y,t)/A(y,n) is closest to x0.
Avec = zeros(1,n+1);
for t = 0:n
  Avec(t+1) = A(y,t)/A(y,n);
end

% The following finds x0.
x2 = (B(y,n)*C(y,n)-A(y,n)*D(y,n)) / (A(y,n)*C(y,n)-B(y,n)^2);
x1 = (B(y,n)*D(y,n)-C(y,n)^2) / (A(y,n)*C(y,n)-B(y,n)^2);
x0 = .5 - (B(y,n)/A(y,n)+x2/2) / sqrt(x2^2-4*x1);

% And finally the threshold.
[minimum,ind] = min(abs(Avec-x0));
T = ind-1;
