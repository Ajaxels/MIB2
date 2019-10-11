classdef GuiTutorialController < handle
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
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
                case {'changeSlice'}
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = GuiTutorialController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'GuiTutorialGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % check for the virtual stacking mode and close the controller
            if isprop(obj.mibModel.I{obj.mibModel.Id}, 'Virtual') && obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nThis plugin is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
                    'Not implemented');
                obj.closeWindow();
                return;
            end
            
            % resize all elements of the GUI
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            % you may need to replace "obj.View.handles" with tag of any text field of your own GUI
            global Font;
            if ~isempty(Font)
                if obj.View.handles.infoText1.FontSize ~= Font.FontSize ...
                        || ~strcmp(obj.View.handles.infoText1.FontName, Font.FontName)
                    mibUpdateFontSize(obj.View.gui, Font);
                end
            end
            
            obj.updateWidgets();
            
            % obj.View.gui.WindowStyle = 'modal';     % make window modal
            
            % add listner to obj.mibModel and call controller function as a callback
            % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
            
            % option 2: in some situations
            % obj.listener{1} = addlistener(obj.mibModel, 'Id', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
            % obj.listener{2} = addlistener(obj.mibModel, 'newDatasetSwitch', 'PostSet', @(src,evnt) obj.ViewListner_Callback(obj, src, evnt));     % for static
            
            % populate the contents of convertPopup
            obj.View.handles.convertPopup.String = {'uint8', 'uint16'};
            obj.View.handles.cropRadio.Value = 1;
        end
        
        function closeWindow(obj)
            % closing GuiTutorialController window
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
            
            % get information about dataset dimensions in pixels
            options.blockModeSwitch=0;
            [height, width, colors, depth, time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, 0, options);
            % force to switch off the BlockMode to make sure that dimensions of the whole dataset will be returned
            % 'image' - indicates type of the layer to get dimensions (other options: 'model','mask','selection')
            % 4 - forces to return dimensions of the dataset in the original (XY) orientation.
            % 0 - requires to return number of all color channels of the dataset
            
            % populate the edit boxes
            obj.View.handles.xMinEdit.String = '1';
            obj.View.handles.yMinEdit.String = '1';
            % width of the dataset
            obj.View.handles.widthEdit.String = num2str(width);
            % height of the dataset
            obj.View.handles.heightEdit.String = num2str(height);
            
            % populate colorPopup
            colorsList = cell([colors, 1]);     % allocate space
            % generate cell array with color names
            for i=1:colors
                colorsList{i} = sprintf('Channel %d', i);
            end
            % assing the cell array with color names to colorPopup
            obj.View.handles.colorPopup.String = colorsList;
        end
        
        function cropDataset(obj)
            % function cropDataset(obj)
            % crop dataset
            
            % get new dimensions
            x1 = str2double(obj.View.handles.xMinEdit.String);
            y1 = str2double(obj.View.handles.yMinEdit.String);
            width1 = str2double(obj.View.handles.widthEdit.String);
            height1 = str2double(obj.View.handles.heightEdit.String);
            
            % get information about the current dataset dimensions in pixels
            options.blockModeSwitch=0;
            [height, width, colors, depth, time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, 0, options);
            
            % check dimensions
            if x1 < 1 || y1 < 1 || x1+width1-1 > width || y1+height1-1 > height
                % cancel if dimensions are wrong
                errordlg('Please check dimensions for cropping!', 'Wrong dimensions');
                return
            end
            
            % create a waitbar
            wb = waitbar(0, 'Please wait...');
            
            % get the whole dataset, use the getData2D, getData3D,
            % getData4D of mibModel class to obtain 2D, 3D, or 4D dataset
            % the 'image' parameter defines that the image is required
            % The function returns a cell with the image
            % because complete dataset should be cropped, the blockModeSwitch is forced to be 0
            img = obj.mibModel.getData4D('image', NaN, 0, options);
            
            % crop the dataset
            img{1} = img{1}(y1:y1+height-1, x1:x1+width1-1, : , :, :);
            
            % update the image layer
            obj.mibModel.setData4D('image', img, NaN, 0, options);
            
            waitbar(0.5, wb);   % update waitbar
            
            % in addition it is needed to crop the other layers
            % (Selection, Mask and Model).
            % it can be done in a single step when the 63-material type of the model
            % is used (obj.mibModel.I{obj.mibModel.Id}.modelType==63) or one by one
            % when it is 255-material type (obj.mibModel.I{obj.mibModel.Id}.modelType~=63).
            
            if obj.mibModel.I{obj.mibModel.Id}.modelType==63
                list = {'everything'};
            else
                list = {'selection', 'model', 'mask'};
            end
            for layer = 1:numel(list)
                if strcmp(list{layer},'mask') && obj.mibModel.I{obj.mibModel.Id}.maskExist == 0
                    % skip when no mask
                    continue;
                end
                if strcmp(list{layer},'model') && obj.mibModel.I{obj.mibModel.Id}.modelExist == 0
                    % skip when no model
                    continue;
                end
                img = obj.mibModel.getData4D(list{layer}, NaN, NaN, options);
                img{1} = img{1}(y1:y1+height-1, x1:x1+width1-1, :, :);
                % update the layers
                obj.mibModel.setData4D(list{layer}, img, NaN, NaN, options);
                
                waitbar(0.5+.1*layer, wb);  % update waitbar
            end
            
            % update the log text available from MIB->Path panel->Log
            log_text = sprintf('Crop: [x1 x2 y1 y2]: %d %d %d %d', x1, x1+width1-1, y1, y1+height-1);
            obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(log_text);
            
            % during the crop the BoundingBox is changed, so it should be fixed.
            % calculate the shift of the coordinates in the dataset units
            % xyzShift = [x1-1 y1-1 0];
            
            % shift of the bounding box in X
            xyzShift(1) = (x1-1)*obj.mibModel.I{obj.mibModel.Id}.pixSize.x;
            % shift of the bounding box in Y
            xyzShift(2) = (y1-1)*obj.mibModel.I{obj.mibModel.Id}.pixSize.y;
            % shift of the bounding box in Z
            xyzShift(3) = 0;
            % update BoundingBox Coordinates
            obj.mibModel.I{obj.mibModel.Id}.updateBoundingBox(NaN, xyzShift);
            waitbar(1, wb); % update waitbar
            
            % notify MIB that the dataset has been updated
            % see more events in the events section of mibModel.m
            notify(obj.mibModel, 'newDataset');
            % ask MIB to redraw the dataset
            notify(obj.mibModel, 'plotImage');
            
            delete(wb); % delete waitbar
        end
        
        function resizeDataset(obj)
            % function resizeDataset(obj)
            % resize the current dataset
            
            % get new dimensions
            width1 = str2double(obj.View.handles.widthEdit.String);
            height1 = str2double(obj.View.handles.heightEdit.String);
            
            % check dimensions
            if width1 < 1 || height1 < 1
                % cancel if dimensions are wrong
                errordlg('Please check dimensions for resizing!', 'Wrong dimensions');
                return
            end
            wb = waitbar(0, 'Please wait...'); % create a waitbar
            
            % get the whole dataset
            % the 'image' parameter defines that the image is required
            % The function returns a cell with the image
            % because complete dataset should be resized, the blockModeSwitch is forced to be 0
            options.blockModeSwitch = 0;
            img = obj.mibModel.getData4D('image', NaN, 0, options);
            % get the current dataset dimensions
            [height, width] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, 0, options);
            
            % allocate memory for the output dataset
            imgOut = zeros([height1, width1, size(img{1}, 3), size(img{1}, 4), size(img{1}, 5)], class(img{1}));
            
            % loop the time dimension
            for t=1:size(img{1},5)
                % loop the depth dimension
                for slice = 1:size(img{1},4)
                    imgOut(:,:,:,slice,t) = ...
                        imresize(img{1}(:,:,:,slice,t),[height1, width1],'bicubic');
                end
            end
            waitbar(0.5, wb);   % update waitbar
            
            % update the image
            obj.mibModel.setData4D('image', imgOut, NaN, 0, options);
            
            % in addition it is needed to resize the other layers
            % (Selection, Mask and Model).
            % it can be done in a single step when the 63-material type of the model
            % is used (obj.mibModel.I{obj.mibModel.Id}.modelType==63) or one by one
            % when it is 255-material type (obj.mibModel.I{obj.mibModel.Id}.modelType~=63).
            
            if obj.mibModel.I{obj.mibModel.Id}.modelType==63
                list = {'everything'};
            else
                list = {'selection', 'model', 'mask'};
            end
            for layer = 1:numel(list)
                if strcmp(list{layer},'mask') && ...
                        obj.mibModel.I{obj.mibModel.Id}.maskExist == 0
                    % skip when no mask
                    continue;
                end
                if strcmp(list{layer},'model') && ...
                        obj.mibModel.I{obj.mibModel.Id}.modelExist == 0
                    % skip when no model
                    continue;
                end
                % get the dataset
                img = obj.mibModel.getData4D(list{layer}, NaN, NaN, options);
                
                % allocate memory for the output dataset
                imgOut = zeros([height1, width1, size(img{1},3), size(img{1},4)], class(img{1}));
                for t=1:size(img{1},4)  % loop the time dimension
                    for slice = 1:size(img{1},3)    % loop the depth dimension
                        % it is important to use nearest resizing method for these layers
                        imgOut(:,:,slice,t) = ...
                            imresize(img{1}(:,:,slice,t),[height1, width1],'nearest');
                    end
                end
                % update the layers
                obj.mibModel.setData4D(list{layer}, img, NaN, NaN, options);
                waitbar(0.5+.1*layer, wb);  % update waitbar
            end
            
            % generate log text with description of the performed actions, the log can be accessed with the Log button in the Path
            % panel
            log_text = sprintf('Resized to (height x width) %d x %d', height1, width1);
            obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(log_text);
            
            % update pixel size for the x and y. The z was not changed
            % get current pixel size
            pixSize = obj.mibModel.I{obj.mibModel.Id}.pixSize;
            % update x
            pixSize.x = ...
                obj.mibModel.I{obj.mibModel.Id}.pixSize.x/width1*width;
            % update y
            pixSize.y = ...
                obj.mibModel.I{obj.mibModel.Id}.pixSize.y/height1*height;
            % update pixels size for the dataset
            obj.mibModel.I{obj.mibModel.Id}.updatePixSizeResolution(pixSize)
            
            waitbar(1, wb); % update waitbar
            
            % notify MIB that the dataset has been updated
            % see more events in the events section of mibModel.m
            notify(obj.mibModel, 'newDataset');
            % ask MIB to redraw the dataset
            notify(obj.mibModel, 'plotImage');
            
            delete(wb); % delete waitbar
        end
        
        function convertDataset(obj)
            % function convertDataset(obj)
            % convert dataset to a different image class
            
            % get class to convert image to
            List = obj.View.handles.convertPopup.String;
            val = obj.View.handles.convertPopup.Value;
            convertTo = List{val};
            
            % get the dataset
            % the 'image' parameter defines that the image is required
            % The function returns a cell with the image
            % because complete dataset should change its clas, the blockModeSwitch is forced to be 0
            options.blockModeSwitch = 0;
            img = obj.mibModel.getData4D('image', 4, 0, options);
            classFrom = class(img{1});  % get current image class
            
            % check whether the destination is the same class as the
            % current
            if strcmp(classFrom, convertTo)
                warndlg(sprintf('The current dataset is already %s class!', convertTo));
                return;
            end
            wb = waitbar(0, 'Please wait...');
            if strcmp(convertTo, 'uint16')  % convert to uint16 class
                % calculate stretching coefficient
                coef = double(intmax('uint16')) / double(intmax(class(img{1})));
                
                % convert stretch dataset to uint16
                img{1} = uint16(img{1})*coef;
                
            else                            % convert to uint8 class
                % calculate stretching coefficient
                coef = double(intmax('uint8')) / double(intmax(class(img{1})));
                
                % convert stretch dataset to uint16
                img{1} = uint8(img{1}*coef);
            end
            waitbar(0.5, wb);
            % update dataset in MIB
            obj.mibModel.setData4D('image', img, 4, 0, options);
            
            % when the image class has been changed it is important to update the handles.h.Img{handles.h.Id}.I.viewPort structure.
            obj.mibModel.I{obj.mibModel.Id}.updateDisplayParameters();
            
            % generate log text with description of the performed actions, the log can be accessed with the Log button in the Path
            % panel
            log_text = sprintf('Converted from %s to %s', classFrom, class(img{1}));
            obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(log_text);
            waitbar(1, wb);
            % ask MIB to update own widgets, because it is required to
            % update a checkbox in MIB->Menu->Image->Mode
            notify(obj.mibModel, 'updateId');
            
            % ask MIB to update the shown image
            notify(obj.mibModel, 'plotImage');
            delete(wb);     % delete waitbar
        end
        
        function invertDataset(obj)
            % function invertDataset(obj)
            % invert the dataset
            
            wb = waitbar(0, 'Please wait...');
            
            % get the color channel to invert
            colCh = obj.View.handles.colorPopup.Value;
            
            % in this function we will use getData2D function to show how
            % to minimize memory consumption
            
            % get the current dataset dimensions
            [height, width, colors, depth, time] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image');
            
            % specify the roiId option: when ROIs are shown the dataset
            % will be not the full dataset, but only the areas that are
            % inside the ROI areas
            options.roiId = [];
            
            % do backup if time dimension is 1
            % after backup the previous state can be restored using the
            % Ctrl+Z shortcut
            if time == 1
                storeOptions.roiId = [];    % backup only the ROI areas
                obj.mibModel.mibDoBackup('image', 1, storeOptions);
            end
            
            index = 1;  % define dataset counter for the waitbar
            maxIndex = depth*time;  % find the maximal number of images to process
            % loop across the time dimension
            for t=1:time
                % loop across the depth dimension
                for z=1:depth
                    % get 2D slice
                    img = obj.mibModel.getData2D('image', z, NaN, colCh, options);
                    % find maximal point of the dataset
                    maxInt = intmax(class(img{1}));
                    % loop across the ROIs
                    for i=1:numel(img)
                        % invert the image
                        img{i} = maxInt - img{i};
                    end
                    obj.mibModel.setData2D('image', img, z, NaN, colCh, options);
                    waitbar(index/maxIndex, wb);
                    index = index + 1;
                end
            end
            
            % update the log text
            log_text = 'Invert image';
            obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(log_text);
            % ask MIB to update the shown image
            notify(obj.mibModel, 'plotImage');
            delete(wb); % delete waitbar
        end
    end
end