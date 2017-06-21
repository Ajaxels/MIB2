function rgbaVector = mapRgbaScalarToVector(rgbaScalar)
% IceImarisConnector:  mapRgbaScalarToVector (static public method)
%
% DESCRIPTION
%
%   This method maps an uint32 RGBA scalar to an 1-by-4, (0..1) vector
%
% SYNOPSIS
%
%   rgbaScalar = mapRgbaVectorToScalar(rgbaScalar)
%
% INPUT
%
%   rgbaScalar: int32 scalar number coding for RGBA (for Imaris use)
%
% OUTPUT
%
%   rgbaVector: 1-by-4 array with [R G B A] indicating (R)ed, (G)reen,
%               (B)lue, and (A)lpha (=transparency; 0 is opaque)
%
% IMPORTANT REMARK
%
%   The scalar returned by ImarisXT is signed int32 (since ImarisLib() is
%   written in Java). This means that if the transparency is not zero
%   (i.e. the value for A in the RGBA scalar is not zero), the returned
%   value WILL BE NEGATIVE (i.e. Imaris pushes an uint32 through ImarisXT
%   and thus Java and this reaches MATLAB as a signed int32)! 
%
%   The mapRgbaScalarToVector() function will work around this problem
%   by forcing a typecast (and not just a cast!) to int32 passing through
%   a forced cast to int32 (since ImarisXT's .GetColorRGBA() returns a 
%   double...).
%
%   Please notice that the combined values for R, G, and B will be 
%   represented correctly no matter if the RGBA scalar is stored in an
%   int32 or an uint32, therefore the transparency "bug" does not affect
%   the actual colors.
%
% SEE ALSO
%
%   mapRgbaScalarToVector

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

% Check input
if ~isscalar(rgbaScalar)
    error('rgbaScalar must be a scalar.')
end

% Force conversion to uint32 passing through int32.
rgbaScalar = typecast(int32(rgbaScalar), 'uint32');

% Perform conversion
rgbaVector = zeros(1, 4);
for i = 1 : 4
    
    % Use bit-operators to extract information
    rgbaVector(i) = double(...
        bitget(rgbaScalar, 8 : -1 : 1)) * 2.^(7 : -1 : 0)';
    
    % Shift the scalar by 8 bits
    rgbaScalar = bitshift(rgbaScalar, -8);
    
end

% Normalize
rgbaVector = rgbaVector / 255;
