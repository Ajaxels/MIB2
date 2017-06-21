classdef mibImageAdjController < handle
    % @type mibImageAdjController class is resposnible for showing the
    % dataset adjustment window, available from MIB->View settings
    % panel->Display
    
	% Copyright (C) 20.01.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
	% 
	% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
	%
	% Updates
	% 
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback2(obj, src, evnt)
            switch evnt.EventName
                case 'changeSlice'     
                    if obj.listener{3}.Enabled
                        obj.updateHist();
                    end
                case 'changeTime'
                    if obj.listener{4}.Enabled
                        obj.updateHist();
                    end     
                case 'updateGuiWidgets'
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibImageAdjController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibImageAdjustmentGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            obj.updateWidgets();
            
            % add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));
            obj.listener{2} = addlistener(obj.mibModel, 'changeSlice', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));
            obj.listener{3} = addlistener(obj.mibModel, 'changeTime', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));
            obj.listener{2}.Enabled = 0;    % this listener is enabled via obj.autoHistCheck_Callback
            obj.listener{3}.Enabled = 0;    % this listener is enabled via obj.autoHistCheck_Callback
            
            if strcmp(obj.mibModel.I{obj.mibModel.Id}.meta('ColorType'), 'indexed')
                warndlg(sprintf('!!! Warning !!!\n\nThe indexed images can not be adjusted!\nPlease convert them to greyscale or GRB color:\nMenu->Image->Mode->'), 'Indexed colors', 'modal');
            end
        end
        
        function closeWindow(obj)
            % closing mibImageAdjController window
            if isvalid(obj.View.gui)
                delete(obj.View.gui);   % delete mibImageAdjController window
            end
            
            % delete listeners, otherwise they stay after deleting of the
            % controller
            for i=1:numel(obj.listener)
                delete(obj.listener{i});
            end
            
            notify(obj, 'closeEvent');      % notify mibController that this child window is closed
        end
        
        function updateWidgets(obj, colorChannelSelection)
            % function updateWidgets(obj, colorChannelSelection)
            % update widgets of the window
            
            if nargin < 2
                colorChannelSelection = obj.View.handles.colorChannelCombo.Value;
            end
           
            obj.View.handles.colorChannelCombo.Value = 1;   % the colors of the popup menu are updated in the updateHist function
            obj.colorChannelCombo_Callback();
            if obj.mibModel.getImageProperty('colors') >= colorChannelSelection
                obj.View.handles.colorChannelCombo.Value = colorChannelSelection;
            end
            
            % when only one color channel is shown select it
            slices = obj.mibModel.getImageProperty('slices');
            if numel(slices{3}) == 1
                colorChannelSelection = slices{3};
                obj.View.handles.colorChannelCombo.Value = colorChannelSelection;
            else
                if obj.mibModel.getImageProperty('colors') >= colorChannelSelection
                    obj.View.handles.colorChannelCombo.Value = colorChannelSelection;
                end
            end
            obj.updateSliders();
        end
        
        function colorChannelCombo_Callback(obj)
            % function colorChannelCombo_Callback(obj)
            % a callback for selection in
            % obj.View.handles.colorChannelCombo of a new color channel
            
            val = obj.View.handles.colorChannelCombo.Value;
            obj.View.handles.adjustPanel.Title = sprintf('Adjust channel %d', val);
            obj.updateSliders();
        end
        
        
        function minSlider_Callback(obj)
            % function minSlider_Callback(obj)
            % a callback for obj.View.handles.minSlider
            
            channel = obj.View.handles.colorChannelCombo.Value;
            current_value = obj.View.handles.minSlider.Value;
            viewPort = obj.mibModel.getImageProperty('viewPort');
            max_val = viewPort.max(channel);
            if current_value >= max_val
                obj.View.handles.minSlider.Value = max_val-3;
                current_value = max_val-3;
            end
            obj.View.handles.maxSlider.Min = current_value;
            obj.View.handles.minEdit.String = num2str(current_value);
            obj.updateSettings();
            obj.updateHist();
            notify(obj.mibModel, 'plotImage');
        end
        
        function minEdit_Callback(obj)
            % function minEdit_Callback(obj)
            % a callback for update of obj.View.handles.minEdit
            
            channel = obj.View.handles.colorChannelCombo.Value;
            val = str2double(obj.View.handles.minEdit.String);
            if isnan(val)
                obj.View.handles.minEdit.String = num2str(obj.mibModel.I{obj.mibModel.Id}.viewPort.min(channel));
                return;
            end
            
            if val >= obj.mibModel.I{obj.mibModel.Id}.viewPort.max(channel)
                obj.mibModel.I{obj.mibModel.Id}.viewPort.min(channel) = obj.mibModel.I{obj.mibModel.Id}.viewPort.max(channel) - 1;
            elseif val < 0
                obj.mibModel.I{obj.mibModel.Id}.viewPort.min(channel) = 0;
            else
                obj.mibModel.I{obj.mibModel.Id}.viewPort.min(channel) = val;
            end
            
            obj.View.handles.minSlider.Value = obj.mibModel.I{obj.mibModel.Id}.viewPort.min(channel);
            obj.minSlider_Callback();
        end
        
        function maxSlider_Callback(obj)
            % function maxSlider_Callback(obj)
            % a callback for obj.View.handles.maxSlider update
            
            channel = obj.View.handles.colorChannelCombo.Value;
            current_value = obj.View.handles.maxSlider.Value;
            min_val = obj.mibModel.I{obj.mibModel.Id}.viewPort.min(channel);
            if current_value <= min_val
                obj.View.handles.maxSlider.Value = min_val+3;
                current_value = min_val + 3;
            end
            obj.View.handles.minSlider.Max = current_value;
            obj.updateSettings();
            notify(obj.mibModel, 'plotImage');
            obj.View.handles.maxEdit.String = num2str(obj.mibModel.I{obj.mibModel.Id}.viewPort.max(channel));
            obj.updateHist();
        end
        
        function maxEdit_Callback(obj)
            % function maxEdit_Callback(obj)
            % a callback for obj.View.handles.maxEdit update
            
            channel = obj.View.handles.colorChannelCombo.Value;
            val = str2double(obj.View.handles.maxEdit.String);
            if isnan(val)
                obj.View.handles.maxEdit.String = num2str(obj.mibModel.I{obj.mibModel.Id}.viewPort.max(channel));
                return;
            end
            if val <= obj.mibModel.I{obj.mibModel.Id}.viewPort.min(channel)
                obj.mibModel.I{obj.mibModel.Id}.viewPort.max(channel) = obj.mibModel.I{obj.mibModel.Id}.viewPort.min(channel) + 1;
            elseif val >= double(intmax(class(obj.mibModel.I{obj.mibModel.Id}.img{1})))
                obj.mibModel.I{obj.mibModel.Id}.viewPort.max(channel) = double(intmax(class(obj.mibModel.I{obj.mibModel.Id}.img{1})));
            else
                obj.mibModel.I{obj.mibModel.Id}.viewPort.max(channel) = val;
            end
            obj.View.handles.maxSlider.Value = obj.mibModel.I{obj.mibModel.Id}.viewPort.max(channel);
            obj.maxSlider_Callback();
        end
        
        function gammaSlider_Callback(obj)
            % function gammaSlider_Callback(obj)
            % a callback for obj.View.handles.gammaSlider update
            
            channel = obj.View.handles.colorChannelCombo.Value;
            obj.updateSettings();
            notify(obj.mibModel, 'plotImage');
            obj.View.handles.gammaEdit.String = num2str(obj.mibModel.I{obj.mibModel.Id}.viewPort.gamma(channel));
            obj.updateHist();
        end
        
        function gammaEdit_Callback(obj)
            % function gammaEdit_Callback(obj)
            % a callback for obj.View.handles.gammaEdit update
            
            channel = obj.View.handles.colorChannelCombo.Value;
            val = str2double(obj.View.handles.gammaEdit.String);
            if isnan(val)
                obj.View.handles.gammaEdit.String = num2str(obj.mibModel.I{obj.mibModel.Id}.viewPort.gamma(channel));
                return;
            end
            if val < 0.1
                obj.mibModel.I{obj.mibModel.Id}.viewPort.gamma(channel) = 0.1;
            elseif val > 5
                obj.mibModel.I{obj.mibModel.Id}.viewPort.gamma(channel) = 5;
            else
                obj.mibModel.I{obj.mibModel.Id}.viewPort.gamma(channel) = val;
            end
            obj.View.handles.gammaSlider.Value = obj.mibModel.I{obj.mibModel.Id}.viewPort.gamma(channel);
            obj.gammaSlider_Callback();
        end
        
        function mibImageAdjustmentGUI_WindowButtonDownFcn(obj)
            % function mibImageAdjustmentGUI_WindowButtonDownFcn(obj)
            % --- Executes on mouse press over figure background, over a disabled or
            % --- inactive control, or over an axes background.
            
            xy = obj.View.handles.imHist.CurrentPoint;
            seltype = obj.View.gui.SelectionType;
            
            ylims = obj.View.handles.imHist.YLim;
            if xy(1,2) > ylims(2)+diff(ylims)*.2; return; end; % mouse click away from histogram
            
            switch seltype
                case 'normal'       % set the min limit
                    if xy(1,1) >= str2double(obj.View.handles.maxEdit.String)-3; return; end;
                    obj.View.handles.minEdit.String = num2str(xy(1,1));
                    obj.minEdit_Callback();
                case 'alt'          % set the max limit
                    if xy(1,1) <= str2double(obj.View.handles.minEdit.String)+3; return; end;
                    obj.View.handles.maxEdit.String = num2str(xy(1,1));
                    obj.maxEdit_Callback();
            end
        end
        
        % --- Executes on button press in findMinBtn.
        function findMinBtn_Callback(obj)
            % function findMinBtn_Callback(obj)
            % a callback for obj.View.handles.findMinBtn update; find a
            % minimal intensity point for the dataset
            colorCh = obj.View.handles.colorChannelCombo.Value;
            minval = min(min(min(min(obj.mibModel.I{obj.mibModel.Id}.img{1}(:,:,colorCh,:,:)))));
            obj.View.handles.minEdit.String = num2str(minval);
            obj.minEdit_Callback();
        end
        
        % --- Executes on button press in findMaxBtn.
        function findMaxBtn_Callback(obj)
            % function findMaxBtn_Callback(obj)
            % a callback for obj.View.handles.findMaxBtn update; find a
            % maximal intensity point for the dataset
            colorCh = obj.View.handles.colorChannelCombo.Value;
            maxval = max(max(max(max(obj.mibModel.I{obj.mibModel.Id}.img{1}(:,:,colorCh,:,:)))));
            obj.View.handles.maxEdit.String = num2str(maxval);
            obj.maxEdit_Callback();
        end
        
        function minSlider_ButtonDownFcn(obj)
            % function minSlider_ButtonDownFcn(obj)
            % a callback for button press over obj.View.handles.minSlider
            obj.View.handles.minSlider.Value = 0;
            obj.minSlider_Callback();
        end
        
        function maxSlider_ButtonDownFcn(obj)
            % function maxSlider_ButtonDownFcn(obj)
            % a callback for button press over obj.View.handles.maxSlider
            obj.View.handles.maxSlider.Value = double(intmax(class(obj.mibModel.I{obj.mibModel.Id}.img{1})));
            obj.maxSlider_Callback();
        end
        
        function updateSettings(obj)
            % function updateSettings(obj)
            % update min, max, and gamma fields of obj.mibModel.I{obj.mibModel.Id}.viewPort with parameters from sliders/editboxes
            
            slices = obj.mibModel.getImageProperty('slices');
            if obj.View.handles.linkChannelsCheck.Value == 1
                channel = slices{3};
            else
                channel = obj.View.handles.colorChannelCombo.Value;
            end
            obj.mibModel.I{obj.mibModel.Id}.viewPort.min(channel) = obj.View.handles.minSlider.Value;
            obj.mibModel.I{obj.mibModel.Id}.viewPort.max(channel) = obj.View.handles.maxSlider.Value;
            obj.mibModel.I{obj.mibModel.Id}.viewPort.gamma(channel) = obj.View.handles.gammaSlider.Value;
        end
        
        function updateHist(obj)
            % update image histogram
            channel = obj.View.handles.colorChannelCombo.Value;
            logscale = obj.View.handles.logViewCheck.Value;
            
            options.blockModeSwitch = 1;
            img = cell2mat(obj.mibModel.getData2D('image', NaN, NaN, channel, options));
            
            % histcounts is much faster than imhist
            if isa(img, 'uint8')
                x = 0:255;
                counts = histcounts(img(:), x);
            elseif isa(img, 'uint16')
                x = 0:256:65535;
                counts = histcounts(img(:), x);
            else
                %error('Fix here');
                %x = 0:256*256:intmax('uint32');
                %[counts, x] = imhist(img(:), x);
                [counts,x] = histcounts(img(:),255);
             end
            
            %bar(obj.View.handles.imHist, x(counts>0), counts(counts>0));
            area(obj.View.handles.imHist, x(counts>0), counts(counts>0), 'linestyle', 'none');
            %stem(obj.View.handles.imHist,x(counts>0),counts(counts>0), 'Marker', 'none');
            
            viewPort = obj.mibModel.getImageProperty('viewPort');
            
            obj.View.handles.imHist.XLim = ...
                [min([viewPort.min(channel)+1 intmax(class(obj.mibModel.I{obj.mibModel.Id}.img{1}))-3]) ...
                 max([viewPort.max(channel)-1 2]) ];
            if logscale
                obj.View.handles.imHist.YScale = 'Log';
            else
                obj.View.handles.imHist.YScale = 'Linear';
            end
            
            % update colors in the popup menu
            col_channels = cell([obj.mibModel.getImageProperty('colors'), 1]);
            selectedColorChannel = obj.View.handles.colorChannelCombo.Value;
            
            for col_ch=1:obj.mibModel.getImageProperty('colors')
                if isnan(obj.mibModel.displayedLutColors(col_ch,1)) % when 'X'
                    colorText = 'rgb(0, 0, 0)';
                else
                    colorText = sprintf('rgb(%.0f, %.0f, %.0f)', ...
                        obj.mibModel.displayedLutColors(col_ch,1)*255, ...
                        obj.mibModel.displayedLutColors(col_ch,2)*255,...
                        obj.mibModel.displayedLutColors(col_ch,3)*255);
                end
                
                if col_ch == selectedColorChannel
                    if isnan(obj.mibModel.displayedLutColors(col_ch,1)) % when 'X'
                        selectedColor = [0, 0, 0];
                    else
                        selectedColor = obj.mibModel.displayedLutColors(col_ch, :);
                    end
                end
                col_channels{col_ch} = sprintf('<html><font color=''%s''>Channel %d</Font></html>', colorText, col_ch);
            end
            obj.View.handles.colorChannelCombo.String = col_channels;
            
            % update colorChannelPanel1
            obj.View.handles.colorChannelPanel1.BackgroundColor = selectedColor;
        end
        
        function updateSliders(obj)
            % update sliders in the window
            channel = obj.View.handles.colorChannelCombo.Value;
            viewPort = obj.mibModel.getImageProperty('viewPort');
            min_val = viewPort.min(channel);
            max_val = viewPort.max(channel);
            gamma = viewPort.gamma(channel);
            
            obj.View.handles.minSlider.Min = 0;
            obj.View.handles.minSlider.Max = max_val;
            obj.View.handles.minSlider.Value = min_val;
            obj.View.handles.minEdit.String = num2str(min_val);
            
            obj.View.handles.maxSlider.Min = min_val;
            obj.View.handles.maxSlider.Max = double(intmax(class(obj.mibModel.I{obj.mibModel.Id}.img{1} )));
            obj.View.handles.maxSlider.Value = max_val;
            obj.View.handles.maxEdit.String = num2str(max_val);
            
            obj.View.handles.gammaSlider.Value = gamma;
            obj.View.handles.gammaEdit.String = num2str(gamma);
            
            obj.updateHist();
        end
        
        function adjHelpBtn_Callback(obj)
            global mibPath;
            
            % start help page
            if isdeployed
                web(fullfile(mibPath, 'techdoc/html/ug_panel_adjustments.html'), '-helpbrowser');
            else
                web(fullfile(mibPath, 'techdoc/html/ug_panel_adjustments.html'), '-helpbrowser');
            end
        end
        
        % --- Executes on button press in applyBtn.
        function applyBtn_Callback(obj)
            % function applyBtn_Callback(obj)
            % a callback for press of obj.View.handles.applyBtn to
            % recalculate intensities for the dataset
            
            res = questdlg(sprintf('You are going to recalculate intensities of the original image by stretching!\n\nAre you sure?'),'!!! Warning !!!','Proceed','Cancel','Cancel');
            if strcmp(res,'Cancel'); return; end;
            
            wb = waitbar(0,'Please wait...','Name','Adjusting...');
            
            maxZ = obj.mibModel.getImageProperty('depth');
            maxT = obj.mibModel.getImageProperty('time');
            if maxT == 1; obj.mibModel.mibDoBackup('image', 1); end;
            max_int = double(intmax(class( obj.mibModel.I{obj.mibModel.Id}.img{1} )));
            channel = obj.View.handles.colorChannelCombo.Value;
            viewPort = obj.mibModel.getImageProperty('viewPort');
            waitbarStep = round(maxT*maxZ/20);
            for t=1:maxT
                for i=1:maxZ
                    obj.mibModel.I{obj.mibModel.Id}.img{1}(:,:,channel,i,t) = imadjust(obj.mibModel.I{obj.mibModel.Id}.img{1}(:,:,channel,i,t),...
                        [viewPort.min(channel)/max_int viewPort.max(channel)/max_int],...
                        [0 1], viewPort.gamma(channel));
                    if mod(i, waitbarStep) == 0; waitbar(i/(maxZ*maxT), wb); end;   % update waitbar
                end
            end
            
            log_text = ['ContrastGamma: Channel:' num2str(channel) ', Min:' num2str(viewPort.min(channel)) ', Max: ' num2str(viewPort.max(channel)) ,...
                ', Gamma: ' num2str(viewPort.gamma(channel))];
            obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(log_text);
            obj.mibModel.I{obj.mibModel.Id}.viewPort.min(channel) = 0;
            obj.mibModel.I{obj.mibModel.Id}.viewPort.max(channel) = max_int;
            obj.mibModel.I{obj.mibModel.Id}.viewPort.gamma(channel) = 1;
            
            obj.updateSliders();
            delete(wb);
            notify(obj.mibModel, 'plotImage');
        end
        
        % --- Executes on button press in stretchCurrent.
        function stretchCurrent_Callback(obj)
            % function stretchCurrent_Callback(obj)
            % a callback for press of obj.View.handles.stretchCurrent to recalculate intensities for the currently shown slice of the dataset
            obj.mibModel.mibDoBackup('image', 0);
            max_int = double(intmax(class( obj.mibModel.I{obj.mibModel.Id}.img{1} )));
            channel = obj.View.handles.colorChannelCombo.Value;
            
            getDataOptions.blockModeSwitch = 0;
            slice = cell2mat(obj.mibModel.getData2D('image', NaN, NaN, channel, getDataOptions));
            viewPort = obj.mibModel.getImageProperty('viewPort');
            
            slice = imadjust(slice,...
                [viewPort.min(channel)/max_int viewPort.max(channel)/max_int],...
                [0 1], viewPort.gamma(channel));
            obj.mibModel.setData2D('image', {slice}, NaN, NaN, channel, getDataOptions);
            obj.mibModel.I{obj.mibModel.Id}.viewPort.min(channel) = 0;
            obj.mibModel.I{obj.mibModel.Id}.viewPort.max(channel) = max_int;
            obj.mibModel.I{obj.mibModel.Id}.viewPort.gamma(channel) = 1;
            obj.updateSliders();
            notify(obj.mibModel, 'plotImage');
        end
        
        function autoHistCheck_Callback(obj)
            val = obj.View.handles.autoHistCheck.Value;
            if val == 1
                obj.listener{2}.Enabled = 1;     % enable listener for change of obj.mibModel.I{obj.mibModel.Id}.slices
                obj.listener{3}.Enabled = 1;     % enable listener for change of obj.mibModel.I{obj.mibModel.Id}.slices
                obj.updateHist();
            else
                obj.listener{2}.Enabled = 0;
                obj.listener{3}.Enabled = 0;
            end
        end
        
    end
end