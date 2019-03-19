function x = D(y,j)
% x = D(y,j)
%
% The partial sum D from C. A. Glasbey, "An analysis of histogram-based
% thresholding algorithms," CVGIP: Graphical Models and Image Processing,
% vol. 55, pp. 532-537, 1993.
%
% In:
%  y    histogram
%  j    last index in the sum
%
% Out:
%  x    value of the sum
%  
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

ind = 0:j;
x = ind.^3*y(1:j+1)';
