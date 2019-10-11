function T = th_entropy(I,n)
% T =  th_intermeans(I,n)
%
% Find a global threshold for a grayscale image using the method based on
% the entropy of the image histogram.
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
% J. N. Kapur, P. K. Sahoo, and A. K. C. Wong, "A new method for gray-level
% picture thresholding using the entropy of the histogram," Computer Vision,
% Graphics, and Image Processing, vol. 29, pp. 273-285, 1985.
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
y = hist(I(:), 0:n);

warning_state = warning('off');
% The threshold is chosen such that the following expression is minimized.
for j = 0:n
  vec(j+1) = E(y,j)/A(y,j) - log10(A(y,j)) + ...
      (E(y,n)-E(y,j))/(A(y,n)-A(y,j)) - log10(A(y,n)-A(y,j));
end
warning(warning_state);     % Switch warning back to initial settings

[minimum,ind] = min(vec);
T = ind-1;


% Entroy function. Note that the function returns the negative of
% entropy.
function x = E(y,j)

y = y(1:j+1);
y = y(y~=0);
x = sum(y.*log10(y));
