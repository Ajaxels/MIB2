function menuImageMode_Callback(obj, hObject, BatchOpt)
% function menuImageMode_Callback(obj, hObject, BatchOpt)
% callback to the Menu->Image->Mode, convert image to different formats
%
% Parameters:
% hObject: handle to the selected menu entry
% BatchOpt: a structure for batch processing mode

% Copyright (C) 03.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 12.03.2019, IB updated for the batch mode

% check for the virtual stacking mode and close the controller
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    toolname = 'image conversion tools';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s are not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

PossibleOptions = {'Grayscale', 'RGB Color', 'HSV Color', 'Indexed', '8 bit', '16 bit', '32 bit'};

if nargin == 3
    if isstruct(BatchOpt) == 0
        if isnan(BatchOpt)     % when varargin{3} == NaN return possible settings
            BatchOpt = struct();
            BatchOpt.Target = {'Grayscale'};
            BatchOpt.Target{2} = PossibleOptions;
            BatchOpt.mibBatchSectionName = 'Menu Image';
            BatchOpt.mibBatchActionName = 'Mode';
            % trigger syncBatch event to send BatchOptOut to mibBatchController 
            eventdata = ToggleEventData(BatchOpt);
            notify(obj.mibModel, 'syncBatch', eventdata);
        else
            errordlg(sprintf('A structure as the 3rd parameter is required!'));
        end
        return;
    end
end

if nargin < 3
    BatchOpt = struct();
    switch get(hObject,'tag')
        case 'menuImageGrayscale'
            BatchOpt.Target = {'Grayscale'};
        case 'menuImageRGBColor'
            BatchOpt.Target = {'RGB Color'};
        case 'menuImageHSVColor'
            BatchOpt.Target = {'HSV Color'};
        case 'menuImageIndexed'
            BatchOpt.Target = {'Indexed'};
        case 'menuImage8bit'
            BatchOpt.Target = {'8 bit'};
        case 'menuImage16bit'
            BatchOpt.Target = {'16 bit'};
        case 'menuImage32bit'
            BatchOpt.Target = {'32 bit'};
    end
end
if obj.mibModel.getImageProperty('time') < 2; obj.mibModel.mibDoBackup('image', 1); end    

switch BatchOpt.Target{1}
    case 'Grayscale'
        if strcmp(obj.mibModel.I{obj.mibModel.Id}.meta('ColorType'), 'truecolor') && obj.mibModel.I{obj.mibModel.Id}.colors > 3
            button = questdlg(sprintf('!!! Attention !!!\n\nDirect conversion of the multichannel image to greyscale is not possible\nHowever it is possible to perform conversion using the LUT colors'),'Multiple color channels','Convert','Cancel','Cancel');
            if strcmp(button, 'Cancel'); return; end
            if obj.mibModel.useLUT == 0
                errordlg('Please make sure that the LUT checkbox in the View settings panel is checked!','LUT is not selected');
                return;
            end
            obj.mibModel.useLUT = 0;
        end
        obj.mibModel.I{obj.mibModel.Id}.convertImage('grayscale');
    case 'RGB Color'
        obj.mibModel.I{obj.mibModel.Id}.convertImage('truecolor');
    case 'HSV Color'
        obj.mibModel.I{obj.mibModel.Id}.convertImage('hsvcolor');
    case 'Indexed'
        if strcmp(obj.mibModel.I{obj.mibModel.Id}.meta('ColorType'), 'truecolor') && obj.mibModel.I{obj.mibModel.Id}.colors > 3
            button = questdlg(sprintf('!!! Attention !!!\n\nDirect conversion of the multichannel image to greyscale is not possible\nHowever it is possible to perform conversion using the LUT colors'),...
                'Multiple color channels', 'Convert', 'Cancel', 'Cancel');
            if strcmp(button, 'Cancel'); return; end
            if obj.mibModel.useLUT == 0
                errordlg('Please make sure that the LUT checkbox in the View settings panel is checked!','LUT is not selected');
                return;
            end
            obj.mibModel.useLUT = 0;
        end
        obj.mibModel.I{obj.mibModel.Id}.convertImage('indexed');
    case '8 bit'
        obj.mibModel.I{obj.mibModel.Id}.convertImage('uint8');
    case '16 bit'
        obj.mibModel.I{obj.mibModel.Id}.convertImage('uint16');
    case '32 bit'
        obj.mibModel.I{obj.mibModel.Id}.convertImage('uint32');
end
% trigger syncBatch event to send BatchOptOut to mibBatchController 
% add position of the Plugin in the Menu Plugins
BatchOpt.mibBatchSectionName = 'Menu Image';
BatchOpt.mibBatchActionName = 'Mode';
BatchOpt.Target{2} = PossibleOptions;
eventdata = ToggleEventData(BatchOpt);
notify(obj.mibModel, 'syncBatch', eventdata);

obj.updateGuiWidgets();
obj.plotImage();
end