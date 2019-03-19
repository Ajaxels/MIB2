function T = th_ptile(I,p,n)
% T =  th_ptile(I,p,n)
%
% Find a global threshold for a grayscale image by using the p-tile method.
%
% In:
%  I    grayscale image
%  p    fraction of foreground pixels (defaults to 0.5)
%  n    maximum graylevel (defaults to 255)
%
% Out:
%  T    threshold
%
% References: 
%
% W. Doyle, "Operation useful for similarity-invariant pattern recognition,"
% Journal of the Association for Computing Machinery, vol. 9,pp. 259-267,
% 1962.
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
  p = 0.5;
  n = 255;
elseif nargin == 2
  n = 255;
end

I = double(I);

% Calculate the histogram.
y = hist(I(:),0:n);

% The threshold is chosen such that 50% of pixels lie in each category.
Avec = zeros(1,n+1);
for t = 0:n
  Avec(t+1) = A(y,t)/A(y,n);
end

[minimum,ind] = min(abs(Avec-p));
T = ind-1;
