function vecOut = mibRunningAverageSmoothPoints2(vecIn, halfwidth, excludePeaks)
% mibRunningAverageSmoothPoints - Smooth points for running average correction
%
% Parameters:
% vecIn:    Vector of input values to be smoothed
% halfwidth: Half-width of the smoothing window (0 = no smoothing)
% excludePeaks: Peaks higher than this value are excluded from correction (0 = ignore peaks)
%
% Return values:
% vecOut: Smoothed vector with drift removed

% Update
% 07.03.2025 modified to use polyfit to extrapolate smoothing at the edges

asInSmooth = true;
if halfwidth > 0
    if excludePeaks > 0
        diffX = diff(vecIn);
        peakPntsX = find(abs(diffX)>excludePeaks);
        vecIn3 = vecIn;
        for pntId=1:numel(peakPntsX)
            vecIn3(peakPntsX(pntId)+1:end) = vecIn3(peakPntsX(pntId)+1:end) - diffX(peakPntsX(pntId));
        end
        vecOut = vecIn3 - windv(vecIn3, halfwidth, asInSmooth);

        for pntId=1:numel(peakPntsX)
            vecOut(peakPntsX(pntId)+1:end) = vecOut(peakPntsX(pntId)+1:end) + diffX(peakPntsX(pntId));
        end
    else
        % subtract running average
        vecOut = vecIn - windv(vecIn, halfwidth, asInSmooth);
    end
else
    vecOut = vecIn;
end
