function im8 = uint8Img(im)
  im = double(im(:,:,1));
  im = im - min(min(im));
  im = im / max(max(im)) * 255;
  im8 = uint8(im);