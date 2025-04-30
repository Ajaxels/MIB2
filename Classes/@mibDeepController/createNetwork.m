function [lgraph, outputPatchSize] = createNetwork(obj, previewSwitch)
% function lgraph = createNetwork(obj, previewSwitch)
% generate network
% Parameters:
% previewSwitch: logical switch, when 1 - the generated network
% is only for preview, i.e. weights of classes won't be
% calculated
%
% Return values:
% lgraph: network object
% outputPatchSize: output patch size as [height, width, depth, color]

if nargin < 2; previewSwitch = 0; end
lgraph = [];
outputPatchSize = [];
inputPatchSize = str2num(obj.BatchOpt.T_InputPatchSize);    % as [height, width, depth, color]

% debug 2.5D
%obj.BatchOpt.Workflow{1} = '2.5D Semantic';
%obj.BatchOpt.Architecture{1} = '3DC + DLv3 Resnet18';

selectedArchitecture = obj.BatchOpt.Architecture{1};

try
    switch obj.BatchOpt.Workflow{1}
        case '2D Semantic'
            colorDimension = 4; % index of the color dimension in inputPatch

            switch selectedArchitecture
                case 'U-net'
                    [lgraph, outputPatchSize] = unetLayers(...
                        inputPatchSize([1 2 colorDimension]), obj.BatchOpt.T_NumberOfClasses{1}, ...
                        'NumFirstEncoderFilters', obj.BatchOpt.T_NumFirstEncoderFilters{1}, 'FilterSize', obj.BatchOpt.T_FilterSize{1}, ...
                        'ConvolutionPadding', obj.BatchOpt.T_ConvolutionPadding{1}, 'EncoderDepth', obj.BatchOpt.T_EncoderDepth{1}); %#ok<*ST2NM>
                    outputPatchSize = [outputPatchSize(1), outputPatchSize(2), 1, outputPatchSize(3)];  % reformat to [height, width, depth, numClasses]
                case 'U-net +Encoder'
                    [lgraph, outputPatchSize] = obj.generateUnet2DwithEncoder(inputPatchSize([1 2 colorDimension]), obj.BatchOpt.T_EncoderNetwork{1});
                    outputPatchSize = [outputPatchSize(1), outputPatchSize(2), 1, outputPatchSize(3)];  % reformat to [height, width, depth, numClasses]
                case 'SegNet'
                    lgraph = segnetLayers(inputPatchSize([1 2 colorDimension]), obj.BatchOpt.T_NumberOfClasses{1}, obj.BatchOpt.T_EncoderDepth{1}, ...
                        'NumOutputChannels', obj.BatchOpt.T_NumFirstEncoderFilters{1}, ...
                        'FilterSize', obj.BatchOpt.T_FilterSize{1});
                    outputPatchSize = inputPatchSize;  % as [height, width, depth, color]
                case 'DeepLab v3+'
                    if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')
                        uialert(obj.View.gui, ...
                            sprintf('!!! Error !!!\n\n"%s" network architecture requires:\n - input patch size of at least [224 224]\n- 1 or 3 color channels\n- "same" padding', obj.BatchOpt.Architecture{1}), ...
                            'Wrong configuration!');
                        return;
                    end

                    targetNetwork = lower(obj.BatchOpt.T_EncoderNetwork{1});
                    if ismember(targetNetwork, {'xception', 'inceptionresnetv2'}) && isdeployed
                        uialert(obj.View.gui, ...
                            sprintf('!!! Error !!!\n\nCurrently %s network is only available in MIB for MATLAB\nTry to use DLv3-Resnet18/50 instead!', obj.BatchOpt.Architecture{1}), ...
                            'Now available');
                        return;
                    end
                    lgraph = obj.generateDeepLabV3Network(inputPatchSize([1 2 colorDimension]), obj.BatchOpt.T_NumberOfClasses{1}, targetNetwork);
                    if isempty(lgraph); return; end
                    outputPatchSize = inputPatchSize([1 2 4]);
            end
        case '2.5D Semantic'
            if strcmp(obj.BatchOpt.Architecture{1}(1:3), 'Z2C')
                selectedArchitecture = obj.BatchOpt.Architecture{1}(7:end); % skip "Z2C + "
                colorDimension = 3; % index of the color dimension in inputPatch

                switch selectedArchitecture
                    case 'U-net'
                        [lgraph, outputPatchSize] = unetLayers(...
                            inputPatchSize([1 2 colorDimension]), obj.BatchOpt.T_NumberOfClasses{1}, ...
                            'NumFirstEncoderFilters', obj.BatchOpt.T_NumFirstEncoderFilters{1}, 'FilterSize', obj.BatchOpt.T_FilterSize{1}, ...
                            'ConvolutionPadding', obj.BatchOpt.T_ConvolutionPadding{1}, 'EncoderDepth', obj.BatchOpt.T_EncoderDepth{1}); %#ok<*ST2NM>
                    case 'U-net +Encoder'
                        [lgraph, outputPatchSize] = obj.generateUnet2DwithEncoder(inputPatchSize([1 2 colorDimension]), obj.BatchOpt.T_EncoderNetwork{1});
                        outputPatchSize = [outputPatchSize(1) outputPatchSize(2) 1]; % [height, width, depth]
                        % remove the skip connection from the first layer
                        lgraph = layerGraph(lgraph);
                        
                        % find index of the layer (encoderDecoderSkipConnectionCrop1) that needs to be removed
                        skipConnectionLayer = zeros([numel(lgraph.Layers), 1]);
                        % find indices of ReLU layers
                        for layerId = 1:numel(lgraph.Layers)
                            %if isa(lgraph.Layers(layerId), 'nnet.cnn.layer.Convolution2DLayer')
                            %    convIndices(layerId) = 1;
                            %end
                            if strcmp(lgraph.Layers(layerId).Name, 'encoderDecoderSkipConnectionCrop1')
                                skipConnectionLayer(layerId) = 1;
                            end
                        end
                        skipConnectionLayer = find(skipConnectionLayer);
                        % find the name of the previous layer to reconnect the new network
                        prevLayerName = lgraph.Layers(skipConnectionLayer-1).Name;
                        % find the name of the previous layer to reconnect the new network
                        % skip convolutions that were designed to use the
                        % channels from the input layer
                        nextLayerName = lgraph.Layers(skipConnectionLayer+4).Name;

                        removeLayerName0 = lgraph.Layers(skipConnectionLayer).Name;
                        removeLayerName1 = lgraph.Layers(skipConnectionLayer+1).Name;
                        removeLayerName2 = lgraph.Layers(skipConnectionLayer+2).Name;
                        removeLayerName3 = lgraph.Layers(skipConnectionLayer+3).Name;

                        lgraph = removeLayers(lgraph, removeLayerName0);
                        lgraph = removeLayers(lgraph, removeLayerName1);
                        lgraph = removeLayers(lgraph, removeLayerName2);
                        lgraph = removeLayers(lgraph, removeLayerName3);

                        lgraph = connectLayers(lgraph, prevLayerName, nextLayerName);
                        % Convert to dlnetwork
                        lgraph = dlnetwork(lgraph);

                    case 'DLv3'
                        if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')
                            uialert(obj.View.gui, ...
                                sprintf('!!! Error !!!\n\n"%s" network architecture requires:\n - input patch size of at least [224 224]\n- 1 or 3 color channels\n- "same" padding', obj.BatchOpt.Architecture{1}), ...
                                'Wrong configuration!');
                            return;
                        end
                        targetNetwork = lower(obj.BatchOpt.T_EncoderNetwork{1});
                        
                        lgraph = obj.generateDeepLabV3Network(inputPatchSize([1 2 colorDimension]), obj.BatchOpt.T_NumberOfClasses{1}, targetNetwork);
                        if isempty(lgraph); return; end
                        outputPatchSize = inputPatchSize([1 2 4]);
                end
            else  % 3D convolutional filters
                switch selectedArchitecture
                    case {'3DC + DLv3 Resnet18'}
                        if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')
                            uialert(obj.View.gui, ...
                                sprintf('!!! Error !!!\n\n"%s" network architecture requires:\n - input patch size of at least [224 224]\n- 1 or 3 color channels\n- "same" padding', obj.BatchOpt.Architecture{1}), ...
                                'Wrong configuration!');
                            return;
                        end
                        switch selectedArchitecture
                            case '3DC + DLv3 Resnet18'
                                targetNetwork = 'resnet18';
                            case '3DC + DLv3 Resnet50'
                                targetNetwork = 'resnet50';
                        end
                        lgraph = obj.generate3DDeepLabV3Network(inputPatchSize, obj.BatchOpt.T_NumberOfClasses{1}, targetNetwork);

                        if isempty(lgraph); return; end
                        outputPatchSize = inputPatchSize([1 2 3 4]);
                end
            end
        case '3D Semantic'
            switch selectedArchitecture
                case 'U-net'
                    %lgraph = obj.generate3DDeepLabV3Network(inputPatchSize([1 2 4]), obj.BatchOpt.T_NumberOfClasses{1}, 8, 'resnet50');


                    [lgraph, outputPatchSize] = unet3dLayers(...
                        inputPatchSize, obj.BatchOpt.T_NumberOfClasses{1}, ...
                        'NumFirstEncoderFilters', obj.BatchOpt.T_NumFirstEncoderFilters{1}, 'FilterSize', obj.BatchOpt.T_FilterSize{1}, ...
                        'ConvolutionPadding', obj.BatchOpt.T_ConvolutionPadding{1}, 'EncoderDepth', obj.BatchOpt.T_EncoderDepth{1}); %#ok<*ST2NM>
                case 'U-net Anisotropic'
                    % 3D U-net for anisotropic datasets, the first
                    % convolutional and max pooling layers are 2D
                    switch obj.BatchOpt.T_ConvolutionPadding{1}
                        case 'same'
                            PaddingValue = 'same';
                        case 'valid'
                            PaddingValue = 0;
                    end

                    % generate standard 3D Unet
                    [lgraph, outputPatchSize] = unet3dLayers(...
                        inputPatchSize, obj.BatchOpt.T_NumberOfClasses{1}, ...
                        'NumFirstEncoderFilters', obj.BatchOpt.T_NumFirstEncoderFilters{1}, 'FilterSize', obj.BatchOpt.T_FilterSize{1}, ...
                        'ConvolutionPadding', obj.BatchOpt.T_ConvolutionPadding{1}, 'EncoderDepth', obj.BatchOpt.T_EncoderDepth{1});

                    % replace first convolution layers of the 1 lvl of the net
                    %lgraph.Layers(2).Name
                    layerId = find(ismember({lgraph.Layers.Name}, 'Encoder-Stage-1-Conv-1')==1);
                    layer = convolution3dLayer([obj.BatchOpt.T_FilterSize{1} obj.BatchOpt.T_FilterSize{1} 1], obj.BatchOpt.T_NumFirstEncoderFilters{1}, ...
                        'Padding', PaddingValue, 'Name', lgraph.Layers(layerId).Name);
                    lgraph = replaceLayer(lgraph, lgraph.Layers(layerId).Name, layer);

                    layerId = find(ismember({lgraph.Layers.Name}, 'Encoder-Stage-1-Conv-2')==1);
                    layer = convolution3dLayer([obj.BatchOpt.T_FilterSize{1} obj.BatchOpt.T_FilterSize{1} 1], obj.BatchOpt.T_NumFirstEncoderFilters{1}, ...
                        'Padding', PaddingValue, 'Name', lgraph.Layers(layerId).Name);
                    lgraph = replaceLayer(lgraph, lgraph.Layers(layerId).Name, layer);

                    layerId = find(ismember({lgraph.Layers.Name}, 'Encoder-Stage-1-MaxPool')==1);
                    layer = maxPooling3dLayer([2 2 1], ...
                        'Padding', PaddingValue, 'Name', lgraph.Layers(layerId).Name, ...
                        'Stride', [2 2 1]);
                    lgraph = replaceLayer(lgraph, lgraph.Layers(layerId).Name, layer);

                    %analyzeNetwork(lgraph);
                    % get index of the final convolution layer
                    finalConvId = find(ismember({lgraph.Layers.Name}, 'Final-ConvolutionLayer')==1);
                    % using name of the previous level find index of the last decoder stage
                    layerName = lgraph.Layers(finalConvId-1).Name;  % 'Decoder-Stage-2-ReLU-2'
                    dashIds = strfind(layerName, '-');  % positions of dashes
                    stageId = layerName(dashIds(2)+1:dashIds(3)-1);     % get stage id

                    layerId = find(ismember({lgraph.Layers.Name}, sprintf('Decoder-Stage-%s-UpConv', stageId))==1);
                    layer = transposedConv3dLayer([2 2 1], lgraph.Layers(layerId).NumFilters, ...
                        'Stride', [2 2 1], 'Name', lgraph.Layers(layerId).Name);
                    lgraph = replaceLayer(lgraph, lgraph.Layers(layerId).Name, layer);

                    layerId = find(ismember({lgraph.Layers.Name}, sprintf('Decoder-Stage-%s-Conv-1', stageId))==1);
                    layer = convolution3dLayer([obj.BatchOpt.T_FilterSize{1} obj.BatchOpt.T_FilterSize{1} 1], obj.BatchOpt.T_NumFirstEncoderFilters{1}, ...
                        'Padding', PaddingValue, 'Name', lgraph.Layers(layerId).Name);
                    lgraph = replaceLayer(lgraph, lgraph.Layers(layerId).Name, layer);

                    layerId = find(ismember({lgraph.Layers.Name}, sprintf('Decoder-Stage-%s-Conv-2', stageId))==1);
                    layer = convolution3dLayer([obj.BatchOpt.T_FilterSize{1} obj.BatchOpt.T_FilterSize{1} 1], obj.BatchOpt.T_NumFirstEncoderFilters{1}, ...
                        'Padding', PaddingValue, 'Name', lgraph.Layers(layerId).Name);
                    lgraph = replaceLayer(lgraph, lgraph.Layers(layerId).Name, layer);

                    if strcmp(obj.BatchOpt.T_ConvolutionPadding{1}, 'valid')
                        outputPatchSize = [];
                    end
            end
        case '2D Patch-wise'
            if obj.BatchOpt.T_UseImageNetWeights
                if isdeployed
                    uialert(obj.View.gui,...
                        sprintf('!!! Warning !!!\n\nInitialization of the network with imagenet weights is only available in MIB for MATLAB!\n\nPlease uncheck the "use ImageNet weights" checkbox to initialize the network using empty weights and try again.'), ...
                        'Not available', 'Icon', 'warning');
                    return;
                end
                if inputPatchSize(4) ~= 3
                    uialert(obj.View.gui,...
                        sprintf('!!! Warning !!!\n\nInitialization of the network with imagenet weights is only available for images with 3 color channels!\n\nPlease change "Input patch size" to [%d %d %d 3] and try again.', ...
                        inputPatchSize(1), inputPatchSize(2), inputPatchSize(3)), ...
                        'Not available', 'Icon', 'warning');
                    return;
                end
                weightsValue = 'imagenet';
            else
                weightsValue = 'none';
            end
            try
                switch selectedArchitecture
                    case 'Resnet18'
                        lgraph = resnet18('Weights', weightsValue);
                        outputPatchSize = [1 1 inputPatchSize(4)];
                    case 'Resnet50'
                        lgraph = resnet50('Weights', weightsValue);
                        outputPatchSize = [1 1 inputPatchSize(4)];
                    case 'Resnet101'
                        lgraph = resnet101('Weights', weightsValue);
                        outputPatchSize = [1 1 inputPatchSize(4)];
                    case 'Xception'
                        lgraph = xception('Weights', weightsValue);
                        outputPatchSize = [1 1 inputPatchSize(4)];
                end
                % convert from 'DAGNetwork' to 'LayerGraph'
                % when init with imagenet weights
                if isa(lgraph, 'DAGNetwork')
                    lgraph = layerGraph(lgraph);
                end
            catch err
                %obj.showErrorDialog(err, 'Missing packages', '', 'Most likely required package is missing!');
                mibShowErrorDialog(obj.View.gui, err, 'Missing packages', '', 'Most likely required package is missing!');
                return;
            end
    end     % end of "switch obj.BatchOpt.Workflow"
catch err
    if obj.mibController.matlabVersion >= 9.11
        uialert(obj.View.gui, ...
            sprintf('%s', err.message), 'Network configuration error', 'Icon', 'error', 'Interpreter', 'html');
    else
        uialert(obj.View.gui, ...
            sprintf('%s', err.message), 'Network configuration error', 'Icon', 'error');
    end
    return;
end

% update the input layer
lgraph = obj.updateNetworkInputLayer(lgraph, inputPatchSize);
if isempty(lgraph); return; end

% update the activation layers
lgraph = obj.updateActivationLayers(lgraph);

% update the initialization weight for convolutional layers
% lgraph = updateConvolutionLayers(obj, lgraph);

% update maxPool and TransposedConvolution layers depending on network downsampling factor
if obj.View.handles.T_DownsamplingFactor.Value ~=2 && ismember(selectedArchitecture, {'U-net', 'SegNet'})
    lgraph = obj.updateMaxPoolAndTransConvLayers(lgraph);
end

if strcmp(obj.BatchOpt.Workflow{1}, '2D Patch-wise') % 2D Patch-wise Resnet18 or 2D Patch-wise Resnet50
    % update last 3 layers to adapt them to the new number of output classes
    fullConnLayer = fullyConnectedLayer(obj.BatchOpt.T_NumberOfClasses{1}-1, 'Name', 'FullyConnectedLayer');
    switch obj.BatchOpt.Architecture{1}
        case {'Resnet18', 'Resnet50', 'Resnet101'}
            lgraph = replaceLayer(lgraph, 'fc1000', fullConnLayer);
        case 'Xception'
            lgraph = replaceLayer(lgraph, 'predictions', fullConnLayer);
    end
    if obj.BatchOpt.T_UseImageNetWeights % replace classification output layer
        classificationOutputLayer = classificationLayer('Name', 'ClassificationLayer_predictions');
        lgraph = replaceLayer(lgraph, lgraph.Layers(end).Name, classificationOutputLayer); % 'ClassificationLayer_predictions'
    end
else    % semantic segmentation
    if ~isa(lgraph, 'dlnetwork')
        lgraph = obj.updateSegmentationLayer(lgraph);
    end
end
end