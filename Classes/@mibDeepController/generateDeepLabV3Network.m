function net = generateDeepLabV3Network(obj, imageSize, numClasses, targetNetwork)
% function generateDeepLabV3Network(obj, imageSize, numClasses, targetNetwork)
% generate DeepLab v3+ convolutional neural network for semantic image
% segmentation of 2D RGB images
%
% Parameters:
% imageSize: vector [height, width, colors] defining input patch size,
% should be larger than [224 224] for resnet18, colors should be 3
% numClasses: number of output classes (including exterior) for the output results
% targetNetwork: string defining the base architecture for the initialization
%   'resnet18' - resnet18 network

% Copyright (C) 12.01.2022, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% notes on original tests
%
% to do:
% - add option for dropout 50% layer afte ReLU 67
% - add for classification layer options
% - add ReLU layer options

if nargin < 4; targetNetwork = 'resnet18'; end

% generate template network

if strcmp(targetNetwork, 'resnet50') % 'resnet50', 'xception', 'inceptionresnetv2'
    % define parameters for dummy initialization
    if imageSize(3) == 3
        net = deeplabv3plusLayers(imageSize, numClasses, targetNetwork, 'DownsamplingFactor', 16);
        return;
    end
    dummyImageSize = [imageSize([1 2]), 3];
    lgraph = deeplabv3plusLayers(dummyImageSize, numClasses, targetNetwork, 'DownsamplingFactor', 16);
else
    if exist(fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, '2D_DeepLabV3_Resnet18.mat'), 'file') == 0
        result = uiconfirm(obj.View.gui, ...
            sprintf('!!! Warning !!!\n\nGeneration of the "2D DeepLabV3 Resnet18" requires a templete file!\nThe file will be downloaded and placed to\n%s\n\nThis destination directory can be changed from\nMenu->File->Preferences->External directories', obj.mibModel.preferences.ExternalDirs.DeepMIBDir), ...
            'Download the network template','Icon', 'warning');
        if strcmp(result, 'Cancel')
            net = [];
            return;
        end
        if obj.BatchOpt.showWaitbar; waitbar(0, obj.wb, sprintf('Downloading network\nPlease wait...')); end
        unzip('http://mib.helsinki.fi/tutorials/deepmib/2D_DeepLabV3_Resnet18.zip', obj.mibModel.preferences.ExternalDirs.DeepMIBDir);
        if obj.BatchOpt.showWaitbar; waitbar(0.5, obj.wb, sprintf('Generating network\nPlease wait...')); end
    end
    load(fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, '2D_DeepLabV3_Resnet18.mat'), 'lgraph');
end

% start a new network for the output
net = layerGraph();

% define that the following layers are coming after the scorer layer and should have update number of classes
% updated in 'nnet.cnn.layer.Convolution2DLayer' scorer layer:
afterScorerLayerSwitch = false;
noLayers = numel(lgraph.Layers);
for layerId = 1:noLayers
    props = properties(lgraph.Layers(layerId));
    switch class(lgraph.Layers(layerId))
        case 'nnet.cnn.layer.ImageInputLayer'
            layer = imageInputLayer(imageSize, ...
                'Normalization', lgraph.Layers(layerId).Normalization, ...
                'DataAugmentation', lgraph.Layers(layerId).DataAugmentation, ...
                'Name', 'ImageInputLayer');    
        case 'nnet.cnn.layer.Convolution2DLayer'
            props(ismember(props, {'FilterSize', 'NumChannels', 'NumFilters', 'PaddingMode', 'PaddingValue', 'NumInputs', ...
                'InputNames', 'NumOutputs', 'OutputNames', 'Stride', 'PaddingSize'})) = '';
            if strcmp(lgraph.Layers(layerId).Name, 'scorer') % the layer defining number of output classes
                NumFilters = numClasses;
                afterScorerLayerSwitch = true;  % define that the following layers are coming after the scorer layer and should have update number of classes
                %props(ismember(props, {'Bias', 'Weights'}) = '';
            else
                NumFilters = lgraph.Layers(layerId).NumFilters;
            end

            % correct architecture for grayscale images
            if layerId == 2
                numChannels = imageSize(3);
            else
                numChannels = lgraph.Layers(layerId).NumChannels;
            end

            if strcmp(lgraph.Layers(layerId).PaddingMode, 'manual')
                layer = convolution2dLayer(lgraph.Layers(layerId).FilterSize, NumFilters, ...
                    'NumChannels', numChannels, ... % lgraph.Layers(layerId).NumChannels, ...
                    'PaddingValue', lgraph.Layers(layerId).PaddingValue, ...
                    'Padding', lgraph.Layers(layerId).PaddingSize, ...
                    'Stride', lgraph.Layers(layerId).Stride);
            else    % same
                layer = convolution2dLayer(lgraph.Layers(layerId).FilterSize, NumFilters, ...
                    'NumChannels', numChannels, ... % lgraph.Layers(layerId).NumChannels, ...
                    'PaddingValue', lgraph.Layers(layerId).PaddingValue, ...
                    'Padding', 'same', ...
                    'Stride', lgraph.Layers(layerId).Stride);
            end
            for propId = 1:numel(props)
                if layerId == 2 && imageSize(3) == 1 && strcmp(props{propId}, 'Weights')
                    layer.(props{propId}) = mean(lgraph.Layers(layerId).(props{propId}), 3);
                else
                    layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
                end
            end
        case 'nnet.cnn.layer.BatchNormalizationLayer'
%             props(ismember(props, {'NumChannels', 'NumInputs', 'InputNames', 'NumOutputs', 'OutputNames'})) = '';
%             layer = batchNormalizationLayer();
%             for propId = 1:numel(props)
%                layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
%             end
            layer = lgraph.Layers(layerId); 
        case 'nnet.cnn.layer.ReLULayer'
%             layer = reluLayer();
%             props(ismember(props, {'NumInputs','InputNames', 'NumOutputs','OutputNames'})) = '';
%             for propId = 1:numel(props)
%                layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
%             end
            layer = lgraph.Layers(layerId);
        case 'nnet.cnn.layer.MaxPooling2DLayer'
%             layer = maxPooling2dLayer(lgraph.Layers(layerId).PoolSize, ...
%                 'Stride', lgraph.Layers(layerId).Stride, ...
%                 'HasUnpoolingOutputs', lgraph.Layers(layerId).HasUnpoolingOutputs);
%             if strcmp(targetNetwork, 'resnet18')
%                 props(ismember(props, {'PoolSize', 'PaddingMode','Stride','HasUnpoolingOutputs', ...
%                     'NumInputs', 'InputNames', 'NumOutputs', 'OutputNames'})) = '';
%             else
%                 props(ismember(props, {'PoolSize', 'PaddingMode','Stride','HasUnpoolingOutputs', ...
%                     'NumInputs', 'InputNames', 'NumOutputs', 'OutputNames', 'PaddingSize'})) = '';
%             end
%             for propId = 1:numel(props)
%                 layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
%             end
            layer = lgraph.Layers(layerId);
        case 'nnet.cnn.layer.AdditionLayer'
%             layer = additionLayer(lgraph.Layers(layerId).NumInputs);
%             props(ismember(props, {'NumInputs','InputNames','NumOutputs','OutputNames'})) = '';
%             for propId = 1:numel(props)
%                 layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
%             end
            layer = lgraph.Layers(layerId);
        case 'nnet.cnn.layer.DepthConcatenationLayer'
%             layer = depthConcatenationLayer(lgraph.Layers(layerId).NumInputs);
%             props(ismember(props, {'NumInputs', 'InputNames', 'NumOutputs', 'OutputNames'})) = '';
%             for propId = 1:numel(props)
%                 layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
%             end
            layer = lgraph.Layers(layerId);
        case 'nnet.cnn.layer.TransposedConvolution2DLayer'
            if ~afterScorerLayerSwitch
                layer = transposedConv2dLayer(lgraph.Layers(layerId).FilterSize, lgraph.Layers(layerId).NumFilters, ...
                    'NumChannels', lgraph.Layers(layerId).NumChannels, ...
                    'Stride', lgraph.Layers(layerId).Stride, ...
                    'Cropping', lgraph.Layers(layerId).CroppingSize);
                props(ismember(props, {'FilterSize', 'NumFilters', 'NumChannels', 'Stride', 'CroppingSize', 'CroppingMode', ...
                    'NumInputs', 'InputNames', 'NumOutputs', 'OutputNames'})) = '';
            else
                layer = transposedConv2dLayer(lgraph.Layers(layerId).FilterSize, numClasses, ...
                    'NumChannels', numClasses, ...
                    'Stride', lgraph.Layers(layerId).Stride, ...
                    'Cropping', lgraph.Layers(layerId).CroppingSize);
                % generates weights from the template network
                weightsMatrix = zeros([size(lgraph.Layers(layerId).Weights, 1), size(lgraph.Layers(layerId).Weights, 1), numClasses, numClasses]);
                for i=1:numClasses
                    weightsMatrix(:,:,i,i) = lgraph.Layers(layerId).Weights(:,:,1,1);
                end
                props(ismember(props, {'FilterSize', 'NumFilters', 'NumChannels', 'Stride', 'CroppingSize', 'CroppingMode', ...
                    'Bias', 'Weights', ...
                    'NumInputs', 'InputNames', 'NumOutputs', 'OutputNames'})) = '';
                layer.Weights = weightsMatrix;
            end
            for propId = 1:numel(props)
                layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
            end
        case 'nnet.cnn.layer.Crop2DLayer'
%             layer = crop2dLayer(lgraph.Layers(layerId).Mode);
%             props(ismember(props, {'Mode', 'Location', ...
%                 'NumInputs', 'InputNames', 'NumOutputs', 'OutputNames'})) = '';
%             for propId = 1:numel(props)
%                 layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
%             end
            layer = lgraph.Layers(layerId);
        case 'nnet.cnn.layer.SoftmaxLayer'
%             layer = softmaxLayer('Name', lgraph.Layers(layerId).Name);
            layer = lgraph.Layers(layerId);
        case 'nnet.cnn.layer.PixelClassificationLayer'
            layer = pixelClassificationLayer('Name', 'Segmentation-Layer');
            props(ismember(props, {'OutputSize', 'LossFunction', 'Name', ...
                'NumInputs', 'InputNames', 'NumOutputs', 'OutputNames'})) = '';
            for propId = 1:numel(props)
                layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
            end
        case 'nnet.cnn.layer.AveragePooling2DLayer'
%             layer = averagePooling2dLayer(lgraph.Layers(layerId).PoolSize);
%             props(ismember(props, {'PoolSize', 'PaddingMode', 'NumInputs', 'InputNames', ...
%                 'NumOutputs', 'OutputNames'})) = '';
%             for propId = 1:numel(props)
%                 layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
%             end
            layer = lgraph.Layers(layerId);
        case 'nnet.inceptionresnetv2.layer.ScalingFactorLayer'
            layer = lgraph.Layers(layerId);
        otherwise
            layer = lgraph.Layers(layerId);
            %error(sprintf('undefined layer: %s', class(lgraph.Layers(layerId)))); %#ok<SPERR>
    end
    %net = [net; layer];
    net = addLayers(net, layer);
    if obj.BatchOpt.showWaitbar && mod(layerId, 20) == 1; waitbar(layerId/(noLayers*2), obj.wb); end
end

% connect layers
% rename layers to match general names of DeepMIB
if obj.BatchOpt.showWaitbar; waitbar(0.5, obj.wb, sprintf('Connecting layers\nPlease wait...')); end
sourceLayers = lgraph.Connections.Source;
destinationLayers = lgraph.Connections.Destination;
switch targetNetwork
    case 'resnet18'
        sourceLayers(ismember(sourceLayers, 'data')) = {'ImageInputLayer'};
        destinationLayers(ismember(destinationLayers, 'data')) = {'ImageInputLayer'};
    case {'inceptionresnetv2', 'resnet50'}
        sourceLayers(ismember(sourceLayers, 'input_1')) = {'ImageInputLayer'};
        destinationLayers(ismember(destinationLayers, 'input_1')) = {'ImageInputLayer'};
end
sourceLayers(ismember(sourceLayers, 'classification')) = {'Segmentation-Layer'};
destinationLayers(ismember(destinationLayers, 'classification')) = {'Segmentation-Layer'};

noSourceLayers = numel(sourceLayers);
for connectId = 1:noSourceLayers
    net = connectLayers(net, sourceLayers{connectId}, destinationLayers{connectId});
    if obj.BatchOpt.showWaitbar && mod(layerId, 20) == 1; waitbar(0.5+(connectId/(noSourceLayers*2)), obj.wb);  end
end

end