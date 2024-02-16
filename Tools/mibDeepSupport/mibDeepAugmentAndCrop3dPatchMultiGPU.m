% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 25.04.2023
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function [patchOut, info, augList, augPars] = mibDeepAugmentAndCrop3dPatchMultiGPU(patchIn, info, inputPatchSize, outputPatchSize, mode, options)
% function [patchOut, augList, augPars] = mibDeepAugmentAndCrop3dPatchMultiGPU(patchIn, info, inputPatchSize, outputPatchSize, mode, options)
%
% Augment training data by set of operations encoded in
% options.AugOpt3D and/or crop the response to the network's output size.
%
% Parameters:
% patchIn: a table with InputImage and ResponsePixelLabelImage fields for semantic segmentation or matrix for classification
% info: additional info about input patch
% inputPatchSize: input patch size as [height, width, depth, color]
% outputPatchSize: output patch size as [height, width, depth, classes] or [height, width, classes] for 2.5D Z2C network
% mode: string
% 'show' - do not transform/augment, do not crop, only show
% 'crop' - do not transform/augment, only crop and show
% 'aug' - transform/augment, crop and show
% options: a struture with additional parameters
%   .Workflow - [string] used workflow, taken from options.Workflow
%   .Aug3DFuncNames - copy of mibDeepController.Aug2DFuncNames
%   .AugOpt3D - copy of mibDeepController.AugOpt2D
%   .Aug3DFuncProbability - copy of mibDeepController.Aug2DFuncProbability probabilities of augmentation functions to be triggered
%   .O_PreviewImagePatches - [logical] switch to show image patches, taken from mibDeepController.BatchOpt.O_PreviewImagePatches;
%   .O_FractionOfPreviewPatches - [numerical] fraction of patches to preview taken from mibDeepController.BatchOpt.O_FractionOfPreviewPatches{1};
%   .T_ConvolutionPadding - [string] type of padding, taken from mibDeepController.BatchOpt.T_ConvolutionPadding{1}
%
% Return values:
% patchOut: return the image patches in a two-column table as required by the trainNetwork function for single-input networks.
% info: additional info about input patch
% augList: cell array with used augmentation operations
% augPars: matrix with used values, NaN if the value was not used, the second column is the parameter for blend of Hue+Sat jitters

global mibDeepTrainingProgressStruct

augList = {};    % list of used aug functions
augPars = [];       % array with used parameters

if mibDeepTrainingProgressStruct.emergencyBrake == true   % stop training, return. This function is still called multiple times after stopping the training
    patchOut = [];
    return;
end

% check for the classification type training
if strcmp(options.Workflow, '3D Patch-wise')
    error('to do!')
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

    % dynamically convert grayscale to RGB
    if size(patchIn.InputImage{1}, 3) ~= inputPatchSize(4)
        for id=1:size(patchIn, 1)
            patchIn.InputImage{id} = repmat(patchIn.InputImage{id}, [1, 1, 3]);
        end
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

if strcmp(mode, 'show')
    inpVol = patchIn.InputImage;
    inpResponse = patchIn.(fieldId);
else
    numAugFunc = numel(options.Aug3DFuncNames);    % number of functions to be used
    inpVol = cell(size(patchIn, 1), 1);
    inpResponse = cell(size(patchIn, 1), 1);
    augList = cell(size(patchIn, 1), 1);
    augPars = nan([size(patchIn, 1), 18]); % allocate space for augmentation parameters

    cropSwitch = 0;
    if ~classificationType
        diffPatchY = (inputPatchSize(1)-outputPatchSize(1))/2;
        diffPatchX = (inputPatchSize(2)-outputPatchSize(2))/2;
        diffPatchZ = (inputPatchSize(3)-outputPatchSize(3))/2;

        if diffPatchY ~=0 || diffPatchX ~=0 || diffPatchZ ~=0
            y1 = diffPatchY+1;
            y2 = inputPatchSize(1)-diffPatchY;
            x1 = diffPatchX+1;
            x2 = inputPatchSize(2)-diffPatchX;
            z1 = diffPatchZ+1;
            z2 = inputPatchSize(3)-diffPatchZ;
            cropSwitch = 1;   % crop resulting image to match output patch
        end
    end

    for id=1:size(patchIn, 1)
        if strcmp(mode, 'crop')  % do only crop
            if cropSwitch
                inpResponse{id, 1} = patchIn.(fieldId){id}(y1:y2, x1:x2, z1:z2, :, :);
            else
                inpResponse{id, 1} = patchIn.(fieldId){id};
            end
            inpVol{id, 1}= patchIn.InputImage{id};
        else    % augment and crop
            rndIdx = randi(100, 1)/100;
            if rndIdx > options.AugOpt3D.Fraction   % if index lower than options.AugOpt3D.Fraction -> augment the data
                out =  patchIn.InputImage{id};
                respOut = patchIn.(fieldId){id};
                augList{id} = {'Original'};
            else
                % find augmentations, based on probability
                randVector = rand([2, numAugFunc]);
                randVector(2,:) = options.Aug3DFuncProbability;
                [~, index] = min(randVector, [], 1);
                augFuncIndeces = find(index == 1);

                if isempty(augFuncIndeces)
                    out =  patchIn.InputImage{id};
                    respOut = patchIn.(fieldId){id};
                    augList{id} = {'Original'};
                else
                    augList{id} = options.Aug3DFuncNames(augFuncIndeces);
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
                            case 'RandZReflection'
                                out = flip(out, 3);
                                if ~classificationType; respOut = flip(respOut, 3); end
                            case 'Rotation90'
                                if randi(2) == 1
                                    out = rot90(out);
                                    if ~classificationType; respOut = rot90(respOut); end
                                else
                                    out = rot90(out, 3);
                                    if ~classificationType; respOut = rot90(respOut, 3); end
                                end
                            case 'ReflectedRotation90'
                                out = rot90(fliplr(out));
                                if ~classificationType; respOut = rot90(fliplr(respOut)); end
                            case 'RandRotation'
                                augPars(id,augId) = options.AugOpt3D.RandRotation.Min + (options.AugOpt3D.RandRotation.Max-options.AugOpt3D.RandRotation.Min)*rand;
                                tform = randomAffine2d('Rotation', [augPars(id,augId) augPars(id,augId)]);
                                outputView = affineOutputView([size(out,1) size(out,2)], tform);
                                for z=1:size(out, 3)
                                    out(:,:,z) = imwarp(out(:,:,z), tform, 'cubic', 'OutputView', outputView, 'FillValues', options.AugOpt3D.FillValue);
                                    respOut(:,:,z) = imwarp(respOut(:,:,z), tform, 'nearest', 'OutputView', outputView);
                                end
                            case 'RandScale'
                                %minScaleRand = -1/options.AugOpt3D.RandScale.Min*rand;
                                %minScaleRand = -1;
                                %maxScaleRand = options.AugOpt3D.RandScale.Max*rand;
                                %meanVal = (minScaleRand+maxScaleRand)/2;
                                %if meanVal < 0; randomNumber = -1/(meanVal-1); else; randomNumber = meanVal+1; end
                                augPars(id, augId) = exp((log(options.AugOpt3D.RandScale.Max) - log(options.AugOpt3D.RandScale.Min)) * rand + log(options.AugOpt3D.RandScale.Min));
                                %augPars(id,augId) = options.AugOpt3D.RandScale(1) + (options.AugOpt3D.RandScale(2)-options.AugOpt3D.RandScale(1))*rand;
                                tform = randomAffine2d('Scale', [augPars(id,augId) augPars(id,augId)]);
                                outputView = affineOutputView([size(out,1) size(out,2)], tform);
                                for z=1:size(out, 3)
                                    out(:,:,z) = imwarp(out(:,:,z), tform, 'cubic', 'OutputView', outputView, 'FillValues', options.AugOpt3D.FillValue);
                                    respOut(:,:,z) = imwarp(respOut(:,:,z), tform, 'nearest', 'OutputView', outputView);
                                end
                            case 'RandXScale'
                                augPars(id,augId) = exp((log(options.AugOpt3D.RandXScale.Max) - log(options.AugOpt3D.RandXScale.Min)) * rand + log(options.AugOpt3D.RandXScale.Min));
                                %augPars(id,augId) = options.AugOpt3D.RandXScale(1) + (options.AugOpt3D.RandXScale(2)-options.AugOpt3D.RandXScale(1))*rand;
                                T = [augPars(id,augId) 0 0; 0 1 0; 0 0 1];
                                tform = affine2d(T);
                                outputView = affineOutputView([size(out,1) size(out,2)], tform);
                                for z=1:size(out, 3)
                                    out(:,:,z) = imwarp(out(:,:,z), tform, 'cubic', 'OutputView', outputView, 'FillValues', options.AugOpt3D.FillValue);
                                    respOut(:,:,z) = imwarp(respOut(:,:,z), tform, 'nearest', 'OutputView', outputView);
                                end
                            case 'RandYScale'
                                augPars(id,augId) = exp((log(options.AugOpt3D.RandYScale.Max) - log(options.AugOpt3D.RandYScale.Min)) * rand + log(options.AugOpt3D.RandYScale.Min));
                                %augPars(id,augId) = options.AugOpt3D.RandYScale(1) + (options.AugOpt3D.RandYScale(2)-options.AugOpt3D.RandYScale(1))*rand;
                                T = [1 0 0; 0 augPars(id,augId) 0; 0 0 1];
                                tform = affine2d(T);
                                outputView = affineOutputView([size(out,1) size(out,2)], tform);
                                for z=1:size(out, 3)
                                    out(:,:,z) = imwarp(out(:,:,z), tform, 'cubic', 'OutputView', outputView, 'FillValues', options.AugOpt3D.FillValue);
                                    respOut(:,:,z) = imwarp(respOut(:,:,z), tform, 'nearest', 'OutputView', outputView);
                                end
                            case 'RandXShear'
                                augPars(id,augId) = options.AugOpt3D.RandXShear.Min + (options.AugOpt3D.RandXShear.Max-options.AugOpt3D.RandXShear.Min)*rand;
                                tform = randomAffine2d('XShear', [augPars(id,augId) augPars(id,augId)]);
                                outputView = affineOutputView([size(out,1) size(out,2)], tform);
                                for z=1:size(out, 3)
                                    out(:,:,z) = imwarp(out(:,:,z), tform, 'cubic', 'OutputView', outputView, 'FillValues', options.AugOpt3D.FillValue);
                                    respOut(:,:,z) = imwarp(respOut(:,:,z), tform, 'nearest', 'OutputView', outputView);
                                end
                            case 'RandYShear'
                                augPars(id,augId) = options.AugOpt3D.RandYShear.Min + (options.AugOpt3D.RandYShear.Max-options.AugOpt3D.RandYShear.Min)*rand;
                                tform = randomAffine2d('YShear', [augPars(id,augId) augPars(id,augId)]);
                                outputView = affineOutputView([size(out,1) size(out,2)], tform);
                                for z=1:size(out, 3)
                                    out(:,:,z) = imwarp(out(:,:,z), tform, 'cubic', 'OutputView', outputView, 'FillValues', options.AugOpt3D.FillValue);
                                    respOut(:,:,z) = imwarp(respOut(:,:,z), tform, 'nearest', 'OutputView', outputView);
                                end
                            case 'GaussianNoise'
                                augPars(id,augId) = options.AugOpt3D.GaussianNoise.Min + (options.AugOpt3D.GaussianNoise.Max-options.AugOpt3D.GaussianNoise.Min)*rand;
                                for z=1:size(out, 3)
                                    out(:,:,z) =  imnoise(out(:,:,z), 'gaussian', 0, augPars(id,augId));
                                end
                                %respOut = patchIn.(fieldId){id};
                            case 'PoissonNoise'
                                for z=1:size(out, 3)
                                    out(:,:,z) =  imnoise(out(:,:,z), 'poisson');
                                end
                                %respOut = patchIn.(fieldId){id};
                            case 'HueJitter'
                                if size(out, 4) == 3
                                    augPars(id,augId) = options.AugOpt3D.HueJitter.Min + (options.AugOpt3D.HueJitter.Max-options.AugOpt3D.HueJitter.Min)*rand;
                                    for z=1:size(out, 3)
                                        out(:,:,z) = jitterColorHSV(out(:,:,z), 'Hue', [augPars(id,augId) augPars(id,augId)]);
                                    end
                                end
                                %respOut = patchIn.(fieldId){id};
                            case 'SaturationJitter'
                                if size(out, 4) == 3
                                    augPars(id,augId) = options.AugOpt3D.SaturationJitter.Min + (options.AugOpt3D.SaturationJitter.Max-options.AugOpt3D.SaturationJitter.Min)*rand;
                                    for z=1:size(out, 3)
                                        out(:,:,z) = jitterColorHSV(out(:,:,z), 'Saturation', [augPars(id,augId) augPars(id,augId)]);
                                    end
                                end
                                %respOut = patchIn.(fieldId){id};
                            case 'BrightnessJitter'
                                augPars(id,augId) = options.AugOpt3D.BrightnessJitter.Min + (options.AugOpt3D.BrightnessJitter.Max-options.AugOpt3D.BrightnessJitter.Min)*rand;
                                if size(out, 4) == 3
                                    for z=1:size(out, 3)
                                        out(:,:,z) = jitterColorHSV(out(:,:,z), 'Brightness', [augPars(id,augId) augPars(id,augId)]);
                                    end
                                else
                                    for z=1:size(out, 3)
                                        out(:,:,z) = out(:,:,z) + augPars(id,augId)*255;
                                    end
                                end
                                %respOut = patchIn.(fieldId){id};
                            case 'ContrastJitter'
                                augPars(id,augId) = options.AugOpt3D.ContrastJitter.Min + (options.AugOpt3D.ContrastJitter.Max-options.AugOpt3D.ContrastJitter.Min)*rand;
                                if size(out, 4) == 3
                                    for z=1:size(out, 3)
                                        out(:,:,z) = jitterColorHSV(out(:,:,z), 'Contrast', [augPars(id,augId) augPars(id,augId)]);
                                    end
                                else
                                    for z=1:size(out, 3)
                                        out(:,:,z) = out(:,:,z).*augPars(id,augId);
                                    end
                                end
                                %respOut = patchIn.(fieldId){id};
                            case 'ImageBlur'
                                augPars(id,augId) = options.AugOpt3D.ImageBlur.Min + (options.AugOpt3D.ImageBlur.Max-options.AugOpt3D.ImageBlur.Min)*rand;
                                for z=1:size(out, 3)
                                    out(:,:,z) =  imgaussfilt(out(:,:,z), augPars(id,augId));
                                end
                                %respOut = patchIn.(fieldId){id};
                        end
                    end
                end
            end

            if cropSwitch
                inpResponse{id, 1} = respOut(y1:y2, x1:x2, z1:z2, :, :);
            else
                if size(outputPatchSize, 2) == 3    % Z2C 2.5D semantic segmentation
                    inpResponse{id, 1} = respOut(:,:,ceil(size(respOut,3)/2));
                else
                    inpResponse{id, 1} = respOut;
                end
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

if options.O_PreviewImagePatches && rand < options.O_FractionOfPreviewPatches
    if isfield(mibDeepTrainingProgressStruct, 'UIFigure') && isvalid(mibDeepTrainingProgressStruct.UIFigure)
        zVal = ceil(size(inpVol{1}, 3)/2);  % calculate position of mid-slice
        if size(inpVol{1}, 4) == 3 || size(inpVol{1}, 4) == 1
            image(mibDeepTrainingProgressStruct.imgPatch, squeeze(inpVol{1}(:,:,zVal,:)), 'CDataMapping', 'scaled');
        elseif size(inpVol{1}, 4) == 2
            out2 = squeeze(inpVol{1}(:,:,zVal,:));
            out2(:,:,3) = zeros([size(inpVol{1},1) size(inpVol{1},2)]);
            out2 = uint8(out2 * (255/double(max(out2(:)))));
            image(mibDeepTrainingProgressStruct.imgPatch, out2);
        end
        if ~classificationType
            zValResp = ceil(size(inpResponse{1}, 3)/2);  % calculate position of mid-slice
            if strcmp(options.T_ConvolutionPadding, 'valid')
                padSize = ceil((size(inpVol{1},1)- size(inpResponse{1},1))/2);
                previewLabel = padarray(uint8(inpResponse{1}(:,:,zValResp)), [padSize, padSize], 0, 'both');
                imagesc(mibDeepTrainingProgressStruct.labelPatch, previewLabel, [0 options.T_NumberOfClasses]);
            else
                imagesc(mibDeepTrainingProgressStruct.labelPatch, uint8(inpResponse{1}(:,:,zValResp)), [0 options.T_NumberOfClasses]);
            end
        else
            mibDeepTrainingProgressStruct.labelPatch.Text = inpResponse{1};
        end
        drawnow;
    end
    %figure(112345)
    %imshowpair(out, uint8(respOut), 'montage');
end

patchOut = table(inpVol, inpResponse);

%             % debug section to export generated patches
%             debugSwitch = true;
%             if debugSwitch
%                 zVal = ceil(size(inpVol{1}, 3)/2);  % calculate position of mid-slice
%                 dirOut = fullfile(obj.BatchOpt.ResultingImagesDir, 'PatchExamples');
%                 if ~isfolder(dirOut); mkdir(dirOut); end
%                 fnIndex = randi(10000000);
%                 fnOut1 = fullfile(dirOut, sprintf('patch_%0.8d_img.tif', fnIndex));
%                 fnOut2 = fullfile(dirOut, sprintf('patch_%0.8d_label.tif', fnIndex));
%                 imwrite(inpVol{1}(:,:,zVal), fnOut1);
%                 imwrite(uint8(inpResponse{1}(:,:,zVal))*64, fnOut2);
%             end

% imtool(patchOut.inpVol{1}(:,:,32,1), [])
end
