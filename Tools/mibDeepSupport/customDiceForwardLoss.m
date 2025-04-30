function loss = customDiceForwardLoss(Y, T, dataDimension, useClasses)
% loss = customDiceForwardLoss(Y, T, dataDimension, useClasses) returns the Dice loss between
% the predictions Y and the training targets T.
%
% At the moment it is a test function to be used in
% [net, info] = trainnet(AugTrainDS, net, @customDiceForwardLoss, TrainingOptions);
% in startTraining
%dataDimensions
% Parameters:
% Y: dlarray objects that correspond to the n network predictions (provided by trainnet)
% T: dlarray objects that correspond to the n network targets (provided by trainnet)
% dataDimension: value defining dimension of the data: 2, 2.5, 3
% useClasses: indices of class ids to be used for calculation of loss, when empty, calculate for all classes

% Info:
% https://se.mathworks.com/help/releases/R2024b/deeplearning/ug/semantic-segmentation-using-deep-learning.html

% Small constant to prevent division by zero
layer.Epsilon = 1e-8; 

% checks
%             sliceNo = 32;
%             Y2 = gather(Y);     % prediction, class probabilities
%             Y2 = extractdata(Y2);
%             T2 = gather(T);     % ground truth labels
%             T2 = extractdata(T2);      labels: T2(:,:,sliceNo, 1==bg); T2(:,:,sliceNo, 2==label); T2(:,:,sliceNo, 3==mask)
%             layer.Unet2DSwitch == 1:     T2(height, width, label, batchImgId)
%             layer.Unet2DSwitch == 0:     T2(height, width, depth, label, batchImgId)
%             figure(1);
%             imshowpair(Y2(:,:,sliceNo,1,1), T2(:,:,sliceNo,1,1));
%             imshowpair(Y2(:,:,1,1), T2(:,:,1,1));

% useClasses = 2;   % 1-bg, 2-material1, 3-material2...

if ~isempty(useClasses)
    if dataDimension == 2
        T = T(:,:,useClasses,:);
        Y = Y(:,:,useClasses,:);
    else
        T = T(:,:,:,useClasses,:);
        Y = Y(:,:,:,useClasses,:);
    end
end

% handle NaN values, when the image is rotated, the NaN values are
% generated at the background, at the areas that have <unidentified> tag in
% the categorical labels
mask = ~isnan(T);          % logical mask: true where T is not NaN
T(isnan(T)) = 0;           % replace NaNs with 0 to avoid NaN propagation

if dataDimension == 2 %    2D network
    % weights are equal to
    % W(1) = 1/numel(find(T(:,:,1)==1))^2;  % count bg weight
    % W(2) = 1/numel(find(T(:,:,2)==1))^2;  % count obj weight
    W = 1 ./ sum(sum(T .* mask, 1), 2).^2;
    W(W == Inf) = layer.Epsilon;   % add layer.Epsilon to compensate for missing classes in the patch

    intersection = sum(sum((Y .* T) .* mask, 1), 2);
    union = sum(sum((Y.^2 + T.^2) .* mask, 1), 2);

    numer = 2 * sum(W .* intersection, 3);
    denom = sum(W .* union, 3);

    N = size(Y, 4);     % for the average dice-loss
else     % 3D
    W = 1 ./ sum(sum(sum(T .* mask, 1), 2), 3).^2;
    W(W == Inf) = layer.Epsilon;   % add layer.Epsilon to compensate for missing classes in the patch

    intersection = sum(sum(sum((Y .* T) .* mask, 1), 2), 3);
    union = sum(sum(sum((Y.^2 + T.^2) .* mask, 1), 2), 3);

    numer = 2 * sum(W .* intersection, 4);
    denom = sum(W .* union, 4);

    N = size(Y, 5);     % for the average dice-loss
end

% Compute Dice score.
dice = numer ./ (denom + layer.Epsilon);

% Return average Dice loss.
loss = sum(1 - dice) / N;
end