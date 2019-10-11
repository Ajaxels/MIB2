classdef mibModel < handle
    % classdef mibModel < handle
    % the main model class of MIB
    
    % Copyright (C) 04.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    
    properties 
        I
        % variable for keeping instances of mibImage
        maxId
        % maximal number of mibImage instances
        myPath
        % current working directory
        U
        % variable for Undo history
        connImaris
        % a handle to Imaris connection
        disableSegmentation
        % a switch 0/1 to disable segmentation tools while for example modifying ROIs
        displayedLutColors
        % a matrix with the currently shown colors for the color channels (updated in mibController.redrawMibChannelMixerTable function)
        mibAnnMarkerEdit
        % a string with the mode to show the annotation: 'marker', 'label', 'value', 'label + value' (@em default)
        mibAnnValueEccentricCheck
        % enable value-eccentric annotations, @b 0 - annotation text first,
        % value second; @b 1 - annotation value first, text - second
        mibAnnValuePrecision
        % precision of annotation values, an integer from 0 and above
        mibHideImageCheck
        % define whether or not dispay the image layer (used in obj.getRGBimage)
        % a status of mibCpontroller.mibView.handles.mibHideImageCheck.Value
        mibLiveStretchCheck
        % define whether or not stretch the image intensities (used in obj.getRGBimage) a status of mibCpontroller.mibView.handles.mibLiveStretchCheck.Value
        mibMaskShowCheck
        % define whether or not dispay the mask layer (used in obj.getRGBimage) a status of mibCpontroller.mibView.handles.mibMaskShowCheck.Value
        mibModelShowCheck
        % define whether or not dispay the model layer (used in obj.getRGBimage) a status of mibCpontroller.mibView.handles.mibModelShowCheck.Value 
        mibPrevId
        % id of the previously selected mibModel container
        mibShowAnnotationsCheck
        % show or not the annotations
        mibShowLines3DCheck
        % show or not 3D lines
        mibSegmShowTypePopup
        % type of model visualization: @b 1 - filled; @b 2 - contour
        sessionSettings
        % a structure with settings for some tools used during the current session of MIB
        % .automaticAlignmentOptions -> a structure used in mibAlignmentController
        % .guiImages - CData for images to be shown on some buttons
        storedSelection
        % a buffer to store selection with press of Ctrl+C button, and restore with Ctrl+V
        % @note dimensions are @code {1}[1:height, 1:width] or [] @endcode
        preferences
        % a structure with program preferences
        showAllMaterials
        % a switch to show all materials of the model, or only a single one; defined in mibView.handles.mibSegmentationTable
    end
    
    properties (SetObservable)
        Id
        % id of the currently shown dataset    
        newDatasetSwitch
        % a switch 0/1 which is changed when a new dataset is opened (updated in mibController.Listner2_Callback)
    end
        
    events
        changeSlice
        % change of a slice number using the slider
        changeTime
        % change of a time point using the slider
        newDataset
        % loaded or imported a new dataset
        plotImage
        % ask to redraw the image from mibController
        setData
        % when the set data method was used
        showMask
        % an event that enables the obj.mibController.mibView.handles.mibMaskShowCheck.Value
        showModel
        % an event that enables the
        % obj.mibController.mibView.handles.mibModelShowCheck.Value;
        % @code
        % eventdata = ToggleEventData(1);   // show the model
        % notify(obj.mibModel, 'showModel', eventdata);
        % @endcode
        stopProtocol
        % stop batch protocol from execution
        syncBatch
        % synchromize structure for batch actions
        undoneBackup
        % when the undo is triggered
        updateId   
        % updating Id
        updateImgInfo
        % meta data was has been updated, works via obj.getImageMethod
        updatedAnnotations
        % event that the annotation list has been updated for use with mibAnnotationsController
        updatedLines3D
        % event that the lines3D class was updated for use with mibLines3DController
        updateROI
        % event after change number of ROIs
        updateGuiWidgets
        % event after update of GuiWidgets of mibController
        updateLayerSlider
        % event to trigger update of mibView.handles.mibChangeLayerSlider based on provided value, see mibAnnotationController.tableContextMenu_cb
        updateTimeSlider
        % event to trigger update of mibView.handles.mibTimeSlider based on provided value, see mibAnnotationController.tableContextMenu_cb
    end
    
    methods
        % declaration of functions in the external files, keep empty line in between for the doc generator
        
        BatchOptOut = addFrame(obj, BatchOpt)   % add a frame around the dataset
        
        clearMask(obj, BatchOptIn)          % clear the Mask layer
        
        clearSelection(obj, sel_switch, BatchOptIn)  % clear the Selection layer
        
        colorChannelActions(obj, mode, channel1, channel2, BatchOptIn)  % handling various color channel operations
        
        contentAwareFill(obj, BatchOptIn)   % content aware fill
        
        contrastCLAHE(obj, mode, colCh)        % Do CLAHE Contrast-limited adaptive histogram equalization for the dataset
        
        contrastNormalization(obj, mode, BatchOptIn) % Normalize contrast between the layers of the dataset
        
        [xOut, yOut] = convertDataToMouseCoordinates(obj, x, y, mode, magFactor)        % Convert coordinates of a pixel in the dataset to the coordinates of the mibView.handles.mibImageView axes
        
        [xOut, yOut, zOut, tOut] = convertMouseToDataCoordinates(obj, x, y, mode, permuteSw)        % Convert coordinates under the mouse cursor to the coordinates of the dataset
        
        convertModel(obj, ModelType, BatchOptIn)    % convert model to the specified ModelType 
        
        copySwapSlice(obj, SourceSlice, TargetSlice, mode, BatchOptIn)      % Copy/swap slice(s) within the dataset
        
        createModel(obj, ModelType, ModelMaterialNames, BatchOptIn)         % Create a new model
        
        deleteSlice(obj, orientation, sliceNumber, BatchOptIn)    % delete a slice from the dataset
        
        dilateImage(obj, BatchOptIn)   % dilate image
        
        erodeImage(obj, BatchOptIn)    % erode image
        
        fillSelectionOrMask(obj, sel_switch, type, BatchOptIn)  % fill holes for selection or mask layers
        
        [axesX, axesY] = getAxesLimits(obj, id)        % get axes limits for the currently shown or id dataset
        
        slice = getData2D(obj, type, slice_no, orient, col_channel, options, custom_img)        % get 2D dataset with colors 
        
        dataset = getData3D(obj, type, time, orient, col_channel, options, custom_img)        % Get the a 3D dataset with colors: height:width:colors:depth
        
        dataset = getData4D(obj, type, orient, col_channel, options, custom_img)        % Get the a 4D dataset with colors: height:width:colors:depth:time
        
        varargout = getImageMethod(obj, methodName, id, varargin)        % run desired method of the mibImage class
        
        propertyValue = getImageProperty(obj, propertyName, id)        % get desired property for the currently shown or id dataset
        
        magFactor = getMagFactor(obj, id)        % get magnification for the currently shown or id dataset
        
        pixSize = getPixSize(obj, id)        % get pixSize structure for the currently shown or id dataset
        
        [imgRGB, imgRAW] = getRGBimage(obj, options, sImgIn)        % Generate RGB image from all layers that have to be shown on the screen
        
        imgRGB = getRGBvolume(obj, img, options)        % Generate RGB volume rendering image of the stack
        
        flipDataset(obj, mode, showWaitbar)        % Flip dataset horizontally, vertically or in the Z direction
        
        insertEmptySlice(obj, BatchOptIn)   % Insert an empty slice into the existing volume
        
        interpolateImage(obj, imgType, intType, BatchOptIn)     % interpolate selection, mask or model layer
        
        result = invertImage(obj, mode, colChannel, Options)        % Invert image
        
        loadMask(obj, mask, BatchOptIn)      % load mask from a file or import when mask variable is provided
        
        loadModel(obj, model, BatchOptIn)           % load model from a file or import when model variable is provided
        
        mibDoBackup(obj, type, switch3d, storeOptions)        % store the dataset for Undo
        
        mibImageDeepCopy(obj, toId, fromId)        % copy mibImage class from one container to another; used in mibBufferToggleContext_Callback, duplicate
        
        moveLayers(obj, SourceLayer, DestinationLayer, DatasetType, ActionType, BatchOptIn)  % to move datasets between the layers (image, model, mask, selection)
        
        rotateDataset(obj, mode, showWaitbar)        % Rotate dataset in 90 or -90 degrees
        
        fnOut = saveImageAsDialog(obj, filename, BatchOptIn)        % save image to a file
        
        fnOut = saveMask(obj, filename, BatchOptIn)        % save mask to a file
        
        fnOut = saveModel(obj, filename, BatchOptIn)        % save model to a file
        
        setAxesLimits(obj, axesX, axesY, id)        % set axes limits for the currently shown or id dataset
        
        result = setData2D(obj, type, slice, slice_no, orient, col_channel, options)        % set the 2D slice with colors: height:width:colors to the dataset
        
        result = setData3D(obj, type, dataset, time, orient, col_channel, options)        % set the 3D dataset with colors: height:width:colors:depth to the dataset
        
        result = setData4D(obj, type, dataset, orient, col_channel, options)        % Set complete 4D dataset with colors [height:width:colors:depth:time]
        
        setImageProperty(obj, propertyName, propertyValue, id)        % set desired property for the currently shown or id dataset
        
        setMagFactor(obj, magFactor, id)        % set magnification for the currently shown or id dataset
        
        setPixSize(obj, pixSize, id)        % set pixSize structure for the currently shown or id dataset
        
        smoothImage(obj, type, BatchOptIn)        % smooth 'Mask', 'Selection' or 'Model' layer
        
        transposeDataset(obj, mode, showWaitbar)        % Transpose dataset physically between dimensions
        
        transposeZ2T(obj)        % transpose Z to T dimension
        
        
        function obj = mibModel()
            obj.reset();
        end
        
        function reset(obj)
            obj.maxId = 9;  % define maximal number of datasets (equal to number of mibBufferToggle buttons in the Directory contents panel)
            obj.myPath = '\';   % define working directory
            obj.Id = 1;         % index of the current dataset
            obj.newDatasetSwitch = 0;
            obj.showAllMaterials = 1;   % display all materials of the model
            obj.disableSegmentation = 0;    % disable segmentation switch
            obj.storedSelection = [];   % initialize stored selection
            obj.connImaris = [];    % empty connection to Imaris
            obj.sessionSettings = struct();     % current session settings
            obj.mibPrevId = 1;     % index of the previous dataset
            
            for i=1:obj.maxId   % initialize mibImage 
                obj.I{i}= mibImage();
            end
            obj.U = mibImageUndo();    % create instanse for keeping undo information
        end
    end
    
end