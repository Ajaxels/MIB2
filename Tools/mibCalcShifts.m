function [shiftX, shiftY] = mibCalcShifts(I, options)
% function [shiftX, shiftY] = mibCalcShifts(I, options)
% Calculate alignment shifts between slices in I
%
% Parameters:
% I: a stack to align in format: [1:height, 1:width, 1:depth]
% options: an optional structure with parameters
% - .method -> method: 'Drift correction', 'Template matching'
% - .refFrame, a number with the reference slice: when @b 0 - use the previous
% - .mask, an optional mask image to select subareas to use for alignment,
% - .waitbar, [optional] a handle to an existing waitbar
%
% Return values:
% shiftX: a vector with absolute shifts in the X-plane, the shifts are calculated relative to the first slice
% shiftY: a vector with absolute shifts in the Y-plane, the shifts are calculated relative to the first slice

% Copyright (C) 30.01.2017 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% based on algorithms descibed in
% - JC Russ, The image processing handbook, CRC Press, Boca Raton, FL, 1994
% - JD Sugar, AW Cummings, BW Jacobs, DB Robinson, A Free Matlab Script For
% Spatial Drift Correction, Microscopy Today — Volume 22, Number 5, 2014
% https://se.mathworks.com/matlabcentral/fileexchange/45453-drifty-shifty-deluxe-m
% http://onlinedigeditions.com/publication/?i=223321&p=40
%
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if nargin < 2; options = struct(); end

if ~isfield(options, 'method'); options.method = 'xcMatlab'; end    
if ~isfield(options, 'refFrame'); options.refFrame = 0; end    % use the previous slice for the reference

if isfield(options, 'waitbar')
    wb = options.waitbar;
else
    wb = waitbar(0, '', 'Name', 'Align and drift correction', 'WindowStyle','modal');
end

% get image dimensions
[Height, Width, Depth] = size(I);

shiftX = zeros(Depth,1);
shiftY = zeros(Depth,1);

% Get the first reference frame
Iref=fft2(I(:,:,1));

% get center of the image 
imgCenterX=floor((Width/2)+1);
imgCenterY=floor((Height/2)+1);

waitbar(0,wb, sprintf('Calculating drifts\nPlease wait...'));

%assignin('base', 'I', I);

switch options.method
    case {'Drift correction', 'Template matching'}
        for i=2:Depth
            Icur=fft2(I(:,:,i));
            
            prod = Iref .* conj(Icur);
            cc=ifft2(prod);
            
            if strcmp(options.method, 'Drift correction') 
                [Yo, Xo]=find(fftshift(cc)==max(max(cc)));
                shiftX(i)=Xo(1)-imgCenterX;
                shiftY(i)=Yo(1)-imgCenterY;
                % Checks to see if there is an ambiguity problem with FFT because of the periodic boundary in FFT
                if abs(shiftX(i)-shiftX(i-1)) > Width/2
                    shiftX(i)=shiftX(i)-sign(shiftX(i)-shiftX(i-1))*Width;
                end
                if abs(shiftY(i)-shiftY(i-1)) > Height/2
                    shiftY(i)=shiftY(i)-sign(shiftY(i)-shiftY(i-1))*Height;
                end
            else
                [shiftY(i), shiftX(i)]=find(cc==max(max(cc)));
                % [cY, cX]=find(cc==max(max(cc)));
            end
                        
            if options.refFrame == 0
                Iref = Icur;
            elseif options.refFrame < 0 && i > abs(options.refFrame)
                Iref = fft2(I(:,:,i+options.refFrame+1));
            end
            
            if mod(i,10)==0
                waitbar(i/Depth, wb);
            end
        end 
        
        % recalculate shifts from relative to vs the first one
        if options.refFrame == 0
            shiftX = cumsum(shiftX);
            shiftY = cumsum(shiftY);
        elseif options.refFrame < 0
            shiftX2 = shiftX;
            shiftY2 = shiftY;
            step = -options.refFrame;
            
%             % option 1
%             for j=step+2:length(shiftY2)
%                 shiftX2(j) = shiftX(j) + shiftX2(j-step);
%                 shiftY2(j) = shiftY(j) + shiftY2(j-step);
%             end
%             shiftX2b = round(windv(shiftX2, step));
%             shiftY2b = round(windv(shiftY2, step));
%             % end of option 1
            
            % option 2
            refId = step;
            for j=step+2:length(shiftY2)
                if mod(j, step) == 0
                    shiftX2(j) = shiftX(j) + shiftX2(refId);
                    refId = j;
                else
                    shiftX2(j) = shiftX(j) + shiftX2(refId-step+1);
                end
            end
            shiftX2 = round(windv(shiftX2, step));
            shiftY2 = round(windv(shiftY2, step));
            % end of option 2
            
            shiftX = shiftX2;
            shiftY = shiftY2;
        end
end
if ~isfield(options, 'waitbar')
    delete(wb);
end

end

