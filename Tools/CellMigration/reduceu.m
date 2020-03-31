function [redData]=reduceu(data,numReductions,reducein3D)
% function [redData]=reduceu(data,numReductions,reducein3D)
%
%--------------------------------------------------------------------------
% reduceu  function to reduce data in uniform levels receives an image (or stack of images)
%     and reduces it in quadtree, reduction is ALWAYS in factor of 2 
%
%       INPUT
%         data:             data to be reduced 
%
%         numReductions:    number of reductions (1 : 1000x1000 -> 500X500, 
%                           2: 1000x1000 -> 250x250, etc)
%
%         reducein3D:       if 1, will combine levels; 0, performs reduction 
%                           in a per-slice basis
%
%       OUTPUT
%         redData:          reduced data
%           
%          
%--------------------------------------------------------------------------
%
%     Copyright (C) 2012  Constantino Carlos Reyes-Aldasoro
%
%     This file is part of the PhagoSight package.
%
%     The PhagoSight package is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, version 3 of the License.
%
%     The PhagoSight package is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
%
%     You should have received a copy of the GNU General Public License
%     along with the PhagoSight package.  If not, see <http://www.gnu.org/licenses/>.
%
%--------------------------------------------------------------------------
%
% This m-file is part of the PhagoSight package used to analyse fluorescent phagocytes
% as observed through confocal or multiphoton microscopes.  For a comprehensive 
% user manual, please visit:
%
%           http://www.phagosight.org.uk
%
% Please feel welcome to use, adapt or modify the files. If you can improve
% the performance of any other algorithm please contact us so that we can
% update the package accordingly.
%
%--------------------------------------------------------------------------
%
% The authors shall not be liable for any errors or responsibility for the 
% accuracy, completeness, or usefulness of any information, or method in the content, or for any 
% actions taken in reliance thereon.
%
%--------------------------------------------------------------------------



%------ no input data is received, error -------------------------
if nargin<1;    help reduceu;   redData=[];   return; end;

if ~exist('numReductions','var');   numReductions   = 1; end
if ~exist('reducein3D','var');      reducein3D      = 0; end




if ~(isa(data,'double')); data=double(data); end

if numReductions==0
    redData                 = data;
else
    if numReductions>1
        data                = reduceu(data,numReductions-1,reducein3D);
    end

    [rows,cols,levels]      = size(data);

    if (levels==1)||(reducein3D==0)
        redData             = convn(data,[1 1;1 1]);
        if levels==1
            redData         = redData(2:2:end,2:2:end)/4;
        else
            redData         = redData(2:2:end,2:2:end,:)/4;
        end
    else      
        redData             = convn(data,ones(2,2,2));
        redData             = redData(2:2:end,2:2:end,2:2:end)/8;

    end
end
