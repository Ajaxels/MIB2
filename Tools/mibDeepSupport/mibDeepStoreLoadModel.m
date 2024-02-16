% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 25.04.2023
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function model = mibDeepStoreLoadModel(filename)
% function model = mibDeepStoreLoadModel(filename)
% supporting function for mibDeepController
% to be used with pixelLabelDatastore to load MIB models
%
% Parameters:
% filename: filename to load the model

res = load(filename, '-mat');
model = res.(res.modelVariable);
end