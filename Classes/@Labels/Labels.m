classdef Labels < matlab.mixin.Copyable
    % @type Labels class is resposnible for keeping Labels/Annotations of the model
    
	% Copyright (C) 16.12.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
	% 
	% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
	%
	% Updates
	% 16.12.2017, IB, adapted for MIB2
    % 28.02.2018, IB, updated to be compatible with values

    properties
        labelText
        % a cell array with labels
        labelValue
        % an array with values for labels
        labelPosition
        % a matrix with coordinates of the labels [pointIndex, z  x  y  t]
    end
    
    methods
        function obj = Labels()
            % function obj = Labels()
            % Constructor for the @type Labels class.
            %
            % Constructor for the Labels class. Create a new instance of
            % the class with default parameters
            %
            % Parameters:
            %
            % Return values:
            % obj - instance of the @type Labels class.
            
            obj.clearContents();
        end
        
        function clearContents(obj)
            % function clearContents(obj)
            % Set all elements of the class to default values
            %
            % Parameters:
            %
            % Return values:
            
            %| 
			% @b Examples:
            % @code obj.mibModel.I{obj.mibModel.Id}.hLabels.clearContents(); @endcode
            % @code clearContents(obj); // Call within the class @endcode
            
            obj.labelText = {};   %  a cell array with labels
            obj.labelValue = [];    % an array with values for the labels
            obj.labelPosition = [];  % a matrix with coordinates of the labels [pointIndex, z, x, y  t]
        end
        
        function addLabels(obj, labels, positions, values)
            % function addLabel(obj, labels, positions, values)
            % Add labels with positions to the class
            %
            % Parameters:
            % labels: a cell array with labels
            % positions: a matrix with coordinates of the labels [pointIndex, z  x  y  t]
            % values: an array of numbers with values for the labels [@em
            % optional], default = 1
            % Return values:
            
            %| 
			% @b Examples:
            % @code
            % labels{1} = 'my label 1';
            % labels{2} = 'my label 2';
            % positions(1,:) = [50, 75, 1, 3]; // position 1: z=1, x=50, y=75, t=3;            
            % positions(2,:) = [50, 75, 2, 5]; // position 1: z=2, x=50, y=75, t=5;
            % @endcode
            % @code obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabel(labels, positions); // add a labels to the list, call from mibController @endcode
            % @code addLabel(obj, labels, positions); // Call within the class;  add a labels to the list @endcode
            
            if ~iscell(labels); labels = cellstr(labels); end
            if numel(labels) ~= size(positions, 1); error('Labels.addLabels: error, number of labels and coordinates mismatch!'); end
            if nargin < 4
                values = zeros([numel(labels), 1]) + 1;
            end
            
            % trim the blanks from the strings
            for i=1:numel(labels)
                labels{i} = strtrim(labels{i});
            end
            
            % transpose if needed
            if size(labels,1) < size(labels,2)
                labels = labels';
            end
            
            if size(values,1) < size(values,2)
                values = values';
            end
            obj.labelText = [obj.labelText; labels];
            obj.labelValue = [obj.labelValue; values];
            
            if size(positions,2) == 3   % fix for old position lists with z,x,y coordinates only
                positions = [positions ones([size(positions,1),1])];
            end
            obj.labelPosition = [obj.labelPosition; positions];
        end
        
        function crop(obj, cropF)
            % function crop(obj, cropF)
            % Recalculation of annotation positions during image crop
            %
            % Parameters:
            % cropF: a vector [x1, y1, dx, dy, z1, dz, t1, dt] with
            % parameters of the crop. @b Note! The units are pixels! Parameters t1 and
            % dt are optional!
            
            %|
            % @b Examples:
            % @code cropF = [100 512 200 512 5 20 7 15];  // define parameters of the crop  @endcode
            % @code cropF2 = [100 512 NaN NaN 5 NaN 7 NaN];  // alternative definition of parameters for the crop  @endcode
            % @code obj.mibModel.I{obj.mibModel.Id}.hLabels.crop(cropF); // adjust coordinates due to cropping @endcode
            % @attention parameters dx, dy, dz, dt are not used, so they can be replaced with NaNs 

            if obj.getLabelsNumber > 0
                obj.labelPosition(:,1) = obj.labelPosition(:,1) - cropF(5) + 1;
                obj.labelPosition(:,2) = obj.labelPosition(:,2) - cropF(1) + 1;
                obj.labelPosition(:,3) = obj.labelPosition(:,3) - cropF(2) + 1;
                if numel(cropF) > 6
                    obj.labelPosition(:,4) = obj.labelPosition(:,4) - cropF(7) + 1;
                end
            end
            
        end
        
        
        function [labelsList, labelValues, labelPositions, indices] = getCurrentSliceLabels(obj)
            % [labelsList, labelValues, labelPositions, indices] = getCurrentSliceLabels(obj)
            % Get list of labels shown at the current slice
            %
            % @note replaced with mibImage.getSliceLabels
            %
            % Parameters:
            %
            % Return values:
            % labelsList:   a cell array with labels
            % labelPositions:   a matrix with coordinates of the labels [labelIndex, z x y t]
            % indices:  indices of the labels
            
            %| 
			% @b Examples:
            % @code [labelsList, labelPositions, indices] = LabelsInstance.getCurrentSliceLabels(); // get all labels from the currently shown slice @endcode
            % @code [labelsList, labelPositions, indices] = getCurrentSliceLabels(obj); // Call within the class;  get all labels from the currently shown slice @endcode
            
            error('replaced with mibImage.getSliceLabels(), use without parameters!');
            
%             rangeT = [handles.Img{handles.Id}.I.slices{5}(1) handles.Img{handles.Id}.I.slices{5}(2)];
%             
%             if handles.Img{handles.Id}.I.orientation == 4   % xy
%                 [labelsList, labelPositions, indices] = obj.getLabels(handles.Img{handles.Id}.I.slices{4}(1), NaN, NaN, rangeT);
%             elseif handles.Img{handles.Id}.I.orientation == 1   % zx
%                 [labelsList, labelPositions, indices] = obj.getLabels(NaN, NaN, handles.Img{handles.Id}.I.slices{1}(1), rangeT);
%             elseif handles.Img{handles.Id}.I.orientation == 2   % zy
%                 [labelsList, labelPositions, indices] = obj.getLabels(NaN, handles.Img{handles.Id}.I.slices{2}(1), NaN, rangeT);
%             end
        end
        
        function [labelsList, labelValues, labelPositions, indices] = getLabels(obj, rangeZ, rangeX, rangeY, rangeT)
            % function [labelsList, labelValues, labelPositions, indices] = getLabels(obj, rangeZ, rangeX, rangeY, rangeT)
            % Get list of labels
            %
            % Parameters:
            % rangeZ: [@em optional] define range of labels to retrieve for
            % Z [minZ maxZ], can be @b NaN
            % rangeX: [@em optional] define range of labels to retrieve for X [minX maxX], can be @b NaN
            % rangeY: [@em optional] define range of labels to retrieve for Y [minY maxY], can be @b NaN
            % rangeT: [@em optional] define range of labels to retrieve for T [minT maxT], can be @b NaN
            %
            % Return values:
            % labelsList:   a cell array with labels
            % labelValues: an array of numbers with values
            % labelPositions:   a matrix with coordinates of the labels [labelIndex, z x y t]
            % indices:  indices of the labels
            
            %| 
			% @b Examples:
            % @code [labelsList, labelValues, labelPositions, indices] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels(); // get all labels @endcode
            % @code [labelsList, labelValues, labelPositions, indices] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels(50); // get all labels from slice 50 @endcode
            % @code [labelsList, labelValues, labelPositions, indices] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels(obj, 50); // Call within the class;  get all labels from slice 50 @endcode
            
            if nargin < 5; rangeT = NaN; end
            if nargin < 4; rangeY = NaN; end
            if nargin < 3; rangeX = NaN; end
            if nargin < 2; rangeZ = NaN; end
            % fetch Z
            labelsList = obj.labelText;
            labelValues = obj.labelValue;
            labelPositions = obj.labelPosition;
            indices = 1:numel(labelsList);
            
            if isempty(labelsList); return; end

            if ~isnan(rangeZ(1))   % sort with Z
                if numel(rangeZ) == 1
                    selIndices = find(round(labelPositions(:,1))==rangeZ);
                else
                    selIndices = find(labelPositions(:,1) >= rangeZ(1) & labelPositions(:,1) <= rangeZ(2));
                end
                labelsList = labelsList(selIndices);
                labelValues = labelValues(selIndices);
                labelPositions = labelPositions(selIndices,:);
                indices = indices(selIndices);  
            end
            if ~isnan(rangeX(1))   % sort with X
                if numel(rangeX) == 1
                    selIndices = find(round(labelPositions(:,2))==rangeX);
                else
                    selIndices = find(labelPositions(:,2) >= rangeX(1) & labelPositions(:,2) <= rangeX(2));
                end
                labelsList = labelsList(selIndices);
                labelValues = labelValues(selIndices);
                labelPositions = labelPositions(selIndices,:);
                indices = indices(selIndices);  
            end
            if ~isnan(rangeY(1))   % sort with Y
                if numel(rangeY) == 1
                    selIndices = find(round(labelPositions(:,3))==rangeY);
                else
                    selIndices = find(labelPositions(:,3) >= rangeY(1) & labelPositions(:,3) <= rangeY(2));
                end
                labelsList = labelsList(selIndices);
                labelValues = labelValues(selIndices);
                labelPositions = labelPositions(selIndices,:);
                indices = indices(selIndices);  
            end
            if ~isnan(rangeT(1))   % sort with Y
                if numel(rangeT) == 1
                    selIndices = find(round(labelPositions(:, 4))==rangeT);
                else
                    selIndices = find(labelPositions(:,4) >= rangeT(1) & labelPositions(:,4) <= rangeT(2));
                end
                labelsList = labelsList(selIndices);
                labelValues = labelValues(selIndices);
                labelPositions = labelPositions(selIndices,:);
                indices = indices(selIndices);  
            end
            if size(indices, 1) < size(indices, 2)
                indices = indices'; 
            end
        end
        
        function [labels, values, positions, indices] = getLabelsById(obj, labelId)
            % function labels, values, positions, indices] = getLabelsById(obj, labelId)
            % Get labels using labelId
            %
            % Parameters:
            % labelId: a variable or a vector with an old label to be updated:
            % - @b a @b single @b number @b or @b a @b column @b of @b numbers:     remove label that have index equal to the number
            % - @b a @b matrix:     remove all labels that have coordinates specified in the matrix [labelIndex, z x y t]
            % - @b a @b cell @b array:     remove all labels that have text specified in the cell array 
            % newLabelText,     a cell or a char string with new text for the label
            %
            % Return values:
            % labels:   - cell array with labels of annotations
            % values:   - array with values of annotations
            % positions: - a matrix with coordinates (index; z,x,y,t)
            % indices: - array with indices of annoations
            %| 
			% @b Examples:
            % @code
            % labelIds = [5, 7, 10]';
            % [labels, values, positions, id] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsById(labelIds); // call from mibController, get labels with indices 5, 7, 10 
            % @endcode
            
            if nargin < 2     % check parameters
                error('Labels.getLabelsById: not enough arguments!');
            end
            labels = [];
            values = [];
            positions = [];
            
            if ischar(labelId); labelId = cellstr(labelId); end    
            
            if iscell(labelId)   % get specified with labelText label
                indices = strcmp(labelId, obj.labelText);
                labels = obj.labelText(indices);
                values = obj.labelValue(indices);
                positions = obj.labelPosition(indices,:);
                return;
            end
            
            if size(labelId, 2) == 1 % a get number update specified index
                labels = obj.labelText(labelId);
                values = obj.labelValue(labelId);
                positions = obj.labelPosition(labelId,:);
                indices = labelId;
                return;
            else    % find and update the specified point
                indices = ismember(obj.labelPosition, labelId, 'rows');
                if sum(indices) ~= 1; return; end % no matches were found
                
                labels = obj.labelText(indices);
                values = obj.labelValue(indices);
                positions = obj.labelPosition(indices,:);
                return;
            end
        end
        
        function labelsNumber = getLabelsNumber(obj)
            % function labelsNumber = getLabelsNumber(obj, rangeZ)
            % Get total number of labels 
            %
            % Parameters:
            %
            % Return values:
            % labelsNumber:   a number of labels
            
            %| 
			% @b Examples:
            % @code labelsNumber = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsNumber(); // get number of labels @endcode
            % @code labelsNumber = getLabelsNumber(obj); // Call within the class;  get number of labels  @endcode
            labelsNumber = numel(obj.labelText);
        end
        
        function [labelsList, labelValues, labelPositions, indices] = getSliceLabels(obj, handles, sliceNumber, timePoint)
            % [labelsList, labelValues, labelPositions, indices] = getSliceLabels(obj, handles, sliceNumber, timePoint)
            % Get list of labels shown at the specified slice
            %
            % Parameters:
            % handles:  a handles structure of im_browser
            % sliceNumber: [@em optional], a slice number to get labels
            % timePoint: [@em optional], a time point to get the labels
            %
            % Return values:
            % labelsList:   a cell array with labels
            % labelPositions:   a matrix with coordinates of the labels [labelIndex, z x y]
            % indices:  indices of the labels
            
            %| 
			% @b Examples:
            % @code [labelsList, labelPositions, indices] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getSliceLabels(handles, 15); // get all labels from the slice 15 @endcode
            % @code [labelsList, labelPositions, indices] = getSliceLabels(obj, handles); // Call within the class;  get all labels from the currently shown slice @endcode
            error('moved to mibImage.getSliceLabels');
            
            if nargin < 4
                timePnt = handles.Img{handles.Id}.I.slices{5}(1);
            end
            if nargin < 3
                [labelsList, labelValues, labelPositions, indices] = getCurrentSliceLabels(obj, handles);
                return;
            end
            
            if handles.Img{handles.Id}.I.orientation == 4   % xy
                [labelsList, labelValues, labelPositions, indices] = obj.getLabels(sliceNumber, NaN, NaN, timePnt);
            elseif handles.Img{handles.Id}.I.orientation == 1   % zx
                [labelsList, labelValues, labelPositions, indices] = obj.getLabels(NaN, NaN, sliceNumber, timePnt);
            elseif handles.Img{handles.Id}.I.orientation == 2   % zy
                [labelsList, labelValues, labelPositions, indices] = obj.getLabels(NaN, sliceNumber, NaN, timePnt);
            end
        end
        
        function removeLabels(obj, labels)
            % removeLabels(obj, labels)
            % Remove specified labels
            %
            % Parameters:
            % labels: a variable or a vector with a label:
            % @li @b omitted:     remove all labels
            % @li @b a @b single @b number @b or @b a @b column @b of @b numbers:     remove label that have index equal to the number
            % @li @b a @b matrix:     remove all labels that have coordinates specified in the matrix [labelIndex, z x y t]
            % @li @b a @b cell @b array:     remove all labels that have text specified in the cell array 
            
            %| 
			% @b Examples:
            % @code
            % labels{1} = 'my label 1';
            % @endcode
            % @code obj.mibModel.I{obj.mibModel.Id}.hLabels.removeLabels(labels); // remove annotations that match labels @endcode
            % @code removeLabels(obj, labels); // Call within the class; remove annotations that match labels  @endcode
            
            if isempty(obj.labelPosition); return; end  % nothing to remove
            
            if nargin < 2      % remove all labels
                choice = questdlg('Delete all annotations from the model?', 'Remove annotations', 'Delete', 'Cancel','Cancel');
                if strcmp(choice, 'Cancel'); return; end
                obj.clearContents();
                return;
            end
            
            if iscell(labels)   % remove specified label
                for i=1:numel(labels)
                    indices = strcmp(labels(i),obj.labelText);
                    obj.labelText(indices) = [];
                    obj.labelValue(indices) = [];
                    obj.labelPosition(indices,:) = [];
                end
                return;
            end
            
            if size(labels, 2) == 1 % a single number or a column, remove specified indices
                    obj.labelText(labels) = [];
                    obj.labelValue(labels) = [];
                    obj.labelPosition(labels,:) = [];
                return;
            else    % find and remove specified points
                for i = 1:size(labels,1)
                    indices = ismember(obj.labelPosition, labels(i,:), 'rows');
                    obj.labelText(indices) = [];
                    obj.labelValue(indices) = [];
                    obj.labelPosition(indices,:) = [];
                end
                return;
            end
        end
        
        function result = renameLabels(obj, oldLabel, newLabelText)
            % function result = renameLabels(obj, oldLabel, newLabelText)
            % Rename specified labels with new text
            %
            % Parameters:
            % oldLabel: a variable or a vector with an old label to be updated:
            % - @b a @b single @b number @b or @b a @b column @b of @b numbers:     remove label that have index equal to the number
            % - @b a @b matrix:     remove all labels that have coordinates specified in the matrix [labelIndex, z x y t]
            % - @b a @b cell @b array:     remove all labels that have text specified in the cell array 
            % newLabelText:     a cell or a char string with new text for the label
            %
            % Return values:
            % result:   result of the function work: @b 1 - good, @b 0 - bad
            
            %| 
			% @b Examples:
            % @code
            % oldLabelId = [5, 7, 10]';
            % label{1} = 'my label 1';
            % @endcode
            % @code obj.mibModel.I{obj.mibModel.Id}.hLabels.renameLabels(oldLabelId, label); // call from mibController, rename labels with indices 5, 7, 10 @endcode
            
            
            result = 0;
            if nargin < 3     % check parameters
                error('Labels.updateLabels: not enough arguments!');
            end
            
            if ischar(oldLabel); oldLabel = cellstr(oldLabel); end    
            if ischar(newLabelText); newLabelText = cellstr(newLabelText); end    
            
            if iscell(oldLabel)   % rename specified with oldLabel label
                indices = strcmp(oldLabel, obj.labelText);
                obj.labelText(indices) = newLabelText;
                result = 1;
                return;
            end
            
            if size(oldLabel, 2) == 1 % a single number update specified index
                obj.labelText(oldLabel) = newLabelText;
                result = 1;
                return;
            else    % find and update the specified point
                indices = ismember(obj.labelPosition, oldLabel, 'rows');
                if sum(indices) ~= 1; return; end % no matches were found
                obj.labelText(indices) = newLabelText;
                result = 1;
                return;
            end
        end
        
        function replaceLabels(obj, labels, positions, values)
            % replaceLabels(obj, labels, positions, values)
            % Replace existing labels with a new list of labels and their
            % values
            %
            % Parameters:
            % labels: a cell array with labels
            % positions: a matrix with coordinates of the labels [pointIndex, x, y, z, t]
            % values: an array of numbers with values of the labels, [@em optional] default = 1
            
            %| 
			% @b Examples:
            % @code
            % labels{1} = 'my label 1';
            % labels{2} = 'my label 2';
            % positions(1,:) = [50, 75, 1, 5]; // position 1: x=50, y=75, z=1,t=5;
            % positions(2,:) = [50, 75, 2, 6]; // position 1: x=50, y=75, z=2, t=6;
            % @endcode
            % @code obj.mibModel.I{obj.mibModel.Id}.hLabels.replaceLabels(labels, positions); // replace labels with a new list @endcode
            % @code replaceLabels(obj, labels, positions); // Call within the class; replace labels with a new list @endcode
            
            if ~iscell(labels); labels = cellstr(labels); end
            if numel(labels) ~= size(positions, 1); error('Labels.replaceLabels: error, number of labels and coordinates mismatch!'); end;
            
            if nargin < 4; values = zeros([numel(labels), 1]) + 1; end
            
            if size(labels,1) < size(labels,2)  % transpose labels to a column
                labels = labels';
            end
            
            if size(values,1) < size(values,2)  % transpose labels to a column
                values = values';
            end
            
            obj.labelText = labels;
            obj.labelValue = values;
            obj.labelPosition = positions;
        end
        
        function result = updateLabels(obj, oldLabel, newLabelText, newLabelPos, newLabelValues)
            % function result = updateLabels(obj, oldLabel, newLabelText, newLabelPos, newLabelValues)
            % Update specified labels with newLabels
            %
            % Parameters:
            % oldLabel: a variable or a vector with an old label to be updated:
            % - @b a @b single @b number @b or @b a @b column @b of @b numbers:     remove label that have index equal to the number
            % - @b a @b matrix:     remove all labels that have coordinates specified in the matrix [labelIndex, z x y t]
            % - @b a @b cell @b array:     remove all labels that have text specified in the cell array 
            % newLabelText:     a cell or a char string with new text for the label
            % newLabelPos:      coordinates of the new label [z, x, y]
            % newLabelValues:   an array of numbers with values of the labels, [@em optional] default = 1
            %
            % Return values:
            % result:   result of the function work: @b 1 - good, @b 0 - bad
            
            %| 
			% @b Examples:
            % @code
            % label{1} = 'my label 1';
            % newPosition(1,:) = [50, 75, 1, 5]; // position 1: x=50, y=75; z=1, t=5
            % @endcode
            % @code obj.mibModel.I{obj.mibModel.Id}.hLabels.updateLabels(label, label, newPosition); // call from mibController, update coordinates of a label that has "my label 1" text @endcode
            
            
            result = 0;
            if nargin < 3     % check parameters
                error('Labels.updateLabels: not enough arguments!');
            end
            
            if ischar(oldLabel); oldLabel = cellstr(oldLabel); end    
            if ischar(newLabelText); newLabelText = cellstr(newLabelText); end    
            
            if nargin < 5; newLabelValues = zeros([numel(newLabelText), 1]) + 1; end
            
            if iscell(oldLabel)   % update specified with labelText label
                    indices = strcmp(oldLabel,obj.labelText);
                    obj.labelText(indices) = newLabelText;
                    obj.labelValue(indices) = newLabelValues;
                    obj.labelPosition(indices,:) = newLabelPos;
                    result = 1;
                return;
            end
            
            if size(oldLabel, 2) == 1 % a single number update specified index
                    obj.labelText(oldLabel) = newLabelText;
                    obj.labelPosition(oldLabel,:) = newLabelPos;
                    obj.labelValue(oldLabel) = newLabelValues;
                    result = 1;
                return;
            else    % find and update the specified point
                indices = ismember(obj.labelPosition, oldLabel, 'rows');
                if sum(indices) ~= 1; return; end % no matches were found
                obj.labelText(indices) = newLabelText;
                obj.labelValue(indices) = newLabelValues;
                obj.labelPosition(indices,:) = repmat(newLabelPos, [numel(sum(indices)), 1] );
                result = 1;
                return;
            end
        end
        
        function saveToFile(obj, filename, options)
            % function saveToFile(obj, filename, options)
            % save Labels to a file
            %
            % Parameters:
            % filename: full path to file
            % options: a structure with optional paramters
            %  .format - a char string
            %       'ann' - MIB annotation format
            %       'landmarksAscii' - amira landmarks in the ascii format
            %       'landmarksBin' - amira landmarks as binaries
            %       'psi' - PSI format ASCII
            %       'xls' - Microsoft Excel format
            %  .showWaitbar - [@em optional] a number 1-show; 0-do not show the waitbar
            %  .outputDir - [@em optional] output directory
            %  .convertToUnits - [@em optional] a logical, or not convert pixel coordinates to the units requires bounding box and pixSize information
            %  .boundingBox - a matrix [x1 width y1 height z1 depth],  required for conversion to units
            %  .pixSize - a MIB structure with pixel sizes
            %  .labelText - [@em optional], instead of obj.labelText save provided labelText
            %  .labelPosition - [@em optional], instead of obj.labelPosition save provided labelPosition
            %  .labelValue - [@em optional], instead of obj.labelValue save provided labelValue
            
            if nargin < 3; options = struct(); end
            if nargin < 2; filename = []; end
            if ~isfield(options, 'showWaitbar'); options.showWaitbar = 1; end
            if ~isfield(options, 'outputDir'); options.outputDir = ''; end
            if ~isfield(options, 'convertToUnits'); options.convertToUnits = 0; end
            
            if options.convertToUnits   % check for required bounding box and pixSize 
                if ~isfield(options, 'boundingBox') || ~isfield(options, 'pixSize') 
                    errordlg(sprintf('!!! Error !!!\n\nConversion to units requires additional parameters: boundingBox and pixSize structure'), 'Not enough parameters!');
                    return;
                end
            end
            
            % obtain filename if it is not provided
            if isempty(filename)
                Filters = {'*.ann;',  'Matlab format (*.ann)';...
                           '*.csv',   'Comma-separated value (*.csv)';...
                           '*.landmarksAscii',   'Amira landmarks ASCII (*.landmarksAscii)';...
                           '*.landmarksBin',   'Amira landmarks BINARY(*.landmarksBin)';...
                           '*.psi',   'PSI format ASCII(*.psi)';...
                           '*.xls',   'Excel format (*.xls)'; };
                
                [filename, path, FilterIndex] = uiputfile(Filters, 'Save annotations...', options.outputDir); %...
                if isequal(filename,0); return; end % check for cancel
                
                filename = fullfile(path, filename);
                
                switch Filters{FilterIndex, 2}
                    case 'Matlab format (*.ann)'
                        options.format = 'ann';
                    case 'Comma-separated value (*.csv)'
                        options.format = 'csv';
                    case 'Amira landmarks ASCII (*.landmarksAscii)'
                        options.format = 'landmarksAscii';
                    case 'Amira landmarks BINARY(*.landmarksBin)'
                        options.format = 'landmarksBin';
                    case 'PSI format ASCII(*.psi)'
                         options.format = 'psi';
                    case 'Excel format (*.xls)'
                        options.format = 'xls';
                end
            end
            if options.showWaitbar; wb = waitbar(0, 'Please wait...', 'Name', 'Saving Annotations', 'WindowStyle','modal'); end
            % obtain format if it is not provided
            if isempty(options.format)
                [path, fn, ext] = fileparts(filename);
                options.format = ext(2:end);
            end
            
            if ~isfield(options, 'labelText')
                labelText = obj.labelText;  %#ok<*PROPLC>
            else
                labelText = options.labelText;
            end
            if ~isfield(options, 'labelPosition')
                labelPosition = obj.labelPosition; 
            else
                labelPosition = options.labelPosition;
            end
            if ~isfield(options, 'labelValue')
                labelValue = obj.labelValue;
            else
                labelValue = options.labelValue;
            end
            
            switch options.format
                case 'ann'
                    save(filename, 'labelText', 'labelValue', 'labelPosition', '-mat', '-v7.3');
                case 'csv'
                    LabelText = labelText;
                    LabelValue = labelValue;
                    LabelPositionXpx = labelPosition(:,2);
                    LabelPositionYpx = labelPosition(:,3);
                    LabelPositionZpx = labelPosition(:,1);
                    LabelPositionTpx = labelPosition(:,4);
                    % convert to coordinates to physical units
                    if isfield(options, 'boundingBox')
                        bb = options.boundingBox;
                        LabelPositionXunits = labelPosition(:,2)*options.pixSize.x + bb(1) - options.pixSize.x/2;
                        LabelPositionYunits = labelPosition(:,3)*options.pixSize.y + bb(3) - options.pixSize.y/2;
                        LabelPositionZunits = labelPosition(:,1)*options.pixSize.z + bb(5) - options.pixSize.z;
                        LabelPositionTunits = labelPosition(:,4);
                        T = table(LabelText, LabelValue, LabelPositionXpx, LabelPositionYpx, LabelPositionZpx, LabelPositionTpx,...
                            LabelPositionXunits, LabelPositionYunits, LabelPositionZunits, LabelPositionTunits);
                    else
                        T = table(LabelText, LabelValue, LabelPositionXpx, LabelPositionYpx, LabelPositionZpx, LabelPositionTpx);
                    end
                    % save results as CSV
                    writetable(T, filename);
                case 'xls'
                    warning('off', 'MATLAB:xlswrite:AddSheet');
                    % Sheet 1
                    s = {'Annotations export'};
                    s(3,1) = {'Annotation'};
                    s(4,1) = {'Text'};
                    s(4,2) = {'Value'};
                    s(3,4) = {'Coordinates, pixels'};
                    s(4,3) = {'Z'};
                    s(4,4) = {'X'};
                    s(4,5) = {'Y'};
                    s(4,6) = {'T'};
                    
                    noAnn = numel(labelText);
                    rowId = 5;
                    s(rowId:rowId+noAnn-1, 1) = labelText;
                    s(rowId:rowId+noAnn-1, 2) = num2cell(labelValue);
                    s(rowId:rowId+noAnn-1, 3:6) = num2cell(labelPosition);
                    
                    % convert to coordinates to physical units
                    if isfield(options, 'boundingBox')
                        s(3,8) = {sprintf('Coordinates, %s', options.pixSize.units)};
                        s(4,8) = {'Z'};
                        s(4,9) = {'X'};
                        s(4,10) = {'Y'};
                        s(4,11) = {'T'};
                        bb = options.boundingBox; 
                        labelPositionsOut(:, 1) = labelPosition(:, 1)*options.pixSize.z + bb(5) - options.pixSize.z;
                        labelPositionsOut(:, 2) = labelPosition(:, 2)*options.pixSize.x + bb(1) - options.pixSize.x/2;
                        labelPositionsOut(:, 3) = labelPosition(:, 3)*options.pixSize.y + bb(3) - options.pixSize.y/2;
                        s(rowId:rowId+noAnn-1, 8:10) = num2cell(labelPositionsOut);
                        s(rowId:rowId+noAnn-1, 11) = num2cell(labelPosition(:, 4));
                    end
                    if options.showWaitbar; waitbar(0.3, wb); end
                    
                    xlswrite2(filename, s, 'Sheet1', 'A1');
                    if options.showWaitbar; waitbar(1, wb); end
                case 'psi'
                    %recalcCoordinates = questdlg(sprintf('Recalculate annotations with respect to the current bounding box or save as they are?'),...
                    %    'Recalculate coordinates', 'Recalculate', 'Save as they are', 'Recalculate');
                    
                    % rearrange to [x, y, z] format from [z, x, y]
                    labelPositionsOut = [labelPosition(:,2) labelPosition(:,3) labelPosition(:,1)];
                    
                    if options.convertToUnits      % recalculate annotations to the real world coordinates
                        bb = options.boundingBox; 
                        labelPositionsOut(:, 1) = labelPositionsOut(:, 1)*options.pixSize.x + bb(1) - options.pixSize.x/2;
                        labelPositionsOut(:, 2) = labelPositionsOut(:, 2)*options.pixSize.y + bb(3) - options.pixSize.y/2;
                        labelPositionsOut(:, 3) = labelPositionsOut(:, 3)*options.pixSize.z + bb(5) - options.pixSize.z;
                    end
                    options.format = 'ascii';
                    options.overwrite = 1;
                    if options.showWaitbar; waitbar(0.3, wb); end
                    points2psi(filename, labelPositionsOut, labelText, labelValue, options);
                    if options.showWaitbar; waitbar(1, wb); end
                case {'landmarksBin', 'landmarksAscii'}
                    % rearrange to [x, y, z] format from [z, x, y]
                    labelPositionsOut = [labelPosition(:,2) labelPosition(:,3) labelPosition(:,1)];
                    
                    if options.convertToUnits      % recalculate annotations to the real world coordinates
                        bb = options.boundingBox; 
                        labelPositionsOut(:, 1) = labelPositionsOut(:, 1)*options.pixSize.x + bb(1) - options.pixSize.x/2;
                        labelPositionsOut(:, 2) = labelPositionsOut(:, 2)*options.pixSize.y + bb(3) - options.pixSize.y/2;
                        labelPositionsOut(:, 3) = labelPositionsOut(:, 3)*options.pixSize.z + bb(5) - options.pixSize.z;
                    end
                    if options.showWaitbar; waitbar(0.3, wb); end
                    if strcmp(options.format, 'landmarksAscii')
                        options.format = 'ascii';
                    else
                        options.format = 'binary';
                    end
                    options.overwrite = 1;
                    points2amiraLandmarks(filename, labelPositionsOut, options);
                    if options.showWaitbar; waitbar(1, wb); end
            end
            fprintf('Saving annotations to %s: done!\n', filename);
            if options.showWaitbar; delete(wb); end
        end
        
        function sortLabels(obj, sortBy, direction)
            % function sortLabels(obj, sortBy, direction)
            % Resort the list of annotation labels
            %
            % Parameters:
            % sortBy: a string with the field to be used for sorting
            % - 'name', @em default sort by the label name
            % - 'value', sort by value
            % - 'x', sort by the X coordinate
            % - 'y', sort by the Y coordinate
            % - 'z', sort by the Z coordinate
            % - 't', sort by the T coordinate
            % direction: a string with sorting direction
            % - 'ascend', @em default sort in the ascending order
            % - 'descend', sort in the descending order
            %
            % Return values:
            % 
            
            %| 
			% @b Examples:
            % @code obj.mibModel.I{obj.mibModel.Id}.hLabels.sortLabels(); // call from mibController, sort the list by the label name @endcode
            % @code obj.mibModel.I{obj.mibModel.Id}.hLabels.sortLabels('name', 'descend'); // call from mibController, sort the list by the label name using descending order @endcode
            
            if nargin < 3; direction = 'ascend'; end
            if nargin < 2; sortBy = 'name'; end
            
            switch sortBy
                case 'name'     % re-sort by label name
                    [~, indices] = sort(obj.labelText);
                case 'value'    % re-sort by label value
                    [~, indices] = sort(obj.labelValue);
                case 'x'        % re-sort by x coordinate
                    [~, indices] = sort(obj.labelPosition(:, 2), direction);
                case 'y'        % re-sort by y coordinate
                    [~, indices] = sort(obj.labelPosition(:, 3), direction);
                case 'z'        % re-sort by z coordinate
                    [~, indices] = sort(obj.labelPosition(:, 1), direction);
                case 't'        % re-sort by t coordinate
                    [~, indices] = sort(obj.labelPosition(:, 4), direction);
            end
            if strcmp(direction, 'descend'); indices = indices(end:-1:1); end
            obj.labelText = obj.labelText(indices);
            obj.labelValue = obj.labelValue(indices);
            obj.labelPosition = obj.labelPosition(indices,:);
        end
        
    end
    
end

