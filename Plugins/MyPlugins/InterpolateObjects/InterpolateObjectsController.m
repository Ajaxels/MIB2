classdef InterpolateObjectsController < handle
    properties
        mibModel
        % handles to the model
        noGui = 1
        % a variable indicating a plugin without GUI
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when plugin is closed
    end
    
    methods
        function obj = InterpolateObjectsController(mibModel)
            obj.mibModel = mibModel;    % assign model
            
            % check for the virtual stacking mode and close the controller
            if isprop(obj.mibModel.I{obj.mibModel.Id}, 'Virtual') && obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
                warndlg(sprintf('!!! Warning !!!\n\nThis plugin is not compatible with the virtual stacking mode!\nPlease switch to the memory-resident mode and try again'), ...
                    'Not implemented');
                return;
            end
            
            obj.calculateBtn_Callback();  % start the main function
        end
        
        % ------------------------------------------------------------------
        % Main function for calculations
        % Add your code here
        function calculateBtn_Callback(obj)
            % start main calculation of the plugin
            global mibPath;
            
            % get current slice number
            currentSliceNumber = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
            
            % ask for starting and ending slice numbers
            prompts = {'Starting slice number'; 'Ending slice number'};
            defAns = {num2str(currentSliceNumber-1); num2str(currentSliceNumber+1)};
            dlgTitle = 'Settings';
            options.WindowStyle = 'modal';
            [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
            if isempty(answer); return; end 

            slice_start = str2double(answer{1});   % slice number before the gap
            slice_end = str2double(answer{2});     % slice number after the gap

            % do backup
            obj.mibModel.mibDoBackup('model', 1);

            % add a waitbar to follow the progress
            wb = waitbar(0, 'Please wait');

            % get max number of materials for models < 256
            maxMaterialId = numel(obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames);  
            
            % define options to get the dataset
            getDataOptions.z = [slice_start, slice_end];
            
            % make a loop over materials
            for matId = 1:maxMaterialId
                % get a subvolume that includes material with index matId for slices 30,31,32
                % it is returned as cell array, so it needs to be converted
                % to standard matrix
                subModel = cell2mat(obj.mibModel.getData3D('model', NaN, NaN, matId, getDataOptions));
                % interpolate the material
                subModel = mibInterpolateShapes(subModel, obj.mibModel.preferences.SegmTools.Interpolation.NoPoints);
                % return back the subvolume the model
                obj.mibModel.setData3D('model', subModel, NaN, NaN, matId, getDataOptions);
                waitbar(matId/maxMaterialId, wb);   % update the waitbar
            end
            delete(wb);         % delete the waitbar
            notify(obj.mibModel, 'plotImage');
        end
    end
end