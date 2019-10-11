classdef TripleAreaIntensityController < handle
    % TripleAreaIntensityController
	% This plugin can be used to calculate image intensities (mean, min, max or sum) of 3 areas stored
	% under 3 materials of a model.
	% 
	% The results of the plugin may be seen on the screen of |Microscopy Image
	% Browser| or saved as Excel spreadsheet. See more in the Help file

	
	
	% Copyright (C) 19.05.2014 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
	% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
	% This program is free software; you can redistribute it and/or
	% modify it under the terms of the GNU General Public License
	% as published by the Free Software Foundation; either version 2
	% of the License, or (at your option) any later version.
	%
	% Updates
	% 02.03.2017, IB adapted for MIB2
	
	
	properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        matlabExportVariable
        % name of variable for export results to Matlab
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback2(obj, src, evnt)
            switch evnt.EventName
                case {'updateGuiWidgets'}
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = TripleAreaIntensityController(mibModel)
            obj.mibModel = mibModel;    % assign model
            guiName = 'TripleAreaIntensityGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            % check for the virtual stacking mode and close the controller
            if isprop(obj.mibModel.I{obj.mibModel.Id}, 'Virtual') && obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nThis plugin is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
                    'Not implemented');
                obj.closeWindow();
                return;
            end
            
            if isdeployed
                obj.View.handles.exportMatlabCheck.Enable = 'off';
            end
            
            obj.matlabExportVariable = 'TripleaAreaIntensity';
            
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
            
			obj.updateWidgets();
			
			% add listner to obj.mibModel and call controller function as a callback
            obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing TripleAreaIntensityController window
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
            
            % populate color channel combo box
            obj.View.handles.colorChannelCombo.Value = 1;
            col_channels = cell([obj.mibModel.getImageProperty('colors'), 1]);
            for col_ch=1:obj.mibModel.getImageProperty('colors')
                col_channels(col_ch) = cellstr(['Channel ' num2str(col_ch)]);
            end
            obj.View.handles.colorChannelCombo.String = col_channels;
            colorChannelSelection = max([1 obj.mibModel.I{obj.mibModel.Id}.slices{3}(end)]);     % get selected color channel
            % when only one color channel is shown select it
            if numel(obj.mibModel.I{obj.mibModel.Id}.slices{3}) == 1
                colorChannelSelection = obj.mibModel.I{obj.mibModel.Id}.slices{3};
                obj.View.handles.colorChannelCombo.Value = colorChannelSelection;
            else
                if obj.mibModel.getImageProperty('colors') >= colorChannelSelection
                    obj.View.handles.colorChannelCombo.Value = colorChannelSelection;
                end
            end
            
            obj.View.handles.backgroundPopup.Value = 1;
            obj.View.handles.material1Popup.Value = 1;
            obj.View.handles.thresholdingPopup.Value = 1;
            materialsList = obj.mibModel.getImageProperty('modelMaterialNames');
            if isempty(materialsList)
                materialsList = {'Insufficient data, please check Help!'};
                obj.View.handles.material2Popup.Value = 1;
                obj.View.handles.continueBtn.Enable = 'off';
            else
                obj.View.handles.continueBtn.Enable = 'on';
                if numel(materialsList) > 1
                    obj.View.handles.material2Popup.Value = 2;
                else
                    obj.View.handles.material2Popup.Value = 1;
                end
            end
            obj.View.handles.backgroundPopup.String = materialsList;
            obj.View.handles.material1Popup.String = materialsList;
            obj.View.handles.material2Popup.String = materialsList;
            obj.View.handles.thresholdingPopup.String = materialsList;
            
            [path, fn] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            obj.View.handles.filenameEdit.String = fullfile(path, [fn '_analysis.xls']);
            obj.View.handles.filenameEdit.TooltipString = fullfile(path, [fn '_analysis.xls']);
        end
        
        function exportMatlabCheck_Callback(obj)
            % callback for press of the Export to Matlab checkbox
            if obj.View.handles.exportMatlabCheck.Value
                answer = mibInputDlg({[]}, sprintf('Please define output variable\n(do not use spaces or specials characters):'),...
                    'Export variable', obj.matlabExportVariable);
                if ~isempty(answer)
                    obj.matlabExportVariable = answer{1};
                else
                    return;
                end
            end
        end
        
        function continueBtn_Callback(obj)
            % function continueBtn_Callback(obj)
            % do calculations
            
            if obj.mibModel.getImageProperty('modelExist') == 0
                errordlg('This plugin requires a model to be present!','Model was not detected');
                return;
            end
            
            fn = obj.View.handles.filenameEdit.String;
            if obj.View.handles.savetoExcel.Value
                % check filename
                if exist(fn, 'file') == 2
                    strText = sprintf('!!! Warning !!!\n\nThe file:\n%s \nis already exist!\n\nOverwrite?', fn);
                    button = questdlg(strText, 'File exist!','Overwrite', 'Cancel', 'Cancel');
                    if strcmp(button, 'Cancel'); return; end
                    delete(fn);     % delete existing file
                end
            end
            
            connectionsCheck = obj.View.handles.connectionsCheck.Value;     % show or not connected objects
            
            parameterToCalculateList = obj.View.handles.parameterCombo.String;    % get type of intensity to calculate (min, max, average...)
            parameterToCalculateVal = obj.View.handles.parameterCombo.Value;
            parameterToCalculate = parameterToCalculateList{parameterToCalculateVal};
            colCh = obj.View.handles.colorChannelCombo.Value;    % color channel to analyze
            
            % get materials to be analyzed
            material1_Index = obj.View.handles.material1Popup.Value;
            material2_Index = obj.View.handles.material2Popup.Value;
            background_Check = obj.View.handles.backgroundCheck.Value;   % get background values
            background_Index = obj.View.handles.backgroundPopup.Value;   % index of the background material
            subtractBg_Check = obj.View.handles.subtractBackgroundCheck.Value;   % index of the background material
            calculateRatioCheck = obj.View.handles.calculateRatioCheck.Value;    % calculate ratio of material1/material2
            additionalThresholdingCheck = obj.View.handles.additionalThresholdingCheck.Value;    % whether to do additional thresholding of any material
            
            if additionalThresholdingCheck  % clear the mask layer
                addMaterial_Index = obj.View.handles.thresholdingPopup.Value;
                addMaterial_Shift = str2double(obj.View.handles.thresholdEdit.String);   % shift of intensities from background value for additional thresholding
                obj.mibModel.getImageMethod('clearMask');
                obj.mibModel.setImageProperty('maskExist', 1);
                if addMaterial_Index ~= material1_Index && addMaterial_Index ~= material2_Index
                    errordlg(sprintf('Material for additional thresholding should be Material 1 or Material 2!'), 'Wrong material!')
                    return;
                end
            end
            
            % generate structure for results
            TripleArea = struct();
            % TripleArea.info - general info
            % TripleArea.imgDir - directory with images
            % TripleArea.calcPar - calculated parameter
            % TripleArea.colChannel - calculated parameter
            % TripleArea.BackgroundMaterial - name of the background material
            % TripleArea.RatioInfo - ratio of materials
            % TripleArea.subtractedBg - 0 background was not subtracted, 1 - background was subtracted
            % TripleArea.additionalThresholdingValue - additionally threshold one of the materials
            % TripleArea.MaterialName1 - name of the 1st material
            % TripleArea.MaterialName2 - name of the 2nd material
            % TripleArea.Filename - cell array of filenames filename
            % TripleArea.SliceNumber - array of slice numbers
            % TripleArea.MaterialNameAdditionallyThresholded - name of the 2nd material
            % TripleArea.Intensity1 - array of intensity of Material 1
            % TripleArea.Intensity2 - array of intensity of Material 2
            % TripleArea.IntensityBg - array of intensity of Background
            % TripleArea.IntensityA - array of additionally thresholded areas
            % TripleArea.Ratio - array of ratio of materials
            TripleArea.Filename = {};
            TripleArea.SliceNumber = [];
            TripleArea.Intensity1 = [];
            TripleArea.Intensity2 = [];
            TripleArea.IntensityBg = [];
            TripleArea.IntensityA = [];
            TripleArea.Ratio = [];
            
            wb = waitbar(0,'Please wait...','Name','Triple Area Intensity...', 'WindowStyle', 'modal');
            obj.mibModel.mibDoBackup('selection', 1);
            obj.mibModel.I{obj.mibModel.Id}.hLabels.clearContents();  % remove annotations from the model
            
            warning('off', 'MATLAB:xlswrite:AddSheet');
            % Sheet 1
            s = {'TripleAreaIntensity: triple material intensity analysis and ratio calculation'};
            s(2,1) = {'Image directory:'};
            s(2,2) = {fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'))};
            s(3,1) = {['Calculating: ' parameterToCalculate]};
            s(3,4) = {['Color channel: ' num2str(colCh)]};
            
            TripleArea.info = 'TripleAreaIntensity: triple material intensity analysis and ratio calculation';
            TripleArea.imgDir = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
            TripleArea.calcPar = parameterToCalculate;
            TripleArea.colChannel = colCh;
            TripleArea.subtractedBg = subtractBg_Check;
            TripleArea.RatioInfo = [obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{material1_Index} '/' obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{material2_Index}];
            
            
            if background_Check
                s(4,4) = {['Background material: ' obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{background_Index}]};
                TripleArea.BackgroundMaterial = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{background_Index};
            end
            
            s(6,1) = {'Filename'};
            s(6,2) = {'Slice Number'};
            if subtractBg_Check
                s(6,3) = cellstr([obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{material1_Index} '-minus-Bg']);
                s(6,4) = cellstr([obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{material2_Index} '-minus-Bg']);
                TripleArea.MaterialName1 = [obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{material1_Index} '_minus_Bg'];
                TripleArea.MaterialName2 = [obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{material2_Index} '_minus_Bg'];
            else
                s(6,3) = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames(material1_Index);
                s(6,4) = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames(material2_Index);
                TripleArea.MaterialName1 = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{material1_Index};
                TripleArea.MaterialName2 = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{material2_Index};
            end
            s(6,5) = cellstr('Bg');
            s(7,5) = cellstr('(background)');
            s(6,6) = {'Ratio'};
            s(7,6) = {[obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{material1_Index} '/' obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{material2_Index}]};
            if additionalThresholdingCheck
                TripleArea.additionalThresholdingValue = addMaterial_Shift;
                
                s(4,8) = {['Intensity shift for thresholding: ' num2str(addMaterial_Shift)]};
                s(6,7) = {'Intensity of thresholded'};
                if subtractBg_Check
                    s(7,7) = {[obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{addMaterial_Index} '-minus-Bg']};
                    TripleArea.MaterialNameAdditionallyThresholded = [obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{addMaterial_Index} '-minus-Bg'];
                else
                    s(7,7) = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames(addMaterial_Index);
                    TripleArea.MaterialNameAdditionallyThresholded = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames(addMaterial_Index);
                end
            end
            
            options.blockModeSwitch = 0;
            img = cell2mat(obj.mibModel.getData3D('image', NaN, 4, colCh, options));    % get desired color channel from the image
            model1 = cell2mat(obj.mibModel.getData3D('model', NaN, 4, material1_Index, options));    % get model 1
            model2 = cell2mat(obj.mibModel.getData3D('model', NaN, 4, material2_Index, options));    % get model 2
            if background_Check     % get background material
                background = cell2mat(obj.mibModel.getData3D('model', NaN, 4, background_Index, options));    % get model 2
            else
                background = NaN;
            end
            
            if connectionsCheck
                selection = zeros(size(model1), class(model1));   % create new selection layer
            end
            
            if isKey(obj.mibModel.I{obj.mibModel.Id}.meta, 'SliceName')   % when filenames are present use them
                inputFn = obj.mibModel.I{obj.mibModel.Id}.meta('SliceName');
                if numel(inputFn) < size(img,4)
                    inputFn = repmat(inputFn(1),[size(img,4),1]);
                end
            else
                [~,inputFn, ext] = fileparts(obj.mibModel.I{obj.mibModel.Id}.meta('Filename'));
                inputFn = [inputFn ext];
            end
            
            rowId = 8;  % a row for the excel file
            Ratio = []; % a variable to keep ratios of intensities
            %
            for sliceId = 1:size(model1, 3)
                waitbar(sliceId/size(model1, 3),wb);
                CC1 = bwconncomp(model1(:,:,sliceId),8);
                if CC1.NumObjects == 0; continue; end  % check whether the materials exist on the current slice
                STATS1 = regionprops(CC1, 'Centroid', 'PixelIdxList');
                CC2 = bwconncomp(model2(:,:,sliceId), 8);
                STATS2 = regionprops(CC2, 'Centroid', 'PixelIdxList');
                if CC1.NumObjects ~= CC2.NumObjects; continue; end
                
                BG_CC.NumObjects = 0;
                BG_STATS = [];
                if background_Check
                    BG_CC = bwconncomp(background(:,:,sliceId),8);
                    BG_STATS = regionprops(BG_CC, 'Centroid', 'PixelIdxList');
                end
                
                % find distances between centroids of material 1 and material 2
                X1 = zeros([numel(STATS1) 2]);
                X2 = zeros([numel(STATS2) 2]);
                for i=1:numel(STATS1)
                    X1(i,:) = STATS1(i).Centroid;
                    X2(i,:) = STATS2(i).Centroid;
                end
                idx = mibFindMatchingPairs(X1, X2);
                
                % find distances between centroids of material 1 and background
                if background_Check == 1  % when number of objects for material 1 match number of Bg objects - find matching pairs, otherwise use mean value for the background
                    X3 = zeros([numel(BG_STATS) 2]);
                    for i=1:numel(BG_STATS)
                        X3(i,:) = BG_STATS(i).Centroid;
                    end
                    if CC1.NumObjects == BG_CC.NumObjects   % find matching to material 1 background
                        bg_idx =  mibFindMatchingPairs(X1, X3);   % indeces of the matching objects, i.e. STATS1(objId) =match= BG_STATS(bg_idx(objId))
                    elseif BG_CC.NumObjects > 0     % average all background areas
                        bg_idx = [];
                    end
                else
                    bg_idx = [];
                end
                
                % calculate intensities
                Intensity1 = zeros([numel(STATS1), 1]);  % reserve space for intensities of the 1st material
                Intensity2 = zeros([numel(STATS2), 1]);  % reserve space for intensities of the 2nd material
                Background = zeros([numel(BG_STATS), 1]);  % reserve space for intensities of the background
                BackgroundStd = zeros([numel(BG_STATS), 1]);  % reserve space for intensities of the background standard deviation
                if additionalThresholdingCheck
                    if addMaterial_Index == material1_Index
                        IntensityA = zeros([numel(STATS1),1]);
                        AD_STATS = STATS1;
                    else
                        IntensityA = zeros([numel(STATS2),1]);
                        AD_STATS = STATS2;
                    end
                    mask = zeros(size(model1, 1), size(model1, 2), 'uint8');    % create empty mask layer
                end
                slice = squeeze(img(:,:,:,sliceId));
                
                % when number of background objects is different from number of material 1 objects -> average Bg
                if background_Check == 1 && CC1.NumObjects ~= BG_CC.NumObjects
                    IntVec = [];
                    for bgId = 1:numel(BG_STATS)
                        IntVec = [IntVec; slice(BG_STATS(bgId).PixelIdxList)];
                    end
                    
                    switch parameterToCalculate
                        case 'Mean intensity'
                            Background = mean(IntVec);
                        case 'Min intensity'
                            Background = min(IntVec);
                        case 'Max intensity'
                            Background = max(IntVec);
                        case 'Sum intensity'
                            Background = sum(IntVec);
                    end
                    clear IntVec;
                    %         for bgId = 1:numel(BG_STATS)
                    %             switch parameterToCalculate
                    %                 case 'Mean intensity'
                    %                     Background(bgId) = mean(slice(BG_STATS(bgId).PixelIdxList));
                    %                 case 'Min intensity'
                    %                     Background(bgId) = min(slice(BG_STATS(bgId).PixelIdxList));
                    %                 case 'Max intensity'
                    %                     Background(bgId) = max(slice(BG_STATS(bgId).PixelIdxList));
                    %                 case 'Sum intensity'
                    %                     Background(bgId) = sum(slice(BG_STATS(bgId).PixelIdxList));
                    %             end
                    %             %BackgroundStd(bgId) = std(slice(BG_STATS(bgId).PixelIdxList));
                    %         end
                    %         Background = mean(Background);
                end
                
                % calculate intensities of material 1 and material 2
                for objId = 1:numel(STATS1)
                    pnts(1,:) = STATS1(objId).Centroid;
                    pnts(2,:) = STATS2(idx(objId)).Centroid;
                    if connectionsCheck
                        selection(:,:,sliceId) = mibConnectPoints(selection(:,:,sliceId), pnts);    % connect centroids between Material 1 and Material 2 for checking
                        if numel(bg_idx) > 0    % connect centroids of material 1 and Bg
                            pnts2(1,:) = STATS1(objId).Centroid;
                            pnts2(2,:) = BG_STATS(bg_idx(objId)).Centroid;
                            selection(:,:,sliceId) = mibConnectPoints(selection(:,:,sliceId), pnts2);    % connect centroids for checking
                        end
                    end
                    
                    switch parameterToCalculate
                        case 'Mean intensity'
                            Intensity1(objId) = mean(slice(STATS1(objId).PixelIdxList));
                            Intensity2(objId) = mean(slice(STATS2(idx(objId)).PixelIdxList));
                            if background_Check == 1 && CC1.NumObjects == BG_CC.NumObjects
                                Background(objId) = mean(slice(BG_STATS(bg_idx(objId)).PixelIdxList));
                            end
                            if additionalThresholdingCheck
                                indecesId = find(slice(AD_STATS(objId).PixelIdxList) > (Background(min([numel(Background) objId]))+addMaterial_Shift));    % get indeces with intensities higher than bg+shift
                                PixelIdxList = AD_STATS(objId).PixelIdxList(indecesId);   %#ok<FNDSB> % generate new indeces
                                mask(PixelIdxList) = 1;     % generate mask
                                IntensityA(objId) = mean(slice(PixelIdxList));
                            end
                        case 'Min intensity'
                            Intensity1(objId) = min(slice(STATS1(objId).PixelIdxList));
                            Intensity2(objId) = min(slice(STATS2(idx(objId)).PixelIdxList));
                            if background_Check == 1 && CC1.NumObjects == BG_CC.NumObjects
                                Background(objId) = min(slice(BG_STATS(bg_idx(objId)).PixelIdxList));
                            end
                            if additionalThresholdingCheck
                                indecesId = find(slice(AD_STATS(objId).PixelIdxList) > (Background(min([numel(Background) objId]))+addMaterial_Shift));    % get indeces with intensities higher than bg+shift
                                PixelIdxList = AD_STATS(objId).PixelIdxList(indecesId);   %#ok<FNDSB> % generate new indeces
                                mask(PixelIdxList) = 1;     % generate mask
                                IntensityA(objId) = min(slice(PixelIdxList));
                            end
                        case 'Max intensity'
                            Intensity1(objId) = max(slice(STATS1(objId).PixelIdxList));
                            Intensity2(objId) = max(slice(STATS2(idx(objId)).PixelIdxList));
                            if background_Check == 1 && CC1.NumObjects == BG_CC.NumObjects
                                Background(objId) = max(slice(BG_STATS(bg_idx(objId)).PixelIdxList));
                            end
                            if additionalThresholdingCheck
                                indecesId = find(slice(AD_STATS(objId).PixelIdxList) > (Background(min([numel(Background) objId]))+addMaterial_Shift));    % get indeces with intensities higher than bg+shift
                                PixelIdxList = AD_STATS(objId).PixelIdxList(indecesId);   %#ok<FNDSB> % generate new indeces
                                mask(PixelIdxList) = 1;     % generate mask
                                IntensityA(objId) = max(slice(PixelIdxList));
                            end
                        case 'Sum intensity'
                            Intensity1(objId) = sum(slice(STATS1(objId).PixelIdxList));
                            Intensity2(objId) = sum(slice(STATS2(idx(objId)).PixelIdxList));
                            if background_Check == 1 && CC1.NumObjects == BG_CC.NumObjects
                                Background(objId) = sum(slice(BG_STATS(bg_idx(objId)).PixelIdxList));
                            end
                            if additionalThresholdingCheck
                                indecesId = find(slice(AD_STATS(objId).PixelIdxList) > (Background(min([numel(Background) objId]))+addMaterial_Shift));    % get indeces with intensities higher than bg+shift
                                PixelIdxList = AD_STATS(objId).PixelIdxList(indecesId);   %#ok<FNDSB> % generate new indeces
                                mask(PixelIdxList) = 1;     % generate mask
                                IntensityA(objId) = sum(slice(PixelIdxList));
                            end
                    end
                    
                    % subtract background
                    if subtractBg_Check == 1 && background_Check == 1
                        Intensity1(objId) = Intensity1(objId) - Background(min([numel(Background) objId]));
                        Intensity2(objId) = Intensity2(objId) - Background(min([numel(Background) objId]));
                        if additionalThresholdingCheck
                            IntensityA(objId) = IntensityA(objId) - Background(min([numel(Background) objId]));
                        end
                    end
                    
                    % generate filename/slice name for excel
                    if iscell(inputFn)
                        s(rowId, 1) = inputFn(sliceId);
                    else
                        s(rowId, 1) = {inputFn};
                    end
                    
                    % generate slice number for excel
                    s(rowId, 2) = {num2str(sliceId)};
                    
                    % generate intensity 1 for excel
                    s(rowId, 3) = {num2str(Intensity1(objId))};
                    
                    % generate intensity 2 for excel
                    s(rowId, 4) = {num2str(Intensity2(objId))};
                    if background_Check
                        % save background
                        if CC1.NumObjects == BG_CC.NumObjects
                            s(rowId, 5) = {num2str(Background(objId))};
                        elseif objId==1     % save averaged background once
                            s(rowId, 5) = {num2str(Background(1))};
                        end
                    end
                    if calculateRatioCheck
                        % generate ratio, intensity2/intensity1
                        s(rowId, 6) = {num2str(Intensity1(objId)/Intensity2(objId))};
                    end
                    
                    if additionalThresholdingCheck
                        % report intensities of additional thresholding
                        s(rowId, 7) = {num2str(IntensityA(objId))};
                    end
                    
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(TripleArea.MaterialName1, [sliceId, round(X1(objId,:))], Intensity1(objId));
                    obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(TripleArea.MaterialName2, [sliceId, round(X2(idx(objId),:))], Intensity2(objId));
                    
                    if background_Check == 1 && CC1.NumObjects == BG_CC.NumObjects
                        obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(TripleArea.BackgroundMaterial, [sliceId, round(X3(bg_idx(objId),:))], Background(objId));
                    end
                    if additionalThresholdingCheck
                        try
                            if addMaterial_Index == material1_Index
                                coordinates = round(X1(objId,:));
                            else
                                coordinates = round(X2(idx(objId),:));
                            end
                            coordinates(2) = coordinates(2) + 18;    % shift coordinate for text
                            obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels('thres:', [sliceId, coordinates], IntensityA(objId));
                        catch err
                        end
                    end
                    
                    rowId = rowId + 1;
                end
                
                if background_Check == 1 && CC1.NumObjects ~= BG_CC.NumObjects  % add text of averaged background
                    for bgId = 1:numel(BG_STATS)
                        obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(TripleArea.BackgroundMaterial, [sliceId, round(X3(bgId,:))], Background(min([numel(Background) bgId])));
                    end
                end
                
                if calculateRatioCheck
                    Ratio = [Ratio; Intensity1./Intensity2]; %#ok<AGROW>
                end
                
                % do additional thresholding
                if additionalThresholdingCheck
                    obj.mibModel.setData2D('mask', mask, sliceId, NaN, NaN, options);
                end
                
                if obj.View.handles.exportMatlabCheck.Value
                    TripleArea.Filename = [TripleArea.Filename; repmat(s(rowId-1, 1), [numel(STATS1), 1])];
                    TripleArea.SliceNumber = [TripleArea.SliceNumber; repmat(sliceId, [numel(STATS1), 1])];
                    TripleArea.Intensity1 = [TripleArea.Intensity1; Intensity1];
                    TripleArea.Intensity2 = [TripleArea.Intensity2; Intensity2];
                    if additionalThresholdingCheck
                        TripleArea.IntensityA = [TripleArea.IntensityA; IntensityA];
                    end
                    
                    if numel(Background) == numel(STATS1)
                        TripleArea.IntensityBg = [TripleArea.IntensityBg; Background];
                    else
                        TripleArea.IntensityBg = [TripleArea.IntensityBg; repmat(Background, [numel(STATS1), 1])];
                    end
                    if calculateRatioCheck
                        TripleArea.Ratio = [TripleArea.Ratio; Intensity1./Intensity2];
                    end
                  
                end
                
                %rowId = rowId + 1;
            end
            
            if connectionsCheck
                obj.mibModel.setData3D('selection', selection, NaN, 4, NaN, options);
            end
            
            if obj.View.handles.savetoExcel.Value
                waitbar(.99, wb, 'Generating Excel file...');
                xlswrite2(fn, s, 'Sheet1', 'A1');
            end
            
            if obj.View.handles.exportMatlabCheck.Value
                waitbar(1, wb, 'Exporting to Matlab...');
                fprintf('TripleIntensity: a structure with results "%s" was created\n', obj.matlabExportVariable);
                assignin('base', obj.matlabExportVariable, TripleArea);
            end
            
            % turn on annotations
            obj.mibModel.mibShowAnnotationsCheck = 1;
            notify(obj.mibModel, 'plotImage');
            
            % plot histogram
            if calculateRatioCheck
                figure(321);
                hist(Ratio, ceil(numel(Ratio)/2));
                t1 = title(sprintf('Ratio (%s/%s) calculated from %s, N=%d', ...
                    obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{material1_Index}, ...
                    obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{material2_Index}, parameterToCalculate, numel(Ratio)));
                xl = xlabel(sprintf('Ratio (%s/%s)',...
                    obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{material1_Index}, obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames{material2_Index}));
                yl = ylabel('Number of cells');
                grid;
                set(xl, 'Fontsize', 12);
                set(yl, 'Fontsize', 12);
                set(t1, 'Fontsize', 14);
            end
            
            delete(wb);
        end
    end
end