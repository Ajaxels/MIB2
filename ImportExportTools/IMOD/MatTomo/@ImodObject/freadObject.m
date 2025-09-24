%freadObject  ImodObject file reader
%
%   imodObject = freadObject(imodObject, fid, debug)
%
%   imodObject  The ImodObject
%
%   fid         A file ID of an open file with the pointer at the start of an
%               IMOD Object object.
%
%   Bugs: none known
%
% This file is part of PEET (Particle Estimation for Electron Tomography).
% Copyright 2000-2020 The Regents of the University of Colorado.
% See PEETCopyright.txt for more details.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  $Author: John Heumann $
%
%  $Date: 2020/01/02 23:33:44 $
%
%  $Revision: ce44cef00aca $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function imodObject = freadObject(imodObject, fid, debug)

%  Check to make sure we have a Imod Object
ID = char(fread(fid, [1 4], 'uchar')); %#ok<*FREAD>

if strncmp('OBJT', ID, 4) ~= 1
  PEETError('This is not an IMOD Object!');
end

imodObject.name = char(fread(fid, [1 64], 'uchar'));
junk = char(fread(fid, [1 64], 'uchar')); %#ok<NASGU>
imodObject.nContours = fread(fid, 1, 'int32');
imodObject.flags = fread(fid, 1, 'uint32'); %
imodObject.axis = fread(fid, 1, 'int32');  %
imodObject.drawMode = fread(fid, 1, 'int32'); %
imodObject.red = fread(fid, 1, 'float32');
imodObject.green = fread(fid, 1, 'float32');
imodObject.blue = fread(fid, 1, 'float32');
imodObject.pdrawsize = fread(fid, 1, 'int32'); %

imodObject.symbol = fread(fid, 1, 'uchar'); %
imodObject.symbolSize = fread(fid, 1, 'uchar'); %
imodObject.lineWidth2D = fread(fid, 1, 'uchar');
imodObject.lineWidth3D = fread(fid, 1, 'uchar');
imodObject.lineStyle = fread(fid, 1, 'uchar');
imodObject.symbolFlags = fread(fid, 1, 'uchar'); %
imodObject.sympad = fread(fid, 1, 'uchar'); %
imodObject.transparency = fread(fid, 1, 'uchar');%

imodObject.nMeshes = fread(fid, 1, 'int32');
imodObject.nSurfaces = fread(fid, 1, 'int32');

if debug
  fprintf('  Name: %s\n', imodObject.name);
  fprintf('  Contours: %d\n', imodObject.nContours);
  fprintf('  Meshes: %d\n', imodObject.nMeshes);
  fprintf('  Flags: 0x%08X\n', imodObject.flags);
end

%  Read in each of the specified objects
iContour = 1;
iMesh = 1;
%iSurface = 1;
%iChunk = 1;

while iContour <= imodObject.nContours || iMesh <= imodObject.nMeshes 
     % iSurface <= imodObject.nSurfaces %surface is different

  %  Read the ID string for the structure and rewind the file pointer
  id = char(fread(fid, [1 4], 'uchar'));
  fseek(fid, -4, 'cof');

  if debug
    fprintf('  TAG: %s\n', id);
  end 

  switch id
   
   case {'CONT'}
    imodContour = ImodContour;
    imodContour = freadContour(imodContour, fid, debug);
    % A contour can optionally be followed by a point SIZE structure
    id = char(fread(fid, [1 4], 'uchar'));
    if strcmp(id, 'SIZE');
      nPoints = fread(fid, 1, 'int32') / 4;
      if (nPoints ~= getNPoints(imodContour));
        PEETError('SIZE record contains incorrect number of points!');
      end
      pointSizes = fread(fid, nPoints,'float32');
      imodContour = setPointSizes(imodContour, pointSizes);
    else
      fseek(fid, -4, 'cof');
    end    
    imodObject.contour{iContour} = imodContour;
    iContour = iContour + 1;
    
   case{'MESH'}
    imodMesh = ImodMesh;
    imodMesh = freadMesh(imodMesh, fid, debug);
    imodObject.mesh{iMesh} = imodMesh;
    iMesh = iMesh + 1;
   
   % FIXME check logic to see if this works with multple objects.  If there
   % are multiple objects how do we know where this one ends, probably
   % reading an IOBJ tag
   case{'IEOF'}
    return
    
   otherwise
    imodChunk = ImodChunk;
    imodChunk = freadChunk(imodChunk, fid); %#ok<NASGU>
    % No longer storing unrecognized chunks
    clear imodChunk
    %imodObject.chunk{iChunk} = imodChunk;
    %iChunk = iChunk + 1;
  end

end
