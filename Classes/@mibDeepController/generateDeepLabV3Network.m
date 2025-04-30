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
%   'resnet50' - resnet50 network
%   'xception' - xception network (requires matlab)
%   'inceptionresnetv2' - inceptionresnetv2 network (required matlab)

% Updates
% 

% notes on original tests
%
% to do:
% - add option for dropout 50% layer afte ReLU 67
% - add for classification layer options
% - add ReLU layer options

global mibPath;

if nargin < 4; targetNetwork = 'resnet18'; end

% generate template network
downsamplingFactor = 16; % 8 or 16
%if ismember(targetNetwork, {'xception', 'inceptionresnetv2', 'resnet50'}) % 'resnet18', 'resnet50', 'xception', 'inceptionresnetv2'
if ismember(targetNetwork, {'xception', 'inceptionresnetv2'}) % 'resnet18', 'resnet50', 'xception', 'inceptionresnetv2'
    % define parameters for dummy initialization
    if imageSize(3) == 3
        net = deeplabv3plusLayers(imageSize, numClasses, targetNetwork, 'DownsamplingFactor', downsamplingFactor);
        return;
    end
    dummyImageSize = [imageSize([1 2]), 3];
    lgraph = deeplabv3plusLayers(dummyImageSize, numClasses, targetNetwork, 'DownsamplingFactor', downsamplingFactor);
else
    switch targetNetwork
        case 'resnet18'
            netName = '2D_DeepLabV3_Resnet18.mat';  % original: 2D_DeepLabV3_Resnet18_old.mat; updated: 2D_DeepLabV3_Resnet18.mat
            %netName = '2D_DeepLabV3_Resnet18_old.mat';  
        case 'resnet50'
            netName = '2D_DeepLabV3_Resnet50.mat'; 
    end   
    [~, fnTemplate] = fileparts(netName);

    if exist(fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, netName), 'file') == 0
        prompts = {sprintf('Select the target application:')};
        defAns = {{'Electron Microscopy', 'Light microscopy/Pathology', 1}};
        dlgTitle = 'Download network template';
        options.WindowStyle = 'normal';       % [optional] style of the window
        options.PromptLines = 1;   % [optional] number of lines for widget titles
        options.Title = sprintf(['!!! Warning !!!\n\nGeneration of CNN using the "2D DeepLabV3 %s" architecture requires a templete file!\n\n' ...
            'The file will be downloaded and placed to\n%s\n' ...
            'This destination directory can be changed from\n' ...
            'Menu->File->Preferences->External directories'], targetNetwork, strrep(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, '\','/'));
        options.TitleLines = 9;                   % [optional] make it twice tall, number of text lines for the title
        options.WindowWidth = 1.5; 
        options.HelpUrl = 'http://mib.helsinki.fi/help/main2/ug_gui_menu_tools_deeplearning.html';
        [answer, selIndex] = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle, options);
        if isempty(answer); net = []; return; end 

        switch answer{1}
            case 'Electron Microscopy'
                fnTemplate = [fnTemplate '_sbem'];
            case 'Light microscopy/Pathology'
                fnTemplate = [fnTemplate '_pathology'];
        end

        if obj.BatchOpt.showWaitbar
            obj.wb.Value = 0;
            obj.wb.Message = 'Downloading network...'; 
        end
        unzip(sprintf('http://mib.helsinki.fi/tutorials/deepmib/%s.zip', fnTemplate), obj.mibModel.preferences.ExternalDirs.DeepMIBDir);
        if obj.BatchOpt.showWaitbar; obj.wb.Message = 'Generating network...'; obj.wb.Value = 0.5; end
    end
    load(fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, netName), 'lgraph');
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
                if layerId == 2 && strcmp(props{propId}, 'Weights') % correct weights for the first 2D convolution layer
                    if size(lgraph.Layers(layerId).(props{propId}), 3) == imageSize(3)
                        layer.(props{propId}) = lgraph.Layers(layerId).(props{propId});
                    elseif size(lgraph.Layers(layerId).(props{propId}), 3) > imageSize(3)
                        layer.(props{propId}) = mean(lgraph.Layers(layerId).(props{propId}), 3);
                    elseif size(lgraph.Layers(layerId).(props{propId}), 3) < imageSize(3)
                        layer.(props{propId}) = repmat(mean(lgraph.Layers(layerId).(props{propId}), 3), [1 1 imageSize(3) 1]);
                    end
                %if layerId == 2 && imageSize(3) == 1 && strcmp(props{propId}, 'Weights')  % this is an old code that handles case when the template network is trained with 3 colors
                %    layer.(props{propId}) = mean(lgraph.Layers(layerId).(props{propId}), 3);
                elseif afterScorerLayerSwitch && (strcmp(props{propId}, 'Weights') || strcmp(props{propId}, 'Bias'))
                    layer.(props{propId}) = [];     % clear weights for the scorer layer
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
                'NumInputs', 'InputNames', 'NumOutputs', 'OutputNames', 'Classes'})) = '';
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
    if obj.BatchOpt.showWaitbar && mod(layerId, 20) == 1; obj.wb.Value = layerId/(noLayers*2); end
end

% connect layers
% rename layers to match general names of DeepMIB
if obj.BatchOpt.showWaitbar; obj.wb.Message = 'Connecting layers...'; obj.wb.Value = 0.5; end
sourceLayers = lgraph.Connections.Source;
destinationLayers = lgraph.Connections.Destination;
switch targetNetwork
    case {'resnet18', 'resnet50'}
        if max(ismember(sourceLayers, 'data')) == 1     % pre-trained nets
            sourceLayers(ismember(sourceLayers, 'data')) = {'ImageInputLayer'};
            destinationLayers(ismember(destinationLayers, 'data')) = {'ImageInputLayer'};
        else    % generated with deeplabv3plusLayers nets
            sourceLayers(ismember(sourceLayers, 'input_1')) = {'ImageInputLayer'};
            destinationLayers(ismember(destinationLayers, 'input_1')) = {'ImageInputLayer'};
        end
    case {'inceptionresnetv2', 'xception'}
        sourceLayers(ismember(sourceLayers, 'input_1')) = {'ImageInputLayer'};
        destinationLayers(ismember(destinationLayers, 'input_1')) = {'ImageInputLayer'};
end
sourceLayers(ismember(sourceLayers, 'classification')) = {'Segmentation-Layer'};
destinationLayers(ismember(destinationLayers, 'classification')) = {'Segmentation-Layer'};

noSourceLayers = numel(sourceLayers);
for connectId = 1:noSourceLayers
    net = connectLayers(net, sourceLayers{connectId}, destinationLayers{connectId});
    if obj.BatchOpt.showWaitbar && mod(layerId, 20) == 1; obj.wb.Value = 0.5+(connectId/(noSourceLayers*2));  end
end

end