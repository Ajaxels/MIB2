% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 25.04.2023
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function mibDeepTrainingProgressStructUpdateAxesLimits(hMenu, actionData, parameter)
% function trainingProgressUpdateAxesLimits(hMenu, actionData, parameter)
% function to handle callbacks from the context menu for mibDeepTrainingProgressStruct.UILossAxes
global mibPath;
global mibDeepTrainingProgressStruct

prompts = {'Define value for Y max:', 'Define value for Y min:'};
defAns = {num2str(mibDeepTrainingProgressStruct.UILossAxes.YLim(2)), 
    num2str(mibDeepTrainingProgressStruct.UILossAxes.YLim(1))};
dlgTitle = 'Update Y limits';
options.WindowStyle = 'normal';
answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
if isempty(answer); return; end
ymax = str2double(answer{1});
ymin = str2double(answer{2});
if isnan(ymin) || isnan(ymax); return; end

mibDeepTrainingProgressStruct.UILossAxes.YLim = [ymin, ymax];
end