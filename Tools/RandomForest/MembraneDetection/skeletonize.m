%skelImage = skeletonize(image)
function skelImage = skeletonize(image)
  
  skelImage = watershed(bwdist(max(image(:))-image))==0;