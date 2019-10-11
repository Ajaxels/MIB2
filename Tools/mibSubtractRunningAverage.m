function [shiftXOut, shiftYOut, halfwidth, excludePeaks] = mibSubtractRunningAverage(shiftX, shiftY, halfwidth, excludePeaks, useBatchMode)

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
        answer = mibInputMultiDlg({mibPath}, prompts, defAns, 'Running average');
        
        if isempty(answer)
            shiftXOut = [];
            return;
        end
        halfwidth = str2double(answer{1});
        excludePeaks = str2double(answer{2});
        
        [shiftXOut, shiftYOut] = generatePoints(shiftX, shiftY, halfwidth, excludePeaks);
        
        figure(155);
        subplot(2,1,1)
        plot(1:length(shiftX), shiftX, 1:length(shiftXOut), shiftXOut);
        legend('Shift X', 'Smoothed X');
        grid;
        xlabel('Frame number');
        ylabel('Displacement');
        title('X coordinate');
        subplot(2,1,2)
        plot(1:length(shiftY), shiftY, 1:length(shiftYOut), shiftYOut);
        legend('Shift Y', 'Smoothed Y');
        grid;
        xlabel('Frame number');
        ylabel('Displacement');
        title('Y coordinate');
        
        fixDrifts = questdlg('Align the stack using detected displacements?', 'Fix drifts', 'Yes', 'Change window size', 'No', 'Yes');
        if strcmp(fixDrifts, 'No')
            if isdeployed == 0
                assignin('base', 'shiftX', shiftXOut);
                assignin('base', 'shiftY', shiftYOut);
                fprintf('Shifts between images were exported to the Matlab workspace (shiftX, shiftY)\nThese variables can be modified and saved to a disk using the following command:\nsave ''myfile.mat'' shiftX shiftY;\n');
            end
            shiftXOut = [];
            return;
        end
        
        if strcmp(fixDrifts, 'Yes')
            notOk = 0;
        end
        delete(155);
    else
        [shiftXOut, shiftYOut] = generatePoints(shiftX, shiftY, halfwidth, excludePeaks);
        notOk = 0;
    end
end
end

function [shiftXOut, shiftYOut] = generatePoints(shiftX, shiftY, halfwidth, excludePeaks)
if halfwidth > 0
    if excludePeaks > 0
        diffX = diff(shiftX);
        diffY = diff(shiftY);
        peakPntsX = find(abs(diffX)>excludePeaks);
        peakPntsY = find(abs(diffY)>excludePeaks);
        shiftX3 = shiftX;
        for pntId=1:numel(peakPntsX)
            shiftX3(peakPntsX(pntId)+1:end) = shiftX3(peakPntsX(pntId)+1:end) - diffX(peakPntsX(pntId));
        end
        shiftY3 = shiftY;
        for pntId=1:numel(peakPntsY)
            shiftY3(peakPntsY(pntId)+1:end) = shiftY3(peakPntsY(pntId)+1:end) - diffY(peakPntsY(pntId));
        end
        shiftXOut = round(shiftX3-windv(shiftX3, halfwidth));
        shiftYOut = round(shiftY3-windv(shiftY3, halfwidth));
        
        for pntId=1:numel(peakPntsX)
            shiftXOut(peakPntsX(pntId)+1:end) = shiftXOut(peakPntsX(pntId)+1:end) + diffX(peakPntsX(pntId));
        end
        for pntId=1:numel(peakPntsY)
            shiftYOut(peakPntsY(pntId)+1:end) = shiftYOut(peakPntsY(pntId)+1:end) + diffY(peakPntsY(pntId));
        end
    else
        % subtract running average
        shiftXOut = round(shiftX-windv(shiftX, halfwidth));
        shiftYOut = round(shiftY-windv(shiftY, halfwidth));
    end
else
    shiftXOut = shiftX;
    shiftYOut = shiftY;
end
end