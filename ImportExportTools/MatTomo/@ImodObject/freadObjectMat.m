% This file is part of PEET (Particle Estimation for Electron Tomography).
% Copyright 2000-2020 The Regents of the University of Colorado.
% See PEETCopyright.txt for more details.

function imodObject = freadObjectMat(imodObject, fid, debug) %#ok<INUSD>
ID = fread(fid,[1 4], '*char');
if strncmp('IMAT', ID, 4) ~= 1
  PEETError('This is not an IMAT section of an ImodObject!');
end
fseek(fid, 4, 'cof'); % skip the length field
imodObject.ambient=fread(fid, 1, 'uchar');
imodObject.diffuse=fread(fid, 1, 'uchar');
imodObject.specular=fread(fid, 1, 'uchar');
imodObject.shininess=fread(fid, 1, 'uchar');
imodObject.fillred=fread(fid, 1, 'uchar');
imodObject.fillgreen=fread(fid, 1, 'uchar');
imodObject.fillblue=fread(fid, 1, 'uchar');
imodObject.quality=fread(fid, 1, 'uchar');
imodObject.mat2=fread(fid, 1, 'int32');
imodObject.valblack=fread(fid, 1, 'uchar');
imodObject.valwhite=fread(fid, 1, 'uchar');
imodObject.matflags2=fread(fid, 1, 'uchar');
imodObject.mat3b3=fread(fid, 1, 'uchar');

