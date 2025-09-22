% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 15.08.2025
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function writeZarrAttributes(zarrPath, attributes, zarrFormat)
% writeZarrAttributes
% Write custom attributes into a Zarr group or array.
%
% Parameters:
% zarrPath    : string, path to the Zarr group or array
% attributes  : struct of key-value pairs to write as attributes
% zarrFormat  : int, Zarr format version (2 or 3). Default: 2
%
% Notes:
%   - Existing attributes are preserved unless overwritten.
%   - Works for both Zarr groups and arrays.
%
% Example:
%   attrs = struct();
%   attrs.creator = 'MyLab';
%   attrs.sampleID = 'EXP42';
%   writeZarrAttributes('my.zarr', attrs, 2);

arguments
    zarrPath (1,:) char
    attributes struct = struct()
    zarrFormat (1,1) double = 2
end

% Normalize path
zarrPath = strrep(zarrPath,'\','/');

if ~isfolder(zarrPath)
    error('Zarr path does not exist: %s', zarrPath);
end

% Encode attributes as JSON so Python can parse them
attrs_json = jsonencode(attributes, 'PrettyPrint', true);

% Use Zarr API to update attrs
if zarrFormat == 2
    pyrun([ ...
        "import zarr, json" ...
        "obj = zarr.open(storePath, mode='a', zarr_format=2)" ...
        "obj.attrs.update(json.loads(attrs_json))" ...
        ], ...
        storePath=zarrPath, ...
        attrs_json=attrs_json);
else
    pyrun([ ...
        "import zarr, json" ...
        "obj = zarr.open(storePath, mode='a', zarr_format=3)" ...
        "obj.attrs.update(json.loads(attrs_json))" ...
        ], ...
        storePath=zarrPath, ...
        attrs_json=attrs_json);
end

fprintf('Custom attributes written to %s (Zarr v%d).\n', zarrPath, zarrFormat);
end
