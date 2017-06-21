function mask = mibGetFrangiMask(img, Options, Options2, type, orientation2d, layer_id)
% function mask = mibGetFrangiMask(img, Options, Options2, type, orientation2d, layer_id)
% Return Frangi mask generated from img
%
% Parameters:
% img: -> input image, [1:height, 1:width, 1:color, 1:layers]
% Options: -> a structure with Parameters
%  - .FrangiScaleRange -> The range of sigmas used, default [1 8]
%  - .FrangiScaleRatio -> Step size between sigmas, default 2
%  - .FrangiBetaOne -> Frangi correction constant, default 0.5
%  - .FrangiBetaTwo -> Frangi correction constant, default 15
%  - .BlackWhite -> Detect black ridges (default) set to true, for white ridges set to false.
%  - .verbose -> Show debug information, default true
% Options2: -> a structure with extra parameters
%  - .bwthreshold -> threshold for mask generation
%  - .sizefilter -> size exclusion parameter
% type: -> ''2d'' or ''3d'' (''3d'' is not implemented)
% orientation2d: -> defines the stack orientation for 2d filtering, @b 1 - zx, @b 2 - zy, or @b 4 - yx
% layer_id: -> define a single slice from the dataset, when omitted filter the whole dataset
%
% Return values:
% mask: generated mask image [1:height,1:width,1:no_stacks], (0/1);

% Copyright (C) 21.11.2013, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 


wb = waitbar(0,'Generating Frangi filtered mask...','Name','Frangi filter','WindowStyle','modal');
tic
if nargin < 6
    start_id = 1;
    end_id = size(img, orientation2d);
else
    start_id = layer_id;
    end_id = layer_id;
end
mask = zeros(size(img,1),size(img,2),size(img,4),'uint8');

%     % 3d test
%     clear Options;
%     Options.FrangiScaleRange = [1 8];  % The range of sigmas used, default [1 8]
%     Options.FrangiScaleRatio = 2; % Step size between sigmas, default 2
%     Options.FrangiAlpha = 0.2; % Frangi vesselness constant, treshold on Lambda2/Lambda3
%     				           % determines if its a line(vessel) or a plane like structure
%                                % default .5;
%     Options.FrangiBeta = .5;  %Frangi vesselness constant, which determines the deviation
%                                % from a blob like structure, default .5;
%     Options.FrangiC = 500;     % Frangi vesselness constant which gives
%                                % the threshold between eigenvalues of noise and
%                                % vessel structure. A thumb rule is dividing the
%                                % the greyvalues of the vessels by 4 till 6, default 500;
%     Options.BlackWhite = 1;
%     Options.verbose = 0;
%
%     [J,Scale,Vx,Vy,Vz] = FrangiFilter3D(squeeze(handles.Img{handles.Id}.I.img), Options);
%     result = J;
%     bwthreshold = max(max(max(result)))*.01;
%     for i=start_no:end_no
%         bw = im2bw(result(:,:,i),bwthreshold);
%         bw = bwareaopen(bw, sizefilter);
%     end

bwthreshold = Options2.bwthreshold;
sizefilter = Options2.sizefilter;

if strcmp(type, '2d')
    if orientation2d == 4    % xy plane
        for layer=start_id:end_id
            curr_img = double(img(:,:,:,layer));
            result = FrangiFilter2D(curr_img,Options);
            if bwthreshold ~= 0
                result = result/max(max(result));
                bw = im2bw(result, bwthreshold);
                bw = bwareaopen(bw, sizefilter);
                mask(:,:,layer) = bw;
            else
                mask(:,:,layer) = uint8(result/max(max(result))*255);
            end
        end
    elseif orientation2d == 1
        parfor layer=start_id:end_id
            curr_img = double(squeeze(img(layer,:,:,:)));
            result = FrangiFilter2D(curr_img,Options);
            if bwthreshold ~= 0
                result = result/max(max(result));
                bw = im2bw(result, bwthreshold);
                bw = bwareaopen(bw, sizefilter);
                mask(layer,:,:) = bw;
            else
                mask(layer,:,:) = uint8(result/max(max(result))*255);
            end
        end
    elseif orientation2d == 2
        parfor layer=start_id:end_id
            curr_img = double(squeeze(img(:,layer,:,:)));
            result = FrangiFilter2D(curr_img,Options);
            if bwthreshold ~= 0
                result = result/max(max(result));
                bw = im2bw(result, bwthreshold);
                bw = bwareaopen(bw, sizefilter);
                mask(:,layer,:) = bw;
            else
                mask(:,layer,:) = uint8(result/max(max(result))*255);
            end
        end
    else
        error('Wrong orientation!');
    end
else    % do in 3d Test
    Options3.FrangiScaleRange = Options.FrangiScaleRange;  % The range of sigmas used, default [1 8]
    Options3.FrangiScaleRatio = Options.FrangiScaleRatio; % Step size between sigmas, default 2
    Options3.FrangiAlpha = Options.FrangiBetaOne; % Frangi vesselness constant, treshold on Lambda2/Lambda3
                                                 % determines if its a line(vessel) or a plane like structure
                                                 % default .5;
    Options3.FrangiBeta = Options.FrangiBetaTwo;  %Frangi vesselness constant, which determines the deviation
                                                 % from a blob like structure, default .5;
    Options3.FrangiC = Options.FrangiBetaThree;    % Frangi vesselness constant which gives
                                                  % the threshold between eigenvalues of noise and
                                                  % vessel structure. A thumb rule is dividing the
                                                  % the greyvalues of the vessels by 4 till 6, default 500;
    Options3.BlackWhite = Options.BlackWhite;
    Options3.verbose = 0;
    
    %[J, Scale, Vx, Vy, Vz] = FrangiFilter3D(squeeze(img), Options3);
    J = FrangiFilter3D(squeeze(img), Options3);
    maxJ = max(max(max(J)));
    minJ = min(min(min(J)));
    diffJ = maxJ - minJ;
    img = uint8((J-minJ)/diffJ*255);
    if bwthreshold ~= 0
        for i=1:size(img,3)
            bw = im2bw(img(:,:,i), bwthreshold);
            bw = bwareaopen(bw, sizefilter);
            mask(:,:,i) = bw;
        end
    else
        mask = img;
    end
end
delete(wb);
toc;
end



