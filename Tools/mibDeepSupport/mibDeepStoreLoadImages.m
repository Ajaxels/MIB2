% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 25.04.2023
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function imOut = mibDeepStoreLoadImages(fn, getDataOptions)
% function imOut = mibDeepStoreLoadImages(fn, getDataOptions)
% supporting function for mibDeepController
% load image function for the imagedatastore
%
% Parameters:
% fn: [string] with the full filename
% getDataOptions: additional structure with options
% .mibBioformatsCheck - [logical] switch indicating use (true) or not use
% (false) of the BioFormats file reader
% .BioFormatsIndices - [numerical] index of series to be used with the
% BioFormats reader or index within TIF file for standard reader
% .Workflow - [string] used workflow, taken from obj.BatchOpt.Workflow{1}
% .randomCrop - []

if nargin < 2
    getDataOptions = struct();
end
if ~isfield(getDataOptions, 'mibBioformatsCheck'); getDataOptions.mibBioformatsCheck = false; end
if ~isfield(getDataOptions, 'BioFormatsIndices'); getDataOptions.BioFormatsIndices = 1; end
if ~isfield(getDataOptions, 'randomCrop'); getDataOptions.randomCrop = [0 0]; end
if ~isfield(getDataOptions, 'Workflow'); getDataOptions.Workflow = '2D Semantic'; end

[~, ~, fnExt] = fileparts(fn);

if getDataOptions.mibBioformatsCheck % use BioFormats reader
    getDataOptions.verbose = false;
    imOut = mibLoadImages(fn, getDataOptions);
    % permute from [height, width, color, depth] -> [height, width, depth, color]
    if ndims(imOut) == 4
        imOut = permute(imOut, [1 2 4 3]);
    end
elseif ismember(fnExt, {'.mibImg', '.mask', '.mibCat'})
    % load MATLAB MAT-based formats
    inp = load(fn, '-mat');
    if isfield(inp, 'imgVariable')
        imOut = inp.(inp.imgVariable);
    else
        f = fields(inp);
        imOut = inp.(f{1});
    end
else    % use standard reader
    if getDataOptions.Workflow(1) == '2'   % 2D networks
        switch fnExt
            case '.am'
                getDataOptions.getMeta = false;     % do not process meta data in amiramesh files
                getDataOptions.verbose = false;     % do not display info about loaded image
                imOut = amiraMesh2bitmap(fn, getDataOptions);
            case '.png'
                imOut = imread(fn, fnExt(2:end));
            case {'.tif', '.tiff'}
                getDataOptions.verbose = false;
                imOut = mibLoadImages(fn, getDataOptions);
            otherwise
                getDataOptions.verbose = false;
                imOut = mibLoadImages(fn, getDataOptions);
        end
    else    % 3D networks
        getDataOptions.verbose = false;
        imOut = mibLoadImages(fn, getDataOptions);
    end
    % permute from [height, width, color, depth] -> [height, width, depth, color]
    if ndims(imOut) == 4
        imOut = permute(imOut, [1 2 4 3]); 
    end
end

% do a random crop of the patch if needed
if getDataOptions.randomCrop(1) ~= 0
    % Generate random coordinates for the top-left corner of the crop
    dY = randi(size(imOut, 1) - getDataOptions.randomCrop(1) + 1);
    dX = randi(size(imOut, 2) - getDataOptions.randomCrop(2) + 1);

    % Perform the random crop
    imOut = imOut(dY:dY+getDataOptions.randomCrop(1)-1, dX:dX+getDataOptions.randomCrop(2)-1, :, :);
end
end
