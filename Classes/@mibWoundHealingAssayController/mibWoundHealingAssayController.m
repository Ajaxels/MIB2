classdef mibWoundHealingAssayController < handle
    % @type mibWoundHealingAssayController class is a template class for using with
    % GUI developed using appdesigner of Matlab
    %
    % @code
    % obj.startController('mibWoundHealingAssayController'); // as GUI tool
    % @endcode
    % or 
    % @code 
    % // a code below was used for mibImageArithmeticController
    % BatchOpt.Parameter = 'test';  // fill edit boxes as strings
    % BatchOpt.Checkbox = true;     // fill checkboxes with logicals: true/false
    % BatchOpt.Popup = {'value'};        // value for the popups as a cell
    % BatchOpt.Radio = {'Radio1'};          // selection of radio buttons, as cell with the handle of the target radio button
    % BatchOpt.showWaitbar = true;  // show or not the waitbar
    % obj.startController('mibWoundHealingAssayController', [], BatchOpt); // start mibWoundHealingAssayController in the batch mode
    % @endcode
    % or
    % @code
    % // trigger return of the possible Options using returnBatchOpt function
    % // using notify syncBatch event
    % obj.startController('mibWoundHealingAssayController', [], NaN);
    % @endcode
    
    % Copyright (C) 17.09.2019, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
        % handle to the view / mibWoundHealingAssayGUI
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
        function obj = mibWoundHealingAssayController(mibModel, varargin)
            obj.mibModel = mibModel;    % assign model
            
            %% fill the BatchOpt structure with default values
            % fields of the structure should correspond to the starting
            % text in the each widget tooltip.
            % For example, this demo template has an edit box, where the
            % tooltip starts with "Parameter:...". Text Parameter
            % indicates field of the BatchOpt structure that defines value
            % for this widget
            obj.BatchOpt.Extension = 'tif';
            obj.BatchOpt.NoRows = {3};
            obj.BatchOpt.NoColumns = {3};
            obj.BatchOpt.SelectedDirectories = {};
            obj.BatchOpt.OutputDirectory = obj.mibModel.myPath;
            obj.BatchOpt.ConvertToGrayscale = true;
            obj.BatchOpt.PixelSize = {1};
            obj.BatchOpt.TimeStep = {1};
            obj.BatchOpt.DownsampleImages = {50};
            obj.BatchOpt.ShowInteractivePlot = true;
            obj.BatchOpt.showWaitbar = true;
            
            %% part below is only valid for use of the plugin from MIB batch controller
            % comment it if intended use not from the batch mode
            obj.BatchOpt.mibBatchSectionName = 'Menu -> Plugins';    % section name for the Batch
            obj.BatchOpt.mibBatchActionName = 'mibWoundHealingAssay';           % name of the plugin
            % tooltips that will accompany the BatchOpt
            obj.BatchOpt.mibBatchTooltip.Extension = 'Filename extension';
            obj.BatchOpt.mibBatchTooltip.NoRows = 'Number of rows';
            obj.BatchOpt.mibBatchTooltip.NoColumns = 'Number of columns';
            obj.BatchOpt.mibBatchTooltip.SelectedDirectories = 'Cell array with input directories';
            obj.BatchOpt.mibBatchTooltip.OutputDirectory = 'Output directory path';
            obj.BatchOpt.mibBatchTooltip.ConvertToGrayscale = 'Convert to grayscale for the output';
            obj.BatchOpt.mibBatchTooltip.PixelSize = 'Pixel size for the wound healing analysis';
            obj.BatchOpt.mibBatchTooltip.TimeStep = 'Time step between the images for the wound healing analysis';
            obj.BatchOpt.mibBatchTooltip.DownsampleImages = '%% to downsample the resulting images showing the detected wound';
            obj.BatchOpt.mibBatchTooltip.ShowInteractivePlot = 'Display interactive plot with results during the run';
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
                
                obj.Calculate();
                notify(obj, 'closeEvent');
                return;
            end
            
            guiName = 'mibWoundHealingAssayGUI';
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
            % % this function is not yet
%             global Font;
%             if ~isempty(Font)
%               if obj.View.handles.text1.FontSize ~= Font.FontSize ...
%                     || ~strcmp(obj.View.handles.text1.FontName, Font.FontName)
%                   mibUpdateFontSize(obj.View.gui, Font);
%               end
%             end
            
            obj.View.handles.OutputDir.Value = obj.BatchOpt.OutputDirectory;

			obj.updateWidgets();
			% update widgets from the BatchOpt structure
            obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.BatchOpt);
            
			% obj.View.gui.WindowStyle = 'modal';     % make window modal
			
			% add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing mibWoundHealingAssayController window
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
        
        function SelectDirectories(obj)
            path = uigetfile_n_dir(obj.mibModel.myPath, 'Select directories');
            if isempty(path); return; end
            obj.BatchOpt.SelectedDirectories = path;
            obj.View.handles.SelectedDirectories.Value = path';
        end
        
        function SelectOutputDirectory(obj)
            path = uigetdir(obj.BatchOpt.OutputDirectory, 'Select output directory');
            if path == 0; return; end
            obj.BatchOpt.OutputDirectory = path;
            obj.View.handles.OutputDir.Value = path;
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
        
        function updateOutputPath(obj, value)
            % function updateOutputPath(obj, value)
            % update output path from the editbox
            
            if isfolder(value) == 0
                mkdir(value);
                if isfolder(value) == 0
                    errordlg(sprintf('!!! Error !!!\n\nCan not make an output directory!\n%s', value));
                    return;
                end
            end
            obj.BatchOpt.OutputDirectory = value;
        end
        
        % ------------------------------------------------------------------
        % % Additional functions and callbacks
        function Stitch(obj)
            % function Stitch(obj)
            % stitch the datasets
            global mibPath;
            
            if obj.BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'Stitching'); end
            
            % get number of files
            if numel(obj.BatchOpt.SelectedDirectories) < 2; return; end 
            
            filelist = cell([numel(obj.BatchOpt.SelectedDirectories), 1]);
            for i=1:numel(obj.BatchOpt.SelectedDirectories)
                filelist{i} = dir(fullfile(obj.BatchOpt.SelectedDirectories{i}, ['*.' obj.BatchOpt.Extension]));
            end
            noFiles = numel(filelist{1});   % number of files in a single directory
            
            % get metadata
            getDataOpt.waitbar = 0;
            [img_info, files, pixSize] = mibGetImageMetadata({fullfile(filelist{1}(1).folder, filelist{1}(1).name)}, getDataOpt);
            
            width = files.width;
            height = files.height;
            color = files.color;
            NoCols = obj.BatchOpt.NoColumns{1};
            NoRows = obj.BatchOpt.NoRows{1};
            imgClass = files.imgClass;
            
            % allocate space for time tags
            timeVector = cell([noFiles, 1]);
            
            if strcmp(lower(obj.BatchOpt.Extension), 'jpg') %#ok<STCI>
                prompt = {'Compression mode:'; 'Quality (0-100):'};
                dlg_title = 'JPG Parameters';
                defAns = {{'lossy','lossless'}; '90'};
                
                answer = mibInputMultiDlg({mibPath}, prompt, defAns, dlg_title);
                if isempty(answer); return; end
        
                SavingOpt.Compression = answer{1};
                SavingOpt.Quality = str2double(answer{2});
            end
            
            for fnId = 1:noFiles
                I = zeros([height*NoCols, width*NoRows, color], imgClass);
                dy = 1;
                index = 1;
                for rowId = 1:NoRows
                    dx = 1;
                    if rowId == 1
                        infoStruct = imfinfo(fullfile(filelist{index}(fnId).folder, filelist{index}(fnId).name));
                        timeVector{fnId} = infoStruct.FileModDate;
                    end
                    for colId = 1:NoCols
                        [img_info, files, pixSize] = mibGetImageMetadata({fullfile(filelist{index}(fnId).folder, filelist{index}(fnId).name)}, getDataOpt);
                        [img, img_info] = mibGetImages(files, img_info, getDataOpt);
                        I(dy:dy+height-1, dx:dx+width-1, :) = img;
                        dx = dx + width - 1;
                        index = index + 1; 
                    end
                    dy = dy + height - 1;
                end
                
                [~, outFn, outExt] = fileparts(filelist{1}(fnId).name);
                outputFn = fullfile(obj.BatchOpt.OutputDirectory, [outFn, '_stitched' outExt]);
                if obj.BatchOpt.ConvertToGrayscale
                    I = mean(I, 3);
                    evalStr = sprintf('I = %s(I);', imgClass);
                    eval(evalStr);
                end
                
                % convert to mibImage and calibrate
                I2 = mibImage(I);
                pixSize.x = obj.BatchOpt.PixelSize{1};
                pixSize.y = pixSize.x;
                pixSize.z = obj.BatchOpt.TimeStep{1};
                I2.updatePixSizeResolution(pixSize);
                
                SavingOpt.FilenamePolicy = {'Use new provided name'};
                SavingOpt.OutputDirectoryPolicy = {'Full path'};
                SavingOpt.silent = 1;
                SavingOpt.showWaitbar = false;
                
                switch lower(obj.BatchOpt.Extension)
                    case 'jpg'
                        SavingOpt.Format = 'Joint Photographic Experts Group (*.jpg)';
                        I2.saveImageAsDialog(outputFn, SavingOpt);
                        %imwrite(I, outputFn, 'Quality', 85);
                    case 'tif'
                        SavingOpt.Format = 'TIF format uncompressed (*.tif)';
                        I2.saveImageAsDialog(outputFn, SavingOpt);
                        %imwrite(I, outputFn);
                    otherwise
                        imwrite(I, outputFn);
                end
                
                if obj.BatchOpt.showWaitbar; waitbar(fnId/noFiles, wb); end
            end
            
            % generate info file with time stamps
            [~, timeStampFn] = fileparts(filelist{1}(1).name);
            fid = fopen(fullfile(obj.BatchOpt.OutputDirectory, [timeStampFn, '_TimeStamps.txt']), 'w');
            fprintf(fid, 'Time stamps from the original files in Greenwich Mean Time (GMT)\n');
            for i=1:numel(timeVector)
                fprintf(fid, '%s\n', timeVector{i});
            end
            fclose(fid);
            
            if obj.BatchOpt.showWaitbar; delete(wb); end
            
            % redraw the image if needed
            notify(obj.mibModel, 'plotImage');
            
            
            % for batch need to generate an event and send the BatchOptLoc
            % structure with it to the macro recorder / mibBatchController
            %obj.returnBatchOpt();
        end
        
        function WoundHealing(obj)
            % function WoundHealing(obj)
            % perform wound healing assay for the selected directories
            % detection of the wound width is based on code of Constantino Carlos Reyes-Aldasoro
            % https://se.mathworks.com/matlabcentral/fileexchange/67932-cell-migration-in-scratch-wound-assays
            % Reference:
            % C.C. Reyes-Aldasoro, D. Biram, G.M. Tozer, C. Kanthou
            % Measuring cellular migration with image processing
            % Electronics Letters, Volume 44, Issue 13, 19 June 2008, p. 791 – 793
            % https://digital-library.theiet.org/content/journals/10.1049/el_20080943
            
            % get number of files
            if numel(obj.BatchOpt.SelectedDirectories) < 1; return; end
            
            pixsize = obj.BatchOpt.PixelSize{1};
            timeStep = obj.BatchOpt.TimeStep{1};
            
            if obj.BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'Wound healing assay'); end
            
            for dirId=1:numel(obj.BatchOpt.SelectedDirectories)
                inputPath = obj.BatchOpt.SelectedDirectories{dirId};    % get input directory
                if obj.BatchOpt.showWaitbar; waitbar(0, wb, sprintf('Directory %d/%d, %s\nPlease wait...', dirId, numel(obj.BatchOpt.SelectedDirectories), inputPath)); end
                
                list = dir([inputPath filesep '*.' obj.BatchOpt.Extension]);    % get list of files
                    
                % allocate space
                res.minVec = zeros([numel(list), 1]);
                res.maxVec = zeros([numel(list), 1]);
                res.avVec = zeros([numel(list), 1]);
                timeVec = 0:timeStep:timeStep*(numel(list)-1);  % vector of time points
                
                for fnId=1:numel(list)
                    fn = fullfile(list(fnId).folder, list(fnId).name);
                    [Res_stats, Res_colour] = cellMigration(fn);
                    if ~isfield(Res_stats, 'minimumDist'); break; end
                    res.minVec(fnId) = Res_stats.minimumDist * pixsize;
                    res.maxVec(fnId) = Res_stats.maxDist * pixsize;
                    res.avVec(fnId) = Res_stats.avDist * pixsize;

                    % save resulting image to disk
                    outFn = fullfile(list(fnId).folder, 'snapshots', ['Wound_' list(fnId).name]);
                    if fnId == 1
                        if isfolder(fullfile(list(fnId).folder, 'snapshots')) == 0
                            mkdir(fullfile(list(fnId).folder, 'snapshots'));
                        end
                    end
                    if obj.BatchOpt.DownsampleImages{1} ~= 100
                        Res_colour = imresize(Res_colour, obj.BatchOpt.DownsampleImages{1}/100);    % downsample image
                    end
                    imwrite(Res_colour, outFn);     % save image to a file

                    if obj.BatchOpt.ShowInteractivePlot
                        figure(2)
                        plot(timeVec, res.minVec, timeVec, res.maxVec, timeVec, res.avVec);
                        title(sprintf('Directory %d/%d, %s', dirId, numel(obj.BatchOpt.SelectedDirectories), inputPath));
                        set(gca, 'ylim', [min(res.minVec(res.minVec>0)) max(res.maxVec)]);
                        legend('MinVector', 'maxVector', 'averageVector');
                        xlabel('Time, h');
                        ylabel('Wound width, \mum');
                        grid;
                    end
                    if obj.BatchOpt.showWaitbar; waitbar(fnId/numel(list), wb); end
                end
                
                figure(2)
                plot(timeVec, res.minVec, timeVec, res.maxVec, timeVec, res.avVec);
                title(sprintf('Directory %d/%d, %s', dirId, numel(obj.BatchOpt.SelectedDirectories), inputPath))
                legend('MinVector', 'maxVector', 'averageVector');
                set(gca, 'ylim', [min(res.minVec(res.minVec>0)) max(res.maxVec)]);
                xlabel('Time, h');
                ylabel('Wound width, \mum');
                grid;
                
                % generate results
                [~, pathPart] = fileparts(inputPath);
                exportFn = fullfile(inputPath, sprintf('WoundAssayResults_%s.mat', pathPart));
                save(exportFn, 'res');    % save in Matlab format
                
                % export to Excel
                warning('off', 'MATLAB:xlswrite:AddSheet');
                % Sheet 1
                s = {'Wound healing assay results'};
                s(2,1) = {'Directory name:'};  s(2,2) = {inputPath}; 
                s(2,3) = {'PixelSize:'}; s(2,4) = obj.BatchOpt.PixelSize(1);
                s(2,5) = {'TimeStep:'}; s(2,6) = obj.BatchOpt.TimeStep(1);
                
                s(3,1) = {'Image index'}; s(3,2) = {'Image name'}; s(3,3) = {'Time point'}; s(3,4) = {'Min'};
                s(3,5) = {'Average'}; s(3,6) = {'Max'};
                lineIndex = 4;
                
                s(lineIndex:lineIndex+numel(list)-1, 1) = num2cell(1:numel(list))';
                s(lineIndex:lineIndex+numel(list)-1, 3) = num2cell(timeVec)';
                s(lineIndex:lineIndex+numel(list)-1, 4) = num2cell(res.minVec)';
                s(lineIndex:lineIndex+numel(list)-1, 5) = num2cell(res.avVec)';
                s(lineIndex:lineIndex+numel(list)-1, 6) = num2cell(res.maxVec)';
                
                for pointId = 1:numel(list)
                    s(lineIndex+pointId-1, 2) = {sprintf('%s', list(pointId).name)};
                end
                warning('off','MATLAB:COM:invalidargumenttype');    % switch off warnings
                exportFn = fullfile(inputPath, sprintf('WoundAssayResults_%s.xls', pathPart));
                try
                    delete(exportFn);
                catch err
                end
                xlswrite2(exportFn, s, 'WoundAssay');
            end
            if obj.BatchOpt.showWaitbar; delete(wb); end
        end
    end
end