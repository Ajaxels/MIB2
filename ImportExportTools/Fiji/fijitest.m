function fijitest(handles)

if exist('MIJ','class') == 8
    if ~isempty(ij.gui.Toolbar.getInstance)
        ij_instance = char(ij.gui.Toolbar.getInstance.toString);
        % -> ij.gui.Toolbar[canvas1,3,41,548x27,invalid]
        if numel(strfind(ij_instance, 'invalid')) > 0    % instance already exist, but not shown
            Miji_wrapper(true);     % wrapper to Miji.m file
        end
    else
        Miji_wrapper(true);     % wrapper to Miji.m file
    end
else
    Miji_wrapper(true);     % wrapper to Miji.m file
end

%img = zeros([512, 512, 10],'uint8');
%for i=1:size(img,3)
%    img(:,:,i) = uint8(randi(255,[512,512]));
%end
img = handles.Img{handles.Id}.I.getData3D('image', NaN, 4);
img = squeeze(img);


imp = MIJ.createImage('test', img, 0);
imp.show
end

