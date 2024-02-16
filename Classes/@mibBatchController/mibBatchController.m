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

classdef mibBatchController < handle
    % classdef mibBatchController < handle
    % This a template class for making GUI windows for MIB
    % it is the second version that was designed to be compatible with
    % future macro editor
    %
    % @code
    % obj.startController('mibBatchController'); // as GUI tool
    % @endcode
    
    
    properties
        mibController
        % handle to mibController
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        CurrentBatch
        % a structure with selected Batch options, returned by returnBatchOpt function of the controller
        jSelectedActionTable
        % a handle to java class for the selectedActionTable
        jSelectedActionTableScroll
        % a handle to java class for the selectedActionTable scroll
        Protocol
        % a structure with picked actions that should be executed
        ProtocolBackups
        % a cell array with backuped protocols
        ProtocolBackupsCurrNumber
        % current number of the protocol history
        ProtocolBackupsMaxNumber
        % maximal number of protocol history for backup
        Sections
        % a strutcure with available Sections and corresponding actions
        % Sections(id).Name -> name of available section (i.e. 'Menu -> File', 'Menu -> Dataset')
        % Sections(id).Actions(id2).Name -> name of an action available for the selected section (i.e. 'Tools for Images -> Image Arithmetics', 'Semi-automatic segmentation --> Global thresholding')
        % Sections(id).Actions(id2).Parameters -> a structure with parameters for the action
        selectedActionTableIndex
        % index of a row selected in the selectedActionTable
        protocolListIndex
        % index of a row selected in the protocolList
        selectedSection
        % index of the selected section, i.e. id for obj.Sections(id) updated by obj.View.handles.sectionPopup
        selectedAction
        % index of the selected action for the currect section, i.e. id2 for Sections(id).Actions(id2) updated by obj.View.handles.actionPopup
    end
    
    properties (SetObservable)
        stopProtocolSwitch
        % stop protocol property
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
        stopProtocol
        % stop batch
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
                case 'syncBatch'
                    obj.selectedActionTableIndex = 1;
                    obj.updateWidgets();
                    obj.updateSelectedActionTable(evnt.Parameter);  % update the selected action table
                    if obj.View.handles.autoAddToProtocol.Value == true     % add to protocol
                        obj.protocolActions_Callback('add');
                    end
                    %obj.displaySelectedActionTableItems();
                case 'stopProtocol'
                    obj.stopProtocolSwitch = true;
                    obj.View.handles.runProtocolBtn.String = 'Start protocol';
                    obj.View.handles.runProtocolBtn.BackgroundColor = 'g';
            end
        end
    end
    
    methods
        % declaration of functions in the external files, keep empty line in between for the doc generator
        updateWidgets(obj)  % update widgets of the GUI
        
        function obj = mibBatchController(mibModel, varargin)
            obj.mibModel = mibModel;    % assign model
            obj.mibController = varargin{1};    % obtain mibController
            % check for the virtual stacking mode and close the controller if the plugin is not compatible with the virtual stacking mode
            if isprop(obj.mibModel.I{obj.mibModel.Id}, 'Virtual') && obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nThis plugin is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
                    'Not implemented');
                obj.closeWindow();
                return;
            end
            
            obj.Protocol = [];
            obj.ProtocolBackups = {};
            
            % generate Actions structure
            secIndex = 1;
            actionId = 1;
            obj.Sections(secIndex).Name = 'Menu -> File';
            obj.Sections(secIndex).Actions(actionId).Name = 'Load and combine images';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibFilesListbox_cm_Callback([], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Example datasets';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.menuFileExamples_Callback(Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Save dataset';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.saveImageAsDialog([], Batch);'; actionId = actionId + 1;
            %obj.Sections(secIndex).Actions(actionId).Name = 'Make snapshot';
            %obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.startController(''mibSnapshotController'', Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'DIRECTORY LOOP START';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.DirectoryLoopAction_Callback(Batch)'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'DIRECTORY LOOP STOP';
            obj.Sections(secIndex).Actions(actionId).Command = []; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'FILE LOOP START';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.FileLoopAction_Callback(Batch)'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'FILE LOOP STOP';
            obj.Sections(secIndex).Actions(actionId).Command = []; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Directory operations';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.DirectoryOperationsAction_Callback(Batch)'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'File operations';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.FileOperationsAction_Callback(Batch)'; actionId = actionId + 1;
            
            secIndex = secIndex + 1;
            actionId = 1;
            obj.Sections(secIndex).Name = 'Menu -> Dataset';
            obj.Sections(secIndex).Actions(actionId).Name = 'Alignment tool';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.startController(''mibAlignmentController'', [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Crop dataset';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.startController(''mibCropController'', [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Resample...';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.startController(''mibResampleController'', [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Transform...';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.menuDatasetTrasform_Callback([], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Transform... --> Add frame (width/height)';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.menuDatasetTrasform_Callback(''Add frame (width/height)'', Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Transform... --> Add frame (dX/dY)';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.menuDatasetTrasform_Callback(''Add frame (dX/dY)'', Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Slice -> Copy slice';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.copySwapSlice([], [], ''replace'', Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Slice -> Delete slice/frame';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.deleteSlice([], [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Slice -> Insert an empty slice';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.insertEmptySlice(Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Slice -> Stride reslicing';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.resliceDataset([], [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Slice -> Swap slices';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.copySwapSlice([], [], ''swap'', Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Bounding Box';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.startController(''mibBoundingBoxController'', [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Parameters';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.menuDatasetParameters_Callback([], Batch);'; actionId = actionId + 1;
            
            secIndex = secIndex + 1;
            actionId = 1;
            obj.Sections(secIndex).Name = 'Menu -> Image';
            obj.Sections(secIndex).Actions(actionId).Name = 'Mode';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.menuImageMode_Callback([], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Adjust Display/Image';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.startController(''mibImageAdjController'', [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Color channel actions';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.colorChannelActions([], [], [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Contrast -> Contrast-limited adaptive histogram equalization';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.contrastCLAHE(''Current stack (3D)'', Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Contrast -> Normalize layers';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.contrastNormalization(''Z stack'', Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Invert image';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.menuImageInvert_Callback([], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Image filters';
            obj.Sections(secIndex).Actions(actionId).Command = ''; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Tools for Images -> Content-aware fill';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.contentAwareFill(Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Tools for Images -> Debris removal';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.startController(''mibDebrisRemovalController'', [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Tools for Images -> Image Arithmetics';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.startController(''mibImageArithmeticController'', [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Tools for Images -> Intensity projection';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.menuImageToolsProjection_Callback(Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Tools for Images -> White balance correction';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.startController(''mibWhiteBalanceController'', [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Morphological operations';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.startController(''mibImageMorphOpsController'', [], Batch);'; actionId = actionId + 1;
            
            secIndex = secIndex + 1;
            actionId = 1;
            obj.Sections(secIndex).Name = 'Menu -> Models';
            obj.Sections(secIndex).Actions(actionId).Name = 'Model to Mask';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.moveLayers(''model'', ''mask'', [], [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Model to Selection';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.moveLayers(''model'', ''selection'', [], [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Convert type';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.convertModel([], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'New model';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.createModel([], [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Load model';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.loadModel([], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Import model from Matlab';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.menuModelsImport_Callback(Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Export model';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.menuModelsExport_Callback([], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Rename material';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.renameMaterial(Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Save model';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.saveModel([], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Interpolate material';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.interpolateImage(''model'', [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Smooth model';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.smoothImage(''model'', Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Get statistics';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.startController(''mibStatisticsController'', [], Batch);'; actionId = actionId + 1;
            
            secIndex = secIndex + 1;
            actionId = 1;
            obj.Sections(secIndex).Name = 'Menu -> Mask';
            obj.Sections(secIndex).Actions(actionId).Name = 'Mask to Model';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.moveLayers(''mask'', ''model'', [], [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Mask to Selection';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.moveLayers(''mask'', ''selection'', [], [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Clear mask';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.clearMask(Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Load mask';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.loadMask([], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Import mask';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.menuMaskImport_Callback([], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Export mask';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.menuMaskExport_Callback([], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Save mask';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.saveMask([], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Interpolate mask';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.interpolateImage(''mask'', [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Invert mask';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.menuMaskInvert_Callback(''mask'', Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Replace masked area in the image';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.menuMaskImageReplace_Callback(''mask'', Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Smooth mask';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.smoothImage(''mask'', Batch)'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Get statistics';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.startController(''mibStatisticsController'', -1, Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Fill mask';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.fillSelectionOrMask([], ''mask'', Batch);'; actionId = actionId + 1;
            
            
            secIndex = secIndex + 1;
            actionId = 1;
            obj.Sections(secIndex).Name = 'Menu -> Selection';
            obj.Sections(secIndex).Actions(actionId).Name = 'Selection to Model';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibModel.moveLayers(''selection'', ''model'', [], [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Selection to Mask';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibModel.moveLayers(''selection'', ''mask'', [], [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Interpolate selection';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.interpolateImage(''selection'', [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Replace selected area in the image';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.menuMaskImageReplace_Callback(''selection'', Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Smooth selection';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.smoothImage(''selection'', Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Invert selection';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.menuMaskInvert_Callback(''selection'', Batch);'; actionId = actionId + 1;
            
            secIndex = secIndex + 1;
            actionId = 1;
            obj.Sections(secIndex).Name = 'Menu -> Tools';
            obj.Sections(secIndex).Actions(actionId).Name = 'Semi-automatic segmentation --> Global thresholding';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.startController(''mibHistThresController'', [], Batch);'; actionId = actionId + 1;
            
            secIndex = secIndex + 1;
            actionId = 1;
            obj.Sections(secIndex).Name = 'Menu -> Plugins';
            obj.Sections(secIndex).Actions(actionId).Name = 'Convert image files';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.startController(''ImageConverterController'', [], Batch);'; actionId = actionId + 1;
            
            secIndex = secIndex + 1;
            actionId = 1;
            obj.Sections(secIndex).Name = 'Panel -> Directory contents';
            obj.Sections(secIndex).Actions(actionId).Name = 'Change container';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibBufferToggle_Callback([], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Duplicate dataset';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibBufferToggleContext_Callback(''duplicate'', [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Close dataset';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibBufferToggleContext_Callback(''close'', [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Close all datasets';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibBufferToggleContext_Callback(''closeAll'', [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Sync views';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibBufferToggleContext_Callback(''sync_xy'', [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Link views';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibBufferToggleContext_Callback(''link_views'', [], Batch);'; actionId = actionId + 1;
            
            secIndex = secIndex + 1;
            actionId = 1;
            obj.Sections(secIndex).Name = 'Panel -> Segmentation';
            obj.Sections(secIndex).Actions(actionId).Name = 'Modify parameters';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibSegmentationPanelCheckboxes(Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Add material';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibAddMaterialBtn_Callback(Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Rename material';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.renameMaterial(Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Remove material';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibRemoveMaterialBtn_Callback(Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = '3D ball';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibSegmentation3dBall([], [], [], [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Black and white thresholding';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibSegmentationBlackWhiteThreshold([], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Drag & Drop materials';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibGUI_WindowButtonUpDragAndDropFcn([], [], [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Segment-anything model';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibSegmentationSAM([], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Spot';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibSegmentationSpot([], [], [], Batch);'; actionId = actionId + 1;
            
            secIndex = secIndex + 1;
            actionId = 1;
            obj.Sections(secIndex).Name = 'Panel -> Image view';
            obj.Sections(secIndex).Actions(actionId).Name = 'Change slice number';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibChangeLayerEdit_Callback([], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Change frame/time number';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibChangeTimeEdit_Callback([], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Change magnification';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibZoomEdit_Callback(Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Recenter the view';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibPixelInfo_Callback([], Batch);'; actionId = actionId + 1;
            
            secIndex = secIndex + 1;
            actionId = 1;
            obj.Sections(secIndex).Name = 'Panel -> View settings';
            obj.Sections(secIndex).Actions(actionId).Name = 'Modify parameters';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibViewSettingsPanelCheckboxes(Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Display';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.startController(''mibImageAdjController'', [], Batch);'; actionId = actionId + 1;
            
            secIndex = secIndex + 1;
            actionId = 1;
            obj.Sections(secIndex).Name = 'Panel -> Selection';
            obj.Sections(secIndex).Actions(actionId).Name = 'Modify parameters';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibSelectionPanelCheckboxes(Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Erode';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.erodeImage(Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Dilate';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.dilateImage(Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Clear selection';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.clearSelection([], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Fill selection';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibModel.fillSelectionOrMask([], ''selection'', Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Selection to Model';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibModel.moveLayers(''selection'', ''model'', [], [], Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'Selection to Mask';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.mibController.mibModel.moveLayers(''selection'', ''mask'', [], [], Batch);'; actionId = actionId + 1;
            
            secIndex = secIndex + 1;
            obj.Sections(secIndex).Name = 'Panel -> Image filters';
            if verLessThan('Matlab', '9.8')
                FiltersList = {'Average', 'Disk', 'DistanceMap', 'Entropy', 'Frangi', 'Gaussian', 'Gradient', 'LoG', 'MathOps', 'Motion','Prewitt','Range', 'SaltAndPepper','Sobel','Std',...
                    'AnisotropicDiffusion', 'Bilateral', 'DNNdenoise', 'Median', 'NonLocalMeans', 'Wiener',...
                    'AddNoise', 'FastLocalLaplacian', 'FlatfieldCorrection', 'LocalBrighten', 'LocalContrast', 'ReduceHaze', 'UnsharpMask',...
                    'Edge', 'SlicClustering', 'WatershedClustering'};
            else
                FiltersList = {'Average', 'Disk', 'DistanceMap', 'Entropy', 'Frangi', 'Gaussian', 'Gradient', 'LoG', 'MathOps', 'Mode', 'Motion','Prewitt','Range', 'SaltAndPepper','Sobel','Std',...
                    'AnisotropicDiffusion', 'Bilateral', 'DNNdenoise', 'Median', 'NonLocalMeans', 'Wiener',...
                    'AddNoise', 'FastLocalLaplacian', 'FlatfieldCorrection', 'LocalBrighten', 'LocalContrast', 'ReduceHaze', 'UnsharpMask',...
                    'Edge', 'SlicClustering', 'WatershedClustering'};
            end
            % add BMxD filter if available
            if ~isempty(obj.mibModel.preferences.ExternalDirs.bm3dInstallationPath)
                if exist(fullfile(obj.mibModel.preferences.ExternalDirs.bm3dInstallationPath, 'BM3D.m'), 'file') == 2
                    FiltersList{end+1} = 'BMxD';
                end
            end
            
            FiltersList = sort(FiltersList);
            for actionId = 1:numel(FiltersList)
                obj.Sections(secIndex).Actions(actionId).Name = FiltersList{actionId};
                obj.Sections(secIndex).Actions(actionId).Command = sprintf('obj.mibController.startController(''mibImageFiltersController'', ''%s'', Batch);', FiltersList{actionId});
            end
            
            secIndex = secIndex + 1;
            actionId = 1;
            obj.Sections(secIndex).Name = 'Service steps';
            obj.Sections(secIndex).Actions(actionId).Name = 'STOP EXECUTION';
            obj.Sections(secIndex).Actions(actionId).Command = []; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'DIRECTORY LOOP START';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.DirectoryLoopAction_Callback(Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'DIRECTORY LOOP STOP';
            obj.Sections(secIndex).Actions(actionId).Command = []; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'FILE LOOP START';
            obj.Sections(secIndex).Actions(actionId).Command = 'obj.FileLoopAction_Callback(Batch);'; actionId = actionId + 1;
            obj.Sections(secIndex).Actions(actionId).Name = 'FILE LOOP STOP';
            obj.Sections(secIndex).Actions(actionId).Command = []; actionId = actionId + 1;
            
            % init default selections
            obj.selectedSection = 1;
            obj.selectedAction = 1;
            obj.protocolListIndex = 0;
            obj.selectedActionTableIndex = 0;
            obj.ProtocolBackupsCurrNumber = 0;
            obj.ProtocolBackupsMaxNumber = 10;
            
            guiName = 'mibBatchGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % move the window to the left hand side of the main window
            obj.View.gui = moveWindowOutside(obj.View.gui, 'left');
            
            % resize all elements of the GUI
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            % you may need to replace "obj.View.handles.text1" with tag of any text field of your own GUI
            global Font;
            if ~isempty(Font)
                if obj.View.handles.sectionNameText.FontSize ~= Font.FontSize ...
                        || ~strcmp(obj.View.handles.sectionNameText.FontName, Font.FontName)
                    mibUpdateFontSize(obj.View.gui, Font);
                end
            end
            
            % update GUI widgets
            obj.View.handles.sectionPopup.String = {obj.Sections.Name}';
            
            % find java object for the segmentation table
            obj.jSelectedActionTableScroll = findjobj(obj.View.handles.selectedActionTable);
            obj.jSelectedActionTable = obj.jSelectedActionTableScroll.getViewport.getComponent(0);
            obj.jSelectedActionTable.setAutoResizeMode(obj.jSelectedActionTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
            obj.View.handles.selectedActionTable.ColumnWidth = {100, 100};
            %obj.jSelectedActionTable.setAutoResizeMode(obj.jSelectedActionTable.AUTO_RESIZE_ALL_COLUMNS);
            
            % add images to buttons
            obj.View.handles.runStepBtn.CData = obj.mibModel.sessionSettings.guiImages.step;
            obj.View.handles.runStepAdvanceBtn.CData = obj.mibModel.sessionSettings.guiImages.step_and_advance;
            
            obj.updateWidgets();
            obj.View.gui.Visible = 'on';    % turn on the window
            
            % add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen for update of widgets
            obj.listener{2} = addlistener(obj.mibModel, 'syncBatch', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen for return of the batch structure
            obj.listener{3} = addlistener(obj.mibModel, 'stopProtocol', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen stop protocol event
            
            % option 2: in some situations
            % obj.listener{1} = addlistener(obj.mibModel, 'Id', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
            % obj.listener{2} = addlistener(obj.mibModel, 'newDatasetSwitch', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
        end
        
        function closeWindow(obj)
            % closing mibBatchController window
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
        
        function helpBtn_Callback(obj)
            % function helpBtn_Callback(obj)
            % show help page
            global mibPath;
            web(fullfile(mibPath, 'techdoc', 'html', 'ug_gui_menu_file_batch.html'), '-helpbrowser');
        end
        
        % ------------------------------------------------------------------
        % % Additional functions and callbacks
        function selectAction_Callback(obj, hObject)
            % function selectAction_Callback(obj, hObject)
            % callback for change of the selected actions in popups:
            % sectionPopup and actionPopup defined by hObject
            
            % disable "add to protocol"
            autoAddSwitch = obj.View.handles.autoAddToProtocol.Value;
            obj.View.handles.autoAddToProtocol.Value = false;
            
            switch hObject.Tag
                case 'sectionPopup'
                    obj.selectedSection = hObject.Value;
                    obj.selectedAction = 1;
                case 'actionPopup'
                    if strcmp(hObject.String{hObject.Value}, 'Image filters')
                        obj.selectedSection = find(ismember(obj.View.handles.sectionPopup.String, 'Panel -> Image filters'));   
                        obj.View.handles.sectionPopup.Value = obj.selectedSection;
                        obj.selectedAction = 1;
                    else
                        obj.selectedAction = hObject.Value;
                    end
            end
            
            if isempty(obj.Sections(obj.selectedSection).Actions(obj.selectedAction).Command)
                switch obj.Sections(obj.selectedSection).Actions(obj.selectedAction).Name
                    case 'STOP EXECUTION'
                        Batch.Description = 'Wait for a user';
                    case 'DIRECTORY LOOP STOP'
                        Batch.Description = 'Place this step at the end of the directory loop';
                    case 'FILE LOOP STOP'
                        Batch.Description = 'Place this step at the end of the file loop';
                end
                Batch.mibBatchSectionName = 'Service steps';
                Batch.mibBatchActionName = obj.Sections(obj.selectedSection).Actions(obj.selectedAction).Name;
                obj.updateSelectedActionTable(Batch);
            else
                Batch = NaN; %#ok<NASGU>    % when Parameter is NaN calling of the command returns structure with possible options
                eval(obj.Sections(obj.selectedSection).Actions(obj.selectedAction).Command);
            end
            obj.selectedActionTableIndex = 1;
            obj.updateWidgets();
            obj.displaySelectedActionTableItems();
            obj.View.handles.autoAddToProtocol.Value = autoAddSwitch;   % restore "add to protocol" status
        end
        
        function updateSelectedActionTable(obj, BatchOpt)
            % update selected action table using the BatchOpt structure
            % Parameters:
            % BatchOpt: a structure with parameters
            % .Checkbox - logical, true/false, will be displayed as a checkbox
            % .Popupmenu - a cell array with 2 items for popupmenus.
            % .Popupmenu(1) - {'Container 1'}, selected item
            % .Popupmenu(2) - [{Container 1'},{Container 2'},{Container 3'}]
            % .Editbox - a string for edit box
            
            % update sections list
            obj.selectedSection = find(ismember({obj.Sections.Name}, BatchOpt.mibBatchSectionName) == 1);
            % update actions list
            obj.selectedAction = find(ismember({obj.Sections(obj.selectedSection).Actions.Name}, BatchOpt.mibBatchActionName));
            obj.updateWidgets();
            
            obj.CurrentBatch = BatchOpt;
            fieldNames = fieldnames(BatchOpt);
            
            % remove mibBatchSectionName and mibBatchActionName
            fieldNames(ismember(fieldNames, {'mibBatchSectionName', 'mibBatchActionName', 'mibBatchTooltip'})) = [];
            
            %obj.View.handles.selectedActionTable.RowName = fieldNames;  % row names are too wide, do not use them
            
            tData = cell([numel(fieldNames), 2]);
            %tData(:,1) = fieldNames;
            tData(:,1) = cellfun(@(x) sprintf('<html><b>%s</b></html>', x), fieldNames, 'UniformOutput', false);
            
            for rowId = 1:numel(fieldNames)
                if iscell(BatchOpt.(fieldNames{rowId}))
                    tData{rowId,2} = BatchOpt.(fieldNames{rowId}){1};
                elseif islogical(BatchOpt.(fieldNames{rowId}))
                    tData{rowId,2} = BatchOpt.(fieldNames{rowId});
                else
                    tData{rowId,2} = num2str(BatchOpt.(fieldNames{rowId}));
                end
            end
            obj.View.handles.selectedActionTable.Data = tData;
        end
        
        function displaySelectedActionTableItems(obj)
            % display current options for the highlighted row in the selectedActionTable
            
            if obj.selectedActionTableIndex == 0; return; end
            if isempty(obj.CurrentBatch); return; end
            
            obj.View.handles.selectedActionTableCellCheck.Visible = 'off';
            obj.View.handles.selectedActionTableCellPopup.Visible = 'off';
            obj.View.handles.selectedActionTableCellEdit.Visible = 'off';
            obj.View.handles.selectedActionTableCellNumericEdit.Visible = 'off';
            
            fieldNames = fieldnames(obj.CurrentBatch);
            % remove mibBatchSectionName and mibBatchActionName
            fieldNames(ismember(fieldNames, {'mibBatchSectionName', 'mibBatchActionName', 'mibBatchTooltip'})) = [];
            
            if isempty(fieldNames)
                obj.View.handles.selectedActionTableCellText.String = '';
                return;
            end
            
            obj.View.handles.selectedActionTableCellText.String = fieldNames{obj.selectedActionTableIndex};
            
            if isnumeric(obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}))
                obj.View.handles.selectedActionTableCellNumericEdit.Visible = 'on';
                obj.View.handles.selectedActionTableCellNumericEdit.String = num2str(obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}));
            else
                switch class(obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}))
                    case 'cell'
                        if numel(obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex})) == 1
                            warndlg(sprintf('!!! Warning !!!\n\nThe possible configurations for this widgets were not provided!'));
                            obj.View.handles.selectedActionTableCellPopup.String = obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}){1};
                            obj.View.handles.selectedActionTableCellPopup.Value = 1;
                        else
                            if ~isnumeric(obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}){1})  % dropdown
                                obj.View.handles.selectedActionTableCellPopup.Visible = 'on';
                                obj.View.handles.selectedActionTableCellPopup.String = obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}){2};
                                obj.View.handles.selectedActionTableCellPopup.Value = ...
                                    find(ismember(obj.View.handles.selectedActionTableCellPopup.String, obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex})(1)));
                            else    % numeric edit box
                                obj.View.handles.selectedActionTableCellEdit.Visible = 'on';
                                obj.View.handles.selectedActionTableCellEdit.String = num2str(obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}){1});
                            end
                        end
                    case 'logical'
                        obj.View.handles.selectedActionTableCellCheck.Visible = 'on';
                        obj.View.handles.selectedActionTableCellCheck.Value = obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex});
                    case 'char'
                        obj.View.handles.selectedActionTableCellEdit.Visible = 'on';
                        if numel(strfind(obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}), sprintf('\n'))) > 0
                            obj.View.handles.selectedActionTableCellEdit.Max = 3;
                        else
                            obj.View.handles.selectedActionTableCellEdit.Max = 1;
                        end
                        obj.View.handles.selectedActionTableCellEdit.String = obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex});
                end
            end
            
            % add tooltips and comments
            showTooltip = false;
            if isfield(obj.CurrentBatch, 'mibBatchTooltip')
                if isfield(obj.CurrentBatch.mibBatchTooltip, fieldNames{obj.selectedActionTableIndex})
                    showTooltip = true;
                end
            end
            if showTooltip
                tooltipStr = obj.CurrentBatch.mibBatchTooltip.(fieldNames{obj.selectedActionTableIndex});
                obj.View.handles.selectedActionTableCellEdit.TooltipString = tooltipStr;
                obj.View.handles.selectedActionTableCellCheck.TooltipString = tooltipStr;
                obj.View.handles.selectedActionTableCellPopup.TooltipString = tooltipStr;
                obj.View.handles.selectedActionTableCellNumericEdit.TooltipString = tooltipStr;
                obj.View.handles.selectedActionTableCellText.TooltipString = tooltipStr;
                obj.View.handles.TooltipText.String = tooltipStr;
            else
                obj.View.handles.selectedActionTableCellText.TooltipString = fieldNames{obj.selectedActionTableIndex};
                obj.View.handles.TooltipText.String = 'Provide the value';
            end
        end
        
        function selectedActionTableItem_Update(obj, hObject)
            % update selected action in selectedActionTable
            if obj.selectedActionTableIndex == 0; return; end
            fieldNames = fieldnames(obj.CurrentBatch);
            
            % remove mibBatchSectionName and mibBatchActionName
            fieldNames(ismember(fieldNames, {'mibBatchSectionName', 'mibBatchActionName', 'mibBatchTooltip'})) = [];
            currIndex = obj.selectedActionTableIndex; % store the index
            
            switch hObject.Tag
                case 'selectedActionTableCellPopup'    % for popup menus
                    if numel(obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex})) > 1
                        obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex})(1) = ...
                            obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}){2}(hObject.Value);
                        obj.View.handles.selectedActionTable.Data{obj.selectedActionTableIndex,2} = obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}){1};
                    end
                case 'selectedActionTableCellCheck'     % for checkboxes
                    obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}) = logical(hObject.Value);
                    obj.View.handles.selectedActionTable.Data{obj.selectedActionTableIndex,2} = logical(hObject.Value);
                case 'selectedActionTableCellEdit'      % for text edits
                    if iscell(obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}))      % numeric edit box
                        values = str2double(hObject.String);
                        if numel(obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex})) > 1     % rounding of numbers
                            Limits = obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}){2};
                            if values < Limits(1) || values > Limits(2)
                                errordlg(sprintf('!!! Error!!!\n\nThe value should be between %f - %f!', Limits(1), Limits(2)));
                                hObject.String = num2str(obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}){1});
                                return;
                            end
                        end
                        if numel(obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex})) > 2     % rounding of numbers
                            RoundFractionalValues = obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}){3};
                        else
                            RoundFractionalValues = 'on';
                        end
                        if strcmp(RoundFractionalValues, 'on'); values = round(values); end
                        
                        obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}){1} = values; %#ok<ST2NM>
                        obj.View.handles.selectedActionTable.Data{obj.selectedActionTableIndex,2} = obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}){1};
                    else    % normal text edit box
                        obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}) = hObject.String;
                        obj.View.handles.selectedActionTable.Data{obj.selectedActionTableIndex,2} = hObject.String;
                    end
                case 'selectedActionTableCellNumericEdit'   % for numeric edits
                    newValue =  str2num(hObject.String);      %#ok<ST2NM>
                    if ismember(fieldNames{obj.selectedActionTableIndex}, {'x', 'y', 'z', 't'}) && numel(newValue) == 1 && newValue ~= 0
                        newValue = [newValue newValue];
                    end
                    obj.CurrentBatch.(fieldNames{obj.selectedActionTableIndex}) = newValue;
                    obj.View.handles.selectedActionTable.Data{obj.selectedActionTableIndex,2} = num2str(newValue);
            end
            obj.selectedActionTableIndex = currIndex;
        end
        
        function selectedActionTable_ContextCallback(obj, parameter)
            % function selectedActionTable_ContextCallback(obj, parameter)
            % callback for context menu over selectedActionTable
            global mibPath;
            if obj.selectedActionTableIndex == 0; return; end
            if isempty(obj.CurrentBatch); return; end
            
            switch parameter
                case 'add'  % add parameter
                    prompts = {'Parameter type'; 'Parameter name'; 'Custom parameter name';'Parameter value'};
                    defAns = {{'numeric', 'logical', 1}; {'z', 'x', 'y', 't', 'c', 'id', 'custom name', 1}; ''; '1'};
                    dlgTitle = 'Please specify parameter to add';
                    options.WindowStyle = 'normal';
                    options.PromptLines = [1, 1, 1, 1];
                    options.Title = 'Add parameter';
                    options.TitleLines = 1;
                    options.WindowWidth = 1;
                    options.Focus = 3;
                    [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                    if isempty(answer); return; end

                    % select existing of new parameter name
                    if ~isempty(answer{3})
                        newParName = answer{3};
                    else
                        newParName = answer{2};
                    end

                    switch answer{1}
                        case 'numeric'
                            newValue =  str2num(answer{4});      %#ok<ST2NM>
                            if ismember(newParName, {'x', 'y', 'z', 't', 'c'}) && numel(newValue) == 1
                                newValue = [newValue newValue];
                            end
                            obj.CurrentBatch.(newParName) = newValue;
                        case 'logical'
                            obj.CurrentBatch.(newParName) = logical(str2num(answer{4}));
                    end
                    obj.updateSelectedActionTable(obj.CurrentBatch);
                case 'delete'   % delete parameter
                    fieldNames = fieldnames(obj.CurrentBatch);
                    % remove mibBatchSectionName and mibBatchActionName
                    fieldNames(ismember(fieldNames, {'mibBatchSectionName', 'mibBatchActionName', 'mibBatchTooltip'})) = [];
                    obj.CurrentBatch = rmfield(obj.CurrentBatch, fieldNames{obj.selectedActionTableIndex});
                    obj.selectedActionTableIndex = obj.selectedActionTableIndex - 1;
                    obj.updateSelectedActionTable(obj.CurrentBatch);
                case 'Add directories'   % add file or directory to the list
                    switch obj.CurrentBatch.mibBatchActionName
                        case 'DIRECTORY LOOP START'
                            selpath = uigetfile_n_dir(fileparts(obj.CurrentBatch.DirectoriesList{1}), 'Select directories');
                            if isempty(selpath); return; end
                            
                            % look for duplicates
                            duplicateIds = ismember(lower(selpath), lower(obj.CurrentBatch.DirectoriesList{2}));
                            selpath(duplicateIds) = []; % remove duplicates
                            obj.CurrentBatch.DirectoriesList{2} = [obj.CurrentBatch.DirectoriesList{2}; selpath'];     % add to the list
                            obj.CurrentBatch.DirectoriesList(1) = obj.CurrentBatch.DirectoriesList{2}(1);      % set as selected option
                            obj.updateSelectedActionTable(obj.CurrentBatch);
                            obj.displaySelectedActionTableItems();
                            obj.selectedActionTableIndex = 1;   % for some strange reason, selectedActionTableIndex gets reset to 0...
                        case {'FILE LOOP START', 'Directory operations', 'File operations'}
                            warndlg(sprintf('!!! Warning !!!\nOnly Modify directory is available for this action'), 'Not available');
                            return;
                        otherwise
                            return;
                    end
                case 'Modify directory'
                    switch obj.CurrentBatch.mibBatchActionName
                        case 'DIRECTORY LOOP START'
                            selpath = uigetdir(obj.CurrentBatch.DirectoriesList{1}, 'Update directory');
                            if selpath == 0; return; end
                            if ismember({lower(selpath)}, lower(obj.CurrentBatch.DirectoriesList{2}))   % check whether it is already exist
                                warndlg(sprintf('!!! Warning !!!\n\nDirectory\n%s\nis already in the list', selpath), 'Already present');
                                return;
                            end
                            obj.CurrentBatch.DirectoriesList{2}(ismember(obj.CurrentBatch.DirectoriesList{2}, obj.CurrentBatch.DirectoriesList{1})) = {selpath};
                            obj.CurrentBatch.DirectoriesList{1} = selpath;      % set as selected option
                            obj.updateSelectedActionTable(obj.CurrentBatch);
                            obj.displaySelectedActionTableItems();
                        case {'FILE LOOP START', 'Load and combine images'}
                            if strcmp(obj.CurrentBatch.DirectoryName{1}, 'Current MIB path')
                                warndlg(sprintf('This directory parameter:\n"%s"\ncan not be modified!', obj.CurrentBatch.DirectoryName{1}));
                                return;
                            end
                            if strcmp(obj.CurrentBatch.DirectoryName{1}, 'Current MIB path') || strcmp(obj.CurrentBatch.DirectoryName{1}, 'Inherit from Directory loop')
                                warndlg(sprintf('The option %s can not be modified!\nPlease select a directory first and after that modify it...', obj.CurrentBatch.DirectoryName{1}));
                                return;
                            end
                            selpath = uigetdir(obj.CurrentBatch.DirectoryName{1}, 'Update directory');
                            if selpath == 0; return; end
                            obj.CurrentBatch.DirectoryName{2}(3) = {selpath};
                            obj.CurrentBatch.DirectoryName{1} = selpath;      % set as selected option
                            obj.updateSelectedActionTable(obj.CurrentBatch);
                            obj.displaySelectedActionTableItems();
                        case 'Directory operations'
                            if ~isfolder(obj.CurrentBatch.DirectoryName)
                                selpath = uigetdir(obj.mibModel.myPath, 'Update directory');
                            else
                                selpath = uigetdir(obj.CurrentBatch.DirectoryName, 'Update directory');
                            end
                            if selpath == 0; return; end
                            obj.CurrentBatch.DirectoryName = selpath;
                            obj.CurrentBatch.Mode(1) = obj.CurrentBatch.Mode{2}(ismember(obj.CurrentBatch.Mode{2}, 'Absolute'));
                            obj.updateSelectedActionTable(obj.CurrentBatch);
                            obj.displaySelectedActionTableItems();
                        case 'File operations'
                            if obj.selectedActionTableIndex == 3
                                modeField = 'CurrentDirectoryMode';
                                curDirField = 'CurrentDirectory';
                            elseif obj.selectedActionTableIndex == 5
                                modeField = 'TargetDirectoryMode';
                                curDirField = 'TargetDirectory';
                            else
                                return;
                            end
                            if ~isfolder(obj.CurrentBatch.(curDirField))
                                selpath = uigetdir(obj.mibModel.myPath, 'Update directory');
                            else
                                selpath = uigetdir(obj.CurrentBatch.(curDirField), 'Update directory');
                            end
                            if selpath == 0; return; end
                            
                            obj.CurrentBatch.(curDirField) = selpath;
                            obj.CurrentBatch.(modeField)(1) = obj.CurrentBatch.(modeField){2}(ismember(obj.CurrentBatch.(modeField){2}, 'Absolute'));
                            obj.updateSelectedActionTable(obj.CurrentBatch);
                            obj.displaySelectedActionTableItems();
                        otherwise
                            fieldNames = fieldnames(obj.CurrentBatch);
                            curDirField = fieldNames{obj.selectedActionTableIndex};
                            switch class(obj.CurrentBatch.(curDirField))
                                case 'cell'
                                    if strcmp(obj.CurrentBatch.(curDirField){1}, 'Inherit from dataset filename'); return; end
                                    selpath = uigetdir(obj.CurrentBatch.(curDirField){1}, 'Update directory');
                                    obj.CurrentBatch.(curDirField){2}(ismember(obj.CurrentBatch.(curDirField){2}, obj.CurrentBatch.(curDirField){1})) = {selpath};
                                    obj.CurrentBatch.(curDirField)(1) = {selpath};
                                case 'char'
                                    if ~isfolder(obj.CurrentBatch.(curDirField))
                                        selpath = uigetdir(obj.mibModel.myPath, 'Update directory');
                                    else
                                        selpath = uigetdir(obj.CurrentBatch.(curDirField), 'Update directory');
                                    end
                                    if selpath == 0; return; end
                                    obj.CurrentBatch.(curDirField) = selpath;
                            end
                            obj.updateSelectedActionTable(obj.CurrentBatch);
                            obj.displaySelectedActionTableItems();
                            return;
                    end
                case 'Remove directories'    % remove selected file or directory from the list
                    switch obj.CurrentBatch.mibBatchActionName
                        case 'DIRECTORY LOOP START'
                            if numel(obj.CurrentBatch.DirectoriesList{2}) == 1
                                warndlg(sprintf('!!! Warning !!!\n\nThe last directory can not be removed!'));
                                return;
                            end
                            
                            prompts = obj.CurrentBatch.DirectoriesList{2};
                            defAns = repmat({false}, [numel(obj.CurrentBatch.DirectoriesList{2}) 1]);
                            dlgTitle = 'Remove directories';
                            options.Title = 'Check directories to be removed from the list';
                            options.WindowWidth = 1.5;
                            answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
                            if isempty(answer); return; end
                            
                            obj.CurrentBatch.DirectoriesList{2}(cell2mat(answer)==1) = [];
                            obj.CurrentBatch.DirectoriesList(1) = obj.CurrentBatch.DirectoriesList{2}(1);
                            obj.updateSelectedActionTable(obj.CurrentBatch);
                            obj.displaySelectedActionTableItems();
                        case {'FILE LOOP START', 'Directory operations', 'File operations'}
                            warndlg(sprintf('!!! Warning !!!\nOnly Modify directory is available for this action'), 'Not available');
                            return;
                        otherwise
                            return;
                    end
                case 'Set second column width'
                    prompts = {'New width of the second column'};
                    defAns = {num2str(obj.View.handles.selectedActionTable.ColumnWidth{2})};
                    dlgTitle = 'Set column width';
                    [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle);
                    if isempty(answer); return; end
                    obj.View.handles.selectedActionTable.ColumnWidth = {1, str2double(answer{1})};
            end
        end
        
        function deleteProtocol(obj)
            % function deleteProtocol(obj)
            % delete current protocol
            obj.BackupProtocol();   % store the current protocol
            
            obj.Protocol = [];
            obj.protocolListIndex = 0;
            obj.updateProtocolList();
            obj.protocolList_SelectionCallback();
        end
        
        function saveProtocol(obj)
            % function saveProtocol(obj)
            % save protocol to a file
            
            if isempty(obj.Protocol); return; end
            
            fn_out = obj.mibModel.I{obj.mibModel.Id}.meta('Filename');
            dotIndex = strfind(fn_out,'.');
            if ~isempty(dotIndex); fn_out = fn_out(1:dotIndex-1); end
            if isempty(strfind(fn_out,'/')) && isempty(strfind(fn_out,'\')) %#ok<STREMP>
                fn_out = fullfile(obj.mibModel.myPath, fn_out);
            end
            if isempty(fn_out); fn_out = obj.mibModel.myPath; end
            
            Filters = {'*.mibProtocol',  'Matlab format (*.mibProtocol)';...
                '*.xls',   'Excel format (*.xls)'; };
            
            [filename, path, FilterIndex] = uiputfile(Filters, 'Save protocol...', fn_out); %...
            if isequal(filename,0); return; end % check for cancel
            fn_out = fullfile(path, filename);
            
            switch Filters{FilterIndex,2}
                case 'Matlab format (*.mibProtocol)'
                    Protocol = obj.Protocol; %#ok<PROP>
                    save(fn_out, 'Protocol', '-mat', '-v7');
                case 'Excel format (*.xls)'
                    warning('off', 'MATLAB:xlswrite:AddSheet');
                    wb = waitbar(0, sprintf('Saving to Excel\nPlease wait...'));
                    % Sheet 1
                    s = {sprintf('MIB protocol file: %s', fn_out)};
                    s(3,1) = {'Step'}; s(3,2) = {'Section name'}; s(3,3) = {'Action name'}; s(3,4) = {'Command'};
                    s(3,5) = {'Parameter name'}; s(3,6) = {'Parameter value'};
                    lineIndex = 4;
                    for protId = 1:numel(obj.Protocol)
                        s(lineIndex,1) = {sprintf('%d', protId)};
                        s(lineIndex,2) = {obj.Protocol(protId).mibBatchSectionName};
                        s(lineIndex,3) = {obj.Protocol(protId).mibBatchActionName};
                        s(lineIndex,4) = {obj.Protocol(protId).Command};
                        fieldNames = fieldnames(obj.Protocol(protId).Batch);
                        for i=1:numel(fieldNames)
                            s(lineIndex,5) = fieldNames(i);
                            if isstruct(obj.Protocol(protId).Batch.(fieldNames{i}))
                                continue;
                            elseif iscell(obj.Protocol(protId).Batch.(fieldNames{i}))
                                s(lineIndex,6) = {obj.Protocol(protId).Batch.(fieldNames{i}){1}};
                            else
                                s(lineIndex,6) = {obj.Protocol(protId).Batch.(fieldNames{i})};
                            end
                            lineIndex = lineIndex + 1;
                        end
                        if isempty(fieldNames); lineIndex = lineIndex + 1; end  % to fix position for the STOP EXECUTION
                    end
                    waitbar(.2, wb);
                    warning('off','MATLAB:COM:invalidargumenttype');    % switch off warnings
                    xlswrite2(fn_out, s, 'Protocol');
                    waitbar(1, wb);
                    delete(wb);
            end
            fprintf('mib: protocol was saved to "%s"\n', fn_out);
        end
        
        function loadProtocol(obj)
            % function loadProtocol(obj)
            % load protocol from a file
            
            if isempty(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'))
                path = obj.mibView.handles.mibPathEdit.String;
            else
                path = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
                if isempty(path); path = obj.mibModel.myPath; end
            end
            
            [filename, path] = mib_uigetfile(...
                {'*.mibProtocol',  'Matlab format (*.mibProtocol)'; ...
                '*.*',  'All Files (*.*)'}, ...
                'Load a protocol...', path);
            if isequal(filename,0); return; end % check for cancel
            res = load(fullfile(path, filename{1}), '-mat');
            obj.BackupProtocol();   % store the current protocol
            obj.Protocol = res.Protocol;
            obj.protocolListIndex = 1;
            obj.updateProtocolList();
            obj.protocolList_SelectionCallback();
        end
        
        function protocolActions_Callback(obj, options)
            % function protocolActions_Callback(obj, options)
            % options to modify protocol
            % options: a string with action to perform to the protocol
            % 'add' - add selected action to the protocol
            % 'duplicate' - duplicate selected action
            % 'insert' - insert selected action to the protocol
            % 'insertstop' - insert a stop action
            % 'update' - update selected action of the protocol
            % 'show' -  display settings for the selected action
            % 'delete' - delete selected action from the protocol
            
            switch options
                case {'add', 'insert', 'update', 'duplicate'}      % add, insert or update selected action to the protocol
                    if isempty(obj.CurrentBatch)
                        warndlg(sprintf('!!! Warning !!!\n\nPlease select an action to perform from the list of available actions and try again!'), 'The action was not selected!');
                        return;
                    end
                    obj.BackupProtocol();   % store the current protocol
                    switch options
                        case 'add'
                            obj.protocolListIndex = numel(obj.Protocol)+1;
                        case 'duplicate'
                            obj.protocolListIndex = max([1 obj.protocolListIndex]);
                            obj.Protocol(obj.protocolListIndex+1:numel(obj.Protocol)+1) = obj.Protocol(obj.protocolListIndex:numel(obj.Protocol));
                            obj.protocolListIndex = obj.protocolListIndex + 1;
                        case 'insert'
                            obj.protocolListIndex = max([1 obj.protocolListIndex]);
                            obj.Protocol(obj.protocolListIndex+1:numel(obj.Protocol)+1) = obj.Protocol(obj.protocolListIndex:numel(obj.Protocol));
                        case 'update'
                            if obj.protocolListIndex==0; obj.protocolListIndex=1; end
                    end
                    obj.Protocol(obj.protocolListIndex).mibBatchSectionName = obj.CurrentBatch.mibBatchSectionName;
                    obj.Protocol(obj.protocolListIndex).mibBatchActionName = obj.CurrentBatch.mibBatchActionName;
                    obj.Protocol(obj.protocolListIndex).Command = obj.Sections(obj.selectedSection).Actions(obj.selectedAction).Command;
                    obj.Protocol(obj.protocolListIndex).Batch = rmfield(obj.CurrentBatch, {'mibBatchSectionName','mibBatchActionName'});
                    obj.View.handles.protocolList.Value = obj.protocolListIndex;
                case 'insertstop'
                    obj.BackupProtocol();   % store the current protocol
                    obj.protocolListIndex = max([1 obj.protocolListIndex]);
                    obj.Protocol(obj.protocolListIndex+1:numel(obj.Protocol)+1) = obj.Protocol(obj.protocolListIndex:numel(obj.Protocol));
                    
                    obj.Protocol(obj.protocolListIndex).mibBatchSectionName = 'Service steps';
                    obj.Protocol(obj.protocolListIndex).mibBatchActionName = 'STOP EXECUTION';
                    obj.Protocol(obj.protocolListIndex).Command = [];
                    obj.Protocol(obj.protocolListIndex).Batch = struct();
                    obj.Protocol(obj.protocolListIndex).Batch.Description = 'Wait for a user';
                    obj.View.handles.protocolList.Value = obj.protocolListIndex;
                case 'show'
                    if obj.protocolListIndex == 0; return; end
                    obj.protocolList_SelectionCallback();
                case 'moveup'
                    if obj.protocolListIndex < 2; return; end
                    obj.BackupProtocol();   % store the current protocol
                    currAction = obj.Protocol(obj.protocolListIndex);
                    obj.Protocol(obj.protocolListIndex) = obj.Protocol(obj.protocolListIndex-1);
                    obj.Protocol(obj.protocolListIndex-1) = currAction;
                    obj.protocolListIndex = obj.protocolListIndex - 1;
                case 'movedown'
                    if obj.protocolListIndex == numel(obj.Protocol); return; end
                    obj.BackupProtocol();   % store the current protocol
                    currAction = obj.Protocol(obj.protocolListIndex);
                    obj.Protocol(obj.protocolListIndex) = obj.Protocol(obj.protocolListIndex+1);
                    obj.Protocol(obj.protocolListIndex+1) = currAction;
                    obj.protocolListIndex = obj.protocolListIndex + 1;
                case 'delete'
                    if obj.protocolListIndex == 0; return; end
                    obj.BackupProtocol();   % store the current protocol
                    obj.Protocol(obj.protocolListIndex) = [];
                    obj.protocolListIndex = obj.protocolListIndex - 1;
                    if numel(obj.Protocol)>0 && obj.protocolListIndex == 0
                        obj.protocolListIndex = 1;
                    end
                    if obj.protocolListIndex > 0; obj.View.handles.protocolList.Value = obj.protocolListIndex; end
            end
            obj.updateProtocolList();
            obj.protocolList_SelectionCallback();
        end
        
        function protocolList_SelectionCallback(obj)
            % function protocolList_SelectionCallback(obj)
            % callback for selection of a row in protocolList
            if obj.protocolListIndex == 0; return; end
            
            BatchOpt = obj.Protocol(obj.protocolListIndex).Batch;
            BatchOpt.mibBatchSectionName = obj.Protocol(obj.protocolListIndex).mibBatchSectionName;
            BatchOpt.mibBatchActionName = obj.Protocol(obj.protocolListIndex).mibBatchActionName;
            obj.updateSelectedActionTable(BatchOpt);
            
            obj.selectedActionTableIndex = 1;
            obj.displaySelectedActionTableItems();
        end
        
        function updateProtocolList(obj)
            % function updateProtocolList(obj)
            % update protocol list
            
            tData = cell([numel(obj.Protocol), 1]);
            for rowId = 1:numel(obj.Protocol)
                tData{rowId} = sprintf('%d. %s -> %s',rowId,obj.Protocol(rowId).mibBatchSectionName, obj.Protocol(rowId).mibBatchActionName);
            end
            obj.View.handles.protocolList.Value = 1;
            obj.View.handles.protocolList.String = tData;
            if obj.protocolListIndex > 0; obj.View.handles.protocolList.Value = obj.protocolListIndex; end
        end
        
        function BackupProtocol(obj)
            % function BackupProtocol(obj)
            % backup the current protocol
            %if isempty(obj.Protocol); return; end
            
            obj.ProtocolBackupsCurrNumber = obj.ProtocolBackupsCurrNumber + 1;
            obj.ProtocolBackups(obj.ProtocolBackupsCurrNumber:end) = [];
            if obj.ProtocolBackupsCurrNumber > obj.ProtocolBackupsMaxNumber     % limit of backup steps reached
                obj.ProtocolBackupsCurrNumber = obj.ProtocolBackupsCurrNumber - 1;
                obj.ProtocolBackups = obj.ProtocolBackups(2:obj.ProtocolBackupsCurrNumber);
            end
            obj.ProtocolBackups{obj.ProtocolBackupsCurrNumber} = obj.Protocol;
        end
        
        function BackupProtocolRestore(obj, mode)
            % function BackupProtocolRestore(obj, mode)
            % restore protocol from the backup
            % Parameters:
            % mode: a string
            %  'undo' - to make an undo
            %  'redo' - to make a redo
            
            if nargin < 2; mode = 'undo'; end
            switch mode
                case 'undo'
                    if obj.ProtocolBackupsCurrNumber == 0; return; end % first history entry is reached
                    currProtocol = obj.Protocol;
                    obj.Protocol = obj.ProtocolBackups{obj.ProtocolBackupsCurrNumber};
                    obj.ProtocolBackups{obj.ProtocolBackupsCurrNumber} = currProtocol;
                    obj.ProtocolBackupsCurrNumber = obj.ProtocolBackupsCurrNumber - 1;
                    obj.protocolListIndex = obj.protocolListIndex - 1;
                case 'redo'
                    if obj.ProtocolBackupsCurrNumber == obj.ProtocolBackupsMaxNumber || obj.ProtocolBackupsCurrNumber == numel(obj.ProtocolBackups)
                        return;
                    end % last history entry is reached
                    obj.ProtocolBackupsCurrNumber = min([obj.ProtocolBackupsCurrNumber + 1, numel(obj.ProtocolBackups)]);
                    currProtocol = obj.Protocol;
                    obj.Protocol = obj.ProtocolBackups{obj.ProtocolBackupsCurrNumber};
                    obj.ProtocolBackups{obj.ProtocolBackupsCurrNumber} = currProtocol;
                    obj.protocolListIndex = min([obj.protocolListIndex + 1, numel(obj.View.handles.protocolList.String)]);
            end
            obj.updateProtocolList();
            %obj.protocolList_SelectionCallback();
        end
        
        function runProtocolBtn_Callback(obj, parameter)
            % function runProtocolBtn_Callback(obj, parameter)
            % run the protocol
            %
            % Parameters:
            % parameter: a string with details
            %   'complete' - run all steps of the protocol
            %   'from' - run the protocol from the selected step
            %   'step' - run the selected step only
            %   'stepadvance' - run the selected step and advance to next
            obj.stopProtocolSwitch = false;
            
            if isempty(obj.Protocol); return; end
            autoAddSwitch = obj.View.handles.autoAddToProtocol.Value;
            obj.View.handles.autoAddToProtocol.Value = false;
            switch parameter
                case 'complete'
                    if strcmp(obj.View.handles.runProtocolBtn.String, 'Stop protocol')
                        %error('check here')
                        obj.stopProtocolSwitch = true;
                        %return;
                    end
                    startStep = 1;
                    finishStep = numel(obj.Protocol);
                    obj.View.handles.runProtocolBtn.String = 'Stop protocol';
                    obj.View.handles.runProtocolBtn.BackgroundColor = 'r';

                    % count user's points
                    obj.mibModel.preferences.Users.Tiers.numberOfBatchProcessings = obj.mibModel.preferences.Users.Tiers.numberOfBatchProcessings+1;
                    eventdata = ToggleEventData(3);    % scale scoring by factor 5
                    notify(obj.mibModel, 'updateUserScore', eventdata);
                    timerProtocolStart = tic;
                case 'from'
                    startStep = obj.protocolListIndex;
                    if strcmp(obj.Protocol(startStep).mibBatchActionName, 'STOP EXECUTION')
                        startStep = startStep + 1;
                    end
                    finishStep = numel(obj.Protocol);
                    obj.View.handles.runProtocolBtn.String = 'Stop protocol';
                    obj.View.handles.runProtocolBtn.BackgroundColor = 'r';
                case {'step', 'stepadvance'}
                    startStep = obj.protocolListIndex;
                    finishStep = obj.protocolListIndex;
                    if strcmp(parameter, 'stepadvance') && ...
                            strcmp(obj.Protocol(startStep).mibBatchSectionName, 'Service steps') && ...
                            strcmp(obj.Protocol(startStep).mibBatchActionName, 'STOP EXECUTION')
                        obj.protocolListIndex = min([obj.protocolListIndex + 1, numel(obj.Protocol)]);
                        obj.updateProtocolList();
                        obj.protocolList_SelectionCallback();
                        obj.View.handles.autoAddToProtocol.Value = autoAddSwitch;
                        return;
                    end
            end
            
            stepId = startStep;
            while stepId <= finishStep
                if strcmp(obj.Protocol(stepId).mibBatchActionName, 'DIRECTORY LOOP START')    % make directory loop
                    startStep2 = stepId + 1;
                    finishStep2 = find(ismember({obj.Protocol(:).mibBatchActionName}, 'DIRECTORY LOOP STOP'));
                    if isempty(finishStep2); finishStep2 = finishStep; end
                    
                    % for compatibility add check for DirLoopWaitbar
                    if ~isfield(obj.Protocol(stepId).Batch, 'DirLoopWaitbar')
                        obj.Protocol(stepId).Batch.DirLoopWaitbar = false;
                        obj.Protocol(stepId).Batch.mibBatchTooltip.DirLoopWaitbar = 'when checked the waitbar for the dirloop is displayed';
                    end

                    % show dirloop waitbar
                    showDirLoopWaitbar = false;     % do not show the dir-loop waitbar
                    if obj.Protocol(stepId).Batch.DirLoopWaitbar 
                        dirLoopWaitbar = waitbar(0, 'Please wait...', 'Name', 'Processing directories'); 
                        set(findall(dirLoopWaitbar, 'type', 'text'), 'Interpreter', 'none'); 
                        showDirLoopWaitbar = true;  % show dir-loop waitbar, disable other waitbars
                    end
                    
                    for dirId = 1:numel(obj.Protocol(stepId).Batch.DirectoriesList{2})
                        if obj.Protocol(stepId).Batch.DirLoopWaitbar
                            [~, currDirWaitbarText] = fileparts(obj.Protocol(stepId).Batch.DirectoriesList{2}{dirId});
                            waitbar(dirId/numel(obj.Protocol(stepId).Batch.DirectoriesList{2}), dirLoopWaitbar, sprintf('Processing: %s\nPlease wait...', currDirWaitbarText)); 
                        end

                        stepId2 = startStep2;
                        while stepId2 <= finishStep2
                            %for stepId2 = startStep2:finishStep2
                            switch obj.Protocol(stepId2).mibBatchActionName
                                case 'FILE LOOP START'
                                    if strcmp(obj.Protocol(stepId2).Batch.DirectoryName{1}, 'Inherit from Directory loop')  % check whether the dir name provided from Dir-loop
                                        DirectoryName = obj.Protocol(stepId).Batch.DirectoriesList{2}{dirId};   % take directory name from dir-loop
                                    elseif strcmp(obj.Protocol(stepId2).Batch.DirectoryName{1}, 'Current MIB path')
                                        DirectoryName = obj.mibModel.myPath;
                                    else
                                        DirectoryName = obj.Protocol(stepId2).Batch.DirectoryName{1};           % take directory name from File loop
                                    end
                                    
                                    fileLoopStart = stepId2 + 1;
                                    fileLoopFinish = find(ismember({obj.Protocol(startStep2:finishStep2).mibBatchActionName}, 'FILE LOOP STOP')) + startStep2 - 1;
                                    if isempty(fileLoopFinish); fileLoopFinish = finishStep2; end
                                    
                                    FileloopSettings.DirectoryName = DirectoryName;
                                    FileloopSettings.FilenameFilter = obj.Protocol(stepId2).Batch.FilenameFilter;
                                    FileloopSettings.FileLoopWaitbar = obj.Protocol(stepId2).Batch.FileLoopWaitbar;
                                    status = obj.doFileLoop(fileLoopStart, fileLoopFinish, FileloopSettings);
                                    if status == 0
                                        notify(obj.mibModel, 'stopProtocol');
                                        obj.View.handles.autoAddToProtocol.Value = autoAddSwitch;
                                        if obj.Protocol(stepId).Batch.DirLoopWaitbar; delete(dirLoopWaitbar); end
                                        return;
                                    end
                                    stepId2 = fileLoopFinish + 1;
                                    %break;  % quit the loop
                                    %case 'DIRECTORY LOOP STOP'
                                    %    break
                                otherwise
                                    SteploopSettings.DirectoryName = obj.Protocol(stepId).Batch.DirectoriesList{2}{dirId};
                                    SteploopSettings.FileLoopWaitbar = showDirLoopWaitbar;
                                    status = obj.doBatchStep(stepId2, SteploopSettings);    % make a single step
                                    if status == 0
                                        notify(obj.mibModel, 'stopProtocol');
                                        obj.View.handles.autoAddToProtocol.Value = autoAddSwitch;
                                        if obj.Protocol(stepId).Batch.DirLoopWaitbar; delete(dirLoopWaitbar); end
                                        return;
                                    end
                                    stepId2 = stepId2 + 1;
                            end
                        end
                    end
                    if obj.Protocol(stepId).Batch.DirLoopWaitbar; delete(dirLoopWaitbar); end
                    stepId = finishStep2 + 1;
                elseif strcmp(obj.Protocol(stepId).mibBatchActionName, 'FILE LOOP START')
                    if strcmp(obj.Protocol(stepId).Batch.DirectoryName{1}, 'Inherit from Directory loop')
                        errordlg(sprintf('!!! Error !!!\n\nInherit from Directory loop works only when the File loop is placed after the Directory loop!'), 'Wrong sequence of actions');
                        obj.View.handles.autoAddToProtocol.Value = autoAddSwitch;
                        return;
                    end
                    FileloopSettings.DirectoryName = obj.Protocol(stepId).Batch.DirectoryName{1};
                    FileloopSettings.FilenameFilter = obj.Protocol(stepId).Batch.FilenameFilter;
                    FileloopSettings.FileLoopWaitbar = obj.Protocol(stepId).Batch.FileLoopWaitbar;
                    
                    fileLoopStart = stepId+1;
                    fileLoopFinish = find(ismember({obj.Protocol(:).mibBatchActionName}, 'FILE LOOP STOP'));
                    if isempty(fileLoopFinish); fileLoopFinish = finishStep; end
                    
                    status = obj.doFileLoop(fileLoopStart, fileLoopFinish, FileloopSettings);
                    if status == 0
                        notify(obj.mibModel, 'stopProtocol');
                        obj.View.handles.autoAddToProtocol.Value = autoAddSwitch;
                        return;
                    end
                    stepId = fileLoopFinish + 1;
                else
                    if strcmp(obj.Protocol(stepId).mibBatchActionName, 'Load and combine images') && ...
                            strcmp(obj.Protocol(stepId).Batch.Mode{1}, 'Series-by-series')
                        % processing of bio-formats dataset series by series
                        startStep = stepId;
                        status = obj.doSeriesLoop(startStep, finishStep);
                    else
                        status = obj.doBatchStep(stepId);    % make a single step
                    end
                    
                    if status == 0
                        notify(obj.mibModel, 'stopProtocol');
                        obj.View.handles.autoAddToProtocol.Value = autoAddSwitch;
                        return;
                    end
                    stepId = stepId + 1;
                end
            end
            
            if strcmp(parameter, 'stepadvance')
                obj.protocolListIndex = min([obj.protocolListIndex + 1, numel(obj.Protocol)]);
                obj.updateProtocolList();
                obj.protocolList_SelectionCallback();
            end
            obj.View.handles.autoAddToProtocol.Value = autoAddSwitch;
            
            obj.View.handles.runProtocolBtn.String = 'Start protocol';
            obj.View.handles.runProtocolBtn.BackgroundColor = 'g';
            if strcmp(parameter, 'complete')
                fprintf('Protocol finished; elapsed time: %f seconds\n', toc(timerProtocolStart));
            end
        end
        
        function status = doSeriesLoop(obj, startStep, finishStep)
            % function doSeriesLoop(obj, startStep, finishStep)
            % do open each series in dataset-container one-by-one and
            % process until end of File loop or end of the protocol
            % Only for Bio-formats!
            %
            % Parameters:
            % startStep: is index of the first action inside the file loop
            % finishStep: is index of the last action of the file loop
            %
            % Return values:
            % status: [logical], success or fail of the function
            status = false;
            options.FileLoopWaitbar = true;
            
            stepOptions.seriesId = 1;   % define index of the first series
            
            switch obj.Protocol(startStep).Batch.DirectoryName{1}
                case 'Current MIB path'
                    filename = fullfile(obj.mibModel.myPath, obj.Protocol(startStep).Batch.FilenameFilter);
                case 'Inherit from Directory/File loop'
                    error('not implemented')
                otherwise
                    filename = fullfile(obj.Protocol(startStep).Batch.DirectoryName{1}, ...
                        obj.Protocol(startStep).Batch.FilenameFilter);
            end
            % get number of series in the container
            hDataset = loci.formats.Memoizer(bfGetReader(), 0, ...
                java.io.File(obj.mibModel.preferences.ExternalDirs.BioFormatsMemoizerMemoDir));
            hDataset.setId(filename);
            numSeries = hDataset.getSeriesCount();
            
            if options.FileLoopWaitbar
                wb = waitbar(0, '', 'Name', 'Processing series');
                set(findall(wb, 'type', 'text'), 'Interpreter', 'none');
                waitbar(0, wb, sprintf('Processing : %s\nPlease wait...', filename));
            end
            stepOptions.FileLoopWaitbar = options.FileLoopWaitbar;
            
            for seriesId =  1:numSeries
                if options.FileLoopWaitbar; waitbar(seriesId/numSeries, wb); end
                stepOptions.seriesId = seriesId;    % set series id for doBatchStep function
                for stepId = startStep:finishStep
                    status = obj.doBatchStep(stepId, stepOptions);
                    if status == 0; return; end
                end
            end
            if options.FileLoopWaitbar; delete(wb); end
            status = true;
        end
        
        function status = doFileLoop(obj, startStep, finishStep, options)
            % do the file loop action
            %
            % Parameters:
            % startStep: is index of the first action inside the file loop
            % finishStep: is index of the last action of the file loop
            % options: a structure with parameters
            % @li .DirectoryName - name of the file loop directory
            % @li .FilenameFilter - filter for filenames
            % @li .FileLoopWaitbar - when true show waitbar for the file loop only, all waitbars for subfunctions will be disabled
            %
            % Return values:
            % status: [logical], success or fail of the function
            status = false; %#ok<NASGU>
            
            if strcmp(options.DirectoryName, 'Current MIB path'); options.DirectoryName = obj.mibModel.myPath; end
            
            filename = dir(fullfile(options.DirectoryName, options.FilenameFilter));   % get list of files
            filename2 = arrayfun(@(filename) fullfile(options.DirectoryName, filename.name), filename, 'UniformOutput', false);  % generate full paths
            notDirsIndices = arrayfun(@(filename2) ~isdir(cell2mat(filename2)), filename2);     % get indices of not directories
            filename = {filename(notDirsIndices).name}';
            
            stepOptions.DirectoryName = options.DirectoryName;
            
            if options.FileLoopWaitbar; wb = waitbar(0, '', 'Name', 'Processing files'); set(findall(wb, 'type', 'text'), 'Interpreter', 'none'); end
            
            
            for fnId = 1:numel(filename)
                if options.FileLoopWaitbar
                    waitbar(fnId/numel(filename), wb, sprintf('Processing: %s\nPlease wait...', filename{fnId}));
                end
                stepOptions.FilenameFilter = filename{fnId};
                stepOptions.Filenames = {{fullfile(stepOptions.DirectoryName, filename{fnId})}};
                stepOptions.FileLoopWaitbar = options.FileLoopWaitbar;
                for stepId = startStep:finishStep
                    status = obj.doBatchStep(stepId, stepOptions);
                    if status == 0; return; end
                end
            end
            if options.FileLoopWaitbar; delete(wb); end
            status = true;
        end
        
        function status = doBatchStep(obj, stepId, stepOptions)
            % do a single step of the protocol
            %
            % Parameters:
            % stepId: index of a step to be done
            % stepOptions: an optional structure with parameters
            % @li .DirectoryName -> directory name provided by the File or Directory loop
            % @li .FilenameFilter -> FilenameFilter == filename provided by the File loop
            % @li .Filenames -> full path to the filename
            % @li .FileLoopWaitbar -> when true show waitbar for the file loop only, all waitbars for subfunctions will be disabled
            %
            % Return values:
            % status: [logical], success or fail of the function
            status = false;
            if nargin < 3; stepOptions = struct; end
            
            if obj.stopProtocolSwitch == true
                obj.View.handles.runProtocolBtn.String = 'Start protocol';
                obj.View.handles.runProtocolBtn.BackgroundColor = 'g';
                return;
            end    % stop protocol
            
            switch obj.Protocol(stepId).mibBatchActionName
                case 'STOP EXECUTION'
                    % stop the protocol
                    obj.View.handles.protocolList.Value = stepId;
                    obj.protocolListIndex = stepId;
                    msgbox(sprintf('Protocol: stop execution event!\n\n%s', obj.Protocol(stepId).Batch.Description), 'STOP EXECUTION', 'help');
                    status = false;
                    return;
                case {'DIRECTORY LOOP STOP', 'FILE LOOP STOP'}
                    obj.View.handles.protocolList.Value = stepId;
                    obj.protocolListIndex = stepId;
                    status = true;
                    return;
                case 'Directory operations'
                    % get directory
                    dirOut = obj.obtainDirectoryForAction('Mode', 'DirectoryName', stepId, stepOptions);
                    if isempty(dirOut); return; end
                    switch obj.Protocol(stepId).Batch.Operation{1}
                        case 'Change current MIB directory'
                            obj.mibModel.myPath = dirOut;
                        case 'Create new'
                            % already created in obtainDirectoryForAction function, except for Dir loop mode
                            if ~isfolder(dirOut)
                                try
                                    mkdir(dirOut);
                                catch err
                                    errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s\n\n%s', err.identifier, err.message, dirOut), 'Problem with directory');
                                    return;
                                end
                            end
                        case 'Delete directory'
                            try
                                rmdir(dirOut);
                            catch err
                                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s\n\nMost likely the following directory is not empty!\n%s', err.identifier, err.message, dirOut), 'Problem with directory');
                                return;
                            end
                    end
                    % force to refresh main window
                    notify(obj.mibModel, 'updateId');
                    status = true;
                    return;
                case 'File operations'
                    % obtain directories
                    sourceDir = obj.obtainDirectoryForAction('CurrentDirectoryMode', 'CurrentDirectory', stepId, stepOptions);
                    if isempty(sourceDir); return; end
                    
                    switch obj.Protocol(stepId).Batch.Operation{1}
                        case 'Delete'   % delete files
                            delete(fullfile(sourceDir, obj.Protocol(stepId).Batch.FilenameMask))
                            %system(sprintf('del %s', fullfile(sourceDir, obj.Protocol(stepId).Batch.FilenameMask)));
                        case 'Copy'     % copy files
                            targetDir = obj.obtainDirectoryForAction('TargetDirectoryMode', 'TargetDirectory', stepId, stepOptions);
                            if isempty(targetDir); return; end
                            try
                                copyfile(fullfile(sourceDir, obj.Protocol(stepId).Batch.FilenameMask), targetDir);
                            catch err
                                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s\n\nSource directory:\n%s', err.identifier, err.message, fullfile(sourceDir, obj.Protocol(stepId).Batch.FilenameMask)), 'Problem with directory');
                                return;
                            end
                        case 'Move'     % move files
                            targetDir = obj.obtainDirectoryForAction('TargetDirectoryMode', 'TargetDirectory', stepId, stepOptions);
                            if isempty(targetDir); return; end
                            try
                                movefile(fullfile(sourceDir, obj.Protocol(stepId).Batch.FilenameMask), targetDir);
                            catch err
                                errordlg(sprintf('!!! Error !!!\n\n%s\n\n%s\n\nSource directory:\n%s', err.identifier, err.message, fullfile(sourceDir, obj.Protocol(stepId).Batch.FilenameMask)), 'Problem with directory');
                                return;
                            end
                    end
                    status = true;
                    return;
                case 'Load and combine images'
                    Batch = obj.Protocol(stepId).Batch; %#ok<NASGU>
                    if strcmp(Batch.DirectoryName{1}, 'Inherit from Directory/File loop')
                        if ~isfield(stepOptions, 'DirectoryName')
                            errordlg(sprintf('!!! Error !!!\n\nWrong settings: Inherit from Directory/File loop parameter requires Directory or File loop before this action!'));
                            return;
                        end
                        Batch.DirectoryName{1} = stepOptions.DirectoryName;
                        if isfield(stepOptions, 'FilenameFilter'); Batch.FilenameFilter = stepOptions.FilenameFilter; end
                        if isfield(stepOptions, 'Filenames'); Batch.Filenames = stepOptions.Filenames; end
                    end
                    if Batch.UseBioFormats && strcmp(Batch.Mode{1}, 'Series-by-series')
                        Batch.Mode{1} = 'Combine datasets';     % replace mode to load the datasets
                        Batch.BioFormatsIndices = num2str(stepOptions.seriesId);
                    end
                    
                    %                     if Batch.UseBioFormats && strcmp(Batch.Mode{1}, 'Series-by-series')
                    %                         if ~isfield(stepOptions, 'seriesId')
                    %                             stepOptions.seriesId = 1;
                    %                             switch Batch.DirectoryName{1}
                    %                                 case 'Current MIB path'
                    %                                     filename = fullfile(obj.mibModel.myPath, Batch.FilenameFilter);
                    %                                 case 'Inherit from Directory/File loop'
                    %
                    %                                 otherwise
                    %                                     filename = fullfile(BatchOpt.DirectoryName{1}, Batch.FilenameFilter);
                    %                             end
                    %                             % get number of series in the container
                    %                             hDataset = loci.formats.Memoizer(bfGetReader(), 0, ...
                    %                                 java.io.File(obj.mibModel.preferences.ExternalDirs.BioFormatsMemoizerMemoDir));
                    %                             hDataset.setId(filename);
                    %                             stepOptions.numSeries = hDataset.getSeriesCount();
                    %                         else
                    %                             stepOptions.seriesId = stepOptions.seriesId + 1;
                    %                             if stepOptions.seriesId > stepOptions.numSeries
                    %                                 error('fadfaf');
                    %                             end
                    %                         end     % define starting index of the series
                    %                         Batch.Mode{1} = 'Combine datasets';     % replace mode to load the datasets
                    %                         Batch.BioFormatsIndices = num2str(stepOptions.seriesId);
                    %                     end
                case 'Save dataset'
                    Batch = obj.Protocol(stepId).Batch;
                    if ~isempty(strfind(Batch.DestinationDirectory, '[InheritLastDIR]'))
                        if ~isfield(stepOptions, 'DirectoryName')
                            errordlg(sprintf('!!! Error !!!\n\n[InheritLastDIR] requires DIRECTORY LOOP START action above this step!'), 'Problem with [InheritLastDIR]');
                            return;
                        end
                        % get inherited path
                        [~, InheritLastDIR] = fileparts(stepOptions.DirectoryName);
                        Batch.DestinationDirectory = strrep(Batch.DestinationDirectory, '[InheritLastDIR]', InheritLastDIR);
                    end
                case 'Example datasets'
                    Batch = obj.Protocol(stepId).Batch;
                    if strcmp(Batch.DirectoryName{1}, 'Inherit from Directory/File loop')
                        if ~isfield(stepOptions, 'DirectoryName')
                            errordlg(sprintf('!!! Error !!!\n\nWrong settings: Inherit from Directory/File loop parameter requires Directory or File loop before this action!'));
                            return;
                        end
                        Batch.DirectoryName{1} = stepOptions.DirectoryName;
                    end
                otherwise
                    Batch = obj.Protocol(stepId).Batch; %#ok<NASGU>
                    % remove possible settings for the comboboxes from the
                    % Batch structure
                    %fieldNames = fieldnames(Batch);
                    %for fName = 1:numel(fieldNames)
                    %    if iscell(Batch.(fieldNames{fName}))
                    %        Batch.(fieldNames{fName}) = Batch.(fieldNames{fName})(1);
                    %    end
                    %end
            end
            
            % update waitbar for file loops
            if isfield(stepOptions, 'FileLoopWaitbar') && isfield(Batch, 'showWaitbar')
                if stepOptions.FileLoopWaitbar == 1
                    Batch.showWaitbar = false;
                end
            end
            
            obj.View.handles.protocolList.Value = stepId;
            eval(obj.Protocol(stepId).Command);
            
            status = true;
        end
        
        function DirectoryLoopAction_Callback(obj, BatchOptInput)
            % callback for selection of Directory Loop action
            BatchOpt.DirectoriesList = {obj.mibModel.myPath};   % cell with the selected directory
            BatchOpt.DirectoriesList{2} = {obj.mibModel.myPath};    %  cell array with list of directories
            BatchOpt.DirLoopWaitbar = true;   % when true show waitbar for the directory loop

            % add section name and action name for the batch tool
            BatchOpt.mibBatchSectionName = 'Service steps';
            BatchOpt.mibBatchActionName = 'DIRECTORY LOOP START';
            % tooltips that will accompany the BatchOpt
            BatchOpt.mibBatchTooltip.DirectoriesList = sprintf('List of directories that are going to be processed in the loop; use the right mouse click over the Parameters table to add/remove directory');
            BatchOpt.mibBatchTooltip.DirLoopWaitbar = 'when checked the waitbar for the dirloop is displayed';

            if nargin == 2
                if isstruct(BatchOptInput) == 0
                    if isnan(BatchOptInput)
                        % trigger syncBatch event to send BatchOptOut to mibBatchController
                        eventdata = ToggleEventData(BatchOpt);
                        notify(obj.mibModel, 'syncBatch', eventdata);
                    else
                        errordlg(sprintf('A structure as the 1st parameter is required!'));
                    end
                    return;
                end
                % combine fields from input and default structures
                BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptInput);
            end
        end
        
        function FileOperationsAction_Callback(obj, BatchOptInput)
            % do various operations with files
            BatchOpt.Operation = {'Delete'};   % specify the target directory
            BatchOpt.Operation{2} = {'Copy', 'Delete', 'Move'};
            BatchOpt.CurrentDirectoryMode = {'Relative to current MIB path'};
            BatchOpt.CurrentDirectoryMode{2} = {'Absolute', 'Relative to current MIB path', 'Inherit from Directory loop'};
            BatchOpt.CurrentDirectory = '';
            BatchOpt.TargetDirectoryMode = {'Relative to current MIB path'};
            BatchOpt.TargetDirectoryMode{2} = {'Absolute', 'Relative to current MIB path', 'Inherit from Directory loop'};
            BatchOpt.TargetDirectory = '';
            BatchOpt.FilenameMask = '*.extension';
            % add section name and action name for the batch tool
            BatchOpt.mibBatchSectionName = 'Menu -> File';
            BatchOpt.mibBatchActionName = 'File operations';
            % tooltips that will accompany the BatchOpt
            BatchOpt.mibBatchTooltip.Operation = 'File operation to perform';
            BatchOpt.mibBatchTooltip.CurrentDirectoryMode = 'Strategy to acquire source directory with files';
            BatchOpt.mibBatchTooltip.CurrentDirectory = 'List here the full path to directory (Absolute) or relative. Use the right mouse click to select directory';
            BatchOpt.mibBatchTooltip.TargetDirectoryMode = 'Strategy to acquire directory for files, not used for Delete operation';
            BatchOpt.mibBatchTooltip.TargetDirectory = 'List here the full path to directory (Absolute) or relative. Use the right mouse click to select directory';
            BatchOpt.mibBatchTooltip.FilenameMask = 'Filter file names using this mask, put "*.*" to take all files';
            
            if nargin == 2
                if isstruct(BatchOptInput) == 0
                    if isnan(BatchOptInput)
                        % trigger syncBatch event to send BatchOptOut to mibBatchController
                        eventdata = ToggleEventData(BatchOpt);
                        notify(obj.mibModel, 'syncBatch', eventdata);
                    else
                        errordlg(sprintf('A structure as the 1st parameter is required!'));
                    end
                    return;
                end
                % combine fields from input and default structures
                BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptInput);
            end
        end
        
        function DirectoryOperationsAction_Callback(obj, BatchOptInput)
            % Directory operations of MIB
            BatchOpt.Operation = {'Change current MIB directory'};   % specify the target directory
            BatchOpt.Operation{2} = {'Change current MIB directory', 'Create new', 'Delete directory'};
            BatchOpt.Mode = {'Relative to current MIB path'};   % specify the target directory
            BatchOpt.Mode{2} = {'Absolute', 'Inherit from Directory loop', 'Inherit dirs +Dirname', 'Relative to current MIB path'};
            BatchOpt.DirectoryName = 'subFolder';
            % add section name and action name for the batch tool
            BatchOpt.mibBatchSectionName = 'Menu -> File';
            BatchOpt.mibBatchActionName = 'Directory operations';
            % tooltips that will accompany the BatchOpt
            BatchOpt.mibBatchTooltip.Operation = 'A directory operation to perform, directories that have files can not be removed';
            BatchOpt.mibBatchTooltip.Mode = 'Relative: directory name will be added to the current MIB path; Inherit: path will be acquired from DIR LOOP; +Dirname: adds dirname to dir loop directory; Absolute: the full provided dirname will be used';
            BatchOpt.mibBatchTooltip.DirectoryName = 'Provide full directory name, relative to current or use "../" to go to parent directory. Use the right mouse click to modify';
            
            if nargin == 2
                if isstruct(BatchOptInput) == 0
                    if isnan(BatchOptInput)
                        % trigger syncBatch event to send BatchOptOut to mibBatchController
                        eventdata = ToggleEventData(BatchOpt);
                        notify(obj.mibModel, 'syncBatch', eventdata);
                    else
                        errordlg(sprintf('A structure as the 1st parameter is required!'));
                    end
                    return;
                end
                % combine fields from input and default structures
                BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptInput);
            end
        end
        
        function FileLoopAction_Callback(obj, BatchOptInput)
            % callback for selection of File Loop action
            BatchOpt.DirectoryName = {'Current MIB path'};   % specify the target directory
            BatchOpt.DirectoryName{2} = {'Current MIB path', 'Inherit from Directory loop', obj.mibModel.myPath};
            BatchOpt.FilenameFilter = '*.*';   % use the filename filter to select files
            BatchOpt.FileLoopWaitbar = true;   % when true only the waitbar for the fileloop is displayed, waitbars in all substeps are disabled
            % add section name and action name for the batch tool
            BatchOpt.mibBatchSectionName = 'Service steps';
            BatchOpt.mibBatchActionName = 'FILE LOOP START';
            % tooltips that will accompany the BatchOpt
            BatchOpt.mibBatchTooltip.DirectoryName = 'Directory name, where the files are located, use the right mouse click over the Parameters table to modify the directory';
            BatchOpt.mibBatchTooltip.FilenameFilter = 'Filter for filenames: *.* - process all files in the directory; *.tif - process only the TIF files';
            BatchOpt.mibBatchTooltip.FileLoopWaitbar = 'when checked only the waitbar for the fileloop is displayed, waitbars in all substeps are turned off';
            
            if nargin == 2
                if isstruct(BatchOptInput) == 0
                    if isnan(BatchOptInput)
                        % trigger syncBatch event to send BatchOptOut to mibBatchController
                        eventdata = ToggleEventData(BatchOpt);
                        notify(obj.mibModel, 'syncBatch', eventdata);
                    else
                        errordlg(sprintf('A structure as the 1st parameter is required!'));
                    end
                    return;
                end
                % combine fields from input and default structures
                BatchOpt = updateBatchOptCombineFields_Shared(BatchOpt, BatchOptInput);
            end
        end
        
        function gui_WinMouseMotionFcn(obj)
            % function gui_WinMouseMotionFcn(obj)
            % get mouse coordinates for the window to change cursor shape when above separatingPanel
            % to rescaling the panels
            
            position = obj.View.gui.CurrentPoint;
            x = round(position(1,1));
            y = round(position(1,2));
            separatingPanelPos = obj.View.handles.separatingPanel.Position;
        
            if x>separatingPanelPos(1) && x<separatingPanelPos(1)+separatingPanelPos(3) && ...
                y>separatingPanelPos(2) && y<separatingPanelPos(2)+separatingPanelPos(4) % mouse pointer within the panel
                obj.View.gui.Pointer = 'top';
            else
                obj.View.gui.Pointer = 'arrow';
            end
        end
        
        function gui_WindowButtonDownFcn(obj)
            % function gui_WindowButtonDownFcn(obj)
            % callback for mouse press over the figure,
            % to start rescaling of panels
            
            position = obj.View.gui.CurrentPoint;
            x = round(position(1,1));
            y = round(position(1,2));
            
            separatingPanelPos = obj.View.handles.separatingPanel.Position;
            if x>separatingPanelPos(1) && x<separatingPanelPos(1)+separatingPanelPos(3) && ...
                    y>separatingPanelPos(2) && y<separatingPanelPos(2)+separatingPanelPos(4) % mouse pointer within the panel

                obj.View.gui.WindowButtonUpFcn = (@(hObject, eventdata, handles) obj.panelShiftBtnUpFcn());
                return;
            end
        end
        
        function panelShiftBtnUpFcn(obj)
            % function panelShiftBtnUpFcn(obj)
            % get values to change size of the panels
            
            obj.View.gui.Pointer = 'arrow';
            
            position = obj.View.gui.CurrentPoint;  % get position of the cursor
            y = round(position(1,2));
            obj.View.handles.actionListPanel.Position(4) = obj.View.handles.mibBatchGUI.Position(4) - y - 6;
            obj.View.gui.WindowButtonUpFcn = [];
            obj.sizeChangedFcn();
        end
        
        function sizeChangedFcn(obj)
            % function sizeChangedFcn(obj)
            % main resizing function for the window
            
            mainFigPos = obj.View.handles.mibBatchGUI.Position;
            if mainFigPos(4) < 372
                obj.View.handles.mibBatchGUI.Position(4) = 372;
                obj.View.handles.mibBatchGUI.Position(2) = mainFigPos(2)-(372-mainFigPos(4));
                return;
            end
            obj.View.handles.actionListPanel.Position(2:3) = [mainFigPos(4)-obj.View.handles.actionListPanel.Position(4), ...
                mainFigPos(3) - 10];
            obj.View.handles.protocolList.Position(4) = obj.View.handles.actionListPanel.Position(4) - 30;
            
            obj.View.handles.separatingPanel.Position(2) = obj.View.handles.actionListPanel.Position(2) - 4;
            
            obj.View.handles.selectActionPanel.Position(3:4) = [mainFigPos(3) - 14, ...
                obj.View.handles.actionListPanel.Position(2) - obj.View.handles.selectActionPanel.Position(2)]-4;
            
            obj.View.handles.StepsSubpanelUp.Position(2) = obj.View.handles.selectActionPanel.Position(4) - obj.View.handles.StepsSubpanelUp.Position(4) - 10;
            obj.View.handles.selectedActionTable.Position(3:4) = [(obj.View.handles.selectActionPanel.Position(3) - obj.View.handles.selectedActionTable.Position(2))/2, ...
                obj.View.handles.StepsSubpanelUp.Position(2) - 10];
            obj.View.handles.ParametersText.Position(2) = obj.View.handles.selectedActionTable.Position(2)+obj.View.handles.selectedActionTable.Position(4)-obj.View.handles.ParametersText.Position(4);
            obj.View.handles.StepsSubpanelRight.Position(2) = obj.View.handles.StepsSubpanelUp.Position(2) - obj.View.handles.StepsSubpanelRight.Position(4);
            obj.View.handles.StepsSubpanelRight.Position(1) = obj.View.handles.selectedActionTable.Position(1)+obj.View.handles.selectedActionTable.Position(3) + 10;
            obj.View.handles.StepsSubpanelRight.Position(3) = obj.View.handles.selectActionPanel.Position(3)-obj.View.handles.StepsSubpanelRight.Position(1);
        end
        
        function listenMIB_Callback(obj)
            % function listenMIB_Callback(obj)
            % modify listener to actions from MIB
            if obj.View.handles.listenMIB.Value == 1
                obj.listener{2}.Enabled = true;
            else
                obj.listener{2}.Enabled = false;
            end
        end
    end
end