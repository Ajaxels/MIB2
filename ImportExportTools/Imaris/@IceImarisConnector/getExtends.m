function varargout = getExtends(this)
% IceImarisConnector:  getExtends (public method)
%
% DESCRIPTION
% 
%   This method returns the dataset extends.
% 
% SYNOPSIS
% 
%   (1)                              extends = conn.getExtends()
%   (2) [minX, maxX, minY, maxY, minZ, maxZ] = conn.getExtends()
% 
% INPUT
% 
%   None
% 
% OUTPUT
% 
%   (1) extends : vector of extends, [minX maxX minY maxY minZ maxZ]
% 
%   (2) minX : minimum dataset extend in X direction
%       maxX : maximum dataset extend in X direction
%       minY : minimum dataset extend in Y direction
%       maxY : maximum dataset extend in Y direction
%       minZ : minimum dataset extend in Z direction
%       maxZ : maximum dataset extend in Z direction

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

% Is Imaris running?
if this.isAlive() == 0
    return
end

% Is there a Dataset?
if isempty(this.mImarisApplication.GetDataSet())
    return
end

% Return the extends
if nargout <= 1
    
    % We return all extends as one vector in the first output parameter 
    varargout{1} = [
        this.mImarisApplication.GetDataSet().GetExtendMinX(), ...
        this.mImarisApplication.GetDataSet().GetExtendMaxX(), ...
        this.mImarisApplication.GetDataSet().GetExtendMinY(), ...
        this.mImarisApplication.GetDataSet().GetExtendMaxY(), ...
        this.mImarisApplication.GetDataSet().GetExtendMinZ(), ...
        this.mImarisApplication.GetDataSet().GetExtendMaxZ()
        ];

else
    
    % Independent extends
    varargout{1} = this.mImarisApplication.GetDataSet().GetExtendMinX();
    varargout{2} = this.mImarisApplication.GetDataSet().GetExtendMaxX();
    varargout{3} = this.mImarisApplication.GetDataSet().GetExtendMinY();
    varargout{4} = this.mImarisApplication.GetDataSet().GetExtendMaxY();
    varargout{5} = this.mImarisApplication.GetDataSet().GetExtendMinZ();
    varargout{6} = this.mImarisApplication.GetDataSet().GetExtendMaxZ();

end
