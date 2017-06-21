mImarisLibPath = 'c:\Program Files\Bitplane\Imaris x64 8.0.2\XT\matlab\ImarisLib.jar';
if all(cellfun(@isempty, strfind(javaclasspath, 'ImarisLib.jar')))
    javaaddpath(mImarisLibPath);
end
mImarisLib = ImarisLib();
vImarisApp = mImarisLib.GetApplication(0);

% Works fine
img = zeros([512, 512, 512], 'uint8');

% % uncomment the code below to test a bigger data block
%img = zeros([1024, 1024, 1024], 'uint8');

sizeX = size(img,2);
sizeY = size(img,1);
sizeZ = size(img,3);


% Create the dataset
iDataset = vImarisApp.GetFactory().CreateDataSet();
iDataset.Create(Imaris.tType.eTypeUInt8, sizeX, sizeY, sizeZ, 1, 1);

voxelSizeX = 1;
voxelSizeY = 1;
voxelSizeZ = 1;

% Apply the spatial calibration
iDataset.SetExtendMinX(0);
iDataset.SetExtendMinY(0);
iDataset.SetExtendMinZ(0);
iDataset.SetExtendMaxX(sizeX * voxelSizeX);
iDataset.SetExtendMaxY(sizeY * voxelSizeY);
iDataset.SetExtendMaxZ(sizeZ * voxelSizeZ);

vImarisApp.SetDataSet(iDataset);
img = permute(img, [2 1 3]);

% best, fast 1.1 sec with 512x512x512
% but does not work for 1k x 1k x 1k datasets
iDataset.SetDataVolumeAs1DArrayBytes(img(:), 0, 0);

% % imaris refreshes after each slice -> too slow
%for z=1:size(img,3)
%   iDataset.SetDataSliceBytes(img(:,:,z),z-1,0,0);
%end

% too slow, ~47sec with 512x512x512
% iDataset.SetDataVolumeBytes(img, 0, 0);

% suggested solution, but I am not happy with it...
blockSizeX = 128;
blockSizeY = 512;
blockSizeZ = 512;
callsId = 0;
for z=0:ceil(sizeZ/blockSizeZ)-1
    for y=0:ceil(sizeY/blockSizeY)-1
        for x=0:ceil(sizeX/blockSizeX)-1
            imgBlock = img(...
                1+blockSizeX*x:min(blockSizeX+blockSizeX*x, sizeX) ,...
                1+blockSizeY*y:min(blockSizeY+blockSizeY*y, sizeY) ,...
                1+blockSizeZ*z:min(blockSizeZ+blockSizeZ*z, sizeZ));
            
            iDataset.SetDataSubVolumeAs1DArrayBytes(imgBlock(:),...
                blockSizeX*x, blockSizeY*y, blockSizeZ*z, 0, 0,...
                size(imgBlock,1), size(imgBlock,2), size(imgBlock,3));
            callsId = callsId + 1;
        end
    end
end


