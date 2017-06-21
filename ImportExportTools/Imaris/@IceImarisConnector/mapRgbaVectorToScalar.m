function rgbaScalar = mapRgbaVectorToScalar(rgbaVector)
% IceImarisConnector:  mapRgbaVectorToScalar (static public method)
%
% DESCRIPTION
%
%   This method maps an 1-by-4, (0..1) RGBA vector to an uint32 scalar
%
% SYNOPSIS
%
%   rgbaScalar = mapRgbaVectorToScalar(rgbaVector)
%
% INPUT
%
%   rgbaVector: 1-by-4 array with [R G B A] indicating (R)ed, (G)reen,
%               (B)lue, and (A)lpha (=transparency; 0 is opaque).
%               All values are between 0 and 1.
%
% OUTPUT
%
%   rgbaScalar: uint32 scalar number coding for RGBA (for Imaris use)
%
% IMPORTANT REMARK
%
%   
%   The way one calculates the RGBA value from an [R G B A] vector (with
%   the values of R, G, B, and A all between 0 and 1) is simply:
%   
%     uint32([R G B A] * [1 256 256^2 256^3])
%
%   (where * is the matrix product). This gives a number between 0 and 
%   intmax('uint32') = 4294967295.
%
%   When we pass this number to Imaris through ImarisXT, the Java layer in
%   Ice will mess with this number, since there are no unsigned values
%   in Java and our original uint32 will end up negative if its value is
%   larger than 0.5 * intmax('uint32'): the first bit becomes the sign
%   bit. 
%  
%   The bit that changes is in the transparency (A) byte. Which means, if
%   we change the value for the tranparency, we will end up with an
%   incorrect result in Imaris.
%
%   To work around this problem, we must typecast (and not just cast!) 
%   the calculated uint32 value to int32 before it is ready to be sent 
%   to Imaris (i.e. to be passed to the SetColorRGBA() method of the 
%   IDataItem object.
%
% SEE ALSO
%
%   mapRgbaVectorToScalar

% AUTHORS
%
% Author: Jonas Dorn
% Contributor: Aaron Ponti (int32/uint32 type casting fix)

% LICENSE
%
% ImarisConnector is a simple commodity class that eases communication between
% Imaris and MATLAB using the Imaris XT interface.
% Copyright (C) 2011  Aaron Ponti
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

% check input
if ~isvector(rgbaVector) || length(rgbaVector) ~= 4 || ...
        any(rgbaVector < 0) || any(rgbaVector) > 1
    error('rgbaVector must be 1-by-4 with all elements between 0 and 1.')
end

% Make sure we have a row vector
rgbaVector = rgbaVector(:)';

% Need integer values scaled to the range 0-255
rgbaVector = round(rgbaVector * 255);

% Combine different components (four bytes) into one integer
rgbaScalar = uint32(rgbaVector * 256 .^ (0 : 3)');

% Now typecast it to signed int32 to get it right into Imaris
rgbaScalar = typecast(rgbaScalar, 'int32');
