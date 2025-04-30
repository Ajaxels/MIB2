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

function KeyShortcuts = generateDefaultKeyShortcuts()
% function KeyShortcuts = generateDefaultKeyShortcuts()
% generate KeyShortcuts structure with defauld key shortcuts

% define keyboard shortcuts
maxShortCutIndex = 45;  % total number of shortcuts

KeyShortcuts.shift(1:maxShortCutIndex) = 0;
KeyShortcuts.overrideShift(1:maxShortCutIndex) = 0;     % here should be indices of operations that are used with Shifts, such as shift+a, shift+s...
KeyShortcuts.control(1:maxShortCutIndex) = 0;
KeyShortcuts.alt(1:maxShortCutIndex) = 0;
KeyShortcuts.overrideAlt(1:maxShortCutIndex) = 0;     % here should be indices of operations that are used with Alt, such as alt+a...

KeyShortcuts.Key{1} = '1';
KeyShortcuts.Action{1} = 'Switch dataset to XY orientation';
KeyShortcuts.alt(1) = 1;

KeyShortcuts.Key{2} = '2';
KeyShortcuts.Action{2} = 'Switch dataset to ZY orientation';
KeyShortcuts.alt(2) = 1;

KeyShortcuts.Key{3} = '3';
KeyShortcuts.Action{3} = 'Switch dataset to ZX orientation';
KeyShortcuts.alt(3) = 1;

KeyShortcuts.Key{4} = 'i';
KeyShortcuts.Action{4} = 'Interpolate selection';

KeyShortcuts.Key{5} = 'i';
KeyShortcuts.Action{5} = 'Invert image';
KeyShortcuts.control(5) = 1;

KeyShortcuts.Key{6} = 'a';
KeyShortcuts.Action{6} = 'Add to selection to material';
KeyShortcuts.overrideShift(6) = 1;

KeyShortcuts.Key{7} = 's';
KeyShortcuts.Action{7} = 'Subtract from material';
KeyShortcuts.overrideShift(7) = 1;
KeyShortcuts.overrideAlt(7) = 1;

KeyShortcuts.Key{8} = 'r';
KeyShortcuts.Action{8} = 'Replace material with current selection';
KeyShortcuts.overrideShift(8) = 1;
KeyShortcuts.overrideAlt(8) = 1;

KeyShortcuts.Key{9} = 'c';
KeyShortcuts.Action{9} = 'Clear selection';
KeyShortcuts.overrideShift(9) = 1;
KeyShortcuts.overrideAlt(9) = 1;

KeyShortcuts.Key{10} = 'f';
KeyShortcuts.Action{10} = 'Fill the holes in the Selection layer';
KeyShortcuts.overrideShift(10) = 1;
KeyShortcuts.overrideAlt(10) = 1;

KeyShortcuts.Key{11} = 'z';
KeyShortcuts.Action{11} = 'Erode the Selection layer';
KeyShortcuts.overrideShift(11) = 1;
KeyShortcuts.overrideAlt(11) = 1;

KeyShortcuts.Key{12} = 'x';
KeyShortcuts.Action{12} = 'Dilate the Selection layer';
KeyShortcuts.overrideShift(12) = 1;
KeyShortcuts.overrideAlt(12) = 1;

KeyShortcuts.Key{13} = 'q';
KeyShortcuts.Action{13} = 'Zoom out/Previous slice';
KeyShortcuts.overrideShift(13) = 1;
KeyShortcuts.overrideAlt(13) = 1;

KeyShortcuts.Key{14} = 'w';
KeyShortcuts.Action{14} = 'Zoom in/Next slice';
KeyShortcuts.overrideShift(14) = 1;
KeyShortcuts.overrideAlt(14) = 1;

KeyShortcuts.Key{15} = 'downarrow';
KeyShortcuts.Action{15} = 'Previous slice';
KeyShortcuts.overrideShift(15) = 1;

KeyShortcuts.Key{16} = 'uparrow';
KeyShortcuts.Action{16} = 'Next slice';
KeyShortcuts.overrideShift(16) = 1;

KeyShortcuts.Key{17} = 'space';
KeyShortcuts.Action{17} = 'Show/hide the Model layer';

KeyShortcuts.Key{18} = 'space';
KeyShortcuts.Action{18} = 'Show/hide the Mask layer';
KeyShortcuts.control(18) = 1;

KeyShortcuts.Key{19} = 'space';
KeyShortcuts.Action{19} = 'Fix selection to material';
KeyShortcuts.shift(19) = 1;

KeyShortcuts.Key{20} = 's';
KeyShortcuts.Action{20} = 'Save image as...';
KeyShortcuts.control(20) = 1;

KeyShortcuts.Key{21} = 'c';
KeyShortcuts.Action{21} = 'Copy to buffer selection from the current slice';
KeyShortcuts.control(21) = 1;

KeyShortcuts.Key{22} = 'v';
KeyShortcuts.Action{22} = 'Paste buffered selection to the current slice';
KeyShortcuts.control(22) = 1;

KeyShortcuts.Key{23} = 'e';
KeyShortcuts.Action{23} = 'Toggle between the selected material and exterior';

KeyShortcuts.Key{24} = 'd';
KeyShortcuts.Action{24} = 'Loop through the list of favourite segmentation tools';

KeyShortcuts.Key{25} = 'leftarrow';
KeyShortcuts.Action{25} = 'Previous time point';

KeyShortcuts.Key{26} = 'rightarrow';
KeyShortcuts.Action{26} = 'Next time point';

KeyShortcuts.Key{27} = 'z';
KeyShortcuts.Action{27} = 'Undo/Redo last action';
KeyShortcuts.control(27) = 1;

KeyShortcuts.Key{28} = 'f';
KeyShortcuts.Action{28} = 'Find material under cursor';
KeyShortcuts.control(28) = 1;

KeyShortcuts.Key{29} = 'v';
KeyShortcuts.Action{29} = 'Paste buffered selection to all slices';
KeyShortcuts.control(29) = 1;
KeyShortcuts.shift(29) = 1;

KeyShortcuts.Key{30} = 'm';
KeyShortcuts.Action{30} = 'Add measurement (Measure tool)';

KeyShortcuts.Key{31} = 'e';
KeyShortcuts.control(31) = 1;
KeyShortcuts.Action{31} = 'Toggle current and previous buffer';

KeyShortcuts.Key{32} = '';
KeyShortcuts.Action{32} = 'Zoom to 100% view';

KeyShortcuts.Key{33} = '';
KeyShortcuts.Action{33} = 'Zoom to fit the view';

KeyShortcuts.Key{34} = 'leftbracket';
KeyShortcuts.Action{34} = 'Brush size decrease';
KeyShortcuts.overrideShift(34) = 1;

KeyShortcuts.Key{35} = 'rightbracket';
KeyShortcuts.Action{35} = 'Brush size increase';
KeyShortcuts.overrideShift(35) = 1;

KeyShortcuts.Key{36} = 'f2';
KeyShortcuts.Action{36} = 'Rename material';

KeyShortcuts.Key{37} = '1';
KeyShortcuts.Action{37} = 'Preset 1 use for the selected segmentation tool';

KeyShortcuts.Key{38} = '2';
KeyShortcuts.Action{38} = 'Preset 2 use for the selected segmentation tool';

KeyShortcuts.Key{39} = '3';
KeyShortcuts.Action{39} = 'Preset 3 use for the selected segmentation tool';

KeyShortcuts.Key{40} = '1';
KeyShortcuts.Action{40} = 'Preset 1 update from the selected segmentation tool';
KeyShortcuts.shift(40) = 1;

KeyShortcuts.Key{41} = '2';
KeyShortcuts.Action{41} = 'Preset 2 update from the selected segmentation tool';
KeyShortcuts.shift(41) = 1;

KeyShortcuts.Key{42} = '3';
KeyShortcuts.Action{42} = 'Preset 3 update from the selected segmentation tool';
KeyShortcuts.shift(42) = 1;

KeyShortcuts.Key{43} = 'd';
KeyShortcuts.Action{43} = 'Favorite tool A';
KeyShortcuts.shift(43) = 1;

KeyShortcuts.Key{44} = 'd';
KeyShortcuts.Action{44} = 'Favorite tool B';
KeyShortcuts.control(44) = 1;

% add a new key shortcut to the end of the list
KeyShortcuts.Key{maxShortCutIndex} = 'n';
KeyShortcuts.Action{maxShortCutIndex} = 'Increse active material index by 1 for models with 65535 materials';

% resort the shortcuts to be alphabetical
[KeyShortcuts.Action, sortedIds] = sort(KeyShortcuts.Action);
KeyShortcuts.shift = KeyShortcuts.shift(sortedIds);
KeyShortcuts.overrideShift = KeyShortcuts.overrideShift(sortedIds);
KeyShortcuts.control = KeyShortcuts.control(sortedIds);
KeyShortcuts.alt = KeyShortcuts.alt(sortedIds);
KeyShortcuts.overrideAlt = KeyShortcuts.overrideAlt(sortedIds);
KeyShortcuts.Key = KeyShortcuts.Key(sortedIds);

