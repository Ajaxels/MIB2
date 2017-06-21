function varargout = getSizes(this)
% IceImarisConnector:  getSizes (public method)
%
% DESCRIPTION
% 
%   This method returns the dataset sizes.
% 
% SYNOPSIS
% 
%   (1)                               sizes = conn.getSizes()
%   (2) [sizeX, sizeY, sizeZ, sizeC, sizeT] = conn.getSizes()
% 
% INPUT
% 
%   None
% 
% OUTPUT
%
%   (1) sizes : vector of sizes, [sizeX sizeY sizeZ sizeC sizeT]  
% 
%   (2) sizeX : dataset size X
%       sizeY : dataset size Y
%       sizeZ : number of planes
%       sizeC : number of channels
%       sizeT : number of time points

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

% Return the sizes
if nargout <= 1

    % We return all sizes as one vector in the first output parameter 
    varargout{1} = [
        this.mImarisApplication.GetDataSet().GetSizeX(), ...
        this.mImarisApplication.GetDataSet().GetSizeY(), ...
        this.mImarisApplication.GetDataSet().GetSizeZ(), ...
        this.mImarisApplication.GetDataSet().GetSizeC(), ...
        this.mImarisApplication.GetDataSet().GetSizeT()
        ];
else
    
    % Independent dimensions
    varargout{1} = this.mImarisApplication.GetDataSet().GetSizeX();
    varargout{2} = this.mImarisApplication.GetDataSet().GetSizeY();
    varargout{3} = this.mImarisApplication.GetDataSet().GetSizeZ();
    varargout{4} = this.mImarisApplication.GetDataSet().GetSizeC();
    varargout{5} = this.mImarisApplication.GetDataSet().GetSizeT();

end
