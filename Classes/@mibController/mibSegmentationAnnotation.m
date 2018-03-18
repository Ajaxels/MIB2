function mibSegmentationAnnotation(obj, y, x, z, t, modifier)
% function mibSegmentationAnnotation(obj, y, x, z, t, modifier)
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
%
% Return values:
% 

%| @b Examples:
% @code obj.mibSegmentationAnnotation(50, 75, 10, 1, '');  // add an annotation to position [y,x,z,t]=50,75,10,1 @endcode

% Copyright (C) 16.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 28.02.2018, IB, added compatibility with values

% check for switch that disables segmentation tools
if obj.mibModel.disableSegmentation == 1; return; end

global mibPath;
defaultAnnotationText = obj.mibModel.getImageProperty('defaultAnnotationText');
defaultAnnotationValue = obj.mibModel.getImageProperty('defaultAnnotationValue');
obj.mibModel.mibDoBackup('labels', 0);
if isempty(modifier) || strcmp(modifier, 'shift')  % add annotation
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
    
    obj.mibModel.I{obj.mibModel.Id}.hLabels.addLabels(labelText, [z, x, y, t], labelValue);
    obj.mibModel.setImageProperty('defaultAnnotationText', labelText{1});
    obj.mibModel.setImageProperty('defaultAnnotationValue', labelValue);
    obj.mibView.handles.mibShowAnnotationsCheck.Value = 1;
    obj.mibModel.mibShowAnnotationsCheck = 1;
elseif strcmp(modifier, 'control')  % remove the closest to the mouse click annotation
    [~, ~, labelPositions] = obj.mibModel.I{obj.mibModel.Id}.getSliceLabels();
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
end
notify(obj.mibModel, 'updatedAnnotations');     % notify about updated annotation
end
