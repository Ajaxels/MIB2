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
% - add for input layer options
% - add for classification layer options
% - add ReLU layer options

% generate template network
%if ~isdeployed
% % define parameters for dummy initialization
%    dummyImageSize = [512 512 3];
%    dummyNumClasses = 4;
%    lgraph = deeplabv3plusLayers(dummyImageSize, dummyNumClasses, targetNetwork);
%else
if exist(fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, '2D_DeepLabV3_Resnet18.mat'), 'file') == 0
    result = uiconfirm(obj.View.gui, ...
        sprintf('!!! Warning !!!\n\nGeneration of the "2D DeepLabV3 Resnet18" requires a templete file!\nThe file will be downloaded and placed to\n%s\n\nThis destination directory can be changed from\nMenu->File->Preferences->External directories', obj.mibModel.preferences.ExternalDirs.DeepMIBDir), ...
        'Download the network template','Icon', 'warning');
    if strcmp(result, 'Cancel')
        net = [];
        return;
    end
    waitbar(0, obj.wb, sprintf('Downloading network\nPlease wait...'));
    unzip('http://mib.helsinki.fi/tutorials/deepmib/2D_DeepLabV3_Resnet18.zip', obj.mibModel.preferences.ExternalDirs.DeepMIBDir);
    waitbar(0.5, obj.wb, sprintf('Generating network\nPlease wait...'));
end
load(fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, '2D_DeepLabV3_Resnet18.mat'), 'lgraph');
%end

% start a new network for the output
net = layerGraph();

% define that the following layers are coming after the scorer layer and should have update number of classes
% updated in 'nnet.cnn.layer.Convolution2DLayer' scorer layer:
afterScorerLayerSwitch = false;

for layerId = 1:numel(lgraph.Layers)
    props = properties(lgraph.Layers(layerId));
    switch class(lgraph.Layers(layerId))
        case 'nnet.cnn.layer.ImageInputLayer'
            layer = imageInputLayer(imageSize, ...
                'Normalization', lgraph.Layers(layerId).Normalization, ...
                'DataAugmentation', lgraph.Layers(layerId).DataAugmentation, ...
                'Name', 'ImageInputLayer');    
                % 'Name', lgraph.Layers(layerId).Name);

%             % update the input layer settings
%             switch obj.InputLayerOpt.Normalization
%                 case 'zerocenter'
%                     layer = imageInputLayer(imageSize, 'Name', 'ImageInputLayer', ...
%                         'Normalization', obj.InputLayerOpt.Normalization, ...
%                         'Mean', reshape(obj.InputLayerOpt.Mean, [1 1 numel(obj.InputLayerOpt.Mean)]), ...
%                         'DataAugmentation', lgraph.Layers(layerId).DataAugmentation, ...
%                         'Name', lgraph.Layers(layerId).Name);
%                 case 'zscore'
%                     layer = imageInputLayer(imageSize, 'Name', 'ImageInputLayer', ...
%                         'Normalization', obj.InputLayerOpt.Normalization, ...
%                         'Mean', reshape(obj.InputLayerOpt.Mean, [1 1 numel(obj.InputLayerOpt.Mean)]), ...
%                         'StandardDeviation', reshape(obj.InputLayerOpt.StandardDeviation, [1 1 numel(obj.InputLayerOpt.StandardDeviation)]), ...
%                         'DataAugmentation', lgraph.Layers(layerId).DataAugmentation, ...
%                         'Name', lgraph.Layers(layerId).Name);
%                 case {'rescale-symmetric', 'rescale-zero-one'}
%                     layer = imageInputLayer(imageSize, 'Name', 'ImageInputLayer', ...
%                         'Normalization', obj.InputLayerOpt.Normalization, ...
%                         'Min', reshape(obj.InputLayerOpt.Min, [1 1 numel(obj.InputLayerOpt.Min)]), ...
%                         'Max', reshape(obj.InputLayerOpt.Max, [1 1 numel(obj.InputLayerOpt.Max)]), ...
%                         'DataAugmentation', lgraph.Layers(layerId).DataAugmentation, ...
%                         'Name', lgraph.Layers(layerId).Name);
%                 case 'none'
%                     layer = imageInputLayer(imageSize, 'Name', 'ImageInputLayer', ...
%                         'Normalization', obj.InputLayerOpt.Normalization, ...
%                         'DataAugmentation', lgraph.Layers(layerId).DataAugmentation, ...
%                         'Name', lgraph.Layers(layerId).Name);
%                 otherwise
%                     errordlg(sprintf('!!! Error !!!\n\nWrong normlization paramter (%s)!\n\nUse one of those:\n - zerocenter\n - zscore\n - rescale-symmetric\n - rescale-zero-one\n - none', obj.InputLayerOpt.Normalization), 'Wrong normalization');
%                     return;
%             end
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

            if strcmp(lgraph.Layers(layerId).PaddingMode, 'manual')
                layer = convolution2dLayer(lgraph.Layers(layerId).FilterSize, NumFilters, ...
                    'NumChannels', lgraph.Layers(layerId).NumChannels, ...
                    'PaddingValue', lgraph.Layers(layerId).PaddingValue, ...
                    'Padding', lgraph.Layers(layerId).PaddingSize, ...
                    'Stride', lgraph.Layers(layerId).Stride);
            else    % same
                layer = convolution2dLayer(lgraph.Layers(layerId).FilterSize, NumFilters, ...
                    'NumChannels', lgraph.Layers(layerId).NumChannels, ...
                    'PaddingValue', lgraph.Layers(layerId).PaddingValue, ...
                    'Padding', 'same', ...
                    'Stride', lgraph.Layers(layerId).Stride);
            end
            for propId = 1:numel(props)
                layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
            end
        case 'nnet.cnn.layer.BatchNormalizationLayer'
            props(ismember(props, {'NumChannels', 'NumInputs', 'InputNames', 'NumOutputs', 'OutputNames'})) = '';
            layer = batchNormalizationLayer();
            for propId = 1:numel(props)
                layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
            end
        case 'nnet.cnn.layer.ReLULayer'
            layer = reluLayer();
            props(ismember(props, {'NumInputs','InputNames', 'NumOutputs','OutputNames'})) = '';
            for propId = 1:numel(props)
                layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
            end
        case 'nnet.cnn.layer.MaxPooling2DLayer'
            layer = maxPooling2dLayer(lgraph.Layers(layerId).PoolSize, ...
                'Stride', lgraph.Layers(layerId).Stride, ...
                'HasUnpoolingOutputs', lgraph.Layers(layerId).HasUnpoolingOutputs);
            props(ismember(props, {'PoolSize', 'PaddingMode','Stride','HasUnpoolingOutputs', ...
                'NumInputs', 'InputNames', 'NumOutputs', 'OutputNames'})) = '';
            for propId = 1:numel(props)
                layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
            end
        case 'nnet.cnn.layer.AdditionLayer'
            layer = additionLayer(lgraph.Layers(layerId).NumInputs);
            props(ismember(props, {'NumInputs','InputNames','NumOutputs','OutputNames'})) = '';
            for propId = 1:numel(props)
                layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
            end
        case 'nnet.cnn.layer.DepthConcatenationLayer'
            layer = depthConcatenationLayer(lgraph.Layers(layerId).NumInputs);
            props(ismember(props, {'NumInputs', 'InputNames', 'NumOutputs', 'OutputNames'})) = '';
            for propId = 1:numel(props)
                layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
            end
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
            layer = crop2dLayer(lgraph.Layers(layerId).Mode);
            props(ismember(props, {'Mode', 'Location', ...
                'NumInputs', 'InputNames', 'NumOutputs', 'OutputNames'})) = '';
            for propId = 1:numel(props)
                layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
            end
        case 'nnet.cnn.layer.SoftmaxLayer'
            layer = softmaxLayer('Name', lgraph.Layers(layerId).Name);
        case 'nnet.cnn.layer.PixelClassificationLayer'
            layer = pixelClassificationLayer('Name', 'Segmentation-Layer');
            props(ismember(props, {'OutputSize', 'LossFunction', 'Name', ...
                'NumInputs', 'InputNames', 'NumOutputs', 'OutputNames'})) = '';
            for propId = 1:numel(props)
                layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
            end
        otherwise
            error(sprintf('undefined layer: %s', class(lgraph.Layers(layerId)))); %#ok<SPERR>
    end
    %net = [net; layer];
    net = addLayers(net, layer);
end

% connect layers
% rename layers to match general names of DeepMIB
sourceLayers = lgraph.Connections.Source;
destinationLayers = lgraph.Connections.Destination;
sourceLayers(ismember(sourceLayers, 'data')) = {'ImageInputLayer'};
destinationLayers(ismember(destinationLayers, 'data')) = {'ImageInputLayer'};
sourceLayers(ismember(sourceLayers, 'classification')) = {'Segmentation-Layer'};
destinationLayers(ismember(destinationLayers, 'classification')) = {'Segmentation-Layer'};
for connectId = 1:numel(sourceLayers)
    net = connectLayers(net, sourceLayers{connectId}, destinationLayers{connectId});
end

end