function mibChangeLayerSlider_Callback(obj)
% function mibChangeLayerSlider_Callback(obj)
% A callback function for mibGUI.mibChangeLayerSlider. Responsible for showing next or previous slice of the dataset
%
% Parameters:
% 
% Return values:
%

% Copyright (C) 09.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

%t1 = tic;

value = obj.mibView.handles.mibChangeLayerSlider.Value;
value_str = sprintf('%.0f',value);
obj.mibView.handles.mibChangeLayerEdit.String = value_str;
value = str2double(value_str);
if obj.mibModel.I{obj.mibModel.Id}.orientation == 1 %'xz'
    obj.mibModel.I{obj.mibModel.Id}.slices{1} = [value, value];
elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 2 %'yz'
    obj.mibModel.I{obj.mibModel.Id}.slices{2} = [value, value];
elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 4 %'yx'
    % update label text for the image view panel
    if isKey(obj.mibModel.I{obj.mibModel.Id}.meta, 'SliceName')
        % use getfield to get exact value as suggested by Ian M. Garcia in
        % http://stackoverflow.com/questions/3627107/how-can-i-index-a-matlab-array-returned-by-a-function-without-first-assigning-it
        layerNamePrevious = getfield(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'), ...
            {min([obj.mibModel.I{obj.mibModel.Id}.slices{4}(1) numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'))])}); %#ok<GFLD>
        layerNameNext = getfield(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'), ...
            {min([value numel(obj.mibModel.I{obj.mibModel.Id}.meta('SliceName'))])}); %#ok<GFLD>
        if strcmp(layerNamePrevious{1}, layerNameNext{1}) == 0  % update label
            strVal1 = 'Image View    >>>>>    ';
            [~, fn, ext] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            strVal2 = sprintf('%s%s    >>>>>    %s', fn, ext, layerNameNext{1});
            obj.mibView.handles.mibViewPanel.Title = [strVal1 strVal2];    
        end
    end
     obj.mibModel.I{obj.mibModel.Id}.slices{4} = [value, value];
end

% % add a label to the image view panel
% if isKey(handles.Img{handles.Id}.I.img_info, 'SliceName') && handles.Img{handles.Id}.I.orientation == 4   %'yx'
%     % from http://stackoverflow.com/questions/3627107/how-can-i-index-a-matlab-array-returned-by-a-function-without-first-assigning-it
%     layerName = builtin('_paren', handles.Img{handles.Id}.I.img_info('SliceName'), current); 
%     set(handles.imagePanel, 'Title', sprintf('Image View   %s    >>>>>    %s', handles.Img{handles.Id}.I.img_info('Filename'), layerName{1}));
% else
%     set(handles.imagePanel, 'Title', sprintf('Image View   %s', handles.Img{handles.Id}.I.img_info('Filename')));    
% end

%im_browser_winMouseMotionFcn(handles.im_browser, NaN, handles);
obj.plotImage(0);
notify(obj.mibModel, 'changeSlice');   % notify the controller about changed slice
%unFocus(hObject);   % remove focus from hObject
%toc(t1)
end