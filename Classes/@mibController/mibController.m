classdef mibController < handle
    % main controller for MIB
    
    % Copyright (C) 04.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    %
    
    properties
        mibVersion = 'ver. 2.1 / 01.06.2017';  % ATTENTION! it is important to have the version number between "ver." and "/"
        % version of MIB
        mibModel
        % handles to the model
        mibView
        % handle to the view
        listener
        % a cell array with handles to listeners
        matlabVersion
        % version of Matlab
        mibPath 
        % path to MIB installation directory
        brushSizeNumbers
        % matrix with the font for changing of brush size
        connImaris
        % a handle to Imaris connection
        childControllers
        % list of opened subcontrollers
        childControllersIds
        % a cell array with names of initialized child controllers
    end
    
    events
        %> Description of events
    end
    
    methods (Static)
        function purgeControllers(obj, src, evnt)
            % find index of the child controller
            id = obj.findChildId(class(src));
            
            % delete the child controller
            delete(obj.childControllers{id});
            
            % clear the handle
            obj.childControllers(id) = [];
            obj.childControllersIds(id) = [];
        end
    end
    
    methods
        % declaration of functions in the external files, keep empty line in between for the doc generator
        devTest_ClickedCallback(obj)        % for developmental purposes
        
        exitProgram(obj)        % exit MIB    
        
        id = findChildId(obj, childName)        % find index of a child controller    
        
        getDefaultParameters(obj)          % initialization of default parameters
        
        imageRedraw(obj)        % redraw image in the handles.mibImageAxes after press of handles.mibHideImageCheck or transparency sliders
        
        result = menuDatasetParameters_Callback(obj, pixSize)        % Update mibImage.pixelSize, mibImage.meta(''XResolution'') and mibImage.meta(''XResolution'') and mibView.volren
        
        menuDatasetScalebar_Callback(obj, parameter)        % callback to Menu->Dataset->Scale bar; calibrate pixel size from an existing scale bar
        
        menuDatasetSlice_Callback(obj, parameter)        % callback to Menu->Dataset->Slice; do actions with individual slices
        
        menuDatasetTrasform_Callback(obj, mode)        % callback to Menu->Dataset->Transform... do different transformation with the dataset
        
        menuFileChoppedImage_Callback(obj, parameter)        % callback to Menu->File->Chopped images, chop/rechop dataset to/from smaller subsets
        
        menuFileExportImage_Callback(obj, parameter)        % callback to Menu->File->Export Image, export image and meta-data from MIB to the main Matlab workspace or Imaris
        
        menuFileImportImage_Callback(obj, parameter)        % callback to Menu->File->Import Image, import image from Matlab main workspace or system clipboard
        
        menuFilePreference_Callback(obj)        % callback to MIB->Menu->File->Preferences...
        
        menuFileRenderFiji_Callback(obj)        % callback to MIB->Menu->File->Render volume (with Fiji)...
        
        menuFileSaveImageAs_Callback(obj)        % callback to the mibGUI.handles.menuFileSaveImageAs, saves image to a file
        
        menuHelpAbout_Callback(obj)        % callback to Menu->Help->About; show the About window
        
        menuImageColorCh_Callback(obj, parameter)        % callback to Menu->Image->Color Channels do actions with individual color channels
        
        menuImageContrast_Callback(obj, parameter)        % callback to Menu->Image->Contrast; do contrast enhancement
        
        menuImageIntensity_Callback(obj, parameter)        % callback to the Menu->Image->Intensity profile; get the image intensity profile 
        
        menuImageInvert_Callback(obj, mode)        % callback for Menu->Image->Invert image; start invert image 
        
        menuImageMode_Callback(obj, hObject)        % callback to the Menu->Image->Mode, convert image to different formats
        
        menuMaskClear_Callback(obj)        % callback to Menu->Mask->Clear mask, clear the Mask layer
        
        menuMaskExport_Callback(obj, parameter)        % callback to Menu->Mask->Export, export the Mask layer to Matlab or another buffer
        
        menuMaskImageReplace_Callback(obj, type)        % callback to Menu->Mask->Replace color; replace image intensities in the @em Masked or @em Selected areas with new intensity value
        
        menuMaskImport_Callback(obj, parameter)        % callback to Menu->Mask->Import, import the Mask layer from Matlab or another buffer of MIB
        
        menuMaskInvert_Callback(obj, type)        % callback to Menu->Mask->Invert; invert the Mask layer
        
        menuMaskLoad_Callback(obj)        % callback to Menu->Mask->Load Mask; load the Mask layer to MIB from a file
        
        menuMaskSaveAs_Callback(obj)        % callback to Menu->Mask->Save As; save the Mask layer to a file
        
        menuModelsConvertModel(obj, modelType)  % callback to Menu->Models->Convert, convert the model to a different modelType
        
        menuModelsExport_Callback(obj, parameter)        % callback to Menu->Models->Export export the Model layer to the main Matlab workspace
        
        menuModelsImport_Callback(obj)        % callback to Menu->Models->Import; import the Model layer from the main Matlab workspace
        
        menuModelsRender_Callback(obj, type)        % callback to MIB->Menu->Models->Render model...
        
        menuModelsSaveAs_Callback(obj, parameter)        % callback to Menu->Models->Save as; save model to a file
        
        menuSelectionBuffer_Callback(obj, parameter)        % callback to Menu->Selection to Buffer... to Copy/Paste/Clear of the selection of the shown layer
        
        menuSelectionInterpolate(obj)        % callback to the Menu->Selection->Interpolate; interpolates shapes of the selection layer
        
        menuSelectionToMaskBorder_Callback(obj)        % callback to Menu->Selection->Expand to Mask border; expand selection to borders of the Masked layer
        
        menuSmooth_Callback(obj, type)        % callback to the smooth mask, selection or model layer
        
        menuToolsMeasure_Callback(obj, type)        % callback for selection of obj.mibView.handles.menuToolsMeasure entries
        
        mibAddMaterialBtn_Callback(obj)        % callback to the obj.mibView.handles.mibAddMaterialBtn, add material to the model
        
        mibAnisotropicDiffusion(obj, filter_type)        % Filter image with Anisotropic diffusion filters
        
        mibAutoBrightnessBtn_Callback(obj)        % Adjust brightness automatically for the shown image
        
        mibBioformatsCheck_Callback(obj)  % Bioformats that can be read with BioFormats toolbox this function updates the list of file filters in obj.mibView.handles.mibFileFilterPopup
        
        mibBufferToggle_Callback(obj, Id)            % a callback to press of obj.mibView.handles.mibBufferToggle button
        
        mibBufferToggleContext_Callback(obj, parameter, buttonID)   % callback function for the popup menu of the buffer buttons in the upper part of the @em Directory @em contents panel. This callback is triggered from all those buttons.
        
        mibBrushSuperpixelsEdit_Callback(obj, hObject)        % callback for modification of superpixel mode settings of the brush tool
        
        mibBrushSuperpixelsWatershedCheck_Callback(obj, hObject)        % callback for selection of superpixel mode for the brush tool

        mibChangeLayerEdit_Callback(obj, parameter)        % callback for changing the slices of the 3D dataset by entering a new slice number
        
        mibChangeLayerSlider_Callback(obj)        % callback function for mibGUI.mibChangeLayerSlider. Responsible for showing next or previous slice of the dataset
        
        mibChangeTimeEdit_Callback(obj, parameter)        % callback for changing the time points of the dataset by entering a new time value
        
        mibChangeTimeSlider_Callback(obj)        % callback function for mibGUI.mibChangeTimeSlider. Responsible for showing next or previous time point of the dataset
        
        mibChannelMixerTable_Callback(obj, type)        % callback for the context menu of obj.mibView.handles.mibChannelMixerTable
        
        mibChannelMixerTable_CellEditCallback(obj, Indices, PreviousData, modifier)        % callback edit of a cell in obj.mibView.handles.mibChannelMixerTable
        
        mibChannelMixerTable_CellSelectionCallback(obj, Indices)        % callback selection of a cell in obj.mibView.handles.mibChannelMixerTable
        
        mibColChannelCombo_Callback(obj)    % callback for modification of obj.View.handles.mibColorChannelCombo box
        
        mibCreateModelBtn_Callback(obj, modelType)        % Create a new model
        
        mibDoUndo(obj, newIndex)        % Undo the recent changes with Ctrl+Z shortcut
        
        mibEraserEdit_Callback(obj)        % increase size of the eraser tool with the provided in obj.mibView.handles.mibEraserEdit
        
        mibFijiExport(obj)        % export currently open dataset to Fiji
        
        mibFijiImport(obj)        % import dataset from Fiji to MIB
        
        mibFijiRunMacro(obj)        % run command or macro on Fiji
        
        mibFilesListbox_Callback(obj)        % navigation in the file list, i.e. open file or change directory
        
        mibFilesListbox_cm_Callback(obj, parameter)        % a context menu to the to the handles.mibFilesListbox, the menu is called
        
        mibFindMaterialUnderCursor(obj)     % find material under the mouse cursor, a callback for Ctrl+F key shortcut
        
        mibImageFilterDoitBtn_Callback(obj)        % callback to the obj.mibView.handles.mibImageFilterDoitBtn, apply image filtering using the selected filter
        
        mibInvertImage(obj, col_channel, sel_switch)        % Invert image
        
        mibLoadModelBtn_Callback(obj, model, options)        % callback to the obj.mibView.handles.mibLoadModelBtn, loads model to MIB from a file
        
        mibMaskGenerator(obj, type)        % generate the 'Mask' later
        
        mibMaskRecalcStatsBtn_Callback(obj)        % recalculate objects for Mask or Model layer to use with the Object Picker tool in 3D
        
        mibMaskShowCheck_Callback(obj)        % callback to the mibGUI.handles.mibMaskShowCheck, allows to toggle visualization of the mask layer
        
        mibModelPropertyUpdate(obj, parameter)        % update switches in the obj.mibModel class that describe states of GUI widgets
        
        meta = getMeta(obj)        % get meta data for the currently shown dataset, mibImage.meta
        
        mibLutCheckbox_Callback(obj)        % callback to the mibGUI.handles.mibLutCheckbox, turn on/off visualization of color channels using luck-up table (LUT)
        
        mibModelShowCheck_Callback(obj)        % callback to the mibGUI.handles.mibModelShowCheck to toggle the Model layer on/off
        
        mibMoveLayers(obj, obj_type_from, obj_type_to, layers_id, action_type)        % to move datasets between the layers (image, model, mask, selection)
        
        mibPixelInfo_Callback(obj, parameter)        % center image to defined position it is callback from a popup menu above the pixel information field of the Path panel
        
        mibRemoveMaterialBtn_Callback(obj)        % callback to the obj.mibView.handles.mibRemoveMaterialBtn, remove material from the model
        
        mibRoiAddBtn_Callback(obj)        % callback to handles.mibRoiAddBtn, adds a roi to a dataset
        
        mibRoiList_cm_Callback(obj, parameter)        % callback for obj.mibView.handles.mibRoiList context menu
        
        mibRoiLoadBtn_Callback(obj)        % callback to the obj.mibView.handles.mibRoiLoadBtn, loads roi from a file to MIB
        
        mibRoiOptionsBtn_Callback(obj, parameter)        % update ROI visualization settings, as callback of mibGUI.handles.mibRoiOptionsBtn
        
        mibRoiRemoveBtn_Callback(obj)        % callback to obj.mibView.handles.mibRoiRemoveBtn, remore selected ROI
        
        mibRoiSaveBtn_Callback(obj)        % callback to the obj.mibView.handles.mibRoiSaveBtn, saves roi to a file in the matlab format
        
        mibRoiShowCheck_Callback(obj, parameter)        % toggle show/hide state of ROIs, as callback of mibGUI.handles.mibRoiShowCheck
        
        mibRoiToSelectionBtn_Callback(obj)        % callback to obj.mibView.handles.mibRoiToSelectionBtn, highlight area under the selected ROI in the Selection layer
        
        mibSegmentation3dBall(obj, y, x, z, modifier)        % Do segmentation using the 3D ball tool
        
        mibSegmentationAnnotation(obj, y, x, z, t, modifier)        % Add text annotation to the dataset
        
        mibSegmAnnDeleteAllBtn_Callback(obj)        % callback to Menu->Models->Annotations...->Delete all annotations; delete all annotations of the model
        
        mibSegmentationBlackWhiteThreshold(obj, parameter)        % Perform black and white thresholding for @em BW @em Threshold tool of the 'Segmentation panel'
        
        mibSegmentationBrush(obj, y, x, modifier)        % do segmentation using the brush tool
        
        mibSegmentationLasso(obj, modifier)        % Do segmentation using the lasso tool
        
        mibSegmentationLassoManual(obj, modifier)        % Do manual segmentation using the lasso tool in the manual mode
        
        mibSegmentationMagicWand(obj, yxzCoordinate, modifier)        % Do segmentation using the Magic Wand tool
        
        output = mibSegmentationMembraneClickTraker(obj, yxzCoordinate, yx, modifier)        % Trace membranes and draw a straight lines in 2d and 3d
        
        mibSegmentationObjectPicker(obj, yxzCoordinate, modifier)        % Select 2d/3d objects from the Mask or Model layers
        
        mibSegmentationRegionGrowing(obj, yxzCoordinate, modifier)        % Do segmentation using the Region Growing method
        
        mibSegmentationSpot(obj, y, x, modifier)        % Do segmentation using the spot tool
        
        mibSegmentationTable_CellSelectionCallback(obj, eventdata)        % callback for cell selection in the handles.mibSegmentationTable table of mibGIU.m
        
        mibSegmentationTable_cm_Callback(obj, hObject, type)        % callback to the context menu of mibView.handles.mibSegmentationTable
        
        mibSegmentationToolPopup_Callback(obj)        % callback to the handles.mibSegmentationToolPopup, allows to select tool for the segmentation
        
        mibSegmFavToolCheck_Callback(obj)        % callback to the obj.mibView.handles.mibSegmFavToolCheck, to add the selected tool to the list of favourites
        
        mibSegmSelectedOnlyCheck_Callback(obj)        % callback to the mibGUI.handles.mibSegmSelectedOnlyCheck, allows to toggle state of the 'Fix selection to material'
        
        mibSelectionButton_Callback(obj, action)        % callback to 'A', 'S', 'R' buttons in the Selection panel of obj.mibView.gui
        
        mibSelectionClearBtn_Callback(obj, sel_switch)        % callback to the mibGUI.handles.mibSelectionClearBtn, allows to clear the Selection layer
        
        mibSelectionDilateBtn_Callback(obj, sel_switch)        % callback to the mibGUI.handles.mibSelectionDilateBtn, expands the selection layer
        
        mibSelectionErodeBtn_Callback(obj, sel_switch)        % callback to the mibGUI.handles.mibSelectionErodeBtn, shrinks the selection layer
        
        mibSelectionFillBtn_Callback(obj, sel_switch)        % callback to the mibGUI.handles.mibSelectionFillBtn, allows to fill holes for the Selection layer
        
        mibToolbar_ZoomBtn_ClickedCallback(obj, hObject, recenterSwitch)        % modifies magnification using the zoom buttons in the toolbar of MIB
        
        mibToolbarPlaneToggle(obj, hObject, moveMouseSw)        % callback to the change orientation buttons in the toolbar of MIB; it toggles viewing plane: xy, zx, or zy direction
        
        mibZoomEdit_Callback(obj)        % callback function for modification of the handles.mibZoomEdit 
        
        mibGUI_Brush_scrollWheelFcn(obj, eventdata)        % Control callbacks from mouse scroll wheel during the brush tool
        
        mibGUI_panAxesFcn(obj, xy, imgWidth, imgHeight)        % This function is responsible for moving image in obj.mibView.handles.mibImageAxes during panning
        
        mibGUI_PanelShiftBtnUpFcn(obj, panelName)        % callback for the release of a mouse button over handles.mibSeparatingPanel to change size of Directory contents and Segmentation panels
        
        mibGUI_ScrollWheelFcn(obj, eventdata)         % control callbacks from mouse scroll wheel 
        
        mibGUI_SizeChangedFcn(obj, resizeParameters)        % resizing for panels of MIB
        
        mibGUI_WindowBrushMotionFcn(obj, selection_layer, structElement, currMask)        % This function draws the brush trace during use of the brush tool
        
        mibGUI_WindowButtonDownFcn(obj)        % this is callback for the press of a mouse button
        
        mibGUI_WindowButtonUpFcn(obj, brush_switch)        % callback for release of the mouse button
        
        mibGUI_WindowKeyPressFcn(obj, hObject, eventdata)        % callback for a key press in mibGUI
        
        mibGUI_WindowKeyPressFcn_BrushSuperpixel(hObject, eventdata, handles)        % a function to check key callbacks when using the Brush in the Superpixel mode
        
        mibGUI_WindowKeyReleaseFcn(obj, eventdata)        % callback for release of keys in mibGUI window
        
        mibGUI_WinMouseMotionFcn(obj)        % returns coordinates and image intensities under the mouse cursor
        
        plotImage(obj, resize, sImgIn)        % plot image to mibImageAxes
        
        redrawMibChannelMixerTable(obj)        % Update obj.mibView.handles.mibChannelMixerTable table and obj.mibView.handles.mibColChannelCombo color combo box
        
        setMeta(obj, meta)        % set meta data for the currently shown dataset, mibImage.meta
        
        startController(obj, controllerName, varargin)        % start a child controller
        
        startPlugin(obj, pluginName)        % start plugin from mib menu
        
        toolbarBlockModeSwitch_ClickedCallback(obj)        % callback for press of obj.mibView.toolbarBlockModeSwitch in the toolbar of MIB
        
        toolbarInterpolation_ClickedCallback(obj, options)        % Function to set the state of the interpolation button in the toolbar
        
        toolbarRedo_ClickedCallback(obj)        % do one step forward in the undo history
        
        toolbarResizingMethod_ClickedCallback(obj, options)        % Function to set type of image interpolation for the visualization
        
        toolbarUndo_ClickedCallback(obj)        % do one step back in the undo history
        
        updateAxesLimits(obj, index, mode, newMagFactor)        % Updates the obj.mibView.axesX and obj.mibView.axesY during fit screen, resize, or new dataset drawing
        
        updateFilelist(obj, filename)        % Update list of files in the current working directory (obj.mibModel.myPath) 
        
        updateGuiWidgets(obj)        % Update user interface widgets in obj.mibView.gui based on the properties of the opened dataset
        
        updateMyPath(obj, myPath)        % update obj.mibModel.myPath variable in the model
        
        updateShownId(obj, Id)        % update index of the displayed dataset
        
        updateSegmentationTable(obj, position)        % update obj.mibView.handles.mibSegmentationTable in the main window of mibGIU.m
        
        volrenToolbarSwitch_ClickedCallback(obj, parameter)        % callback for press of obj.mibView.volrenToolbarSwitch in the toolbar of MIB
        
        volren_WindowButtonDownFcn(obj)        % callback for the press of a mouse button during the volume rendering mode
        
        volren_scrollWheelFcn(obj, eventdata)        % callback for mouse wheel during the volume rendering mode
        
        volren_winMouseMotionFcn(obj)        % change cursor shape when cursor is inside the axis during the volume rendering mode
        
        volren_WindowButtonUpFcn(obj)        % callback for mouse button up event during the volume rendering mode
        
        volren_WindowInteractMotionFcn(obj, seltype)        % callback for translation/rotation of dataset during the volume rendering mode
        
        
%         function purgeControllers(obj, src, evnt)
%             % find index of the child controller
%             id = obj.findChildId(class(src));
%             
%             % delete the child controller
%             delete(obj.childControllers{id});
%             
%             % clear the handle
%             obj.childControllers(id) = [];
%         end
        
        function obj = mibController(mibModel)
            % function obj = mibController(mibModel)
            % mibController class constructor
            %
            % Constructor for the mibController class. Create a new instance of
            % the class with default parameters
            %
            % Parameters:
            % mibModel: a handle to mibModel class
            
            % show splash screen
            try
                if isdeployed
                    if isunix()
                        if ismac()
                            NameOfDeployedApp = 'MIB'; % do not include the '.app' extension
                            [~, result] = system(['top -n100 -l1 | grep ' NameOfDeployedApp ' | awk ''{print $1}''']);
                            result=strtrim(result);
                            [status, result] = system(['ps xuwww -p ' result ' | tail -n1 | awk ''{print $NF}''']);
                            if status==0
                                diridx=strfind(result,[NameOfDeployedApp '.app']);
                                obj.mibPath=result(1:diridx-2);
                            else
                                obj.mibPath = '/Applications/MIB/application/';
                            end
                        else
                            % the code below does not work on Mac OS X Yosemite and R2016a
                            % so fix MIB location
                            [~, result] = system('path');
                            obj.mibPath = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
                        end
                    else
                        [~, result] = system('path');
                        obj.mibPath = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
                    end
                    img = imread(fullfile(obj.mibPath, 'Resources', 'splash'));  % load splash screen
                    
                    % get numbers for the brush size change
                    obj.brushSizeNumbers = 1-imread(fullfile(obj.mibPath, 'Resources', 'numbers.png'));   % height=16, letter size = 8, +1 pixel border
                    dejavufont = 1-imread(fullfile(obj.mibPath, 'Resources', 'DejaVuSansMono.png'));   % table with DejaVu font, Pt = 8, 10, 12, 14, 16, 18, 20
                else
                    obj.mibPath = fileparts(which('mib'));
                    img = imread(fullfile(obj.mibPath, 'Resources', 'splash'));  % load splash screen
                    
                    % get numbers for the brush size change
                    obj.brushSizeNumbers = 1-imread(fullfile(obj.mibPath, 'Resources', 'numbers.png'));   % height=16, letter size = 8, +1 pixel border
                    dejavufont = 1-imread(fullfile(obj.mibPath, 'Resources', 'DejaVuSansMono.png'));   % table with DejaVu font, Pt = 8, 10, 12, 14, 16, 18, 20
                end
                addTextOptions.color = [1 1 0];
                addTextOptions.fontSize = 2;
                addTextOptions.markerText = 'text';
                img = mibAddText2Img(img, obj.mibVersion, [1, 425], dejavufont, addTextOptions);
                
                jimg = im2java(img);
                frame = javax.swing.JFrame;
                frame.setUndecorated(true);
                icon = javax.swing.ImageIcon(jimg);
                label = javax.swing.JLabel(icon);
                frame.getContentPane.add(label);
                frame.pack;
                imgSize = size(img);
                frame.setSize(imgSize(2),imgSize(1));
                screenSize = get(0,'ScreenSize');
                frame.setLocation((screenSize(3)-imgSize(2))/2,...
                    (screenSize(4)-imgSize(1))/2);
                frame.show;
                %    end
            catch err
                sprintf('%s', err.identifier);
            end
            
            % get the current version of Matlab; keep this variable to be faster and
            % not call ver function
            v = ver('matlab');
            obj.matlabVersion = str2double(v(1).Version);
            
            obj.childControllers = {};    % initialize child controllers
            obj.childControllersIds = {};
            
            obj.mibModel = mibModel;
            obj.getDefaultParameters();          % restore default/stored parameters
            % define some global variables
            global Font mibPath scalingGUI;
            Font = obj.mibModel.preferences.Font;
            mibPath = obj.mibPath;
            scalingGUI = obj.mibModel.preferences.gui;
            
            obj.mibView = mibView(obj);
            
            % update LUT colors and non-63 materials models
            for i=1:obj.mibModel.maxId
                obj.mibModel.I{i}.modelMaterialColors = obj.mibModel.preferences.modelMaterialColors;
                obj.mibModel.I{i}.lutColors = obj.mibModel.preferences.lutColors;
                obj.updateAxesLimits('resize', i);
            end
            
            obj.mibModel.mibHideImageCheck = obj.mibView.handles.mibHideImageCheck.Value;   % define whether or not display the image layer
            obj.mibModel.mibModelShowCheck = obj.mibView.handles.mibModelShowCheck.Value; % define whether or not dispay the model layer (used in obj.mibModel.getRGBimage)
            obj.mibModel.mibMaskShowCheck = obj.mibView.handles.mibMaskShowCheck.Value; % define whether or not dispay the mask layer (used in obj.mibModel.getRGBimage)

            obj.mibModel.mibLiveStretchCheck = obj.mibView.handles.mibLiveStretchCheck.Value;   % enable/disable live stretching of image intensities
            obj.mibModel.mibShowAnnotationsCheck = obj.mibView.handles.mibShowAnnotationsCheck.Value;   % enable/disable live stretching of image intensities
            obj.mibModel.mibAnnMarkerCheck = obj.mibView.handles.mibAnnMarkerCheck.Value;   % show only annotation marker: @b 0 - marker and text; @ 1 - only marker
            obj.mibModel.mibSegmShowTypePopup = obj.mibView.handles.mibSegmShowTypePopup.Value;   % type of model visualization: @b 1 - filled; @b 2 - contour
            
            obj.plotImage(1);
            
            obj.connImaris = [];    % empty connection to Imaris
            
            obj.mibModel.myPath = obj.mibModel.preferences.lastpath;  % define current working directory
            obj.mibModel.U.setNumberOfHistorySteps(obj.mibModel.preferences.maxUndoHistory, obj.mibModel.preferences.max3dUndoHistory);    % update number of history steps
            
            if strcmp(obj.mibModel.preferences.undo, 'no')   % define enable/disable undo
                obj.mibModel.U.enableSwitch = 0;
            else
                obj.mibModel.U.enableSwitch = 1;
            end
            
            obj.mibBioformatsCheck_Callback();          % update list of file filters
            obj.updateMyPath(obj.mibModel.myPath);      % update list of files in the GUI
            obj.updateGuiWidgets();
            
            % update listeners
            %obj.listener{1} = addlistener(obj.mibModel, 'Id', 'PostSet', @(src,evnt) mibController.ViewListner_Callback(obj, src, evnt));     % for static
            %obj.listener{2} = addlistener(obj.mibModel, 'newDatasetSwitch', 'PostSet', @(src,evnt) mibController.ViewListner_Callback(obj, src, evnt));     % for static
            obj.listener{1} = addlistener(obj.mibModel, 'newDataset', @(src,evnt) mibController.Listner2_Callback(obj, src, evnt));
            obj.listener{2} = addlistener(obj.mibModel, 'updateId', @(src,evnt) mibController.Listner2_Callback(obj,src,evnt));
            obj.listener{3} = addlistener(obj.mibModel, 'plotImage', @(src,evnt) mibController.Listner2_Callback(obj,src,evnt));
            obj.listener{4} = addlistener(obj.mibModel, 'updateLayerSlider', @(src,evnt) mibController.Listner2_Callback(obj,src,evnt));
            obj.listener{5} = addlistener(obj.mibModel, 'updateTimeSlider', @(src,evnt) mibController.Listner2_Callback(obj,src,evnt));
            obj.listener{6} = addlistener(obj.mibModel, 'showMask', @(src,evnt) mibController.Listner2_Callback(obj,src,evnt));
            obj.listener{7} = addlistener(obj.mibModel, 'showModel', @(src,evnt) mibController.Listner2_Callback(obj,src,evnt));
            
            % update version specific elements
            if obj.matlabVersion < 9
                obj.mibView.handles.mibSegmThresPanelAdaptiveCheck.Enable = 'off';
            end
            
            if exist('frame','var')     % close splash window
                frame.hide;
                clear frame;
            end
            
            % check for update
            currentDate = floor(now);
            if currentDate - obj.mibModel.preferences.updateChecked > 30
                % check for update
                obj.mibModel.preferences.updateChecked = currentDate;
                if isdeployed
                    if ismac()
                        link = 'http://mib.helsinki.fi/web-update/mib2_mac.txt';
                    else
                        link = 'http://mib.helsinki.fi/web-update/mib2_win.txt';
                    end
                else
                    link = 'http://mib.helsinki.fi/web-update/mib2_matlab.txt';
                end
                try
                    urlText = urlread(link, 'Timeout', 4);
                catch err
                    urlText = sprintf('0.305\n<html>\ntest\n</html>\n---Info---\n<html>\n<div style="font-family: arial;">\n<b>The update file has not been detected...</b>\n</html>');
                end
                
                linefeedPos = strfind(urlText, sprintf('\n'));
                availableVersion = str2double(urlText(1:linefeedPos(1)));
                index1 = strfind(obj.mibVersion, 'ver.');
                index2 = strfind(obj.mibVersion, '/');
                currentVersion = str2double(obj.mibVersion(index1+4:index2-1));
                if availableVersion - currentVersion > 0
                    anwser = questdlg(sprintf('A new version %f of MIB is available!\nWould you like to download/install it?\n\nYou can always do that later from Menu->Help->Check for Update', availableVersion),'New version', 'Update now', 'Later', 'Update');
                    if strcmp(anwser, 'Update now')
                        obj.startController('mibUpdateCheckController', obj);
                    end
                end
            end
            % add callbacks for keys
            obj.mibView.handles.mibGUI.WindowKeyPressFcn = (@(hObject, eventdata, handles) obj.mibGUI_WindowKeyPressFcn(eventdata));   % turn ON callback for the keys
            obj.mibView.handles.mibGUI.WindowKeyReleaseFcn = (@(hObject, eventdata) obj.mibGUI_WindowKeyReleaseFcn(eventdata));   % turn ON callback for the keys
           
        end
    end
    
    methods (Static)
%         function ViewListner_Callback(obj, src, evnt)
%             switch src.Name
%                 case {'Id', 'newDatasetSwitch'}     % added in mibChildView
%                     obj.updateGuiWidgets();
%             end
%         end
        
        function Listner2_Callback(obj, src, evnt)
            switch evnt.EventName
                case 'updateId'
                    obj.updateGuiWidgets();
                case 'newDataset'
                    if ismember('Parameter', fieldnames(evnt))
                        obj.updateAxesLimits('resize', evnt.Parameter);
                    else
                        obj.updateAxesLimits('resize');
                    end
                    obj.updateGuiWidgets();
                    obj.mibModel.newDatasetSwitch = abs(obj.mibModel.newDatasetSwitch) - 1;
                case 'plotImage'
                    if ismember('Parameter', fieldnames(evnt))
                        if isa(evnt.Parameter, 'double')   % if number, use evnt.Parameter as resize switch in plotImage
                            obj.plotImage(evnt.Parameter);
                        else                            % if number of dimensions > 1, use evnt.Parameter as sImgIn, a preview image to show in mibView.handles.mibImageAxes
                            obj.plotImage(0, evnt.Parameter);
                        end
                    else
                        obj.plotImage(0);
                    end
                case 'updateLayerSlider'
                    obj.mibView.handles.mibChangeLayerEdit.String = evnt.Parameter;
                    obj.mibChangeLayerEdit_Callback(evnt.Parameter);
                case 'updateTimeSlider'
                    obj.mibView.handles.mibChangeTimeEdit.String = evnt.Parameter;
                    obj.mibChangeTimeEdit_Callback(evnt.Parameter);                    
                case 'showMask'
                    obj.mibView.handles.mibMaskShowCheck.Value = 1;
                    obj.mibMaskShowCheck_Callback();
                case 'showModel'
                    obj.mibView.handles.mibModelShowCheck.Value = 1;
                    obj.mibModelShowCheck_Callback();
            end
        end
    end
    
end