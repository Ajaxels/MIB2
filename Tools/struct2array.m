function result = struct2array(S)
% function result = struct2array(S)
% replacement for struct2array function that was present is Matlab before
% R2021b (at least)
%
% Parameters:
% S: input structure
%
% Return values:
% result: array with values

% Convert structure to cell
c = struct2cell(S);

% generate an array
result = [c{:}];