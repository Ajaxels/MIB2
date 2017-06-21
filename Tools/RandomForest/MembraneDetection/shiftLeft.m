function imErgTmp = shiftLeft(im)
  imErgTmp = im(:,2:end);
  imErgTmp(:,end+1) = 0;
