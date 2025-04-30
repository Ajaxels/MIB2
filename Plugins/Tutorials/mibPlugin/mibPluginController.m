% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

classdef mibPluginController < handle
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
        function obj = mibPluginController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibPluginGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % check for the virtual stacking mode and close the controller
            if isprop(obj.mibModel.I{obj.mibModel.Id}, 'Virtual') && obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nThis plugin is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
                    'Not implemented');
                obj.closeWindow();
                return;
            end
            
            % resize all elements of the GUI
            mibRescaleWidgets(obj.View.gui);
            
            % % update font and size
            % % you may need to replace "obj.View.handles.text1" with tag of any text field of your own GUI
            % global Font;
            % if ~isempty(Font)
            %   if obj.View.handles.text1.FontSize ~= Font.FontSize ...
            %         || ~strcmp(obj.View.handles.text1.FontName, Font.FontName)
            %       mibUpdateFontSize(obj.View.gui, Font);
            %   end
            % end
            
			obj.updateWidgets();
			
			% obj.View.gui.WindowStyle = 'modal';     % make window modal
			
			% add listner to obj.mibModel and call controller function as a callback
             % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
             obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in MIB
             
             % option 2: in some situations
             % obj.listener{1} = addlistener(obj.mibModel, 'Id', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
             % obj.listener{2} = addlistener(obj.mibModel, 'newDatasetSwitch', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
        end
        
        function closeWindow(obj)
            % closing mibPluginController window
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
            
            fprintf('childController:updateWidgets: %g\n', toc);
        end
        
        % ------------------------------------------------------------------
        % % Additional functions and callbacks
        function calculateBtn_Callback(obj)
            % start main calculation of the plugin
            
            % get the user provided threshold value from the GUI
            value = obj.View.handles.thresholdValue.String;
            % convert it from string to double
            threhsoldValue = str2double(value); 
            wb = waitbar(0, 'Please wait'); % add a waitbar to follow the progress
            
            [height, width, ~, depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image');  % get dataset dimensions
            img = cell2mat(obj.mibModel.getData2D('image'));    % get the currently displayed image
            waitbar(0.5, wb);   % update the waitbar

            mask = zeros([height, width, depth], 'uint8'); % allocate space for the mask layer
            mask(img<threhsoldValue) = 1; % threshold image
            waitbar(0.95, wb);     % update the waitbar
            
            obj.mibModel.setData2D('mask', mask); % send the mask layer back to MIB
            delete(wb);         % delete the waitbar

            % notify mibModel to switch on the Show mask checkbox, 
            % which also redraws the image
            % alternatively, 
            % notify(obj.mibModel, 'plotImage');
            % can be used to force image redraw
            notify(obj.mibModel, 'showMask'); 
        end
        
        
    end
end