function result = mibImage2mrc(O, Options)
% function result = mibImage2mrc(O, Options)
% Export volume in MRC format
%
% @note Requires matTomo function set, provided in @em mib\ImportExportTools\MatTomo
%
% Parameters:
% O: a dataset, [1:height,1:width,1:thickness] or [1:height,1:width,1,1:thickness]
% Options: a structure:
% @li .volumeFilename a filename, use 'mrc' extension
% @li .pixSize.x - physical width of the voxels
% @li .pixSize.y - physical height of the voxels
% @li .pixSize.z physical thickness of the voxels
% @li .pixSize.units - physical units
% @li .showWaitbar - if @b 1 - show the wait bar, if @b 0 - do not show
%
% Return values:
% result: result of the function run, @b 1 - success, @b 0 - fail

% % Copyright (C) 06.12.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

result = 0;
if ~isfield(Options, 'showWaitbar'); Options.showWaitbar = 1; end

if ndims(O) == 3
    O = permute(O, [2 1 3]);
else
    if size(O,3) > 1
        errordlg(sprintf('MRC format requires grayscale images!\nPlease convert dataset to the grayscale mode: Menu->Image->Mode->Grayscale'),'Wrong input data');
        return;
    end
    O = permute(squeeze(O), [2 1 3]);
end

if Options.showWaitbar
    %warning('off','MATLAB:gui:latexsup:UnableToInterpretTeXString');    % switch off warnings for latex
    curInt = get(0, 'DefaulttextInterpreter'); 
    set(0, 'DefaulttextInterpreter', 'none'); 
    wb = waitbar(0,sprintf('Saving:\n%s\nPlease wait...', Options.volumeFilename),'Name','Saving to MRC');
    set(findall(wb,'type','text'),'Interpreter','none');
end

mrcImage = MRCImage();
mrcImage = setVolume(mrcImage, O);

switch Options.pixSize.units
    case 'm'
        coef = 1e-10;
    case 'cm'
        coef = 1e-8;
    case 'mm'
        coef = 1e-7;
    case 'um'
        coef = 1e-4;
    case 'nm'
        coef = 1e-1;
end
pixSizeX_Angstrom = Options.pixSize.x/coef;
pixSizeY_Angstrom = Options.pixSize.y/coef;
pixSizeZ_Angstrom = Options.pixSize.z/coef;

mrcImage = setPixelSize(mrcImage, pixSizeX_Angstrom, pixSizeY_Angstrom, pixSizeZ_Angstrom);

save(mrcImage, Options.volumeFilename);
if Options.showWaitbar; delete(wb); set(0, 'DefaulttextInterpreter', curInt); end;


result = result + 1;
end
