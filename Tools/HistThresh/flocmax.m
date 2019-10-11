function y = flocmax(x)
% y = flocmax(x)
%
% Find the local maxima of a vector using a three point neighborhood.
%
% In:
%  x    vector
%
% Out:
%  y    binary vector with maxima of x marked as ones
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

len = length(x);
y = zeros(1,len);

for k = 2:len-1
  [dummy,ind] = max(x(k-1:k+1));
  if ind == 2
    y(k) = 1;
  end
end
