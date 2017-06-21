function imErgTmp = shiftUp(im)
  imErgTmp = im(2:end,:);
  imErgTmp(end+1,:) = 0;
