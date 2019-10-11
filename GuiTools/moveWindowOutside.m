function hObject = moveWindowOutside(hObject, alignH, alignV)
% function hObject = moveWindowOutside(hObject, alignH, alignV)
% Determine the position of the dialog - on a side of the main figure
% if available, else, centered on the main figure
% Parameters:
% hObject: a handle of the window to be moved
% alignH: an optional string with the preferred horizontal alignment: 'left' (@em default), 'right', 'center'
% alignV: an optional string with the preferred vertical alignment: 'top' (@em default), 'bottom', 'center'

if nargin < 3; alignV = 'top'; end
if nargin < 2; alignH = 'left'; end
if isempty(alignH); alignH = 'left'; end

if ismember(alignH, {'left', 'right', 'center'}) == 0
    warndlg('Wrong alignH parameter; alignH should be one of those: ''left'',''right'',''center''', 'moveWindowOutside');
    alignH = 'left';
end

if ismember(alignV, {'top', 'bottom', 'center'}) == 0
    warndlg('Wrong alignH parameter; alignV should be one of those: ''top'',''bottom'',''center''', 'moveWindowOutside');
    alignV = 'top';
end

OldUnits = hObject.Units;
hObject.Units = 'pixels';
OldPos = hObject.OuterPosition;
FigWidth = OldPos(3);   % width of the window to move
FigHeight = OldPos(4);  % height of the window to move

if isempty(gcbf)    % can't obtain info about parent window
    ScreenUnits=get(0, 'Units');
    set(0, 'Units', 'pixels');
    ScreenSize = get(0, 'ScreenSize');
    set(0, 'Units', ScreenUnits);
    
    FigPos(1) = 1/2*(ScreenSize(3)-FigWidth);
    FigPos(2) = 2/3*(ScreenSize(4)-FigHeight);
else
    GCBFOldUnits = get(gcbf, 'Units');
    set(gcbf, 'Units', 'pixels');
    GCBFPos = get(gcbf, 'OuterPosition');   % parent window position
    set(gcbf, 'Units', GCBFOldUnits);
    screenSize = get(0, 'ScreenSize');  
    
    switch alignH
        case 'left'
            if GCBFPos(1)-FigWidth > 0 % put figure on the left side of the main figure
                FigPos(1) = GCBFPos(1)-FigWidth;
            elseif GCBFPos(1) + GCBFPos(3) + FigWidth < screenSize(3) % put figure on the right side of the main figure
                FigPos(1) = GCBFPos(1)+GCBFPos(3);
            else
                FigPos(1) = (GCBFPos(1) + GCBFPos(3) / 2) - FigWidth / 2;
                alignV = 'center';
            end
        case 'right'
            if GCBFPos(1) + GCBFPos(3) + FigWidth < screenSize(3) % put figure on the right side of the main figure
                FigPos(1) = GCBFPos(1)+GCBFPos(3);
            elseif GCBFPos(1)-FigWidth > 0 % put figure on the left side of the main figure
                FigPos(1) = GCBFPos(1)-FigWidth;
            else
                FigPos(1) = (GCBFPos(1) + GCBFPos(3) / 2) - FigWidth / 2;
                alignV = 'center';
            end
        case 'center'
            FigPos(1) = (GCBFPos(1) + GCBFPos(3) / 2) - FigWidth / 2;
    end
    
    switch alignV
        case 'top'
            FigPos(2) = GCBFPos(2)+GCBFPos(4)-FigHeight;
        case 'bottom'
            FigPos(2) = GCBFPos(2) - FigHeight;
        case 'center'
            FigPos(2) = (GCBFPos(2) + GCBFPos(4) / 2) - FigHeight / 2;
    end
end
FigPos(3:4)=[FigWidth FigHeight];

try
    hObject.OuterPosition = FigPos;
catch
    FigPos(2) = FigPos(2) - 32;
    hObject.Position = FigPos;
end
hObject.Units = OldUnits;
end