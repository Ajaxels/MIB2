
%this you can change
testImageNumber = [1 2 3 4 5];
maxNumberOfSamplesPerClass = 1000;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%save feature matrizes
  cs = 29;
  ms = 3;
  csHist = cs;
  hessianSigma = 4;
  
  imgNames = dir('*_image.tif');
  
  for i=1:length(imgNames)
    name = imgNames(i).name
    %only extract features if not already presaved
    if ~exist(strcat(name(1:6),'_fm.mat'));
      disp('extracting membrane features');
      disp(name);
      im = norm01((imresize(imread(imgNames(i).name),1)));
      fm  = membraneFeatures(im, cs, ms, csHist);
      save(strcat(name(1:6),'_fm.mat'),'fm');
      clear fm
      clear im
    end
    
    if ~exist(strcat(name(1:6),'_train.tif'));
      im = imread(name);
      im(:,:,2) = im;
      im(:,:,3) = im(:,:,1);
      imwrite(im,strcat(name(1:6),'_train.tif'),'tif');
    end
  end
  
imgNames = dir('*_train.tif');
fmPos = [];
fmNeg = [];

disp('for loop');
tic;
for i=1:length(imgNames)
  name = imgNames(i).name;
  im = imread(name);
  posPos = find(im(:,:,2)==255 & im(:,:,1)==0);
  posNeg = find(im(:,:,1)==255 & im(:,:,2)==0);
  
  if length(posPos)>0 | length(posNeg)>0
    load(strcat(name(1:end-10),'_fm.mat'));
    fm = reshape(fm,size(fm,1)*size(fm,2),size(fm,3));
    fm(isnan(fm))=0;
    fmPos = [fmPos; fm(posPos,:)];
    fmNeg = [fmNeg; fm(posNeg,:)];
    clear fm;
  end
end
toc;
clear posPos
clear posNeg

disp('training')
disp('Original number of samples per class: ');
disp('membrane: ');
disp(size(fmPos,1));
disp('not membrane: ');
disp(size(fmNeg,1));

tic;

y = [zeros(size(fmNeg,1),1);ones(size(fmPos,1),1)];
x = double([fmNeg;fmPos]);

extra_options.sampsize = [maxNumberOfSamplesPerClass, maxNumberOfSamplesPerClass];
forest = classRF_train(x, y, 300,5,extra_options); 
%forest = classRF_train(x, y, 500,5);  
toc;

disp('classification')
%now give classification results
imgNames = dir('*_image.tif');

for i=testImageNumber
disp('preparation')
tic;
  name = imgNames(i).name
  im = imread(name);
  load(strcat(name(1:end-10),'_fm.mat'));
  fm = reshape(fm,size(fm,1)*size(fm,2),size(fm,3));
  fm(isnan(fm))=0;
  clear fmNeg
  clear fmPos
  im=uint8Img(im(:,:,1));
  imsize = size(im);
  clear y
  clear im
  
  votes = zeros(imsize(1)*imsize(2),1);
  test = struct();
  toc;
  disp('prediction')
  tic;

% $$$   for j=1:4				% 
% $$$     [y_h,v] = classRF_predict(double(fm(j:4:end,:)), forest);
% $$$     votes(j:4:end,:)=v(:,2);    
% $$$ end
    
  [y_h,v] = classRF_predict(double(fm), forest);
  votes = v(:,2);
  votes = reshape(votes,imsize);
  votes = double(votes)/max(votes(:));
toc;
  disp('visualization')
  tic;
  im = imread(name);			% 
  %this illustration uses the thickened skeleton of the
  %segmentation
  %figure;
%  figure; imshow(makeColorOverlay(uint8Img(bwmorph(bwmorph(bwmorph(votes>0.5,'skel',inf),'spur',10),'dilate',1)),uint8Img(im)));
  figure; imshow(makeColorOverlay(uint8Img(filterSmallRegions(votes>=0.5,1000)),uint8Img(im)));
  pause(1); %to give matlab time to show the figure
%  clear votes
%  clear y_hat
toc;
end


%When the result is fine, save the random forest classifier
%with this command:

% save forest.mat forest

