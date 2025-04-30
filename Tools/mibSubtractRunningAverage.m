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

function [shiftXOut, shiftYOut, halfwidth, excludePeaks] = mibSubtractRunningAverage(shiftX, shiftY, halfwidth, excludePeaks, useBatchMode)
% function [shiftXOut, shiftYOut, halfwidth, excludePeaks] = mibSubtractRunningAverage(shiftX, shiftY, halfwidth, excludePeaks, useBatchMode)
% smooth drift correction using the running average correction
%
% Parameters:
% shiftX:    vector of input X values to be smoothed
% shiftY:    vector of input Y values to be smoothed
% halfwidth:    half-width of the smoothing window, when 0-do not smooth
% excludePeaks: peaks higher than this value are excluded from the
% correction, when 0 - do not consider peaks
% useBatchMode: use the batch mode, i.e. no questions asked
%
% Return values:
% shiftXOut: smoothed X vector
% shiftYOut: smoothed X vector
% halfwidth: used half-width
% excludePeaks: excluded peaks value

% Updates
%

global mibPath;
if nargin < 5; useBatchMode = 0; end
if nargin < 4; excludePeaks = 0; end
if nargin < 3; halfwidth = 25; end

notOk = 1;
while notOk
    if useBatchMode == 0
        %answer = mibInputDlg({mibPath}, ...
        %    sprintf('Please enter half-width of the averaging window:'),...
        %    'Running average', '25');
        
        prompts = {'Please enter half-width of the averaging window:'; 'Exclude peaks higher than this value from the running average:'};
        defAns = {num2str(halfwidth), num2str(excludePeaks)};
        questOpt.WindowStyle  = 'normal';
        answer = mibInputMultiDlg({mibPath}, prompts, defAns, 'Running average', questOpt);
        
        if isempty(answer)
            shiftXOut = [];
            return;
        end
        halfwidth = str2double(answer{1});
        excludePeaks = str2double(answer{2});
        
        shiftXOut = round(mibRunningAverageSmoothPoints(shiftX, halfwidth, excludePeaks));
        shiftYOut = round(mibRunningAverageSmoothPoints(shiftY, halfwidth, excludePeaks));
        
        figure(155);
        subplot(2,1,1)
        plot(1:length(shiftX), shiftX, '.-', 1:length(shiftXOut), shiftXOut, '.-');
        legend('Shift X', 'Smoothed X', 'Location', 'best');
        grid;
        xlabel('Frame number');
        ylabel('Displacement');
        title('X coordinate');
        subplot(2,1,2)
        plot(1:length(shiftY), shiftY, '.-', 1:length(shiftYOut), shiftYOut, '.-');
        legend('Shift Y', 'Smoothed Y', 'Location', 'best');
        grid;
        xlabel('Frame number');
        ylabel('Displacement');
        title('Y coordinate');
        
        mibQuestDlgOpt.ButtonWidth = [70 90 90];
        mibQuestDlgOpt.WindowHeight = 70;
        fixDrifts = mibQuestDlg({}, 'Align the stack using detected displacements?', ...
            {'Quit alignment'; 'Change window size'; 'Apply current values'}, 'Align dataset', mibQuestDlgOpt);

        if strcmp(fixDrifts, 'Quit alignment')
            if isdeployed == 0
                assignin('base', 'shiftX', shiftXOut);
                assignin('base', 'shiftY', shiftYOut);
                fprintf('Shifts between images were exported to the Matlab workspace (shiftX, shiftY)\nThese variables can be modified and saved to a disk using the following command:\nsave ''myfile.mat'' shiftX shiftY;\n');
            end
            shiftXOut = [];
            return;
        end
        
        if strcmp(fixDrifts, 'Apply current values')
            notOk = 0;
        end
        %delete(155);
    else
        shiftXOut = round(mibRunningAverageSmoothPoints(shiftX, halfwidth, excludePeaks));
        shiftYOut = round(mibRunningAverageSmoothPoints(shiftY, halfwidth, excludePeaks));
        notOk = 0;
    end
end
end
