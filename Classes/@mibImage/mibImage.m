classdef mibImage < matlab.mixin.Copyable    
    % classdef mibImage < matlab.mixin.Copyable    
    % a basic class to contain individual datasets loaded in MIB. This
    % class is ruled by the mibModel class
    
    % Copyright (C) 26.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    
    
    properties
        axesX
        % a vector [min, max] with minimal and maximal coordinates of
        % the axes X of the 'mibView.handles.mibImageAxes' axes; use @code mibModel.getAxesLimits() @endcode to
        % read this property
        axesY
        % a vector [min, max] with minimal and maximal coordinates of
        % the axes Y of the 'mibView.handles.mibImageAxes' axes; use @code mibModel.getAxesLimits() @endcode to
        % read this property
        blockModeSwitch
        % a variable to hold a status of the block mode (mibView.handles.toolbarBlockModeSwitch), 1 - enabled, 0 - disabled
        colors
        % number of color channels
        current_yxz
        % a vector to remember last selected slice number of each 'yx', 'zx', 'zy' planes,
        % @note dimensions: @code [1 1 1] @endcode
        depth
        % number of stacks in the dataset
        defaultAnnotationText
        % default test for the annotations
        height
        % image height, px
        hLabels
        % a handle to class to keep annotations
        hMeasure
        % a handle to class to keep measurements
        hROI
        % handle to ROI class, @b mibRoiRegion
        img
        % a cell array to keep the 'Image' layer. The layer img{1} has
        % image in full resolution, img{2} - bin2, img{3} - bin4
        % @note The 'Image' layer dimensions: @code [1:height, 1:width, 1:colors 1:depth, 1:time] @endcode
        lutColors
        % a matrix with LUT colors [1:colorChannel, R G B], (0-1)
        magFactor
        % magnification factor for the datasets, 1=100%,
        % 1.5 = 150%; use @code mibModel.getMagFactor() @endcode to read this property
        maskExist
        % a switch to indicate presense of the 'Mask' layer. Can be 0 (no
        % model) or 1 (model exist)
        maskImg
        % a property to keep the 'Mask' layer
        % @note The 'Mask' dimensions are: @code [1:height, 1:width, 1:no_stacks] @endcode
        % @note When the imageData.model_type == ''uint6'', imageData.maskImg = NaN
        maskImgFilename
        % file name of the 'Mask' layer image
        maskStat
        % Statistics for the 'Mask' layer with the 'PixelList' info returned by 'regionprops' Matlab function
        meta
        % information about the dataset, an instance of the 'containers'.'Map' class
        % Default keys:
        % @li @b ColorType - a string witg type of colors - grayscale, truecolor, hsvcolor, indexed
        % @li @b ImageDescription - ''''
        % @li @b Filename - ''none.tif''
        % @li @b SliceName - @em [optional] a cell array with names of the slices; for combined Z-stack, it is a name of the file that corresponds to the slice. Dimensions of the array should be equal to the  obj.no_stacks
        % @li @b Height
        % @li @b Width
        % @li @b Depth
        % @li @b Colors
        % @li @b Time
        model
        % @em model is a property to keep the 'Model' layer
        % @note The model dimensions are @code [1:height, 1:width, 1:no_stacks] @endcode
        modelFilename
        % @em modelFilename is a property to keep filename of the 'Model' layer
        modelExist
        % a switch to indicate presense of the 'Model' layer. Can be 0 (no
        % model) or 1 (model exist)
        modelMaterialColors
        % a matrix of colors [0-1] for materials of the 'Model', [materialIndex, R G B]
        modelMaterialNames
        % an array of strings to define names of materials of the 'Model'
        modelType
        % type for models
        % @li 0 - an overlay type model with indices from -128 to 128
        % @li 63 - maximum  63 material for the model
        % @li 255 - maximum 255 material for the model
        % @li 65535 - maximum 65535 material for the model
        modelVariable
        % @em modelVariable is a variable name in the mat-file to keep the 'Model' layer'; default: 'mibModel'
        orientation
        % Orientation of the currently shown dataset,
        % @li @b 4 = the 'yz' plane, @b default
        % @li @b 1 = the 'zx' plane
        % @li @b 2 = the 'zy' plane
        pixSize
        % a structure with diminsions of voxels, @code .x .y .z .t .tunits .units @endcode
        % the fields are
        % @li .x - physical width of a pixel
        % @li .y - physical height of a pixel
        % @li .z - physical thickness of a pixel
        % @li .t - time between the frames for 2D movies
        % @li .tunits - time units
        % @li .units - physical units for x, y, z. Possible values: [m, cm, mm, um, nm]
        selectedAddToMaterial
        % index of selected Add to Material, where the Selection layer
        % should be targeted, assigned in mibView.handles.mibSegmentationTable
        selectedColorChannel
        % color channel selected in the Color channel combo box of the
        % Selection panel. 0 - all colors, 1, 2 - 1st, 2nd ...
        selectedMaterial
        % index of material selected in the
        % mibView.handles.mibSegmentationTable: @b 1 - Mask; @b 2 -
        % Exterior; @b 3 - first material of the model, @b 4 - second
        % material etc
        selectedROI
        % a vector of indeces (as stored in mibRoiRegion class) of the
        % selected ROI in the mibView.handles.mibRoiList table; -1 -> roi is not shown; [1, 3] -> first and third...
        selection
        % a property to keep the Selection layer
        % @note The selection dimensions: @code [1:height, 1:width, 1:no_stacks] @endcode
        % @note When the imageData.model_type == ''uint6'', imageData.selection = NaN
        slices 
        % coordinates of the shown part of the dataset
        % @note dimensions are @code ([height, width, color, depth, time],[min max]) @endcode
        % @li (1,[min max]) - height
        % @li (2,[min max]) - width
        % @li (3,[min max]) - colors , array of color channels to show, for example [1, 3, 4]
        % @li (4,[min max]) - z - value
        % @li (5,[min max]) - t - time point
        time
        % number of time points in the dataset
        viewPort    
        % a structure with viewing parameters:
        % @li .min - a vector with minimal value for intensity stretching for each color channel
        % @li .max - a vector with maximal value for intensity stretching for each color channel
        % @li .gamma a vector with gamma factor for contrast adjustment for each color channel
        volren
        % a structure with parameters for the volume rendering the fields are
        % @li .show - a switch show or not the volume rendering
        % @li .viewer_matrix - a viewer matrix generated from the Rotation, Translation and Scaling vectors using makeViewMatrix function
        % @li .previewScale - scaledown factor for dataset preview during volren
        % @li .previewImg - scaled down image
        % @li .showFullRes - switch whether or not render image in full resolution or just preview
        width
        % image width, px
    end
    
    properties (SetObservable)

    end
    
    methods
        % declaration of functions in the external files, keep empty line in between for the doc generator
        result = addColorChannel(obj, img, channelId, lutColors)        % Add a new color channel to the existing dataset
        
        clearContents(obj, img, meta, disableSelection)        % set all elements of the class to default values
        
        clearMask(obj, height, width, z)        % clear the 'Mask' layer. It is also possible to specify the area where the 'Mask' layer should be cleared
        
        clearSelection(obj, height, width, z, t, blockModeSwitch)        % Clear the 'Selection' layer. It is also possible to specify the area where the Selection layer should be cleared.
        
        status = convertImage(obj, format)  % Convert image to specified format: 'grayscale', 'truecolor', 'indexed' and 'uint8', 'uint16', 'uint32' class
        
        convertModel(obj, type)        % Convert model from obj.modelType==63 to obj.modelType==255 and other way around
        
        copyColorChannel(obj, channel1, channel2)        % Copy intensity from the first color channel (@em channel1) to the position of the second color channel (@em channel2)
        
        result = copySlice(obj, sliceNumberFrom, sliceNumberTo, orient)        % Copy specified slice from one part of the dataset to another
        
        createModel(obj, model_type)        % Create an empty model: allocate memory for a new model
        
        cropDataset(obj, cropF)        % Crop image and all corresponding layers of the opened dataset
        
        deleteColorChannel(obj, channel1)        % Delete specified color channel from the dataset
        
        result = deleteSlice(obj, sliceNumber, orient)        % Delete specified slice from the dataset
        
        generateModelColors(obj)        % Generate list of colors for materials of a model
        
        bb = getBoundingBox(obj)        % Get Bounding box info as a vector [xmin, width, ymin, height, zmin, thickness]
        
        [yMin, yMax, xMin, xMax] = getCoordinatesOfShownImage(obj)        % return minimal and maximal coordinates (XY) of the image that is currently shown
        
        slice_no = getCurrentSliceNumber(obj)        % Get slice number of the currently shown image
        
        timePnt = getCurrentTimePoint(obj)        % Get time point of the currently shown image
        
        dataset = getData(obj, type, orient, col_channel, options, custom_img)        % get dataset from the class
        
        [height, width, color, depth, time] = getDatasetDimensions(obj, type, orient, color, options)        % Get dimensions of the dataset
        
        bb = getROIBoundingBox(obj, roiIndex)        % return the bounding box info for the ROI at the current orientation
        
        [totalSize, imSize] = getDatasetSizeInBytes(obj)        % Get size of the loaded dataset in bytes
        
        [labelsList, labelPositions, indices] = getSliceLabels(obj, sliceNumber, timePoint)        % Get list of labels (mibImage.hLabels) shown at the specified slice
        
        insertEmptyColorChannel(obj, channel1)        % Insert an empty color channel to the specified position
        
        insertSlice(obj, img, insertPosition, meta)        % Insert a slice or a dataset into the existing volume
        
        invertColorChannel(obj, channel1)        % Invert color channel of the dataset
        
        moveMaskToSelectionDataset(obj, action_type, options)        % move the Mask layer to the Selection layer
        
        moveModelToMaskDataset(obj, action_type, options)        % Move the selected Material to the Mask layer
        
        moveModelToSelectionDataset(obj, action_type, options)        % Move the selected Material to the Selection layer
        
        moveSelectionToMaskDataset(obj, action_type, options)        % Move the Selection layer to the Mask layer
        
        moveSelectionToModelDataset(obj, action_type, options)        % Move the Selection layer to the Model layer
        
        moveView(obj, x, y, orient)        % Center the image view at the provided coordinates: x, y
        
        replaceImageColor(obj, type, color_id, channel_id, slice_id, time_pnt)        % replace image intensities in the @em Masked or @em Selected areas with new intensity value
        
        rotateColorChannel(obj, channel1)        % Rotate color channel of the dataset
        
        result = setData(obj, type, dataset, orient, col_channel, options)        % update contents of the class
        
        swapColorChannels(obj, channel1, channel2)        % Swap two color channels of the dataset
        
        transpose(obj, new_orient)        % change orientation of the image to the XY, XZ, or YZ plane.
        
        updateBoundingBox(obj, newBB, xyzShift, imgDims)        % Update the bounding box info of the dataset
        
        updateDisplayParameters(obj)        % Update display parameters for visualization (mibImage.viewPort structure)
        
        updateImgInfo(obj, addText, action, entryIndex)        % Update action log
        
        function obj = mibImage(img, meta, modelType)
            % obj = mibImage(img, meta, modelType)
            % mibImage class constructor
            %
            % Constructor for the mibImage class. Create a new instance of
            % the class with default parameters
            %
            % Parameters:
            % img: a new 2D-5D image stack
            % meta: a 'containers'.'Map' class with parameters of the dataset, can be @e []
            % modelType: an integer that defines type of the model to use: 63 (default) or 255, can be @e []
            
            if nargin < 3; modelType = []; end
            if nargin < 2; meta = []; end
            if nargin < 1; img = []; end
            
            if isempty(modelType)
                obj.modelType = 63;
            else
                if ismember(modelType, [63 255]) == 0
                    errordlg('Wrong model type, please use a number 63 or 255 for the modelType parameter during initialization of mibImage');
                    return;
                end
                obj.modelType = modelType;
            end
            
            obj.defaultAnnotationText = 'Feature 1';
            
            if isempty(img) 
                obj.clearContents();
            else
                obj.clearContents(img, meta);
            end
        end
    end
end