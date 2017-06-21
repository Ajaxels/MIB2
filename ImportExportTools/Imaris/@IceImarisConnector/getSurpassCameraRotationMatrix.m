function [R, isI] = getSurpassCameraRotationMatrix(this)
% IceImarisConnector:  getSurpassCameraRotationMatrix (public method)
%
% DESCRIPTION
%
%   This method calculates the rotation matrix that corresponds to current
%   view in the Surpass Scene (from the Camera Quaternion) for the axes
%   with "Origin Bottom Left". 
%
% TO DO
%
%   Verify the correctness for the other axes orientations.
%
% SYNOPSIS
%
%   [R, isI] = conn.getSurpassCameraRotationMatrix()
%
% INPUT
%
%   None
%
% OUTPUT
%
%   R   : (4 x 4) rotation matrix
%   isI : true if the rotation matrix is the Identity matrix, i.e. the
%         camera is perpendicular to the dataset

% AUTHORS
%
% Author: Aaron Ponti

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

% Initialize R
R = [];

% Get the camera
vCamera = this.mImarisApplication.GetSurpassCamera();
if isempty(vCamera)
    return
end

% Get the camera position quaternion
q = vCamera.GetOrientationQuaternion();

% Make sure the quaternion is a unit quaternion
[q1, q2, q3, q4] = makeUnit(q(1), q(2), q(3), q(4));

% Calculate the rotation matrix R from the quaternion
R = rotationMatrixFromQuaternion(q1, q2, q3, q4);

% Is R the Identity matrix?
T = R == eye(4);
isI = all(T(:));

end

% =========================================================================

function R = rotationMatrixFromQuaternion(X, Y, Z, W)

R = zeros(4, 4);

x2 = X + X;    y2 = Y + Y;    z2 = Z + Z;
xx = X * x2;   xy = X * y2;   xz = X * z2;
yy = Y * y2;   yz = Y * z2;   zz = Z * z2;
wx = W * x2;   wy = W * y2;   wz = W * z2;

R(1, 1) = 1.0 - (yy + zz);
R(1, 2) = xy - wz;
R(1, 3) = xz + wy;

R(2, 1) = xy + wz;
R(2, 2) = 1.0 - (xx + zz);
R(2, 3) = yz - wx;

R(3, 1) = xz - wy;
R(3, 2) = yz + wx;
R(3, 3) = 1.0 - (xx + yy);

R(4, 4) = 1;

end

% =========================================================================

function [X, Y, Z, W] = makeUnit(X, Y, Z, W)

n2 = X ^ 2 + Y ^ 2 + Z ^ 2 + W ^ 2;
if n2 == 1
    return
end
n = sqrt(n2);
X = X / n;
Y = Y / n;
Z = Z / n;
W = W / n;

end
