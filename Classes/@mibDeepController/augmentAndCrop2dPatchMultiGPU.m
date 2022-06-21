function [patchOut, info, augList, augPars] = augmentAndCrop2dPatchMultiGPU(patchIn, info, inputPatchSize, outputPatchSize, mode, BatchOpt)
% function [patchOut, augList, augPars] = augmentAndCrop2dPatchMultiGPU(patchIn, info, inputPatchSize, outputPatchSize, mode, BatchOpt)
%
% Augment training data by set of operations encoded in obj.AugOpt2D and/or crop the response to the network's output size.
%
% Parameters:
% patchIn: a table with InputImage and ResponsePixelLabelImage fields for semantic segmentation or matrix for classification
% info: additional info about input patch
% inputPatchSize: input patch size as [height, width, depth, color]
% outputPatchSize: output patch size as [height, width, depth, classes]
% mode: string
% 'show' - do not transform/augment, do not crop, only show
% 'crop' - do not transform/augment, only crop and show
% 'aug' - transform/augment, crop and show
%
% Return values:
% patchOut: return the image patches in a two-column table as required by the trainNetwork function for
% single-input networks.
% augList: cell array with used augmentation operations
% augPars: matrix with used values, NaN if the value was not
% used, the second column is the parameter for blend of Hue+Sat
% jitters

augList = {};    % list of used aug functions
augPars = [];       % array with used parameters

% if obj.TrainingProgress.emergencyBrake == 1   % stop training, return. This function is still called multiple times after stopping the training
%     patchOut = [];
%     return;
% end

% check for the classification type training
if strcmp(BatchOpt.Workflow{1}, '2D Patch-wise')
    classificationType = true;
    if ~istable(patchIn)
        % convert to table for the same workflow as with
        % semantic segmentation
        patchIn = table({patchIn}, {info.Label}, 'VariableNames', {'InputImage', 'ResponseLabel'});
        fieldId = 'ResponseLabel';
    else
        % when preview augmentation is used
        fieldId = 'ResponseImage';
    end
else
    classificationType = false;
    % update field names
    if ismember('ResponsePixelLabelImage', patchIn.Properties.VariableNames)  % this one for pixelLabelDatastore
        fieldId = 'ResponsePixelLabelImage';
    else    % this one for imageDatastore
        fieldId = 'ResponseImage';
    end
end

% dynamically convert grayscale to RGB
if size(patchIn.InputImage{1}, 3) ~= inputPatchSize(4)
    for id=1:size(patchIn, 1)
        patchIn.InputImage{id} = repmat(patchIn.InputImage{id}, [1, 1, 3]);
    end
end

if strcmp(mode, 'show')
    inpVol = patchIn.InputImage;
    inpResponse = patchIn.(fieldId);
else
    numAugFunc = numel(obj.Aug2DFuncNames);    % number of functions to be used
    inpVol = cell(size(patchIn, 1), 1);
    inpResponse = cell(size(patchIn, 1), 1);
    augList = cell(size(patchIn, 1), 1);
    augPars = nan([size(patchIn, 1), 17]); % allocate space for augmentation parameters

    cropSwitch = 0;
    if ~classificationType
        diffPatchY = (inputPatchSize(1)-outputPatchSize(1))/2;
        diffPatchX = (inputPatchSize(2)-outputPatchSize(2))/2;

        if diffPatchY ~=0 || diffPatchX ~=0
            y1 = diffPatchY+1;
            y2 = inputPatchSize(1)-diffPatchY;
            x1 = diffPatchX+1;
            x2 = inputPatchSize(2)-diffPatchX;
            cropSwitch = 1;   % crop resulting image to match output patch
        end
    end

    for id=1:size(patchIn, 1)
        if strcmp(mode, 'crop')  % do only crop
            if cropSwitch
                inpResponse{id, 1} = patchIn.(fieldId){id}(y1:y2, x1:x2, :, :);
            else
                inpResponse{id, 1} = patchIn.(fieldId){id};
            end
            inpVol{id, 1}= patchIn.InputImage{id};
        else    % augment and crop
            rndIdx = randi(100, 1)/100;
            if rndIdx > obj.AugOpt2D.Fraction   % if index lower than obj.AugOpt2D.Fraction -> augment the data
                out =  patchIn.InputImage{id};
                respOut = patchIn.(fieldId){id};
                augList{id} = {'Original'};
            else
                if numAugFunc == 0
                    uialert(obj.View.gui, ...
                        sprintf('!!! Error !!!\n\nThe augmentation functions were not selected!'), ...
                        'Missing augmentation fuctions');
                    return;
                end

                %                             % find augmentations, based on probability
                %                             if numAugFunc > 1   % calculate only for number of aug. filters > 1
                %                                 notOk = 1;
                %                                 while notOk
                %                                     randVector = rand([2, numAugFunc]);
                %                                     randVector(2,:) = obj.Aug2DFuncProbability;
                %                                     [~, index] = min(randVector, [], 1);
                %                                     augFuncIndeces = find(index == 1);
                %                                     if numel(augFuncIndeces)>0; notOk = 0; end
                %                                 end
                %                             else
                %                                 augFuncIndeces = 1;
                %                             end

                % find augmentations, based on probability
                % the code above was always returning an
                % augmented patch despite the fact that the probability was too low
                randVector = rand([2, numAugFunc]);
                randVector(2,:) = obj.Aug2DFuncProbability;
                [~, index] = min(randVector, [], 1);
                augFuncIndeces = find(index == 1);

                if isempty(augFuncIndeces)
                    out =  patchIn.InputImage{id};
                    respOut = patchIn.(fieldId){id};
                    augList{id} = {'Original'};
                else
                    augList{id} = obj.Aug2DFuncNames(augFuncIndeces);
                    out = patchIn.InputImage{id};
                    respOut = patchIn.(fieldId){id};
                    for augId = 1:numel(augList{id})
                        switch augList{id}{augId}
                            case 'RandXReflection'
                                out = fliplr(out);
                                if ~classificationType; respOut = fliplr(respOut); end
                            case 'RandYReflection'
                                out = flipud(out);
                                if ~classificationType; respOut = flipud(respOut); end
                            case 'Rotation90'
                                if randi(2) == 1
                                    out = rot90(out);
                                    if ~classificationType; respOut = rot90(respOut); end
                                else
                                    out = rot90(out,3);
                                    if ~classificationType; respOut = rot90(respOut,3); end
                                end
                            case 'ReflectedRotation90'
                                out = rot90(fliplr(out));
                                if ~classificationType; respOut = rot90(fliplr(respOut)); end
                            case 'RandRotation'
                                augPars(id,augId) = obj.AugOpt2D.RandRotation(1) + (obj.AugOpt2D.RandRotation(2)-obj.AugOpt2D.RandRotation(1))*rand;
                                tform = randomAffine2d('Rotation', [augPars(id,augId) augPars(id,augId)]);
                                outputView = affineOutputView([size(out,1) size(out,2)], tform);
                                out = imwarp(out, tform, 'cubic', 'OutputView', outputView, 'FillValues', obj.AugOpt2D.FillValue);
                                if ~classificationType; respOut = imwarp(respOut, tform, 'nearest', 'OutputView', outputView); end
                            case 'RandScale'
                                augPars(id,augId) = obj.AugOpt2D.RandScale(1) + (obj.AugOpt2D.RandScale(2)-obj.AugOpt2D.RandScale(1))*rand;
                                tform = randomAffine2d('Scale', [augPars(id,augId) augPars(id,augId)]);
                                outputView = affineOutputView([size(out,1) size(out,2)], tform);
                                out = imwarp(out, tform, 'cubic', 'OutputView', outputView, 'FillValues', obj.AugOpt2D.FillValue);
                                if ~classificationType; respOut = imwarp(respOut, tform, 'nearest', 'OutputView', outputView); end
                            case 'RandXScale'
                                augPars(id,augId) = obj.AugOpt2D.RandXScale(1) + (obj.AugOpt2D.RandXScale(2)-obj.AugOpt2D.RandXScale(1))*rand;
                                T = [augPars(id,augId) 0 0; 0 1 0; 0 0 1];
                                tform = affine2d(T);
                                outputView = affineOutputView([size(out,1) size(out,2)], tform);
                                out = imwarp(out, tform, 'cubic', 'OutputView', outputView, 'FillValues', obj.AugOpt2D.FillValue);
                                if ~classificationType; respOut = imwarp(respOut, tform, 'nearest', 'OutputView', outputView); end
                            case 'RandYScale'
                                augPars(id,augId) = obj.AugOpt2D.RandYScale(1) + (obj.AugOpt2D.RandYScale(2)-obj.AugOpt2D.RandYScale(1))*rand;
                                T = [1 0 0; 0 augPars(id,augId) 0; 0 0 1];
                                tform = affine2d(T);
                                outputView = affineOutputView([size(out,1) size(out,2)], tform);
                                out = imwarp(out, tform, 'cubic', 'OutputView', outputView, 'FillValues', obj.AugOpt2D.FillValue);
                                if ~classificationType; respOut = imwarp(respOut, tform, 'nearest', 'OutputView', outputView); end
                            case 'RandXShear'
                                augPars(id,augId) = obj.AugOpt2D.RandXShear(1) + (obj.AugOpt2D.RandXShear(2)-obj.AugOpt2D.RandXShear(1))*rand;
                                tform = randomAffine2d('XShear', [augPars(id,augId) augPars(id,augId)]);
                                outputView = affineOutputView([size(out,1) size(out,2)], tform);
                                out = imwarp(out, tform, 'cubic', 'OutputView', outputView, 'FillValues', obj.AugOpt2D.FillValue);
                                if ~classificationType; respOut = imwarp(respOut, tform, 'nearest', 'OutputView', outputView); end
                            case 'RandYShear'
                                augPars(id,augId) = obj.AugOpt2D.RandYShear(1) + (obj.AugOpt2D.RandYShear(2)-obj.AugOpt2D.RandYShear(1))*rand;
                                tform = randomAffine2d('YShear', [augPars(id,augId) augPars(id,augId)]);
                                outputView = affineOutputView([size(out,1) size(out,2)], tform);
                                out = imwarp(out, tform, 'cubic', 'OutputView', outputView, 'FillValues', obj.AugOpt2D.FillValue);
                                if ~classificationType; respOut = imwarp(respOut, tform, 'nearest', 'OutputView', outputView); end
                            case 'GaussianNoise'
                                augPars(id,augId) = obj.AugOpt2D.GaussianNoise(1) + (obj.AugOpt2D.GaussianNoise(2)-obj.AugOpt2D.GaussianNoise(1))*rand;
                                out =  imnoise(out, 'gaussian', 0, augPars(id,augId));
                                %respOut = patchIn.(fieldId){id};
                            case 'PoissonNoise'
                                out =  imnoise(out, 'poisson');
                                %respOut = patchIn.(fieldId){id};
                            case 'HueJitter'
                                if size(out, 3) == 3
                                    augPars(id,augId) = obj.AugOpt2D.HueJitter(1) + (obj.AugOpt2D.HueJitter(2)-obj.AugOpt2D.HueJitter(1))*rand;
                                    out = jitterColorHSV(out, 'Hue', [augPars(id,augId) augPars(id,augId)]);
                                end
                                %respOut = patchIn.(fieldId){id};
                            case 'SaturationJitter'
                                if size(out, 3) == 3
                                    augPars(id,augId) = obj.AugOpt2D.SaturationJitter(1) + (obj.AugOpt2D.SaturationJitter(2)-obj.AugOpt2D.SaturationJitter(1))*rand;
                                    out = jitterColorHSV(out, 'Saturation', [augPars(id,augId) augPars(id,augId)]);
                                end
                                %respOut = patchIn.(fieldId){id};
                            case 'BrightnessJitter'
                                augPars(id,augId) = obj.AugOpt2D.BrightnessJitter(1) + (obj.AugOpt2D.BrightnessJitter(2)-obj.AugOpt2D.BrightnessJitter(1))*rand;
                                if size(out, 3) == 3
                                    out = jitterColorHSV(out, 'Brightness', [augPars(id,augId) augPars(id,augId)]);
                                else
                                    out = out + augPars(id,augId)*255;
                                end
                                %respOut = patchIn.(fieldId){id};
                            case 'ContrastJitter'
                                augPars(id,augId) = obj.AugOpt2D.ContrastJitter(1) + (obj.AugOpt2D.ContrastJitter(2)-obj.AugOpt2D.ContrastJitter(1))*rand;
                                if size(out, 3) == 3
                                    out = jitterColorHSV(out, 'Contrast', [augPars(id,augId) augPars(id,augId)]);
                                else
                                    out = out.*augPars(id,augId);
                                end
                                %respOut = patchIn.(fieldId){id};
                            case 'ImageBlur'
                                augPars(id,augId) = obj.AugOpt2D.ImageBlur(1) + (obj.AugOpt2D.ImageBlur(2)-obj.AugOpt2D.ImageBlur(1))*rand;
                                out =  imgaussfilt(out, augPars(id,augId));
                                %respOut = patchIn.(fieldId){id};
                        end
                    end
                end
            end

            if cropSwitch
                inpResponse{id, 1} = respOut(y1:y2, x1:x2, :, :);
            else
                inpResponse{id, 1} = respOut;
            end
            inpVol{id, 1} = out;

        end
    end
end

%             global counter
%             figure(1)
%             imshow(inpVol{1, 1});
%             for ii=1:numel(inpVol)
%                 fn = sprintf('d:\\Matlab\\Data\\DeepMIB_patch_Test\\PatchOut\\Case1\\patch_%.2d.tif', counter);
%                 imwrite(inpVol{1, 1}, fn, 'tif');
%                 counter = counter + 1
%             end

%             if counter == 26
%                 counter = 1;
%                 figure(1)
%                 imds = imageDatastore('d:\\Matlab\\Data\\DeepMIB_patch_Test\\PatchOut\\Case1\\');
%                 montage(imds, 'BackgroundColor', [1 1 1], 'BorderSize', [8 8]);
%                 error('');
%             end

% if BatchOpt.O_PreviewImagePatches && rand < BatchOpt.O_FractionOfPreviewPatches{1}
%     if isfield(obj.TrainingProgress, 'UIFigure')
%         if size(inpVol{1}, 3) == 3 || size(inpVol{1}, 3) == 1
%             image(obj.TrainingProgress.imgPatch, inpVol{1});
%         elseif size(inpVol{1}, 3) == 2
%             out2 = inpVol{1};
%             out2(:,:,3) = zeros([size(inpVol{1},1) size(inpVol{1},2)]);
%             image(obj.TrainingProgress.imgPatch, out2);
%         end
%         if ~classificationType
%             if strcmp(BatchOpt.T_ConvolutionPadding{1}, 'valid')
%                 padSize = ceil((size(inpVol{1},1)- size(inpResponse{1},1))/2);
%                 previewLabel = padarray(uint8(inpResponse{1}),[padSize, padSize], 0, 'both');
%                 imagesc(obj.TrainingProgress.labelPatch, previewLabel, [0 BatchOpt.T_NumberOfClasses{1}]);
%             else
%                 imagesc(obj.TrainingProgress.labelPatch, uint8(inpResponse{1}), [0 BatchOpt.T_NumberOfClasses{1}]);
%             end
%         else
%             obj.TrainingProgress.labelPatch.Text = inpResponse{1};
%         end
%         drawnow;
%     end
%     %figure(112345)
%     %imshowpair(out, uint8(respOut), 'montage');
% end

patchOut = table(inpVol, inpResponse);
% imtool(patchOut.inpVol{1}(:,:,32,1), [])
end
