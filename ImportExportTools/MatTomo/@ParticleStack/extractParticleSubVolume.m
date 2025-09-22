% extractParticleSubVolume  Extract a sub-volume from particle in a
%   ParticleStack. The subvolume at the closest whole voxel coordinate will
%   be returned, in additon to the fractional shift (in voxels) from the 
%   actual to the requested position.
%
%   [subVolume shift] = extractParticleSubVolume(particleStack,        ...
%     particleNum, center, volSize,test, meanFill, permissive)
%
%   particleNum The index of the desired particle in the stack
%
%   particleStack    The MRCImage containing the volume
%
%   center      The array index of the center voxel, this can be non-integer
%               and the nearest voxels will be extracted.
%
%   volSize     The size of the sub volume to extract [nX nY nZ]
%
%   test        OPTIONAL: If true then only test to see if the
%               subvolume to be extracted is fully or partially in the in 
%               the volume. subVolume and shift will be overloaded as
%               fullyInVolume and partiallyInVolume, respectively, and
%               warning and error messages will be suppressed.
%
%   meanFill    OPTIONAL: If true allow for sub volumes outside the
%               boundaries of the MRCImage data.  Outside data will be
%               filled with the mean of the present data (default: 0).
%
%   permissive  OPTIONAL: If true, allow fully out of volume subvolumes
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
function [subVolume, shift] = extractParticleSubVolume(particleStack,  ...
  particleNum, center, volSize, test, meanFill, permissive)

if nargin < 5
  test = 0;
end

if nargin < 6
  meanFill = 0;
end

if nargin < 7
  permissive = 0;
end

szParticle = getParticleSize(particleStack);

% Calculate the index range to extract; need to use floor(x + 0.5) because
% round([-0.5 0.5]) = [-1 1]. Also use volSize with same shape as center.
if any(size(volSize)  ~= size(center))
  volSizeT = volSize.';
else
  volSizeT = volSize;
end
hi = floor(center + 0.5 * volSizeT);
lo = hi - volSizeT + 1;
shift = center - 0.5 * (lo + hi);   % Shift from actual to requested center
if abs(shift) > 0.5
  inc = sign(shift);
  lo = lo + inc;
  hi = hi + inc;
  shift = shift + inc;
end
rngX = [lo(1), hi(1)];
rngY = [lo(2), hi(2)];
rngZ = [lo(3), hi(3)];

% Check the indices for any out of range
[fullyInRange, partiallyInRange] =                                     ...
  checkIndexRange('X', szParticle(1), rngX, test, meanFill, permissive);
  [full, part] =                                                       ...
    checkIndexRange('Y', szParticle(2), rngY, test, meanFill, permissive);
  fullyInRange = fullyInRange && full;
  partiallyInRange = partiallyInRange && part;
  [full, part] =                                                       ...
    checkIndexRange('Z', szParticle(3), rngZ, test, meanFill, permissive);
  fullyInRange = fullyInRange && full;
  partiallyInRange = partiallyInRange && part;

if test
  % Overload return values when testing 
  subVolume = fullyInRange;
  shift = partiallyInRange;
  return
end

if partiallyInRange
  particle = getParticle(particleStack, particleNum);
else
  particle = [];
end

% Set index ranges to extract if meanFill and partially out of volume
if meanFill && ~fullyInRange
  [idxSubVolX, extractRngX] = mapPresentIndices(szParticle(1), rngX);
  [idxSubVolY, extractRngY] = mapPresentIndices(szParticle(2), rngY);
  [idxSubVolZ, extractRngZ] = mapPresentIndices(szParticle(3), rngZ);
  if partiallyInRange
    extractVolume = particle(extractRngX(1):extractRngX(2),            ...
                             extractRngY(1):extractRngY(2),            ...
                             extractRngZ(1):extractRngZ(2));
  else
    extractVolume = [];
  end
  svMean = mean(double(extractVolume(:)));
  if ~isfinite(svMean)
    svMean = 128;
    PEETWarning(['Replacing an undefined mean value with 128!\n'       ...
      '         This is typically caused by out-of-range subvolume '   ...
      'indices.\n']);
  end
  dataType = getModeString(particleStack);
  % When filling the images, make sure we fill with the correct type
  switch dataType
    case 'uint8'
      subVolume = uint8(ones(volSize) * svMean);
    case 'int16'
      subVolume = int16(ones(volSize) * svMean);
    case 'int16*2'
      subVolume = int16(ones(volSize) * svMean);
    case 'float32'
      subVolume = single(ones(volSize) * svMean);
    case 'float32*2'
      subVolume = single(ones(volSize) * svMean);
  end
  if partiallyInRange
    subVolume(idxSubVolX, idxSubVolY,idxSubVolZ) = extractVolume;
  end
else    
  subVolume = particle(rngX(1):rngX(2), rngY(1):rngY(2), rngZ(1):rngZ(2));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check the indices to see if they are in range
function [fullyInRange, partiallyInRange] = checkIndexRange(           ...
  axisLabel, axisMax, indices, test, meanFill, permissive)

minIdx = min(indices);
maxIdx = max(indices);

partiallyInRange = ~((minIdx < 1 && maxIdx < 1) ||                     ...
                     (minIdx > axisMax && maxIdx > axisMax));
% Exit with an error completely out of range unless testing or permissive
if ~(test || partiallyInRange)
  if permissive && ~test
    PEETWarning(['Subvolume %s indices (%d..%d) are completely outside '...
      'the volume!'], axisLabel, indices(1), indices(2));
  else
    PEETError(['Subvolume %s indices (%d..%d) are completely outside ' ...
      'the volume!'], axisLabel, indices(1), indices(2));
  end
end

fullyInRange = (minIdx >= 1 && maxIdx <= axisMax);
if ~(test || fullyInRange)
  % Minimum index too small?
  if minIdx < 1
    msg = sprintf('%s axis minimum index out of range by %d voxels!',  ...
      axisLabel, 1 - minIdx);
    if meanFill && ~test
      PEETWarning(msg);
    else
      PEETError(msg);
    end
  end
  
  % Maximum index too large?
  if maxIdx > axisMax
    msg = sprintf('%s axis maximum index out of range by %d voxels!',  ...
      axisLabel, maxIdx - axisMax);
    if meanFill && ~test
      PEETWarning(msg);
    else
      PEETError(msg);
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [idxSubVol, idxExtract] = mapPresentIndices(szDim, selectRange)
% On return, idxExtract will contain the range of indices in the input
% volume (or nothing if completely out of range); idxSubVol will be a range
% of indices indicating the corresponding output indices.

% Check if the selected range lies completely out of bounds
% [This is redundant, since we've already checked for it]
if (selectRange(1) < 1 && selectRange(2) < 1) ||                       ... 
   (selectRange(1) > szDim && selectRange(2) > szDim)
  idxSubVol = [];
  idxExtract = [];
  return
end

% Assume everything is in range
idxExtract = selectRange;
start = 1;
stop = selectRange(2) - selectRange(1) + 1;

% Lower index out of range?
if selectRange(1) < 1
  idxExtract(1) = 1;
  start = 2 - selectRange(1);
end

% Upper index out of range
if selectRange(2) > szDim
  idxExtract(2) = szDim;
  stop = idxExtract(2) - idxExtract(1) + start;
end

idxSubVol = start:stop;
