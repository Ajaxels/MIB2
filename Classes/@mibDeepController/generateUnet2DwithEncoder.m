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
% Date: 24.10.2024

function [net, outputSize] = generateUnet2DwithEncoder(obj, imageSize, encoderNetwork)
% function generateUnet2DwithEncoder(obj, imageSize, encoderNetwork)
% generate Unet convolutional neural network for semantic image
% segmentation of 2D RGB images using a specified encoder 
%
% Parameters:
% imageSize: vector [height, width, colors] defining input patch size,
% should be larger than [224 224] for Resnet18, colors should be 3
% encoderNetwork: string defining the base architecture for the initialization
%   'Classic' - classic unet architecture
%   'Resnet18' - Resnet18 network
%   'Resnet50' - Resnet50 network
%
% Return values:
% net:  Unet dlnetwork, with softmax (Name: 'FinalNetworkSoftmax-Layer') as the final layer
% outputSize: output size of the network returned as [height, width, number of classes]
% Updates
% 

if nargin < 3; encoderNetwork = 'Classic'; end

encoderDepth = obj.BatchOpt.T_EncoderDepth{1};
numClasses = obj.BatchOpt.T_NumberOfClasses{1};

if obj.BatchOpt.showWaitbar; obj.wb.Message = 'Generating network...'; obj.wb.Value = 0.1; end

switch encoderNetwork
    case {'Resnet18', 'Resnet50'}
        if encoderDepth > 5
            errID = 'generateUnet2DwithEncoder:wrongEncoderDepth';
            msgtext = sprintf('!!! Error !!!\n\nThe maximal depth of the encoder is 5!');
            ME = MException(errID, msgtext);
            throw(ME);
        end

        % generate template network
        % define filename for the encoder network
        encoderFilename = sprintf('encoder_%s_depth%d.mat', lower(encoderNetwork), encoderDepth);
        [~, fnTemplate] = fileparts(encoderFilename);

        if exist(fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, encoderFilename), 'file') == 0
            if obj.BatchOpt.showWaitbar
                obj.wb.Value = 0.3;
                obj.wb.Message = 'Downloading network...';
            end
            try
                unzip(sprintf('http://mib.helsinki.fi/web-update/encoders/%s.zip', fnTemplate), obj.mibModel.preferences.ExternalDirs.DeepMIBDir);
            catch err
                unzip(sprintf('https://mib.helsinki.fi/web-update/encoders/%s.zip', fnTemplate), obj.mibModel.preferences.ExternalDirs.DeepMIBDir);
            end
        end
        if obj.BatchOpt.showWaitbar; obj.wb.Value = 0.3; end
        load(fullfile(obj.mibModel.preferences.ExternalDirs.DeepMIBDir, encoderFilename), 'encoder');

        if obj.BatchOpt.showWaitbar; obj.wb.Value = 0.4; end

        % downsamplging factor check
        downsampleFactor = 2^encoderDepth;
        if mod(imageSize(1), downsampleFactor) ~= 0 || mod(imageSize(2), downsampleFactor) ~= 0
            targetImageSize = imageSize;
            targetImageSize(1) = floor(imageSize(1) / downsampleFactor)*downsampleFactor;
            targetImageSize(2) = floor(imageSize(2) / downsampleFactor)*downsampleFactor;

            errID = 'generateUnet2DwithEncoder:wrongDimensions';
            msgtext = sprintf(['!!! Error !!!\n\n' ...
                'The width and height of the image must be a multiple of %d.\n' ...
                'You can specify image size as [%d %d %d] ' ...
                'instead of [%d %d %d]'], ...
                2^encoderDepth, ...
                targetImageSize(1), targetImageSize(2), imageSize(3), ...
                imageSize(1), imageSize(2), imageSize(3));
            ME = MException(errID, msgtext);
            throw(ME);
        end

        % Filter size is not used
        % NumFirstEncoderFilters is not used
        [net, outputSize] = unet(imageSize, numClasses, ...
            'EncoderDepth', encoderDepth, ...
            'EncoderNetwork', encoder.netEncoder, ...
            'ConvolutionPadding', obj.BatchOpt.T_ConvolutionPadding{1});

    case 'Classic'
        [net, outputSize] = unet(imageSize, numClasses, ...
            'EncoderDepth', encoderDepth, ...
            'ConvolutionPadding', obj.BatchOpt.T_ConvolutionPadding{1}, ...
            'FilterSize', obj.BatchOpt.T_FilterSize{1}, ...
            'NumFirstEncoderFilters', obj.BatchOpt.T_NumFirstEncoderFilters{1});
end

% is seems to be a bug there in R2024b
outputSize(3) = numClasses;

if obj.BatchOpt.showWaitbar; obj.wb.Value = 0.5; end

end