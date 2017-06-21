%author: Verena Kaynig
%save feature matrizes
  cs = 29;
  ms = 3;
  csHist = cs;
  hessianSigma = 4;
  
  imgNames = dir('*_image.tif');
  
  for i=1:length(imgNames)
    name = imgNames(i).name;
    %only extract features if not already presaved
    if ~exist(strcat(name(1:6),'_fm.mat'));
      disp('extracting membrane features');
      disp(name);
      im = norm01(adapthisteq(imresize(imread(imgNames(i).name),1)));
      fm  = membraneFeatures(im, cs, ms, csHist, hessianSigma);
      %fm  = membraneFeatures(im, 29, 3, 29, 4); %was to test if problem
      %was with attributes ... but problem is with im
      save(strcat(name(1:6),'_fm.mat'),'fm');
    end
  end
  


