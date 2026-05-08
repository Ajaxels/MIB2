% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>

% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% Date: 25.04.2023

function fn = generateSequentialFilename(name, num, files_no, ext)
% function fn = generateSequentialFilename(name, num, files_no, ext)
% generate sequential filenames
% 
% Parameters:
% name: a filename template
% num: sequential number to generate
% files_no: total number of files in sequence
% ext: string with extension

% Updates
% 

if files_no == 1
    fn = [name ext];
else
    digits = max(2, floor(log10(files_no)) + 1);
    fn = sprintf('%s_%0*i%s', name, digits, num, ext);
end

end