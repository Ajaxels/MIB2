classdef ImageConverterController < handle
    % @type ImageConverterController class is a template class for using with
    % GUI developed using appdesigner of Matlab
    %
    % @code
    % obj.startController('ImageConverterController'); // as GUI tool
    % @endcode
    % or 
    % @code 
    % // a code below was used for mibImageArithmeticController
    % BatchOpt.Parameter = 'test';  // fill edit boxes as strings
    % BatchOpt.Checkbox = true;     // fill checkboxes with logicals: true/false
    % BatchOpt.Popup = {'value'};        // value for the popups as a cell
    % BatchOpt.Radio = {'Radio1'};          // selection of radio buttons, as cell with the handle of the target radio button
    % BatchOpt.showWaitbar = true;  // show or not the waitbar
    % obj.startController('ImageConverterController', [], BatchOpt); // start ImageConverterController in the batch mode
    % @endcode
    % or
    % @code
    % // trigger return of the possible Options using returnBatchOpt function
    % // using notify syncBatch event
    % obj.startController('ImageConverterController', [], NaN);
    % @endcode
    
    % Copyright (C) 27.10.2020, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
        % handles to mibModel
        View
        % handle to the view / ImageConverterGUI
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
%         function ViewListner_Callback(obj, src, evnt)
%             switch evnt.EventName
%                 case {'updateGuiWidgets'}
%                     obj.updateWidgets();
%             end
%         end
        
        function imOut = getPNGwithoutColormap(fn)
            % read PNG files omitting the colormap
            imOut = imread(fn);
        end
    end
    
    methods
        function obj = ImageConverterController(mibModel, varargin)
            obj.mibModel = mibModel;    % assign model
            
            %% fill the BatchOpt structure with default values
            % fields of the structure should correspond to the starting
            % text in the each widget tooltip.
            % For example, this demo template has an edit box, where the
            % tooltip starts with "Parameter:...". Text Parameter
            % indicates field of the BatchOpt structure that defines value
            % for this widget
            
            obj.BatchOpt.InputDirectory = obj.mibModel.myPath;
            obj.BatchOpt.OutputDirectory = fullfile(obj.mibModel.myPath, 'FileConvert');
            registry = imformats();
            obj.BatchOpt.InputImageFormatExtension = {'png'};
            obj.BatchOpt.InputImageFormatExtension{2} = [registry.ext];
            obj.BatchOpt.IncludeSubfolders = false;
            obj.BatchOpt.OutputImageFormatExtension = {'tif'};
            obj.BatchOpt.OutputImageFormatExtension{2} = {'png', 'jpg', 'jpeg', 'tif', 'tiff'};
            obj.BatchOpt.DiscardColormap = false;
            obj.BatchOpt.Prefix = '';
            obj.BatchOpt.Suffix = '';
            obj.BatchOpt.ParallelProcessing = false;
            obj.BatchOpt.showWaitbar = true;
            
            %% part below is only valid for use of the plugin from MIB batch controller
            % comment it if intended use not from the batch mode
            obj.BatchOpt.mibBatchSectionName = 'Menu -> Plugins';    % section name for the Batch
            obj.BatchOpt.mibBatchActionName = 'Convert image files';           % name of the plugin
            % tooltips that will accompany the BatchOpt
            obj.BatchOpt.mibBatchTooltip.InputDirectory = 'Directory with input images';
            obj.BatchOpt.mibBatchTooltip.OutputDirectory = 'Output directory for results';
            obj.BatchOpt.mibBatchTooltip.InputImageFormatExtension = 'Extension of the input images';
            obj.BatchOpt.mibBatchTooltip.OutputImageFormatExtension = 'Extension of the output images';
            obj.BatchOpt.mibBatchTooltip.IncludeSubfolders = 'Include subfolders';
            obj.BatchOpt.mibBatchTooltip.DiscardColormap = 'Discard colormap during processing of PNG files';
            obj.BatchOpt.mibBatchTooltip.Prefix = 'Prefix to the output filename';
            obj.BatchOpt.mibBatchTooltip.Suffix = 'Suffix to the output filename';
            obj.BatchOpt.mibBatchTooltip.ParallelProcessing = 'Use parallel processing during image conversion';
            obj.BatchOpt.mibBatchTooltip.showWaitbar = sprintf('Show or not waitbar');

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
                
                obj.Convert();
                notify(obj, 'closeEvent');
                return;
            end
            
            guiName = 'ImageConverterGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
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
%             global Font;
%             if ~isempty(Font)
%               if obj.View.handles.text1.FontSize ~= Font.FontSize+4 ...   
%                     || ~strcmp(obj.View.handles.text1.FontName,
%                     Font.FontName) % font size for appdesigner +4 larger than that for guide 
%                   mibUpdateFontSize(obj.View.gui, Font);
%               end
%             end

            obj.View.handles.infoText.Text = sprintf('This tool convert image files from one format to another');
            
			obj.updateWidgets();
			% update widgets from the BatchOpt structure
            obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.BatchOpt);
            
			% obj.View.gui.WindowStyle = 'modal';     % make window modal
			
			% add listner to obj.mibModel and call controller function as a callback
            %obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing ImageConverterController window
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
        
        function selectDirectory(obj, event)
            % function selectDirectory(obj, event)
            % select input/output directory 
        
            switch event.Source.Tag
                case 'SelectInputDirectory'
                    selpath = uigetdir(obj.BatchOpt.InputDirectory, 'Select input directory');
                    if selpath == 0; return; end
                    obj.View.handles.InputDirectory.Value = selpath;
                    event2.Source = obj.View.handles.InputDirectory;
                    obj.updateBatchOptFromGUI(event2);
                    obj.View.handles.OutputDirectory.Value = fullfile(selpath, 'FileConvert');
                    event2.Source = obj.View.handles.OutputDirectory;
                    obj.updateBatchOptFromGUI(event2);
                case 'SelectOutputDirectory'
                    if exist(obj.BatchOpt.InputDirectory, 'dir') == 7
                        defDir = obj.BatchOpt.OutputDirectory;
                    else
                        defDir = obj.BatchOpt.InputDirectory;
                    end
                    selpath = uigetdir(defDir, 'Select output directory');
                    if selpath == 0; return; end
                    obj.View.handles.OutputDirectory.Value = selpath;
                    event2.Source = obj.View.handles.OutputDirectory;
                    obj.updateBatchOptFromGUI(event2);
            end
        
        end
        
        % ------------------------------------------------------------------
        % % Additional functions and callbacks
        function Convert(obj)
            % start main calculation of the plugin
            t1 = tic;
            if obj.BatchOpt.showWaitbar; wb = waitbar(0, sprintf('Making data store\nPlease wait...'), 'Name', 'Image converter'); end
            
            if exist(obj.BatchOpt.OutputDirectory, 'dir') == 0
                mkdir(obj.BatchOpt.OutputDirectory);
            end
            
            if strcmp(obj.BatchOpt.InputImageFormatExtension{1}, 'png') && obj.BatchOpt.DiscardColormap
                imgDS = imageDatastore(obj.BatchOpt.InputDirectory, ...
                    'FileExtensions', lower(['.' obj.BatchOpt.InputImageFormatExtension{1}]), ...
                    'IncludeSubfolders', obj.BatchOpt.IncludeSubfolders, ...
                    'ReadFcn', @(fn)ImageConverterController.getPNGwithoutColormap(fn));
            else
                imgDS = imageDatastore(obj.BatchOpt.InputDirectory, ...
                    'FileExtensions', lower(['.' obj.BatchOpt.InputImageFormatExtension{1}]), ...
                    'IncludeSubfolders', obj.BatchOpt.IncludeSubfolders);
            end
            
            if obj.BatchOpt.showWaitbar; waitbar(0.1, wb, sprintf('Processing\nPlease wait...')); end
            try
                writeall(imgDS, obj.BatchOpt.OutputDirectory, ...
                    'OutputFormat', obj.BatchOpt.OutputImageFormatExtension{1},...
                    'FilenamePrefix', obj.BatchOpt.Prefix, 'FilenameSuffix', obj.BatchOpt.Suffix, ...
                    'UseParallel', obj.BatchOpt.ParallelProcessing);
            catch err
                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s', err.identifier, err.message), 'Missing files');
                if obj.BatchOpt.showWaitbar; delete(wb); end
                return;
            end
            if obj.BatchOpt.showWaitbar; delete(wb); end
            
            fprintf('Image conversion finished, elapsed time: %f seconds\n', toc(t1));
            % for batch need to generate an event and send the BatchOptLoc
            % structure with it to the macro recorder / mibBatchController
            obj.returnBatchOpt();
        end
        
        
    end
end