function PixelIdxList = convertPixelIdxListCrop2Full(obj, PixelIdxListCrop, options)
% function PixelIdxList = convertPixelIdxListCrop2Full(obj, PixelIdxListCrop, options)
% convert PixelIdxList of the cropped dataset to PixelIdxList of the full
% dataset, only for 4D datasets (h, w, depth, time)
%
% Parameters:
% PixelIdxListCrop: vector of indices of the cropped dataset
% options: a structure with parameters
% @li .y -> [ymin, ymax] y-dimensions of the cropped dataset
% @li .x -> [xmin, xmax] x-dimensions of the cropped dataset
% @li .z -> [@em optional], [zmin, zmax] z-dimensions of the cropped dataset

%| 
% @b Examples:
% @code 
% [yMin, yMax, xMin, xMax, zMin, zMax] = obj.mibModel.I{obj.mibModel.Id}.getCoordinatesOfShownImage(4); 
% convertPixelOpt.y = [yMin yMax]; // y-dimensions of the cropped dataset
% convertPixelOpt.x = [xMin xMax]; // x-dimensions of the cropped dataset
% convertPixelOpt.z = [zMin, zMax]; // z-dimensions of the cropped dataset
% PixelIdxListFull = obj.mibModel.I{obj.mibModel.Id}.convertPixelIdxListCrop2Full(PixelIdxListFullCrop, convertPixelOpt);
% @endcode


if nargin < 3; error('missing parameters'); end

if ~isfield(options, 'z') 
    if obj.orientation ~= 4; error('Wrong orientation, please transpose dataset to the XY orientation');end
    z1 = obj.getCurrentSliceNumber();
else
    z1 = options.z(1);
end
x1 = options.x(1);
dx = options.x(2)-options.x(1)+1;
y1 = options.y(1);
dy = options.y(2)-options.y(1)+1;

% calculate the time shift
% dt = obj.width*obj.height*obj.depth*options.t-1;

PixelIdxList = obj.height * obj.width * ...
    (z1 + ceil(PixelIdxListCrop/(dx*dy))-2) + ...
     obj.height * (x1 + ceil((mod(PixelIdxListCrop-1, dy*dx)+1)/dy)-2) + ...
     y1 + mod(PixelIdxListCrop-1, dy);

end 
 
 
%% ------ test code -----
% % % below is the testing code
% % full 3D block 5x5x5 (h, w, d)
% % crop 3D block 2x3x2 -> starting at x1=2; y1=3; z1=3;
% % crop coordinates = 1:12
% % full dataset coordinates =  [58    59    63    64    68    69    83    84 88    89    93    94]
% 
% % full image size
% h = 5;
% w = 5;
% d = 5;
% 
% % crop area
% w1 = 2;
% h1 = 3;
% d1 = 3;
% dx = 3;
% dy = 2;
% dz = 2;
% 
% maxIndex = 12;
% vec = 1:maxIndex;
% 
% % 2d case
% IndFull = h * (w1 + ceil(vec/dy)-2) + h1 + mod(vec-1, dy);
% 
% % 3d case
% IndFull = h*w *(d1 + ceil(vec/(dy*dx))-2) + h * (w1 + ceil((mod(vec-1, dy*dx)+1)/dy)-2) + h1 + mod(vec-1, dy);
% 
% % test in a for loop
% IndFull = zeros([1, maxIndex]);
% for i=1:maxIndex
%     % 2d case
%     %shift1 = h * (w1 + ceil(i/dy)-2) + h1;
%     %IndFull(i) = shift1 + mod(i-1, dy); 
% 
%     % 3d case
%     shift3d = h*w *(d1 + ceil(i/(dy*dx))-2);
%     shift2d = h * (w1 + ceil((mod(i-1, dy*dx)+1)/dy)-2) + h1;
%     IndFull(i) = shift3d + shift2d + mod(i-1, dy);
% end


