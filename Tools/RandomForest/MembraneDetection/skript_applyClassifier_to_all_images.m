%author: Verena Kaynig
%load forest file
load forest.mat

%now give classification results
imgNames = dir('*_image.tif');
for i=1:length(imgNames)
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

  %y_hat has the binary yes/no decision of the classifier
  %votes is the votes of the trees (more like probability map)
  [y_hat,votes] = classRF_predict(double(fm), forest);
  votes = reshape(votes(:,2),imsize);
  votes = double(votes)/max(votes(:));

  im = imread(name);
  %this illustration uses the thickened skeleton of the
  %segmentation
  %imwrite(uint8Img(bwmorph(bwmorph(votes>0.5,'skel',inf),'dilate',1)),strcat(name(1:6),'_seg.tif'),'tif');
  imwrite(uint8Img(votes>0.5),strcat(name(1:6),'_seg.tif'),'tif');
  clear votes
  clear y_hat
end


