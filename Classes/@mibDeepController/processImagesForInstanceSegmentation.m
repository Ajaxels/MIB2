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
% Date: 08.05.2024

function processImagesForInstanceSegmentation(obj, preprocessFor)
% function processImagesForInstanceSegmentation(obj, preprocessFor)
% Preprocess labels for 2D instance segmentation for training and prediction
% as result, mat-files with the following variables are created:
% - instanceBoxes, matrix  [N×4 double] containing bounding box coordinates of objects, where N is a number of objects on the image
% - instanceNames, array [N×1 categorical] containing names of objects,
% currently the same name should be used for all objects, can be any string
% converted to categorical.
% - instanceMasks, matrix [720×1280×N logical] binary masks where each slice
% represents individual object that should match the corresponding entry in
% instanceBoxes and instanceNames
%
% Parameters:
% preprocessFor: a string with target, 'training', 'prediction'

if nargin < 2; uialert(obj.View.gui, 'processImagesForInstanceSegmentation: the second parameter is required!', 'Preprocessing error'); return; end

if strcmp(preprocessFor, 'training')
    imageDirIn = obj.BatchOpt.OriginalTrainingImagesDir;
    imageFilenameExtension = obj.BatchOpt.ImageFilenameExtensionTraining{1};
    trainingSwitch = 1;     % a switch indicating processing of images for training    
elseif strcmp(preprocessFor, 'prediction')
    imageDirIn = obj.BatchOpt.OriginalPredictionImagesDir;
    imageFilenameExtension = obj.BatchOpt.ImageFilenameExtension{1};
    trainingSwitch = 0;
    uialert(obj.View.gui, 'processImagesForInstanceSegmentation: not yet implemented!', 'Preprocessing error'); 
    return; 
else
    uialert(obj.View.gui, 'processImagesForInstanceSegmentation: the second parameter is wrong!', 'Preprocessing error'); return;
end

%% Load data
if ~isfolder(fullfile(imageDirIn, 'Images'))
    uialert(obj.View.gui, sprintf('!!! Warning !!!\n\nThe images and models should be arranged in "Images" and "Labels" directories under\n\n%s\n\nCopy files there and try again!', imageDirIn), ...
        'Old project or missing files', 'Icon', 'warning');
    return;
end

imgFilelist = dir(fullfile(imageDirIn, 'Images', ['*.' lower(imageFilenameExtension)]));
if isempty(imgFilelist)
    uialert(obj.View.gui, ...
        sprintf('!!! Error !!!\n\Image files are missing in\n%s', fullfile(imageDirIn, 'Images')), ...
        'Missing image files!');
    return;
end
numImgFiles = numel(imgFilelist);

obj.BatchOpt.showWaitbar = true;
if obj.BatchOpt.showWaitbar
    pwb = PoolWaitbar(1, sprintf('Creating labels datastore\nPlease wait...'), [], ...
        sprintf('%s %s: processing for %s', obj.BatchOpt.Workflow{1}, obj.BatchOpt.Architecture{1}, preprocessFor), ...
        obj.View.gui);
else
    pwb = [];
end
warning('off', 'MATLAB:MKDIR:DirectoryExists');

% preparing the directories
% delete exising directories and files
try
    if trainingSwitch
        outputDir = fullfile(imageDirIn, 'LabelsInstances');
        if isfolder(outputDir)
            rmdir(outputDir, 's');
        end
    else
        outputDir = fullfile(imageDirIn, 'GroundTruthLabelsInstances');
        if isfolder(outputDir)
            rmdir(outputDir, 's');
        end
    end
catch err
    mibShowErrorDialog(obj.View.gui, err, 'Problems with removing directories');
    if obj.BatchOpt.showWaitbar; delete(pwb); end
    return;
end

% make new directory
mkdir(outputDir);

labelsExists = 0;     % models exists
if strcmp(obj.BatchOpt.ModelFilenameExtension{1}, 'MODEL')
    % read number of materials for the first file
    files = dir(fullfile(imageDirIn, 'Labels', '*.model'));
    if isempty(files) && trainingSwitch
        uialert(obj.View.gui, ...
            sprintf('!!! Error !!!\n\nModel files are missing in\n%s', fullfile(imageDirIn, 'Labels')), ...
            'Missing model files!');
        if obj.BatchOpt.showWaitbar; delete(pwb); end
        return;
    elseif ~isempty(files)
        labelsExists = 1;     % models exists
    end
else
    files = dir(fullfile(imageDirIn, 'Labels', lower(['*.' obj.BatchOpt.ModelFilenameExtension{1}]))); % extensions on Linux are case sensitive
    if ~isempty(files)
        labelsExists = 1;     % models exists
    end
end

% define usage of parallel computing
if obj.BatchOpt.UseParallelComputing
    parforArg = obj.View.handles.PreprocessingParForWorkers.Value;    % Maximum number of workers running in parallel
    if isempty(gcp('nocreate')); parpool(parforArg); end % create parpool
else
    parforArg = 0;      % Maximum number of workers running in parallel, when 0 a single core used without parallel
end

% create local variables for parfor
mode2D3DParFor = obj.BatchOpt.Workflow{1}(1:2);
showWaitbarParFor = obj.BatchOpt.showWaitbar;
compressModels = obj.BatchOpt.CompressProcessedModels;
singleModelTrainingFileParFor = obj.BatchOpt.SingleModelTrainingFile;

if obj.BatchOpt.showWaitbar
    if pwb.getCancelState(); delete(pwb); return; end
    pwb.updateText(sprintf('Processing instance labels\nPlease wait...'));
    pwb.setIncrement(10);  % set increment step to 10
end

labelsDS = [];
if labelsExists
    if strcmp(obj.BatchOpt.Workflow{1}(1:2), '2D')  % preprocess files for 2D networks
        if singleModelTrainingFileParFor
            fileList = dir(fullfile(imageDirIn, 'Labels', '*.model'));
            fullModelPathFilenames = arrayfun(@(filename) fullfile(imageDirIn, 'Labels', cell2mat(filename)), {fileList.name}, 'UniformOutput', false);  % generate full paths
            labelsDS = matfile(fullModelPathFilenames{1});     % models
        else
            switch obj.BatchOpt.ModelFilenameExtension{1}
                case 'MODEL'
                    labelsDS = imageDatastore(fullfile(imageDirIn, 'Labels'), ...
                        'IncludeSubfolders', false, ...
                        'FileExtensions', '.model', 'ReadFcn', @mibDeepStoreLoadModel);
                    % I = readimage(labelsDS,1);  % read model test
                    % reset(labelsDS);
                otherwise
                    labelsDS = imageDatastore(fullfile(imageDirIn, 'Labels'), ...
                        'IncludeSubfolders', false, ...
                        'FileExtensions', lower(['.' obj.BatchOpt.ModelFilenameExtension{1}]));
            end
            if numel(labelsDS.Files) ~= numImgFiles
                uialert(obj.View.gui, ...
                    sprintf('!!! Error !!!\n\nIn this mode number of model files should match number of image files!'), 'Error');
                if obj.BatchOpt.showWaitbar; delete(pwb); end
                return;
            end
        end
    else    % preprocess files for 3D networks
        
    end    % read corresponding model
end

if singleModelTrainingFileParFor && ~isempty(labelsDS)
    if size(labelsDS.(labelsDS.modelVariable), 3) < numImgFiles
        uialert(obj.View.gui, ...
            sprintf('!!! Error !!!\n\nNumber of slices in the model file is smaller than number of images\n\nYou may want to uncheck the "Single MIB model file" checkbox!'), ...
            'Wrong model file');
        if showWaitbarParFor; delete(pwb); end
        return;
    end
end

if showWaitbarParFor
    pwb.setCurrentIteration(0);
    pwb.updateMaxNumberOfIterations(numImgFiles);
end

parfor (imgId=1:numImgFiles, parforArg)
%for imgId=1:numImgFiles
    if labelsExists
        if strcmp(mode2D3DParFor, '2D')
            if singleModelTrainingFileParFor
                labelMap = labelsDS.(labelsDS.modelVariable)(:,:,imgId);    % get 2D slice from the model
                [~, fnModOut] = fileparts(imgFilelist.Files{imgId});    % get filename for the model
                fnModOut = sprintf('Labels_%s', fnModOut);  % generate name for the output model file
            else
                labelMap = readimage(labelsDS, imgId);      % read corresponding model
                [~, fnModOut] = fileparts(labelsDS.Files{imgId});    % get filename for the model
            end

            % get label size
            [height, width] = size(labelMap);
            % detect bounding boxes
            stats = regionprops(labelMap, {'BoundingBox', 'PixelIdxList'});
            instanceBoxes = ceil(reshape([stats.BoundingBox], [4, 8])');
            % get number of objects
            numObjects = numel(stats);
            % allocate labels
            instanceNames = categorical(repmat({'object'}, [numObjects, 1]));
            instanceMasks = zeros([height, width, numObjects], 'logical');
            for objId = 1:numObjects
                PixelIdxListShift = height*width*(objId-1);     % calculate shift of pixel Ids
                instanceMasks(stats(objId).PixelIdxList + PixelIdxListShift) = true;
            end

            % save mat-file
            saveInstanceLabelsParFor(fullfile(outputDir, [fnModOut '.mat']), imgFilelist(imgId).name, instanceBoxes, instanceNames, instanceMasks, compressModels)
        else   % 3D case
            
        end
    end
    
    if showWaitbarParFor && mod(imgId, 10) == 1; increment(pwb); end
end
if obj.BatchOpt.showWaitbar; delete(pwb); end

end
