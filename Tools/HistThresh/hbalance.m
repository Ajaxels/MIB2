function E = hbalance(y,ind)
% E = hbalance(y,ind)
%
% Calculate the balance measure of the histogram around a histogram index.
%
% In:
%  y    histogram
%  ind  index about which balance is calculated
%
% Out:
%  E    balance measure
%
% References: 
%
% A. Rosenfeld and P. De La Torre, "Histogram concavity analysis as an aid
% in threhold selection," IEEE Transactions on Systems, Man, and
% Cybernetics, vol. 13, pp. 231-235, 1983.
%
% P. K. Sahoo, S. Soltani, and A. K. C. Wong, "A survey of thresholding
% techniques," Computer Vision, Graphics, and Image Processing, vol. 41,
% pp. 233-260, 1988.
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

n = length(y)-1;
E = A(y, ind)*(A(y, n)-A(y, ind));
