function mibFijiExport(obj)
% function mibFijiExport(obj)
% Export currently open dataset to Fiji
%
% Parameters:
% 
% Return values
%

% Copyright (C) 02.03.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

global mibPath;
% define type of the dataset
datasetTypeValue = obj.mibView.handles.mibFijiConnectTypePopup.Value;
datasetTypeList = obj.mibView.handles.mibFijiConnectTypePopup.String;
datasetType = datasetTypeList{datasetTypeValue};

if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    if ismember(datasetType, {'model','mask','selection'})
        toolname = datasetType;
        warndlg(sprintf('!!! Warning !!!\n\nIt is not yet possible to export %s in the virtual stacking mode!\nPlease switch to the memory-resident mode and try again', ...
            toolname), 'Not implemented');
        return;
    end
end

% check for MIJ
if exist('MIJ','class') == 8
    if ~isempty(ij.gui.Toolbar.getInstance)
        ij_instance = char(ij.gui.Toolbar.getInstance.toString);
        % -> ij.gui.Toolbar[canvas1,3,41,548x27,invalid]
        if numel(strfind(ij_instance, 'invalid')) > 0    % instance already exist, but not shown
            Miji_wrapper(true);     % wrapper to Miji.m file
        end
    else
        Miji_wrapper(true);     % wrapper to Miji.m file
    end
else
   Miji_wrapper(true);     % wrapper to Miji.m file
end

filename = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
[~, fn] = fileparts(filename);

roiNo = obj.mibModel.I{obj.mibModel.Id}.selectedROI;
% cancel if more than one roi selected
if roiNo > -1 && numel(roiNo) > 1
    msgbox('Please select ROI from the ROI list or unselect the ROI mode!','Select ROI!','warn','modal');
    return;
end

answer = mibInputDlg({mibPath}, 'Please name for the dataset:', 'Set name', fn);
if isempty(answer); return; end

pause(0.1);     % for some strange reason have to put pause here, otherwise everything is freezing...

options.roiId = roiNo;
options.blockModeSwitch = 0;

img = obj.mibModel.getData3D(datasetType, NaN, 4, NaN, options);
if size(img{1}, 3) == 1; img{1} = squeeze(img{1}); end

if isa(img{1}, 'uint16')
    if ndims(img{1}) == 4
        errordlg(sprintf('Export to Fiji:\nIt is not possible to export 16 bit Z-stack to Fiji\n\nThe export is implemented for 8 bit Z-stacks or for 16 bit individual images'), 'Export to Fiji', 'modal');
        return;
        %img{1} = permute(img{1}, [1 2 4 3]);
        %MIJ.createColor(answer{1}, img{1}, 1);
    %elseif strcmp(handles.Img{handles.Id}.I.img_info('ColorType'),'truecolor')
    %    MIJ.createColor(answer{1}, img{1}, 1);
    else
        imp = MIJ.createImage(answer{1}, img{1}, 0);
        imp.show
    end  
else
    if ndims(img{1}) == 4
        img{1} = permute(img{1}, [1 2 4 3]);
        MIJ.createColor(answer{1}, img{1}, 1);
    elseif strcmp(obj.mibModel.I{obj.mibModel.Id}.meta('ColorType'),'truecolor')
        MIJ.createColor(answer{1}, img{1}, 1);
    else
        imp = MIJ.createImage(answer{1}, img{1}, 0);
        imp.show;
    end    
end
end
