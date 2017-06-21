function ims = imsmooth(im, sigma)
  H = fspecial('gaussian',3*sigma,sigma);
  ims = imfilter(double(im),H,'replicate');
