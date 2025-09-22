% deleteEmptyContours   Remove any empty contours, renumbering as needed
%
%   imodObject = deleteEmptyContours(imodObject)
%
%   Bugs: none known
%
% This file is part of PEET (Particle Estimation for Electron Tomography).
% Copyright 2000-2025 The Regents of the University of Colorado.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2025/01/02 17:09:20 $
%
%  $Revision: 03a2974f77e3 $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function imodObject = deleteEmptyContours(imodObject)

  % First simply delete any trailing empty contours
  for iContour = imodObject.nContours:-1:1
    if getNPoints(getContour(imodObject, iContour)) == 0
      imodObject.contour = imodObject.contour(1:(iContour - 1));
      imodObject.nContours = length(imodObject.contour);
    else
      break;   % Stop at the 1st non-empty contour
    end
  end
  
  % Next check for internal empty contours, shifting contents down
  for iContour = (imodObject.nContours - 1):-1:1
    if getNPoints(getContour(imodObject, iContour)) == 0
      imodObject.contour{iContour} = imodObject.contour{iContour + 1};
      imodObject.contour = imodObject.contour(1:iContour);
      imodObject.nContours = length(imodObject.contour);
    end
  end
  
end
