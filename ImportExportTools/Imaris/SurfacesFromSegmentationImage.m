function SurfacesFromSegmentationImage(aImarisApplicationID)
% an old surface segmentation function written by Igor Beati from Bitplane

% connect to Imaris Com interface
if ~isa(aImarisApplicationID, 'COM.Imaris_Application')
  vImarisServer = actxserver('ImarisServer.Server');
  vImarisApplication = vImarisServer.GetObject(aImarisApplicationID);
else
  vImarisApplication = aImarisApplicationID;
end

vTestTouching = 1; % set this to 1 to test algorithm for touching objects!
vTouching = vTestTouching;
if ~vTouching
  vImage = GetSegmentationImage;
  vSurfaces = SurfacesFromImage(vImage, vImarisApplication);
else
  vImage = GetSegmentationImageWithTouchingObjects;
  vSurfaces = SurfacesFromImageWithTouchingObjects(vImage, vImarisApplication);
end

vImarisApplication.mSurpassScene.AddChild(vSurfaces);


function aImage = GetSegmentationImage
vSize = [128, 128, 32];
aImage = zeros(vSize, 'uint8');
aImage(10:20, 10:20, 5:10) = 1; % first cell
aImage(30:60, 10:30, 5:15) = 2; % second cell


function aImage = GetSegmentationImageWithTouchingObjects
vSize = [128, 128, 32];
aImage = zeros(vSize, 'uint8');
aImage(10:20, 10:20, 5:10) = 1; % first cell
aImage(20:60, 10:30, 5:15) = 2; % second cell touching the first


function aDataSet = DataSetFromImage(aImage, aImaris)
% generate imaris dataset from matlab image
aDataSet = aImaris.mFactory.CreateDataSet;
vSize = size(aImage);
aDataSet.Create('eTypeUInt8', vSize(1), vSize(2), vSize(3));
aDataSet.SetDataVolume(aImage);


function aSurfaces = SurfacesFromImage(aImage, aImaris)
vSmoothing = 0; % no smoothing, increase this to obtain nicer result (require more time)
vBinaryImage = uint8(aImage > 0); % select all objects
vDataSet = DataSetFromImage(vBinaryImage, aImaris);
aSurfaces = aImaris.mImageProcessing.DetectSurfaces(vDataSet, ...
  [], ... no region of interest (entire image)
  0, vSmoothing, 0, ... first channel, smoothing, no background subtraction
  0, 0.5, ... keep objects with value > 0.5 in image
  ''); % no filtering


function aSurfaces = SurfacesFromImageWithTouchingObjects(aImage, aImaris)
vSmoothing = 0; % no smoothing, increase this to obtain nicer result (require more time)
vNumberOfObjects = max(aImage(:));
aSurfaces = aImaris.mFactory.CreateSurfaces;
vProgress = waitbar(0, 'SurfacesFromSegmentationImage'); 
for vIndex = 1:vNumberOfObjects
  vBinaryImage = uint8(aImage == vIndex); % select this object
  vDataSet = DataSetFromImage(vBinaryImage, aImaris);
  vSurfaces = aImaris.mImageProcessing.DetectSurfaces(vDataSet, ...
    [], 0, vSmoothing, 0, 0, 0.5, ''); % same as for no touching
  for vSurface = 1:vSurfaces.GetNumberOfSurfaces
    % copy this surface to the main container
    vTimeIndex = vSurfaces.GetTimeIndex(vSurface - 1);
    vVertices = vSurfaces.GetVertices(vSurface - 1);
    vTriangles = vSurfaces.GetTriangles(vSurface - 1);
    vNormals = vSurfaces.GetNormals(vSurface - 1);
    if ~isempty(vVertices)
      aSurfaces.AddSurface(vVertices, vTriangles, vNormals, vTimeIndex);
    end
  end
  waitbar(vIndex / vNumberOfObjects, vProgress)
end
close(vProgress)