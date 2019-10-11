classdef mibImageUndo < handle
    % This class is resposnible to store the previous versions of the dataset, to be used for Undo (Ctrl+Z) command
    
    % The usage of this class is implemented via Ctrl+Z short cut. It allows to return one step back to the previous version of the
    % dataset. It works with @em do_undo function of mib.m
    % @attention Use of undo, increase memory consumption. The Undo may be switched off in the @em Preferences of
    % mib.m: @em Menu->File->Preferences
	
    % Copyright (C) 04.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
    % part of Microscopy Image Browser, http:\\mib.helsinki.fi
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
	%
	% Updates
	% 

    properties (SetAccess = public, GetAccess = public)
        enableSwitch         % Enable/disable undo operation
        % a variable to store whether Undo is available or not:
        % @li @b 1 - enable
        % @li @b 0 - disable
        type
        % a variable to store type of the data: ''image'', ''model'', ''selection'', ''mask'','labels',''measurement'',''everything'' (for imageData.model_type==''uint6'' only)
        undoList
        % a structure to store the list of the actions for undo
        % @li @b .type - type of the data: ''image'', ''model'', ''selection'', ''mask'', 'labels',''measurement'',''everything'' (for imageData.model_type==''uint6'' only)
        % @li @b .data - a field to store a cell with 3D dataset or 2D slice
        % @li @b .meta - meta containers.Map , for the ''image'' type
        % @li @b .options - a substructure with all additional paramters,
        % as for example the following list
        % @li @b .orient - orientation of the slice, @b 1 - xz, @b 2 - yz, @b 4 - yx
        % @li @b .switch3d - a switch indicating 3D dataset
        % @li @b .x - coordinates of the stored of the part of the dataset,as [roiId; xmin, xmax]
        % @li @b .y - coordinates of the stored of the part of the dataset
        % @li @b .z - coordinates of the stored of the part of the dataset
        % @li @b .t - coordinates of the stored of the part of the dataset
        % @li @b .viewPort - viewPort structure (only for the 'image')
        % @li @b .id - index of MIB container
        max_steps
        % a variable to limit maximal number of history steps
        max3d_steps
        % a variable to limit maximal number of history for the 3D datasets
        undoIndex
        % a variable to keep index of @em NaN (currently restored dataset) element of the undoList structure
        prevUndoIndex
        % a variable to keep previous index of NaN element of the undoList structure, for use with Ctrl+Z
        index3d
        % an array of indeces of the 3D datasets
    end
    
    events
        none   %
    end
    
    methods
        function obj = mibImageUndo(max_steps, max3d_steps)
            % function obj = mibImageUndo(max_steps, max3d_steps)
            % mibImageUndo class constructor
            %
            % Constructor for the mibImageUndo class. Create a new instance of
            % the class with default parameters
            %
            % Parameters:
            % max_steps: maximal length of the history log
            % max3d_steps: maximal length of the 3D history log
            if nargin < 2; max3d_steps = 1; end
            if nargin < 1; max_steps = 8; end
            obj.setNumberOfHistorySteps(max_steps, max3d_steps);
            obj.clearContents();
        end
        
        function clearContents(obj)
            % function clearContents(obj)
            % Set all elements of the class to default values
            
            %| 
			% @b Examples:
            % @code mibImageUndo.clearContents(); @endcode
            % @code clearContents(obj); // Call within the class @endcode
            
            obj.type = '';
            obj.undoList = struct('type', NaN, 'data', NaN, 'meta', NaN, 'orient', NaN, 'x', NaN, 'y', NaN, 'z', NaN, 't', NaN, 'viewPort', [], 'switch3d', NaN, 'options', struct);
            obj.undoList.data = {NaN};
            obj.undoIndex = 1;
            obj.prevUndoIndex = 0;
            obj.index3d = [];
        end
        
        function setNumberOfHistorySteps(obj, max_steps, max3d_steps)
            % setNumberOfHistorySteps(obj, max_steps, max3d_steps)
            % Set number of history steps for undo
            obj.clearContents();
            obj.max_steps = max_steps;
            obj.max3d_steps = max3d_steps;
        end
        
        function store(obj, type, data, meta, options)
            % function store(obj, type, data, meta, options)
            % Store the data
            %
            % Parameters:
            % type: a string that defines the type of the stored data:
            % ''image'', ''model'', ''selection'', ''mask'', ''everything'' (for imageData.model_type==''uint6'' only), 'labels', 'lines3d'
            % data: a cell/cell array with actual 3D or 2D dataset to store, 
            %       or with a structure for labels or with Lines3D class for lines3d object
            % meta: [@em optional] a imageData.meta containers.Map, not required for ''model'', ''selection'', ''mask'', ''everything'', can be @em NaN
            % options: a structure with fields:
            % @li .orient -> [@em optional], a number with the orientation of the dataset
            % @li .y -> [@em optional], [roiId][ymin, ymax] of the part of the dataset to store
            % @li .x -> [@em optional], [roiId][xmin, xmax] of the part of the dataset to store
            % @li .z -> [@em optional], [roiId][zmin, zmax] of the part of the dataset to store
            % @li .t -> [@em optional], [roiId][tmin, tmax] of the part of the dataset to store
            % @li .viewPort -> [@em optional] viewPort structure (only for the 'image')
            % @li .switch3d -> a switch indicating 3D dataset
            % @li .id -> index of MIB container to store
            
            %| 
			% @b Examples:
            % @code storeOptions.t = [5 5]; @endcode
            % @code mibImageUndo.store('image', img, meta, storeOptions); // store 3D image dataset at the 5th time point @endcode
            % @code store(obj, 'selection', selection, NaN, storeOptions); // Call within the class; store selection at the 5th time point @endcode
            
            if obj.enableSwitch == 0; return; end
            if nargin < 5; options = struct(); end
            if nargin < 4; meta = NaN; end
            if nargin < 3; error('Store Undo: please provide type and data to store!'); end
            
            if ~isfield(options, 'viewPort'); options.viewPort = []; end
            if ~isfield(options, 'id'); options.id = []; end
            
            % check for empty datasets, that are coming for example from
            % ROIs outside the image
            for roiId=numel(data):-1:1
                if isempty(data{roiId})
                    data{roiId} = [];
                    if isfield(options, 'x')
                        options.x(roiId, :) = [];
                    end
                    if isfield(options, 'y')
                        options.y(roiId, :) = [];
                    end
                end
            end
            if isempty(data{1}); return; end   % no data to store
            
            if ~isfield(options, 'switch3d') 
                if strcmp(type, 'image')
                    dimId = 4;
                else
                    dimId = 3;
                end
                if size(data{1}, dimId) > 1
                    options.switch3d = 1;
                else
                    options.switch3d = 0;
                end
            end
            if ~isfield(options, 'orient'); options.orient = NaN; end % options.orient = NaN identifies 3D dataset
            if ~isfield(options, 'x'); options.x = [1, size(data{1}, 2)]; end
            if ~isfield(options, 'y'); options.y = [1, size(data{1}, 1)]; end
            if strcmp(type, 'image')
                if ~isfield(options, 'z'); options.z = [1, size(data{1}, 4)]; end
                if ~isfield(options, 't'); options.t = [1, size(data{1}, 5)]; end
            else
                if ~isfield(options, 'z'); options.z = [1, size(data{1}, 3)]; end
                if ~isfield(options, 't'); options.t = [1, size(data{1}, 4)]; end
            end
            
            % crop undoList
            if options.switch3d && obj.max3d_steps == 0 && size(data{1}, 4) > 1
                clearContents(obj);
                return;
            else
                obj.undoList = obj.undoList(1:obj.undoIndex);
                obj.index3d = obj.index3d(obj.index3d < obj.undoIndex);
            end
            if isnan(options.t(1)); options.t = [1 1]; end
                
            % calculate number of stored 3d datasets
            newMinIndex = 1;
            if options.switch3d    % adding 3D dataset
                if (numel(obj.index3d)) == obj.max3d_steps - 1 && obj.max3d_steps > 1
                    newMinIndex = obj.index3d(1)+1;   % the element of obj.undoList with this index is going to be number 1
                elseif (numel(obj.index3d)) == obj.max3d_steps && obj.max3d_steps == 1
                    newMinIndex = obj.index3d(1) + 1;   % tweak for a single stored 3D dataset
                elseif numel(obj.undoList) == obj.max_steps + 1
                    newMinIndex = 2;
                end
            else
                if numel(obj.undoList) == obj.max_steps + 1
                    newMinIndex = 2;
                end
            end
            
            % shift undoList when it gets overloaded
            obj.undoList = obj.undoList(newMinIndex:end);
            % update index3d
            obj.index3d = obj.index3d - (newMinIndex - 1);
            obj.index3d = obj.index3d(obj.index3d>0);
            
            % to check for entry of the first element
            if isstruct(obj.undoList(1).data{1}) || isa(obj.undoList(1).data{1}, 'Lines3D')
                obj.undoIndex = numel(obj.undoList) + 1;
            else
                if ~isnan(obj.undoList(1).data{1}(1))
                    obj.undoIndex = numel(obj.undoList) + 1;
                else
                    obj.undoIndex = 2;      
                end
            end
            
            obj.prevUndoIndex = obj.undoIndex - 1;
            
            obj.undoList(obj.undoIndex-1).type = type;
            obj.undoList(obj.undoIndex-1).data = data;
            obj.undoList(obj.undoIndex-1).options = options;
            
            % containers.Map is a class and should be reinitialized,
            % the plain copy (obj.undoList(obj.undoIndex-1).meta = meta) results in just a new copy of its handle
            if isa(meta, 'double')
                obj.undoList(obj.undoIndex-1).meta = NaN;
            else
                obj.undoList(obj.undoIndex-1).meta = containers.Map(meta.keys, meta.values);
            end
            
            obj.undoList(obj.undoIndex).type = NaN;
            obj.undoList(obj.undoIndex).data = {NaN};
            obj.undoList(obj.undoIndex).meta = NaN;
            obj.undoList(obj.undoIndex).options = struct();
            
            if options.switch3d
                obj.index3d(end+1) = obj.undoIndex-1;
            end
        end
        
        function [type, data, meta, options] = undo(obj, index)
            % function [type, data, meta, options] = undo(obj, index)
            % Recover the stored dataset
            %
            % Parameters:
            % index: [@em Optional] - index of the dataset to restore. When omitted return the last stored dataset
            %
            % Return values:
            % type: a string that defines the type of the stored data: ''image'', ''model'', ''selection'', ''mask'', ''everything'' (for imageData.model_type==''uint6'' only)
            % data: a variable where to retrieve the dataset
            % meta: [@em optional, NaN for 2D] a imageData.meta containers.Map, not required for ''model'', ''selection'', ''mask'', ''everything''
            % options: a structure with fields:
            % @li .orient -> [@em optional], a number with the orientation of the dataset, for 2D slices; or NaN for 3D
            % @li .y -> [ymin, ymax] coordinates of the stored of the part of the dataset
            % @li .x -> [xmin, xmax] coordinates of the stored of the part of the dataset
            % @li .z -> [zmin, zmax] coordinates of the stored of the part of the dataset
            % @li .z -> [tmin, tmax] coordinates of the stored of the part of the dataset
            % @li .viewPort -> viewPort structure (only for the 'image')
            % @li .switch3d -> a switch indicating 3d dataset
            % @li .id -> index of MIB container
            
            %| 
			% @b Examples:
            % @code [type, img, meta, options] = mibImageUndo.undo(); // recover the image @endcode
            % @code [type, img] = undo(obj); // Call within the class; recover the image @endcode
            if obj.enableSwitch == 0; return; end
            if nargin < 2
                if obj.undoIndex == numel(obj.undoList)
                    index = obj.undoIndex - 1;
                else
                    index = obj.undoIndex + 1;
                end
            end
            
            type = obj.undoList(index).type;
            data = obj.undoList(index).data;
            %meta = obj.undoList(index).meta;
            if isa(obj.undoList(index).meta, 'double')  % means NaN
                meta = NaN;
            else
                % containers.Map is a class and should be reinitialized,
                % the plain copy (obj.undoList(obj.undoIndex-1).meta = meta) results in just a new copy of its handle
                meta = containers.Map(obj.undoList(index).meta.keys, obj.undoList(index).meta.values);
            end
            options = obj.undoList(index).options;
            obj.undoIndex = index;
        end
        
        
        function removeItem(obj, index)
            % function removeItem(obj, index)
            % Delete a stored item
            %
            % Parameters:
            % index: [@em optional] - index of the item to remove, when empty will remove the last entry
            
            %| 
			% @b Examples:
            % @code mibImageUndo.removeItem(5); // delete item number 5 @endcode
            % @code removeItem(obj, 5); // Call within the class; delete item number 5 @endcode
            if nargin < 2; index = numel(obj.undoList); end
            if obj.undoIndex >= index; obj.undoIndex = obj.undoIndex - 1; end
            vector = 1:numel(obj.undoList);
            obj.undoList = obj.undoList(vector ~= index);
        end
        
        function replaceItem(obj, index, type, data, meta, options)
            % function replaceItem(obj, index, type, data, meta, options)
            % Replace the stored item with a new dataset
            %
            % Parameters:
            % index: an index of the item to replace, when @em empty replace the last entry
            % type: a string that defines the type of the new dataset:  ''image'', ''model'', ''selection'', ''mask'', ''everything'' (for imageData.model_type==''uint6'' only)
            % data: a variable with the new dataset to store
            % meta: [@em optional] imageData.meta containers.Map, not required for ''model'', ''selection'', ''mask'', ''everything'', can be @em NaN
            % options: a structure with fields:
            % @li .orient -> [@em optional], a number with the orientation of the dataset
            % @li .y -> [@em optional], [ymin, ymax] of the part of the dataset to store
            % @li .x -> [@em optional], [xmin, xmax] of the part of the dataset to store
            % @li .z -> [@em optional], [zmin, zmax] of the part of the dataset to store
            % @li .z -> [@em optional], [tmin, tmax] of the part of the dataset to store
            % @li .viewPort -> [@em optional], viewPort structure (only for the 'image')
            % @li .switch3d -> switch that indicates 3D dataset
            % @li .id -> index of MIB container
            
            %| 
			% @b Examples:
            % @code storeOptions.t = [5 5]; @endcode
            % @code mibImageUndo.replaceItem(1, 'image', img, meta, storeOptions); // replace the 1st stored dataset @endcode
            % @code replaceItem(obj, 1, 'selection', selection, storeOptions); // Call within the class; replace the 1st stored dataset  @endcode
            
            %if nargin < 7; orient=NaN; sliceNo=NaN; end;
            %if nargin < 6; timePnt=1; end;
            if nargin < 6; options=struct(); end
            if nargin < 5; meta=NaN; end
            if nargin < 3; type=NaN; data=NaN; end
            if index < 1 || index > numel(obj.undoList); error('Undo:replaceItem wrong index!'); end
            
            if ~isfield(options, 'orient'); options.orient = NaN; end % options.orient = NaN identifies 3D dataset
            if ~isfield(options, 'x'); options.x = [1, size(data,2)]; end
            if ~isfield(options, 'y'); options.y = [1, size(data,1)]; end
            if ~isfield(options, 'z'); options.z = [1, size(data,4)]; end
            if ~isfield(options, 't'); options.t = [1, size(data,5)]; end
            if ~isfield(options, 'viewPort'); options.viewPort = []; end
            if ~isfield(options, 'switch3d') 
                if strcmp(type, 'image')
                    dimId = 4;
                else
                    dimId = 3;
                end
                if size(data{1}, dimId) > 1
                    options.switch3d = 1;
                else
                    options.switch3d = 0;
                end
            end
            
            obj.undoList(index).type = type;
            obj.undoList(index).data = data;
            obj.undoList(index).meta = meta;
            obj.undoList(index).options = options;

            if obj.max3d_steps == 1     % tweak for a single stored 3D dataset
                obj.index3d = index;
            else
                obj.index3d = obj.index3d(obj.index3d ~= index);
                if options.switch3d
                    obj.index3d = sort([obj.index3d index]);
                end
            end
        end
    end
end
