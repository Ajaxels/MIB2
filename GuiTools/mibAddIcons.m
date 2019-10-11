function mibAddIcons(handles)
% function mibAddIcons(handles)
% add icons to the menus

% Copyright (C) 14.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% add icons to buttons
global mibPath;

%% Old code for adding icons to buttons, does not work from R2019b, instead
% changed to CData, see mibController/add icons for buttons section for details
% on PC path is file://c:/... or //ad.xxxxx.xxx.xx
% on Mac file:///Volumes/Transcend/...

% if ispc
%     if mibPath(1) == '\'; fileText = 'file:'; else; fileText = 'file:/'; end    % check for a installation in the network path \\ad.xxxx
% else
%     fileText = 'file://';
% end
% 
% btnText = strrep([fileText fullfile(mibPath, 'Resources', 'minus.png')],'\','/'); 
% btnText = ['<html><img src="' btnText '"/></html>']; 
% handles.mibRemoveMaterialBtn.String = btnText;
% 
% % add icon to the preview button
% btnText = strrep([fileText fullfile(mibPath, 'Resources', 'settings.gif')],'\','/'); 
% btnText = ['<html><img src="' btnText '"/></html>']; 
% handles.mibBrushPanelInterpolationSettingsBtn.String = btnText;

%%
%jFrame = handles.mibGUI.JavaFrame;
jFrame = get(handle(handles.mibGUI), 'JavaFrame');
try
    if handles.mibController.matlabVersion >= 8.4     % R2014b at least
        jMenuBar = jFrame.fHG2Client.getMenuBar;
    else
    % R2008a and later
        jMenuBar = jFrame.fHG1Client.getMenuBar;
    end
catch
    % R2007b and earlier
    jMenuBar = jFrame.fFigureClient.getMenuBar;
end
resourcesPath = fullfile(handles.mibController.mibPath, 'Resources');

jFileMenu = jMenuBar.getComponent(0);
jFileMenu.doClick; % open the File menu
drawnow;    % set delay
jFileMenu.doClick; % close the menu
drawnow;    % set delay
    Item = jFileMenu.getMenuComponent(0);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'importmatlab2.png')));
    Item = jFileMenu.getMenuComponent(1);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'omero.png')));
    Item = jFileMenu.getMenuComponent(3);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'protocol.png')));
    Item = jFileMenu.getMenuComponent(4);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'chop.png')));
    Item = jFileMenu.getMenuComponent(5);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'shuffle.png')));
    Item = jFileMenu.getMenuComponent(7);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'exportmatlab2.png')));
    Item = jFileMenu.getMenuComponent(8);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'saveas.png')));
    Item = jFileMenu.getMenuComponent(9);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'makevideo.png')));
    Item = jFileMenu.getMenuComponent(10);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'snapshot.png')));
    Item = jFileMenu.getMenuComponent(12);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'render.png')));
    Item = jFileMenu.getMenuComponent(14);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'preferences.png')));
    
jDatasetMenu = jMenuBar.getComponent(1);
jDatasetMenu.doClick; % open the Dataset menu
drawnow;    % set delay
jDatasetMenu.doClick; % close the menu
drawnow;    % set delay
    Item = jDatasetMenu.getMenuComponent(0);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'align.png')));
    Item = jDatasetMenu.getMenuComponent(2);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'crop.png')));
    Item = jDatasetMenu.getMenuComponent(3);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'resample.png')));
    Item = jDatasetMenu.getMenuComponent(4);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'transform.png')));
    Item = jDatasetMenu.getMenuComponent(5);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'slice.png')));
    Item = jDatasetMenu.getMenuComponent(7);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'scalebar.png')));
    Item = jDatasetMenu.getMenuComponent(8);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'boundingbox.png')));
    Item = jDatasetMenu.getMenuComponent(9);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'parameters.png')));

jImageMenu = jMenuBar.getComponent(2);
jImageMenu.doClick; % open the Image menu
drawnow;    % set delay
jImageMenu.doClick; % close the menu
drawnow;    % set delay

    Item = jImageMenu.getMenuComponent(0);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'changemode.png')));
    Item = jImageMenu.getMenuComponent(1);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'colorchannels.png')));
    Item = jImageMenu.getMenuComponent(2);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'contrast.png')));
    Item = jImageMenu.getMenuComponent(3);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'invert.png')));
    Item = jImageMenu.getMenuComponent(5);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'tools.png')));
    Item = jImageMenu.getMenuComponent(6);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'morph_ops.png')));
    Item = jImageMenu.getMenuComponent(8);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'intensity.png')));
    
jModelMenu = jMenuBar.getComponent(3);
jModelMenu.doClick; % open the Models menu
drawnow;    % set delay
jModelMenu.doClick; % close the menu
drawnow;    % set delay
    Item = jModelMenu.getMenuComponent(0);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'convertmodel.png')));    
    Item = jModelMenu.getMenuComponent(2);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'new.png')));    
    Item = jModelMenu.getMenuComponent(3);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'load.png')));    
    Item = jModelMenu.getMenuComponent(4);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'importmatlab2.png')));    
    Item = jModelMenu.getMenuComponent(6);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'exportmatlab2.png')));    
    Item = jModelMenu.getMenuComponent(7);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'save.png')));    
    Item = jModelMenu.getMenuComponent(8);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'saveas.png')));    
    Item = jModelMenu.getMenuComponent(10);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'render.png')));        
    Item = jModelMenu.getMenuComponent(12);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'notes.png'))); 
    Item = jModelMenu.getMenuComponent(13);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'statistics.png'))); 

jMaskMenu = jMenuBar.getComponent(4);
jMaskMenu.doClick; % open the Mask menu
drawnow;    % set delay
jMaskMenu.doClick; % close the menu
drawnow;    % set delay

    Item = jMaskMenu.getMenuComponent(0);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'copylayers.png')));     
    Item = jMaskMenu.getMenuComponent(1);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'clear.png')));     
    Item = jMaskMenu.getMenuComponent(2);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'load.png')));  
    Item = jMaskMenu.getMenuComponent(3);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'importmatlab2.png')));   
    Item = jMaskMenu.getMenuComponent(5);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'exportmatlab2.png')));   
    Item = jMaskMenu.getMenuComponent(6);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'saveas.png')));   
    Item = jMaskMenu.getMenuComponent(8);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'invert.png')));   
    Item = jMaskMenu.getMenuComponent(9);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'replacecolor.png')));
    Item = jMaskMenu.getMenuComponent(10);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'smooth.png')));
    Item = jMaskMenu.getMenuComponent(12);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'statistics.png')));

jSelMenu = jMenuBar.getComponent(5);
jSelMenu.doClick; % open the Selection menu
drawnow;    % set delay
jSelMenu.doClick; % close the menu
drawnow;    % set delay
    Item = jSelMenu.getMenuComponent(0);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'buffer.png')));       
    Item = jSelMenu.getMenuComponent(1);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'copylayers.png')));       
    Item = jSelMenu.getMenuComponent(2);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'morph_ops.png'))); 
    Item = jSelMenu.getMenuComponent(4);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'expand.png')));
    Item = jSelMenu.getMenuComponent(5);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'interpolation.png')));
    Item = jSelMenu.getMenuComponent(6);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'replacecolor.png')));
    Item = jSelMenu.getMenuComponent(7);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'smooth.png')));
    Item = jSelMenu.getMenuComponent(8);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'invert.png')));

jMeasureMenu = jMenuBar.getComponent(6);
jMeasureMenu.doClick; % open the Tools menu
drawnow;    % set delay
jMeasureMenu.doClick; % close the menu
drawnow;    % set delay
    Item = jMeasureMenu.getMenuComponent(0);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'linemeasure.png')));     
    Item = jMeasureMenu.getMenuComponent(1);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'randomforest.png')));     
    Item = jMeasureMenu.getMenuComponent(2);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'semiauto.png')));     
    Item = jMeasureMenu.getMenuComponent(3);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'watershed.png')));     
    Item = jMeasureMenu.getMenuComponent(4);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'stereology.png')));     
    
jHelpMenu = jMenuBar.getComponent(8);
jHelpMenu.doClick; % open the Help menu
drawnow;    % set delay
jHelpMenu.doClick; % close the menu
drawnow;    % set delay
    Item = jHelpMenu.getMenuComponent(0);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'help.png')));
    Item = jHelpMenu.getMenuComponent(1);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'lamp.png')));
    Item = jHelpMenu.getMenuComponent(2);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'image-sc.png')));
    Item = jHelpMenu.getMenuComponent(3);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'classhelp.png')));
    Item = jHelpMenu.getMenuComponent(5);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'update.png')));
    Item = jHelpMenu.getMenuComponent(7);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'copyright.png')));
    Item = jHelpMenu.getMenuComponent(8);
    Item.setIcon(javax.swing.ImageIcon(fullfile(resourcesPath, 'about.png')));

% unselect Help entry
jHelpMenu.setSelected(false);
end


