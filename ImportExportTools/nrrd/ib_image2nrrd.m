function result = ib_image2nrrd(filename, bitmap, bb, options)
% function result = ib_image2nrrd(filename, bitmap, bb, options)
% Save image to NRRD binary format
%
% Parameters:
% filename: filename for Amira Mesh file
% bitmap: a dataset, [1:height, 1:width, 1:colors, 1:no_stacks]
% bb: bounding box information, a vector [minX, maxX, minY, maxY, minZ, maxZ]
% options: a structure with some optional parameters
% - .overwrite - if @b 1 do not check whether file with provided filename already exists
% - .showWaitbar - if @b 1 - show the wait bar, if @b 0 - do not show
%
% Return values:
% result: result of the function run, @b 1 - success, @b 0 - fail

% Copyright (C) 21.02.2014 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

result = 0;
if nargin < 2
    error('Please provide filename, and bitmap matrix!');
end
if nargin < 3   % generate bb
    bb(1) = 0;
    bb(2) = size(bitmap,2)-1;
    bb(3) = 0;
    bb(4) = size(bitmap,1)-1;
    bb(5) = 0;
    bb(6) = max([1 size(bitmap,4)-1]);
end

if nargin < 4   
    options = struct();
end
if ~isfield(options, 'overwrite'); options.overwrite = 0; end;
if ~isfield(options, 'showWaitbar'); options.showWaitbar = 1; end;

if options.overwrite == 0
    if exist(filename,'file') == 2
        choice = questdlg('File exists! Overwrite?', 'Warning!', 'Continue','Cancel','Cancel');
        if ~strcmp(choice,'Continue'); disp('Canceled, nothing was saved!'); return; end;
    end;
end

if options.showWaitbar; 
  %warning('off','MATLAB:gui:latexsup:UnableToInterpretTeXString');    % switch off warnings for latex
  curInt = get(0, 'DefaulttextInterpreter'); 
  set(0, 'DefaulttextInterpreter', 'none'); 
  wb = waitbar(0,sprintf('%s\nPlease wait...',filename),'Name','Saving images as Amira Mesh...','WindowStyle','modal');
  set(findall(wb,'type','text'),'Interpreter','none');
  waitbar(0, wb);
end;
if ndims(bitmap) == 4
    stacks = size(bitmap, 4);
else
    stacks = size(bitmap, 3);
end

img = struct();
if size(bitmap,3)>1     % color
    img.data = permute(bitmap, [3 1 2 4]);
    img.space = 3;
    img.spacedirections = [(bb(2)-bb(1))/(width-1), 0, 0; ...
                       0, (bb(4)-bb(3))/(height-1), 0; ...
                       0, 0, (bb(6)-bb(5))/(stacks-1)];
    img.centerings = int32([0; 0; 0; 0]);
    img.kinds = int32([6;1;1;1]);
else    % grayscale
    img.data = permute(bitmap, [2 1 4 3]);
    img.space = 3;
    img.spacedirections = [(bb(2)-bb(1))/(width-1), 0, 0; ...
                       0, (bb(4)-bb(3))/(height-1), 0; ...
                       0, 0, (bb(6)-bb(5))/(stacks-1)];
    img.centerings = int32([0; 0; 0]);
    img.kinds = int32([1;1;1]);
    
end
img.spaceunits = [{''};{''};{''}];
img.spaceorigin = [-bb(1); -bb(3); bb(5)];
img.measurementframe = nan(3);

nrrdSaveWithMetadata(filename, img);

disp(['ib_image2nrrd: ' filename ' was created!']);
result = 1;
if options.showWaitbar; delete(wb); set(0, 'DefaulttextInterpreter', curInt); end;
end

