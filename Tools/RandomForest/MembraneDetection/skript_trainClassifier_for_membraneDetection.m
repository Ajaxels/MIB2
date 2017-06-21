%author: Verena Kaynig
%this you can change
testImageNumber = [1 2];
maxNumberOfSamplesPerClass = 500;

t1=tic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%save feature matrizes
cs = 29;      % context size
ms = 3;       % membrane thickness
csHist = cs;  % context Size Histogram
hessianSigma = 4;

% get images
imgNames = dir('*_image.tif');

for i=1:length(imgNames)
    name = imgNames(i).name
    %only extract features if not already presaved
    if ~exist(strcat(name(1:6),'_fm.mat'), 'file');
        disp('extracting membrane features');
        disp(name);
        %im = norm01((imresize(imread(imgNames(i).name),1)));
        im = norm01((imread(imgNames(i).name)));    % normalize image, i.e. stretch from 0 to 1 and convert to double
        
        % generate membrane features:
        % fm(:,:,1) -> orig image
        % fm(:,:,2:5) -> 1-90 degrees
        % fm(:,:,6) -> minimal values of all degrees
        % fm(:,:,7) -> maximal values of all degrees
        % fm(:,:,8) -> mean values of all degrees
        % fm(:,:,9) -> variance values of all degrees
        % fm(:,:,10) -> median values of all degrees
        % fm(:,:,11:14) -> 90-180 degrees
        % fm(:,:,17:26) -> 10-bin histogram of a context area at each point of the image
        % fm(:,:,27) -> mean value of a context area at each point of the image
        % fm(:,:,28) -> variance (?) value of a context area at each point of the image
        % fm(:,:,29) -> maximal - minimal values for all degrees
        % the following are repeats of
        % fm(:,:,30) -> smoothed original image, sigma = 1
        % fm(:,:,31) -> smoothed eig1/eig2, sigma = 1
        % fm(:,:,32) -> smoothed magnitude, sigma = 1
        % fm(:,:,33) -> magnitude, sigma = 1
        % fm(:,:,34-37) -> repeat 30-33, with sigma=2
        % fm(:,:,38-41) -> repeat 30-33, with sigma=3
        % fm(:,:,42) -> 38 -minus- smoothed original image with sigma=1
        % fm(:,:,43-46) -> repeat 30-33, with sigma=4
        % fm(:,:,47) -> 43 -minus- smoothed original image with sigma=1
        % ...
        % fm(:,:,89) -> end of that cycle
        % fm(:,:,90) -> variance of last 10 entries in the fm
        % fm(:,:,91) -> normalized smoothed orig.image sigma=2 - smoothed orig.image sigma=50
        % fm(:,:,92) -> original image
        
        fm  = membraneFeatures(im, cs, ms, csHist);
        save(strcat(name(1:6),'_fm.mat'),'fm');
        clear fm
        clear im
    end
    
    if ~exist(strcat(name(1:6),'_train.tif'), 'file');  % if train file is missing generate a dummy RGB file from the original
        im = imread(name);
        im(:,:,2) = im;     % second channel
        im(:,:,3) = im(:,:,1);
        imwrite(im,strcat(name(1:6),'_train.tif'),'tif');
    end
end

imgNames = dir('*_train.tif');
fmPos = [];
fmNeg = [];

disp('for loop');
for i=1:length(imgNames)
    name = imgNames(i).name;
    im = imread(name);
    posPos = find(im(:,:,2)==255 & im(:,:,1)==0);   % find indices of points with the signal
    posNeg = find(im(:,:,1)==255 & im(:,:,2)==0);   % find indices of points with the background
    
    if ~isempty(posPos) || ~isempty(posNeg)
        load(strcat(name(1:end-10),'_fm.mat'));     % load matrix with features
        fm = reshape(fm,size(fm,1)*size(fm,2),size(fm,3));  % convert x,y -> to vector
        fm(isnan(fm))=0;
        fmPos = [fmPos; fm(posPos,:)];  % get features for positive points, combine with another training slice
        fmNeg = [fmNeg; fm(posNeg,:)];  % get features for negative points
        clear fm;
    end
end
clear posPos
clear posNeg

disp('training')
disp('Original number of samples per class: ');
disp('membrane: ');
disp(size(fmPos,1));
disp('not membrane: ');
disp(size(fmNeg,1));

y = [zeros(size(fmNeg,1),1);ones(size(fmPos,1),1)];     % generate a vector that defines positive and negative values
x = double([fmNeg;fmPos]);  % generate a matrix with combined membrane features

extra_options.sampsize = [maxNumberOfSamplesPerClass, maxNumberOfSamplesPerClass];
forest = classRF_train(x, y, 300, 5, extra_options);    % train classifier
%forest = classRF_train(x, y, 500,5);

disp('classification')

%now give classification results
imgNames = dir('*_image.tif');

for i=testImageNumber
    disp('preparation')
    name = imgNames(i).name
    im = imread(name);
    load(strcat(name(1:end-10),'_fm.mat'));
    fm = reshape(fm,size(fm,1)*size(fm,2),size(fm,3));
    fm(isnan(fm))=0;
    clear fmNeg
    clear fmPos
    im=uint8Img(im(:,:,1));     % convert to uint8 and scale from 0 to 255
    imsize = size(im);
    clear y
    clear im
    
    votes = zeros(imsize(1)*imsize(2),1);
    test = struct();
    disp('prediction')
    
    % $$$   for j=1:4				%
    % $$$     [y_h,v] = classRF_predict(double(fm(j:4:end,:)), forest);
    % $$$     votes(j:4:end,:)=v(:,2);
    % $$$ end
    
    [y_h,v] = classRF_predict(double(fm), forest);
    votes = v(:,2);
    votes = reshape(votes,imsize);
    votes = double(votes)/max(votes(:));
    disp('visualization')
    im = imread(name);			%
    %this illustration uses the thickened skeleton of the
    %segmentation
    %figure;
    %this is the skeletonized view
    figure; imshow(makeColorOverlay(votes,im));
    imwrite(makeColorOverlay(votes,im),strcat(name(1:6),'_overlay.tif'),'tif');
    %this is the thick membrane view
    %  figure; imshow(makeColorOverlay(uint8Img(filterSmallRegions(votes>=0.5,1000)),uint8Img(im)));
    pause(1); % to give matlab time to show the figure
    %  clear votes
    %  clear y_hat
end


%When the result is fine, save the random forest classifier
%with this command:

%save forest.mat forest

toc(t1)