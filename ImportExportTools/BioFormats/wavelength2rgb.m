function rgb = wavelength2rgb(wavelength)
% function rgb = wavelength2rgb(wavelength)
% Convert wavelength into RGB value (0-255)
% The code is adapted from http://www.efg2.com/Lab/ScienceAndEngineering/Spectra.htm
%
% Parameters:
% wavelength: a number containing wavelength
%
% Return values:
% rgb: an array containing, (red, green, blue) components of the color,
% range 0-255

% Copyright (C) 06.11.2015, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

if wavelength >= 380 && wavelength<440
    Red = -(wavelength - 440) / (440 - 380);
    Green = 0;
    Blue = 1;
elseif wavelength >= 440 && wavelength < 490
    Red = 0;
    Green = (wavelength - 440) / (490 - 440);
    Blue = 1;
elseif wavelength >= 490 && wavelength < 510
    Red = 0;
    Green = 1;
    Blue = -(wavelength - 510) / (510 - 490);
elseif wavelength >= 510 && wavelength < 580
    Red = (wavelength - 510) / (580 - 510);
    Green = 1;
    Blue = 0;
elseif wavelength >= 580 && wavelength < 645
    Red = 1;
    Green = -(wavelength - 645) / (645 - 580);
    Blue = 0;
elseif wavelength >= 645 && wavelength <= 780
    Red = 1;
    Green = 0;
    Blue = 0;
else
    Red = 1;
    Green = 1;
    Blue = 1;
end

% Let the intensity fall off near the vision limits
if wavelength >= 380 && wavelength < 420
    factor = 0.3 + 0.7*(wavelength - 380) / (420 - 380);
elseif wavelength >= 420 && wavelength < 701
    factor = 1;
elseif wavelength >= 701 && wavelength <= 780
    factor = 0.3 + 0.7*(780 - wavelength) / (780 - 700);
else
    factor = 0;
end

% Don't want 0^x = 1 for x <> 0
% have to fix that...

IntensityMax = 255;
Gamma = 0.8;
rgb(1) = round(IntensityMax * (Red*factor)^Gamma);
rgb(2) = round(IntensityMax * (Green*factor)^Gamma);
rgb(3) = round(IntensityMax * (Blue*factor)^Gamma);

end