function result = bitmap2nrrd(filename, bitmap, bb, options)
% function result = bitmap2nrrd(filename, bitmap, img_info, options)
% Save bitmap matrix to NRRD format
%
% Format description:
% http://teem.sourceforge.net/nrrd/format.html
%
% Parameters:
% filename: filename for NRRD
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
if nargin < 3   % generate img_info
    bb(1) = 0;
    bb(2) = size(bitmap,2)-1;
    bb(3) = 0;
    bb(4) = size(bitmap,1)-1;
    bb(5) = 0;
    bb(6) = max([1 size(bitmap,4)-1 size(bitmap,3)]);
end

if nargin < 4   
    options = struct();
end
if ~isfield(options, 'overwrite'); options.overwrite = 0; end
if ~isfield(options, 'showWaitbar'); options.showWaitbar = 1; end

if options.overwrite == 0
    if exist(filename,'file') == 2
        choice = questdlg('File exists! Overwrite?', 'Warning!', 'Continue','Cancel','Cancel');
        if ~strcmp(choice,'Continue'); disp('Canceled, nothing was saved!'); return; end
    end
end

if options.showWaitbar
  %warning('off','MATLAB:gui:latexsup:UnableToInterpretTeXString');    % switch off warnings for latex
  curInt = get(0, 'DefaulttextInterpreter'); 
  set(0, 'DefaulttextInterpreter', 'none'); 
  wb = waitbar(0,sprintf('%s\nPlease wait...',filename),'Name','Saving images in the nrrd format...','WindowStyle','modal');
  set(findall(wb,'type','text'),'Interpreter','none');
  waitbar(0, wb);
end

width = size(bitmap, 2);
height = size(bitmap, 1);
if ndims(bitmap) == 4
    stacks = size(bitmap, 4);
    colors = size(bitmap, 3);
else
    if size(bitmap, 3) == 3
        stacks = 1;
        colors = size(bitmap, 3);
    else
        stacks = size(bitmap, 3);
        colors = 1;
    end
end
% 
% if colors == 1
%     bitmap = squeeze(bitmap)
% end

fid = fopen(filename, 'w');
% saving the header
fprintf(fid, 'NRRD0004\n');
fprintf(fid, '# Complete NRRD file format specification at:\n');
fprintf(fid, '# http://teem.sourceforge.net/nrrd/format.html\n');
if isa(bitmap, 'uint8')
    fprintf(fid, 'type: unsigned char\n');
elseif isa(bitmap, 'uint16')
    fprintf(fid, 'type: unsigned short\n');
else
    error('bitmap2nrrd: wrong data type');
end

if colors==1
    fprintf(fid, 'dimension: 3\n');
else
    fprintf(fid, 'dimension: 4\n');
end
fprintf(fid, 'space: left-posterior-superior\n');

% save size 
if colors==1
    fprintf(fid, 'sizes: %d %d %d\n', size(bitmap,2), size(bitmap,1), size(bitmap, ndims(bitmap)));
else
    fprintf(fid, 'sizes: %d %d %d %d\n', size(bitmap,3), size(bitmap,2), size(bitmap,1), size(bitmap,4));
end

% save voxel sizes
%space directions: (25.399999999999999,0,0) (0,25.399999999999999,0) (0,0,1) 
if colors == 1
    fprintf(fid, 'space directions: (%f,0,0) (0,%f,0) (0,0,%f)\n',(bb(2)-bb(1))/(max([1 width-1])), (bb(4)-bb(3))/max([(height-1) 1]), (bb(6)-bb(5))/max([(stacks-1) 1]));
    fprintf(fid, 'kinds: domain domain domain\n');
else
    fprintf(fid, 'space directions: none (%f, 0, 0) (0, %f, 0) (0,0,%f)\n',(bb(2)-bb(1))/(max([1 width-1])), (bb(4)-bb(3))/max([(height-1) 1]), (bb(6)-bb(5))/max([(stacks-1) 1]));
    fprintf(fid, 'kinds: vector domain domain domain\n');
end
fprintf(fid, 'encoding: raw\n');
fprintf(fid, 'endian: little\n');
fprintf(fid, 'space origin: (%f,%f,%f)\n', -bb(1), -bb(3), bb(5));
fprintf(fid, '\n');
if options.showWaitbar; waitbar(.05,wb); end;
% save data
if colors == 1  % greyscale
    if ndims(bitmap) == 4
        bitmap = reshape(permute(bitmap,[2 1 4 3]),1,[])';
    else
        bitmap = reshape(permute(bitmap,[2 1 3]),1,[])';
    end
else
    bitmap = reshape(permute(bitmap,[3 2 1 4]),1,[])';
end
fwrite(fid, bitmap, class(bitmap), 0, 'ieee-le');  
if options.showWaitbar; waitbar(1, wb); end;
fclose(fid);
disp(['bitmap2nrrd: ' filename ' was created!']);
result = 1;
if options.showWaitbar; delete(wb); set(0, 'DefaulttextInterpreter', curInt); end;
end

% maxZ = size(bitmap,4);
% 
% if size(bitmap,3) == 1  % grayscale images
%     fprintf(fid,'Lattice { %s Data } @1\n\n', imgClass);
%     fprintf(fid,'# Data section follows\n');
%     fprintf(fid,'@1\n');
%     
%     for zIndex = 1:maxZ
%         img = bitmap(:,:,1,zIndex);
%         img = reshape(permute(img,[3 2 1]),1,[])';
%         fwrite(fid, img, class(img), 0, 'ieee-le');  
%         if options.showWaitbar && mod(zIndex, ceil(maxZ/20))==0;
%             waitbar(zIndex/maxZ, wb);
%         end
%     end
% elseif size(bitmap,3) == 3  % RGB images + Alpha
%     fprintf(fid,'Lattice { %s[4] Data } @1\n\n', imgClass);
%     fprintf(fid,'# Data section follows\n');
%     fprintf(fid,'@1\n');
%     width = size(bitmap,2);
%     height = size(bitmap,1);
%     % reshape the matrix into a vector
%     for zIndex = 1:maxZ
%         img = bitmap(:,:,:,zIndex);
%         img(:,:,4,:) = zeros(height,width,1); % add alpha channel
%         img = reshape(permute(img,[3 2 1]),1,[])';
%         fwrite(fid, img, class(img), 0, 'ieee-le');  
%         if options.showWaitbar && mod(zIndex, ceil(maxZ/20))==0;
%             waitbar(zIndex/maxZ, wb);
%         end
%     end
% else
%     maxIndex = maxZ * size(bitmap,3);
%     index = 1;
%     for ch = 1:size(bitmap,3)
%         fprintf(fid,'Lattice { %s Data%d } @%d\n', imgClass, ch, ch);
%     end
%     fprintf(fid,'\n');
%     fprintf(fid,'# Data section follows');
%     for ch = 1:size(bitmap,3)
%         fprintf(fid,'\n');
%         fprintf(fid,'@%d\n', ch);
%         for zIndex = 1:maxZ
%             img = bitmap(:,:,ch,zIndex);
%             img = reshape(permute(img,[3 2 1]),1,[])';
%             fwrite(fid, img, class(img), 0, 'ieee-le');
%             if options.showWaitbar && mod(index, ceil(maxIndex/20))==0;
%                 waitbar(index/maxIndex, wb);
%             end
%         index = index + 1;    
%         end
%     end
% end
% fprintf(fid,'\n');
% fclose(fid);
% disp(['bitmap2nrrd: ' filename ' was created!']);
% result = 1;
% if options.showWaitbar; delete(wb); end;
% end

