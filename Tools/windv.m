% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function vector2 = windv(vector1, w_size, asInSmooth)
% windv(vector, window size, asInSmooth)
% vectorized version of windv()
% smooths a vector using a window of +/- window size
% window size is reduced at the edges
%
% Parameters:
% vector1: vector to smooth
% w_size: a number with a window size to use; w_size==1 gives average window of 3
% points, w_size==2 gives average window of 5 points
% asInSmooth: an optional switch how to handle the end points. When
% asInSmooth == 1 the results are similar to the Matlab smooth function of
% the curve fitting toolbox

% When AsInSmooth == 1
% The first few elements of yy are given by
% yy(1) = y(1)
% yy(2) = (y(1) + y(2) + y(3))/3
% yy(3) = (y(1) + y(2) + y(3) + y(4) + y(5))/5
% yy(4) = (y(2) + y(3) + y(4) + y(5) + y(6))/5

% 
% Updates
% 20.09.2017 IB added AsInSmooth switch

if nargin < 3; asInSmooth = 0; end

vl = length(vector1);
vector2 = vector1;
for index = 1:w_size
    vector2(1:vl-index) = vector2(1:vl-index) + vector1(index+1:vl);
    vector2(index+1:vl) = vector2(index+1:vl) + vector1(1:vl-index);
end

vector2=vector2./(2*w_size+1);

if asInSmooth == 0
    for index = 1:w_size
        vector2(index) = mean(vector1(1:w_size+index));
        vector2(vl+1-index) = mean(vector1(vl+1-index-w_size:vl));
    end
else
    for index = 1:w_size
        vector2(index) = mean(vector1(1:(index-1)*2+1));
        vector2(vl+1-index) = mean(vector1(vl-(index-1)*2:vl));
    end
end
