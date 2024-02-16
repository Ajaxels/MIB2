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

function vecOut = mibRunningAverageSmoothPoints(vecIn, halfwidth, excludePeaks)
%function vecOut = mibRunningAverageSmoothPoints(vecIn, halfwidth, excludePeaks)
% smooth points for the running average correction
%
% Parameters:
% vecIn:    vector of input values to be smoothed
% halfwidth:    half-width of the smoothing window, when 0-do not smooth
% excludePeaks: peaks higher than this value are excluded from the
% correction, when 0 - do not consider peaks
%
% Return values:
% vecOut: smoothed vector

% Updates
%

if halfwidth > 0
    if excludePeaks > 0
        diffX = diff(vecIn);
        peakPntsX = find(abs(diffX)>excludePeaks);
        vecIn3 = vecIn;
        for pntId=1:numel(peakPntsX)
            vecIn3(peakPntsX(pntId)+1:end) = vecIn3(peakPntsX(pntId)+1:end) - diffX(peakPntsX(pntId));
        end
        vecOut = vecIn3-windv(vecIn3, halfwidth);
        
        for pntId=1:numel(peakPntsX)
            vecOut(peakPntsX(pntId)+1:end) = vecOut(peakPntsX(pntId)+1:end) + diffX(peakPntsX(pntId));
        end
    else
        % subtract running average
        vecOut = vecIn-windv(vecIn, halfwidth);
    end
else
    vecOut = vecIn;
end
end