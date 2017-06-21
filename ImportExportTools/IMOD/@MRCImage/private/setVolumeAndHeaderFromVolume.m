% setVolumeAndHeaderFromVolume
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
%
% 22.09.2014, Ilya Belevich ilya.belevich @ helsinki.fi Added uint16 class,

function mRCImage = setVolumeAndHeaderFromVolume(mRCImage, volume)

if isa(volume, 'uint8')
  mRCImage.header.mode = 0;
  mRCImage.volume = volume;
end
if isa(volume, 'uint16')
    mRCImage.header.mode = 6;
    mRCImage.volume = volume;
end

if isa(volume, 'int16')
  if isreal(volume)
    mRCImage.header.mode = 1;
  else
    mRCImage.header.mode = 3;
  end
  mRCImage.volume = volume;
end

if isa(volume, 'single')
  if isreal(volume)
    mRCImage.header.mode = 2;
  else
    mRCImage.header.mode = 4;
  end
  mRCImage.volume = volume;
end
if isa(volume, 'double')
  if ~isreal(volume)
    PEETError('Double precision complex images are not supported!');
  end
  mRCImage.header.mode = 2;
  mRCImage.volume = single(volume);
end
  
%  TODO: is this the correct/best way to set the values
mRCImage.header.nX = size(volume, 1);
mRCImage.header.nY = size(volume, 2);
mRCImage.header.nZ = size(volume, 3);
mRCImage.header.nXStart = 0;
mRCImage.header.nYStart = 0;
mRCImage.header.nZStart = 0;
mRCImage.header.mX = size(volume, 1);
mRCImage.header.mY = size(volume, 2);
mRCImage.header.mZ = size(volume, 3);
mRCImage.header.cellDimensionX = size(volume, 1);
mRCImage.header.cellDimensionY = size(volume, 2);
mRCImage.header.cellDimensionZ = size(volume, 3);
mRCImage.header.cellAngleX = 0;
mRCImage.header.cellAngleY = 0;
mRCImage.header.cellAngleZ = 0;

mRCImage = setStatisticsFromVolume(mRCImage);

mRCImage.type = 'BL3DFS';
mRCImage.header.spaceGroup = 0;
mRCImage.header.nSymmetryBytes = 0;

mRCImage.header.imodStamp = defaultIMODStamp();
writeBytesAsSigned = getWriteBytesAsSigned(mRCImage);
mRCImage.header.imodFlags = writeBytesAsSigned;

mRCImage.header.creatorID = int16(0);
mRCImage.header.nBytesPerSection = int16(0);
mRCImage.header.serialEMType = int16(0);
mRCImage.header.idtype = 0;
mRCImage.header.lens = 0;
mRCImage.header.ndl = 0;
mRCImage.header.nd2 = 0;
mRCImage.header.vdl = 0;
mRCImage.header.vd2 = 0;
mRCImage.header.tiltAngles = single([0 0 0 0 0 0]);

mRCImage.header.extra = zeros(100, 1);
mRCImage.header.xOrigin = 0;
mRCImage.header.yOrigin = 0;
mRCImage.header.zOrigin = 0;
mRCImage.header.map = 'MAP ';
mRCImage.header.machineStamp = uint8([68 65 0 0]); % assume little endian
%mRCImage.header.machineStamp = uchar([17 17 0 0]); % assume big endian
  
mRCImage.flgVolume = 1;
mRCImage.header.nBytesExtended = 0;
mRCImage.header.nLabels = 0;
