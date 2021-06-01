classdef dicePixelCustomClassificationLayer < nnet.layer.ClassificationLayer
    % This layer implements the generalized Dice loss function for training
    % semantic segmentation networks.
    
    properties(Constant)
        % Small constant to prevent division by zero. 
        Epsilon = 1e-8;
            
    end
    
    properties 
        % use mask as the last material of the model
        Unet2DSwitch    % switch to define 2D U-net
        useClasses = [];  % indices of class ids to be used for calculation of loss
    end
    
    methods
        
        function layer = dicePixelCustomClassificationLayer(name)
            % layer =  dicePixelClassificationLayer(name) creates a Dice
            % pixel classification layer with the specified name.
            %
            % Parameters:
            % name: name of the layer
            
            % Set layer name.          
            layer.Name = name;
            
            if strcmp(name, 'Custom Dice Segmentation Layer 3D')
                layer.Unet2DSwitch = 0;
            else
                layer.Unet2DSwitch = 1;
            end
            
            %layer.useClasses = [3]; % indices of class ids to be used for calculation of loss
            
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
%               layer.Unet2DSwitch == 1:     T2(height, width, label, batchImgId)
%               layer.Unet2DSwitch == 0:     T2(height, width, depth, label, batchImgId)
%             figure(1);
%             imshowpair(Y2(:,:,sliceNo,1,1), T2(:,:,sliceNo,2,1));
            
            if ~isempty(layer.useClasses)
                if layer.Unet2DSwitch
                    % weights are equal to
                    % W(1) = 1/numel(find(T(:,:,1)==1))^2;  % count bg weight
                    % W(2) = 1/numel(find(T(:,:,2)==1))^2;  % count obj weight
                    W = 1 ./ sum(sum(T(:,:,layer.useClasses,:),1),2).^2;    
                    W(W == Inf) = layer.Epsilon;   % add layer.Epsilon to compensate for missing classes in the patch

                    intersection = sum(sum(Y(:,:,layer.useClasses,:).*T(:,:,layer.useClasses,:),1),2);
                    union = sum(sum(Y(:,:,layer.useClasses,:).^2 + T(:,:,layer.useClasses,:).^2, 1),2);  % union = sum(sum(Y + T, 1),2);        

                    numer = 2*sum(W.*intersection, 3);
                    denom = sum(W.*union, 3);

                    N = size(Y, 4);     % for the average dice-loss
                else
                    W = 1 ./ sum(sum(sum(T(:,:,:,layer.useClasses,:),1),2),3).^2;
                    W(W == Inf) = layer.Epsilon;   % add layer.Epsilon to compensate for missing classes in the patch

                    intersection = sum(sum(sum(Y(:,:,:,layer.useClasses,:).*T(:,:,:,layer.useClasses,:),1),2),3);
                    union = sum(sum(sum(Y(:,:,:,layer.useClasses,:).^2 + T(:,:,:,layer.useClasses,:).^2, 1),2),3);  % union = sum(sum(Y + T, 1),2);        

                    numer = 2*sum(W.*intersection, 4);
                    denom = sum(W.*union, 4);

                    N = size(Y, 5);     % for the average dice-loss
                end
            else
                if layer.Unet2DSwitch
                    % weights are equal to
                    % W(1) = 1/numel(find(T(:,:,1)==1))^2;  % count bg weight
                    % W(2) = 1/numel(find(T(:,:,2)==1))^2;  % count obj weight
                    W = 1 ./ sum(sum(T,1),2).^2;    
                    W(W == Inf) = layer.Epsilon;   % add layer.Epsilon to compensate for missing classes in the patch

                    intersection = sum(sum(Y.*T,1),2);
                    union = sum(sum(Y.^2 + T.^2, 1),2);  % union = sum(sum(Y + T, 1),2);        

                    numer = 2*sum(W.*intersection, 3);
                    denom = sum(W.*union, 3);

                    N = size(Y, 4);     % for the average dice-loss
                else
                    W = 1 ./ sum(sum(sum(T,1),2),3).^2;
                    W(W == Inf) = layer.Epsilon;   % add layer.Epsilon to compensate for missing classes in the patch

                    intersection = sum(sum(sum(Y.*T,1),2),3);
                    union = sum(sum(sum(Y.^2 + T.^2, 1),2),3);  % union = sum(sum(Y + T, 1),2);        

                    numer = 2*sum(W.*intersection, 4);
                    denom = sum(W.*union, 4);

                    N = size(Y, 5);     % for the average dice-loss
                end
            end
            
            % Compute Dice score.
            dice = numer./denom;
            
            % Return average Dice loss.
            loss = sum((1-dice))/N;
        end
        
        function dLdY = backwardLoss(layer, Y, T)
            % dLdY = backwardLoss(layer, Y, T) returns the derivatives of
            % the Dice loss with respect to the predictions Y.
            
%             % checks
%             sliceNo = 32;
%             Y2 = gather(Y);     % prediction
%             T2 = gather(T);     % labels: T2(:,:,sliceNo, 1==bg); T2(:,:,sliceNo, 2==label); T2(:,:,sliceNo, 3==mask)
%             layer.Unet2DSwitch == 1:     T2(height, width, label, batchImgId)
%             layer.Unet2DSwitch == 0:     T2(height, width, depth, label, batchImgId)
%             figure(1);
%             imshowpair(Y2(:,:,sliceNo,1,1), T2(:,:,sliceNo,2,1));
%             if ~isempty(layer.useClasses)
%                 if layer.Unet2DSwitch
%                     W = 1 ./ sum(sum(T(:,:,layer.useClasses,:),1),2).^2;
%                     W(W == Inf) = layer.Epsilon;    % Weights by inverse of region size.
% 
%                     intersection = sum(sum(Y(:,:,layer.useClasses,:).*T(:,:,layer.useClasses,:),1),2);
%                     union = sum(sum(Y(:,:,layer.useClasses,:).^2 + T(:,:,layer.useClasses,:).^2, 1),2);
% 
%                     numer = 2*sum(W.*intersection, 3);
%                     denom = sum(W.*union, 3);
%                     N = size(Y, 4);  % for the average dice-loss
%                     dLdY = (2*W.*Y(:,:,layer.useClasses,:).*numer./denom.^2 - 2*W.*T(:,:,layer.useClasses,:)./denom)./N;
%                 else
%                     % Weights by inverse of region size.
%                     W = 1 ./ sum(sum(sum(T(:,:,:,layer.useClasses,:),1),2),3).^2;
%                     W(W == Inf) = layer.Epsilon;    
% 
%                     intersection = sum(sum(sum(Y(:,:,:,layer.useClasses,:).*T(:,:,:,layer.useClasses,:),1),2),3);
%                     union = sum(sum(sum(Y(:,:,:,layer.useClasses,:).^2 + T(:,:,:,layer.useClasses,:).^2, 1),2),3);
% 
%                     numer = 2*sum(W.*intersection, 4);
%                     denom = sum(W.*union, 4);
%                     N = size(Y, 5);  % for the average dice-loss
%                     
%                     dLdY = (2*W.*Y(:,:,:,layer.useClasses,:).*numer./denom.^2 - 2*W.*T(:,:,:,layer.useClasses,:)./denom)./N;
%                 end
%                 
%                 
%             else
                if layer.Unet2DSwitch
                    W = 1 ./ sum(sum(T,1),2).^2;
                    W(W == Inf) = layer.Epsilon;    % Weights by inverse of region size.

                    intersection = sum(sum(Y.*T,1),2);
                    union = sum(sum(Y.^2 + T.^2, 1),2);

                    numer = 2*sum(W.*intersection, 3);
                    denom = sum(W.*union, 3);
                    N = size(Y, 4);  % for the average dice-loss
                else
                    % Weights by inverse of region size.
                    W = 1 ./ sum(sum(sum(T,1),2),3).^2;
                    W(W == Inf) = layer.Epsilon;    

                    intersection = sum(sum(sum(Y.*T,1),2),3);
                    union = sum(sum(sum(Y.^2 + T.^2, 1),2),3);

                    numer = 2*sum(W.*intersection, 4);
                    denom = sum(W.*union, 4);
                    N = size(Y, 5);  % for the average dice-loss
                end
                dLdY = (2*W.*Y.*numer./denom.^2 - 2*W.*T./denom)./N;
            %end
            
            
            % imtool( gather(dLdY(:,:,sliceNo,1,1)),[])
        end
    end
end