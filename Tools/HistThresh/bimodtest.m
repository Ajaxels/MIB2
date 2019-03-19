function b = bimodtest(y)
% b = bimodtest(y)
%
% Test if a histogram is bimodal.
%
% In:
%  y    histogram
%
% Out:
%  b    true if histogram is bimodal, false otherwise
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

len = length(y);
b = false;
modes = 0;

% Count the number of modes of the histogram in a loop. If the number
% exceeds 2, return with boolean return value false.
for k = 2:len-1
  if y(k-1) < y(k) & y(k+1) < y(k)
    modes = modes+1;
    if modes > 2
      return
    end
  end
end

% The number of modes could be less than two here
if modes == 2
  b = true;
end
