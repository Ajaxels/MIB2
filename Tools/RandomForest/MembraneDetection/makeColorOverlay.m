function overlayImg = makeColorOverlay(votes,grayImage)
grayWeight = 100;
    overlayImg = uint8(zeros(size(votes,1),size(votes,2),3));
    skelImg = bwmorph(skeletonize(votes>=0.5),'dilate',1);
    overlayImg(:,:,1) = uint8(norm01(grayImage)*grayWeight+norm01(exp(votes))*(255-grayWeight));
    overlayImg(:,:,2) = uint8(norm01(grayImage)*grayWeight);
    overlayImg(:,:,3) = uint8(norm01(grayImage)*grayWeight);
    
    [x,y] = find(skelImg>0);
    for i=1:length(x)
        overlayImg(x(i),y(i),1) = 0;
        overlayImg(x(i),y(i),2) = 255;
        overlayImg(x(i),y(i),3) = 0;
    end
  end