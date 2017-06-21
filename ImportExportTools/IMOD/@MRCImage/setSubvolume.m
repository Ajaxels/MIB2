% setSubvolume      Set a subvolume of an MRCImage
%
%   mRCImage = setSubolume(mRCImage, vol, center)
%
%   mRCImage    The opened MRCImage object.
%
%   vol         The new subvolume
%
%   vol         The volume to be inserted.
%
%   center      OPTIONAL: The indices at which to center the inserted 
%               subvolume
%               
%   setVolume sets a subvolume of the MRCImage object. The subvolume must
%   lie entirely within the existing volume and be of the same type.
%
%   Bugs: none known
%
% This file is part of PEET (Particle Estimation for Electron Tomography).
% Copyright 2000-2012 The Regents of the University of Colorado & BLD3EMC:
%           The Boulder Laboratory For 3D Electron Microscopy of Cells.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2012/06/26 17:04:12 $
%
%  $Revision: 8ebca3b313c1 $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mRCImage = setSubvolume(mRCImage, vol, center)

% Replace a subvolume (up to the entire volume) of an existing volume.
% Expansion or change of mode is not allowed.
szVol = size(vol);
szMRC = getDimensions(mRCImage);

if nargin < 3
  idxMin = [1 1 1];
  idxMax = szVol;
else
  idxMax = center + ceil(szVol ./ 2) - 1;
  idxMin = center - floor(szVol ./ 2);
end

if any(idxMin < 1)
  fprintf('Minimum index ');
  fprintf('%f', idxMin);
  fprintf('\n');
  PEETError('Minimum index out of range!');
end

if any(idxMax > szMRC)
  fprintf('Maximum index ');
  fprintf('%f', idxMin);
  fprintf('\n');
  PEETError('Maximum index out of range!');
end

% If the volume is already loaded return the selected indices
if mRCImage.flgVolume
  mRCImage.volume(idxMin(1):idxMax(1), ...
    idxMin(2):idxMax(2), idxMin(3):idxMax(3)) = vol;
else
  PEETError(['MRCImage.setVolume is not yet implemented for unloaded ' ...
    'volumes!']);
end

% Update the header to reflect the new min, max, mean and rms voxel values
mRCImage = setStatisticsFromVolume(mRCImage);

