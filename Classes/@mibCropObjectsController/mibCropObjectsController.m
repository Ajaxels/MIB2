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

classdef mibCropObjectsController < handle
    % classdef mibCropObjectsController < handle
    % a controller class for the crop objects to file options of the context menu of the Get Statistics window
        
    properties
        mibModel
        % handles to the model
        mibStatisticsController
        % a handle to mibStatisticsController 
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        outputDir
        % output directory
        outputVar
        % output variable for export to Matlab
        storedBatchOpt 
        % stored BatchOpt, because some of the parameters gets overwritten in the crop function
        annotationLabels
        % structure with additional information about annotations
        % .names - cell array with label (annotation) names
        % .positions - matrix with center coordinates of patches to be cropped out from
        % the image, it is used by mibAnnotationsController. 
        % Format: [pntId][z, x, y, t]
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback(obj, src, evnt)
            switch src.Name
                case 'Id'
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibCropObjectsController(mibModel, mibStatisticsController, batchModeSwitch, annotationLabels)
            % function obj = mibCropObjectsController(mibModel, mibStatisticsController, batchModeSwitch, annotationLabels)
            % constructor of the class
            % Parameters:
            % mibStatisticsController: a handle to the mibStatisticsController class
            % batchModeSwitch: a logical switch to use the batch mode instead of GUI mode
            % annotationLabels: structure with additional information about annotations
            % .names - cell array with label (annotation) names
            % .positions - matrix with center coordinates of patches to be cropped out from the image, it is used by mibAnnotationsController. 
            % Format: [pntId][z, x, y, t]
            if nargin < 4; annotationLabels = []; end
            if nargin < 3; batchModeSwitch = 0; end
            
            obj.mibModel = mibModel;    % assign model
            obj.mibStatisticsController = mibStatisticsController;
            obj.annotationLabels = annotationLabels;
            obj.storedBatchOpt = obj.mibStatisticsController.BatchOpt;  % store BatchOpt, because some of the parameters gets overwritten
            
            [~, obj.outputVar] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));  % to be used below in eval block
            if batchModeSwitch == 1
                if verLessThan('matlab',' 9.3'); obj.mibStatisticsController.BatchOpt.SingleMaskObjectPerDataset = false; end
                if obj.mibStatisticsController.runId(2) ~= -1; obj.mibStatisticsController.BatchOpt.SingleMaskObjectPerDataset = false; end
                obj.cropBtn_Callback(batchModeSwitch);
                return;
            end
            
            obj.mibStatisticsController.BatchOpt.CropObjectsTo{1} = 'Amira Mesh binary (*.am)';
            obj.mibStatisticsController.BatchOpt.CropObjectsIncludeModel{1} = 'Do not include';
            obj.mibStatisticsController.BatchOpt.CropObjectsIncludeMask{1} = 'Do not include';
            
            guiName = 'mibCropObjectsGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view

            obj.updateWidgets();
            %obj.View.gui.WindowStyle = 'modal';     % make window modal
            
            if isempty(obj.annotationLabels)   % standard call from mibStatisticsController
                if verLessThan('matlab',' 9.3')
                    if obj.mibStatisticsController.View.handles.Shape3D.Value == 1
                        obj.View.handles.SingleMaskObjectPerDataset.Enable = 'off';     % because it is using bwselect3 function available in R2017b and newer
                        obj.mibStatisticsController.BatchOpt.SingleMaskObjectPerDataset = false; 
                    end
                end

                if obj.mibStatisticsController.View.handles.Shape3D.Value == 1
                    obj.View.handles.Generate3DPatches.Value = true;
                    obj.View.handles.marginZEdit.Enable = 'on';
                end
                
                % runId is a vector runId(1) index of the dataset, runId(2) index of material runId(2)==1 is mask
                % for models <= 255:          -1=Mask; 0=Ext; 1-1st material  ...
                % for models > 255: -2=Model; -1=Mask; 0=Ext; 1-1st material, 2-second selected material...
                if obj.mibStatisticsController.runId(2) ~= -1 
                    obj.View.handles.SingleMaskObjectPerDataset.Enable = 'off';     % because the objects were not detected from the mask
                    obj.mibStatisticsController.BatchOpt.SingleMaskObjectPerDataset = false;
                end
                obj.View.handles.Generate3DPatches.Enable = 'on';
            else % check for alternative call from mibAnnotationsController
                obj.View.handles.marginXYtext.String = 'Width, px';
                obj.View.handles.marginXYtext.Tooltip = 'width of the cropped block in pixels';
                obj.View.handles.marginXYEdit.Tooltip = 'width of the cropped block in pixels';
                obj.View.handles.marginZtext.String = 'Height, px';
                obj.View.handles.marginZtext.Tooltip = 'width of the cropped block in pixels';
                obj.View.handles.marginZEdit.Tooltip = 'width of the cropped block in pixels';
                obj.View.handles.SingleMaskObjectPerDataset.Enable = 'off';     % because it is using bwselect3 function available in R2017b and newer
                obj.mibStatisticsController.BatchOpt.SingleMaskObjectPerDataset = false; 
                obj.View.handles.marginZEdit.Enable = 'on';
                obj.View.handles.Generate3DPatches.Enable = 'on';
                obj.mibStatisticsController.BatchOpt.Generate3DPatches = false;

                obj.View.handles.marginXYEdit.String = obj.mibStatisticsController.BatchOpt.CropObjectsMarginXY;
                obj.View.handles.marginZEdit.String = obj.mibStatisticsController.BatchOpt.CropObjectsMarginZ;
                obj.View.handles.CropObjectsDepth.String = obj.mibStatisticsController.BatchOpt.CropObjectsDepth;
               
                % when elements GIU needs to be updated, update obj.BatchOpt
                % structure and after that update elements of GUI by the
                % following function
                % obj.View = updateGUIFromBatchOpt_Shared(obj.View, obj.mibStatisticsController.BatchOpt);    %
            end

            % crop objects jitter settings
            obj.View.handles.jitterEnableCheckbox.Value = obj.mibStatisticsController.BatchOpt.CropObjectsJitter;
            obj.View.handles.jitterVariationEditbox.String = obj.mibStatisticsController.BatchOpt.CropObjectsJitterVariation;
            obj.View.handles.jitterSeedEditbox.String = obj.mibStatisticsController.BatchOpt.CropObjectsJitterSeed;

            % add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'Id', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
        end
        
        function closeWindow(obj)
            % closing mibCropObjectsController window
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
            % update widgets of the window
            
            % set default directory for the export
            obj.View.handles.dirEdit.String = obj.mibModel.myPath;
            obj.outputDir = obj.mibModel.myPath;
            
            if obj.mibModel.getImageProperty('maskExist') == 0
                obj.View.handles.cropMaskCheck.Enable = 'off';
            end
            if obj.mibModel.getImageProperty('modelExist') == 0
                obj.View.handles.cropModelCheck.Enable = 'off';
            end

            % update jitter widgets
            if obj.mibStatisticsController.BatchOpt.CropObjectsJitter
                obj.View.handles.jitterVariationEditbox.Enable = 'on';
                obj.View.handles.jitterSeedEditbox.Enable = 'on';
            else
                obj.View.handles.jitterVariationEditbox.Enable = 'off';
                obj.View.handles.jitterSeedEditbox.Enable = 'off';
            end
        end
        
        function generate3DPatches_Callback(obj)
            % function generate3DPatches_Callback(obj)
            % callback for selection of crop 3D objects checkbox
            
            if isempty(obj.annotationLabels)   % standard call from mibStatisticsController
                if obj.View.handles.Generate3DPatches.Value == true
                    obj.View.handles.marginZEdit.Enable = 'on';
                else
                    obj.View.handles.marginZEdit.Enable = 'off';
                    obj.View.handles.marginZEdit.String = '0';
                    obj.updateBatchParameters('CropObjectsMarginZ', obj.View.handles.marginZEdit.String);
                end
            else % check for alternative call from mibAnnotationsController
                obj.View.handles.marginZEdit.Enable = 'on';
                if obj.View.handles.Generate3DPatches.Value == true
                    obj.View.handles.CropObjectsDepth.Enable = 'on';
                else 
                    obj.View.handles.CropObjectsDepth.Enable = 'off';
                end
            end
            obj.updateBatchParameters('Generate3DPatches', obj.View.handles.Generate3DPatches.Value);
        end


        function selectDirBtn_Callback(obj)
            % function selectDirBtn_Callback(obj)
            % a callback for press of obj.View.handles.selectDirBtn to select
            % output directory
            
            obj.View.handles.cropBtn.Enable = 'off';    % sometimes update of dir takes longer and this ensures that crop object waits for the update of the directory
            folder_name = uigetdir(obj.View.handles.dirEdit.String, 'Select directory');
            if isequal(folder_name, 0); obj.View.handles.cropBtn.Enable = 'on'; return; end
            obj.outputDir = folder_name;
            obj.View.handles.dirEdit.String = folder_name;
            obj.View.handles.cropBtn.Enable = 'on';
        end
        
        function dirEdit_Callback(obj)
            % function dirEdit_Callback(obj)
            % a callback for obj.View.handles.dirEdit to select output directory
            
            folder_name = obj.View.handles.dirEdit.String;
            if exist(folder_name, 'dir') == 0
                choice = questdlg(sprintf('!!! Warnging !!!\nThe target directory:\n%s\nis missing!\n\nCreate?', folder_name), ...
                    'Create Directory', ...
                    'Create','Cancel','Cancel');
                if strcmp(choice, 'Cancel')
                    obj.View.handles.dirEdit.String = obj.outputDir;
                    return;
                end
                mkdir(folder_name);
            end
            obj.outputDir = folder_name;
        end
        
        function updateBatchParameters(obj, type, newValue)
            % function fileFormatChange_Callback(obj, type)
            % update obj.mibStatisticsController.BatchOpt parameters
            
            switch type
                case {'CropObjectsTo','CropObjectsIncludeModel','CropObjectsIncludeMask'}
                    obj.mibStatisticsController.BatchOpt.(type){1} = newValue;
                case {'CropObjectsMarginXY', 'CropObjectsMarginZ', 'SingleMaskObjectPerDataset', 'CropObjectsDepth', ...
                        'CropObjectsJitterVariation', 'CropObjectsJitterSeed'}
                    obj.mibStatisticsController.BatchOpt.(type) = newValue;
                case {'Generate3DPatches', 'CropObjectsJitter'}
                    obj.mibStatisticsController.BatchOpt.(type) = newValue;
                otherwise
                    error('wrong value!');
            end
        end
        
        function generatePatches(obj)
            % function generatePatches(obj)
            % generate image patches using annotations as center
            % coordinates. The coordinates are provided in
            % obj.annotationLabels as structure with 
            % .names - cell array with label (annotation) names
            % .positions - matrix with center coordinates of patches to be cropped out from the image, it is used by mibAnnotationsController. 

            global mibPath;
            % switches indicating whether the Z, X, or Y coordinate of
            % annotations should be added to filenames
            includeZ = false;
            includeX = false;
            includeY = false;

            if obj.mibStatisticsController.BatchOpt.CropObjectsJitter
                % initialize random generator
                randSeed = str2double(obj.mibStatisticsController.BatchOpt.CropObjectsJitterSeed);
                if randSeed == 0
                    rng('shuffle');
                else
                    rng(randSeed, 'twister');
                end
                % add jitter to coordinates
                randVariation = str2double(obj.mibStatisticsController.BatchOpt.CropObjectsJitterVariation);
                varMatrix = randi(randVariation*2, [size(obj.annotationLabels.positions,1), 2]) - randVariation;
                obj.annotationLabels.positions(:, 2:3) = obj.annotationLabels.positions(:, 2:3) + varMatrix;
            end

            % round label coordinates
            obj.annotationLabels.positions = round(obj.annotationLabels.positions);

            % generate extension
            extensionPosition = strfind(obj.mibStatisticsController.BatchOpt.CropObjectsTo{1}, '*.');
            ext = '';
            if ~isempty(extensionPosition)
                ext = obj.mibStatisticsController.BatchOpt.CropObjectsTo{1}(extensionPosition+1:end-1);     % to be used below in eval block
            end

            dimOpt.blockModeSwitch = 0;
            [h, w, ~, z, tMax] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, NaN, dimOpt);

            if strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsTo{1}, 'Crop to Matlab')
                outputPath = '';
                fnTemplate = obj.outputVar;
            else
                if ~isfield(obj.mibModel.sessionSettings, 'annotationsCropPatches') || ~isfield(obj.mibModel.sessionSettings.annotationsCropPatches, 'includeName')
                    obj.mibModel.sessionSettings.annotationsCropPatches.includeName = false;
                    obj.mibModel.sessionSettings.annotationsCropPatches.includeZ = false;
                    obj.mibModel.sessionSettings.annotationsCropPatches.includeX = false;
                    obj.mibModel.sessionSettings.annotationsCropPatches.includeY = false;
                    obj.mibModel.sessionSettings.annotationsCropPatches.useSliceNameIdentifier = false;
                    obj.mibModel.sessionSettings.annotationsCropPatches.cropOutAllMaterials = 1;
                end

                % obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{max([1 obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial-2])}
                
                prompts = {'Include annotation name'; 
                           'Include Z coordinate';
                           'Include X coordinate';
                           'Include Y coordinate';
                           'Use slice names as filename templates';
                           sprintf('Would you like to export all materials or only selected?\n(when Crop model selected)')};
                if ~isempty(obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames)
                    modelText1 = 'All materials';
                    modelText2 = sprintf('Selected materials (%s)', obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{max([1 obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial-2])});
                else
                    modelText1 = 'not used';
                    modelText2 = '';
                    obj.mibModel.sessionSettings.annotationsCropPatches.cropOutAllMaterials = 1;
                end
                
                defAns = {obj.mibModel.sessionSettings.annotationsCropPatches.includeName; 
                          obj.mibModel.sessionSettings.annotationsCropPatches.includeZ; 
                          obj.mibModel.sessionSettings.annotationsCropPatches.includeX; 
                          obj.mibModel.sessionSettings.annotationsCropPatches.includeY;
                          obj.mibModel.sessionSettings.annotationsCropPatches.useSliceNameIdentifier;
                          {modelText1, modelText2, obj.mibModel.sessionSettings.annotationsCropPatches.cropOutAllMaterials}; 
                          };
                dlgTitle = 'Crop patches settings';
                options.WindowStyle = 'normal';
                options.PromptLines = [1, 1, 1, 1, 1, 2]; 
                options.Title = 'Specify additional parameters to be added to filenames'; 
                options.TitleLines = 2; 
                options.WindowWidth = 1.2;
                [answer, selValue] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                if isempty(answer); obj.View.handles.cropBtn.BackgroundColor = [0, 1, 0]; return; end 

                obj.mibModel.sessionSettings.annotationsCropPatches.includeName = logical(answer{1});
                obj.mibModel.sessionSettings.annotationsCropPatches.includeZ = logical(answer{2});
                obj.mibModel.sessionSettings.annotationsCropPatches.includeX = logical(answer{3});
                obj.mibModel.sessionSettings.annotationsCropPatches.includeY = logical(answer{4});
                obj.mibModel.sessionSettings.annotationsCropPatches.useSliceNameIdentifier = logical(answer{5});
                obj.mibModel.sessionSettings.annotationsCropPatches.cropOutAllMaterials = selValue(6);

                [outputPath, fnTemplate] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));  %#ok<ASGLU> % to be used below in eval block
                fnTemplate =  repmat({fnTemplate}, [z, 1]); %#ok<NASGU>

                if obj.mibModel.sessionSettings.annotationsCropPatches.useSliceNameIdentifier
                    if isKey(obj.mibModel.I{obj.mibModel.Id}.meta, 'SliceName')
                        sliceNames = obj.mibModel.I{obj.mibModel.Id}.meta('SliceName');
                        if numel(sliceNames) == z
                            [~, fnTemplate] = fileparts(sliceNames); %#ok<ASGLU>
                        end
                    end
                end
            end

            % define materials for export
            if obj.View.handles.cropModelCheck.Value == 1
                if obj.mibModel.sessionSettings.annotationsCropPatches.cropOutAllMaterials == 1 % 'All materials'
                    obj.mibStatisticsController.BatchOpt.CropObjectsIncludeModelMaterialIndex = 'NaN';
                else
                    obj.mibStatisticsController.BatchOpt.CropObjectsIncludeModelMaterialIndex = num2str(max([1 obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial-2]));
                end
                
                % button = questdlg(sprintf('Would you like to export all materials or only selected?'), 'Select material to export', ...
                %     'All materials', sprintf('Material "%s"', obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{max([1 obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial-2])}), 'Cancel', 'All materials');
                % switch button
                %     case 'Cancel'
                %         obj.View.handles.cropBtn.BackgroundColor = [0, 1, 0];
                %         return;
                %     case 'All materials'
                %         obj.mibStatisticsController.BatchOpt.CropObjectsIncludeModelMaterialIndex = 'NaN';
                %     otherwise
                %         obj.mibStatisticsController.BatchOpt.CropObjectsIncludeModelMaterialIndex = num2str(max([1 obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial-2]));
                % end
            end
            material_id = str2double(obj.mibStatisticsController.BatchOpt.CropObjectsIncludeModelMaterialIndex);
        
            if obj.mibStatisticsController.BatchOpt.Generate3DPatches == 0
                obj.mibStatisticsController.BatchOpt.CropObjectsDepth = '1';
                obj.View.handles.CropObjectsDepth.String = '1';
            end

            width = str2double(obj.mibStatisticsController.BatchOpt.CropObjectsMarginXY);
            height = str2double(obj.mibStatisticsController.BatchOpt.CropObjectsMarginZ);
            depth = str2double(obj.mibStatisticsController.BatchOpt.CropObjectsDepth);
            
            if obj.mibStatisticsController.BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'Saving objects'); end
            
            % get unique time points
            noPoints = size(obj.annotationLabels.positions, 1);  % get number of annotation points
            objDigits = numel(num2str(noPoints));   % get number of digits for objects

            for pntId = 1:noPoints
                % generate filename
                annZ = obj.annotationLabels.positions(pntId, 1); % z-coordinate of the annotation

                if strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsTo{1}, 'Crop to Matlab')
                    cmdText = ['filename = fullfile(obj.outputDir, sprintf(''%s_%0' num2str(objDigits) 'd%s'',  fnTemplate, pntId, ext));'];
                    eval(cmdText);
                else
                    cmdText = ['filename = fullfile(obj.outputDir, sprintf(''%s_%0' num2str(objDigits) 'd'',  fnTemplate{annZ}, pntId));'];
                    eval(cmdText);
                    if obj.mibModel.sessionSettings.annotationsCropPatches.includeName
                        filename = sprintf('%s_%s', filename, obj.annotationLabels.names{pntId});
                    end
                    if obj.mibModel.sessionSettings.annotationsCropPatches.includeZ
                        depthDigits = numel(num2str(z));   % get number of digits for objects
                        cmdText = ['filename = sprintf(''%s_z%0' num2str(depthDigits) 'd'', filename, obj.annotationLabels.positions(pntId, 1));']; 
                        eval(cmdText);
                    end
                    if obj.mibModel.sessionSettings.annotationsCropPatches.includeX; filename = sprintf('%s_x%d', filename, obj.annotationLabels.positions(pntId, 2)); end
                    if obj.mibModel.sessionSettings.annotationsCropPatches.includeY; filename = sprintf('%s_y%d', filename, obj.annotationLabels.positions(pntId, 3)); end
                    filename = sprintf('%s%s', filename, ext);
                end

                z1 = obj.annotationLabels.positions(pntId, 1);
                t1 = obj.annotationLabels.positions(pntId, 4);
                getDataOpt.t = [t1 t1];
                getDataOpt.z = [z1-floor(depth/2) z1-floor(depth/2)];
            
                x1 = obj.annotationLabels.positions(pntId, 2) - floor(width/2);
                y1 = obj.annotationLabels.positions(pntId, 3) - floor(height/2);
                z1 = obj.annotationLabels.positions(pntId, 1) - floor(depth/2);
                if x1 < 1; x1 = 1; end
                if x1 > w-width+1; x1 = w-width+1; end
                if y1 < 1; y1 = 1; end
                if y1 > h-height+1; y1 = h-height+1; end
                if z1 < 1; z1 = 1; end
                if z1 > z-depth+1; z1 = z-depth+1; end

                getDataOpt.x = [x1, x1+width-1];
                getDataOpt.y = [y1, y1+height-1];
                getDataOpt.z = [z1, z1+depth-1];

                imOut = obj.mibModel.I{obj.mibModel.Id}.getData('image', 4, NaN, getDataOpt);

                imgOut2 = mibImage(imOut);
                imgOut2.pixSize = obj.mibModel.getImageProperty('pixSize');
                imgOut2.meta('ImageDescription') = obj.mibModel.I{obj.mibModel.Id}.meta('ImageDescription');
                imgOut2.meta('Filename') = filename;

                % update Bounding Box
                xyzShift = [(x1-1)*imgOut2.pixSize.x (y1-1)*imgOut2.pixSize.y (z1-1)*imgOut2.pixSize.z];
                imgOut2.updateBoundingBox(NaN, xyzShift);

                % add XResolution/YResolution fields
                [imgOut2.meta, imgOut2.pixSize] = mibUpdatePixSizeAndResolution(imgOut2.meta, imgOut2.pixSize);

                log_text = sprintf('ObjectCrop: [y1:y2,x1:x2,:,z1:z2,t]: %d:%d,%d:%d,:,%d:%d,%d', y1,y1+height-1,x1,x1+width-1, z1, z1+depth-1, t1);
                imgOut2.updateImgInfo(log_text);

                switch obj.mibStatisticsController.BatchOpt.CropObjectsTo{1}
                    case 'Crop to Matlab'
                        [~, obj.outputVar] = fileparts(filename);
                        matlabVar.img = imgOut2.img{1};
                        matlabVar.meta = containers.Map(keys(imgOut2.meta), values(imgOut2.meta));
                    case 'Amira Mesh binary (*.am)'  % Amira Mesh
                        savingOptions = struct('overwrite', 1);
                        savingOptions.colors = obj.mibModel.getImageProperty('lutColors');   % store colors for color channels 0-1;
                        savingOptions.showWaitbar = 0;  % do not show the waitbar
                        bitmap2amiraMesh(filename, imgOut2.img{1}, ...
                            containers.Map(keys(imgOut2.meta),values(imgOut2.meta)), savingOptions);
                    case 'MRC format for IMOD (*.mrc)' % MRC
                        savingOptions.volumeFilename = filename;
                        savingOptions.pixSize = imgOut2.pixSize;
                        savingOptions.showWaitbar = 0;  % do not show the waitbar
                        mibImage2mrc(imgOut2.img{1}, savingOptions);
                    case 'NRRD Data Format (*.nrrd)'  % NRRD
                        savingOptions = struct('overwrite', 1);
                        savingOptions.showWaitbar = 0;  % do not show the waitbar
                        bb = imgOut2.getBoundingBox();
                        bitmap2nrrd(filename, imgOut2.img{1}, bb, savingOptions);
                    case {'TIF format LZW compression (*.tif)', 'TIF format uncompressed (*.tif)'}  % LZW TIF / uncompressed TIF
                        if strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsTo{1}, 'TIF format LZW compression (*.tif)')
                            compression = 'lzw';
                        else
                            compression = 'none';
                        end
                        colortype = imgOut2.meta('ColorType');
                        if strcmp(colortype,'indexed')
                            cmap = imgOut2.meta('Colormap');
                        else
                            cmap = NaN;
                        end

                        ImageDescription = {imgOut2.meta('ImageDescription')};
                        savingOptions = struct('Resolution', [imgOut2.meta('XResolution') imgOut2.meta('YResolution')],...
                            'overwrite', 1, 'Saving3d', 'multi', 'cmap', cmap, 'Compression', compression, 'showWaitbar', 0);
                        mibImage2tiff(filename, imgOut2.img{1}, savingOptions, ImageDescription);
                end

                % crop and save model
                if ~strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsIncludeModel{1}, 'Do not include')
                    imOut = obj.mibModel.I{obj.mibModel.Id}.getData('model', 4, material_id, getDataOpt);
                    modelMaterialNames = obj.mibModel.getImageProperty('modelMaterialNames'); %#ok<NASGU>
                    modelMaterialColors = obj.mibModel.getImageProperty('modelMaterialColors'); %#ok<NASGU>
                    if material_id > 0
                        modelMaterialColors = modelMaterialColors(material_id, :); %#ok<NASGU>
                        modelMaterialNames = modelMaterialNames(material_id);
                    end

                    if strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsTo{1}, 'Crop to Matlab')     % export to Matlab
                        matlabVar.Model.model = imOut;
                        matlabVar.Model.materials = modelMaterialNames;
                        matlabVar.Model.colors = modelMaterialColors;
                    else
                        % generate filename
                        [~, fnModel] = fileparts(filename);
                        BoundingBox = imgOut2.getBoundingBox(); %#ok<NASGU>

                        switch obj.mibStatisticsController.BatchOpt.CropObjectsIncludeModel{1}
                            case 'Matlab format (*.model)'  % Matlab format
                                fnModel = ['Labels_' fnModel '.model']; %#ok<AGROW>
                                fnModel = fullfile(obj.outputDir, fnModel);
                                modelVariable = 'imOut'; %#ok<NASGU>
                                modelType = obj.mibModel.I{obj.mibModel.Id}.modelType;  %#ok<NASGU> % type of the model
                                str1 = sprintf('save ''%s'' imOut modelMaterialNames modelMaterialColors BoundingBox modelVariable modelType -mat -v7.3', fnModel);
                                eval(str1);
                            case 'Amira Mesh binary (*.am)'  % Amira Mesh
                                fnModel = ['Labels_' fnModel '.am']; %#ok<AGROW>
                                fnModel = fullfile(obj.outputDir, fnModel);

                                pixStr = imgOut2.pixSize;
                                pixStr.minx = BoundingBox(1);
                                pixStr.miny = BoundingBox(3);
                                pixStr.minz = BoundingBox(5);
                                showWaitbar = 0;  % show or not waitbar in bitmap2amiraMesh
                                bitmap2amiraLabels(fnModel, imOut, 'binary', pixStr, modelMaterialColors, modelMaterialNames, 1, showWaitbar);
                            case 'MRC format for IMOD (*.mrc)' % MRC
                                fnModel = ['Labels_' fnModel '.mrc']; %#ok<AGROW>
                                fnModel = fullfile(obj.outputDir, fnModel);

                                Options.volumeFilename = fnModel;
                                Options.pixSize = imgOut2.pixSize;
                                Options.showWaitbar = 0;  % show or not waitbar in exportModelToImodModel
                                mibImage2mrc(imOut, Options);
                            case 'NRRD Data Format (*.nrrd)'  % NRRD
                                fnModel = ['Labels_' fnModel '.nrrd']; %#ok<AGROW>
                                fnModel = fullfile(obj.outputDir, fnModel);

                                Options.overwrite = 1;
                                Options.showWaitbar = 0;  % show or not waitbar in bitmap2nrrd
                                bitmap2nrrd(fnModel, imOut, BoundingBox, Options);
                            case {'TIF format LZW compression (*.tif)', 'TIF format uncompressed (*.tif)'}  % LZW TIF / uncompressed TIF
                                fnModel = ['Labels_' fnModel '.tif']; %#ok<AGROW>
                                fnModel = fullfile(obj.outputDir, fnModel);

                                if strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsIncludeModel{1}, 'TIF format LZW compression (*.tif)')
                                    compression = 'lzw';
                                else
                                    compression = 'none';
                                end
                                ImageDescription = {imgOut2.meta('ImageDescription')};
                                imOut = reshape(imOut,[size(imOut,1) size(imOut,2) 1 size(imOut,3)]);
                                savingOptions = struct('Resolution', [imgOut2.meta('XResolution') imgOut2.meta('YResolution')],...
                                    'overwrite', 1, 'Saving3d', 'multi', 'Compression', compression, 'showWaitbar', 0);
                                mibImage2tiff(fnModel, imOut, savingOptions, ImageDescription);
                        end
                    end
                end

                % crop and save mask
                if ~strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsIncludeMask{1}, 'Do not include')
                    imOut = obj.mibModel.I{obj.mibModel.Id}.getData('mask', 4, material_id, getDataOpt);

                    if strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsTo{1}, 'Crop to Matlab')   % export to Matlab
                        matlabVar.Mask = imOut;
                    else
                        % generate filename
                        [~, fnModel] = fileparts(filename);
                        BoundingBox = imgOut2.getBoundingBox(); %#ok<NASGU>

                        switch obj.mibStatisticsController.BatchOpt.CropObjectsIncludeMask{1}
                            case 'Matlab format (*.mask)'  % Matlab format
                                fnModel = ['Mask_' fnModel '.mask']; %#ok<AGROW>
                                fnModel = fullfile(obj.outputDir, fnModel);
                                save(fnModel, 'imOut','-mat', '-v7.3');
                            case 'Amira Mesh binary (*.am)'  % Amira Mesh
                                fnModel = ['Mask_' fnModel '.am']; %#ok<AGROW>
                                fnModel = fullfile(obj.outputDir, fnModel);

                                pixStr = imgOut2.pixSize;
                                pixStr.minx = BoundingBox(1);
                                pixStr.miny = BoundingBox(3);
                                pixStr.minz = BoundingBox(5);
                                showWaitbar = 0;  % show or not waitbar in bitmap2amiraMesh
                                bitmap2amiraLabels(fnModel, imOut, 'binary', pixStr, [.567, .213, .625], cellstr('Mask'), 1, showWaitbar);
                            case 'MRC format for IMOD (*.mrc)' % MRC
                                fnModel = ['Mask_' fnModel '.mrc']; %#ok<AGROW>
                                fnModel = fullfile(obj.outputDir, fnModel);

                                Options.volumeFilename = fnModel;
                                Options.pixSize = imgOut2.pixSize;
                                Options.showWaitbar = 0;  % show or not waitbar in exportModelToImodModel
                                mibImage2mrc(imOut, Options);
                            case 'NRRD Data Format (*.nrrd)'     % NRRD
                                fnModel = ['Mask_' fnModel '.nrrd']; %#ok<AGROW>
                                fnModel = fullfile(obj.outputDir, fnModel);

                                Options.overwrite = 1;
                                Options.showWaitbar = 0;  % show or not waitbar in bitmap2nrrd
                                bitmap2nrrd(fnModel, imOut, BoundingBox, Options);
                            case {'TIF format LZW compression (*.tif)', 'TIF format uncompressed (*.tif)'}  % LZW TIF / uncompressed TIF
                                fnModel = ['Mask_' fnModel '.tif']; %#ok<AGROW>
                                fnModel = fullfile(obj.outputDir, fnModel);

                                if strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsIncludeMask{1}, 'TIF format LZW compression (*.tif)')
                                    compression = 'lzw';
                                else
                                    compression = 'none';
                                end
                                ImageDescription = {imgOut2.meta('ImageDescription')};
                                imOut = reshape(imOut,[size(imOut,1) size(imOut,2) 1 size(imOut,3)]);
                                savingOptions = struct('Resolution', [imgOut2.meta('XResolution') imgOut2.meta('YResolution')],...
                                    'overwrite', 1, 'Saving3d', 'multi', 'Compression', compression, 'showWaitbar', 0);
                                mibImage2tiff(fnModel, imOut, savingOptions, ImageDescription);
                        end
                    end
                end

                % export to Matlab
                if strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsTo{1}, 'Crop to Matlab')
                    [~, matlabVarName] = fileparts(filename);
                    assignin('base', matlabVarName, matlabVar);
                    fprintf('MIB: "%s" was exported to Matlab\n', matlabVarName);
                end
                if obj.mibStatisticsController.BatchOpt.showWaitbar; waitbar(pntId/noPoints, wb); end
            end
            if obj.mibStatisticsController.BatchOpt.showWaitbar; delete(wb); end
            %obj.View.handles.cropBtn.BackgroundColor = [0 1 0];
            obj.closeWindow(); 
        end

        function cropBtn_Callback(obj, batchModeSwitch)
            % function cropBtn_Callback(obj)
            % a callback for press of obj.View.handles.cropBtn to start cropping            
            % Parameters:
            % batchModeSwitch: a logical switch indicating start of the function using the batch mode
            if nargin < 2; batchModeSwitch = 0; end
            global mibPath; % path to mib installation folder
            
            obj.mibModel.sessionSettings.annotationsCropPatches.CropObjectsJitterVariation = obj.mibStatisticsController.BatchOpt.CropObjectsJitterVariation;   % variation of the jitter in pixels
            obj.mibModel.sessionSettings.annotationsCropPatches.CropObjectsJitterSeed = obj.mibStatisticsController.BatchOpt.CropObjectsJitterSeed;    % initialization of the random generator, when 0-random
            
            if isfield(obj.annotationLabels, 'positions') % alternative call from mibAnnotationsController
                obj.generatePatches();
                return;
            end

            % generate extension
            extensionPosition = strfind(obj.mibStatisticsController.BatchOpt.CropObjectsTo{1}, '*.');
            ext = '';
            if ~isempty(extensionPosition)
                ext = obj.mibStatisticsController.BatchOpt.CropObjectsTo{1}(extensionPosition+1:end-1);     % to be used below in eval block
            end
            if strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsTo{1}, 'Crop to Matlab')
                outputPath = '';
                fnTemplate = obj.outputVar;
            else
                [outputPath, fnTemplate] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));  % to be used below in eval block
            end
            
            if batchModeSwitch == 0
                obj.View.handles.cropBtn.BackgroundColor = [1, 0, 0];
                
                data = obj.mibStatisticsController.View.handles.statTable.Data;
                % find uniqueTime - unique time points and their indices uniqueIndex
                selectedIndices = unique(obj.mibStatisticsController.indices(:,1));
                % linear object indices, i.e. in a sequence how they were detected
                objIndices = str2num(cell2mat(obj.mibStatisticsController.View.handles.statTable.RowName(selectedIndices)));
                [uniqueTime, ~, uniqueIndex] = unique(data(selectedIndices,4));
                
                % define materials for export
                if obj.View.handles.cropModelCheck.Value == 1
                    button = questdlg(sprintf('Would you like to export all materials or only selected?'), 'Select material to export', ...
                        'All materials', sprintf('Material "%s"', obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{max([1 obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial-2])}), 'Cancel', 'All materials');
                    switch button
                        case 'Cancel'
                            obj.View.handles.cropBtn.BackgroundColor = [0, 1, 0];
                            return;
                        case 'All materials'
                            obj.mibStatisticsController.BatchOpt.CropObjectsIncludeModelMaterialIndex = 'NaN';
                        otherwise
                            obj.mibStatisticsController.BatchOpt.CropObjectsIncludeModelMaterialIndex = num2str(max([1 obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial-2]));
                    end
                end
            else
                % generate data table, similar to the Statistics table of mibStatisticsController window
                data = zeros(numel(obj.mibStatisticsController.STATS),4);
                if numel(data) ~= 0
                    [data(:,2), sortingRowIndex] = sort(cat(1,obj.mibStatisticsController.STATS.(obj.mibStatisticsController.BatchOpt.Property{1})), 'descend');
                    % add object Ids
                    data(:, 1) = [obj.mibStatisticsController.STATS(sortingRowIndex).ObjectId];

                    w1 = obj.mibModel.getImageProperty('width');
                    h1 = obj.mibModel.getImageProperty('height');
                    d1 = obj.mibModel.getImageProperty('depth');
                    for row = 1:size(data, 1)
                        pixelId = max([1 floor(numel(obj.mibStatisticsController.STATS(sortingRowIndex(row)).PixelIdxList)/2)]);  % id of the voxel to get a slice number
                        [~, ~, data(row,3)] = ind2sub([w1, h1, d1], ...
                            obj.mibStatisticsController.STATS(sortingRowIndex(row)).PixelIdxList(pixelId));
                    end
                    data(:, 4) = [obj.mibStatisticsController.STATS(sortingRowIndex(row)).TimePnt];
                end
                selectedIndices = 1:numel(obj.mibStatisticsController.STATS);
                [uniqueTime, ~, uniqueIndex] = unique([obj.mibStatisticsController.STATS.TimePnt]);
                
                % update obj.outputDir
                if ~strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsTo{1}, 'Crop to Matlab')  % i.e. save to a file
                    if obj.mibStatisticsController.BatchOpt.CropObjectsOutputName(1) ~= filesep % add slash before the filename
                        obj.mibStatisticsController.BatchOpt.CropObjectsOutputName = [filesep obj.mibStatisticsController.BatchOpt.CropObjectsOutputName]; 
                    end  
                    if isempty(outputPath); outputPath = obj.mibModel.myPath; end
                    obj.outputDir = [outputPath, obj.mibStatisticsController.BatchOpt.CropObjectsOutputName];
                    if exist(obj.outputDir, 'dir') == 0; mkdir(obj.outputDir); end  % create a new directory for the output
                else
                    fnTemplate = obj.mibStatisticsController.BatchOpt.CropObjectsOutputName;
                end
            end
            
            material_id = str2double(obj.mibStatisticsController.BatchOpt.CropObjectsIncludeModelMaterialIndex);
            dimOpt.blockModeSwitch = 0;
            [h, w, ~, z, tMax] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, NaN, dimOpt);
            
            % set CC structure for identification of the Bounding Box
            if strcmp(obj.mibStatisticsController.BatchOpt.Shape{1}, 'Shape2D')  % 2D mode
                if strcmp(obj.mibStatisticsController.BatchOpt.Connectivity{1}, '4/6 connectivity')
                    CC.Connectivity = 4;
                else
                    CC.Connectivity = 8;
                end
                CC.ImageSize = [h, w];
                jitterWidthIndex = 3;   % index of the object width in S.BoundingBox for coordinates jitter 
                jitterHeightIndex = 4;  % index of the object height in S.BoundingBox
            else            % 3D mode
                if strcmp(obj.mibStatisticsController.BatchOpt.Connectivity{1}, '4/6 connectivity')
                    CC.Connectivity = 6;
                else
                    CC.Connectivity = 26;
                end
                CC.ImageSize = [h, w, z];
                jitterWidthIndex = 4;   % index of the object width in S.BoundingBox for coordinates jitter 
                jitterHeightIndex = 5;  % index of the object height in S.BoundingBox
            end
            CC.NumObjects = 1;
            
            marginXY = str2double(obj.mibStatisticsController.BatchOpt.CropObjectsMarginXY);
            marginZ = str2double(obj.mibStatisticsController.BatchOpt.CropObjectsMarginZ);
            
            if tMax > 1; timeDigits = numel(num2str(tMax)); end   % get number of digits for time
            
            timeIter = 1;
            if obj.mibStatisticsController.BatchOpt.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'Saving objects'); end
            
            % define random generator for the jitter of coordinates
            if obj.mibStatisticsController.BatchOpt.CropObjectsJitter
                % initialize random generator
                randSeed = str2double(obj.mibStatisticsController.BatchOpt.CropObjectsJitterSeed);
                if randSeed == 0
                    rng('shuffle');
                else
                    rng(randSeed, 'twister');
                end
                % acquire variation for the jitter
                randVariation = str2double(obj.mibStatisticsController.BatchOpt.CropObjectsJitterVariation);
            end

            objectDigits = numel(num2str(numel(obj.mibStatisticsController.STATS))); % get number of digits for objects

            for t=uniqueTime'   % has to be a horizontal vector
                if obj.mibStatisticsController.BatchOpt.showWaitbar; waitbar(0, wb, sprintf('Time point: %d\nPlease wait...', t)); end
                
                if ~strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsIncludeModel{1}, 'Do not include')
                    modelImg =  cell2mat(obj.mibModel.getData3D('model', t, 4, material_id, dimOpt));
                end
                if ~strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsIncludeMask{1}, 'Do not include')
                    maskImg =  cell2mat(obj.mibModel.getData3D('mask', t, 4, NaN, dimOpt));
                end
                
                curTimeObjIndices = selectedIndices(uniqueIndex==timeIter);     % find indices of objects for the current time point t
                
                for rowId = 1:numel(curTimeObjIndices)
                    %objId = data(curTimeObjIndices(rowId), 1);
                    objId = str2double(obj.mibStatisticsController.View.handles.statTable.RowName(curTimeObjIndices(rowId)));
                    
                    if strcmp(obj.mibStatisticsController.BatchOpt.Shape{1}, 'Shape2D')  % 2D mode
                        sliceDigits = numel(num2str(z));    % get number of digits for slices
                        sliceNumber = data(curTimeObjIndices(rowId), 3); %#ok<NASGU>
                        if tMax == 1
                            cmdText = ['filename = fullfile(obj.outputDir, sprintf(''%s_%0' num2str(sliceDigits) 'd_%0' num2str(objectDigits) 'd%s'',  fnTemplate, sliceNumber, objId, ext));'];
                        else
                            cmdText = ['filename = fullfile(obj.outputDir, sprintf(''%s_%0' num2str(timeDigits) 'd_%0' num2str(sliceDigits) 'd_%0' num2str(objectDigits) 'd%s'',  fnTemplate, t, sliceNumber, objId, ext));'];
                        end
                        eval(cmdText);
                        
                        % recalculate pixelIds from 3D to 2D space
                        CC.PixelIdxList{1} = obj.mibStatisticsController.STATS(objId).PixelIdxList-h*w*(sliceNumber-1);
                        
                        % get coordinates of a pixel that belongs to the object
                        pixelInObject = CC.PixelIdxList{1}(1);
                        [objPixY, objPixX] = ind2sub([h, w], pixelInObject);
                        objPixZ = 1;
                    else    % 3D objects
                        %filename = fullfile(handles.outputDir, sprintf('%s_%06d%s',  fnTemplate, objId, ext));
                        if tMax == 1
                            cmdText = ['filename = fullfile(obj.outputDir, sprintf(''%s_%0' num2str(objectDigits) 'd%s'',  fnTemplate, objId, ext));'];
                        else
                            cmdText = ['filename = fullfile(obj.outputDir, sprintf(''%s_%0' num2str(timeDigits) 'd_%0' num2str(objectDigits) 'd%s'',  fnTemplate, t, objId, ext));'];
                        end
                        eval(cmdText);
                        CC.PixelIdxList{1} = obj.mibStatisticsController.STATS(objId).PixelIdxList;
                        
                        % get coordinates of a pixel that belongs to the object
                        pixelInObject = CC.PixelIdxList{1}(1);
                        [objPixY, objPixX, objPixZ] = ind2sub([h, w, z], pixelInObject);
                    end
                    
                    % get bounding box
                    S = regionprops(CC, 'BoundingBox');
                    
                    % add jitter
                    if obj.mibStatisticsController.BatchOpt.CropObjectsJitter
                        varJitterX = randi(randVariation*2)-randVariation;
                        varJitterY = randi(randVariation*2)-randVariation;
                        
                        % check border cases
                        if S.BoundingBox(1) + varJitterX < 0.5; varJitterX = 0; end
                        if S.BoundingBox(2) + varJitterY < 0.5; varJitterY = 0; end
                        if S.BoundingBox(1)+S.BoundingBox(jitterWidthIndex)+varJitterX > w; varJitterX = 0; end
                        if S.BoundingBox(2)+S.BoundingBox(jitterHeightIndex)+varJitterY > h; varJitterY = 0; end
                        S.BoundingBox(1) = S.BoundingBox(1) + varJitterX;
                        S.BoundingBox(2) = S.BoundingBox(2) + varJitterY;
                    end

                    if strcmp(obj.mibStatisticsController.BatchOpt.Shape{1}, 'Shape2D')  % 2D mode
                        xMin = ceil(S.BoundingBox(1))-marginXY;
                        yMin = ceil(S.BoundingBox(2))-marginXY;
                        xMax = xMin+floor(S.BoundingBox(3))-1+marginXY*2;
                        yMax = yMin+floor(S.BoundingBox(4))-1+marginXY*2;
                        zMin = sliceNumber-marginZ;
                        zMax = sliceNumber+marginZ;
                    else
                        xMin = ceil(S.BoundingBox(1))-marginXY;
                        yMin = ceil(S.BoundingBox(2))-marginXY;
                        xMax = xMin+floor(S.BoundingBox(4))-1+marginXY*2;
                        yMax = yMin+floor(S.BoundingBox(5))-1+marginXY*2;
                        zMin = ceil(S.BoundingBox(3))-marginZ;
                        zMax = zMin+floor(S.BoundingBox(6))-1+marginZ*2;
                    end
                    
                    xMin = max([xMin 1]);
                    yMin = max([yMin 1]);
                    zMin = max([zMin 1]);
                    xMax = min([xMax w]);
                    yMax = min([yMax h]);
                    zMax = min([zMax z]);
                    
                    % shift objPixY and objPixX
                    objPixX = objPixX - xMin + 1;
                    objPixY = objPixY - yMin + 1;
                    objPixZ = objPixZ - zMin + 1;
                    
                    getDataOptions.y = [yMin, yMax];
                    getDataOptions.x = [xMin, xMax];
                    getDataOptions.z = [zMin, zMax];
                    getDataOptions.t = [t, t];
                    imOut = obj.mibModel.I{obj.mibModel.Id}.getData('image', 4, 0, getDataOptions);

                    imgOut2 = mibImage(imOut);
                    imgOut2.pixSize = obj.mibModel.getImageProperty('pixSize');
                    imgOut2.meta('ImageDescription') = obj.mibModel.I{obj.mibModel.Id}.meta('ImageDescription');
                    imgOut2.meta('Filename') = filename;
                    
                    % update Bounding Box
                    xyzShift = [(xMin-1)*imgOut2.pixSize.x (yMin-1)*imgOut2.pixSize.y (zMin-1)*imgOut2.pixSize.z];
                    imgOut2.updateBoundingBox(NaN, xyzShift);

                    % add XResolution/YResolution fields
                    [imgOut2.meta, imgOut2.pixSize] = mibUpdatePixSizeAndResolution(imgOut2.meta, imgOut2.pixSize);
                    
                    log_text = sprintf('ObjectCrop: [y1:y2,x1:x2,:,z1:z2,t]: %d:%d,%d:%d,:,%d:%d,%d', yMin,yMax,xMin,xMax, zMin,zMax,t);
                    imgOut2.updateImgInfo(log_text);
                    
                    switch obj.mibStatisticsController.BatchOpt.CropObjectsTo{1}
                        case 'Crop to Matlab'
                            %matlabVarName = sprintf('%s_%06d%s',  fnTemplate, objId);
                            if batchModeSwitch == 0; [~, obj.outputVar] = fileparts(filename); end
                            matlabVar.img = imgOut2.img{1};
                            matlabVar.meta = containers.Map(keys(imgOut2.meta), values(imgOut2.meta));
                        case 'Amira Mesh binary (*.am)'  % Amira Mesh
                            savingOptions = struct('overwrite', 1);
                            savingOptions.colors = obj.mibModel.getImageProperty('lutColors');   % store colors for color channels 0-1;
                            savingOptions.showWaitbar = 0;  % do not show the waitbar
                            bitmap2amiraMesh(filename, imgOut2.img{1}, ...
                                containers.Map(keys(imgOut2.meta),values(imgOut2.meta)), savingOptions);
                        case 'MRC format for IMOD (*.mrc)' % MRC
                            savingOptions.volumeFilename = filename;
                            savingOptions.pixSize = imgOut2.pixSize;
                            savingOptions.showWaitbar = 0;  % do not show the waitbar
                            mibImage2mrc(imgOut2.img{1}, savingOptions);
                        case 'NRRD Data Format (*.nrrd)'  % NRRD
                            savingOptions = struct('overwrite', 1);
                            savingOptions.showWaitbar = 0;  % do not show the waitbar
                            bb = imgOut2.getBoundingBox();
                            bitmap2nrrd(filename, imgOut2.img{1}, bb, savingOptions);
                        case {'TIF format LZW compression (*.tif)', 'TIF format uncompressed (*.tif)'}  % LZW TIF / uncompressed TIF
                            if strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsTo{1}, 'TIF format LZW compression (*.tif)')
                                compression = 'lzw';
                            else
                                compression = 'none';
                            end
                            colortype = imgOut2.meta('ColorType');
                            if strcmp(colortype,'indexed')
                                cmap = imgOut2.meta('Colormap');
                            else
                                cmap = NaN;
                            end
                            
                            ImageDescription = {imgOut2.meta('ImageDescription')};
                            savingOptions = struct('Resolution', [imgOut2.meta('XResolution') imgOut2.meta('YResolution')],...
                                'overwrite', 1, 'Saving3d', 'multi', 'cmap', cmap, 'Compression', compression, 'showWaitbar', 0);
                            mibImage2tiff(filename, imgOut2.img{1}, savingOptions, ImageDescription);
                    end
                    
                    % crop and save model
                    if ~strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsIncludeModel{1}, 'Do not include')
                        imgOut2.hLabels = copy(obj.mibModel.I{obj.mibModel.Id}.hLabels);
                        % crop labels
                        imgOut2.hLabels.crop([xMin, yMin, NaN, NaN, zMin, NaN]);
                        
                        imOut =  modelImg(yMin:yMax, xMin:xMax, zMin:zMax); %#ok<NASGU>
                        
                        modelMaterialNames = obj.mibModel.getImageProperty('modelMaterialNames'); %#ok<NASGU>
                        modelMaterialColors = obj.mibModel.getImageProperty('modelMaterialColors'); %#ok<NASGU>
                        if material_id > 0
                            modelMaterialColors = modelMaterialColors(material_id, :); %#ok<NASGU>
                            modelMaterialNames = modelMaterialNames(material_id);
                        end
                        if strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsTo{1}, 'Crop to Matlab')     % export to Matlab
                            matlabVar.Model.model = imOut;
                            matlabVar.Model.materials = modelMaterialNames;
                            matlabVar.Model.colors = modelMaterialColors;
                            if obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsNumber() > 1  % save annotations
                                [labelText, labelValue, labelPosition] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels(); %#ok<NASGU,ASGLU>
                                matlabVar.labelText = labelText;
                                matlabVar.labelValue = labelValue;
                                matlabVar.labelPosition = labelPosition;
                            end
                        else
                            % generate filename
                            [~, fnModel] = fileparts(filename);
                            BoundingBox = imgOut2.getBoundingBox(); %#ok<NASGU>
                            
                            switch obj.mibStatisticsController.BatchOpt.CropObjectsIncludeModel{1}
                                case 'Matlab format (*.model)'  % Matlab format
                                    fnModel = ['Labels_' fnModel '.model']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    
                                    modelVariable = 'imOut'; %#ok<NASGU>
                                    modelType = obj.mibModel.I{obj.mibModel.Id}.modelType;  %#ok<NASGU> % type of the model
                                    
                                    if obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsNumber() > 1  % save annotations
                                        %[labelText, labelValue, labelPosition] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels(); %#ok<NASGU,ASGLU>
                                        %save(fnModel, 'imOut', 'modelMaterialNames', 'modelMaterialColors', 'BoundingBox', 'labelText', 'labelValue', 'labelPosition', '-mat', '-v7.3');
                                        
                                        [labelText, labelValue, labelPosition] = imgOut2.hLabels.getLabels(); %#ok<NASGU,ASGLU>
                                        str1 = sprintf('save ''%s'' imOut modelMaterialNames modelMaterialColors BoundingBox modelVariable modelType labelText labelValue labelPosition -mat -v7.3', fnModel);
                                    else    % save without annotations
                                        %save(fnModel, 'imOut', 'modelMaterialNames', 'modelMaterialColors', 'BoundingBox', '-mat', '-v7.3');
                                        str1 = sprintf('save ''%s'' imOut modelMaterialNames modelMaterialColors BoundingBox modelVariable modelType -mat -v7.3', fnModel);
                                    end
                                    eval(str1);
                                case 'Amira Mesh binary (*.am)'  % Amira Mesh
                                    fnModel = ['Labels_' fnModel '.am']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    
                                    pixStr = imgOut2.pixSize;
                                    pixStr.minx = BoundingBox(1);
                                    pixStr.miny = BoundingBox(3);
                                    pixStr.minz = BoundingBox(5);
                                    showWaitbar = 0;  % show or not waitbar in bitmap2amiraMesh
                                    bitmap2amiraLabels(fnModel, imOut, 'binary', pixStr, modelMaterialColors, modelMaterialNames, 1, showWaitbar);
                                case 'MRC format for IMOD (*.mrc)' % MRC
                                    fnModel = ['Labels_' fnModel '.mrc']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    
                                    Options.volumeFilename = fnModel;
                                    Options.pixSize = imgOut2.pixSize;
                                    Options.showWaitbar = 0;  % show or not waitbar in exportModelToImodModel
                                    mibImage2mrc(imOut, Options);
                                case 'NRRD Data Format (*.nrrd)'  % NRRD
                                    fnModel = ['Labels_' fnModel '.nrrd']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    
                                    Options.overwrite = 1;
                                    Options.showWaitbar = 0;  % show or not waitbar in bitmap2nrrd
                                    bitmap2nrrd(fnModel, imOut, BoundingBox, Options);
                                case {'TIF format LZW compression (*.tif)', 'TIF format uncompressed (*.tif)'}  % LZW TIF / uncompressed TIF
                                    fnModel = ['Labels_' fnModel '.tif']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    
                                    if strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsIncludeModel{1}, 'TIF format LZW compression (*.tif)') 
                                        compression = 'lzw';
                                    else
                                        compression = 'none';
                                    end
                                    ImageDescription = {imgOut2.meta('ImageDescription')};
                                    imOut = reshape(imOut,[size(imOut,1) size(imOut,2) 1 size(imOut,3)]);
                                    savingOptions = struct('Resolution', [imgOut2.meta('XResolution') imgOut2.meta('YResolution')],...
                                        'overwrite', 1, 'Saving3d', 'multi', 'Compression', compression, 'showWaitbar', 0);
                                    mibImage2tiff(fnModel, imOut, savingOptions, ImageDescription);
                            end
                        end
                    end
                    
                    % crop and save mask
                    if ~strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsIncludeMask{1}, 'Do not include')
                        imOut =  maskImg(yMin:yMax, xMin:xMax, zMin:zMax);
                        if obj.mibStatisticsController.BatchOpt.SingleMaskObjectPerDataset   % remove all secondary object from the image
                            if imOut(objPixY, objPixX, max([objPixZ 1])) ~= 1
                                obj.mibStatisticsController.BatchOpt.SingleMaskObjectPerDataset = false;
                            else
                                if strcmp(obj.mibStatisticsController.BatchOpt.Shape{1}, 'Shape2D')  % 2D mode
                                    imOut = uint8(bwselect(imOut, objPixX, objPixY, CC.Connectivity));
                                    % imOut(imOut~=imOut(objPixY-yMin+1, objPixX-xMin+1)) = 0; alternative solution
                                else
                                    if verLessThan('matlab',' 9.3')     % requires R2017b and newer
                                        obj.mibStatisticsController.BatchOpt.SingleMaskObjectPerDataset = false;
                                    else 
                                        if size(imOut,3) > 1
                                            imOut = uint8(bwselect3(imOut, objPixX, objPixY, objPixZ, CC.Connectivity));
                                        else
                                            imOut = uint8(bwselect(imOut, objPixX, objPixY, CC.Connectivity));
                                        end
                                    end
                                end
                            end
                        end
                        % obj.mibStatisticsController.BatchOpt.SingleMaskObjectPerDataset objPixX, objPixY
                        if strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsTo{1}, 'Crop to Matlab')   % export to Matlab
                            matlabVar.Mask = imOut;
                        else
                            % generate filename
                            [~, fnModel] = fileparts(filename);
                            BoundingBox = imgOut2.getBoundingBox(); %#ok<NASGU>
                            
                            switch obj.mibStatisticsController.BatchOpt.CropObjectsIncludeMask{1}
                                case 'Matlab format (*.mask)'  % Matlab format
                                    fnModel = ['Mask_' fnModel '.mask']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    save(fnModel, 'imOut','-mat', '-v7.3');
                                case 'Amira Mesh binary (*.am)'  % Amira Mesh
                                    fnModel = ['Mask_' fnModel '.am']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    
                                    pixStr = imgOut2.pixSize;
                                    pixStr.minx = BoundingBox(1);
                                    pixStr.miny = BoundingBox(3);
                                    pixStr.minz = BoundingBox(5);
                                    showWaitbar = 0;  % show or not waitbar in bitmap2amiraMesh
                                    bitmap2amiraLabels(fnModel, imOut, 'binary', pixStr, [.567, .213, .625], cellstr('Mask'), 1, showWaitbar);
                                case 'MRC format for IMOD (*.mrc)' % MRC
                                    fnModel = ['Mask_' fnModel '.mrc']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    
                                    Options.volumeFilename = fnModel;
                                    Options.pixSize = imgOut2.pixSize;
                                    Options.showWaitbar = 0;  % show or not waitbar in exportModelToImodModel
                                    mibImage2mrc(imOut, Options);
                                case 'NRRD Data Format (*.nrrd)'     % NRRD
                                    fnModel = ['Mask_' fnModel '.nrrd']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    
                                    Options.overwrite = 1;
                                    Options.showWaitbar = 0;  % show or not waitbar in bitmap2nrrd
                                    bitmap2nrrd(fnModel, imOut, BoundingBox, Options);
                                case {'TIF format LZW compression (*.tif)', 'TIF format uncompressed (*.tif)'}  % LZW TIF / uncompressed TIF
                                    fnModel = ['Mask_' fnModel '.tif']; %#ok<AGROW>
                                    fnModel = fullfile(obj.outputDir, fnModel);
                                    
                                    if strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsIncludeMask{1}, 'TIF format LZW compression (*.tif)')
                                        compression = 'lzw';
                                    else
                                        compression = 'none';
                                    end
                                    ImageDescription = {imgOut2.meta('ImageDescription')};
                                    imOut = reshape(imOut,[size(imOut,1) size(imOut,2) 1 size(imOut,3)]);
                                    savingOptions = struct('Resolution', [imgOut2.meta('XResolution') imgOut2.meta('YResolution')],...
                                        'overwrite', 1, 'Saving3d', 'multi', 'Compression', compression, 'showWaitbar', 0);
                                    mibImage2tiff(fnModel, imOut, savingOptions, ImageDescription);
                            end
                        end
                    end
                    
                    % export to Matlab
                    if strcmp(obj.mibStatisticsController.BatchOpt.CropObjectsTo{1}, 'Crop to Matlab')
                        [~, matlabVarName] = fileparts(filename);
                        assignin('base', matlabVarName, matlabVar);
                        fprintf('MIB: "%s" was exported to Matlab\n', matlabVarName);
                    end
                    
                    if obj.mibStatisticsController.BatchOpt.showWaitbar; waitbar(rowId/numel(curTimeObjIndices), wb); end
                end
                timeIter = timeIter + 1;
            end
            if obj.mibStatisticsController.BatchOpt.showWaitbar; delete(wb); end
            %obj.View.handles.cropBtn.BackgroundColor = [0 1 0];
            
            if batchModeSwitch == 0
                % for batch need to generate an event and send the BatchOptLoc
                % structure with it to the macro recorder / mibBatchController
                obj.mibStatisticsController.BatchOpt.ExportResultsTo{1} = 'Do not export';
                obj.mibStatisticsController.returnBatchOpt(obj.mibStatisticsController.BatchOpt);
                obj.mibStatisticsController.BatchOpt = obj.storedBatchOpt;  % restore BatchOpt
                obj.closeWindow(); 
            else
                obj.mibStatisticsController.BatchOpt = obj.storedBatchOpt;  % restore BatchOpt
            end
            
        end
    end
end