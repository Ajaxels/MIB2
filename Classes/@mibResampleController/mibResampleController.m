classdef mibResampleController  < handle
    % @type mibResampleController class is resposnible for showing the dataset
    % resample window, available from MIB->Menu->Dataset->Resample 
    
	% Copyright (C) 01.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
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
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        height
        width
        color
        depth
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback2(obj, src, evnt)
            switch evnt.EventName
                case 'updateGuiWidgets'
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibResampleController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibResampleGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
				
			obj.updateWidgets();
			
			% add listner to obj.mibModel and call controller function as a callback
             % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
             obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes updateGuiWidgets
        end
        
        function closeWindow(obj)
            % closing mibResampleController  window
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
            % update all widgets of the current window
            
            options.blockModeSwitch = 0;
            [obj.height, obj.width, obj.color, obj.depth] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('image', 4, NaN, options);
            obj.color = numel(obj.color);
            
            obj.View.handles.modelsMethod.String = 'nearest';
            
            obj.View.handles.widthTxt.String = num2str(obj.width);
            obj.View.handles.heightTxt.String = num2str(obj.height);
            obj.View.handles.colorsTxt.String = num2str(obj.color);
            obj.View.handles.depthTxt.String = num2str(obj.depth);
            
            pixSize = obj.mibModel.getImageProperty('pixSize');
            obj.View.handles.pixsizeX.String = sprintf('%f %s', pixSize.x, pixSize.units);
            obj.View.handles.pixsizeY.String = sprintf('%f %s', pixSize.y, pixSize.units);
            obj.View.handles.pixsizeZ.String = sprintf('%f %s', pixSize.z, pixSize.units);
            
            obj.View.handles.dimX.String = num2str(obj.width);
            obj.View.handles.dimY.String = num2str(obj.height);
            obj.View.handles.dimZ.String = num2str(obj.depth);
            obj.View.handles.voxX.String = sprintf('%f', pixSize.x);
            obj.View.handles.voxY.String = sprintf('%f', pixSize.y);
            obj.View.handles.voxZ.String = sprintf('%f', pixSize.z);
            obj.View.handles.percEdit.String = '100';
        end
        
        function editbox_Callback(obj, hObject)
            % function editbox_Callback(obj)
            % callbacks for modification of edit boxes
            %
            % Parameters:
            % hObject: handle to the editbox
            pixSize = obj.mibModel.getImageProperty('pixSize');
            if obj.View.handles.dimensionsRadio.Value
                switch hObject.Tag
                    case 'dimX'
                        val = str2double(hObject.String);
                        ratio = obj.width / val;
                        obj.View.handles.voxX.String = num2str(pixSize.x*ratio);
                        if obj.View.handles.aspectCheck.Value
                            obj.View.handles.dimY.String = num2str(floor(obj.height/ratio));
                            obj.View.handles.voxY.String = num2str(pixSize.y*ratio);
                        end
                    case 'dimY'
                        val = str2double(hObject.String);
                        ratio = obj.height / val;
                        obj.View.handles.voxY.String = num2str(pixSize.y*ratio);
                        if obj.View.handles.aspectCheck.Value
                            obj.View.handles.dimX.String = num2str(floor(obj.width/ratio));
                            obj.View.handles.voxX.String = num2str(pixSize.x*ratio);
                        end
                    case 'dimZ'
                        val = str2double(hObject.String);
                        ratio = obj.depth / val;
                        obj.View.handles.voxZ.String = num2str(pixSize.z*ratio);
                end
            elseif obj.View.handles.voxelsRadio.Value
                switch hObject.Tag
                    case 'voxX'
                        val = str2double(hObject.String);
                        ratio = val / pixSize.x;
                        obj.View.handles.dimX.String = num2str(floor(obj.width/ratio));
                        if obj.View.handles.aspectCheck.Value
                            obj.View.handles.dimY.String = num2str(floor(obj.height/ratio));
                            obj.View.handles.voxY.String = num2str(pixSize.y*ratio);
                        end
                    case 'voxY'
                        val = str2double(hObject.String);
                        ratio = val / pixSize.y;
                        obj.View.handles.dimY.String = num2str(floor(obj.height/ratio));
                        if obj.View.handles.aspectCheck.Value
                            obj.View.handles.dimX.String = num2str(floor(obj.width/ratio));
                            obj.View.handles.voxX.String = num2str(pixSize.x*ratio);
                        end
                    case 'voxZ'
                        val = str2double(hObject.String);
                        ratio = val / pixSize.z;
                        obj.View.handles.dimZ.String = num2str(floor(obj.depth/ratio));
                end
            elseif obj.View.handles.percXYZRadio.Value
                val = str2double(obj.View.handles.percEdit.String);
                obj.View.handles.dimX.String = num2str(floor(obj.width/100*val));
                obj.View.handles.dimY.String = num2str(floor(obj.height/100*val));
                obj.View.handles.dimZ.String = num2str(floor(obj.depth/100*val));
                obj.View.handles.voxX.String = num2str(pixSize.x*obj.width/floor(obj.width/100*val));
                obj.View.handles.voxY.String = num2str(pixSize.y*obj.height/floor(obj.height/100*val));
                obj.View.handles.voxZ.String = num2str(pixSize.z*obj.depth/floor(obj.depth/100*val));
            elseif obj.View.handles.percXYRadio.Value
                val = str2double(obj.View.handles.percEdit.String);
                obj.View.handles.dimX.String = num2str(floor(obj.width/100*val));
                obj.View.handles.dimY.String = num2str(floor(obj.height/100*val));
                obj.View.handles.voxX.String = num2str(pixSize.x*obj.width/floor(obj.width/100*val));
                obj.View.handles.voxY.String = num2str(pixSize.y*obj.height/floor(obj.height/100*val));
            end
        end
        
        
        function resampleBtn_Callback(obj)
            % function resampleBtn_Callback(obj)
            % resample the current dataset
            tic
            newW = str2double(obj.View.handles.dimX.String);
            newH = str2double(obj.View.handles.dimY.String);
            newZ = str2double(obj.View.handles.dimZ.String);
            maxT = obj.mibModel.getImageProperty('time');
            if newW == obj.width && newH == obj.height && newZ == obj.depth
                warndlg('The dimensions were not changed!','Wrong dimensions','modal');
                return;
            end
            
            obj.mibModel.U.clearContents();      % clear Undo history
            
            % define resampled ratio for resampling ROIs
            resampledRatio = [newW/obj.width, newH/obj.height, newZ/obj.depth];
            
            resamplingFunction = obj.View.handles.resamplingFunction.String;
            resamplingFunction = resamplingFunction(obj.View.handles.resamplingFunction.Value);
            methodList = obj.View.handles.imageMethod.String;
            methodValue = obj.View.handles.imageMethod.Value;
            methodImage = methodList{methodValue};
            methodList = obj.View.handles.modelsMethod.String;
            methodValue = obj.View.handles.modelsMethod.Value;
            if isa(methodList, 'char')
                modelsMethod = methodList;
            else
                modelsMethod = methodList{methodValue};
            end
            wb = waitbar(0,sprintf('Resampling image...\n[%d %d %d %d]->[%d %d %d %d]', ...
                obj.height, obj.width, obj.color, obj.depth, newH, newW, obj.color, newZ), 'Name', 'Resampling ...', 'WindowStyle', 'modal');
            
            options.blockModeSwitch=0;
            imgOut = zeros([newH, newW, obj.color, newZ, maxT], class(obj.mibModel.I{obj.mibModel.Id}.img{1}));   %#ok<ZEROLIKE> % allocate space
            options.height = newH;
            options.width = newW;
            options.depth = newZ;
            options.method = methodImage;
            for t=1:maxT
                img = cell2mat(obj.mibModel.getData3D('image', t, 4, NaN, options));
                waitbar(0.05,wb);
                % resample image
                if strcmp(resamplingFunction, 'interpn')
                    options.showWaitbar = 0;
                    options.algorithm = 'interpn';
                    imgOut(:,:,:,:,t) = mibResize3d(img(:,:,:,:,t), [], options);
                elseif strcmp(resamplingFunction, 'imresize')
                    options.showWaitbar = 0;
                    options.algorithm = 'imresize';
                    imgOut(:,:,:,:,t) = mibResize3d(img(:,:,:,:,t), [], options);
                else
                    options.showWaitbar = 0;
                    options.algorithm = 'tformarray';
                    imgOut(:,:,:,:,t) = mibResize3d(img(:,:,:,:,t), [], options);
                end
            end
            clear img;
            clear imgOut2;
            waitbar(0.5,wb);
            obj.mibModel.setData4D('image', imgOut, 4, NaN, options);
            waitbar(0.55,wb);
            
            % update pixel dimensions
            obj.mibModel.I{obj.mibModel.Id}.pixSize.x = obj.mibModel.I{obj.mibModel.Id}.pixSize.x/size(imgOut, 2)*obj.width;
            obj.mibModel.I{obj.mibModel.Id}.pixSize.y = obj.mibModel.I{obj.mibModel.Id}.pixSize.y/size(imgOut, 1)*obj.height;
            obj.mibModel.I{obj.mibModel.Id}.pixSize.z = obj.mibModel.I{obj.mibModel.Id}.pixSize.z/size(imgOut, 4)*obj.depth;
            
            % update img_info
            resolution = mibCalculateResolution(obj.mibModel.I{obj.mibModel.Id}.pixSize);
            obj.mibModel.I{obj.mibModel.Id}.meta('XResolution') = resolution(1);
            obj.mibModel.I{obj.mibModel.Id}.meta('YResolution') = resolution(2);
            obj.mibModel.I{obj.mibModel.Id}.meta('ResolutionUnit') = 'Inch';
            
            options.method = modelsMethod;
            
            % resample model and mask
            if obj.mibModel.I{obj.mibModel.Id}.modelExist
                waitbar(0.75,wb,sprintf('Resampling model...\n[%d %d %d %d]->[%d %d %d %d]', ...
                    obj.height, obj.width, obj.color, obj.depth, newH, newW, obj.color, newZ));
                imgOut = zeros([newH, newW, newZ, maxT], 'uint8');
                model = cell2mat(obj.mibModel.getData4D('model', 4, NaN, options));  % have to use getData4D, because getData3D returns the cropped model because of already resized image
                matetialsNumber = numel(obj.mibModel.getImageProperty('modelMaterialNames'));
                for t=1:maxT
                    if strcmp(resamplingFunction, 'interpn')
                        if strcmp(modelsMethod,'nearest')
                            options.showWaitbar = 0;
                            options.algorithm = 'interpn';
                            imgOut(:,:,:,t) = mibResize3d(model(:,:,:,t), [], options);
                        else
                            modelTemp = zeros([newH, newW, newZ], 'uint8');
                            for materialId = 1:matetialsNumber
                                modelTemp2 = zeros(size(model(:,:,:,t)), 'uint8');
                                modelTemp2(model(:,:,:,t) == materialId) = 1;
                                modelTemp2 = mibResize3d(modelTemp2, [], options);
                                modelTemp(modelTemp2 > 0.33) = materialId;
                            end
                            imgOut(:,:,:,t) = modelTemp;
                        end
                    elseif strcmp(resamplingFunction, 'imresize')
                        options.showWaitbar = 0;
                        options.algorithm = 'imresize';
                        imgOut(:,:,:,t) = mibResize3d(model(:,:,:,t), [], options);
                    else
                        options.showWaitbar = 0;
                        options.algorithm = 'tformarray';
                        imgOut(:,:,:,t) = mibResize3d(model(:,:,:,t), [], options);
                    end
                end
                waitbar(0.95,wb);
                obj.mibModel.I{obj.mibModel.Id}.model{1} = zeros(size(imgOut), 'uint8');  % reinitialize .model
                obj.mibModel.setData4D('model', imgOut, 4, NaN, options);
            elseif obj.mibModel.I{obj.mibModel.Id}.modelType == 63     % when no model, reset handles.Img{andles.Id}.I.model variable
                obj.mibModel.I{obj.mibModel.Id}.model{1} = zeros([size(imgOut,1), size(imgOut,2), size(imgOut,4) size(imgOut,5)], 'uint8');    % clear the old model
            end
            
            % resampling ROIS
            obj.mibModel.I{obj.mibModel.Id}.hROI.resample(resampledRatio);
            
            % update the log
            log_text = sprintf('Resample [%d %d %d %d %d]->[%d %d %d %d %d], method: %s', ...
                obj.height, obj.width, obj.color, obj.depth, maxT, ...
                newH, newW, obj.color, newZ, maxT, methodImage);
            obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(log_text);
            % remove slice name if number of z-sections has changed
            if isKey(obj.mibModel.I{obj.mibModel.Id}.meta, 'SliceName') && newZ ~= obj.depth
                remove(obj.mibModel.I{obj.mibModel.Id}.meta, 'SliceName');
            end
            
            obj.mibModel.I{obj.mibModel.Id}.clearSelection();     % will not resample selection
            obj.mibModel.I{obj.mibModel.Id}.clearMask();          % will not resample mask
            waitbar(1,wb);
            delete(wb)
            toc;
            
            notify(obj.mibModel, 'newDataset');
            eventdata = ToggleEventData(1);
            notify(obj.mibModel, 'plotImage', eventdata);
            
            %profile viewer
            obj.closeWindow();
        end
        
    end
end