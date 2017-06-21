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
	%
    
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
        function obj = mibBoundingBoxController(mibModel)
            obj.mibModel = mibModel;    % assign model
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
            obj.bb = obj.mibModel.getImageMethod('getBoundingBox');
            obj.pixSize = obj.mibModel.getImageProperty('pixSize');
            obj.oldBB = obj.bb;
            
            obj.View.handles.textString.String = ...
                sprintf('xmin-xmax: %g - %g\nymin-ymax: %g - %g\nzmin-zmax: %g - %g\n',...
                obj.bb(1), obj.bb(2), obj.bb(3), obj.bb(4), obj.bb(5), obj.bb(6));
            obj.View.handles.pixSizeText.String = sprintf('X: %g\nY: %g\nZ: %g\n',...
                obj.pixSize.x, obj.pixSize.y, obj.pixSize.z);
            
            obj.View.handles.textInfo.String = ...
                sprintf('To shift the bounding box it is enough to provide one set of numbers: minimal or central.\nUpdate of both minimal and maximal values results in change of pixel size!');
            
            obj.View.handles.xMinEdit.String = num2str(obj.bb(1));
            obj.View.handles.yMinEdit.String = num2str(obj.bb(3));
            obj.View.handles.zMinEdit.String = num2str(obj.bb(5));
            
            obj.View.handles.xCenterEdit.String = '';
            obj.View.handles.yCenterEdit.String = '';
            obj.View.handles.xMaxEdit.String = '';
            obj.View.handles.yMaxEdit.String = '';
            obj.View.handles.zMaxEdit.String = '';
            obj.View.handles.rotationEdit.String = '';
        end
        
        function importBtn_Callback(obj)
            % function importBtn_Callback(obj)
            % import from the system clipboard information about the
            % bounding box
            str = clipboard('paste');
            lineFeeds = strfind(str, sprintf('\n'));
            equalSigns = strfind(str, sprintf('='));
            
            switch obj.mibModel.I{obj.mibModel.Id}.pixSize.units
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
                    dx = (max([obj.mibModel.I{obj.mibModel.Id}.width 2])-1)*obj.pixSize.x*coef;     % tweek (using the max function) for Amira single layer images max([w 2])
                    obj.bb(2) = obj.bb(1) + dx;
                end
            end
            % read pixel size Y
            pos = strfind(str, sprintf('ScaleY'));
            if ~isempty(pos)
                ScaleY = str2double(str(equalSigns(find(equalSigns>pos, 1))+1:lineFeeds(find(lineFeeds>pos, 1))));
                if isnumeric(ScaleY)
                    obj.pixSize.y = ScaleY;
                    dy = (max([obj.mibModel.I{obj.mibModel.Id}.height 2])-1)*obj.pixSize.y*coef;     % tweek for Amira single layer images max([w 2])
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
                    dz = (max([obj.mibModel.I{obj.mibModel.Id}.depth 2])-1)*obj.pixSize.z*coef;     % tweek for Amira single layer images max([w 2])
                    obj.bb(6) = obj.bb(5) + dz;
                end
            end
            
            % read center X
            pos = strfind(str, sprintf('xPos'));
            if ~isempty(pos)
                centerX = str2double(str(equalSigns(find(equalSigns>pos, 1))+1:lineFeeds(find(lineFeeds>pos, 1))));
                if isnumeric(centerX)
                    obj.View.handles.xCenterEdit.String = num2str(centerX);
                end
            end
            
            % read center Y
            pos = strfind(str, sprintf('yPos'));
            if ~isempty(pos)
                centerY = str2double(str(equalSigns(find(equalSigns>pos, 1))+1:lineFeeds(find(lineFeeds>pos, 1))));
                if isnumeric(centerY)
                    obj.View.handles.yCenterEdit.String = num2str(centerY);
                end
            end
            
            % read Z
            pos = strfind(str, sprintf('Z Position'));
            if ~isempty(pos)
                posZ = str2double(str(equalSigns(find(equalSigns>pos, 1))+1:lineFeeds(find(lineFeeds>pos, 1))));
                if isnumeric(posZ)
                    obj.View.handles.zMinEdit.String = num2str(posZ);
                end
            end
            
            % read Rotation
            pos = strfind(str, sprintf('Rotation'));
            if ~isempty(pos)
                rotationVal = str2double(str(equalSigns(find(equalSigns>pos, 1))+1:lineFeeds(find(lineFeeds>pos, 1))));
                if isnumeric(rotationVal)
                    obj.View.handles.rotationEdit.String = num2str(45-rotationVal);
                end
            end
            
            obj.View.handles.textString.String = sprintf('xmin-xmax: %g - %g\nymin-ymax: %g - %g\nzmin-zmax: %g - %g\n',...
                obj.bb(1),obj.bb(2),obj.bb(3),obj.bb(4),obj.bb(5),obj.bb(6));
            
            obj.View.handles.pixSizeText.String = sprintf('X: %g\nY: %g\nZ: %g\n',...
                obj.pixSize.x, obj.pixSize.y,obj.pixSize.z);
        end
        
        function okBtn_Callback(obj)
            % function okBtn_Callback(obj)
            % update the bounding box
            
            drawnow;     % needed to fix callback after the key press
            
            minX = str2double(obj.View.handles.xMinEdit.String);
            minY = str2double(obj.View.handles.yMinEdit.String);
            minZ = str2double(obj.View.handles.zMinEdit.String);
            meanX = str2double(obj.View.handles.xCenterEdit.String);
            meanY = str2double(obj.View.handles.yCenterEdit.String);
            maxX = str2double(obj.View.handles.xMaxEdit.String);
            maxY = str2double(obj.View.handles.yMaxEdit.String);
            maxZ = str2double(obj.View.handles.zMaxEdit.String);
            rotXY = str2double(obj.View.handles.rotationEdit.String);
            
            if isempty(rotXY) || isnan(rotXY); rotXY = 0; end;
            
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
            
            obj.mibModel.I{obj.mibModel.Id}.pixSize.x = obj.pixSize.x;
            obj.mibModel.I{obj.mibModel.Id}.pixSize.y = obj.pixSize.y;
            obj.mibModel.I{obj.mibModel.Id}.pixSize.z = obj.pixSize.z;
            
            if ~isnan(maxX)  % recalculate pixSize.x
                obj.mibModel.I{obj.mibModel.Id}.pixSize.x = (maxX-minX)/(max([obj.mibModel.I{obj.mibModel.Id}.width 2])-1);
            end
            if ~isnan(maxY)  % recalculate pixSize.y
                obj.mibModel.I{obj.mibModel.Id}.pixSize.y = (maxY-minY)/(max([obj.mibModel.I{obj.mibModel.Id}.height 2])-1);
            end
            if ~isnan(maxZ)  % recalculate pixSize.z
                obj.mibModel.I{obj.mibModel.Id}.pixSize.z = (maxZ-minZ)/(max([obj.mibModel.I{obj.mibModel.Id}.depth 2])-1);
            end
            obj.mibModel.I{obj.mibModel.Id}.pixSize.units = 'um';
            resolution = mibCalculateResolution(obj.mibModel.I{obj.mibModel.Id}.pixSize);
            obj.mibModel.I{obj.mibModel.Id}.meta('XResolution') = resolution(1);
            obj.mibModel.I{obj.mibModel.Id}.meta('YResolution') = resolution(2);
            obj.mibModel.I{obj.mibModel.Id}.meta('ResolutionUnit') = 'Inch';
            obj.mibModel.I{obj.mibModel.Id}.updateBoundingBox();
            obj.mibModel.I{obj.mibModel.Id}.updateBoundingBox(NaN, xyzShift);
            notify(obj.mibModel, 'updateImgInfo');
            obj.updateWidgets();
            %obj.closeWindow();
        end
        
        
    end
end