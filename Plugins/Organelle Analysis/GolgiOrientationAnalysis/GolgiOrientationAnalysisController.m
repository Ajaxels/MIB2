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
% Date: 11.12.2023

classdef GolgiOrientationAnalysisController < handle
    % @type GolgiOrientationAnalysisController class is a template class for using with
    % GUI developed using appdesigner of Matlab
    %
    % @code
    % obj.startController('GolgiOrientationAnalysisController'); // as GUI tool
    % @endcode
    % or 
    % @code 
    % // a code below was used for mibImageArithmeticController
    % BatchOpt.Parameter = 'test';  // fill edit boxes as strings
    % BatchOpt.Checkbox = true;     // fill checkboxes with logicals: true/false
    % BatchOpt.Popup = {'value'};        // value for the popups as a cell
    % BatchOpt.Radio = {'Radio1'};          // selection of radio buttons, as cell with the handle of the target radio button
    % BatchOpt.showWaitbar = true;  // show or not the waitbar
    % obj.startController('GolgiOrientationAnalysisController', [], BatchOpt); // start GolgiOrientationAnalysisController in the batch mode
    % @endcode
    % or
    % @code
    % // trigger return of the possible Options using returnBatchOpt function
    % // using notify syncBatch event
    % obj.startController('GolgiOrientationAnalysisController', [], NaN);
    % @endcode
    
	% Updates
	%     
    
    properties
        mibModel
        % handles to mibModel
        View
        % handle to the view / GolgiOrientationAnalysisGUI
        listener
        % a cell array with handles to listeners
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
            end
        end
    end
    
    methods
        function obj = GolgiOrientationAnalysisController(mibModel, varargin)
            obj.mibModel = mibModel;    % assign model
            
            %% fill the BatchOpt structure with default values
            % fields of the structure should correspond to the starting
            % text in the each widget tooltip.
            % For example, this demo template has an edit box, where the
            % tooltip starts with "Parameter:...". Text Parameter
            % indicates field of the BatchOpt structure that defines value
            % for this widget
            
            % parameters
            obj.BatchOpt.Mode = {'Complete model'};
            obj.BatchOpt.Mode{2} = {'Complete model', 'Cropped cells'};
            obj.BatchOpt.Method = {'Relative to nucleus'};
            obj.BatchOpt.Method{2} = {'Relative to nucleus', 'Relative to cell boundary', 'Both'};

            obj.BatchOpt.imagePath = obj.mibModel.myPath;
            obj.BatchOpt.golgiModelPath = obj.mibModel.myPath;
            obj.BatchOpt.nucleiModelPath = obj.mibModel.myPath;
            obj.BatchOpt.celloutlineModelPath = obj.mibModel.myPath;

            obj.BatchOpt.InputDirectories = {'Start by selecting directories'};
            obj.BatchOpt.InputDirectories{2} = {'Start by selecting directories'};
            obj.BatchOpt.OutputFilename = fullfile(obj.mibModel.myPath, 'GolgiOrientation.xls');
            obj.BatchOpt.FilenameImageExtension = {'AM'};
            obj.BatchOpt.FilenameImageExtension{2} = upper(obj.mibModel.preferences.System.Files.StdExt);
            obj.BatchOpt.FilenameModelExtension = {'MODEL'};    % extension for model files
            obj.BatchOpt.FilenameModelExtension{2} = {'MODEL', 'TIF', 'TIFF'};

            obj.BatchOpt.MaterialGolgi{1} = 3; % numeric value
            obj.BatchOpt.MaterialGolgi{2} = [0, Inf]; % possible limits value
            obj.BatchOpt.MaterialGolgi{3} = 'on'; % round the numeric value
            obj.BatchOpt.MaterialNucleus{1} = 2;
            obj.BatchOpt.MaterialNucleus{2} = [0, Inf]; % possible limits value
            obj.BatchOpt.MaterialNucleus{3} = 'on'; % round the numeric value
            obj.BatchOpt.MaterialCell{1} = 1;
            obj.BatchOpt.MaterialCell{2} = [0, Inf]; % possible limits value
            obj.BatchOpt.MaterialCell{3} = 'on'; % round the numeric value
            obj.BatchOpt.ThresholdGolgi{1} = 0; % numeric value
            obj.BatchOpt.ThresholdGolgi{2} = [0, Inf]; % possible limits value
            obj.BatchOpt.ThresholdGolgi{3} = 'on'; % round the numeric value
            obj.BatchOpt.ThresholdNucleus{1} = 0;
            obj.BatchOpt.ThresholdNucleus{2} = [0, Inf]; % possible limits value
            obj.BatchOpt.ThresholdNucleus{3} = 'on'; % round the numeric value
            obj.BatchOpt.ThresholdCell{1} = 0;
            obj.BatchOpt.ThresholdCell{2} = [0, Inf]; % possible limits value
            obj.BatchOpt.ThresholdCell{3} = 'on'; % round the numeric value
            obj.BatchOpt.DistanceMaxFromNucleus{1} = 200;
            obj.BatchOpt.DistanceMaxFromNucleus{2} = [1 Inf];
            obj.BatchOpt.DistanceMaxFromNucleus{3} = 'on'; % round the numeric value
            obj.BatchOpt.showWaitbar = true;

            % tooltips
            obj.BatchOpt.mibBatchTooltip.Mode = sprintf('When Complete model, a single model file is expected, while for the cropped mode each cell should be cropped out from the dataset');
            
            obj.BatchOpt.mibBatchTooltip.imagePath = 'Select file containing the image dataset';
            obj.BatchOpt.mibBatchTooltip.golgiModelPath = 'Select model file containing segmented Golgi';
            obj.BatchOpt.mibBatchTooltip.nucleiModelPath = 'Select model file containing segmented Nuclei';
            obj.BatchOpt.mibBatchTooltip.celloutlineModelPath = 'Select model file containing segmented Cell outlines';

            obj.BatchOpt.mibBatchTooltip.InputDirectories = sprintf('List of input directories containing a dataset and a model with segmented Golgi, nucleus and/or cell shape');
            obj.BatchOpt.mibBatchTooltip.OutputFilename = sprintf('Name of output filename with results');
            obj.BatchOpt.mibBatchTooltip.FilenameImageExtension = sprintf('Filename extension of images');
            obj.BatchOpt.mibBatchTooltip.FilenameModelExtension = sprintf('Filename extension of models');
            
            obj.BatchOpt.mibBatchTooltip.Method = sprintf('Method to calculate orientation of Golgi');
            obj.BatchOpt.mibBatchTooltip.MaterialGolgi = sprintf('Index of material encoding Golgi');
            obj.BatchOpt.mibBatchTooltip.MaterialNucleus = sprintf('Index of material encoding nucleus');
            obj.BatchOpt.mibBatchTooltip.MaterialCell = sprintf('Index of material encoding cell boundary');
            obj.BatchOpt.mibBatchTooltip.ThresholdGolgi = sprintf('Keep Golgi objects that are larger than this value in pixels');
            obj.BatchOpt.mibBatchTooltip.ThresholdNucleus = sprintf('Keep Nuclei objects that are larger than this value in pixels');
            obj.BatchOpt.mibBatchTooltip.ThresholdCell = sprintf('Keep Cell objects that are larger than this value in pixels');
            obj.BatchOpt.mibBatchTooltip.DistanceMaxFromNucleus = sprintf('Max distance for automatic crop when calculating distance map when Relative to nucleus method is used, in pixels');
            
            obj.BatchOpt.mibBatchTooltip.showWaitbar = sprintf('show or not progress bar during the plugin work');

            %% part below is only valid for use of the plugin from MIB batch controller
            % comment it if intended use not from the batch mode
            obj.BatchOpt.mibBatchSectionName = 'Menu -> Plugins';    % section name for the Batch
            obj.BatchOpt.mibBatchActionName = 'GolgiOrientationAnalysis';           % name of the plugin
            
            % get the stored settings of the widget
            if isfield(obj.mibModel.sessionSettings, 'GolgiOrientationAnalysis')
                obj.BatchOpt = mibConcatenateStructures(obj.BatchOpt, obj.mibModel.sessionSettings.GolgiOrientationAnalysis.BatchOpt);
            end

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
                
                obj.Calculate();
                notify(obj, 'closeEvent');
                return;
            end
            
            guiName = 'GolgiOrientationAnalysisGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % add information text
            obj.addInfo();

            % init the widgets
            %destBuffers = arrayfun(@(x) sprintf('Container %d', x), 1:obj.mibModel.maxId, 'UniformOutput', false);
            %obj.View.handles.Popup.String = destBuffers;
            
			% move the window to the left hand side of the main window
            obj.View.gui = moveWindowOutside(obj.View.gui, 'left');
            
            % resize all elements of the GUI
            % mibRescaleWidgets(obj.View.gui); % this function is not yet
            % compatible with appdesigner
            
            % update font and size
            % you may need to replace "obj.View.handles.text1" with tag of any text field of your own GUI
            % this function is not yet
            global Font;
            if ~isempty(Font)
                if obj.View.handles.golgiModelLabel.FontSize ~= Font.FontSize ...
                        || ~strcmp(obj.View.handles.golgiModelLabel.FontName, Font.FontName)
                    mibUpdateFontSize(obj.View.gui, Font);
                end
            end
            
			obj.updateWidgets();
			% update widgets from the BatchOpt structure
            obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.BatchOpt);
            
            obj.selectMode();

			% obj.View.gui.WindowStyle = 'modal';     % make window modal
			
			% add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % store plugin configuration
            obj.mibModel.sessionSettings.GolgiOrientationAnalysis.BatchOpt = obj.BatchOpt;
            
            % closing GolgiOrientationAnalysisController window
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
            if nargin < 2; BatchOptOut = obj.BatchOpt; end
            
            if isfield(BatchOptOut, 'id'); BatchOptOut = rmfield(BatchOptOut, 'id'); end  % remove id field
            % trigger syncBatch event to send BatchOptOut to mibBatchController 
            eventdata = ToggleEventData(BatchOptOut);
            notify(obj.mibModel, 'syncBatch', eventdata);
        end
        
        function selectMode(obj)
            % function selectMode(obj)
            % select mode: complete or cropped to use
            
            obj.BatchOpt.Mode{1} = obj.View.handles.Mode.Value;
            obj.addInfo();
            switch obj.BatchOpt.Mode{1}
                case 'Cropped cells'
                    obj.View.handles.TabGroup.SelectedTab = obj.View.handles.CroppedCellsDirsTab;
                    obj.View.handles.CroppedCellsDirsGridLayout.BackgroundColor = [0.91 0.99 0.90];
                    obj.View.handles.directoriesLeftGridLayout.BackgroundColor = [0.91 0.99 0.90];
                    obj.View.handles.CompleteModelFilesGridLayout.BackgroundColor = [1.00 0.78 0.78];

                    obj.View.handles.InputDirectories.Enable = 'on';
                    obj.View.handles.imagePath.Enable = 'off';
                    obj.View.handles.golgiModelPath.Enable = 'off';
                    obj.View.handles.nucleiModelPath.Enable = 'off';
                    obj.View.handles.celloutlineModelPath.Enable = 'off';

                    obj.View.handles.MaterialGolgi.Enable = 'on';
                    obj.View.handles.MaterialNucleus.Enable = 'on';
                    obj.View.handles.MaterialCell.Enable = 'on';
                    obj.View.handles.ThresholdGolgi.Enable = 'off';
                    obj.View.handles.ThresholdNucleus.Enable = 'off';
                    obj.View.handles.ThresholdCell.Enable = 'off';
                    obj.View.handles.DistanceMaxFromNucleus.Enable = 'off';
                case 'Complete model'
                    obj.View.handles.TabGroup.SelectedTab = obj.View.handles.CompleteModelFilesTab;
                    obj.View.handles.CroppedCellsDirsGridLayout.BackgroundColor = [1.00 0.78 0.78];
                    obj.View.handles.directoriesLeftGridLayout.BackgroundColor = [1.00 0.78 0.78]; 
                    obj.View.handles.CompleteModelFilesGridLayout.BackgroundColor = [0.91 0.99 0.90];

                    obj.View.handles.InputDirectories.Enable = 'off';
                    obj.View.handles.imagePath.Enable = 'on';
                    obj.View.handles.golgiModelPath.Enable = 'on';
                    obj.View.handles.nucleiModelPath.Enable = 'on';
                    obj.View.handles.celloutlineModelPath.Enable = 'on';

                    obj.View.handles.MaterialGolgi.Enable = 'off';
                    obj.View.handles.MaterialNucleus.Enable = 'off';
                    obj.View.handles.MaterialCell.Enable = 'off';
                    obj.View.handles.ThresholdGolgi.Enable = 'on';
                    obj.View.handles.ThresholdNucleus.Enable = 'on';
                    obj.View.handles.ThresholdCell.Enable = 'on';
                    obj.View.handles.DistanceMaxFromNucleus.Enable = 'on';
            end
        end

        function addInfo(obj)
            % function addInfo(obj)
            % Add information about the plugin into the info panel

            switch obj.BatchOpt.Mode{1}
                case 'Complete model'
                    infoText = ['<p style="font-family:arial; font-size: 10pt">' ...
                               'Golgi orientation analysis calculates relative orientation of Golgi relative to ' ...
                                'Nucleus or Cell boundaries<br>' ...
                                '<ul style="font-family:arial; font-size: 9pt">' ...
                                '<li>Segment Golgi, Nucleus and/or Cell shape and save them as separate models, ' ...
                                'where indices indicate cell id (for example, in the cell model indices 1001-1007 indicate Paneth cells ' ...
                                'and the corresponding Golgi model has Golgi segmented within the same cells stored as 1001-1007)</li>' ...
                                '<li>Make sure that the voxels are isotropic!</li>' ...
                                '<li>Specify output filename and file formats</li>' ...
                                '<li>Select the image and model files in the Complete model files tab</li>' ...
                                '<li>In the Settings tab select the method and update object size thresholds and distances from nuclei</li>' ...
                                '<li>Hit the Calculate button</li>' ...
                                '</ul>' ...
                               '</p>'];
                case 'Cropped cells'
                    infoText = ['<p style="font-family:arial; font-size: 10pt">' ...
                        'Golgi orientation analysis calculates relative orientation of Golgi relative to ' ...
                        'Nucleus or Cell boundaries<br>' ...
                        '<ul style="font-family:arial; font-size: 9pt">' ...
                        '<li>Segment Golgi, Nucleus and/or Cell shape; 1 segmented cell/per file</li>' ...
                        '<li>Make sure that the voxels are isotropic!</li>' ...
                        '<li>Arrange data into directories containing 1 image and 1 model file</li>' ...
                        '<li>Select directories in the Cropped cells dirs tab</li>' ...
                        '<li>Specify output filename and file formats</li>' ...
                        '<li>In the Settings tab update indices of segmented materials</li>' ...
                        '<li>Hit the Calculate button</li>' ...
                        '</ul>' ...
                        '</p>'];
            end
            obj.View.handles.infoHTML.HTMLSource = infoText;
        end

        function selectOutputFilename(obj, sourceTag)
            % function selectOutputFilename(obj, sourceTag)
            % select filename for results
            %
            % Parameters:
            % sourceTag: tag of the pressed button
            
            switch sourceTag
                case 'selectOutputFilename'
                    Filters = {'*.mat',  'Matlab format (*.mat)';...
                        '*.csv',   'Comma-separated value (*.csv)';...
                        '*.xls',   'Excel format (*.xls)'; };
        
                    [filename, path, FilterIndex] = uiputfile(Filters, 'Select file to save results...', obj.BatchOpt.OutputFilename); %...
                    if isequal(filename,0); return; end % check for cancel
        
                    obj.BatchOpt.OutputFilename = fullfile(path, filename);
                    obj.View.handles.OutputFilename.Value = obj.BatchOpt.OutputFilename;
                case {'selectImagePath','selectGolgiModel', 'selectNucleiModel', 'selectCelloutlineModel'}
                    switch sourceTag
                        case 'selectImagePath'
                            fieldName = 'imagePath';
                            dlgTitle = 'Select file containing image dataset';
                            fnExt = lower(obj.BatchOpt.FilenameImageExtension{1});
                        case 'selectGolgiModel'
                            fieldName = 'golgiModelPath';
                            dlgTitle = 'Select model file containing segmented Golgi';
                            fnExt = lower(obj.BatchOpt.FilenameModelExtension{1});
                        case 'selectNucleiModel'
                            fieldName = 'nucleiModelPath';
                            dlgTitle = 'Select model file containing segmented Nuclei';
                            fnExt = lower(obj.BatchOpt.FilenameModelExtension{1});
                        case 'selectCelloutlineModel'
                            fieldName = 'celloutlineModelPath';
                            dlgTitle = 'Select model file containing segmented Cell outlines';
                            fnExt = lower(obj.BatchOpt.FilenameModelExtension{1});
                    end
                    Filters = {sprintf('*.%s', fnExt),  sprintf('Model file (*.%s)', fnExt) ;...
                        '*.*',   'All files (*.*)' }; 
                    
                    [file, path] = uigetfile(Filters, dlgTitle, obj.BatchOpt.(fieldName));
                    obj.BatchOpt.(fieldName) = fullfile(path, file);
                    obj.View.handles.(fieldName).Value = obj.BatchOpt.(fieldName);
            end
            % the two following commands are fix of sending the DeepMIB
            % window behind main MIB window
            drawnow;
            figure(obj.View.gui);
        end

        function selectInputDirectories(obj)
            % function selectInputDirectories(obj)
            % select input directories with images and models

            selpath = uigetfile_n_dir(obj.mibModel.myPath, 'Select directories');
            if isempty(selpath); return; end
            selpath = selpath'; % transpose
            selpath(~isfolder(selpath)) = [];   % remove filenames, keep only folders
            if isempty(selpath); return; end

            % remove 'Start by selecting directories'
            obj.BatchOpt.InputDirectories{2}(ismember(obj.BatchOpt.InputDirectories{2}, 'Start by selecting directories')) = [];

            duplicateIds = ismember(lower(selpath), lower(obj.BatchOpt.InputDirectories{2}));
            selpath(duplicateIds) = [];
            obj.BatchOpt.InputDirectories{2} = [obj.BatchOpt.InputDirectories{2}; selpath];
            obj.BatchOpt.InputDirectories{2} = sort(obj.BatchOpt.InputDirectories{2});
            obj.BatchOpt.InputDirectories{1} = obj.BatchOpt.InputDirectories{2}{1};
            
            %update GUI
            obj.View.handles.InputDirectories.Items = obj.BatchOpt.InputDirectories{2};
            obj.View.handles.InputDirectories.Value = obj.BatchOpt.InputDirectories{1};

            % the two following commands are fix of sending the DeepMIB
            % window behind main MIB window
            drawnow;
            figure(obj.View.gui);
        end

        function removeSelectedDirectory(obj, parameter)
            % function removeSelectedDirectory(obj, parameter)
            % remove selected or all directory(ies) from the list of input
            % directories
            %
            % Parameters:
            % parameter: string, 
            %   "all"-remove all directories (default); 
            %   "selected" - remove the selected directory

            if nargin < 2; parameter = 'all'; end
            
            switch parameter
                case 'all'
                    obj.BatchOpt.InputDirectories = {'Start by selecting directories'};
                    obj.BatchOpt.InputDirectories{2} = {'Start by selecting directories'};
                case 'selected'
                    selectedDir = obj.View.handles.InputDirectories.Value;
                    obj.BatchOpt.InputDirectories{2}(ismember(obj.BatchOpt.InputDirectories{2}, selectedDir)) = [];
                    if numel(obj.BatchOpt.InputDirectories{2}) == 0
                        obj.BatchOpt.InputDirectories = {'Start by selecting directories'};
                        obj.BatchOpt.InputDirectories{2} = {'Start by selecting directories'};
                    end
            end
            obj.BatchOpt.InputDirectories{1} = obj.BatchOpt.InputDirectories{2}{1};
            obj.View.handles.InputDirectories.Items = obj.BatchOpt.InputDirectories{2};
            obj.View.handles.InputDirectories.Value = obj.BatchOpt.InputDirectories{1};
        end

        function model = loadModel(obj, modelFilename)
            % function loadModel(obj, modelFilename)
            % load model provided in modelFilename
            %
            % Parameters:
            % modelFilename: cell array with model filename

            model = [];
            if nargin < 2; return; end

            modelFilename = modelFilename{1};
            [path, fn, ext] = fileparts(modelFilename);
            
            switch lower(ext)
                case '.model'
                    res = load(modelFilename, '-mat');
                    model = res.(res.modelVariable);
                case '.tif'
                    meta = imfinfo(modelFilename);
                    model = zeros([meta(1).Height, meta(1).Width, numel(meta)], 'uint8');
                    for sliceId = 1:numel(meta)
                        model(:, :, sliceId) = imread(modelFilename, 'Index', sliceId);
                    end
            end
        end


        % ------------------------------------------------------------------
        % % Additional functions and callbacks
        function Calculate(obj)
            % start main calculation of the plugin

            % turn off warnings when adding a new row into the results table
            warning('off', 'MATLAB:table:RowsAddedExistingVars');
            
            switch obj.BatchOpt.Mode{1}
                case 'Complete model'
                    obj.calculateCompleteMode();
                case 'Cropped cells'
                    obj.calculateCroppedMode();
            end

            % turn on warnings when adding a new row into the results table
            warning('on', 'MATLAB:table:RowsAddedExistingVars');
        end

        function calculateCompleteMode(obj)
            % function calculateCompleteMode(obj)
            % calculate Golgi orientation from models that contain
            % Golgi/Nuclei/Cell outlines of all cells that should be used
            % for calculations
        
            % check presence of image and model files
            if exist(obj.BatchOpt.imagePath, 'file') ~= 2
                res = uiconfirm(obj.View.gui, ...
                    sprintf('!!! Warning !!!\n\nImage file has not been found!\nPlease update "Complete model files->Image filename"\nor continue to use pixels as units.'),...
                    'Missing image', ...
                    'Options', {'Use pixels as units', 'Cancel'}, ...
                    'DefaultOption', 2, 'CancelOption', 2, ...
                    'Icon', 'warning');
                if strcmp(res, 'Cancel'); return; end

                % define pixel size
                pixSize.x = 1;
                pixSize.y = 1;
                pixSize.z = 1;
            else
                % load image
                %[mImg, img_info, pixSize] = mibLoadImages(imageFilename, getDataOpt);
                % define options to load images
                getDataOpt.waitbar = false;
                getDataOpt.silentMode = true;
                [~, ~, pixSize] = mibGetImageMetadata({obj.BatchOpt.imagePath}, getDataOpt);
            end

            if exist(obj.BatchOpt.golgiModelPath, 'file') ~= 2
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nA model file with segmented Golgi is required!\n\nUse\nComplete model files->Golgi model\nto specify it'), ...
                    'Missing model with Golgi', 'Icon', 'error');
                return;
            end

            if (strcmp(obj.BatchOpt.Method{1}, 'Relative to nucleus') || strcmp(obj.BatchOpt.Method{1}, 'Both')) && exist(obj.BatchOpt.nucleiModelPath, 'file') ~= 2
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nA model file with segmented Nuclei is required!\n\nUse\nComplete model files->Nuclei model\nto specify it'), ...
                    'Missing model with Golgi', 'Icon', 'error');
                return;
            end
            if (strcmp(obj.BatchOpt.Method{1}, 'Relative to cell boundary') || strcmp(obj.BatchOpt.Method{1}, 'Both')) && exist(obj.BatchOpt.celloutlineModelPath, 'file') ~= 2
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nA model file with segmented Cell outlines is required!\n\nUse\nComplete model files->Cell outlines model\nto specify it'), ...
                    'Missing model with Golgi', 'Icon', 'error');
                return;
            end
            
            % define options for calculation of distance maps
            distFilterOpt.FilterName = {'DistanceMap'};
            distFilterOpt.DatasetType = {'3D, Stack'};
            distFilterOpt.Mode3D = true;
            distFilterOpt.AspectRatio3D = '1 1 1';
            distFilterOpt.SourceLayer = {'model'};
            distFilterOpt.ColorChannel = {'All'};
            distFilterOpt.Method = {'euclidean'};

            %% detect Golgi
            tic
            obj.BatchOpt.showWaitbar = true;
            if obj.BatchOpt.showWaitbar
                pwb = PoolWaitbar(1, sprintf('Loading and detecting Golgi'), [], ...
                    'Golgi Orientation Calculations', ...
                    obj.View.gui); 
                pwb.updateMaxNumberOfIterations(5);
            end

            % load Golgi model as matrix
            loadedModel = obj.loadModel({obj.BatchOpt.golgiModelPath});
            % detect cell ids with detected Golgi models
            golgiIds = unique(loadedModel);

            % get image dimensions
            [height, width, depth] = size(loadedModel);

            % detect individual Golgi
            CC = bwconncomp(loadedModel, 26);
            % remove small golgi objects
            if obj.BatchOpt.ThresholdGolgi{1} > 0
                golgiSizeList = cellfun(@(s) numel(s), CC.PixelIdxList);
                removeGolgiIds = find(golgiSizeList<obj.BatchOpt.ThresholdGolgi{1});
                CC.PixelIdxList(removeGolgiIds) = [];
                CC.NumObjects = numel(CC.PixelIdxList);
            end
            golgiIds = zeros([CC.NumObjects, 1]); % create list of cell Ids for detected Golgi
            for golgiId=1:CC.NumObjects
                golgiIds(golgiId) = double(loadedModel(CC.PixelIdxList{golgiId}(1)));
                % convert indices to x,y,z coordinates
                [CC.y{golgiId}, CC.x{golgiId}, CC.z{golgiId}] = ind2sub([height, width, depth], CC.PixelIdxList{golgiId});
            end

            % sort the indices
            if obj.BatchOpt.showWaitbar
                if pwb.getCancelState(); delete(pwb); return; end
                pwb.updateText(sprintf('Sorting golgi indices\nPlease wait...'));
            end
            
            [~, indx] = sort(golgiIds);
            golgiCC = CC;
            for golgiId=1:CC.NumObjects
                golgiCC.PixelIdxList(golgiId) = CC.PixelIdxList(indx(golgiId));
                golgiCC.x(golgiId) = CC.x(indx(golgiId));
                golgiCC.y(golgiId) = CC.y(indx(golgiId));
                golgiCC.z(golgiId) = CC.z(indx(golgiId));
                golgiCC.CellIds(golgiId) = golgiIds(indx(golgiId));
            end
            golgiCC.GolgiIdsAsDetected = indx';
            
            % crate a table for results
            % 'Cell Id' -> index of the cell, 
            %       1,2,3-Paneth, 
            %       1001, 1002...-> Stem
            %       2001, 2002...-> Border Stem
            %       3001, 3002...-> TA cells
            % 'Golgi stack Id' -> index of golgi stacks as detected by bwconncomp, after that the indices are resorted to match the order of cells
            % 'Golgi index' -> index of golgi stack in a cell, 1.2.3 etc
            % 'Golgi volume, units' -> volume of Golgi in units
            % 'Golgi volume, px' -> volume of Golgi in pixels
            % 'Std relative to Nucleus' -> standard deviation of distance
            % of pixels inside golgi to nucleus, [0-equal distance of all
            % pixels to Nucleus, i.e. golgi is parallel to nucleus; larger values indicate
            % more perpendicular orientation
            % 'Std relative to Cell boundary' - standard deviation of distance
            % of pixels inside golgi to cell boundaries, [0-equal distance of all
            % pixels to cell boundary, i.e. golgi is parallel to boundary; larger values indicate
            % more perpendicular orientation
            % 'Nucleus volume, units' -> volume of nucleus in units
            % 'Nucleus volume, px' -> volume of nucleus in pixels
            % 'Cell volume, units' -> volume of cells in units
            % 'Cell volume, px' -> volume of cells in pixels
            columnNames = {'Cell Id', 'Golgi stack Id', 'Golgi index', 'Golgi volume, units', 'Golgi volume, px'...
                'Std relative to Nucleus', 'Std relative to Cell boundary', ...
                'Nucleus volume, units', 'Nucleus volume, px', 'Cell volume, units', 'Cell volume, px'};
            columnTypes = {'double', 'double', 'double', 'double', 'double', ...
                           'double', 'double', ...
                           'double', 'double', 'double', 'double'};
            outTable = table('Size', [numel(golgiIds), numel(columnNames)], ...
                'VariableTypes', columnTypes, ...
                'VariableNames', columnNames);
            tableIndex = 0;

            %% Load and detect cell outlines
            if strcmp(obj.BatchOpt.Method{1}, 'Relative to cell boundary') || strcmp(obj.BatchOpt.Method{1}, 'Both')
                if obj.BatchOpt.showWaitbar
                    if pwb.getCancelState(); delete(pwb); return; end
                    pwb.updateText(sprintf('Loading and detecting cell boundaries\nPlease wait...'));
                    pwb.increment();
                end

                loadedModel = obj.loadModel({obj.BatchOpt.celloutlineModelPath});
                cellStats = regionprops(loadedModel, {'Area', 'BoundingBox'});

                % remove small Cell boundaries objects
                if obj.BatchOpt.ThresholdCell{1} > 0
                    % detect not empty indices
                    area = [cellStats.Area];
                    removeCellBoundaryIds = find(area < obj.BatchOpt.ThresholdCell{1} & area > 0);
                    if ~isempty(removeCellBoundaryIds); [cellStats(removeCellBoundaryIds).Area] = deal(0); end
                end

                % detect not empty indices
                area = [cellStats.Area];
                cellboundaryIds = find(~area==0);
                % find intersection of golgi and cell boundaries models
                cellboundaryIds = intersect(golgiCC.CellIds, cellboundaryIds); 

                if obj.BatchOpt.showWaitbar
                    if pwb.getCancelState(); delete(pwb); return; end
                    pwb.updateText(sprintf('Processing cell boundaries\nPlease wait...'));
                    pwb.increaseMaxNumberOfIterations(numel(cellboundaryIds))
                end

                for index = 1:numel(cellboundaryIds)
                    % crop the cell out of the full volume
                    cellId = cellboundaryIds(index);
                    x1 = ceil(cellStats(cellId).BoundingBox(1));
                    y1 = ceil(cellStats(cellId).BoundingBox(2));
                    z1 = ceil(cellStats(cellId).BoundingBox(3));
                    x2 = x1 + cellStats(cellId).BoundingBox(4) - 1;
                    y2 = y1 + cellStats(cellId).BoundingBox(5) - 1;
                    z2 = z1 + cellStats(cellId).BoundingBox(6) - 1;
                    
                    distMapCell = loadedModel(y1:y2, x1:x2, z1:z2);
                    distMapCell = distMapCell & (distMapCell == cellId);

                    % invert the model
                    distMapCell = uint8(~distMapCell);
                    distMapCell = squeeze(mibDoImageFiltering2(distMapCell, distFilterOpt, obj.mibModel.cpuParallelLimit));
                    
                    % Get the size of the distance map
                    [heightDistMap, widthDistMap, depthDistMap] = size(distMapCell);

                    % find indices of Golgi that belong to the current cell
                    [~, tableIndx] = find(golgiCC.CellIds==cellId); % tableIndx will be used as positions in the resulting table

                    for golgiIndex = 1:numel(tableIndx)
                        tableRowIndex = tableIndx(golgiIndex);
                        golgiId = tableRowIndex;

                        % Adjust the coordinates of Golgi after cropping
                        x = golgiCC.x{golgiId} - x1 + 1;
                        y = golgiCC.y{golgiId} - y1 + 1;
                        z = golgiCC.z{golgiId} - z1 + 1;
                            
                        % Convert the subscript indices back to linear indices
                        pixelIdxList_cropped = sub2ind([heightDistMap, widthDistMap, depthDistMap], y, x, z);
                        
                        % get vector of intensities of distances for Golgi area
                        golgiIntensityVals = double(distMapCell(pixelIdxList_cropped));
                        
                        outTable.('Cell Id')(tableRowIndex) = cellId;
                        outTable.('Golgi stack Id')(tableRowIndex) = golgiCC.GolgiIdsAsDetected(tableRowIndex);
                        outTable.('Golgi index')(tableRowIndex) = golgiIndex;
                        
                        % golgi volume
                        outTable.('Golgi volume, px')(tableRowIndex) = numel(pixelIdxList_cropped);
                        outTable.('Golgi volume, units')(tableRowIndex) = outTable.('Golgi volume, px')(tableRowIndex) * ...
                            pixSize.x*pixSize.y*pixSize.z;
                        outTable.('Cell volume, px')(tableRowIndex) = cellStats(cellId).Area;
                        outTable.('Cell volume, units')(tableRowIndex) = cellStats(cellId).Area * ...
                            pixSize.x*pixSize.y*pixSize.z;

                        outTable.('Std relative to Cell boundary')(tableRowIndex) = std(golgiIntensityVals);
                    end
                    if obj.BatchOpt.showWaitbar
                        if pwb.getCancelState(); delete(pwb); return; end
                        pwb.increment();
                    end
                end
                clear cellStats;
            end

            if strcmp(obj.BatchOpt.Method{1}, 'Relative to nucleus') || strcmp(obj.BatchOpt.Method{1}, 'Both')
                if obj.BatchOpt.showWaitbar
                    if pwb.getCancelState(); delete(pwb); return; end
                    pwb.updateText(sprintf('Loading and detecting nuclei\nPlease wait...'));
                    pwb.increment();
                end
            
                loadedModel = obj.loadModel({obj.BatchOpt.nucleiModelPath});
                nucleusStats = regionprops(loadedModel, {'Area', 'BoundingBox'});
                
                % remove small Nuclei objects
                if obj.BatchOpt.ThresholdNucleus{1} > 0
                    % detect not empty indices
                    area = [nucleusStats.Area];
                    removeNucleiIds = find(area < obj.BatchOpt.ThresholdNucleus{1} & area > 0);
                    if ~isempty(removeNucleiIds); [nucleusStats(removeNucleiIds).Area] = deal(0); end
                end

                % detect not empty indices
                area = [nucleusStats.Area];
                nucleusIds = find(~area==0);
                % find intersection of golgi and nuclei models
                nucleusIds = intersect(golgiCC.CellIds, nucleusIds); 

                % expand the area around nuclei for this value in pixels
                modelMarginPx = obj.BatchOpt.DistanceMaxFromNucleus{1};

                if obj.BatchOpt.showWaitbar
                    if pwb.getCancelState(); delete(pwb); return; end
                    pwb.updateText(sprintf('Processing nuclei\nPlease wait...'));
                    pwb.increaseMaxNumberOfIterations(numel(nucleusIds))
                end

                for index = 1:numel(nucleusIds)
                    % crop the cell out of the full volume
                    cellId = nucleusIds(index);
                    % get initial crop min values
                    xMinCrop = ceil(nucleusStats(cellId).BoundingBox(1));
                    yMinCrop = ceil(nucleusStats(cellId).BoundingBox(2));
                    zMinCrop = ceil(nucleusStats(cellId).BoundingBox(3));
                    % add margin and correct for negative values
                    x1 = max([1, xMinCrop - modelMarginPx]);
                    y1 = max([1, yMinCrop - modelMarginPx]);
                    z1 = max([1, zMinCrop - modelMarginPx]);
                    % find the max point and correct for the full dataset
                    % dimensions
                    x2 = min([width, xMinCrop + nucleusStats(cellId).BoundingBox(4) - 1 + modelMarginPx]);
                    y2 = min([height, yMinCrop + nucleusStats(cellId).BoundingBox(5) - 1 + modelMarginPx]);
                    z2 = min([depth, zMinCrop + nucleusStats(cellId).BoundingBox(6) - 1 + modelMarginPx]);
                    
                    % crop the model
                    distMapCell = loadedModel(y1:y2, x1:x2, z1:z2);
                    distMapCell = distMapCell & (distMapCell == cellId);

                    % invert the model
                    distMapCell = uint8(distMapCell);
                    distMapCell = squeeze(mibDoImageFiltering2(distMapCell, distFilterOpt, obj.mibModel.cpuParallelLimit));
                    
                    % Get the size of the distance map
                    [heightDistMap, widthDistMap, depthDistMap] = size(distMapCell);

                    % find indices of Golgi that belong to the current cell
                    [~, tableIndx] = find(golgiCC.CellIds==cellId); % tableIndx will be used as positions in the resulting table

                    for golgiIndex = 1:numel(tableIndx)
                        tableRowIndex = tableIndx(golgiIndex);
                        golgiId = tableRowIndex;

                        % Adjust the coordinates of Golgi after cropping
                        x = golgiCC.x{golgiId} - x1 + 1;
                        y = golgiCC.y{golgiId} - y1 + 1;
                        z = golgiCC.z{golgiId} - z1 + 1;
                            
                        if max(x) > widthDistMap || max(y) > heightDistMap || max(z)>depthDistMap || ...
                                min(x) < 1 || min(y) < 1 || min(z) < 1

                            increaseRange = 0; % recommended increase of the distance range from nucleus
                            % clip coordinates from the right side of the dataset
                            removeIndX2 = find(x > widthDistMap) ;
                            if ~isempty(removeIndX2); increaseRange = max([increaseRange, max(x(removeIndX2) - widthDistMap)]); end
                            removeIndY2 = find(y > heightDistMap | y < 1);
                            if ~isempty(removeIndY2); increaseRange = max([increaseRange, max(y(removeIndY2) - heightDistMap)]); end
                            removeIndZ2 = find(z > depthDistMap | z < 1);
                            if ~isempty(removeIndZ2); increaseRange = max([increaseRange, max(z(removeIndZ2) - depthDistMap)]); end
                            %  clip coordinates from the left side of the dataset
                            removeIndX1 = find(x < 1) ;
                            if ~isempty(removeIndX1); increaseRange = max([increaseRange, max(abs(x(removeIndX1))+1)]); end
                            removeIndY1 = find(y < 1) ;
                            if ~isempty(removeIndY1); increaseRange = max([increaseRange, max(abs(y(removeIndY1))+1)]); end
                            removeIndZ1 = find(z < 1) ;
                            if ~isempty(removeIndZ1); increaseRange = max([increaseRange, max(abs(z(removeIndZ1))+1)]); end
                            removeInd = [removeIndX1, removeIndY1, removeIndZ1, removeIndX2, removeIndY2, removeIndZ2];

                            fprintf('CellId: %d, Golgi index: %d Increase distance from nucleus by ~%d pixels!\n', cellId, golgiIndex, increaseRange);
                            
                            x(removeInd) = [];
                            y(removeInd) = [];
                            z(removeInd) = [];
                        end

                        % Convert the subscript indices back to linear indices
                        pixelIdxList_cropped = sub2ind([heightDistMap, widthDistMap, depthDistMap], y, x, z);
                        
                        % get vector of intensities of distances for Golgi area
                        golgiIntensityVals = double(distMapCell(pixelIdxList_cropped));
                        
                        outTable.('Cell Id')(tableRowIndex) = cellId;
                        outTable.('Golgi stack Id')(tableRowIndex) = golgiCC.GolgiIdsAsDetected(tableRowIndex);
                        outTable.('Golgi index')(tableRowIndex) = golgiIndex;
                        
                        % golgi volume
                        outTable.('Golgi volume, px')(tableRowIndex) = numel(pixelIdxList_cropped);
                        outTable.('Golgi volume, units')(tableRowIndex) = outTable.('Golgi volume, px')(tableRowIndex) * ...
                            pixSize.x*pixSize.y*pixSize.z;
                        outTable.('Nucleus volume, px')(tableRowIndex) = nucleusStats(cellId).Area;
                        outTable.('Nucleus volume, units')(tableRowIndex) = nucleusStats(cellId).Area * ...
                            pixSize.x*pixSize.y*pixSize.z;

                        outTable.('Std relative to Nucleus')(tableRowIndex) = std(golgiIntensityVals);
                    end
                    if obj.BatchOpt.showWaitbar
                        if pwb.getCancelState(); delete(pwb); return; end
                        pwb.increment();
                    end
                end
            end

            % save results
            if obj.BatchOpt.showWaitbar
                if pwb.getCancelState(); delete(pwb); return; end
                pwb.updateText(sprintf('Saving results\nPlease wait...'));
                pwb.increment();
            end

            [path, fn, ext] = fileparts(obj.BatchOpt.OutputFilename);
            % save in Matlab format
            save(fullfile(path, [fn '.mat']), 'outTable');
            % save in xls or csv formats
            if ismember(ext, {'.csv', '.xls'})
                writetable(outTable, obj.BatchOpt.OutputFilename);
            end

            if obj.BatchOpt.showWaitbar
                maxIter = pwb.getMaxNumberOfIterations();
                pwb.setCurrentIteration(maxIter);
                delete(pwb);
            end
            toc

        end

        function calculateCroppedMode(obj)
            % start main calculation of the plugin
            if obj.BatchOpt.showWaitbar
                pwb = PoolWaitbar(1, sprintf('Starting calculations'), [], ...
                    'Golgi Orientation Calculations', ...
                    obj.View.gui); 
            end
            
            % turn off warnings when adding a new row into the results table
            warning('off', 'MATLAB:table:RowsAddedExistingVars');

            imageExt = lower(obj.BatchOpt.FilenameImageExtension{1});
            modelExt = lower(obj.BatchOpt.FilenameModelExtension{1});

            % define options to load images
            getDataOpt.waitbar = false;
            getDataOpt.silentMode = true;

            % define options for calculation of distance maps
            distFilterOpt.FilterName = {'DistanceMap'};
            distFilterOpt.DatasetType = {'3D, Stack'};
            distFilterOpt.Mode3D = true;
            distFilterOpt.AspectRatio3D = '1 1 1';
            distFilterOpt.SourceLayer = {'model'};
            distFilterOpt.ColorChannel = {'All'};
            distFilterOpt.Method = {'euclidean'};

            % crate a table for results
            outTable = table('Size', [numel(obj.BatchOpt.InputDirectories{2}), 8], ...
                'VariableTypes', {'string', 'string', 'string', 'string', 'double', 'double', 'double', 'double'}, ...
                'VariableNames', {'Directory', 'Directory short', 'Dataset name', 'Model name', 'Golgi stack Id', 'Volume, units', 'Std relative to Nucleus', 'Std relative to Cell boundary'});
            
            % switch to skip warning message when no cell boundary exists
            skipRelativeToBoundaryWarning = false;

            tableIndex = 0;
            if obj.BatchOpt.showWaitbar
                if pwb.getCancelState(); delete(pwb); return; end
                pwb.updateMaxNumberOfIterations(numel(obj.BatchOpt.InputDirectories{2}));
            end
            for inputDirId = 1:numel(obj.BatchOpt.InputDirectories{2})
                selectedDir = obj.BatchOpt.InputDirectories{2}{inputDirId};

                if obj.BatchOpt.showWaitbar
                    if pwb.getCancelState(); delete(pwb); return; end
                    [~, currDir] = fileparts(selectedDir);
                    pwb.updateText(sprintf('Processing "%s"\nPlease wait...', currDir));
                    increment(pwb);
                end

                % get image filename
                filename = dir(fullfile(selectedDir, ['*.' imageExt]));   % get list of files
                if numel(filename) ~= 0
                    
                end
                filename2 = arrayfun(@(filename) fullfile(selectedDir, filename.name), filename, 'UniformOutput', false);  % generate full paths
                notDirsIndices = arrayfun(@(filename2) ~isdir(cell2mat(filename2)), filename2);     % get indices of not directories
                imageFilename = filename2(notDirsIndices)';
                
                % get model filename
                filename = dir(fullfile(selectedDir, ['*.' modelExt]));   % get list of files
                filename2 = arrayfun(@(filename) fullfile(selectedDir, filename.name), filename, 'UniformOutput', false);  % generate full paths
                notDirsIndices = arrayfun(@(filename2) ~isdir(cell2mat(filename2)), filename2);     % get indices of not directories
                modelFilename  = filename2(notDirsIndices)';
                                
                if numel(imageFilename) ~= 1 && numel(modelFilename) ~= 1 
                    uialert(obj.View.gui, ...
                                sprintf('!!! Error !!!\n\nThere should be:\n  - a single image file (*.%s)\n  - a single model file (*.%s)\nin each input directory!\n\nThis criteria is not fulfilled in\n%s', ...
                                imageExt, modelExt, selectedDir), ...
                                'Wrong files', 'Icon', 'error');
                end

                % generate short names
                [~, imageFilenameShort, ext] = fileparts(imageFilename{1});
                imageFilenameShort = [imageFilenameShort ext];
                [~, modelFilenameShort, ext] = fileparts(modelFilename{1});
                modelFilenameShort = [modelFilenameShort, ext];


                % load image
                %[mImg, img_info, pixSize] = mibLoadImages(imageFilename, getDataOpt);
                [img_info, files, pixSize] = mibGetImageMetadata(imageFilename, getDataOpt);
                %mImg = mibImage(I, img_info);
                mModel = obj.loadModel(modelFilename);

                % % check for object threshold sizes
                % % define initial values for Golgi, Nucleus, Cell
                % thresholdVectorGNC = [obj.BatchOpt.ThresholdGolgi{1}, ...
                %                       obj.BatchOpt.ThresholdNucleus{1}, ...
                %                       obj.BatchOpt.ThresholdCell{1}];
                % % indices of materials as vector: Golgi, Nucleus, Cell
                % materialIdsGNC = [obj.BatchOpt.MaterialGolgi{1}, ...
                %     obj.BatchOpt.MaterialNucleus{1}, ...
                %     obj.BatchOpt.MaterialCell{1}];
                % % remove from vector materials that are not used
                % if strcmp(obj.BatchOpt.Method{1}, 'Relative to nucleus')
                %     thresholdVectorGNC(2) = [];
                %     materialIdsGNC(2) = [];
                % end
                % if strcmp(obj.BatchOpt.Method{1}, 'Relative to cell boundary')
                %     thresholdVectorGNC(3) = [];
                %     materialIdsGNC(3) = [];
                % end
                % % load model
                % %model = obj.loadModel(modelFilename);
                % CC = bwconncomp(mImg.model, 26);

                % find Golgi
                golgiModel = uint8(mModel==obj.BatchOpt.MaterialGolgi{1});
                CC = bwconncomp(golgiModel, 26);
                noGolgiStacks = CC.NumObjects;
                if noGolgiStacks == 0; continue; end
                % calculate volumes in units
                for golgiId  = 1:noGolgiStacks
                    outTable.('Volume, units')(tableIndex+golgiId) = numel(CC.PixelIdxList{golgiId}) * ...
                        pixSize.x*pixSize.y*pixSize.z;
                end
                
                % calculate distance map from nucleus
                if strcmp(obj.BatchOpt.Method{1}, 'Relative to nucleus') || ...
                    strcmp(obj.BatchOpt.Method{1}, 'Both')

                    distMapNucleus = uint8(mModel==obj.BatchOpt.MaterialNucleus{1});
                    distMapNucleus = squeeze(mibDoImageFiltering2(distMapNucleus, distFilterOpt, obj.mibModel.cpuParallelLimit));
                    
                    STATS = regionprops(CC, distMapNucleus, 'PixelValues');
                    % convert to double
                    intensityValsVsNucleus = arrayfun(@(x) double(x.PixelValues), STATS, 'UniformOutput', false);
                else
                    intensityValsVsNucleus = repmat({NaN}, [noGolgiStacks, 1]);
                end

                % calculate distance map from cell boundary
                if strcmp(obj.BatchOpt.Method{1}, 'Relative to cell boundary') || strcmp(obj.BatchOpt.Method{1}, 'Both')
                    % check for presence of the cell boundary material
                    if isempty(find(mModel==obj.BatchOpt.MaterialCell{1}, 1, 'first'))
                        % skipping
                        intensityValsVsCell = repmat({NaN}, [noGolgiStacks, 1]);
                        
                        if ~skipRelativeToBoundaryWarning
                            uialert(obj.View.gui, ...
                                sprintf('No cell boundary found!\nSkipping the relative to the cell boundary analysis part!'), ...
                                'Missing cell boundary', 'Icon', 'warning');
                            skipRelativeToBoundaryWarning = true;
                        end

                    else
                        % combine all materials as shape
                        distMapCell = mModel>0;
                        % invert the model
                        distMapCell = uint8(~distMapCell);
                        distMapCell = squeeze(mibDoImageFiltering2(distMapCell, distFilterOpt, obj.mibModel.cpuParallelLimit));
                        
                        STATS = regionprops(CC, distMapCell, 'PixelValues');
                        % convert to double
                        intensityValsVsCell = arrayfun(@(x) double(x.PixelValues), STATS, 'UniformOutput', false);
                        noGolgiStacks = numel(intensityValsVsCell);
                    end
                else
                    intensityValsVsCell = repmat({NaN}, [noGolgiStacks, 1]);
                end

                for golgiId = 1:noGolgiStacks
                    outTable.('Directory')(tableIndex+golgiId) = selectedDir;
                    [~, selectedDirShort] = fileparts(selectedDir);
                    outTable.('Directory short')(tableIndex+golgiId) = selectedDirShort;
                    outTable.('Dataset name')(tableIndex+golgiId) = imageFilenameShort;
                    outTable.('Model name')(tableIndex+golgiId) = modelFilenameShort;
                    outTable.('Golgi stack Id')(tableIndex+golgiId) = golgiId;
                    outTable.('Std relative to Nucleus')(tableIndex+golgiId) = std(intensityValsVsNucleus{golgiId}, 'omitnan');
                    outTable.('Std relative to Cell boundary')(tableIndex+golgiId) = std(intensityValsVsCell{golgiId}, 'omitnan');
                end

                clear CC;
                tableIndex = tableIndex + noGolgiStacks;
            end
            
            % save results
            if obj.BatchOpt.showWaitbar
                if pwb.getCancelState(); delete(pwb); return; end
                pwb.updateText(sprintf('Saving results\nPlease wait...'));
            end

            [path, fn, ext] = fileparts(obj.BatchOpt.OutputFilename);
            % save in Matlab format
            save(fullfile(path, [fn '.mat']), 'outTable');
            % save in xls or csv formats
            if ismember(ext, {'.csv', '.xls'})
                writetable(outTable, obj.BatchOpt.OutputFilename);
            end

            if obj.BatchOpt.showWaitbar
                delete(pwb);
            end

            % obj.mibController.mibFilesListbox_cm_Callback([], Batch);



            %if obj.BatchOpt.showWaitbar; delete(wb); end
            
            % redraw the image if needed
            % notify(obj.mibModel, 'plotImage');
            
            % for batch need to generate an event and send the BatchOptLoc
            % structure with it to the macro recorder / mibBatchController
            obj.returnBatchOpt();

            % turn on warnings when adding a new row into the results table
            warning('on', 'MATLAB:table:RowsAddedExistingVars');
        end
        
        
    end
end