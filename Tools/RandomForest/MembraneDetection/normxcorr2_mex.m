function result = normxcorr2_mex(im1,im2,param)
  s = size(im1);
  result = normxcorr2(im1,im2);
  result = result(ceil(s(1)/2):end-floor(s(1)/2),ceil(s(2)/2):end-floor(s(2)/2));
