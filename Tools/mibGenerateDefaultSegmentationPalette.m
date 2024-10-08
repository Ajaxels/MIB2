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
% Date: 28.08.2023

function palette = mibGenerateDefaultSegmentationPalette(paletteName, colorsNo)
% function palette = mibGenerateDefaultSegmentationPalette(paletteName, colorsNo)
% generate color palette depending on the provided paletteName and required noColors
%
% Parameters:
% paletteName: string with the name of the palette to use, see below for
% the options
% colorsNo: numeric, number of required color channels
%
% Return values:
% palette: matrix [colorId][R G B] in range from 0 to 1 with colors

% Updates
% 240605: added definition of the color seed for the random palette generator


global mibPath;

if nargin < 2; colorsNo = 6; end
if nargin < 1; paletteName = 'Default, 6 colors'; end

palette = [];

switch paletteName
    case 'Default, 6 colors'
        palette = [166 67 33; 79 107 171; 255 204 102; 150 169 213; 71 178 126; 26 51 111]/255;
    case 'Distinct colors, 20 colors'
        %palette = [255 80 5; 255 255 128; 116 10 255; 0 153 143; 66 102 0; 255 168 187; 0 51 128; 194 0 136; 143 124 0; 148 255 181; 255 204 153; 76 0 92; 153 63 0; 0 117 220; 240 163 255; 255 255 0; 153 0 0; 94 241 242; 255 0 16; 255 164 5; 157 204 0; 224 255 102; 0 92 49; 25 25 25; 43 206 72; 128 128 128; 255 255 255]/255;
        palette = [230 25 75; 255 225 25; 0 130 200; 245 130 48; 145 30 180; 70 240 240; 240 50 230; 210 245 60; 250 190 190; 0 128 128; 230 190 255; 170 110 40; 255 250 200; 128 0 0; 170 255 195; 128 128 0; 255 215 180; 0 0 128; 128 128 128; 60 180 75]/255;
    case 'Qualitative (Monte Carlo->Half Baked), 3-12 colors'
        switch colorsNo
            case 3; palette = [141,211,199; 255,255,179; 190,186,218]/255;
            case 4; palette = [141,211,199; 255,255,179; 190,186,218; 251,128,114]/255;
            case 5; palette = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211]/255;
            case 6; palette = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98]/255;
            case 7; palette = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98; 179,222,105]/255;
            case 8; palette = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98; 179,222,105; 252,205,229]/255;
            case 9; palette = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98; 179,222,105; 252,205,229; 217,217,217]/255;
            case 10; palette = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98; 179,222,105; 252,205,229; 217,217,217; 188,128,189]/255;
            case 11; palette = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98; 179,222,105; 252,205,229; 217,217,217; 188,128,189; 204,235,197]/255;
            otherwise; palette = [141,211,199; 255,255,179; 190,186,218; 251,128,114; 128,177,211; 253,180,98; 179,222,105; 252,205,229; 217,217,217; 188,128,189; 204,235,197; 255,237,111]/255;
        end
    case 'Diverging (Deep Bronze->Deep Teal), 3-11 colors'
        switch colorsNo
            case 3; palette = [216,179,101; 245,245,245; 90,180,172]/255;
            case 4; palette = [166,97,26; 223,194,125; 128,205,193; 1,133,113]/255;
            case 5; palette = [166,97,26; 223,194,125; 245,245,245; 128,205,193; 1,133,113]/255;
            case 6; palette = [140,81,10; 216,179,101; 246,232,195; 199,234,229; 90,180,172; 1,102,94]/255;
            case 7; palette = [140,81,10; 216,179,101; 246,232,195; 245,245,245; 199,234,229; 90,180,172; 1,102,94]/255;
            case 8; palette = [140,81,10; 191,129,45; 223,194,125; 246,232,195; 199,234,229; 128,205,193; 53,151,143; 1,102,94]/255;
            case 9; palette = [140,81,10; 191,129,45; 223,194,125; 246,232,195; 245,245,245; 199,234,229; 128,205,193; 53,151,143; 1,102,94]/255;
            case 10; palette = [84,48,5; 140,81,10; 191,129,45; 223,194,125; 246,232,195; 199,234,229; 128,205,193; 53,151,143; 1,102,94; 0,60,48]/255;
            otherwise; palette = [84,48,5; 140,81,10; 191,129,45; 223,194,125; 246,232,195; 245,245,245; 199,234,229; 128,205,193; 53,151,143; 1,102,94; 0,60,48]/255;
        end
    case 'Diverging (Ripe Plum->Kaitoke Green), 3-11 colors'
        switch colorsNo
            case 3; palette = [175,141,195; 247,247,247; 127,191,123]/255;
            case 4; palette = [123,50,148; 194,165,207; 166,219,160; 0,136,55]/255;
            case 5; palette = [123,50,148; 194,165,207; 247,247,247; 166,219,160; 0,136,55]/255;
            case 6; palette = [118,42,131; 175,141,195; 231,212,232; 217,240,211; 127,191,123; 27,120,55]/255;
            case 7; palette = [118,42,131; 175,141,195; 231,212,232; 247,247,247; 217,240,211; 127,191,123; 27,120,55]/255;
            case 8; palette = [118,42,131; 153,112,171; 194,165,207; 231,212,232; 217,240,211; 166,219,160; 90,174,97; 27,120,55]/255;
            case 9; palette = [118,42,131; 153,112,171; 194,165,207; 231,212,232; 247,247,247; 217,240,211; 166,219,160; 90,174,97; 27,120,55]/255;
            case 10; palette = [64,0,75; 118,42,131; 153,112,171; 194,165,207; 231,212,232; 217,240,211; 166,219,160; 90,174,97; 27,120,55; 0,68,27]/255;
            otherwise; palette = [64,0,75; 118,42,131; 153,112,171; 194,165,207; 231,212,232; 247,247,247; 217,240,211; 166,219,160; 90,174,97; 27,120,55; 0,68,27]/255;
        end
    case 'Diverging (Bordeaux->Green Vogue), 3-11 colors'
        switch colorsNo
            case 3; palette = [239,138,98; 247,247,247; 103,169,207]/255;
            case 4; palette = [202,0,32; 244,165,130; 146,197,222; 5,113,176]/255;
            case 5; palette = [202,0,32; 244,165,130; 247,247,247; 146,197,222; 5,113,176]/255;
            case 6; palette = [178,24,43; 239,138,98; 253,219,199; 209,229,240; 103,169,207; 33,102,172]/255;
            case 7; palette = [178,24,43; 239,138,98; 253,219,199; 247,247,247; 209,229,240; 103,169,207; 33,102,172]/255;
            case 8; palette = [178,24,43; 214,96,77; 244,165,130; 253,219,199; 209,229,240; 146,197,222; 67,147,195; 33,102,172]/255;
            case 9; palette = [178,24,43; 214,96,77; 244,165,130; 253,219,199; 247,247,247; 209,229,240; 146,197,222; 67,147,195; 33,102,172]/255;
            case 10; palette = [103,0,31; 178,24,43; 214,96,77; 244,165,130; 253,219,199; 209,229,240; 146,197,222; 67,147,195; 33,102,172; 5,48,97]/255;
            otherwise; palette = [103,0,31; 178,24,43; 214,96,77; 244,165,130; 253,219,199; 247,247,247; 209,229,240; 146,197,222; 67,147,195; 33,102,172; 5,48,97]/255;
        end
    case 'Diverging (Carmine->Bay of Many), 3-11 colors'
        switch colorsNo
            case 3; palette = [252,141,89; 255,255,191; 145,191,219]/255;
            case 4; palette = [215,25,28; 253,174,97; 171,217,233; 44,123,182]/255;
            case 5; palette = [215,25,28; 253,174,97; 255,255,191; 171,217,233; 44,123,182]/255;
            case 6; palette = [215,48,39; 252,141,89; 254,224,144; 224,243,248; 145,191,219; 69,117,180]/255;
            case 7; palette = [215,48,39; 252,141,89; 254,224,144; 255,255,191; 224,243,248; 145,191,219; 69,117,180]/255;
            case 8; palette = [215,48,39; 244,109,67; 253,174,97; 254,224,144; 224,243,248; 171,217,233; 116,173,209; 69,117,180]/255;
            case 9; palette = [215,48,39; 244,109,67; 253,174,97; 254,224,144; 255,255,191; 224,243,248; 171,217,233; 116,173,209; 69,117,180]/255;
            case 10; palette = [165,0,38; 215,48,39; 244,109,67; 253,174,97; 254,224,144; 224,243,248; 171,217,233; 116,173,209; 69,117,180; 49,54,149]/255;
            otherwise; palette = [165,0,38; 215,48,39; 244,109,67; 253,174,97; 254,224,144; 255,255,191; 224,243,248; 171,217,233; 116,173,209; 69,117,180; 49,54,149]/255;
        end
    case 'Sequential (Kaitoke Green), 3-9 colors'
        switch colorsNo
            case 3; palette = [229,245,249; 153,216,201; 44,162,95]/255;
            case 4; palette = [237,248,251; 178,226,226; 102,194,164; 35,139,69]/255;
            case 5; palette = [237,248,251; 178,226,226; 102,194,164; 44,162,95; 0,109,44]/255;
            case 6; palette = [237,248,251; 204,236,230; 153,216,201; 102,194,164; 44,162,95; 0,109,44]/255;
            case 7; palette = [237,248,251; 204,236,230; 153,216,201; 102,194,164; 65,174,118; 35,139,69; 0,88,36]/255;
            case 8; palette = [247,252,253; 229,245,249; 204,236,230; 153,216,201; 102,194,164; 65,174,118; 35,139,69; 0,88,36]/255;
            otherwise; palette = [247,252,253; 229,245,249; 204,236,230; 153,216,201; 102,194,164; 65,174,118; 35,139,69; 0,109,44; 0,68,27]/255;
        end
    case 'Sequential (Catalina Blue), 3-9 colors'
        switch colorsNo
            case 3; palette = [224,243,219; 168,221,181; 67,162,202]/255;
            case 4; palette = [240,249,232; 186,228,188; 123,204,196; 43,140,190]/255;
            case 5; palette = [240,249,232; 186,228,188; 123,204,196; 67,162,202; 8,104,172]/255;
            case 6; palette = [240,249,232; 204,235,197; 168,221,181; 123,204,196; 67,162,202; 8,104,172]/255;
            case 7; palette = [240,249,232; 204,235,197; 168,221,181; 123,204,196; 78,179,211; 43,140,190; 8,88,158]/255;
            case 8; palette = [247,252,240; 224,243,219; 204,235,197; 168,221,181; 123,204,196; 78,179,211; 43,140,190; 8,88,158]/255;
            otherwise; palette = [247,252,240; 224,243,219; 204,235,197; 168,221,181; 123,204,196; 78,179,211; 43,140,190; 8,104,172; 8,64,129]/255;
        end
    case 'Sequential (Maroon), 3-9 colors'
        switch colorsNo
            case 3; palette = [254,232,200; 253,187,132; 227,74,51]/255;
            case 4; palette = [254,240,217; 253,204,138; 252,141,89; 215,48,31]/255;
            case 5; palette = [254,240,217; 253,204,138; 252,141,89; 227,74,51; 179,0,0]/255;
            case 6; palette = [254,240,217; 253,212,158; 253,187,132; 252,141,89; 227,74,51; 179,0,0]/255;
            case 7; palette = [254,240,217; 253,212,158; 253,187,132; 252,141,89; 239,101,72; 215,48,31; 153,0,0]/255;
            case 8; palette = [255,247,236; 254,232,200; 253,212,158; 253,187,132; 252,141,89; 239,101,72; 215,48,31; 153,0,0]/255;
            otherwise; palette = [255,247,236; 254,232,200; 253,212,158; 253,187,132; 252,141,89; 239,101,72; 215,48,31; 179,0,0; 127,0,0]/255;
        end
    case 'Sequential (Astronaut Blue), 3-9 colors'
        switch colorsNo
            case 3; palette = [236,231,242; 166,189,219; 43,140,190]/255;
            case 4; palette = [241,238,246; 189,201,225; 116,169,207; 5,112,176]/255;
            case 5; palette = [241,238,246; 189,201,225; 116,169,207; 43,140,190; 4,90,141]/255;
            case 6; palette = [241,238,246; 208,209,230; 166,189,219; 116,169,207; 43,140,190; 4,90,141]/255;
            case 7; palette = [241,238,246; 208,209,230; 166,189,219; 116,169,207; 54,144,192; 5,112,176; 3,78,123]/255;
            case 8; palette = [255,247,251; 236,231,242; 208,209,230; 166,189,219; 116,169,207; 54,144,192; 5,112,176; 3,78,123]/255;
            otherwise; palette = [255,247,251; 236,231,242; 208,209,230; 166,189,219; 116,169,207; 54,144,192; 5,112,176; 4,90,141; 2,56,88]/255;
        end
    case 'Sequential (Downriver), 3-9 colors'
        switch colorsNo
            case 3; palette = [237,248,177; 127,205,187; 44,127,184]/255;
            case 4; palette = [255,255,204; 161,218,180; 65,182,196; 34,94,168]/255;
            case 5; palette = [255,255,204; 161,218,180; 65,182,196; 44,127,184; 37,52,148]/255;
            case 6; palette = [255,255,204; 199,233,180; 127,205,187; 65,182,196; 44,127,184; 37,52,148]/255;
            case 7; palette = [255,255,204; 199,233,180; 127,205,187; 65,182,196; 29,145,192; 34,94,168; 12,44,132]/255;
            case 8; palette = [255,255,217; 237,248,177; 199,233,180; 127,205,187; 65,182,196; 29,145,192; 34,94,168; 12,44,132]/255;
            otherwise; palette = [255,255,217; 237,248,177; 199,233,180; 127,205,187; 65,182,196; 29,145,192; 34,94,168; 37,52,148; 8,29,88]/255;
        end
    case 'Matlab Jet'
        palette =  colormap(jet(colorsNo));
    case 'Matlab Gray'
        palette =  colormap(gray(colorsNo));
    case 'Matlab Bone'
        palette =  colormap(bone(colorsNo));
    case 'Matlab HSV'
        palette =  colormap(hsv(colorsNo));
    case 'Matlab Cool'
        palette =  colormap(cool(colorsNo));
    case 'Matlab Hot'
        palette =  colormap(hot(colorsNo));
    case 'Random Colors'
        rng('shuffle');     % randomize generator
        randomSeed = round(rand()*100000);
        prompts = {'Random seed number';};
        defAns = {num2str(randomSeed)};
        dlgTitle = 'Specify random seed';
        answer = mibInputMultiDlg({mibPath}, prompts, defAns, dlgTitle);
        if isempty(answer); return; end

        rng(str2double(answer{1}), 'twister');
        palette =  colormap(rand([colorsNo,3]));
end

% add random colors to the palette
if size(palette, 1) < colorsNo
    rng('shuffle');     % randomize generator
    palette2 =  colormap(rand([colorsNo-size(palette, 1), 3]));
    palette = [palette; palette2];
end
