function menuFileExportImage_Callback(obj, parameter)
% function menuFileExportImage_Callback(obj, parameter)
% a callback to Menu->File->Export Image, export image and
% meta-data from MIB to the main Matlab workspace or Imaris
%
% Parameters:
% parameter: [@em optional] a string that defines image source:
% - 'matlab', [default] main workspace of Matlab
% - 'imaris', to imaris, requires ImarisXT

% Copyright (C) 25.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%

if nargin < 2;     parameter = 'matlab'; end

colortype = obj.mibModel.I{obj.mibModel.Id}.meta('ColorType');
switch parameter
    case 'matlab'
        title = 'Input variables for export';
        if strcmp(colortype,'indexed')
            defAns = {'I','cmap'};
            prompt = {'Variable for the image:'; 'Variable for the colormap:'};
        else
            defAns = {'I'};
            prompt = {'Variable for the image:'};
        end
        
        answer = mibInputMultiDlg({obj.mibPath}, prompt, defAns, title);
        if isempty(answer); return; end
        
        if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 0
            assignin('base', answer{1}, obj.mibModel.I{obj.mibModel.Id}.img{1});
        else
            img = cell2mat(obj.mibModel.getData4D('image', 4));
            assignin('base', answer{1}, img);
        end
        I_meta = containers.Map(keys(obj.mibModel.I{obj.mibModel.Id}.meta), values(obj.mibModel.I{obj.mibModel.Id}.meta));  % create a copy of the containers.Map
        assignin('base',[answer{1} '_meta'], I_meta);
        disp(['Image export: created [' answer{1} '] and [' [answer{1} '_meta]'] ' variables in the Matlab workspace']);
        if numel(answer) == 2
            assignin('base', answer{2}, obj.mibModel.I{obj.mibModel.Id}.meta('Colormap'));
            disp(['Image export: created variable ' answer{2} ' in the Matlab workspace']);
        end
    case 'imaris'
        % get color channel
        options.lutColors = obj.mibModel.displayedLutColors;   % get colors for the color channels
        obj.mibModel.connImaris = mibSetImarisDataset(obj.mibModel.I{obj.mibModel.Id}, obj.mibModel.connImaris, options);
end
end