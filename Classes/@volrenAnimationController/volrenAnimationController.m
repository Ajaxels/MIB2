classdef volrenAnimationController < handle
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        extraController
        % an optional extra controller
        listener
        % a cell array with handles to listeners
        keyFrameTableIndex
        % index of the selected key frame
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
        function obj = volrenAnimationController(varargin)
            % function obj = volrenAnimationController(varargin)
            % constructor of the class
            % Parameters:
            % parameter 1: a handles to mibModel
            % parameter 2: [@em optional] a handle to extra controllers
            
            obj.mibModel = varargin{1};    % assign model
            if nargin > 1
                obj.extraController = varargin{2};
            else
                obj.extraController = [];
            end
            
            obj.mibModel = mibModel;    % assign model
            guiName = 'volrenAnimationGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
			% check for the virtual stacking mode and close the controller if the plugin is not compatible with the virtual stacking mode
            if isprop(obj.mibModel.I{obj.mibModel.Id}, 'Virtual') && obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nThis plugin is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
                    'Not implemented');
                obj.closeWindow();
                return;
            end
			
            % move the window to the left hand side of the main window
            obj.View.gui = moveWindowOutside(obj.View.gui, 'center', 'bottom');
            
            % resize all elements of the GUI
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            % you may need to replace "obj.View.handles.text1" with tag of any text field of your own GUI
            global Font;
            if ~isempty(Font)
              if obj.View.handles.noFramesTxt.FontSize ~= Font.FontSize ...
                    || ~strcmp(obj.View.handles.noFramesTxt.FontName, Font.FontName)
                  mibUpdateFontSize(obj.View.gui, Font);
              end
            end
            
            obj.keyFrameTableIndex = [];
            obj.updateWidgets();
            
            % obj.View.gui.WindowStyle = 'modal';     % make window modal
            
            % add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            
            % option 2: in some situations
            % obj.listener{1} = addlistener(obj.mibModel, 'Id', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
            % obj.listener{2} = addlistener(obj.mibModel, 'newDatasetSwitch', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
        end
        
        function closeWindow(obj)
            % closing volrenAnimationController window
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
            
            obj.View.handles.noAnimationFramesEdit.String = num2str(obj.extraController.Settings.noFramesPreview);
            obj.updateKeyFrameTable();
        end
        
        function updateKeyFrameTable(obj)
            if ~isfield(obj.extraController.animationPath, 'CameraPosition')
                obj.View.handles.keyFrameTable.Data = [];
                return;
            end
            noFrames = size(obj.extraController.animationPath.CameraPosition, 1);
            Data = 1:noFrames;
            obj.View.handles.keyFrameTable.Data = Data;
            obj.View.handles.keyFrameTable.ColumnWidth = repmat({23}, [1, size(Data, 2)]);
        end
        
        function addFrameBtn_Callback(obj, posIndex)
            % function addFrameBtn_Callback(obj, posIndex)
            % add/insert a key frame
            %
            % Parameters:
            % posIndex: [@em optional] position of the key frame, when 1 -
            % in the beginning of the animation sequence
            %
            if nargin < 2
                if ~isfield(obj.extraController.animationPath, 'CameraPosition')
                    posIndex = 1;
                    obj.extraController.animationPath.CameraPosition = [];
                    obj.extraController.animationPath.CameraUpVector = [];
                    obj.extraController.animationPath.CameraTarget = [];
                else
                    posIndex = size(obj.extraController.animationPath.CameraPosition,1)+1;
                end
            end
            
            if posIndex == 1
                obj.extraController.animationPath.CameraPosition = [obj.extraController.volume.CameraPosition; obj.extraController.animationPath.CameraPosition];
                obj.extraController.animationPath.CameraUpVector = [obj.extraController.volume.CameraUpVector; obj.extraController.animationPath.CameraUpVector];
                obj.extraController.animationPath.CameraTarget = [obj.extraController.volume.CameraTarget; obj.extraController.animationPath.CameraTarget];
            elseif posIndex <= size(obj.extraController.animationPath.CameraPosition,1)
                obj.extraController.animationPath.CameraPosition = [obj.extraController.animationPath.CameraPosition(1:posIndex-1, :); obj.extraController.volume.CameraPosition; obj.extraController.animationPath.CameraPosition(posIndex:end, :)];
                obj.extraController.animationPath.CameraUpVector = [obj.extraController.animationPath.CameraUpVector(1:posIndex-1, :); obj.extraController.volume.CameraUpVector; obj.extraController.animationPath.CameraUpVector(posIndex:end, :)];
                obj.extraController.animationPath.CameraTarget = [obj.extraController.animationPath.CameraTarget(1:posIndex-1, :); obj.extraController.volume.CameraTarget; obj.extraController.animationPath.CameraTarget(posIndex:end, :)];
            else
                obj.extraController.animationPath.CameraPosition(posIndex, :) = obj.extraController.volume.CameraPosition;
                obj.extraController.animationPath.CameraUpVector(posIndex, :) = obj.extraController.volume.CameraUpVector;
                obj.extraController.animationPath.CameraTarget(posIndex, :) = obj.extraController.volume.CameraTarget;
            end
            obj.updateKeyFrameTable();
        end
        
        function keyFrameTable_CellSelectionCallback(obj, Index)
            if nargin < 2; Index = obj.keyFrameTableIndex; end
            
            obj.keyFrameTableIndex = Index;
            if obj.View.handles.updateViewCheck.Value == 1 && ~isempty(Index)
                % update the view
                obj.extraController.volume.CameraPosition = obj.extraController.animationPath.CameraPosition(obj.keyFrameTableIndex, :);
                obj.extraController.volume.CameraUpVector = obj.extraController.animationPath.CameraUpVector(obj.keyFrameTableIndex, :);
                obj.extraController.volume.CameraTarget = obj.extraController.animationPath.CameraTarget(obj.keyFrameTableIndex, :);
            end
        end
        
        function keyFrameTable_cm_Callback(obj, parameter)
            % function keyFrameTable_cm_Callback(obj, parameter)
            % callback for keyFrameTable context menu
            %
            % Parameters:
            % parameter: a string, 
            %   'replace' - replace the selected key frame
            %   'insert' - insert a key frame to the current position
            %   'remove' - remove the key frame from the current position;
            %   'jump' - jump to the selected key frame and update the view
            
            if isempty(obj.keyFrameTableIndex); return; end
            switch parameter
                case 'replace'
                    obj.extraController.animationPath.CameraPosition(obj.keyFrameTableIndex, :) = obj.extraController.volume.CameraPosition;
                    obj.extraController.animationPath.CameraUpVector(obj.keyFrameTableIndex, :) = obj.extraController.volume.CameraUpVector;
                    obj.extraController.animationPath.CameraTarget(obj.keyFrameTableIndex, :) = obj.extraController.volume.CameraTarget;
                case 'insert'
                    if obj.keyFrameTableIndex == 1
                        answer = questdlg(sprintf('Would you like to insert a frame before or after the selected frame index?'), 'Insert frame', 'Before', 'After', 'Cancel', 'Before');
                        if strcmp(answer, 'Cancel'); return; end
                        if strcmp(answer, 'Before'); obj.keyFrameTableIndex = 0; end
                    end
                    obj.addFrameBtn_Callback(obj.keyFrameTableIndex+1);
                    obj.keyFrameTableIndex = [];
                case 'remove'
                    obj.extraController.animationPath.CameraPosition(obj.keyFrameTableIndex, :) = [];
                    obj.extraController.animationPath.CameraUpVector(obj.keyFrameTableIndex, :) = [];
                    obj.extraController.animationPath.CameraTarget(obj.keyFrameTableIndex, :) = [];
                    obj.keyFrameTableIndex = [];
                case 'jump'
                    obj.extraController.volume.CameraPosition = obj.extraController.animationPath.CameraPosition(obj.keyFrameTableIndex, :);
                    obj.extraController.volume.CameraUpVector = obj.extraController.animationPath.CameraUpVector(obj.keyFrameTableIndex, :);
                    obj.extraController.volume.CameraTarget = obj.extraController.animationPath.CameraTarget(obj.keyFrameTableIndex, :);
                    return;
            end
            obj.updateKeyFrameTable();
        end
        
        function previewBtn_Callback(obj)
            obj.extraController.previewAnimation();
        end
        
        function noAnimationFramesEdit_Callback(obj)
            % function noAnimationFramesEdit_Callback(obj)
            % callback for press of the number of frames button
            val = str2double(obj.View.handles.noAnimationFramesEdit.String);
            obj.extraController.Settings.noFramesPreview = val;
        end
        
        function deleteAllBtn_Callback(obj)
        % function deleteAllBtn_Callback(obj) 
        % delete all key frames
        
        answer = questdlg(sprintf('!!! Warning !!!\nYou are going to remove all key points!\nContinue?'), 'Remove key points', 'Remove', 'Cancel', 'Cancel');
        if strcmp(answer, 'Cancel'); return; end
        
        obj.extraController.animationPath = struct();
        obj.updateKeyFrameTable();
        end
        
    end
end