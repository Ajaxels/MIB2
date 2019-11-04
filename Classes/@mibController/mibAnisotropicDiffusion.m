function mibAnisotropicDiffusion(obj, filter_type)
% function mibAnisotropicDiffusion(obj, filter_type)
% Filter image with Anisotropic diffusion filters
% 
% Parameters:
% filter_type: type of desired filter:
%  - ''diplib'', use diplib library to do the filtering (http://www.diplib.org/)
%  - ''anisodiff'', use anisodiff function by Peter Kovesi (http://www.csse.uwa.edu.au/~pk/Research/MatlabFns/#anisodiff)
%  - ''coherence_filter'', use Image Edge Enhancing Coherence Filter by Dirk-Jan Kroon and Pascal Getreuer (http://www.mathworks.com/matlabcentral/fileexchange/25449-image-edge-enhancing-coherence-filter-toolbox)
%
% Return values:
% 

% Copyright (C) 21.11.2013, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

switchIndexed = obj.mibView.handles.menuImageIndexed.Checked;
if strcmp(switchIndexed,'on')
    msgbox('Indexed images are not supported!','Error','error','modal');
    return;
end

% define mode to apply a filter:
% 2D, shown slice
% 3D, current stack
% 4D, complete volume
mode = obj.mibView.handles.mibImageFiltersModePopup.String;
mode = mode{obj.mibView.handles.mibImageFiltersModePopup.Value};
if obj.mibModel.getImageProperty('time') == 1 && strcmp(mode, '4D, complete volume')
    mode = '3D, current stack';
end

% define what to do with the filtered image:
% Apply filter
% Apply and add to the image
% Apply and subtract from the image
doAfter = obj.mibView.handles.mibImageFiltersOptionsPopup.String;
doAfter = doAfter{obj.mibView.handles.mibImageFiltersOptionsPopup.Value};

if strcmp(filter_type, 'anisodiff') %|| strcmp(filter_type,'diplib')   % do diplib or anisodiff filtering
    colorChannel = obj.mibModel.I{obj.mibModel.Id}.selectedColorChannel;
    if colorChannel == 0 && obj.mibModel.getImageProperty('colors') > 1
        button = questdlg(sprintf('Attention!\nEach color channel will be filtered individually!\n\nIf you want to filter only one color channel please select it in the\nSelection Panel->Color channel'),'Warning','Proceed','Cancel','Proceed');
        if strcmp(button,'Cancel'); return; end
    end
    tic
    val = obj.mibView.handles.mibImageFilterPopup.Value;
    opt = obj.mibView.handles.mibImageFilterPopup.String;
    if ischar(opt)
        sel_filter = opt;
    else
        sel_filter = opt{val};
    end
    options.Iter = str2double(obj.mibView.handles.mibImfiltPar1Edit.String);
    options.KSigma = str2double(obj.mibView.handles.mibImfiltPar2Edit.String);
    options.Lambda = str2double(obj.mibView.handles.mibImfiltPar3Edit.String);
    options.Orientation = obj.mibModel.getImageProperty('orientation');
    options.Color = colorChannel;
    options.Favours = obj.mibView.handles.mibImageFiltersTypePopup.Value; % 1: favours high contrast edges over low contrast ones; 2: favours wide regions over smaller ones. For 'anisodiff' only
    switch sel_filter
        case 'Perona Malik anisotropic diffusion' 
            options.Filter = 'anisodiff'; 
            options.KSigma = options.KSigma/100*obj.mibModel.I{obj.mibModel.Id}.meta('MaxInt');   % convert K from %% to numbers
%         case 'Diplib: Perona Malik anisotropic diffusion'; options.Filter = 'pmd';
%         case 'Diplib: Robust Anisotropic Diffusion'; options.Filter = 'aniso';
%         case 'Diplib: Mean Curvature Diffusion'; options.Filter = 'mcd';
%         case 'Diplib: Corner Preserving Diffusion'; options.Filter = 'cpf';
%         case 'Diplib: Kuwahara filter for edge-preserving smoothing'; options.Filter = 'kuwahara';
    end
    options.start_no = obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber();
    options.end_no = options.start_no;
    
    showWaitbarLocal = 0;
    if strcmp(mode, '4D, complete volume')
        timeVector = [1, obj.mibModel.getImageProperty('time')];
        options.showWaitbar = 0;    % do not show waitbar in the filtering function
        showWaitbarLocal = 1;
        wb = waitbar(0,['Applying ' options.Filter ' filter...'],'Name','Filtering','WindowStyle','modal');
    elseif strcmp(mode, '3D, current stack')
        obj.mibModel.mibDoBackup('image', 1);
        timeVector = [obj.mibModel.I{obj.mibModel.Id}.getCurrentTimePoint(), obj.mibModel.I{obj.mibModel.Id}.getCurrentTimePoint()];
    else
        obj.mibModel.mibDoBackup('image', 0);
        timeVector = [obj.mibModel.I{obj.mibModel.Id}.getCurrentTimePoint(), obj.mibModel.I{obj.mibModel.Id}.getCurrentTimePoint()];
    end
    
    getDataOptions.roiId = [];
    for t=timeVector(1):timeVector(2)
        if ~strcmp(mode, '2D, shown slice')
            img = obj.mibModel.getData3D('image', t, NaN, options.Color, getDataOptions);
            options.start_no = 1;
            options.end_no = size(img{1},4);
        else
            getDataOptions.t = [t t];
            img = obj.mibModel.getData2D('image', obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber(), NaN, options.Color, getDataOptions);
            options.start_no = 1;
            options.end_no = 1;
        end
        
        switch doAfter
            case 'Apply filter'
                [img, status] = mibDoAndiffFiltering(img, options);
                if status == 0; return; end
            case 'Apply and add to the image'
                [imgOut, status] = mibDoAndiffFiltering(img, options);
                if status == 0; return; end
                for roi = 1:numel(img)
                    img{roi} = img{roi} + imgOut{roi};
                end
            case 'Apply and subtract from the image'
                [imgOut, status] = mibDoAndiffFiltering(img, options);
                if status == 0; return; end
                for roi = 1:numel(img)
                    img{roi} = img{roi} - imgOut{roi};
                end
        end
            
        if ~strcmp(mode, '2D, shown slice')
            obj.mibModel.setData3D('image', img, t, NaN, options.Color, getDataOptions);
        else
            obj.mibModel.setData2D('image', img, obj.mibModel.I{obj.mibModel.Id}.getCurrentSliceNumber(), NaN, options.Color, getDataOptions);
        end
        if showWaitbarLocal == 1
            waitbar(t/(timeVector(2)-timeVector(1)),wb);
        end
    end
    log_text = [options.Filter ': Iter/Shape=' num2str(options.Iter) ';KSigma=' num2str(options.KSigma) ';lambda=' num2str(options.Lambda) ';Orient=' num2str(options.Orientation) 'Color=' num2str(options.Color)];
    obj.mibModel.I{obj.mibModel.Id}.updateImgInfo(log_text);
    if showWaitbarLocal == 1
        delete(wb);
    end
% elseif strcmp(filter_type,'coherence_filter') || strcmp(filter_type,'coherence_filter_test')   % do coherence filtering
%     colorChannel = get(handles.ColChannelCombo,'Value') - 1;
%     if colorChannel == 0
%         msgbox('Please select the color channel!','Error!','error','modal');
%         return;
%     end
%     
%     [options, dim] = anDiffOptionsDlg('options', NaN);
%     if ~isstruct(options)
%         return;
%     end
%     
%     wb = waitbar(0,'Please wait...','Name','Coherence filter...','WindowStyle','modal');
%     Options = options;
%     im_info = ['AnDiffFilter: Scheme=' Options.Scheme ...
%         ',eigenmode=' num2str(Options.eigenmode) ',T=' num2str(Options.T)...
%         ',dt=' num2str(Options.dt) ',sigma=' num2str(Options.sigma)...
%         ',rho=' num2str(Options.rho) ',C=' num2str(Options.C)...
%         ',m=' num2str(Options.m) ',alpha=' num2str(Options.alpha)...
%         ',lambda_e=' num2str(Options.lambda_e) ',lambda_c=' num2str(Options.lambda_c)...
%         ',lambda_h=' num2str(Options.lambda_h)];
%     tic;
%     
%     if strcmp(mode, '4D, complete volume')
%         timeVector = [1, handles.Img{handles.Id}.I.time];
%         wb = waitbar(0,'Applying coherence filter...','Name','Filtering','WindowStyle','modal');
%     elseif strcmp(mode, '3D, current stack')
%         ib_do_backup(handles, 'image', 1);
%         timeVector = [handles.Img{handles.Id}.I.getCurrentTimePoint(), handles.Img{handles.Id}.I.getCurrentTimePoint()];
%     else
%         ib_do_backup(handles, 'image', 0);
%         timeVector = [handles.Img{handles.Id}.I.getCurrentTimePoint(), handles.Img{handles.Id}.I.getCurrentTimePoint()];
%     end
%     
%     if strcmp(filter_type,'coherence_filter_test')
%         delete(wb);
%         if handles.Img{handles.Id}.I.orientation ~= 4;
%             msgbox('Please rotate the dataset to the XY orientation!','Error!','error','modal');
%             return;
%         end
%         
%         dx = size(handles.Img{handles.Id}.I.img,2);
%         dy = size(handles.Img{handles.Id}.I.img,1);
%         dz = size(handles.Img{handles.Id}.I.img,4);
%         w = round(handles.Img{handles.Id}.I.axesX);
%         h = round(handles.Img{handles.Id}.I.axesY);
%         if w(1)<0; w(1)=1; end;
%         if w(2)>dx; w(2)=dx; end;
%         if h(1)<0; h(1)=1; end;
%         if h(2)>dy; h(2)=dy; end;
%         
%         prompt = {sprintf('Select small region for test run\nImage size(w:h:z) %ix%ix%i pixels\n\nNew width (w1:w2):',dx,dx,dz),'New height (h1:h2):','New stack number (z1:z2)'};
%         title = 'Define Region';
%         lines = 1;
%         slice_no = handles.Img{handles.Id}.I.getCurrentSliceNumber();
%         if slice_no + 2 > dz
%             z_max = dz;
%             z_min = dz-4;
%         elseif slice_no - 2 < 1
%             z_min = 1;
%             z_max = 5;
%         else
%             z_min = slice_no-2;
%             z_max = slice_no+2;
%         end
%         if z_max > size(handles.Img{handles.Id}.I.img,4); z_max = size(handles.Img{handles.Id}.I.img,4); end;
%         if z_min < 1; z_min = 1; end;
%         
%         def = {[num2str(w(1)) ':' num2str(w(2))],[num2str(h(1)) ':' num2str(h(2))],[num2str(z_min) ':' num2str(z_max)]};
%         answer = inputdlg(prompt,title,lines,def,'on');
%         if size(answer) == 0; return; end;
%         tic
%         options.x(1) = str2double(answer{1}(1:strfind(answer{1},':')-1));
%         options.x(2) = str2double(answer{1}(strfind(answer{1},':')+1:end));
%         options.y(1) = str2double(answer{2}(1:strfind(answer{2},':')-1));
%         options.y(2) = str2double(answer{2}(strfind(answer{2},':')+1:end));
%         options.z(1) = str2double(answer{3}(1:strfind(answer{3},':')-1));
%         options.z(2) = str2double(answer{3}(strfind(answer{3},':')+1:end));
%         img = handles.Img{handles.Id}.I.getData3D('image', NaN, 4, colorChannel, options);
%         anDiffOptionsDlg('test', img);
%         toc;
%         return;
%     end
%     
%     for t=timeVector(1):timeVector(2)
%         if ~strcmp(mode, '2D, shown slice')
%             img = ib_getStack('image', handles, t, 0, colorChannel);
%         else
%             if strcmp(dim,'3d')
%                 msgbox('This mode is not supported for 2D slices, change to 3D current stack mode!','Error!','error','modal');
%                 delete(wb);
%                 return;
%             end
%             getDataOptions.t = [t t];
%             img = ib_getSlice('image', handles, handles.Img{handles.Id}.I.getCurrentSliceNumber(), NaN, colorChannel, getDataOptions);
%         end
%         
%         if strcmp(dim,'2d')   % 2D mode
%             for roi=1:numel(img)
%                 img2 = img{roi};
%                 parfor index=1:size(img2, 4)
%                     img2(:,:,1,index) = CoherenceFilter(img2(:,:,1,index),Options);
%                 end
%                 switch doAfter
%                     case 'Apply filter'
%                         img{roi} = img2;
%                     case 'Apply and add to the image'
%                         img{roi} = img{roi} + img2;
%                     case 'Apply and subtract from the image'
%                         img{roi} = img{roi} - img2;
%                 end
%             end
%         elseif strcmp(dim,'3d')   % 3D mode
%             for roi=1:numel(img)
%                 fImg = cast(CoherenceFilter(squeeze(img{roi}),Options),'like', img{1});
%                 fImg = reshape(fImg,size(fImg,1),size(fImg,2),1,size(fImg,3));
%                 switch doAfter
%                     case 'Apply filter'
%                         img{roi} = fImg;
%                     case 'Apply and add to the image'
%                         img{roi} = img{roi} + fImg;
%                     case 'Apply and subtract from the image'
%                         img{roi} = img{roi} - fImg;
%                 end
%             end
%         end
%         
%         if ~strcmp(mode, '2D, shown slice')
%             ib_setStack('image', img, handles, t, 0, colorChannel);
%         else
%             ib_setSlice('image', img, handles, handles.Img{handles.Id}.I.getCurrentSliceNumber(), NaN, colorChannel, getDataOptions);
%         end
%         waitbar(t/(timeVector(2)-timeVector(1)),wb);
%     end
%     delete(wb);
end
toc;
end