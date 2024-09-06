% Author: Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% Date: 06.09.2024
% License: BSD-3 clause (https://opensource.org/license/bsd-3-clause/)

function mibVersionNumeric = mibGetVersionNumberic(mibVersionString)
% function mibVersionNumeric = mibGetVersionNumberic(mibVersionString)
% get MIB version in numeric format from the string
%
% Parameters:
% mibVersionString: string containing the current version of MIB. The
% version is defined in mib.m file and can should be quite strict in
% syntax. Two options ara available:
% @li "ver. 2.909 / 06.08.2024" - release, where mibVersionNumeric is detected
% from text between "ver." and "/"
% @li "ver. 2.909 (beta 07) / 06.08.2024" - beta version, requires "beta"
% and ")" characters. mibVersionNumeric is generated as the specified
% version (i.e. 2.909) -minus- beta version (i.e. 7) as
% "2.909 - (1000-7)/1000000"
%
% Return values:
% mibVersionNumeric: double with the current MIB version
%|
% @ Note:
% None

index1 = strfind(mibVersionString, 'ver.');
index2 = strfind(mibVersionString, '/');

% look for beta keyword
% expected syntax "ver. 2.909 (beta 04) / 06.08.2024"
index3 = strfind(mibVersionString, 'beta');

if isempty(index3) % release, no beta
    mibVersionNumeric = str2double(mibVersionString(index1+4:index2-1));
else % for beta version mibVersionNumeric is calculated as the version - beta/10000
    index4 = strfind(mibVersionString, ')');
    mibVersionNumeric = ...
        str2double(mibVersionString(index1+4:index3-2)) - ...
        (1000-str2double(mibVersionString(index3+4:index4-1)))/1000000;
end

end