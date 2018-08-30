function volrenToolbarSwitch_ClickedCallback(obj, parameter)
% function volrenToolbarSwitch_ClickedCallback(obj, parameter)
% a callback for press of obj.mibView.volrenToolbarSwitch in the toolbar
% of MIB
%
% Parameters:
% parameter: a string 
% @li 'toolbar' - specify that the function was triggered by pressing a
% dedicated button in MIB toolbar

% Copyright (C) 24.01.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% Updates
% 

% check for the virtual stacking mode and return
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1 && strcmp(obj.mibView.handles.volrenToolbarSwitch.State, 'on') 
    toolname = 'rendering of datasets is';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode!\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    obj.mibView.handles.volrenToolbarSwitch.State = 'off';
    return;
end

if nargin < 2; parameter = ''; end

if strcmp(parameter, 'toolbar') && strcmp(obj.mibView.handles.volrenToolbarSwitch.State, 'on')
    getDataOptions.blockModeSwitch = 0;
    [h,w,c,z] = obj.mibModel.getImageMethod('getDatasetDimensions', NaN, 'image', 4, 0, getDataOptions);
    if h*w*c*z > 250000000
        button = questdlg(sprintf('!!! Warning !!!\n\nThe volume rendering large datasets is very slow\nAre you sure that you want to proceed further?'),'Volume Rendering','I am sure, please render','Cancel','Cancel');     
        if strcmp(button, 'Cancel')
            obj.mibView.handles.volrenToolbarSwitch.State = 'off';
            obj.mibModel.I{obj.mibModel.Id}.volren.show = 0;
            return;
        end
    end
end

if strcmp(obj.mibView.handles.volrenToolbarSwitch.State, 'on')
    obj.mibView.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.volren_WindowButtonDownFcn());
    obj.mibView.gui.WindowKeyPressFcn = [];  % turn off callback for the keys during the volren
    obj.mibView.gui.WindowButtonMotionFcn = (@(hObject, eventdata, handles) obj.volren_winMouseMotionFcn());   
    obj.mibView.gui.WindowScrollWheelFcn = (@(hObject, eventdata, handles) obj.volren_scrollWheelFcn(eventdata));   % moved from plotImage
    
    %if isempty(obj.mibModel.I{obj.mibModel.Id}.volren.previewImg)
%         R = [0 0 0];
%         S = [1*obj.mibModel.I{obj.mibModel.Id}.magFactor,...
%              1*obj.mibModel.I{obj.mibModel.Id}.magFactor,...
%              1*obj.mibModel.I{obj.mibModel.Id}.pixSize.x/obj.mibModel.I{obj.mibModel.Id}.pixSize.z*obj.mibModel.I{obj.mibModel.Id}.magFactor];  
%         T = [5 5 5];
%         obj.mibModel.I{obj.mibModel.Id}.volren.viewer_matrix = makeViewMatrix(R, S, T);
    %end
    
    if isempty(obj.mibModel.I{obj.mibModel.Id}.volren.previewImg)
        obj.mibModel.I{obj.mibModel.Id}.volren.previewScale = 256/max([obj.mibModel.I{obj.mibModel.Id}.width obj.mibModel.I{obj.mibModel.Id}.height]);
        getDataOptions.blockModeSwitch = 0;
        
        R = [0 0 0];
        S = [1*obj.mibModel.I{obj.mibModel.Id}.magFactor,...
            1*obj.mibModel.I{obj.mibModel.Id}.magFactor,...
            1*obj.mibModel.I{obj.mibModel.Id}.pixSize.x/obj.mibModel.I{obj.mibModel.Id}.pixSize.z*obj.mibModel.I{obj.mibModel.Id}.magFactor];  
        T = [0 0 0];
        obj.mibModel.I{obj.mibModel.Id}.volren.viewer_matrix = makeViewMatrix(R, S, T);
        
        resizeOpt.imgType = '4D';
        resizeOpt.method = 'nearest';
        obj.mibModel.I{obj.mibModel.Id}.volren.previewImg = mibResize3d(cell2mat(obj.mibModel.getData3D('image', NaN, 4, 0, getDataOptions)), ...
            obj.mibModel.I{obj.mibModel.Id}.volren.previewScale, resizeOpt);
    end
    obj.mibModel.I{obj.mibModel.Id}.volren.showFullRes = 1;
    obj.mibModel.I{obj.mibModel.Id}.volren.show = 1;
else
    obj.mibView.gui.WindowButtonDownFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowButtonDownFcn());
    obj.mibView.gui.WindowKeyPressFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowKeyPressFcn(hObject, eventdata)); % turn ON callback for the keys
    obj.mibView.gui.WindowScrollWheelFcn = (@(hObject, eventdata, handles) obj.mibGUI_ScrollWheelFcn(eventdata));
    obj.mibView.gui.WindowButtonMotionFcn = (@(hObject, eventdata, handles) obj.mibGUI_WinMouseMotionFcn());  
    obj.mibModel.I{obj.mibModel.Id}.volren.show = 0;
end

% plot image when the function is triggered from the toolbar
if strcmp(parameter, 'toolbar')
    obj.mibView.imh.CData = [];
    obj.plotImage();
end