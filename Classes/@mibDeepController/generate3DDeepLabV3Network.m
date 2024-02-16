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

function net = generate3DDeepLabV3Network(obj, imageSize, numClasses, targetNetwork)
% function generate3DDeepLabV3Network(obj, imageSize, numClasses, targetNetwork)
% generate a hybrid 2.5D DeepLabv3+ convolutional neural network for semantic image
% segmentation. The training data should be a small substack of 3,5,7 etc
% slices, where only the middle slice is segmented.
% As the update, a 2 blocks of 3D convolutions were added before the
% standard DLv3
%
% Parameters:
% imageSize: vector [height, width, colors] defining input patch size,
% should be larger than [224 224] for resnet18, colors should be 3
% numClasses: number of output classes (including exterior) for the output results
% targetNetwork: string defining the base architecture for the initialization
%   'resnet18' - resnet18 network
%   'resnet50' - resnet50 network
%   'xception' - xception network
%   'inceptionresnetv2' - resnet50 network

%
% Updates
%

global mibPath;

if nargin < 4; targetNetwork = 'resnet18'; end

%% generate/acquire template DeepLabV3 network
if strcmp(targetNetwork, 'xception') || strcmp(targetNetwork, 'inceptionresnetv2')  % 'resnet50', 'xception', 'inceptionresnetv2'
    % define parameters for dummy initialization
    if imageSize(3) == 3
        net = deeplabv3plusLayers(imageSize, numClasses, targetNetwork, 'DownsamplingFactor', 16);
        return;
    end
    dummyImageSize = [imageSize([1 2]), 3];
    lgraph = deeplabv3plusLayers(dummyImageSize, numClasses, targetNetwork, 'DownsamplingFactor', 16);
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
        options.Title = sprintf(['!!! Warning !!!\n\n' ...
            'Generation of CNN using the "2D DeepLabV3 %s" architecture requires a templete file!\n\n' ...
            'The file will be downloaded and placed to\n%s\n' ...
            'This destination directory can be changed from\n' ...
            'Menu->File->Preferences->External directories'], targetNetwork, strrep(obj.mibModel.preferences.ExternalDirs.DeepMIBDir,'\','/'));
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
            if obj.wb.CancelRequested; net = []; return; end
            obj.wb.Value = 0;
            obj.wb.Message = 'Downloading network...'; 
        end
        unzip(sprintf('http://mib.helsinki.fi/tutorials/deepmib/%s.zip', fnTemplate), obj.mibModel.preferences.ExternalDirs.DeepMIBDir);
        if obj.BatchOpt.showWaitbar
            if obj.wb.CancelRequested; net = []; return; end
            obj.wb.Message = 'Generating network...'; 
            obj.wb.Value = 0.5; 
        end
    end
    load(fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, netName), 'lgraph');
end

%% generate template for 3D Unet network
%lgraphUnet = unet3dLayers([imageSize(1) imageSize(2) imageSize(3)+1 imageSize(4)], numClasses, 'EncoderDepth', 1, ...
%    'NumFirstEncoderFilters', obj.BatchOpt.T_NumFirstEncoderFilters{1}, 'FilterSize', obj.BatchOpt.T_FilterSize{1});

% start a new network for the output
net = layerGraph();

%% Define config parameters
weightsInitializer = 'he'; % 'glorot', 'he', 'narrow-normal', 'zeros', 'ones'
% define padding for convolution3dLayer, default one from DeepLabV3 is == 0
conv3Dpadding = 0; %'symmetric-exclude-edge'; % 0 (default), scalar, 'symmetric-include-edge', 'symmetric-exclude-edge', 'replicate'
dilationFactor = [1 1 1];   % [1 1 1], [2 2 2] to make kernel 5x5x5 from 3
convolutionFilterSize = [obj.BatchOpt.T_FilterSize{1} obj.BatchOpt.T_FilterSize{1} imageSize(3)];

%% Image input layer
if obj.BatchOpt.showWaitbar
    if obj.wb.CancelRequested; net = []; return; end
    obj.wb.Message = 'Adding 3D encoder layers...'; 
    obj.wb.Value = 0.15; 
end
inputLayer = image3dInputLayer(imageSize, 'Name', 'ImageInputLayer');
net = addLayers(net, inputLayer);

% adding resize layer
% resizeLayer = resize3dLayer("Name", "resize3d-encoder-size", "GeometricTransformMode", "half-pixel", "Method", "nearest", "NearestRoundingMode", "round", "OutputSize", [imageSize(1) imageSize(2) 1]);
% net = addLayers(net, resizeLayer);
% net = connectLayers(net,'ImageInputLayer','resize3d-encoder-size');

%% define 3D encoder part
encoder3DLayers = [
    convolution3dLayer(convolutionFilterSize, obj.BatchOpt.T_NumFirstEncoderFilters{1}, 'Name', 'enc3d_conv1', 'Padding', 'same', 'WeightsInitializer', weightsInitializer, 'DilationFactor', dilationFactor, 'Stride', [2 2 1])
    batchNormalizationLayer('Name', 'enc3d_bn1')
    reluLayer('Name','enc3d_relu1')
    convolution3dLayer(convolutionFilterSize, obj.BatchOpt.T_NumFirstEncoderFilters{1}*2, 'Name', 'enc3d_conv2', 'Padding', 'same', 'WeightsInitializer', weightsInitializer, 'DilationFactor', dilationFactor, 'Stride', [1 1 1])
    batchNormalizationLayer('Name','enc3d_bn2')
    reluLayer('Name','enc3d_relu2')

    maxPooling3dLayer([1 1 imageSize(3)], 'Name', 'enc3d_pool1', 'Padding', 'same', 'Stride', [1 1 imageSize(3)]);
    ];

% get number of filters after encoder of 3D-Unet
encoder3DFilters = obj.BatchOpt.T_NumFirstEncoderFilters{1}*2;
encoderLastLayerName = 'enc3d_pool1';

% add 3D encoder layers to the net
net = addLayers(net, encoder3DLayers);

%% Generate the initial part of the DLv3-3D branch
% make connections
net = connectLayers(net,'ImageInputLayer','enc3d_conv1');

% define that the following layers are coming after the scorer layer and should have update number of classes
% updated in 'nnet.cnn.layer.Convolution2DLayer' scorer layer:
afterScorerLayerSwitch = false;
noLayers = numel(lgraph.Layers);
% find softmax layer
softmaxLayerIndex = find(arrayfun(@(x) isa(x, 'nnet.cnn.layer.SoftmaxLayer'), lgraph.Layers));
% find scorer layer index
scorerLayerIndex = find(arrayfun(@(x) strcmp(x.Name, 'scorer'), lgraph.Layers));

% extra channels and extra filters add filters coming from 3D convolution branch
extraChannels = 0;
extraFilters = 0;
customStride = [];  % tweak to modify stride for particular layers
customNumChannels = []; % tweak to modify number of channels for particular layers
%% Process the main part of DLv3 network branch

for layerId = 2:scorerLayerIndex-1
    % update filters and channels depending of 3D convolutions
    switch lgraph.Layers(layerId).Name
        case 'conv1'
            % first convolution filter of DLv3
            customStride = [1 1 1];
            customNumChannels = encoder3DFilters;
    end

    switch class(lgraph.Layers(layerId))
        case 'nnet.cnn.layer.Convolution2DLayer'
            if strcmp(lgraph.Layers(layerId).Name, 'scorer') % the layer defining number of output classes
                afterScorerLayerSwitch = true;  % define that the following layers are coming after the scorer layer and should have update number of classes
                numConvFilters = numClasses;
                filterSize = lgraph.Layers(layerId).FilterSize;
            else
                numConvFilters = lgraph.Layers(layerId).NumFilters + extraFilters;
                %numChannels = lgraph.Layers(layerId).NumChannels + extraChannels;
                filterSize = lgraph.Layers(layerId).FilterSize;
                dilationFactor3D = [lgraph.Layers(layerId).DilationFactor 1];
            end

            % update number of color channels
            if isempty(customNumChannels); customNumChannels = lgraph.Layers(layerId).NumChannels; end

            % update stride parameter
            if isempty(customStride); customStride = [lgraph.Layers(layerId).Stride 1]; end

            if strcmp(lgraph.Layers(layerId).PaddingMode, 'same')
                layer = convolution3dLayer([filterSize 1], ...   % filter size
                    numConvFilters, ...   % number of filters to generate
                    'Padding', 'same', ...
                    'PaddingValue', conv3Dpadding, ...
                    'Stride', customStride, ...
                    'NumChannels', customNumChannels, ...
                    'DilationFactor', dilationFactor3D, ...
                    'Name', lgraph.Layers(layerId).Name);
            else
                layer = convolution3dLayer([filterSize 1], ...   % filter size
                    numConvFilters, ...   % number of filters to generate
                    'PaddingValue', conv3Dpadding, ...
                    'Padding', [lgraph.Layers(layerId).PaddingSize(1) lgraph.Layers(layerId).PaddingSize(2) 0; lgraph.Layers(layerId).PaddingSize(3) lgraph.Layers(layerId).PaddingSize(4) 0], ...
                    'Stride', customStride, ...
                    'NumChannels', customNumChannels, ...
                    'DilationFactor', dilationFactor3D, ...
                    'Name', lgraph.Layers(layerId).Name);
            end
        case 'nnet.cnn.layer.MaxPooling2DLayer'
            layer = maxPooling3dLayer([lgraph.Layers(layerId).PoolSize 1],  ...
                'Stride', [lgraph.Layers(layerId).Stride 1], ...
                'Padding', [lgraph.Layers(layerId).PaddingSize 0 0], ...
                'Name', lgraph.Layers(layerId).Name);
        case 'nnet.cnn.layer.DepthConcatenationLayer'
            layer = concatenationLayer(4, lgraph.Layers(layerId).NumInputs, 'Name', lgraph.Layers(layerId).Name);
        case 'nnet.cnn.layer.TransposedConvolution2DLayer'
            if ~afterScorerLayerSwitch
                numConvFilters = lgraph.Layers(layerId).NumFilters + extraFilters;
                numChannels = lgraph.Layers(layerId).NumChannels + extraChannels;

                layer = transposedConv3dLayer([lgraph.Layers(layerId).FilterSize 1], ...    % filter size
                    numConvFilters, ...   % number of filters to generate
                    'NumChannels', numChannels, ...
                    'Stride', [lgraph.Layers(layerId).Stride, 1], ...
                    'Cropping', [lgraph.Layers(layerId).CroppingSize(1) lgraph.Layers(layerId).CroppingSize(2) 0;  lgraph.Layers(layerId).CroppingSize(3) lgraph.Layers(layerId).CroppingSize(4) 0; ], ...
                    'Name', lgraph.Layers(layerId).Name);
            else
                numConvFilters = numClasses;
                numChannels = numClasses;

                layer = transposedConv3dLayer([lgraph.Layers(layerId).FilterSize 1], ...    % filter size
                    numConvFilters, ...   % number of filters to generate
                    'NumChannels', numChannels, ...
                    'Stride', [lgraph.Layers(layerId).Stride, 1], ...
                    'Cropping', [lgraph.Layers(layerId).CroppingSize(1) lgraph.Layers(layerId).CroppingSize(2) 0;  lgraph.Layers(layerId).CroppingSize(3) lgraph.Layers(layerId).CroppingSize(4) 0; ], ...
                    'Name', lgraph.Layers(layerId).Name);

                % generates weights from the template network
                %weightsMatrix = zeros([size(lgraph.Layers(layerId).Weights, 1), size(lgraph.Layers(layerId).Weights, 1), numClasses, numClasses]);
                %for i=1:numClasses
                %    weightsMatrix(:,:,i,i) = lgraph.Layers(layerId).Weights(:,:,1,1);
                %end
                %layer.Weights = weightsMatrix;
            end
        case 'nnet.cnn.layer.Crop2DLayer'
            layer = crop3dLayer(lgraph.Layers(layerId).Mode, 'Name', lgraph.Layers(layerId).Name);
        case 'nnet.cnn.layer.AveragePooling2DLayer'
            layer = averagePooling3dLayer([lgraph.Layers(layerId).PoolSize 1], 'Name', lgraph.Layers(layerId).Name);
        case 'nnet.cnn.layer.BatchNormalizationLayer'
            layer = batchNormalizationLayer('Name', lgraph.Layers(layerId).Name);
        otherwise
            layer = lgraph.Layers(layerId);
    end
    net = addLayers(net, layer);

    % reset custom parameters
    customStride = [];  % tweak to modify stride for particular layers
    customNumChannels = []; % tweak to change number of color channels

    if obj.BatchOpt.showWaitbar && mod(layerId, 20) == 1; if obj.wb.CancelRequested; net = []; return; end; obj.wb.Value = layerId/(noLayers*2); end
end

%% connect layers
if obj.BatchOpt.showWaitbar 
    if obj.wb.CancelRequested; net = []; return; end; 
    obj.wb.Value = 0.5; 
    obj.wb.Message = 'Connecting layers...'; 
end

% connect DLv3 layers
sourceLayers = lgraph.Connections.Source;
destinationLayers = lgraph.Connections.Destination;
switch targetNetwork
    case {'resnet18', 'resnet50'}
        sourceLayers(ismember(sourceLayers, 'data')) = {'ImageInputLayer'};
        destinationLayers(ismember(destinationLayers, 'data')) = {'ImageInputLayer'};
    case {'inceptionresnetv2', 'xception'}
        sourceLayers(ismember(sourceLayers, 'input_1')) = {'ImageInputLayer'};
        destinationLayers(ismember(destinationLayers, 'input_1')) = {'ImageInputLayer'};
end
sourceLayers(ismember(sourceLayers, 'classification')) = {'Segmentation-Layer'};
destinationLayers(ismember(destinationLayers, 'classification')) = {'Segmentation-Layer'};

% define layers to be removed
sourceLayersBlackList = {'ImageInputLayer', 'softmax-out', 'dec_relu4', 'scorer', 'dec_upsample2', 'dec_crop2'};
destinationLayersBlackList = {'ImageInputLayer', 'conv1', 'softmax-out', 'scorer', 'dec_upsample2', 'dec_crop2'};

% connect layers
noSourceLayers = numel(sourceLayers);
for connectId = 1:noSourceLayers
    if ismember(sourceLayers{connectId}, sourceLayersBlackList); continue; end
    if ismember(destinationLayers{connectId}, destinationLayersBlackList); continue; end
    net = connectLayers(net, sourceLayers{connectId}, destinationLayers{connectId});
    if obj.BatchOpt.showWaitbar && mod(layerId, 20) == 1; if obj.wb.CancelRequested; net = []; return; end; obj.wb.Value = 0.5+(connectId/(noSourceLayers*2));  end
end

% connect the 3D conv encoder to the input of DLv3
net = connectLayers(net, encoderLastLayerName, 'conv1');

% for i=1:numel(sourceLayers)
%     fprintf('%s -> %s     %s -> %s\n', sourceLayers{i}, destinationLayers{i}, lgraph.Connections.Source{i+2},  lgraph.Connections.Destination{i+2});
% end

if obj.BatchOpt.showWaitbar
    if obj.wb.CancelRequested; net = []; return; end
    obj.wb.Value = 0.6; 
    obj.wb.Message = 'Finalizing the decoder part...'; 
end

% finishing as in 2D DLv3 without 3D convolutions

lastDLv4LayerName = 'dec_relu4';

decoder3DLayers = [
    transposedConv3dLayer([4 4 imageSize(3)], numConvFilters, 'Name', 'dec3d_upconv1', 'BiasLearnRateFactor', 2, 'Stride', [2 2 1], 'WeightsInitializer', weightsInitializer)
    crop3dLayer('centercrop', 'Name', 'dec3d_crop1');
    concatenationLayer(4, 2, 'Name', 'dec3d_concat1')

    convolution3dLayer(convolutionFilterSize, obj.BatchOpt.T_NumFirstEncoderFilters{1}, ...
        'Name', 'dec3d_conv1', ...
        'NumChannels', obj.BatchOpt.T_NumFirstEncoderFilters{1}*2 + numConvFilters, ...
        'Padding','same', ...
        'WeightsInitializer', weightsInitializer, ...
        'DilationFactor', dilationFactor)
        batchNormalizationLayer('Name', 'dec3d_bn1')
        reluLayer('Name', 'dec3d_relu1')

    convolution3dLayer(convolutionFilterSize, obj.BatchOpt.T_NumFirstEncoderFilters{1}, ...
        'Name', 'dec3d_conv2', ...
        'NumChannels', obj.BatchOpt.T_NumFirstEncoderFilters{1}, ...
        'Padding','same', ...
        'WeightsInitializer', weightsInitializer, ...
        'DilationFactor', dilationFactor)
        batchNormalizationLayer('Name', 'dec3d_bn2')
        reluLayer('Name', 'dec3d_relu2')

    transposedConv3dLayer([2 2 1], numClasses, ...
        'Name', 'Final-Convolution', 'BiasLearnRateFactor', 2, ...
        'Stride', [2 2 1], 'WeightsInitializer', weightsInitializer)

    softmaxLayer('Name','Softmax-Layer')
    pixelClassificationLayer('Name','Segmentation-Layer')
    ];
net = addLayers(net, decoder3DLayers);

% connect Layer Branches
net = connectLayers(net, lastDLv4LayerName, 'dec3d_upconv1');
net = connectLayers(net, 'enc3d_relu2', 'dec3d_crop1/ref');
net = connectLayers(net, 'enc3d_relu2', 'dec3d_concat1/in2');
if obj.BatchOpt.showWaitbar; obj.wb.Value = 1; drawnow; end

end

function X = padResult(X, Y)
% custom function to pad 2D softmax to 3D

pad = X.*0;
pad = dlresize(pad, 'Scale', [1 1 floor(size(Y,3)/2)]);
X = cat(3, pad, X);
X = cat(3, X, pad);

end