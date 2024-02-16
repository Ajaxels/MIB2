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

classdef dicePixelCustomClassificationLayer < nnet.layer.ClassificationLayer
    % This layer implements the generalized Dice loss function for training
    % semantic segmentation networks.
    
    properties(Constant)
        % Small constant to prevent division by zero. 
        Epsilon = 1e-8;
            
    end
    
    properties 
        % use mask as the last material of the model
        dataDimension   % value defining dimension of the data: 2, 2.5, 3
        useClasses = [];  % indices of class ids to be used for calculation of loss
    end
    
    methods
        
        function layer = dicePixelCustomClassificationLayer(name, dataDimension, useClasses)
            % layer =  dicePixelClassificationLayer(name, dataDimension, useClasses) creates a Dice
            % pixel classification layer with the specified name.
            %
            % Parameters:
            % name: name of the layer
            % dimension: number specifying data dimension, 2-2D or 2.5D, 3-3D
            % useClasses: vector with classes to use for calculation of the
            % loss function, when empty all classes are taken into account
            
            % use all classes for calculation of loss
            if nargin < 3
                layer.useClasses = []; 
            else
                layer.useClasses = useClasses; 
            end

            if nargin < 2
                if strcmp(name, 'Custom Dice Segmentation Layer 3D')
                    layer.dataDimension = 3;    % 3D network
                else
                    layer.dataDimension = 2;    % 2D network
                end
            else
                layer.dataDimension = dataDimension;      
            end

            % Set layer name.          
            layer.Name = name;
            
            % Set layer description.
            layer.Description = 'Custom Dice Loss';
        end
        
        
        function loss = forwardLoss(layer, Y, T)
            % loss = forwardLoss(layer, Y, T) returns the Dice loss between
            % the predictions Y and the training targets T.   

            % checks
%             sliceNo = 32;
%             Y2 = gather(Y);     % prediction
%             T2 = gather(T);     % labels: T2(:,:,sliceNo, 1==bg); T2(:,:,sliceNo, 2==label); T2(:,:,sliceNo, 3==mask)
%             layer.Unet2DSwitch == 1:     T2(height, width, label, batchImgId)
%             layer.Unet2DSwitch == 0:     T2(height, width, depth, label, batchImgId)
%             figure(1);
%             imshowpair(Y2(:,:,sliceNo,1,1), T2(:,:,sliceNo,2,1));
            
            %layer.useClasses = 2;   % 1-bg, 2-material1, 3-material2...
            if ~isempty(layer.useClasses)
                if layer.dataDimension == 2
                    T = T(:,:,layer.useClasses,:);
                    Y = Y(:,:,layer.useClasses,:);
                else
                    T = T(:,:,:,layer.useClasses,:);
                    Y = Y(:,:,:,layer.useClasses,:);
                end
            end

            if layer.dataDimension == 2 %    2D network
                % weights are equal to
                % W(1) = 1/numel(find(T(:,:,1)==1))^2;  % count bg weight
                % W(2) = 1/numel(find(T(:,:,2)==1))^2;  % count obj weight
                W = 1 ./ sum(sum(T,1), 2).^2;
                W(W == Inf) = layer.Epsilon;   % add layer.Epsilon to compensate for missing classes in the patch

                intersection = sum(sum(Y.*T, 1), 2);
                union = sum(sum(Y.^2 + T.^2, 1), 2);  % union = sum(sum(Y + T, 1),2);

                numer = 2*sum(W.*intersection, 3);
                denom = sum(W.*union, 3);

                N = size(Y, 4);     % for the average dice-loss
                %                 elseif layer.dataDimension == 2.5 %    2D network
                %                     zVal = ceil(size(T, 3)/2);
                %                     W = 1 ./ sum(sum(T(:,:,zVal,:,:),1),2).^2;
                %                     W(W == Inf) = layer.Epsilon;   % add layer.Epsilon to compensate for missing classes in the patch
                %
                %                     intersection = sum(sum(Y(:,:,zVal,:,:).*T(:,:,zVal,:,:),1),2);
                %                     union = sum(sum(Y(:,:,zVal,:,:).^2 + T(:,:,zVal,:,:).^2, 1),2);  % union = sum(sum(Y + T, 1),2);
                %
                %                     numer = 2*sum(W.*intersection, 4);
                %                     denom = sum(W.*union, 4);
                %
                %                     N = size(Y, 5);     % for the average dice-loss
            else     % 3D
                W = 1 ./ sum(sum(sum(T,1), 2), 3).^2;
                W(W == Inf) = layer.Epsilon;   % add layer.Epsilon to compensate for missing classes in the patch

                intersection = sum(sum(sum(Y.*T, 1), 2), 3);
                union = sum(sum(sum(Y.^2 + T.^2, 1), 2), 3);  % union = sum(sum(Y + T, 1),2);

                numer = 2*sum(W.*intersection, 4);
                denom = sum(W.*union, 4);

                N = size(Y, 5);     % for the average dice-loss
            end
            
            % Compute Dice score.
            dice = numer./denom;
            
            % Return average Dice loss.
            loss = sum((1-dice))/N;
        end
        
%         function dLdY = backwardLoss(layer, Y, T)
%             % dLdY = backwardLoss(layer, Y, T) returns the derivatives of
%             % the Dice loss with respect to the predictions Y.
% 
% %             % checks
% %             sliceNo = 32;
% %             Y2 = gather(Y);     % prediction
% %             T2 = gather(T);     % labels: T2(:,:,sliceNo, 1==bg); T2(:,:,sliceNo, 2==label); T2(:,:,sliceNo, 3==mask)
% %             layer.Unet2DSwitch == 1:     T2(height, width, label, batchImgId)
% %             layer.Unet2DSwitch == 0:     T2(height, width, depth, label, batchImgId)
% %             figure(1);
% %             imshowpair(Y2(:,:,sliceNo,1,1), T2(:,:,sliceNo,2,1));
% %             if ~isempty(layer.useClasses)
% %                 if layer.Unet2DSwitch
% %                     W = 1 ./ sum(sum(T(:,:,layer.useClasses,:),1),2).^2;
% %                     W(W == Inf) = layer.Epsilon;    % Weights by inverse of region size.
% % 
% %                     intersection = sum(sum(Y(:,:,layer.useClasses,:).*T(:,:,layer.useClasses,:),1),2);
% %                     union = sum(sum(Y(:,:,layer.useClasses,:).^2 + T(:,:,layer.useClasses,:).^2, 1),2);
% % 
% %                     numer = 2*sum(W.*intersection, 3);
% %                     denom = sum(W.*union, 3);
% %                     N = size(Y, 4);  % for the average dice-loss
% %                     dLdY = (2*W.*Y(:,:,layer.useClasses,:).*numer./denom.^2 - 2*W.*T(:,:,layer.useClasses,:)./denom)./N;
% %                 else
% %                     % Weights by inverse of region size.
% %                     W = 1 ./ sum(sum(sum(T(:,:,:,layer.useClasses,:),1),2),3).^2;
% %                     W(W == Inf) = layer.Epsilon;    
% % 
% %                     intersection = sum(sum(sum(Y(:,:,:,layer.useClasses,:).*T(:,:,:,layer.useClasses,:),1),2),3);
% %                     union = sum(sum(sum(Y(:,:,:,layer.useClasses,:).^2 + T(:,:,:,layer.useClasses,:).^2, 1),2),3);
% % 
% %                     numer = 2*sum(W.*intersection, 4);
% %                     denom = sum(W.*union, 4);
% %                     N = size(Y, 5);  % for the average dice-loss
% %                     
% %                     dLdY = (2*W.*Y(:,:,:,layer.useClasses,:).*numer./denom.^2 - 2*W.*T(:,:,:,layer.useClasses,:)./denom)./N;
% %                 end
% %                 
% %                 
% %             else
% 
%                 if layer.dataDimension == 2 %    2D network
%                     W = 1 ./ sum(sum(T,1),2).^2;
%                     W(W == Inf) = layer.Epsilon;    % Weights by inverse of region size.
% 
%                     intersection = sum(sum(Y.*T,1),2);
%                     union = sum(sum(Y.^2 + T.^2, 1),2);
% 
%                     numer = 2*sum(W.*intersection, 3);
%                     denom = sum(W.*union, 3);
%                     N = size(Y, 4);  % for the average dice-loss
% %                 elseif layer.dataDimension == 2.5 %    2D network
% %                     zVal = ceil(size(T,3)/2);
% % 
% %                     % Weights by inverse of region size.
% %                     W = 1 ./ sum(sum(T(:,:,zVal,:,:),1),2).^2;
% %                     W(W == Inf) = layer.Epsilon;    
% % 
% %                     intersection = sum(sum(Y(:,:,zVal,:,:).*T(:,:,zVal,:,:),1),2);
% %                     union = sum(sum(Y(:,:,zVal,:,:).^2 + T(:,:,zVal,:,:).^2, 1),2);
% % 
% %                     numer = 2*sum(W.*intersection, 4);
% %                     denom = sum(W.*union, 4);
% %                     N = size(Y, 5);  % for the average dice-loss
%                 else        % 3D network
%                     % Weights by inverse of region size.
%                     W = 1 ./ sum(sum(sum(T,1),2),3).^2;
%                     W(W == Inf) = layer.Epsilon;    
% 
%                     intersection = sum(sum(sum(Y.*T,1),2),3);
%                     union = sum(sum(sum(Y.^2 + T.^2, 1),2),3);
% 
%                     numer = 2*sum(W.*intersection, 4);
%                     denom = sum(W.*union, 4);
%                     N = size(Y, 5);  % for the average dice-loss
%                 end
% 
%                 dLdY = (2*W.*Y.*numer./denom.^2 - 2*W.*T./denom)./N;
% 
%             % imtool( gather(dLdY(:,:,sliceNo,1,1)),[])
%         end
    end
end
