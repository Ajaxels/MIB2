classdef mibImage < matlab.mixin.Copyable    
    % classdef mibImage < matlab.mixin.Copyable    
    % a basic class to contain individual datasets loaded in MIB. This
    % class is ruled by the mibModel class
    
    % Copyright (C) 26.12.2016, Ilya Belevich, University of Helsinki (ilya.belevich -at- helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    
    
    properties
        % properties of the class
        axesX
        % a vector [min, max] with minimal and maximal coordinates of
        % the axes X of the 'mibView.handles.mibImageAxes' axes; use @code mibModel.getAxesLimits() @endcode to
        % read this property
        axesY
        % a vector [min, max] with minimal and maximal coordinates of
        % the axes Y of the 'mibView.handles.mibImageAxes' axes; use @code mibModel.getAxesLimits() @endcode to
        % read this property
        BioFormatsMemoizerMemoDir
        % path to directory where BioFormats Memoizer is storing memo files
        blockModeSwitch
        % a variable to hold a status of the block mode (mibView.handles.toolbarBlockModeSwitch), 1 - enabled, 0 - disabled
        colors
        % number of color channels
        current_yxz
        % a vector to remember last selected slice number of each 'yx', 'zx', 'zy' planes,
        % @note dimensions: @code [1 1 1] @endcode
        dim_yxczt
        % a matrix with dimensions of the dataset [height, width, colors, depth, time]
        % equal to size obj.img{1} for non-virtual datasets
        depth
        % number of stacks in the dataset
        defaultAnnotationText
        % default text for the annotations
        defaultAnnotationValue
        % default value for the annotations
        disableSelection
        % a switch (0/1) to enable or not the selection, mask, model layers
        fixSelectionToMask
        % a switch indicating the value of the obj.mibView.handles.mibMaskedAreaCheck
        fixSelectionToMaterial
        % a switch indicating the value of the obj.mibView.handles.mibSegmSelectedOnlyCheck
        height
        % image height, px
        hLabels
        % a handle to class for keeping annotations
        hLines3D
        % a handle to class for keeping 3D Lines and skeletons
        hMeasure
        % a handle to class to keep measurements
        hROI
        % handle to ROI class, @b mibRoiRegion
        img
        % a cell array to keep the 'Image' layer. The layer img{1} has
        % image in full resolution, img{2} - bin2, img{3} - bin4
        % @note The 'Image' layer dimensions: @code [1:height, 1:width, 1:colors 1:depth, 1:time] @endcode
        lastSegmSelection
        % a vector with 2 elements of two previously selected materials for use with the 'e' key shortcut
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
        % @li @b MaxInt - maximal number that can be stored in the image container (255 for 8bit, 65535 for 16 bit)
        % @li @b imgClass - a string with image class, 'uint8', 'uint16', 'uint32';
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
        % @li 4294967295 - maximum 4294967295 material for the model
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
        % should be targeted, assigned in the AddTo column of the mibView.handles.mibSegmentationTable
        % @b 1 - Mask; @b 2 - Exterior; @b 3 - first material of the model, @b 4 - second material etc
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
        useLUT
        % use or not LUT for visualization of image, a number @b 0 - do not use; @b 1 - use a status of mibCpontroller.mibView.handles.mibLutCheckbox.Value
        viewPort    
        % a structure with viewing parameters:
        % @li .min - a vector with minimal value for intensity stretching for each color channel
        % @li .max - a vector with maximal value for intensity stretching for each color channel
        % @li .gamma a vector with gamma factor for contrast adjustment for each color channel
        Virtual
        % a structure to work with virtual stacks
        % @li filenames -  a cell array with filenames for each reader,
        % needed for deep copy of bio-format readers
        % @li .objectType - a cell array that defines type of the reader: 'bioformats', 'matlab.hdf5'
        % @li .readerId - define readerId, which is a vector with length equal to the total
        %       number of slices. Each element identifies the reader index for
        %       desired slice number of the combined dataset:
        %       readerId(5) = 3; indicates that slice number 5 is stored in
        %       the reader 3. Obtained from the 'Virtual_readerId' key of
        %       the metadata
        % @li .seriesName - a cell array that defines series name for each file: numbers for bioformats; strings for hdf5
        % @li .slicesPerFile - an array that specifies how many slices each
        %       reader contains. Obtained from the 'Virtual_slicesPerFile' key of
        %       the metadata
        % @li .virtual - a main switch, when = 1, indicates that the
        % dataset is in the virtual stack mode, i.e. disk resident, which
        % is opposed to the normal memory resident mode
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
    
%     properties (SetAccess = private, GetAccess = private)
%         listener
%         % a cell array with handles to listeners
%     end
    
    %properties (SetObservable)
    %    Virtual
    %end
    
%     events
%         closeVirtualDatasets
%     end
    
    methods 
        % declaration of functions in the external files, keep empty line in between for the doc generator

        output = addColorChannel(obj, img, channelId, lutColors)        % Add a new color channel to the existing dataset
        
        output = addFrameToImage(obj, BatchOpt)        %  Add a frame around the dataset
        
        bbShiftXY = addStack(obj, I2, shiftX, shiftY, options)  % Add I2 to mibImage and shift stacks according to shiftX, shiftY translation coefficients
        
        clearContents(obj, img, metaIn, disableSelection)        % set all elements of the class to default values
        
        clearMask(obj, options)        % clear the 'Mask' layer. It is also possible to specify the area where the 'Mask' layer should be cleared
        
        clearSelection(obj, height, width, z, t, blockModeSwitch)        % Clear the 'Selection' layer. It is also possible to specify the area where the Selection layer should be cleared.
        
        closeVirtualDataset(obj) % Close opened virtual dataset readers. Used in the 'closeVirtualDatasets' % event of the mibImage class
        
        status = convertImage(obj, format, options)  % Convert image to specified format: 'grayscale', 'truecolor', 'indexed' and 'uint8', 'uint16', 'uint32' class
        
        convertModel(obj, type)        % Convert model from obj.modelType==63 to obj.modelType==255 and other way around
        
        PixelIdxList = convertPixelIdxListCrop2Full(obj, PixelIdxListCrop, options)  % convert PixelIdxList of the cropped dataset to PixelIdxList of the full  dataset, only for 4D datasets (h, w, depth, time)
        
        [x, y, z] = convertPixelsToUnits(obj, x, y, z)  % convert pixel with x, y, z coordinate to the physical imaging units
        
        [x, y, z] = convertUnitsToPixels(obj, x, y, z)  % convert coordinate in physical units to pixels
        
        copyColorChannel(obj, channel1, channel2, options)        % Copy intensity from the first color channel (@em channel1) to the position of the second color channel (@em channel2)
        
        result = copySlice(obj, sliceNumberFrom, sliceNumberTo, orient, options)        % Copy specified slice from one part of the dataset to another
        
        createModel(obj, model_type, modelMaterialNames)        % Create an empty model: allocate memory for a new model
        
        result = cropDataset(obj, cropF)        % Crop image and all corresponding layers of the opened dataset
        
        deleteColorChannel(obj, channel1, options)       % Delete specified color channel from the dataset
        
        result = deleteSlice(obj, sliceNumber, orient, options)        % Delete specified slice from the dataset
        
        generateModelColors(obj)        % Generate list of colors for materials of a model
        
        bb = getBoundingBox(obj)        % Get Bounding box info as a vector [xmin, width, ymin, height, zmin, thickness]
        
        [yMin, yMax, xMin, xMax, zMin, zMax] = getCoordinatesOfShownImage(obj, transposeTo4)        % return minimal and maximal coordinates (XY) of the image that is currently shown
        
        slice_no = getCurrentSliceNumber(obj)        % Get slice number of the currently shown image
        
        timePnt = getCurrentTimePoint(obj)        % Get time point of the currently shown image
        
        dataset = getData(obj, type, orient, col_channel, options, custom_img)        % get dataset from the class
        
        dataset = getDataVirt(obj, type, orient, col_channel, options, custom_img)        % get virtual dataset from the class
        
        [height, width, color, depth, time] = getDatasetDimensions(obj, type, orient, color, options)        % Get dimensions of the dataset
        
        [totalSize, imSize] = getDatasetSizeInBytes(obj)        % Get size of the loaded dataset in bytes
        
        dataset = getPixelIdxList(obj, type, PixelIdxList, options)     % Get dataset from the list of pixel indices
        
        bb = getROIBoundingBox(obj, roiIndex)        % return the bounding box info for the ROI at the current orientation
        
        index = getSelectedMaterialIndex(obj, target)      % return the index of the currently selected material
        
        [labelsList, labelValues, labelPositions, indices] = getSliceLabels(obj, sliceNumber, timePoint)        % Get list of labels (mibImage.hLabels) shown at the specified slice
        
        insertEmptyColorChannel(obj, channel1, options)       % Insert an empty color channel to the specified position
        
        insertSlice(obj, img, insertPosition, meta, options)        % Insert a slice or a dataset into the existing volume
        
        invertColorChannel(obj, channel1, options)        % Invert color channel of the dataset
        
        moveMaskToModelDataset(obj, action_type, options)   % move the mask layer to the model layer
        
        moveMaskToSelectionDataset(obj, action_type, options)        % move the Mask layer to the Selection layer
        
        moveModelToMaskDataset(obj, action_type, options)        % Move the selected Material to the Mask layer
        
        moveModelToSelectionDataset(obj, action_type, options)        % Move the selected Material to the Selection layer
        
        moveSelectionToMaskDataset(obj, action_type, options)        % Move the Selection layer to the Mask layer
        
        moveSelectionToModelDataset(obj, action_type, options)        % Move the Selection layer to the Model layer
        
        moveView(obj, x, y, orient)        % Center the image view at the provided coordinates: x, y
        
        replaceImageColor(obj, type, color_id, channel_id, slice_id, time_pnt, options)        % replace image intensities in the @em Masked or @em Selected areas with new intensity value
        
        rotateColorChannel(obj, channel1, angle, options)        % Rotate color channel of the dataset
        
        fnOut = saveImageAsDialog(obj, filename, options)   % save image to a file
        
        fnOut = saveMask(obj, filename, options)    % save mask to a file
        
        fnOut = saveModel(obj, filename, options)       % save model to a file
        
        result = setData(obj, type, dataset, orient, col_channel, options)        % update contents of the class
        
        result = setPixelIdxList(obj, type, dataset, PixelIdxList, options)      % update dataset using a vector of values and pixel ids
        
        swapColorChannels(obj, channel1, channel2, options)        % Swap two color channels of the dataset
        
        result = swapSlices(obj, sliceNumberFrom, sliceNumberTo, orient, options)  % Swap specified slices 
        
        newMode = switchVirtualStackingMode(obj, newMode, disableSelection)   % switch on/off the virtual stacking mode
        
        transpose(obj, new_orient)        % change orientation of the image to the XY, XZ, or YZ plane.
        
        updateBoundingBox(obj, newBB, xyzShift, imgDims)        % Update the bounding box info of the dataset
        
        updateDisplayParameters(obj)        % Update display parameters for visualization (mibImage.viewPort structure)
        
        result = updatePixSizeResolution(obj, pixSize)  % Update mibImage.pixelSize, mibImage.meta(''XResolution'') and mibImage.meta(''XResolution'') and mibImage.volren
        
        updateServiceMetadata(obj, metaIn)  % update service metadata of MIB based on obj.img and metaIn
        
        updateSlicesStructure(obj, axesX, axesY)        % Update the slices structure of the dataset from current axesX, axesY
        
        updateImgInfo(obj, addText, action, entryIndex)        % Update action log
        
        function obj = mibImage(img, meta, options)
            % obj = mibImage(img, meta, options)
            % mibImage class constructor
            %
            % Constructor for the mibImage class. Create a new instance of
            % the class with default parameters
            %
            % Parameters:
            % img: a new 2D-5D image stack
            % meta: a 'containers'.'Map' class with parameters of the dataset, can be @e []
            % options: a structure with additional options for the initialization of the instance 
            % .modelType - an integer that defines type of the model to use, 63 (default)
            %   @li 0 - an overlay type model with indices from -128 to 128
            %   @li 63 - maximum  63 material for the model
            %   @li 255 - maximum 255 material for the model
            %   @li 65535 - maximum 65535 material for the model
            %   @li 4294967295 - maximum 4294967295 material for the model
            % .virtual - switch indicating that the dataset should be in the virtual mode,
            %   @li 0 (default) - indicates that the dataset is in the memory mode
            %   @li 1 - indicates that the dataset is in the virtual mode (i.e. the images are not loaded to memory)
            
            if nargin < 3; options = struct(); end
            if nargin < 2; meta = []; end
            if nargin < 1; img = []; end
            
            if ~isfield(options, 'modelType')
                options.modelType = 63; 
            else
                if ismember(options.modelType, [0 63 255 65535 4294967295]) == 0
                    errordlg('Wrong model type, please use one of the following numbers: 0, 63, 255, 65535, 4294967295 for the options.modelType parameter during initialization of mibImage');
                    return;
                end
            end
            if ~isfield(options, 'virtual'); options.virtual = 0; end
            
            obj.modelType = options.modelType;
            obj.Virtual.virtual = options.virtual;
            
            obj.defaultAnnotationText = 'Feature 1';
            obj.defaultAnnotationValue = 1;
            
            if isempty(img) 
                obj.clearContents();
            else
                obj.clearContents(img, meta);
            end
            
            %obj.listener{1} = addlistener(obj, 'Virtual', 'PostSet', @(src,evnt) mibImage.Listner_Callback(obj, src, evnt));     % for static
            %obj.listener{1} = addlistener(obj, 'closeVirtualDatasets', @(src,evnt) mibImage.Listner2_Callback(obj, src, evnt));
            
        end
    end
    
%     methods (Static)
% %         function Listner_Callback(obj, src, evnt)
% %             switch src.Name
% %                 case {'Virtual'}  
% %                     fprintf('Virtual changed: %s\n', toc);
% %                     obj.Virtual
% %             end
% %         end
%         
%         function Listner2_Callback(obj, src, evnt)
%             switch evnt.EventName
%                 case 'closeVirtualDatasets'
%                     obj.closeVirtualDataset();  % close virtual datasets, otherwise files stay locked
%             end
%         end
%     end
    
end