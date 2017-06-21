function imErgTmp = shiftDown(im)
  imErgTmp = flipud(im(1:end-1,:));
  imErgTmp(end+1,:) = 0;
  imErgTmp = flipud(imErgTmp);
