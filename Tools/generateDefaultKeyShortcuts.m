function KeyShortcuts = generateDefaultKeyShortcuts()
% function KeyShortcuts = generateDefaultKeyShortcuts()
% generate KeyShortcuts structure with defauld key shortcuts

% Copyright (C) 04.12.2020 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.

% define keyboard shortcuts
maxShortCutIndex = 32;  % total number of shortcuts

KeyShortcuts.shift(1:maxShortCutIndex) = 0;
KeyShortcuts.control(1:maxShortCutIndex) = 0;
KeyShortcuts.alt(1:maxShortCutIndex) = 0;

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

KeyShortcuts.Key{7} = 's';
KeyShortcuts.Action{7} = 'Subtract from material';

KeyShortcuts.Key{8} = 'r';
KeyShortcuts.Action{8} = 'Replace material with current selection';

KeyShortcuts.Key{9} = 'c';
KeyShortcuts.Action{9} = 'Clear selection';

KeyShortcuts.Key{10} = 'f';
KeyShortcuts.Action{10} = 'Fill the holes in the Selection layer';

KeyShortcuts.Key{11} = 'z';
KeyShortcuts.Action{11} = 'Erode the Selection layer';

KeyShortcuts.Key{12} = 'x';
KeyShortcuts.Action{12} = 'Dilate the Selection layer';

KeyShortcuts.Key{13} = 'q';
KeyShortcuts.Action{13} = 'Zoom out/Previous slice';

KeyShortcuts.Key{14} = 'w';
KeyShortcuts.Action{14} = 'Zoom in/Next slice';

KeyShortcuts.Key{15} = 'downarrow';
KeyShortcuts.Action{15} = 'Previous slice';

KeyShortcuts.Key{16} = 'uparrow';
KeyShortcuts.Action{16} = 'Next slice';

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

% add a new key shortcut to the end of the list
KeyShortcuts.Key{maxShortCutIndex} = 'n';
KeyShortcuts.Action{maxShortCutIndex} = 'Increse active material index by 1 for models with 65535 materials';



