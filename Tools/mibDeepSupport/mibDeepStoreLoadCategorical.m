% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 25.04.2023
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function data = mibDeepStoreLoadCategorical(filename)
% function data = mibDeepStoreLoadCategorical(filename)
% supporting function for mibDeepController
% read categorical dataset and return it as a cell similar to pixelLabelDatastore

inp = load(filename, '-mat');
if isfield(inp, 'imgVariable')
    data = {inp.(inp.imgVariable)};
else
    f = fields(inp);
    data = {inp.(f{1})};
end
end