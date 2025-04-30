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

classdef mibImageFiltersController < handle
    % @type mibImageFiltersController class is a template class for using with
    % GUI developed using appdesigner of Matlab
    %
    % @code
    % obj.startController('mibImageFiltersController'); // as GUI tool
    % @endcode
    % or 
    % @code 
    % // a code below was used for mibImageArithmeticController
    % BatchOpt.Parameter = 'test';  // fill edit boxes as strings
    % BatchOpt.Checkbox = true;     // fill checkboxes with logicals: true/false
    % BatchOpt.Popup = {'value'};        // value for the popups as a cell
    % BatchOpt.Radio = {'Radio1'};          // selection of radio buttons, as cell with the handle of the target radio button
    % BatchOpt.showWaitbar = true;  // show or not the waitbar
    % obj.startController('mibImageFiltersController', [], BatchOpt); // start mibImageFiltersController in the batch mode
    % @endcode
    % or
    % @code
    % // trigger return of the possible Options using returnBatchOpt function
    % // using notify syncBatch event
    % obj.startController('mibImageFiltersController', [], NaN);
    % @endcode
    
	% Updates
	%     
    
    properties
        mibModel
        % handles to mibModel
        View
        % handle to the view / mibImageFiltersGUI
        listener
        % a cell array with handles to listeners
        BasicFiltersList
        % cell array with available basic filters % {'Average', 'Disk'};
        EdgePreservingFiltersList
        % cell array with available edge preserving filters % {'Bilateral', 'Anisotropic diffusion', ''};
        ContrastFiltersList
        % cell array with available contrast adjustment filters 
        BinarizationFiltersList
        % cell array with available binarization filters
        ImageFilters
        % a structure with parameters for the filter, taken from obj.mibModel.sessionSettings.ImageFilters
        Filters3D
        % list of 3D compatible filters
        MatlabR2019b
        % a logical switch indicating matlab version R2019b or newer
        ParaHandles
        % a cell array with handles to the parameters widgets
        BatchOpt
        % a structure compatible with batch operation
        % name of each field should be displayed in a tooltip of GUI
        % it is recommended that the Tags of widgets match the name of the
        % fields in this structure
        % .Parameter - [editbox], char/string 
        % .Checkbox - [checkbox], logical value true or false
        % .Dropdown{1} - [dropdown],  cell string for the dropdown
        % .Dropdown{2} - [optional], an array with possible options
        % .Radio - [radiobuttons], cell string 'Radio1' or 'Radio2'...
        % .ParameterNumeric{1} - [numeric editbox], cell with a number 
        % .ParameterNumeric{2} - [optional], vector with limits [min, max]
        % .ParameterNumeric{3} - [optional], string 'on' - to round the value, 'off' to do not round the value
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback(obj, src, evnt)
            switch evnt.EventName
                case {'updateGuiWidgets'}
                    obj.updateWidgets();
                case 'changeSlice'
                    if obj.View.handles.AutopreviewCheckBox.Value == 1
                        obj.PreviewButtonPushed();
                    end
            end
        end
    end
    
    methods
        function obj = mibImageFiltersController(mibModel, varargin)
            % get version of Matlab, important because not all widgets are
            % available in R2019a and older
            obj.MatlabR2019b = true;
            if verLessThan('Matlab', '9.7')     % 9.7 - R2019b 
                obj.MatlabR2019b = false;
            end
            
            obj.mibModel = mibModel;    % assign model
            
            %% fill the BatchOpt structure with default values
            % fields of the structure should correspond to the starting
            % text in the each widget tooltip.
            % For example, this demo template has an edit box, where the
            % tooltip starts with "Parameter:...". Text Parameter
            % indicates field of the BatchOpt structure that defines value
            % for this widget
            obj.BatchOpt.id = obj.mibModel.Id;
            
            DesiredFilterName = [];
            if nargin > 1
                if ~isempty(varargin{1}); DesiredFilterName = varargin{1}; end
            end
            %% For DEVELOPMENTAL PURPOSE, REMOVE LATER
            % obj.mibModel.sessionSettings.ImageFilters structure is
            % defined in mibController.getDefaultParameters
            
            %if isfield(obj.mibModel.sessionSettings, 'ImageFilters')
            %    obj.mibModel.sessionSettings = rmfield(obj.mibModel.sessionSettings, 'ImageFilters');
            %end
            %
            
            %%
            obj.ImageFilters = obj.mibModel.sessionSettings.ImageFilters; % make a local copy of ImageFilters settings
            
            % update certain parameters
            obj.ImageFilters.Bilateral.degreeOfSmoothing = num2str(obj.mibModel.I{obj.BatchOpt.id}.meta('MaxInt')^2*.01);
            
            % WARNING!
            % When adding filters, please also add them to mibBatchController.m
            % after "obj.Sections(secIndex).Name = 'Panel -> Image filters';" line

            if verLessThan('Matlab', '9.8')
                obj.BasicFiltersList = {'Average', 'Disk', 'DistanceMap', 'ElasticDistortion', 'Entropy', 'Frangi', 'Gaussian', 'Gradient', 'LoG', 'MathOps', 'Motion','Prewitt','Range', 'SaltAndPepper','Sobel','Std'};
            else
                obj.BasicFiltersList = {'Average', 'Disk', 'DistanceMap', 'ElasticDistortion', 'Entropy', 'Frangi', 'Gaussian', 'Gradient', 'LoG', 'MathOps', 'Mode', 'Motion','Prewitt','Range', 'SaltAndPepper','Sobel','Std'};
            end
            obj.EdgePreservingFiltersList = {'AnisotropicDiffusion', 'Bilateral', 'DNNdenoise', 'Median', 'NonLocalMeans', 'Wiener'};
            obj.ContrastFiltersList = {'AddNoise', 'FastLocalLaplacian', 'FlatfieldCorrection', 'LocalBrighten', 'LocalContrast', 'ReduceHaze', 'UnsharpMask'};
            obj.BinarizationFiltersList = {'Edge', 'SlicClustering', 'WatershedClustering'};
            obj.Filters3D = {'Average', 'DistanceMap', 'Frangi', 'Gaussian', 'Gradient', 'LoG', 'Median', 'Mode', 'Prewitt', 'SlicClustering', 'Sobel', 'WatershedClustering'};     % list of 3D compatible filters
            
            % add BMxD filter if available
            if ~isempty(obj.mibModel.preferences.ExternalDirs.bm3dInstallationPath)
                if exist(fullfile(obj.mibModel.preferences.ExternalDirs.bm3dInstallationPath, 'BM3D.m'), 'file') == 2
                    obj.EdgePreservingFiltersList{end+1} = 'BMxD';
                end
            end
            
            % get the last used filter name
            if isempty(DesiredFilterName) && ~isempty(obj.ImageFilters.DesiredFilterName)
                DesiredFilterName = obj.ImageFilters.DesiredFilterName;
            end
            
            if ~isempty(DesiredFilterName)    % varargin{1} is empty of desired filter name
                if ismember(DesiredFilterName, obj.BasicFiltersList)
                    obj.BatchOpt.FilterGroup = {'Basic Image Filtering in the Spatial Domain'};
                    obj.BatchOpt.FilterName{2} = obj.BasicFiltersList;
                    obj.BatchOpt.FilterName(1) = obj.BatchOpt.FilterName{2}(ismember(obj.BasicFiltersList, DesiredFilterName)); 
                elseif ismember(DesiredFilterName, obj.EdgePreservingFiltersList)
                    obj.BatchOpt.FilterGroup = {'Edge-Preserving Filtering'};
                    obj.BatchOpt.FilterName{2} = obj.EdgePreservingFiltersList;
                    obj.BatchOpt.FilterName(1) = obj.BatchOpt.FilterName{2}(ismember(obj.EdgePreservingFiltersList, DesiredFilterName));
                elseif ismember(DesiredFilterName, obj.ContrastFiltersList)
                    obj.BatchOpt.FilterGroup = {'Contrast Adjustment'};
                    obj.BatchOpt.FilterName{2} = obj.ContrastFiltersList;
                    obj.BatchOpt.FilterName(1) = obj.BatchOpt.FilterName{2}(ismember(obj.ContrastFiltersList, DesiredFilterName));
                elseif ismember(DesiredFilterName, obj.BinarizationFiltersList)
                    obj.BatchOpt.FilterGroup = {'Image Binarization'};
                    obj.BatchOpt.FilterName{2} = obj.BinarizationFiltersList;
                    obj.BatchOpt.FilterName(1) = obj.BatchOpt.FilterName{2}(ismember(obj.BinarizationFiltersList, DesiredFilterName));
                end
            else
                obj.BatchOpt.FilterGroup = {'Basic Image Filtering in the Spatial Domain'};
                obj.BatchOpt.FilterName{2} = obj.BasicFiltersList;
                obj.BatchOpt.FilterName(1) = obj.BatchOpt.FilterName{2}(1);    
            end
            obj.BatchOpt.FilterGroup{2} = {'Basic Image Filtering in the Spatial Domain', 'Edge-Preserving Filtering', 'Contrast Adjustment', 'Image Binarization'};
            
            obj.BatchOpt.Mode3D = false;
            obj.BatchOpt.DatasetType = {'2D, Slice'};   % perform opertion on dataset
            obj.BatchOpt.DatasetType{2} = {'2D, Slice', '3D, Stack', '4D, Dataset'};
            PossibleColChannels = arrayfun(@(x) sprintf('%d', x), 1:obj.mibModel.I{obj.BatchOpt.id}.colors, 'UniformOutput', false);
            obj.BatchOpt.ColorChannel = {'All'};         % specify the color channel
            obj.BatchOpt.ColorChannel{2} = [{'All'}, {'Displayed'}, PossibleColChannels];
            obj.BatchOpt.SourceLayer = {'image'};
            obj.BatchOpt.SourceLayer{2} = {'image', 'model', 'selection', 'mask'};
            obj.BatchOpt.MaterialIndex = '1';
            obj.BatchOpt.ActionToResult = {'Fitler image'};         % radio buttons for additional actions applied to the result
            obj.BatchOpt.ActionToResult{2} = {'Fitler image', 'Filter and subtract','Filter and add'};
            obj.BatchOpt.UseParallelComputing = false;  % use parallel computing
%             sessionSettingsFieldnames = fieldnames(obj.mibModel.sessionSettings.ImageFilters);
%             for fieldId=1:numel(sessionSettingsFieldnames)
%                 obj.BatchOpt.(sessionSettingsFieldnames{fieldId}) = (obj.mibModel.sessionSettings.ImageFilters.(sessionSettingsFieldnames{fieldId}));            
%             end
            %obj.BatchOpt.ImageFilters = obj.mibModel.sessionSettings.ImageFilters;
            obj.BatchOpt.showWaitbar = true;
            obj.BatchOpt.id = obj.mibModel.Id;  % optional
            
            %% part below is only valid for use of this class from MIB batch controller
            % comment it if intended use not from the batch mode
            obj.BatchOpt.mibBatchSectionName = 'Panel -> Image filters';    % section name for the Batch
            obj.BatchOpt.mibBatchActionName = obj.BatchOpt.FilterName{1};           % name of the filter
            % tooltips that will accompany the BatchOpt
            obj.BatchOpt.mibBatchTooltip.FilterGroup = 'Specify image group of image filters';
            obj.BatchOpt.mibBatchTooltip.FilterName = 'Specify name of the filter';
            obj.BatchOpt.mibBatchTooltip.Mode3D = 'Apply the selected filter in 2D or 3D space';
            obj.BatchOpt.mibBatchTooltip.DatasetType = 'Specify whether to filter the shown slice (2D, Slice), whole stack (3D, Stack) or complete dataset (4D, Dataset)';
            obj.BatchOpt.mibBatchTooltip.ColorChannel = 'Specify color channel to be filtered';
            obj.BatchOpt.mibBatchTooltip.SourceLayer = 'Apply filter to the selected layer of MIB';
            obj.BatchOpt.mibBatchTooltip.MaterialIndex = 'Index of material to be filtered for SourceLayer==model';
            obj.BatchOpt.mibBatchTooltip.ActionToResult = 'Depending on the choice, filter results can be shown as it is or Added/Subtracted from the dataset';
            obj.BatchOpt.mibBatchTooltip.UseParallelComputing = 'Use parallel computing for 2D filters';
            obj.BatchOpt.mibBatchTooltip.showWaitbar = 'Show or not waitbar';

            %% add here a code for the batch mode, for example
            % when the BatchOpt stucture is provided the controller will
            % use it as the parameters, and performs the function in the
            % headless mode without GUI
            if nargin == 3
                BatchOptIn = varargin{2};
                if isstruct(BatchOptIn) == 0 
                    if isnan(BatchOptIn)     % when varargin{2} == NaN return possible settings
                        obj.returnBatchOpt();   % obtain Batch parameters
                    else
                        errordlg(sprintf('A structure as the 3rd parameter is required!')); 
                    end
                    notify(obj, 'closeEvent'); 
                    return
                end
                % add/update BatchOpt with the provided fields in BatchOptIn
                % combine fields from input and default structures
                obj.BatchOpt = updateBatchOptCombineFields_Shared(obj.BatchOpt, BatchOptIn);
                
                batchModeSwitch = 1;
                obj.Filter([], batchModeSwitch);
                notify(obj, 'closeEvent');
                return;
            end
            
            % some widgets (html and gridlayout) are not yet available in Matlab R2019b
            if obj.MatlabR2019b     % R2019b or newerer
                guiName = 'mibImageFiltersGUI';
            else
                guiName = 'mibImageFiltersR2019aGUI';
            end
            
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % add thumbnail image
            imshow(obj.mibModel.sessionSettings.ImageFilters.TestImg, ...
                'Parent', obj.View.handles.ThumbnailView1);
            
            % init the widgets
            %destBuffers = arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false);
            %obj.View.handles.Popup.String = destBuffers;
            
			% move the window to the left hand side of the main window
            obj.View.gui = moveWindowOutside(obj.View.gui, 'left');
            
            obj.ParaHandles = {};   % a cell array with handles to the parameters widgets
            
            % resize all elements of the GUI
            % mibRescaleWidgets(obj.View.gui); % this function is not yet
            % compatible with appdesigner
            
            % update font and size
            % you may need to replace "obj.View.handles.text1" with tag of any text field of your own GUI
            % % this function is not yet
            global Font;
            if ~isempty(Font)
              if obj.View.handles.DatasetType.FontSize ~= Font.FontSize + 4 ...         % guide font size is 4 points smaller than in appdesigner
                    || ~strcmp(obj.View.handles.DatasetType.FontName, Font.FontName)
                  mibUpdateFontSize(obj.View.gui, Font);
              end
            end
            
			obj.updateWidgets();
            
			% update widgets from the BatchOpt structure
            obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.BatchOpt);
            obj.FilterGroupValueChanged();
            obj.View.Figure.Figure.Visible = 'on';
            
            % obj.View.gui.WindowStyle = 'modal';     % make window modal
			
			% add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));    % listen changes in number of ROIs
            obj.listener{2} = addlistener(obj.mibModel, 'changeSlice', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing mibImageFiltersController window
            
            % store session settings
            obj.mibModel.sessionSettings.ImageFilters = obj.ImageFilters;
            
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
            
            % updateWidgets normally triggered during change of MIB
            % buffers, make sure that any widgets related changes are
            % correctly propagated into the BatchOpt structure
            if isfield(obj.BatchOpt, 'id'); obj.BatchOpt.id = obj.mibModel.Id; end
            
            % update list of color channels if needed
            PossibleColChannels = arrayfun(@(x) sprintf('ColCh %d', x), 1:obj.mibModel.I{obj.BatchOpt.id}.colors, 'UniformOutput', false);
            if numel(PossibleColChannels)+2 ~= numel(obj.BatchOpt.ColorChannel{2})
                obj.BatchOpt.ColorChannel = {'All'};         % specify the color channel
                obj.BatchOpt.ColorChannel{2} = [{'All'}, {'Displayed'}, PossibleColChannels];
            end
            % when elements GIU needs to be updated, update obj.BatchOpt
            % structure and after that update elements of GUI by the
            % following function
            obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.BatchOpt);    %
        end
        
        function updateBatchOptFromGUI(obj, event)
            % function updateBatchOptFromGUI(obj, event)
            %
            % update obj.BatchOpt from widgets of GUI
            % use an external function (Tools\updateBatchOptFromGUI_Shared.m) that is common for all tools
            % compatible with the Batch mode
            %
            % Parameters:
            % event: event from the callback
            
            obj.BatchOpt = updateBatchOptFromGUI_Shared(obj.BatchOpt, event.Source);
        end
        
        function returnBatchOpt(obj, BatchOptOut)
            % return structure with Batch Options and possible configurations
            % via the notify 'syncBatch' event
            % Parameters:
            % BatchOptOut: a local structure with Batch Options generated
            % during Continue callback. It may contain more fields than
            % obj.BatchOpt structure
            % 
            if nargin < 2
                BatchOptOut = obj.BatchOpt;
                % add parameters of the selected filter to the BatchOptOut structure
                ImageFiltersFields = fieldnames(obj.ImageFilters.(BatchOptOut.FilterName{1}));
                for i=1:numel(ImageFiltersFields)
                    if ~isfield(BatchOptOut, ImageFiltersFields{i})
                        BatchOptOut.(ImageFiltersFields{i}) = obj.ImageFilters.(BatchOptOut.FilterName{1}).(ImageFiltersFields{i});
                    end
                end
            end
            
            % add tooltips for the particular used image filter
            CurrentFilterTooltip = obj.ImageFilters.(BatchOptOut.FilterName{1}).mibBatchTooltip;
            fieldNames = fieldnames(CurrentFilterTooltip);
            for i = 1:numel(fieldNames)
                BatchOptOut.mibBatchTooltip.(fieldNames{i}) = CurrentFilterTooltip.(fieldNames{i});
            end
            BatchOptOut.mibBatchActionName = BatchOptOut.FilterName{1};
            BatchOptOut = rmfield(BatchOptOut, {'FilterGroup', 'id', 'FilterName'});
            
            % trigger syncBatch event to send BatchOptOut to mibBatchController 
            eventdata = ToggleEventData(BatchOptOut);
            notify(obj.mibModel, 'syncBatch', eventdata);
        end
        
        function FilterGroupValueChanged(obj, event)
            % update gui upon press of FilterGroup dropout
            if nargin < 2; event = obj.View.handles.FilterGroup; end 
            value = event.Value;
            switch value
                case 'Basic Image Filtering in the Spatial Domain'
                    obj.View.handles.FilterName.Items = obj.BasicFiltersList;
                    obj.BatchOpt.FilterName{2} = obj.BasicFiltersList;
                case 'Edge-Preserving Filtering'
                    obj.View.handles.FilterName.Items = obj.EdgePreservingFiltersList;
                    obj.BatchOpt.FilterName{2} = obj.EdgePreservingFiltersList;
                case 'Contrast Adjustment'
                    obj.View.handles.FilterName.Items = obj.ContrastFiltersList;
                    obj.BatchOpt.FilterName{2} = obj.ContrastFiltersList;
                case 'Image Binarization'
                    obj.View.handles.FilterName.Items = obj.BinarizationFiltersList;
                    obj.BatchOpt.FilterName{2} = obj.BinarizationFiltersList;
            end
            obj.BatchOpt.FilterName(1) = obj.BatchOpt.FilterName{2}(1);
            
            obj.BatchOpt.FilterGroup{1} = value;
            obj.FilterNameValueChanged();
        end
        
        function scrollWheel_Callback(obj, event)
            % verticalScrollAmount = event.VerticalScrollAmount;
            verticalScrollCount = event.VerticalScrollCount;
            h = obj.View.gui.CurrentObject;
            if isempty(h); return; end
            
            if obj.View.Figure.isControlPressed==0 && obj.View.Figure.isShiftPressed==0
                return;
            end

            % define multiplierFactor
            if obj.View.Figure.isControlPressed && obj.View.Figure.isShiftPressed
                multiplierFactor = 10;
            elseif obj.View.Figure.isControlPressed
                multiplierFactor = 0.1;
            elseif obj.View.Figure.isShiftPressed
                multiplierFactor = 1;
            end
            
            switch h.Type
                case 'uieditfield'
                    value = str2num(h.Value); %#ok<ST2NM>
                    if numel(value) > 1; return; end
                    
                    % splitVal = strsplit(h.Value, '.');
                    % multiplierFactor = 1;
                    % if numel(splitVal) == 2
                    %     nDigits = numel(splitVal{2});
                    %     multiplierFactor = multiplierFactor / 10^nDigits;
                    % end
                    
                    h.Value = num2str(value - verticalScrollCount*multiplierFactor);
                % case 'uinumericeditfield'
                %     splitVal = strsplit(num2str(h.Value), '.');
                %     multiplierFactor = 1;
                %     nDigits = 0;
                %     if numel(splitVal) == 2
                %         nDigits = numel(splitVal{2});
                %         multiplierFactor = multiplierFactor / 10^nDigits;
                %     end
                %     value = round(h.Value - verticalScrollCount*multiplierFactor, nDigits);
                %     value = max([h.Limits(1) value]);
                %     value = min([h.Limits(2) value]);
                %     h.Value = value;
                case {'uispinner', 'uinumericeditfield'}
                    % find number of floating digits
                    % splitVal = strsplit(num2str(h.Value), '.');
                    % multiplierFactor = 1;
                    % nDigits = 0;
                    % if numel(splitVal) == 2
                    %     nDigits = numel(splitVal{2});
                    %     multiplierFactor = multiplierFactor / 10^nDigits;
                    % end
                    % value = round(h.Value - verticalScrollCount*multiplierFactor, nDigits);
                    if multiplierFactor < 1
                        value = round(h.Value - verticalScrollCount*multiplierFactor, 3);
                    else
                        value = h.Value - verticalScrollCount*multiplierFactor;
                    end
                    value = max([h.Limits(1) value]);
                    value = min([h.Limits(2) value]);
                    h.Value = value;
            end
            obj.updateImageFiltersParameters(h, event);
        end

        function updateImageFiltersParameters(obj, hWidget, event)
            % update obj.ImageFilters structure with parameters of filters
            subBatchOpt = obj.ImageFilters.(obj.View.handles.FilterName.Value);
            obj.ImageFilters.(obj.View.handles.FilterName.Value) = updateBatchOptFromGUI_Shared(subBatchOpt, hWidget);
            try
                obj.renderThumbnailPreview();
                if obj.View.handles.AutopreviewCheckBox.Value % auto preview
                    obj.PreviewButtonPushed(); 
                end  
            catch err

            end

        end
        
        
        function FilterNameValueChanged(obj, event)
            % function FilterGroupValueChanged(obj, event)
            % update gui upon press of FilterName dropdown
            
            if nargin < 2; event = obj.View.handles.FilterName; end            
            value = event.Value;
            
            if ~isempty(obj.ParaHandles)
                for widgetId = 1:numel(obj.ParaHandles)
                    obj.ParaHandles{widgetId}.delete;
                end
                obj.ParaHandles = {};
            end
            
            if obj.MatlabR2019b     % MatlabR2019b or newer
                noRows = numel(obj.View.handles.GridLayoutParameters.RowHeight);    % get number of rows in the grid layout
                hParent = obj.View.handles.GridLayoutParameters;
            else
                noRows = 3;
                hParent = obj.View.handles.FilterparametersPanel;
                ParentPosition = obj.View.handles.FilterparametersPanel.Position;
                xStep = ParentPosition(3)/4;
                yStep = ParentPosition(4)/(noRows+1);
                widgetWidth = xStep - xStep/10;
                xShift = xStep/50;
                yShift = yStep/3;
            end
            
            paraList = obj.ImageFilters.(value);
            Tooltips = paraList.mibBatchTooltip;
            paraList = rmfield(paraList, 'mibBatchTooltip');
            
            paraNames = fieldnames(paraList);
            index = 1;
            rowId = 1;
            colId = 1;
            for widgetId = 1:numel(paraNames)
                % add label to the grid layout
                if ~islogical(paraList.(paraNames{widgetId}))
                    obj.ParaHandles{index} = uilabel(hParent, 'Text', paraNames{widgetId}, 'HorizontalAlignment', 'right');
                    if obj.MatlabR2019b
                        obj.ParaHandles{index}.Layout.Column = colId;
                        obj.ParaHandles{index}.Layout.Row = rowId;
                    else
                        obj.ParaHandles{index}.Position(1) = xStep*(colId-1)+xShift;
                        obj.ParaHandles{index}.Position(2) = ParentPosition(4) - (yStep*(rowId+1)-yShift);
                        obj.ParaHandles{index}.Position(3) = widgetWidth;
                    end
                    index = index + 1;
                end
                
                switch class(paraList.(paraNames{widgetId}))    % add widget
                    case 'char'     % generate string editbox
                        obj.ParaHandles{index} = uieditfield(hParent, 'text', ...
                            'Value', paraList.(paraNames{widgetId}),...
                            'Tooltip', Tooltips.(paraNames{widgetId}), ...
                            'ValueChangedFcn', @obj.updateImageFiltersParameters);
                    case 'cell'
                        if ~isnumeric(paraList.(paraNames{widgetId}){1})  % dropdown
                            obj.ParaHandles{index} = uidropdown(hParent, ...
                                'Items', paraList.(paraNames{widgetId}){2}, 'Value', paraList.(paraNames{widgetId}){1}, ...
                                'Tooltip', Tooltips.(paraNames{widgetId}), ...
                                'ValueChangedFcn', @obj.updateImageFiltersParameters);
                        else    % numeric
                            if numel(paraList.(paraNames{widgetId})) > 2     % rounding of numbers
                                RoundFractionalValues = paraList.(paraNames{widgetId}){3}; 
                            else
                                RoundFractionalValues = 'on';
                            end
                            if numel(paraList.(paraNames{widgetId})) > 1     % rounding of numbers
                                Limits = paraList.(paraNames{widgetId}){2}; 
                            else
                                Limits = [-Inf Inf];
                            end
                            % obj.ParaHandles{index} = uieditfield(hParent, 'numeric', ...
                            %     'Value', paraList.(paraNames{widgetId}){1}, 'Limits', Limits, 'RoundFractionalValues', RoundFractionalValues,...
                            %     'Tooltip', Tooltips.(paraNames{widgetId}), ...
                            %     'ValueChangedFcn', @obj.updateImageFiltersParameters);
                            obj.ParaHandles{index} = uispinner(hParent, ...
                                'Value', paraList.(paraNames{widgetId}){1}, 'Limits', Limits, ...
                                'RoundFractionalValues', RoundFractionalValues,...
                                'Tooltip', Tooltips.(paraNames{widgetId}), ...                                %'UserData', userData, ...
                                'ValueChangedFcn', @obj.updateImageFiltersParameters);
                        end
                    case 'logical'
                        obj.ParaHandles{index} = uicheckbox(hParent, ...
                            'Value', paraList.(paraNames{widgetId}),...
                            'Text', paraNames{widgetId}, ...
                            'Tooltip', Tooltips.(paraNames{widgetId}), ...
                            'ValueChangedFcn', @obj.updateImageFiltersParameters);
                end
                if obj.MatlabR2019b
                    obj.ParaHandles{index}.Layout.Column = colId+1;
                    obj.ParaHandles{index}.Layout.Row = rowId;
                else
                    obj.ParaHandles{index}.Position(1) = xStep*(colId)+xShift;
                    obj.ParaHandles{index}.Position(2) = ParentPosition(4) - (yStep*(rowId+1)-yShift);
                    obj.ParaHandles{index}.Position(3) = widgetWidth;
                end
                obj.ParaHandles{index}.Tag = paraNames{widgetId};
                index = index + 1; 
                rowId = rowId + 1;
                if rowId > noRows   % shift rowId and colId
                    rowId = 1;
                    colId = colId + 2;
                end
            end
            
            % update info text
            if ismember(value, obj.Filters3D)
                obj.View.handles.Mode3D.Enable = 'on';
            else
                obj.View.handles.Mode3D.Enable = 'off';
                obj.View.handles.Mode3D.Value = false;
            end
            if obj.MatlabR2019b
                obj.View.handles.InfoHTML.HTMLSource = sprintf('<p style="font-family: Sans-serif; font-size: small;">%s</p>', obj.mibModel.sessionSettings.ImageFilters.(value).mibBatchTooltip.Info);
            else
                obj.View.handles.InfoTextarea.Value = obj.mibModel.sessionSettings.ImageFilters.(value).mibBatchTooltip.Info;
            end
            
            obj.BatchOpt.FilterName{1} = value;
            obj.BatchOpt.Mode3D = obj.View.handles.Mode3D.Value;
            
            % enable/disable preview function for 3D datasets
            if obj.BatchOpt.Mode3D == 1
                obj.View.Figure.PreviewButton.Enable = 'off';
                obj.View.Figure.AutopreviewCheckBox.Enable = 'off';
                obj.View.Figure.AutopreviewCheckBox.Value = false;
            else
                obj.View.Figure.PreviewButton.Enable = 'on';
                obj.View.Figure.AutopreviewCheckBox.Enable = 'on';
                
                obj.renderThumbnailPreview();
                if obj.View.handles.AutopreviewCheckBox.Value; obj.PreviewButtonPushed(); end     % auto preview
            end
            
        end
        
        function helpButton_Callback(obj)
            global mibPath;
            web(fullfile(mibPath, 'techdoc/html/user-interface/menu/image/image-filters.html'), '-browser');
        end

        function Mode3DValueChanged(obj)
            % callback for Mode3D press
            val = obj.View.handles.Mode3D.Value;
            obj.BatchOpt = updateBatchOptFromGUI_Shared(obj.BatchOpt, obj.View.handles.Mode3D);
            if val == 1 && strcmp(obj.View.handles.DatasetType.Value, '2D, Slice')
                obj.View.handles.DatasetType.Value = '3D, Stack';
                obj.BatchOpt = updateBatchOptFromGUI_Shared(obj.BatchOpt, obj.View.handles.DatasetType);
            end
            
            % enable/disable preview function for 3D datasets
            if obj.View.handles.Mode3D.Value == 1
                obj.View.Figure.PreviewButton.Enable = 'off';
                obj.View.Figure.AutopreviewCheckBox.Enable = 'off';
                obj.View.Figure.AutopreviewCheckBox.Value = false;
            else
                obj.View.Figure.PreviewButton.Enable = 'on';
                obj.View.Figure.AutopreviewCheckBox.Enable = 'on';
            end
            
        end
        
        function renderThumbnailPreview(obj)
            % function renderThumbnailPreview(obj)
            % render an image for the thumbnail preview
            %if ismember(obj.BatchOpt.FilterName{1}, {'DNNdenoise','FastLocalLaplacian','FlatfieldCorrection', 'LocalBrighten', 'ReduceHaze', 'UnsharpMask'}); return; end % do not render preview for these filters
            if ismember(obj.BatchOpt.FilterName{1}, {'DNNdenoise'}) || obj.BatchOpt.Mode3D
                return; 
            end % do not render preview for these filters and 3D mode
            
            img = obj.Filter(obj.mibModel.sessionSettings.ImageFilters.TestImg);
            
            if strcmp(obj.BatchOpt.FilterGroup{1}, 'Image Binarization')
                SourceLayer = 'selection';
            else
                SourceLayer = obj.BatchOpt.SourceLayer{1};
            end
            
            switch SourceLayer
                case 'selection'
                    if strcmp(obj.BatchOpt.FilterName{1}, 'Edge')
                        thumbImg = obj.mibModel.sessionSettings.ImageFilters.TestImg;
                        thumbImg(img>0) = 255;
                        imshow(thumbImg, 'Parent', obj.View.handles.ThumbnailView2);
                    else
                        imshow(img, [], 'Parent', obj.View.handles.ThumbnailView2);
                    end
                otherwise
                    imshow(img, 'Parent', obj.View.handles.ThumbnailView2);
            end
        end
        
        function PreviewButtonPushed(obj)
            % generate filter preview for the currenly shown area
            getDataOptions.blockModeSwitch = 1;
            switch obj.BatchOpt.SourceLayer{1}
                case 'model'
                    img = cell2mat(obj.mibModel.getData2D(obj.BatchOpt.SourceLayer{1}, NaN, NaN, str2double(obj.BatchOpt.MaterialIndex), getDataOptions));
                case 'image'
                    switch obj.BatchOpt.ColorChannel{1}
                        case 'All'
                            ColCh = 0;
                        case 'Displayed'
                            ColCh = NaN;
                        otherwise
                            ColCh = str2double(obj.BatchOpt.ColorChannel{1});
                    end
                    img = cell2mat(obj.mibModel.getData2D('image', NaN, NaN, ColCh, getDataOptions));
                otherwise
                    img = cell2mat(obj.mibModel.getData2D(obj.BatchOpt.SourceLayer{1}, NaN, NaN, NaN, getDataOptions));
            end
            
            if strcmp(obj.BatchOpt.FilterGroup{1}, 'Image Binarization') && size(img, 3) > 1
                errordlg(sprintf('!!! Error !!!\n\nPlease select a single color channel before binarization'), 'Too many color channels');
                return;
            end
            
            img = obj.Filter(img);
            if isempty(img); return; end
            
            if strcmp(obj.BatchOpt.FilterGroup{1}, 'Image Binarization')
                SourceLayer = 'selection';
                if ismember(obj.BatchOpt.FilterName{1}, {'SlicClustering', 'WatershedClustering'})   % exceptional preview for binary clustering
                    img = uint8(double(img) ./ double(max(img(:))) * 255);
                    eventdata = ToggleEventData(img);   % send image to show in  mibView.handles.mibImageAxes as ToggleEventData class
                    notify(obj.mibModel, 'plotImage', eventdata);
                    return;
                end
            else
                SourceLayer = obj.BatchOpt.SourceLayer{1};
            end
            
            switch SourceLayer
                case 'selection'
                    getRGBimageOptions.blockModeSwitch = 1;
                    getRGBimageOptions.resize = 'no';
                    currTransparency = obj.mibModel.preferences.Colors.SelectionTransparency;
                    obj.mibModel.preferences.Colors.SelectionTransparency = 1;
                    I = obj.mibModel.getRGBimage(getRGBimageOptions);
                    I(img==1) = obj.mibModel.I{obj.mibModel.Id}.meta('MaxInt');
                    eventdata = ToggleEventData(I);   % send image to show in  mibView.handles.mibImageAxes as ToggleEventData class
                    notify(obj.mibModel, 'plotImage', eventdata);
                    obj.mibModel.preferences.Colors.SelectionTransparency = currTransparency;
                case 'mask'
                    getRGBimageOptions.blockModeSwitch = 1;
                    getRGBimageOptions.resize = 'no';
                    currTransparency = obj.mibModel.preferences.Colors.MaskTransparency;
                    obj.mibModel.preferences.Colors.MaskTransparency = 1;
                    I = obj.mibModel.getRGBimage(getRGBimageOptions);
                    I(img==1) = obj.mibModel.I{obj.mibModel.Id}.meta('MaxInt');
                    eventdata = ToggleEventData(I);   % send image to show in  mibView.handles.mibImageAxes as ToggleEventData class
                    notify(obj.mibModel, 'plotImage', eventdata);
                    obj.mibModel.preferences.Colors.MaskTransparency = currTransparency;
                case 'model'
                    getRGBimageOptions.blockModeSwitch = 1;
                    getRGBimageOptions.resize = 'no';
                    currTransparency = obj.mibModel.preferences.Colors.MaskTransparency;
                    obj.mibModel.preferences.Colors.ModelTransparency = 1;
                    I = obj.mibModel.getRGBimage(getRGBimageOptions);
                    I(img==1) = obj.mibModel.I{obj.mibModel.Id}.meta('MaxInt');
                    eventdata = ToggleEventData(I);   % send image to show in  mibView.handles.mibImageAxes as ToggleEventData class
                    notify(obj.mibModel, 'plotImage', eventdata);
                    obj.mibModel.preferences.Colors.ModelTransparency = currTransparency;
                otherwise
                    % convert to 8bit
                    if ~isa(img, 'uint8')
                        currViewPort = obj.mibModel.I{obj.mibModel.Id}.viewPort;
                        max_int = obj.mibModel.I{obj.mibModel.Id}.meta('MaxInt');
                        if ~obj.mibModel.mibLiveStretchCheck
                            % convert to the 8bit image
                            if size(img, 3) == 1
                                colCh = obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel;
                                if currViewPort.min(colCh) ~= 0 || currViewPort.max(colCh) ~= max_int || currViewPort.gamma(colCh) ~= 1
                                    img = imadjust(img, [currViewPort.min(colCh)/max_int currViewPort.max(colCh)/max_int], [0 1], currViewPort.gamma(colCh));
                                end
                            else
                                if max(currViewPort.min) > 0 || min(currViewPort.max) ~= max_int || sum(currViewPort.gamma) ~= 3
                                    for colCh=1:3
                                        img(:,:,colCh) = imadjust(img(:,:,colCh), ...
                                            [currViewPort.min(colCh)/max_int currViewPort.max(colCh)/max_int], [0 1], currViewPort.gamma(colCh));
                                    end
                                end
                            end
                            img = uint8(img/256);
                        end
                    end

                    eventdata = ToggleEventData(img);   % send image to show in  mibView.handles.mibImageAxes as ToggleEventData class
                    notify(obj.mibModel, 'plotImage', eventdata);
            end
        end
    end
end