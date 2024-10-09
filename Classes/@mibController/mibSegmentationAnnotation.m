% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function mibSegmentationAnnotation(obj, y, x, z, t, modifier, options)
% function mibSegmentationAnnotation(obj, y, x, z, t, modifier, options)
% Add text annotation to the dataset
%
% Parameters:
% y: y-coordinate of the annotation point
% x: x-coordinate of the annotation point
% z: z-coordinate of the annotation point
% t: t-coordinate of the annotation point
% modifier: a string, to specify what to do with the generated selection
% - @em empty - add annotation to the list of annotations (obj.mibModel.I{obj.mibModel.Id}.hLabels as called from mibController)
% - @em ''control'' - remove closest annotation from the annotation list
% options: [Optional] structure with additional settings
%   .samInteractiveModel - logical, indicating that the tool is used to perform segmentation using segment-anything model
% Return values:
% 

%| @b Examples:
% @code obj.mibSegmentationAnnotation(50, 75, 10, 1, '');  // add an annotation to position [y,x,z,t]=50,75,10,1 @endcode

% Updates
% 28.02.2018, IB, added compatibility with values
% 14.04.2023, IB, added options parameter

if nargin < 7; options =  struct(); end
if ~isfield(options, 'samInteractiveModel'); options.samInteractiveModel = false; end

% check for switch that disables segmentation tools
if obj.mibModel.disableSegmentation == 1; return; end

global mibPath;
defaultAnnotationText = obj.mibModel.getImageProperty('defaultAnnotationText');
defaultAnnotationValue = obj.mibModel.getImageProperty('defaultAnnotationValue');
obj.mibModel.mibDoBackup('labels', 0);

if isempty(modifier)   % add annotation
    if obj.mibView.handles.mibAnnPromptCheck.Value
        title = 'Add annotation';
        if obj.mibModel.mibAnnValueEccentricCheck == 1
            defAns = {defaultAnnotationValue, defaultAnnotationText};
            prompts = {'Annotation value:'; 'Annotation text:'};
        else
            defAns = {defaultAnnotationText, defaultAnnotationValue};
            prompts = {'Annotation text:'; 'Annotation value:'};
        end
        answer = mibInputMultiDlg({mibPath}, prompts, defAns, title);
        if isempty(answer); return; end
        if obj.mibModel.mibAnnValueEccentricCheck == 1
            labelText = answer(2);
            labelValue = str2double(answer{1});
        else
            labelText = answer(1);
            labelValue = str2double(answer{2});
        end
    else
        labelText = {defaultAnnotationText};
        labelValue = defaultAnnotationValue;
    end
    
    obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(labelText, [z, x, y, t], labelValue);
    obj.mibModel.setImageProperty('defaultAnnotationText', labelText{1});
    obj.mibModel.setImageProperty('defaultAnnotationValue', labelValue);
    obj.mibView.handles.mibShowAnnotationsCheck.Value = 1;
    obj.mibModel.mibShowAnnotationsCheck = 1;
elseif strcmp(modifier, 'control')  % remove the closest to the mouse click annotation
    sliceNo = obj.mibModel.I{obj.mibModel.Id}.slices{obj.mibModel.I{obj.mibModel.Id}.orientation}(1);
    sliceNo = [sliceNo - obj.mibModel.preferences.SegmTools.Annotations.ShownExtraDepth, ...
               sliceNo + obj.mibModel.preferences.SegmTools.Annotations.ShownExtraDepth];
    [~, ~, labelPositions] = obj.mibModel.I{obj.mibModel.Id}.getSliceLabels(sliceNo);
    if isempty(labelPositions); return; end
    orientation = obj.mibModel.getImageProperty('orientation');
    if orientation == 4   % xy
        X1 = [x, y];
        X2 = labelPositions(:,2:3);
    elseif orientation == 1   % zx
        X1 = [z,x];
        X2 = labelPositions(:,1:2);
    elseif orientation == 2   % zy
        X1 = [z,y];
        X2 = labelPositions(:,[1 3]);
    end

    % calculate the distances between the labels and the clicked point
    % taken from here, as analogue of D = pdist2(X2,X1,'euclidean');:
    % http://stackoverflow.com/questions/7696734/pdist2-equivalent-in-matlab-version-7
    distVec = sqrt(bsxfun(@plus, sum(X1.^2,2),sum(X2.^2,2)') - 2*(X1*X2'));
    [~, index] = min(distVec);  % find index
    selectedLabelPos = labelPositions(index, :);
    obj.mibModel.I{obj.mibModel.Id}.hLabels.removeLabels(selectedLabelPos);
elseif strcmp(modifier, 'shift') % interpolate annotations
    noLabels = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsNumber();
    if noLabels == 0; return; end % do nothing
    % get previous label data
    labelText = obj.mibModel.I{obj.mibModel.Id}.hLabels.labelText{end};
    labelValue = obj.mibModel.I{obj.mibModel.Id}.hLabels.labelValue(end);
    labelPosition = obj.mibModel.I{obj.mibModel.Id}.hLabels.labelPosition(end,:);
    timepoint = labelPosition(4);

    if z == labelPosition(1)
        obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(labelText, [z, x, y, t], labelValue);
    else
        % range vector between min and max Z
        if labelPosition(1) < z
            z_range = labelPosition(1):z;
        else
            z_range = labelPosition(1):-1:z;
        end
        
        % Interpolate x and y values for each z value
        x_interp = interp1([labelPosition(1); z], [labelPosition(2); x], z_range, 'linear');     % x_interp = interp1([z1 z2], [x1 x2], z_range);
        y_interp = interp1([labelPosition(1); z], [labelPosition(3); y], z_range, 'linear');     % y_interp = interp1([z1 z2], [y1 y2], z_range);
        
        labelPosition = zeros([size(z_range, 2)-1, 4]); % drop the first label
        labelPosition(:, 1) = z_range(2:end);
        labelPosition(:, 2) = x_interp(2:end);
        labelPosition(:, 3) = y_interp(2:end);
        labelPosition(:, 4) = timepoint;
        labelText = repmat(labelText, [size(z_range, 2)-1, 1]);
        labelValue = repmat(labelValue, [size(z_range, 2)-1, 1]);
        
        obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(labelText, labelPosition, labelValue);
    end
end
notify(obj.mibModel, 'updatedAnnotations');     % notify about updated annotation

% count user's points
obj.mibModel.preferences.Users.Tiers.numberOfAnnotations = obj.mibModel.preferences.Users.Tiers.numberOfAnnotations+1;
notify(obj.mibModel, 'updateUserScore');     % update score using default obj.mibModel.preferences.Users.singleToolScores increase

% do SAM interactive segmentation
if options.samInteractiveModel
    obj.mibSegmentationSAM();
end
end
