function menuImageToolsArithmetics_Callback(obj)
% function menuImageToolsArithmetics_Callback(obj, hObject)
% callback to the Menu->Image->Tools->Image arithmetics, perform arithmetic
% expression over the input image
%
% Parameters:
% 
% 

% Copyright (C) 08.04.2018, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 
global mibPath;

% check for the virtual stacking mode and close the controller
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    toolname = 'image arithmetics tools are';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

prompts = {'Input A:'; 'Destination class'; 'Destination buffer'; ...
    'Input B (optional):'; 'Input C (optional):'; 'Convert via uint32';...
    sprintf('Expression:\n"A=A*2" - to multiply image A in 2 times\n"A=A+100" - to increase image A by 100\n"A=A+B" - to add image B to A\n"A=A-min(A(:))" - shift A by its minimum value\n"A=A+uint32(randi(20, size(A)))" - add random noise')};
destBuffers = cell([1, obj.mibModel.maxId]);
for i=1:obj.mibModel.maxId
    destBuffers{i} = sprintf('Container %d', i);
end
currentId = obj.mibModel.Id;

imgClass = class(obj.mibModel.I{obj.mibModel.Id}.img{1}(1));
classList = {'uint8', 'uint16', 'uint32'};
%classList{4} = find(ismember(classList, imgClass)==1);
classId = find(ismember(classList, imgClass)==1);

%defAns = {[destBuffers, currentId]; classList; [destBuffers, currentId]; [destBuffers, currentId]; [destBuffers, currentId]; 'A*2'};
dlgTitle = 'Image arithmetics';
options.WindowStyle = 'normal';       % [optional] style of the window
options.Title = 'Enter an arithmetic expression; images in the specified containers are referenced as A, B and C';   % [optional] additional text at the top of the window
options.TitleLines = 2;
options.Focus = 1;      % [optional] define index of the widget to get focus
options.PromptLines = [1, 1, 1, 1, 1, 1, 6];
options.WindowWidth = 1.3;
options.Columns = 2;
options.LastItemColumns = 1;
notOk = 1;

selIndex = [currentId, classId, currentId, currentId, currentId];
answer{6} = 1;  % convert via uint32
answer{7} = 'A=A';

selectedUseUnit32 = 1;  % variable to hold a selection state of the via uint32 checkbox

while notOk
    defAns = {[destBuffers, selIndex(1)]; [classList, selIndex(2)]; [destBuffers, selIndex(3)]; [destBuffers, selIndex(4)]; [destBuffers, selIndex(5)]; logical(answer{6}); answer{7}};
    prevSellIndex = selIndex;   % store the previous selection index
    
    [answer, selIndex] = menuImageToolsArithmeticsGetParameters(mibPath, prompts, defAns, dlgTitle, options);
    %[answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
    if isempty(answer); notOk=0; return; end
    IdI1 = selIndex(1); % index for A
    if IdI1 ~= prevSellIndex(1); clear A; end  % clear A if the new container was selected
    classId = answer{2}; % destination class
    destId = selIndex(3);   % destination buffer id
    IdI2 = selIndex(4); % index for B
    if IdI2 ~= prevSellIndex(4); clear B; end  % clear B if the new container was selected
    IdI3 = selIndex(5); % index for C
    if IdI3 ~= prevSellIndex(5); clear C; end  % clear C if the new container was selected
    useUnit32 = answer{6};  % use uint32 class for math
    expStr = answer{7}; % expression string
    if selIndex(2) ~= prevSellIndex(2); clear A B C; end     % clear all variables if the class type was changed

    wb = waitbar(0, sprintf('Performing: %s\nPlease wait...', expStr), 'Name', 'Image arithmetics');
    
    logText = 'Arithmetics:';
    
    % get A
    if exist('A', 'var') == 0 || useUnit32 ~= selectedUseUnit32
        getDataOptions.blockModeSwitch = 0;
        getDataOptions.id = IdI1;
        A = cell2mat(obj.mibModel.getData4D('image', 4, 0, getDataOptions));
        % convert class if needed
        if useUnit32
            A = uint32(A);
        else
            if ~strcmp(class(A), classId)
                switch classId
                    case 'uint8'
                        A = uint8(A);
                    case 'uint16'
                        A = uint16(A);
                    case 'unit32'
                        A = uint32(A);
                end
                logText = sprintf('%s ->%s;', logText, classId);
            end
        end
        waitbar(0.1, wb);
    end

    % get B if needed
    if strfind(expStr, 'B')  %#ok<STRIFCND>
        if exist('B', 'var') == 0 || useUnit32 ~= selectedUseUnit32 
            getDataOptions.id = IdI2;
            B = cell2mat(obj.mibModel.getData4D('image', 4, 0, getDataOptions));
            % convert class if needed
            if useUnit32
                B = uint32(B);
            else
                if ~strcmp(class(B), classId)
                    switch classId
                        case 'uint8'
                            B = uint8(B);
                        case 'uint16'
                            B = uint16(B);
                        case 'unit32'
                            B = uint32(B);
                    end
                end
            end
        end
        waitbar(0.2, wb);
    end
    
    % get C if needed
    if strfind(expStr, 'C')   %#ok<STRIFCND>
        if exist('C', 'var') == 0 || useUnit32 ~= selectedUseUnit32 
            getDataOptions.id = IdI3;
            C = cell2mat(obj.mibModel.getData4D('image', 4, 0, getDataOptions));
            % convert class if needed
            if useUnit32
                B = uint32(B);
            else
                if ~strcmp(class(C), classId)
                    switch classId
                        case 'uint8'
                            C = uint8(C);
                        case 'uint16'
                            C = uint16(C);
                        case 'unit32'
                            C = uint32(C);
                    end
                end
            end
        end
        waitbar(0.3, wb);
    end
    
    selectedUseUnit32 = useUnit32;
    
    try
        expressionText = sprintf('%s;', expStr);
        eval(expressionText);
        notOk = 0;  % exit the while loop
    catch err
        delete(wb);
        questAnswer = questdlg(...
            sprintf('!!! Error !!!\n\nWrong expression!\n%s\nWould you like to try again?', err.message)...
            , 'Error', 'Try again', 'Close', 'Try again');
        %errordlg(err.message, 'Error');
        if strcmp(questAnswer, 'Close')
            notOk = 0;  % exit the while loop
            return;
        end
    end
end
waitbar(0.8, wb);
logText = sprintf('Exp: %s;', logText, expressionText);

% convert to the destination class
if useUnit32
    switch classId
        case 'uint8'
            A = uint8(A);
        case 'uint16'
            A = uint16(A);
        case 'unit32'
            A = uint32(A);
    end
    logText = sprintf('%s ->%s;', logText, classId);
end

if destId == obj.mibModel.Id
    obj.mibModel.mibDoBackup('image', 1);
    getDataOptions.replaceDatasetSwitch = 1;    % force to replace dataset
    %getDataOptions.id = destId;
    obj.mibModel.setData4D('image', A, 4, 0, getDataOptions);
    obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(logText);
    notify(obj.mibModel, 'newDataset');
else
    obj.mibModel.I{destId} = mibImage(A, obj.mibModel.getImageProperty('meta'));

    eventdata = ToggleEventData(destId);
    notify(obj.mibModel, 'newDataset', eventdata);
    obj.mibModel.I{destId}.updateImgInfo(logText);
end
waitbar(1, wb);
obj.updateGuiWidgets();
delete(wb);
obj.plotImage();
end

function [answer, selIndex] = menuImageToolsArithmeticsGetParameters(mibPath, prompts, defAns, dlgTitle, options)
[answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
end