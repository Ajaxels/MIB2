function imNorm = norm01(im)
  im = double(im);
  im = im(:,:,1);
  im = im - min(im(:));
  
  m = max(im(:));
  if m ~= 0
    imNorm = im / m;
  else
    imNorm = im;
  end