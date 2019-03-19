function T = th_intermeans_iter(I,n)
% T =  th_intermeans_iter(I,n)
%
% Find a global threshold for a grayscale image using the iterative
% intermeans method.
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
% T. Ridler and S. Calvard, "Picture thresholding using an iterative
% selection method," IEEE Transactions on Systems, Man, and Cybernetics,
% vol. 8, pp. 630-632, 1978.
%
% H. J. Trussell, "Comments on 'Picture thresholding using an iterative
% selection method'," IEEE Transactions on Systems, Man, and Cybernetics,
% vol. 9, p. 311, 1979.
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

% The initial estimate for the threshold is found with the MEAN algorithm.
T = th_mean(I,n);
Tprev = NaN;

% The threshold is found iteratively. In each iteration, the means of the
% pixels below (mu) the threshold and above (nu) it are found. The
% updated threshold is the mean of mu and nu.
while T ~= Tprev
  mu = B(y,T)/A(y,T);
  nu = (B(y,n)-B(y,T))/(A(y,n)-A(y,T));
  Tprev = T;
  T = floor((mu+nu)/2);
end
