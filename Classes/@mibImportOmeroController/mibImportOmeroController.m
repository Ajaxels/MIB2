classdef mibImportOmeroController < handle
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        client
        % handle to Omero client
        session
        % handle to Omero session
        projectId
        % id of selected project
        datasetId
        % id of selected dataset
        imageId
        % id of selected image
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods
        function obj = mibImportOmeroController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'mibImportOmeroGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % check for the virtual stacking mode and disable it
            if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                result = obj.mibModel.I{obj.mibModel.Id}.switchVirtualStackingMode(0, obj.mibModel.preferences.disableSelection);  % switch to the memory-resident mode
                if isempty(result) || result == 1
                    obj.closeWindow();
                    return;
                end
                obj.mibModel.I{obj.mibModel.Id}.clearContents();
                eventdata = ToggleEventData(obj.mibModel.Id);
                notify(obj.mibModel, 'newDataset', eventdata);
                notify(obj.mibModel, 'plotImage');
            end
            
            % resize all elements x1.25 times for macOS
            mibRescaleWidgets(obj.View.gui);
            
            % update font and size
            global Font;
            if ~isempty(Font)
                if obj.View.handles.text1.FontSize ~= Font.FontSize ...
                        || ~strcmp(obj.View.handles.text1.FontName, Font.FontName)
                    mibUpdateFontSize(obj.View.gui, Font);
                end
            end
            obj.projectId = []; % id of selected project
            obj.datasetId = []; % id of selected dataset
            obj.imageId = [];   % id of selected image
            
            obj.View.gui.WindowStyle = 'modal';     % make window modal
            
            obj.omeroLoginBtn_Callback();
        end
        
        function omeroLoginBtn_Callback(obj)
            % function omeroLoginBtn_Callback(obj)
            %
            result = mibOmeroLoginDlg();
            if isempty(fieldnames(result))
                return;
            end
            %obj.client = omero.client(result.server, result.port);
            obj.client = connectOmero(result.server, result.port);
            
            try
                obj.session = obj.client.createSession(result.username, result.password);
            catch err
                if isa(err.ExceptionObject, 'Glacier2.PermissionDeniedException')
                    obj.client.closeSession();
                    warndlg('Wrong username or password!', 'Login error...', 'modal');
                    return;
                end
            end
            % update the project list
            res = obj.updateProjectTable();
            if res == 0     % no active projects
                obj.closeWindow();
            end
        end
        
        function closeWindow(obj)
            % closing mibImportOmeroController window
            if isvalid(obj.View.gui)
                delete(obj.View.gui);   % delete childController window
            end
            
            notify(obj, 'closeEvent');      % notify mibController that this child window is closed
        end
        
        function status = updateProjectTable(obj)
            % function updateProjectTable(obj)
            % update project list
            
            status = 0;
            
            proxy = obj.session.getContainerService();
            param = omero.sys.ParametersI();
            userId = obj.session.getAdminService().getEventContext().userId; % id of the user.
            param.exp(omero.rtypes.rlong(userId));
            projectsList = proxy.loadContainerHierarchy('omero.model.Project', [], param);
            
            if projectsList.isEmpty
                errordlg(sprintf('!!! Error !!!\n\nNo projects were found!\nThis tool allows to import datasets from OMERO server, at the moment it is empty.\nPlease use OMERO client to upload images first and try again.'));
                return;
            end
            
            for j = 0:projectsList.size()-1
                p = projectsList.get(j);
                list{j+1,1} = char(p.getName.getValue()); %#ok<AGROW>
                list{j+1,2} = double(p.getId.getValue()); %#ok<AGROW>
            end
            obj.View.handles.projectTable.Data = list;
            obj.View.handles.imageTable.Data = [];
            
            obj.projectId = list{1,2};
            obj.datasetId = NaN;
            obj.imageId = NaN;
            
            obj.updateDatasets('project');
            status = 1;
        end
        
        function updateDatasets(obj, tableId)
            % function updateDatasets(obj, tableId)
            % update dataset table
            
            ids = java.util.ArrayList();
            proxy = obj.session.getContainerService();
            switch tableId
                case 'project'
                    ids.add(java.lang.Long(obj.projectId)); %add the id of the dataset.
                    param = omero.sys.ParametersI();
                    userId = obj.session.getAdminService().getEventContext().userId; %id of the user.
                    param.exp(omero.rtypes.rlong(userId));
                    list = proxy.loadContainerHierarchy('omero.model.Project', ids, param);
                    dataset = list.get(0);
                    datasetList = dataset.linkedDatasetList; % The datasets in the project.
                    if datasetList.size() > 0
                        for id=0:datasetList.size()-1
                            dataset = datasetList.get(id);
                            data{id+1,1} = char(dataset.getName.getValue()); %#ok<AGROW>
                            data{id+1,2} = double(dataset.getId.getValue()); %#ok<AGROW>
                        end
                    else
                        data = [];
                    end
                    obj.View.handles.datasetTable.Data = data;
                    obj.View.handles.imageTable.Data = [];
                case 'dataset'
                    ids.add(java.lang.Long(obj.datasetId)); %add the id of the dataset.
                    param = omero.sys.ParametersI();
                    param.leaves(); % indicate to load the images.
                    list = proxy.loadContainerHierarchy('omero.model.Dataset', ids, param);
                    dataset = list.get(0);
                    imageList = dataset.linkedImageList; % The images in the dataset.
                    if imageList.size() > 0
                        for id=0:imageList.size()-1
                            image = imageList.get(id);
                            data{id+1,1} = char(image.getName.getValue()); %#ok<AGROW>
                            data{id+1,2} = double(image.getId.getValue()); %#ok<AGROW>
                        end
                    else
                        data = [];
                    end
                    obj.View.handles.imageTable.Data = data;
                case 'image'
                    ids.add(java.lang.Long(obj.imageId)); %add the id of the image
                    proxy = obj.session.getContainerService();
                    list = proxy.getImages('omero.model.Image', ids, omero.sys.ParametersI());
                    image = list.get(0);
                    pixelsList = image.copyPixels();
                    for k = 0:pixelsList.size()-1
                        pixels = pixelsList.get(k);
                        sizeZ = pixels.getSizeZ().getValue(); % The number of z-sections.
                        sizeT = pixels.getSizeT().getValue(); % The number of timepoints.
                        sizeC = pixels.getSizeC().getValue(); % The number of channels.
                        sizeX = pixels.getSizeX().getValue(); % The number of pixels along the X-axis.
                        sizeY = pixels.getSizeY().getValue(); % The number of pixels along the Y-axis.
                        pixelsId = pixels.getId().getValue();
                        data(:,1) = {'Width','Height', 'Colors', 'Z-sections', 'Timepoints'};
                        data(:,2) = {sizeX, sizeY, sizeC, sizeZ, sizeT};
                        obj.View.handles.imageParametersTable.Data = data;
                        
                        obj.View.handles.maxX.String = num2str(sizeX);
                        obj.View.handles.maxY.String = num2str(sizeY);
                        obj.View.handles.maxC.String = num2str(sizeC);
                        obj.View.handles.maxZ.String = num2str(sizeZ);
                        obj.View.handles.maxT.String = num2str(sizeT);
                    end
                    
                    store = obj.session.createThumbnailStore();
                    map = store.getThumbnailByLongestSideSet(omero.rtypes.rint(150), java.util.Arrays.asList(java.lang.Long(pixelsId)));
                    %Display the thumbnail;
                    collection = map.values();
                    i = collection.iterator();
                    %while (i.hasNext())
                    stream = java.io.ByteArrayInputStream(i.next());
                    image = javax.imageio.ImageIO.read(stream);
                    stream.close();
                    img = JavaImageToMatlab(image);
                    imagesc(img, 'parent', obj.View.handles.thumbView);
                    obj.View.handles.thumbView.DataAspectRatio = [1 1 1];
                    obj.View.handles.thumbView.XTick = [];
                    obj.View.handles.thumbView.YTick = [];
                    %end
            end
        end
        
        function projectTable_CellSelectionCallback(obj, eventdata)
            % function projectTable_CellSelectionCallback(obj, eventdata)
            % callback for selection of cell in the project table
            
            data = obj.View.handles.projectTable.Data;
            obj.projectId = data{eventdata.Indices(1,1), 2};
            obj.datasetId = NaN;
            obj.imageId = NaN;
            obj.updateDatasets('project');
        end
        
        function datasetTable_CellSelectionCallback(obj, eventdata)
            % function datasetTable_CellSelectionCallback(obj, eventdata)
            % callback for cell selection in the dataset table
            
            data = obj.View.handles.datasetTable.Data;
            if isempty(data); return; end;
            if isempty(eventdata.Indices)
                Indices(1,1) = 1;
            else
                Indices = eventdata.Indices;
            end;
            obj.datasetId = data{Indices(1,1), 2};
            obj.imageId = NaN;
            obj.updateDatasets('dataset');
        end
        
        function imageTable_CellSelectionCallback(obj, eventdata)
            % function imageTable_CellSelectionCallback(obj, eventdata)
            % callback for selection of cells in image table
            
            data = obj.View.handles.imageTable.Data;
            if isempty(data); return; end;
            if isempty(eventdata.Indices)
                Indices(1,1) = 1;
            else
                Indices = eventdata.Indices;
            end;
            obj.imageId = data{Indices(1,1), 2};
            obj.updateDatasets('image')
        end
        
        function continueBtn_Callback(obj)
            % function continueBtn_Callback(obj)
            % obtain dataset from Omero server
            global mibPath;
            
            wb = waitbar(0,'Please wait...', 'Name', 'OMERO Import');
            ids = java.util.ArrayList();
            ids.add(java.lang.Long(obj.imageId)); %add the id of the image
            proxy = obj.session.getContainerService();
            list = proxy.getImages('omero.model.Image', ids, omero.sys.ParametersI());
            image = list.get(0);
            pixelsList = image.copyPixels();
            
            for k = 0:pixelsList.size() - 1
                pixels = pixelsList.get(k);
                pixelsId = pixels.getId().getValue();
                store = obj.session.createRawPixelsStore();
                store.setPixelsId(pixelsId, false); %Indicate the pixels set you are working on
                
                sizeX = pixels.getSizeX().getValue();
                sizeY = pixels.getSizeY().getValue();
                sizeZ = pixels.getSizeZ().getValue();
                sizeT = pixels.getSizeT().getValue();
                sizeC = pixels.getSizeC().getValue();
                
                if ~isempty(pixels.getPhysicalSizeX)
                    pixSizeX = pixels.getPhysicalSizeX.getValue();
                    pixSizeY = pixels.getPhysicalSizeY.getValue();
                else
                    pixSizeX = 1;
                    pixSizeY = 1;
                end
                
                if ~isempty(pixels.getPhysicalSizeZ)
                    pixSizeZ = pixels.getPhysicalSizeZ.getValue();
                else
                    pixSizeZ = 1;
                end
                if pixSizeZ == Inf; pixSizeZ = pixSizeX; end;
                pixSizeT = pixels.getTimeIncrement;
                if isempty(pixSizeT)
                    pixSizeT = 1;
                else
                    pixSizeT = pixSizeT.getValue();
                end
                
                minX = str2double(obj.View.handles.minX.String)-1;
                stepX = str2double(obj.View.handles.stepX.String);
                maxX = str2double(obj.View.handles.maxX.String)-1;
                minY = str2double(obj.View.handles.minY.String)-1;
                stepY = str2double(obj.View.handles.stepY.String);
                maxY = str2double(obj.View.handles.maxY.String)-1;
                minC = str2double(obj.View.handles.minC.String)-1;
                stepC = str2double(obj.View.handles.stepC.String);
                maxC = str2double(obj.View.handles.maxC.String)-1;
                minZ = str2double(obj.View.handles.minZ.String)-1;
                stepZ = str2double(obj.View.handles.stepZ.String);
                maxZ = str2double(obj.View.handles.maxZ.String)-1;
                minT = str2double(obj.View.handles.minT.String)-1;
                stepT = str2double(obj.View.handles.stepT.String);
                maxT = str2double(obj.View.handles.maxT.String)-1;
                
                width = numel(minX:stepX:maxX);
                height = numel(minY:stepY:maxY);
                colors = numel(minC:stepC:maxC);
                zThick = numel(minZ:stepZ:maxZ);
                tThick = numel(minT:stepT:maxT);
                
                
                waitbar(0.05,wb);
                % get image class
                if store.getByteWidth == 1
                    outputClass = 'uint8';
                elseif store.getByteWidth == 2
                    outputClass = 'uint16';
                else
                    outputClass = 'uint32';
                end
                
                if sizeZ > 1 && sizeT > 1
                    button = questdlg(sprintf('This is 5D dataset!\nWould you like to load Z-stacks or T-stacks?'),...
                        '5D dataset','z-stacks','t-stacks','cancel','z-stacks');
                    if strcmp(button,'cancel')
                        delete(wb);
                        obj.cancelBtn_Callback(); 
                        return; 
                    end;
                    
                    if strcmp(button, 'z-stacks')
                        %answer = inputdlg(sprintf('Please enter the T-value (1-%d):', sizeT),'Time value',1,{'1'});
                        answer = mibInputDlg({mibPath}, sprintf('Please enter the T-value (1-%d):', sizeT), 'Time value', '1');
                        if isempty(answer)
                            delete(wb);
                            obj.cancelBtn_Callback(); 
                            return; 
                        end;
                        minT = str2double(answer{1})-1;
                        maxT = str2double(answer{1})-1;
                        tThick = 1;
                        imgOut = zeros([height, width, colors, zThick], outputClass);
                    end
                    
                    if strcmp(button, 't-stacks')
                        %answer = inputdlg(sprintf('Please enter the Z-value (1-%d):', sizeZ),'Z-stack value',1,{'1'});
                        answer = mibInputDlg({mibPath}, sprintf('Please enter the Z-value (1-%d):', sizeZ), 'Z-stack value', '1');
                        if isempty(answer)
                            delete(wb);
                            obj.cancelBtn_Callback(); 
                            return; 
                        end;
                        minZ = str2double(answer{1})-1;
                        maxZ = str2double(answer{1})-1;
                        zThick = 1;
                        imgOut = zeros([height, width, colors, tThick], outputClass);
                    end
                else
                    imgOut = zeros([height, width, colors, max([zThick, tThick])], outputClass);
                end
                
                tic;
                maxVal = colors*zThick*tThick;
                counter = 0;
                zIndex = 1;
                for z = minZ:stepZ:maxZ
                    tIndex = 1;
                    for t = minT:stepT:maxT
                        cIndex = 1;
                        for c = minC:stepC:maxC
                            tile = store.getTile(z, c, t, minX, minY, width, height);
                            
                            tPlane = typecast(tile, outputClass);
                            tPlane = reshape(tPlane, [width, height])';
                            tPlane = swapbytes(tPlane);
                            if tThick < zThick
                                imgOut(:, :, cIndex, zIndex) = swapbytes(tPlane);
                            else
                                imgOut(:, :, cIndex, tIndex) = swapbytes(tPlane);
                            end
                            cIndex = cIndex + 1;
                        end
                        tIndex = tIndex + 1;
                        counter = counter + colors;
                        waitbar(counter/maxVal,wb);
                    end
                    zIndex = zIndex + 1;
                end
                t1=toc;
                sprintf('Elapsed time is %f seconds, transfer rate: %f MB/sec', t1, numel(imgOut)/1000000/t1)
            end
            store.close();
            delete(wb);
            
            % metadataService = handles.session.getMetadataService();
            % annotationTypes = java.util.ArrayList();
            % %annotationTypes.add('ome.model.annotations.TagAnnotation');
            % % Unused
            % annotatorIds = java.util.ArrayList();
            % parameters = omero.sys.Parameters();
            %
            % % retrieve the annotations linked to images, for datasets use: 'omero.model.Dataset'
            % annotations = metadataService.loadAnnotations('Image', ids, annotationTypes, annotatorIds, parameters);
            % annotations = metadataService.loadAnnotations('Image', ids);
            % for i=1:annotations.size
            %     ArrList = annotations.get(imageId);
            %     for j=1:ArrList.size
            %         tagValue = ArrList.get(j-1).getTextValue().getValue();
            %         txt = ['TagVale: ' char(tagValue)];
            %         disp(txt);
            %     end
            % end
            
            if ~isempty(obj.client)
                obj.client.closeSession();
            end
            img_info = containers.Map;
            if size(imgOut,3) > 1
                img_info('ColorType') = 'truecolor';
            else
                img_info('ColorType') = 'grayscale';
            end
            img_info('ImageDescription') = '';
            img_info('Height') = sizeY;
            img_info('Width') = sizeX;
            img_info('Depth') = size(imgOut, 4);
            %img_info('XResolution') = 1;
            %img_info('YResolution') = 1;
            %img_info('ResolutionUnit') = 'Inch';
            img_info('Filename') = 'omero.tif';
            
            obj.mibModel.I{obj.mibModel.Id}.clearContents(imgOut, img_info, obj.mibModel.preferences.disableSelection);
            
            obj.mibModel.I{obj.mibModel.Id}.pixSize.x = pixSizeX*stepX;
            obj.mibModel.I{obj.mibModel.Id}.pixSize.y = pixSizeY*stepY;
            obj.mibModel.I{obj.mibModel.Id}.pixSize.z = pixSizeZ*stepZ;
            obj.mibModel.I{obj.mibModel.Id}.pixSize.t = pixSizeT*stepT;
            
            obj.mibModel.I{obj.mibModel.Id}.updatePixSizeResolution();    % update pixels size, and resolution
            notify(obj.mibModel, 'newDataset');   % notify mibController about a new dataset; see function obj.Listner2_Callback for details
            
            eventdata = ToggleEventData(1);
            notify(obj.mibModel, 'plotImage', eventdata);
            
            obj.closeWindow();
        end
        
    end
end