classdef mibBoundingBoxController < handle
    % @type mibBoundingBoxController class is resposnible for display of
    % the Bounding Box window, available from MIB->Menu->Dataset->Bounding
    % Box
    
	% Copyright (C) 16.12.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
	% 
	% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
	%
	% Updates
	% 20.05.2019, updated for the batch mode
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        bb
        % matrix with bounding box information
        oldBB
        % original bounding box
        pixSize
        % a structure with the pixel size information
        BatchOpt
        % a structure compatible with batch operation, see details in the contsructor
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
%         function ViewListner_Callback(obj, src, evnt)
%             switch src.Name
%                 case {'Id', 'newDatasetSwitch'}     % added in mibChildView
%                     obj.updateWidgets();
%                     %                 case 'slices'     % replaced with
%                     %                 'changeSlice', 'changeTime' events because slice is changed too often
%                     %                     if obj.listener{3}.Enabled
%                     %                         disp(toc)
%                     %                         obj.updateHist();
%                     %                     end
%             end
%         end
        
        function ViewListner_Callback2(obj, src, evnt)
            switch evnt.EventName
                case {'updateGuiWidgets'}
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibBoundingBoxController(mibModel, varargin)
            obj.mibModel = mibModel;    % assign model
            
            % --------------  fill BatchOpt structure with default values
            obj.BatchOpt.id = obj.mibModel.Id;  % optional
            
            obj.pixSize = obj.mibModel.I{obj.BatchOpt.id}.pixSize;
            obj.bb = obj.mibModel.I{obj.BatchOpt.id}.getBoundingBox();     % current bounding box
            obj.BatchOpt.Xmin = num2str(obj.bb(1));
            obj.BatchOpt.Ymin = num2str(obj.bb(3));
            obj.BatchOpt.Zmin = num2str(obj.bb(5));
            obj.BatchOpt.Xcent = '';
            obj.BatchOpt.Ycent = '';
            obj.BatchOpt.Xmax = '';
            obj.BatchOpt.Ymax = '';
            obj.BatchOpt.Zmax = '';
            obj.BatchOpt.Zmax = '';
            obj.BatchOpt.StageRotationBias = '';
            obj.BatchOpt.ImportFromClipboard = false;
            % add section name and action name for the batch tool
            
            obj.BatchOpt.mibBatchSectionName = 'Menu -> Dataset';
            obj.BatchOpt.mibBatchActionName = 'Bounding Box';
            % tooltips that will accompany the BatchOpt
            obj.BatchOpt.mibBatchTooltip.Xmin = sprintf('Min X point of the bounding box');
            obj.BatchOpt.mibBatchTooltip.Ymin = sprintf('Min Y point of the bounding box');
            obj.BatchOpt.mibBatchTooltip.Zmin = sprintf('Min Z point of the bounding box');
            obj.BatchOpt.mibBatchTooltip.Xcent = sprintf('Center X point of the bounding box');
            obj.BatchOpt.mibBatchTooltip.Ycent = sprintf('Center Y point of the bounding box');
            obj.BatchOpt.mibBatchTooltip.Xmax = sprintf('Max X point of the bounding box');
            obj.BatchOpt.mibBatchTooltip.Ymax = sprintf('Max Y point of the bounding box');
            obj.BatchOpt.mibBatchTooltip.Zmax = sprintf('Max Z point of the bounding box');
            obj.BatchOpt.mibBatchTooltip.StageRotationBias = sprintf('Stage rotation bias, used for 3view system, where it is normally 45 degrees');
            obj.BatchOpt.mibBatchTooltip.ImportFromClipboard = sprintf('Acquire bounding box information from the system clipboard, see more in the Help section');

            % ---- Batch mode processing code
            % if the BatchOpt stucture is provided the controller is initialized using those parameters
            % and performs the function in the headless mode without GUI
            if nargin == 3
                BatchOptInput = varargin{2};
                if isstruct(BatchOptInput) == 0 
                    if isnan(BatchOptInput)
                        obj.returnBatchOpt();   % obtain Batch parameters
                    else
                        errordlg(sprintf('A structure as the 4th parameter is required!')); 
                    end
                    return;
                end
                
                % combine fields from input and default structures
                obj.BatchOpt = updateBatchOptCombineFields_Shared(obj.BatchOpt, BatchOptInput);
                if obj.BatchOpt.ImportFromClipboard
                    obj.importBtn_Callback(1);  % 1 - batch mode switch
                end
                obj.okBtn_Callback(1);   % 1 - batch mode switch
                return;
            end
            
            guiName = 'mibBoundingBoxGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % resize all elements x1.25 times for macOS
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            Font = obj.mibModel.preferences.Font;
            if obj.View.handles.textInfo.FontSize ~= Font.FontSize ...
                    || ~strcmp(obj.View.handles.textInfo.FontName, Font.FontName)
                mibUpdateFontSize(obj.View.gui, Font);
            end
            
            % update GUI widgets using the provided BatchOpt
            obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.BatchOpt);
            
            obj.updateWidgets();
			
			% add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
             
            % option 2: in some situations
            % obj.listener{1} = addlistener(obj.mibModel, 'Id', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
            % obj.listener{2} = addlistener(obj.mibModel, 'newDatasetSwitch', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
        end
        
        function closeWindow(obj)
            % closing mibBoundingBoxController window
            if isvalid(obj.View.gui)
                delete(obj.View.gui);   % delete childController window
            end
            
            % delete listeners, otherwise they stay after deleting of the
            % controller
            for i=1:numel(obj.listener)
                delete(obj.listener{i});
            end
            
            notify(obj, 'closeEvent');      % notify mibController that this child window is closed
        end
        
        function updateWidgets(obj)
            % function updateWidgets(obj)
            % update widgets of this window
            obj.BatchOpt.id = obj.mibModel.Id;
            obj.bb = obj.mibModel.I{obj.BatchOpt.id}.getBoundingBox();
            obj.pixSize = obj.mibModel.I{obj.BatchOpt.id}.pixSize;
            obj.oldBB = obj.bb;
            
            obj.View.handles.textString.String = ...
                sprintf('xmin-xmax: %g - %g\nymin-ymax: %g - %g\nzmin-zmax: %g - %g\n',...
                obj.bb(1), obj.bb(2), obj.bb(3), obj.bb(4), obj.bb(5), obj.bb(6));
            obj.View.handles.pixSizeText.String = sprintf('X: %g\nY: %g\nZ: %g\n',...
                obj.pixSize.x, obj.pixSize.y, obj.pixSize.z);
            
            obj.View.handles.textInfo.String = ...
                sprintf('To shift the bounding box it is enough to provide one set of numbers: minimal or central.\nUpdate of both minimal and maximal values results in change of pixel size!');
            
            obj.View.handles.Xmin.String = num2str(obj.bb(1));
            obj.View.handles.Ymin.String = num2str(obj.bb(3));
            obj.View.handles.Zmin.String = num2str(obj.bb(5));
            
            obj.View.handles.Xcent.String = '';
            obj.View.handles.Ycent.String = '';
            obj.View.handles.Xmax.String = '';
            obj.View.handles.Ymax.String = '';
            obj.View.handles.Zmax.String = '';
            obj.View.handles.StageRotationBias.String = '';
            
            % update BatchOpt structure
            obj.BatchOpt.Xmin = num2str(obj.bb(1));
            obj.BatchOpt.Ymin = num2str(obj.bb(3));
            obj.BatchOpt.Zmin = num2str(obj.bb(5));
            obj.BatchOpt.Xcent = '';
            obj.BatchOpt.Ycent = '';
            obj.BatchOpt.Xmax = '';
            obj.BatchOpt.Ymax = '';
            obj.BatchOpt.Zmax = '';
            obj.BatchOpt.Zmax = '';
            obj.BatchOpt.StageRotationBias = '';
            
            % update GUI widgets using the provided BatchOpt
            obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.BatchOpt);
        end
        
        function returnBatchOpt(obj, BatchOptOut)
            % return structure with Batch Options and possible configurations
            % Parameters:
            % BatchOptOut: a local structure with Batch Options generated
            % during Continue callback. It may contain more fields than
            % obj.BatchOpt structure
             
            if nargin < 2; BatchOptOut = obj.BatchOpt; end
            if isfield(BatchOptOut, 'id'); BatchOptOut = rmfield(BatchOptOut, 'id'); end  % remove id field
            % trigger syncBatch event to send BatchOptOut to mibBatchController 
            eventdata = ToggleEventData(BatchOptOut);
            notify(obj.mibModel, 'syncBatch', eventdata);
        end
        
        function updateBatchOptFromGUI(obj, hObject)
            % function updateBatchOptFromGUI(obj, hObject)
            %
            % update obj.BatchOpt from widgets of GUI
            % use an external function (Tools\updateBatchOptFromGUI_Shared.m) that is common for all tools
            % compatible with the Batch mode
            %
            % Parameters:
            % hObject: a handle to a widget of GUI
            
            obj.BatchOpt = updateBatchOptFromGUI_Shared(obj.BatchOpt, hObject);
        end
        
        function importBtn_Callback(obj, batchModeSw)
            % function importBtn_Callback(obj, batchModeSw)
            % import from the system clipboard information about the
            % bounding box
            % Parameters:
            % batchModeSw: a switch, 1-when called during the BatchMode, 0-normal mode
            
            if nargin < 2; batchModeSw = 0; end
            
            str = clipboard('paste');
            lineFeeds = strfind(str, sprintf('\n'));
            equalSigns = strfind(str, sprintf('='));
            
            switch obj.mibModel.I{obj.BatchOpt.id}.pixSize.units
                case 'm'
                    coef = 1e6;
                case 'cm'
                    coef = 1e4;
                case 'mm'
                    coef = 1e3;
                case 'um'
                    coef = 1;
                case 'nm'
                    coef = 1e-3;
            end
            
            % read pixel size X
            pos = strfind(str, sprintf('ScaleX'));
            if ~isempty(pos)
                ScaleX = str2double(str(equalSigns(find(equalSigns>pos, 1))+1:lineFeeds(find(lineFeeds>pos, 1))));
                if isnumeric(ScaleX)
                    obj.pixSize.x = ScaleX;
                    dx = (max([obj.mibModel.I{obj.BatchOpt.id}.width 2])-1)*obj.pixSize.x*coef;     % tweek (using the max function) for Amira single layer images max([w 2])
                    obj.bb(2) = obj.bb(1) + dx;
                end
            end
            % read pixel size Y
            pos = strfind(str, sprintf('ScaleY'));
            if ~isempty(pos)
                ScaleY = str2double(str(equalSigns(find(equalSigns>pos, 1))+1:lineFeeds(find(lineFeeds>pos, 1))));
                if isnumeric(ScaleY)
                    obj.pixSize.y = ScaleY;
                    dy = (max([obj.mibModel.I{obj.BatchOpt.id}.height 2])-1)*obj.pixSize.y*coef;     % tweek for Amira single layer images max([w 2])
                    obj.bb(4) = obj.bb(3) + dy;
                end
            end
            % read pixel size Z
            pos = strfind(str, sprintf('ScaleZ'));
            if ~isempty(pos)
                ScaleZ = str2double(str(equalSigns(find(equalSigns>pos, 1))+1:lineFeeds(find(lineFeeds>pos, 1))));
                if isnumeric(ScaleZ)
                    if ScaleZ == 0
                        obj.pixSize.z = obj.pixSize.x;
                    else
                        obj.pixSize.z = ScaleZ;
                    end
                    dz = (max([obj.mibModel.I{obj.BatchOpt.id}.depth 2])-1)*obj.pixSize.z*coef;     % tweek for Amira single layer images max([w 2])
                    obj.bb(6) = obj.bb(5) + dz;
                end
            end
            
            % read center X
            pos = strfind(str, sprintf('xPos'));
            if ~isempty(pos)
                centerX = str2double(str(equalSigns(find(equalSigns>pos, 1))+1:lineFeeds(find(lineFeeds>pos, 1))));
                if isnumeric(centerX)
                    obj.BatchOpt.Xcent = num2str(centerX);
                    if batchModeSw == 0
                        obj.View.handles.Xcent.String = num2str(centerX);
                    end
                end
            end
            
            % read center Y
            pos = strfind(str, sprintf('yPos'));
            if ~isempty(pos)
                centerY = str2double(str(equalSigns(find(equalSigns>pos, 1))+1:lineFeeds(find(lineFeeds>pos, 1))));
                if isnumeric(centerY)
                    obj.BatchOpt.Ycent = num2str(centerY);
                    if batchModeSw == 0
                        obj.View.handles.Ycent.String = num2str(centerY);
                    end
                end
            end
            
            % read Z
            pos = strfind(str, sprintf('Z Position'));
            if ~isempty(pos)
                posZ = str2double(str(equalSigns(find(equalSigns>pos, 1))+1:lineFeeds(find(lineFeeds>pos, 1))));
                if isnumeric(posZ)
                    obj.BatchOpt.Zmin = num2str(posZ);
                    if batchModeSw == 0
                        obj.View.handles.Zmin.String = num2str(posZ);
                    end
                end
            end
            
            % read Rotation
            pos = strfind(str, sprintf('Rotation'));
            if ~isempty(pos)
                rotationVal = str2double(str(equalSigns(find(equalSigns>pos, 1))+1:lineFeeds(find(lineFeeds>pos, 1))));
                if isnumeric(rotationVal)
                    obj.BatchOpt.StageRotationBias = num2str(45-rotationVal);
                    if batchModeSw == 0
                        obj.View.handles.StageRotationBias.String = num2str(45-rotationVal);
                    end
                end
            end
            if batchModeSw == 0
                obj.View.handles.textString.String = sprintf('xmin-xmax: %g - %g\nymin-ymax: %g - %g\nzmin-zmax: %g - %g\n',...
                    obj.bb(1),obj.bb(2),obj.bb(3),obj.bb(4),obj.bb(5),obj.bb(6));
            
                obj.View.handles.pixSizeText.String = sprintf('X: %g\nY: %g\nZ: %g\n',...
                    obj.pixSize.x, obj.pixSize.y,obj.pixSize.z);
            end
        end
        
        function okBtn_Callback(obj, batchModeSw)
            % function okBtn_Callback(obj)
            % update the bounding box
            % Parameters:
            % batchModeSw: a switch, 1-when called during the BatchMode, 0-normal mode

            if nargin < 2; batchModeSw = 0; end
            
            if batchModeSw == 0; drawnow;   end  % needed to fix callback after the key press
            
            minX = str2double(obj.BatchOpt.Xmin);
            minY = str2double(obj.BatchOpt.Ymin);
            minZ = str2double(obj.BatchOpt.Zmin);
            meanX = str2double(obj.BatchOpt.Xcent);
            meanY = str2double(obj.BatchOpt.Ycent);
            maxX = str2double(obj.BatchOpt.Xmax);
            maxY = str2double(obj.BatchOpt.Ymax);
            maxZ = str2double(obj.BatchOpt.Zmax);
            rotXY = str2double(obj.BatchOpt.StageRotationBias);
            
            if isempty(rotXY) || isnan(rotXY); rotXY = 0; end
            
            if isnan(meanX)     % use the min point
                %minX = max([abs(minX) 0]);
                xyzShift(1) = minX-obj.bb(1);
            else                % use the center point
                halfWidth = abs((obj.bb(2)-obj.bb(1))/2);
                %halfHeight = abs((obj.bb(4)-obj.bb(3))/2);
                if rotXY ~= 0
                    tempX = sqrt(meanX^2+meanY^2)*cosd(atan2d(meanY, meanX)-rotXY);
                    xyzShift(1) = tempX-halfWidth-obj.bb(1);
                else
                    xyzShift(1) = meanX-halfWidth-obj.bb(1);
                end
            end
            
            if isnan(meanY)     % use the min point
                %minY = max([abs(minY) 0]);
                xyzShift(2) = minY-obj.bb(3);
            else                % use the center point
                halfHeight = abs((obj.bb(4)-obj.bb(3))/2);
                %halfWidth = abs((obj.bb(2)-obj.bb(1))/2);
                if rotXY ~= 0
                    tempY = sqrt(meanX^2+meanY^2)*sind(atan2d(meanY, meanX)-rotXY);
                    xyzShift(2) = tempY-halfHeight-obj.bb(3);
                else
                    xyzShift(2) = meanY-halfHeight-obj.bb(3);
                end
            end
            
            %minZ = max([abs(minZ) 0]);
            xyzShift(3) = minZ-obj.bb(5);
            
            obj.mibModel.I{obj.BatchOpt.id}.pixSize.x = obj.pixSize.x;
            obj.mibModel.I{obj.BatchOpt.id}.pixSize.y = obj.pixSize.y;
            obj.mibModel.I{obj.BatchOpt.id}.pixSize.z = obj.pixSize.z;
            
            if ~isnan(maxX)  % recalculate pixSize.x
                obj.mibModel.I{obj.BatchOpt.id}.pixSize.x = (maxX-minX)/(max([obj.mibModel.I{obj.BatchOpt.id}.width 2])-1);
            end
            if ~isnan(maxY)  % recalculate pixSize.y
                obj.mibModel.I{obj.BatchOpt.id}.pixSize.y = (maxY-minY)/(max([obj.mibModel.I{obj.BatchOpt.id}.height 2])-1);
            end
            if ~isnan(maxZ)  % recalculate pixSize.z
                obj.mibModel.I{obj.BatchOpt.id}.pixSize.z = (maxZ-minZ)/(max([obj.mibModel.I{obj.BatchOpt.id}.depth 2])-1);
            end
            obj.mibModel.I{obj.BatchOpt.id}.pixSize.units = 'um';
            resolution = mibCalculateResolution(obj.mibModel.I{obj.BatchOpt.id}.pixSize);
            obj.mibModel.I{obj.BatchOpt.id}.meta('XResolution') = resolution(1);
            obj.mibModel.I{obj.BatchOpt.id}.meta('YResolution') = resolution(2);
            obj.mibModel.I{obj.BatchOpt.id}.meta('ResolutionUnit') = 'Inch';
            obj.mibModel.I{obj.BatchOpt.id}.updateBoundingBox();
            obj.mibModel.I{obj.BatchOpt.id}.updateBoundingBox(NaN, xyzShift);
            
            notify(obj.mibModel, 'updateImgInfo');
            if batchModeSw == 0
                obj.updateWidgets(); 
            else
                notify(obj.mibModel, 'updateGuiWidgets');
            end
            
            obj.returnBatchOpt(obj.BatchOpt);
        end
        
        
    end
end