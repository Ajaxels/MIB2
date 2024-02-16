% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 25.04.2023
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function mibDeepStopTrainingCallback(hButton, varargin)
% function mibDeepStopTrainingCallback()
% stop training process by pressing the Stop training or Emergency stop
% buttons

global mibDeepStopTraining
global mibDeepTrainingProgressStruct

mibDeepStopTraining = true;

% check for presence of the progress dialog when training is prepared
% and obj.wb.CancelRequested
if isa(hButton, 'matlab.ui.dialog.ProgressDialog')   % close training progress window
    delete(hButton);
    mibDeepTrainingProgressStruct =  struct();
    return;
end

% instant training stop with generation of mibDeep file from
% the recent checkpoint
if ~isempty(hButton) && isprop(hButton, 'Text') && strcmp(hButton.Text, 'Emergency Brake')
    if mibDeepTrainingProgressStruct.Workflow(1) == '3' || strcmp(mibDeepTrainingProgressStruct.Architecture, 'SegNet')
        answer = questdlg(sprintf('!!! Warning !!!\n\nThe current network architecture has BatchNormalization layers which requires calculation of final means and variances to finalize the network.\n\nIf you are not planning to use the network or planning to continue training in future this step may be skipped (Stop immediately), otherwise cancel and stop the run normally (Stop and finalize)'), ...
            'Emergency brake', ...
            'Stop immediately', 'Stop and finalize', 'Stop and finalize');
        if strcmp(answer, 'Stop immediately')
            mibDeepTrainingProgressStruct.emergencyBrake = true;
        end
    else
        mibDeepTrainingProgressStruct.emergencyBrake = true;
    end
end

switch hButton.Text
    case 'Stop training'
        hButton.Text = 'Stopping...';
        hButton.BackgroundColor = [1 .5 0];
    case 'Stopping...'
        hButton.Text = 'Train';
        hButton.BackgroundColor = [0.7686    0.9020    0.9882];
        mibDeepTrainingProgressStruct =  struct();
end
drawnow;

end