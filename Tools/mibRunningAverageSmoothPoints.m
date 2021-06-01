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

% Copyright (C) 24.08.2020, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
%
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
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