function render_image = render(volume,options)
% Function RENDER will volume render a image of a 3D volume,
% with transperancy, shading and ColorTable.
%
% I = RENDER(VOLUME,OPTIONS);
%
% outputs,
%  I: The rendered image
% 
% inputs,
%  VOLUME : Input image volume (Data of type double has short render 
%    times uint16 the longest)
%  OPTIONS: A struct with all the render options and parameters:
%    OPTIONS.RenderType : Maximum intensitity projections (default) 'mip', 
%                   greyscale volume rendering 'bw', color volume rendering
%                   'color' and volume rendering with shading 'shaded'
%    OPTIONS.ShearInterp : Interpolation method used in the Shear steps
%                   of the shearwarp algoritm, nearest or (default) bilinear
%    OPTIONS.WarpInterp : Interpolation method used in the warp step
%                   of the shearwarp algoritm, nearest or (default)
%                   bilinear
%    OPTIONS.ImageSize : Size of the rendered image, defaults to [400 400]
%    OPTIONS.Mview : This 4x4 matrix is the viewing matrix
%                   defaults to [1 0 0 0;0 1 0 0;0 0 1 0;0 0 0 1]
%    OPTIONS.AlphaTable : This Nx1 table is linear interpolated such that
%    every
%                   voxel intensity gets a specific alpha (transparency)
%                   [0 0.01 0.05 0.1 0.2 1 1 1 1 1] 
%    OPTIONS.ColorTable : This Nx3 table is linear interpolated such that
%                   every voxel intensity gets a specific color. 
%                   defaults to [1 0 0;1 0 0;1 0 0;1 0 0;1 0 0;1 0 0;1 0 0] 
%    OPTIONS.LightVector : Light Direction defaults to [0.67 0.33 -0.67]
%    OPTIONS.ViewerVector : View vector X,Y,Z defaults to [0 0 1]
%    OPTIONS.ShadingMaterial : The type of material shading : dull,
%                   shiny(default) or metal.
%
% Optional parameters to speed up rendering:
%    OPTIONS.VolumeX, OPTIONS.VolumeY : Dimensions shifted Voxel volumes,
%                   Must be used like:
%                       OPTIONS.VolumeX=shiftdim(OPTIONS.Volume,1);
%                       OPTIONS.VolumeY=shiftdim(OPTIONS.Volume,2);
%    OPTIONS.Normals : The normalized gradient of the voxel volume
%                   Must be used like:
%                   [fy,fx,fz]=gradient(OPTIONS.Volume);
%                   flength=sqrt(fx.^2+fy.^2+fz.^2)+1e-6;
%                   OPTIONS.Normals=zeros([size(fx) 3]);
%                   OPTIONS.Normals(:,:,:,1)=fx./flength;
%                   OPTIONS.Normals(:,:,:,2)=fy./flength;
%                   OPTIONS.Normals(:,:,:,3)=fz./flength;
%    
% example,
%   %Add paths
%   functionname='render.m';
%   functiondir=which(functionname);
%   functiondir=functiondir(1:end-length(functionname));
%   addpath(functiondir); 
%   addpath([functiondir '/SubFunctions']);
%   % Load data
%   load('ExampleData/TestVolume.mat'); V=data.volumes(1).volume_original;
%   % Type of rendering
%   options.RenderType = 'color';
%   % color and alpha table
%   options.AlphaTable=[0 0 0 0 0 1 1 1 1 1];
%   options.ColorTable=[1 0 0;1 0 0;1 0 0;1 0 0;1 0 0;1 0 0;1 0 0]; 
%   %options.ColorTable=[1 0 0;1 0 0;]; 
%   % Viewer Matrix
%   options.Mview=makeViewMatrix([0 0 0],[0.25 0.25 0.25],[0 0 0]);
%   % Render and show image
%   figure,
%   I = render(V,options);
%   imshow(I);
%
% Function is written by D.Kroon University of Twente (April 2009)

%% Set the default options
defaultoptions=struct( ...
    'RenderType','mip', ...
    'Volume', zeros(3,3,3), ...
    'VolumeX', [], ...
    'VolumeY', [], ...
    'Normals', [], ...
    'imax',[], ...
    'imin',[], ...
    'ShearInterp', 'bilinear', ...
    'WarpInterp', 'bilinear', ...
    'ImageSize', [400 400], ...
    'Mview', [1 0 0 0;0 1 0 0;0 0 1 0;0 0 0 1], ...
    'AlphaTable', [0 0.01 0.05 0.1 0.2 1 1 1 1 1], ...
    'ColorTable', [1 0 0;1 0 0;1 0 0;1 0 0;1 0 0;1 0 0;1 0 0], ...
    'LightVector',[0.67 0.33 -0.67], ...
    'ViewerVector',[0 0 1], ...
    'SliceSelected', 1, ...
    'ColorSlice', false, ...
    'ShadingMaterial','shiny');

%% Check the input options
if(~exist('options','var')), 
    options=defaultoptions; 
else
    tags = fieldnames(defaultoptions);
    for i=1:length(tags)
         if(~isfield(options,tags{i})),  options.(tags{i})=defaultoptions.(tags{i}); end
    end
    if(length(tags)~=length(fieldnames(options))), 
        warning('Render:unknownoption','unknown options found');
    end
end

% Make the data structure from the options structure
data=options;
if(exist('volume','var')); data.Volume=volume; end

%% If black
if(strcmp(data.RenderType,'black'))
    render_image = zeros(data.ImageSize);
    return
end

%% Needed to convert intensities to range [0 1]
if(isempty(data.imax))
    switch class(data.Volume)
        case 'uint8', 
            data.imax=2^8-1;  data.imin=0; 
        case 'uint16',
            data.imax=2^16-1; data.imin=0;
        case 'uint32',
            data.imax=2^32-1; data.imin=0; 
        case 'int8',  
            data.imax=2^7-1;  data.imin=-2^7; 
        case 'int16', 
            data.imax=2^15-1; data.imin=-2^15;
        case 'int32', 
            data.imax=2^31-1; data.imin=-2^31; 
        otherwise,
            data.imax=max(data.Volume(:)); 
            data.imin=min(data.Volume(:));
    end
end
data.imaxmin=data.imax-data.imin;

%% Split ColorTable in R,G,B
if(~isempty(data.ColorTable))
    if(size(data.ColorTable,2)>size(data.ColorTable,1)), data.ColorTable=data.ColorTable'; end
    data.ColorTable_r=data.ColorTable(:,1); data.ColorTable_g=data.ColorTable(:,2); data.ColorTable_b=data.ColorTable(:,3);
end   

%% If no 3D but slice render do slicerender
if((length(data.RenderType)>5)&&strcmp(data.RenderType(1:5),'slice')) 
    render_image = render_slice(data);
    return
end

%% Calculate the Shear and Warp Matrices
if(ndims(data.Volume)==2)
    sizes=[size(data.Volume) 1];
else
    sizes=size(data.Volume);
end
[data.Mshear,data.Mwarp2D,data.c]=makeShearWarpMatrix(data.Mview,sizes);
data.Mwarp2Dinv=inv(double(data.Mwarp2D)); 
data.Mshearinv=inv(data.Mshear);

%% Store Volume sizes
data.Iin_sizex=size(data.Volume,1); data.Iin_sizey=size(data.Volume,2); data.Iin_sizez=size(data.Volume,3);

%% Create Shear (intimidate) buffer
data.Ibuffer_sizex=ceil(1.7321*max(size(data.Volume))+1);
data.Ibuffer_sizey=data.Ibuffer_sizex;
switch data.RenderType
    case {'mip'}
        data.Ibuffer=zeros([data.Ibuffer_sizex data.Ibuffer_sizey])+data.imin;
    case {'bw'}
        data.Ibuffer=zeros([data.Ibuffer_sizex data.Ibuffer_sizey]);
    otherwise
        data.Ibuffer=zeros([data.Ibuffer_sizex data.Ibuffer_sizey 3]);
end

%% Adjust alpha table by voxel length because of rotation and volume size
lengthcor=sqrt(1+data.Mshearinv(1,3)^2+data.Mshearinv(2,3)^2)*mean(size(data.Volume))/100;
data.AlphaTable=1 - (1-data.AlphaTable).^(1/lengthcor);
data.AlphaTable(data.AlphaTable<0)=0; data.AlphaTable(data.AlphaTable>1)=1;



%% Shading type -> Phong values
switch lower(data.ShadingMaterial)
    case {'shiny'}
        data.material=[0.7,	0.6, 0.9, 15];
    case {'dull'}
        data.material=[0.7,	0.8, 0.0, 10];
    case {'metal'}
        data.material=[0.7,	0.3, 1.0, 20];
    otherwise
        data.material=[0.7,	0.6, 0.9, 20];
end

%% Normalize Light and Viewer vectors
data.LightVector=[data.LightVector(:);0]; data.LightVector=data.LightVector./sqrt(sum(data.LightVector(1:3).^2));
data.ViewerVector=[data.ViewerVector(:);0]; data.ViewerVector=data.ViewerVector./sqrt(sum(data.ViewerVector(1:3).^2));

%% Shear Rendering
data = shear(data);
data = warp(data);
render_image = data.Iout;

%% Slice rendering
function Iout=render_slice(data)
switch (data.RenderType)
    case {'slicex'}
        Iin=(double(squeeze(data.Volume(data.SliceSelected,:,:,:)))-data.imin)/data.imaxmin;
        M=[data.Mview(1,2) data.Mview(1,3) data.Mview(1,4); data.Mview(2,2) data.Mview(2,3) data.Mview(2,4); 0 0 1];
       % Rotate 90
    case {'slicey'}
        Iin=(double(squeeze(data.Volume(:,data.SliceSelected,:,:)))-data.imin)/data.imaxmin;
        M=[data.Mview(1,1) data.Mview(1,3) data.Mview(1,4); data.Mview(2,1) data.Mview(2,3) data.Mview(2,4); 0 0 1];     % Rotate 90
    case {'slicez'}
        Iin=(double(squeeze(data.Volume(:,:,data.SliceSelected,:)))-data.imin)/data.imaxmin;
        M=[data.Mview(1,1) data.Mview(1,2) data.Mview(1,4); data.Mview(2,1) data.Mview(2,2) data.Mview(2,4); 0 0 1];
end

M=inv(M);


% Perform the affine transformation
switch(data.WarpInterp)
    case 'nearest', wi=5;
    case 'bicubic', wi=3;
    case 'bilinear', wi=1;
    otherwise, wi=1;
end

Ibuffer=affine_transform_2d_double(Iin,M,wi,data.ImageSize);
        
if(data.ColorSlice)
    Ibuffer(Ibuffer<0)=0; Ibuffer(Ibuffer>1)=1;
    betaC=(length(data.ColorTable_r)-1);
    indexColor=round(Ibuffer*betaC)+1;
    
    % Greyscale to Color
    Ibuffer=zeros([size(Ibuffer) 3]);
    Ibuffer(:,:,1)=data.ColorTable_r(indexColor);
    Ibuffer(:,:,2)=data.ColorTable_g(indexColor);
    Ibuffer(:,:,3)=data.ColorTable_b(indexColor);
    Iout=Ibuffer;
else
    Iout=Ibuffer;
end


%% Shearwarp functions
function data=shear(data)
switch (data.c)
    case 1
        for z=0:(data.Iin_sizex-1);
            % Offset calculation
            xd=(-data.Ibuffer_sizex/2)+data.Mshearinv(1,3)*(z-data.Iin_sizex/2)+data.Iin_sizey/2;    
            yd=(-data.Ibuffer_sizey/2)+data.Mshearinv(2,3)*(z-data.Iin_sizex/2)+data.Iin_sizez/2; 
        
            xdfloor=floor(xd); ydfloor=floor(yd);
            
            %Calculate the coordinates on which a image slice starts and 
            %ends in the temporary shear image (buffer)
            pystart=-ydfloor; 
                if(pystart<0), pystart=0; end
            pyend=data.Iin_sizez-ydfloor; 
                if(pyend>data.Ibuffer_sizey), pyend=data.Ibuffer_sizey; end
            
            pxstart=-xdfloor; 
                if(pxstart<0), pxstart=0; end
            pxend=data.Iin_sizey-xdfloor; 
                if(pxend>data.Ibuffer_sizex), pxend=data.Ibuffer_sizex; end
            
            data.py=(pystart+1:pyend-1); data.px=(pxstart+1:pxend-1);
            
            if(isempty(data.px)), data.px=pxstart+1; end
            if(isempty(data.py)), data.py=pystart+1; end
            
            % Determine x and y coordinates of pixel(s) which will be come current pixel
            yBas=data.py+ydfloor;  xBas=data.px+xdfloor; 
            
            switch (data.ShearInterp)
                case {'bilinear'}
                    xBas1=xBas+1;  xBas1(end)=xBas1(end)-1;
                    yBas1=yBas+1;  yBas1(end)=yBas1(end)-1;

                    % Linear interpolation constants (percentages)
                    xCom=xd-floor(xd);  yCom=yd-floor(yd);
                    perc=[(1-xCom)*(1-yCom) (1-xCom)*yCom xCom*(1-yCom) xCom*yCom];

                    if(isempty(data.VolumeX))
                        % Get the intensities
                        if(data.Iin_sizez>1)
                            slice=double(squeeze(data.Volume(z+1,:,:)));
                        else
                            slice=double(data.Volume(z+1,:))';
                        end
                        intensity_xyz1=slice(xBas, yBas);
                        intensity_xyz2=slice(xBas, yBas1);
                        intensity_xyz3=slice(xBas1, yBas);
                        intensity_xyz4=slice(xBas1, yBas1);
                    else
                        slice=double(data.VolumeX(:, :,z+1));
                        intensity_xyz1=slice(xBas, yBas);
                        intensity_xyz2=slice(xBas, yBas1);
                        intensity_xyz3=slice(xBas1, yBas);
                        intensity_xyz4=slice(xBas1, yBas1);                        
                    end                        
                    
                    % Calculate the interpolated intensity
                    data.intensity_loc=(intensity_xyz1*perc(1)+intensity_xyz2*perc(2)+intensity_xyz3*perc(3)+intensity_xyz4*perc(4)); 
                otherwise
                    if(isempty(data.VolumeX))
                        data.intensity_loc=double(squeeze(data.Volume(z+1,xBas, yBas)));
                    else
                        data.intensity_loc=double(data.VolumeX(xBas, yBas,z+1));
                    end
            end

            % Update the shear image buffer
            switch (data.RenderType)
                case {'mip'}
                    data=updatebuffer_MIP(data);
                case {'color'}
                    data=updatebuffer_COLOR(data);                   
                case {'bw'}
                    data=updatebuffer_BW(data);
                case {'shaded'}
                    data=returnnormal(z+1,xBas, yBas,data);
                    data=updatebuffer_SHADED(data);
            end
        end        
    case 2
        for z=0:(data.Iin_sizey-1),
            % Offset calculation
            xd=(-data.Ibuffer_sizex/2)+data.Mshearinv(1,3)*(z-data.Iin_sizey/2)+data.Iin_sizez/2;   
            yd=(-data.Ibuffer_sizey/2)+data.Mshearinv(2,3)*(z-data.Iin_sizey/2)+data.Iin_sizex/2; 
           
            xdfloor=floor(xd); ydfloor=floor(yd);

            %Calculate the coordinates on which a image slice starts and 
            %ends in the temporary shear image (buffer)
            pystart=-ydfloor; 
                if(pystart<0), pystart=0; end
            pyend=data.Iin_sizex-ydfloor; 
                if(pyend>data.Ibuffer_sizey), pyend=data.Ibuffer_sizey; end
            pxstart=-xdfloor; 
                if(pxstart<0), pxstart=0; end
            pxend=data.Iin_sizez-xdfloor; 
                if(pxend>data.Ibuffer_sizex), pxend=data.Ibuffer_sizex; end

            data.py=(pystart+1:pyend-1); data.px=(pxstart+1:pxend-1);
            if(isempty(data.px)), data.px=pxstart+1; end
            if(isempty(data.py)), data.py=pystart+1; end
            
                
            %Determine x,y coordinates of pixel(s) which will be come current pixel
            yBas=data.py+ydfloor;  xBas=data.px+xdfloor; 
            
            switch (data.ShearInterp)
                case {'bilinear'}
                    xBas1=xBas+1;  xBas1(end)=xBas1(end)-1;
                    yBas1=yBas+1;  yBas1(end)=yBas1(end)-1;

                    if(isempty(data.VolumeY))
                        % Get the intensities
                        slice=double(squeeze(data.Volume(:,z+1,:)));
                        intensity_xyz1=slice(yBas, xBas);
                        intensity_xyz2=slice(yBas1,xBas);
                        intensity_xyz3=slice(yBas, xBas1);
                        intensity_xyz4=slice(yBas1, xBas1);
                    else
                        % Get the intensities
                        slice=double(data.VolumeY(:,:,z+1));
                        intensity_xyz1=slice(xBas,yBas);
                        intensity_xyz2=slice(xBas,yBas1);
                        intensity_xyz3=slice(xBas1,yBas);
                        intensity_xyz4=slice(xBas1,yBas1);
                    end
                    
                    % Linear interpolation constants (percentages)
                    xCom=xd-floor(xd);  yCom=yd-floor(yd);
                    perc=[(1-xCom)*(1-yCom) (1-xCom)*yCom xCom*(1-yCom) xCom*yCom];

                    % Calculate the interpolated intensity
                    
                    data.intensity_loc=(intensity_xyz1*perc(1)+intensity_xyz2*perc(2)+intensity_xyz3*perc(3)+intensity_xyz4*perc(4)); 
                otherwise
                    if(isempty(data.VolumeY))
                        data.intensity_loc=double(squeeze(data.Volume(yBas, z+1,xBas)));
                    else
                        data.intensity_loc=double(data.VolumeY(xBas,yBas,z+1));
                    end
                    
            end
            
            % Rotate image
            if (isempty(data.VolumeY)),  data.intensity_loc=data.intensity_loc'; end

            % Update the shear image buffer
            switch (data.RenderType)
                case {'mip'}
                    data=updatebuffer_MIP(data);
                case {'color'}
                    data=updatebuffer_COLOR(data);                   
                case {'bw'}
                    data=updatebuffer_BW(data);
                case {'shaded'}
                    data=returnnormal(yBas, z+1,xBas,data);
                    data=updatebuffer_SHADED(data);
            end
        end
    case 3
        for z=0:(data.Iin_sizez-1),
            % Offset calculation
            xd=(-data.Ibuffer_sizex/2)+data.Mshearinv(1,3)*(z-data.Iin_sizez/2)+data.Iin_sizex/2;    
            yd=(-data.Ibuffer_sizey/2)+data.Mshearinv(2,3)*(z-data.Iin_sizez/2)+data.Iin_sizey/2; 
            xdfloor=floor(xd); ydfloor=floor(yd);

            %Calculate the coordinates on which a image slice starts and 
            %ends in the temporary shear image (buffer)
            pystart=-ydfloor; 
                if(pystart<0), pystart=0; end
            pyend=data.Iin_sizey-ydfloor; 
                if(pyend>data.Ibuffer_sizey), pyend=data.Ibuffer_sizey; end
            pxstart=-xdfloor; 
                if(pxstart<0), pxstart=0; end
            pxend=data.Iin_sizex-xdfloor; 
                if(pxend>data.Ibuffer_sizex), pxend=data.Ibuffer_sizex; end

            data.py=(pystart+1:pyend-1); data.px=(pxstart+1:pxend-1);
            if(isempty(data.px)), data.px=pxstart+1; end
            if(isempty(data.py)), data.py=pystart+1; end
            
            %Determine x,y coordinates of pixel(s) which will be come current pixel
            yBas=data.py+ydfloor; xBas=data.px+xdfloor; 

            switch (data.ShearInterp)
                case {'bilinear'}
                    xBas1=xBas+1;  xBas1(end)=xBas1(end)-1;
                    yBas1=yBas+1;  yBas1(end)=yBas1(end)-1;

                    % Get the intensities
                    slice=double(data.Volume(:,:,z+1));
                    intensity_xyz1=slice(xBas, yBas);
                    intensity_xyz2=slice(xBas, yBas1);
                    intensity_xyz3=slice(xBas1, yBas);
                    intensity_xyz4=slice(xBas1, yBas1);

                    % Linear interpolation constants (percentages)
                    xCom=xd-floor(xd);  yCom=yd-floor(yd);
                    perc=[(1-xCom)*(1-yCom) (1-xCom)*yCom xCom*(1-yCom) xCom*yCom];

                    % Calculate the interpolated intensity
                    
                    data.intensity_loc=(intensity_xyz1*perc(1)+intensity_xyz2*perc(2)+intensity_xyz3*perc(3)+intensity_xyz4*perc(4)); 
                otherwise
                    data.intensity_loc=double(data.Volume(xBas, yBas, z+1));
            end
            
            % Update the shear image buffer
            switch (data.RenderType)
                case {'mip'}
                    data=updatebuffer_MIP(data);
                case {'color'}
                    data=updatebuffer_COLOR(data);                   
                case {'bw'}
                    data=updatebuffer_BW(data);
                case {'shaded'}
                    data=returnnormal(xBas,yBas,z+1,data);
                    data=updatebuffer_SHADED(data);
            end
        end
    case 4
        for z=(data.Iin_sizex-1):-1:0,
            % Offset calculation
            xd=(-data.Ibuffer_sizex/2)+data.Mshearinv(1,3)*(z-data.Iin_sizex/2)+data.Iin_sizey/2;    
            yd=(-data.Ibuffer_sizey/2)+data.Mshearinv(2,3)*(z-data.Iin_sizex/2)+data.Iin_sizez/2; 
        
            xdfloor=floor(xd); ydfloor=floor(yd);

            %Calculate the coordinates on which a image slice starts and 
            %ends in the temporary shear image (buffer)
            pystart=-ydfloor; 
                if(pystart<0), pystart=0; end
            pyend=data.Iin_sizez-ydfloor; 
                if(pyend>data.Ibuffer_sizey), pyend=data.Ibuffer_sizey; end
            pxstart=-xdfloor; 
                if(pxstart<0), pxstart=0; end
            pxend=data.Iin_sizey-xdfloor; 
                if(pxend>data.Ibuffer_sizex), pxend=data.Ibuffer_sizex; end

            data.py=(pystart+1:pyend-1); data.px=(pxstart+1:pxend-1);
            if(isempty(data.px)), data.px=pxstart+1; end
            if(isempty(data.py)), data.py=pystart+1; end
            
            % Determine x,y coordinates of pixel(s) which will be come current pixel
            yBas=data.py+ydfloor; xBas=data.px+xdfloor; 
            switch (data.ShearInterp)
                case {'bilinear'}
                    xBas1=xBas+1;  xBas1(end)=xBas1(end)-1;
                    yBas1=yBas+1;  yBas1(end)=yBas1(end)-1;

                    if(isempty(data.VolumeX))
                        % Get the intensities
                        if(data.Iin_sizez>1)
                            slice=double(squeeze(data.Volume(z+1,:,:)));
                        else
                            slice=double(data.Volume(z+1,:))';
                        end
                        
                        intensity_xyz1=slice(xBas, yBas);
                        intensity_xyz2=slice(xBas, yBas1);
                        intensity_xyz3=slice(xBas1, yBas);
                        intensity_xyz4=slice(xBas1, yBas1);
                    else
                        slice=double(data.VolumeX(:, :,z+1));
                        intensity_xyz1=slice(xBas,yBas);
                        intensity_xyz2=slice(xBas,yBas1);
                        intensity_xyz3=slice(xBas1,yBas);
                        intensity_xyz4=slice(xBas1,yBas1);                        
                    end
                    % Linear interpolation constants (percentages)
                    xCom=xd-floor(xd);  yCom=yd-floor(yd);
                    perc=[(1-xCom)*(1-yCom) (1-xCom)*yCom xCom*(1-yCom) xCom*yCom];

                    % Calculate the interpolated intensity
                    
                    data.intensity_loc=(intensity_xyz1*perc(1)+intensity_xyz2*perc(2)+intensity_xyz3*perc(3)+intensity_xyz4*perc(4)); 
                otherwise
                    if(isempty(data.VolumeX))
                        data.intensity_loc=double(squeeze(data.Volume(z+1,xBas, yBas)));
                    else
                        data.intensity_loc=double(data.VolumeX(xBas, yBas,z+1));    
                    end
            end
            
            % Update the shear image buffer
            switch (data.RenderType)
                case {'mip'}
                    data=updatebuffer_MIP(data);
                case {'color'}
                    data=updatebuffer_COLOR(data);                   
                case {'bw'}
                    data=updatebuffer_BW(data);
                case {'shaded'}
                    data=returnnormal(z+1,xBas,yBas,data);
                    data=updatebuffer_SHADED(data);
            end
        end
    case 5
        for z=(data.Iin_sizey-1):-1:0,
            % Offset calculation
            xd=(-data.Ibuffer_sizex/2)+data.Mshearinv(1,3)*(z-data.Iin_sizey/2)+data.Iin_sizez/2;   
            yd=(-data.Ibuffer_sizey/2)+data.Mshearinv(2,3)*(z-data.Iin_sizey/2)+data.Iin_sizex/2; 
           
            xdfloor=floor(xd); ydfloor=floor(yd);

            %Calculate the coordinates on which a image slice starts and 
            %ends in the temporary shear image (buffer)
            pystart=-ydfloor; 
                if(pystart<0), pystart=0; end
            pyend=data.Iin_sizex-ydfloor; 
                if(pyend>data.Ibuffer_sizey), pyend=data.Ibuffer_sizey; end
            pxstart=-xdfloor; 
                if(pxstart<0), pxstart=0; end
            pxend=data.Iin_sizez-xdfloor; 
                if(pxend>data.Ibuffer_sizex), pxend=data.Ibuffer_sizex; end

            data.py=(pystart+1:pyend-1); data.px=(pxstart+1:pxend-1);
            if(isempty(data.px)), data.px=pxstart+1; end
            if(isempty(data.py)), data.py=pystart+1; end
            
            %Determine x,y coordinates of pixel(s) which will be come current pixel
            xBas=data.px+xdfloor; yBas=data.py+ydfloor; 
            switch (data.ShearInterp)
                case {'bilinear'}
                    xBas1=xBas+1;  xBas1(end)=xBas1(end)-1;
                    yBas1=yBas+1;  yBas1(end)=yBas1(end)-1;

                    if(isempty(data.VolumeY))
                        % Get the intensities
                        slice=double(squeeze(data.Volume(:, z+1,:)));
                        intensity_xyz1=slice(yBas, xBas);
                        intensity_xyz2=slice(yBas1,xBas);
                        intensity_xyz3=slice(yBas, xBas1);
                        intensity_xyz4=slice(yBas1, xBas1);
                    else
                        % Get the intensities
                        slice=double(data.VolumeY(:,:,z+1));
                        intensity_xyz1=slice(xBas,yBas);
                        intensity_xyz2=slice(xBas,yBas1);
                        intensity_xyz3=slice(xBas1,yBas);
                        intensity_xyz4=slice(xBas1,yBas1);                        
                    end    
                    % Linear interpolation constants (percentages)
                    xCom=xd-floor(xd);  yCom=yd-floor(yd);
                    perc=[(1-xCom)*(1-yCom) (1-xCom)*yCom xCom*(1-yCom) xCom*yCom];

                    % Calculate the interpolated intensity
                    
                    data.intensity_loc=(intensity_xyz1*perc(1)+intensity_xyz2*perc(2)+intensity_xyz3*perc(3)+intensity_xyz4*perc(4)); 
                otherwise
                    if(isempty(data.VolumeY))
                        data.intensity_loc=double(squeeze(data.Volume(yBas, z+1,xBas)));
                    else
                        data.intensity_loc=double(data.VolumeY(xBas,yBas,z+1));    
                    end
            end
            
            % Rotate image
            if (isempty(data.VolumeY)),  data.intensity_loc=data.intensity_loc'; end

            % Update the shear image buffer
            switch (data.RenderType)
                case {'mip'}
                    data=updatebuffer_MIP(data);
                case {'color'}
                    data=updatebuffer_COLOR(data);                   
                case {'bw'}
                    data=updatebuffer_BW(data);
                case {'shaded'}
                    data=returnnormal(yBas,z+1,xBas,data);
                    data=updatebuffer_SHADED(data);
            end
        end
    case 6
        for z=(data.Iin_sizez-1):-1:0,
            % Offset calculation
            xd=(-data.Ibuffer_sizex/2)+data.Mshearinv(1,3)*(z-data.Iin_sizez/2)+data.Iin_sizex/2;    
            yd=(-data.Ibuffer_sizey/2)+data.Mshearinv(2,3)*(z-data.Iin_sizez/2)+data.Iin_sizey/2; 
            xdfloor=floor(xd); ydfloor=floor(yd);

            %Calculate the coordinates on which a image slice starts and 
            %ends in the temporary shear image (buffer)
            pystart=-ydfloor; 
                if(pystart<0), pystart=0; end
            pyend=data.Iin_sizey-ydfloor; 
                if(pyend>data.Ibuffer_sizey), pyend=data.Ibuffer_sizey; end
            pxstart=-xdfloor; 
                if(pxstart<0), pxstart=0; end
            pxend=data.Iin_sizex-xdfloor; 
                if(pxend>data.Ibuffer_sizex), pxend=data.Ibuffer_sizex; end

            data.py=(pystart+1:pyend-1); data.px=(pxstart+1:pxend-1);
            if(isempty(data.px)), data.px=pxstart+1; end
            if(isempty(data.py)), data.py=pystart+1; end
            
            % Determine x,y coordinates of pixel(s) which will be come current pixel
            xBas=data.px+xdfloor; yBas=data.py+ydfloor; 
            switch (data.ShearInterp)
                case {'bilinear'}            
                    xBas1=xBas+1;  xBas1(end)=xBas1(end)-1;
                    yBas1=yBas+1;  yBas1(end)=yBas1(end)-1;

                    % Get the intensities
                    slice=double(data.Volume(:, :, z+1));
                    intensity_xyz1=slice(xBas, yBas);
                    intensity_xyz2=slice(xBas, yBas1);
                    intensity_xyz3=slice(xBas1, yBas );
                    intensity_xyz4=slice(xBas1, yBas1 );

                    % Linear interpolation constants (percentages)
                    xCom=xd-floor(xd);  yCom=yd-floor(yd);
                    perc=[(1-xCom)*(1-yCom) (1-xCom)*yCom xCom*(1-yCom) xCom*yCom];

                    % Calculate the interpolated intensity
                    
                    data.intensity_loc=(intensity_xyz1*perc(1)+intensity_xyz2*perc(2)+intensity_xyz3*perc(3)+intensity_xyz4*perc(4)); 
                otherwise
                    data.intensity_loc=double(data.Volume(xBas, yBas, z+1));
            end
            
            % Update the shear image buffer
            switch (data.RenderType)
                case {'mip'}
                    data=updatebuffer_MIP(data);
                case {'color'}
                    data=updatebuffer_COLOR(data);                   
                case {'bw'}
                    data=updatebuffer_BW(data);
                case {'shaded'}
                    data=returnnormal(xBas,yBas,z+1,data);
                    data=updatebuffer_SHADED(data);
            end
        end
end

switch (data.RenderType)
	case {'mip'}
    if(data.imin~=0), data.Ibuffer=data.Ibuffer-data.imin; end
    data.Ibuffer=data.Ibuffer/data.imaxmin;
end
	

function data=returnnormal(x,y,z,data)
% Calculate the normals for a certain pixel / slice or volume.
% The Normals are calculated by normalizing the voxel volume gradient.

% The central pixel positions
x1=x; y1=y; z1=z;

% Check if the gradients is delivered by the user
if(isempty(data.Normals))
    % The forward pixel positions
    x2=x1+1; y2=y1+1; z2=z1+1;
    
    % Everything inside the boundaries
    checkx=x2>size(data.Volume,1); checky=y2>size(data.Volume,2); checkz=z2>size(data.Volume,3);
    if(nnz(checkx)>0), x1(checkx)=x1-1; x2(checkx)=size(data.Volume,1); end
    if(nnz(checky)>0), y1(checky)=y1-1; y2(checky)=size(data.Volume,2); end
    if(nnz(checkz)>0), z1(checkz)=z1-1; z2(checkz)=size(data.Volume,3); end

    % Calculate the forward gradient
    S(:,:,1)=double(squeeze(data.Volume(x2,y1,z1)-data.Volume(x1,y1,z1)));
    S(:,:,2)=double(squeeze(data.Volume(x1,y2,z1)-data.Volume(x1,y1,z1)));
    S(:,:,3)=double(squeeze(data.Volume(x1,y1,z2)-data.Volume(x1,y1,z1)));

    % Normalize the gradient data
    nlength=sqrt(S(:,:,1).^2+S(:,:,2).^2+S(:,:,3).^2)+0.000001;
    
    N=zeros(size(S));
    N(:,:,1)=S(:,:,1)./nlength; 
    N(:,:,2)=S(:,:,2)./nlength;
    N(:,:,3)=S(:,:,3)./nlength;
else
    % Get the user inputed normal information
    N(:,:,1)=squeeze(data.Normals(x1,y1,z1,1));
    N(:,:,2)=squeeze(data.Normals(x1,y1,z1,2));
    N(:,:,3)=squeeze(data.Normals(x1,y1,z1,3));
end

% Rotate the data in case of certain views
if(data.c==2||data.c==5),
    N2=zeros([size(N,2) size(N,1) 3]);
    N2(:,:,1)=N(:,:,1)'; N2(:,:,2)=N(:,:,2)'; N2(:,:,3)=N(:,:,3)'; N=N2;
end
% "Return" the Normals
data.N=N;


function data=updatebuffer_MIP(data)
    % Update the current pixel in the shear image buffer
    check=double(data.intensity_loc>data.Ibuffer(data.px,data.py));
    data.Ibuffer(data.px,data.py)=(check).*data.intensity_loc+(1-check).*data.Ibuffer(data.px,data.py);

    function data=updatebuffer_BW(data)
    % Calculate index in alpha transparency look up table
    if(data.imin~=0), data.intensity_loc=data.intensity_loc-data.imin; end
    if(data.imaxmin~=1), data.intensity_loc=data.intensity_loc./data.imaxmin; end
    
    betaA=(length(data.AlphaTable)-1);
    indexAlpha=round(data.intensity_loc*betaA)+1;
    
    % calculate current alphaimage
    alphaimage=data.AlphaTable(indexAlpha);                
    % 2D volume fix because alphaimage becomes a row instead of column
    if(data.Iin_sizez==1), alphaimage=reshape(alphaimage,size(data.Ibuffer(data.px,data.py))); end
    
    alphaimage_inv=(1-alphaimage);
        
    % Update the current pixel in the shear image buffer
    data.Ibuffer(data.px,data.py)=alphaimage_inv.*data.Ibuffer(data.px,data.py)+alphaimage.*data.intensity_loc;

function data=updatebuffer_COLOR(data)    
    % Calculate index in alpha transparency look up table
    if(data.imin~=0), data.intensity_loc=data.intensity_loc-data.imin; end
    betaA=(length(data.AlphaTable)-1)/data.imaxmin;
    betaC=(length(data.ColorTable_r)-1)/data.imaxmin;
    
    
    indexAlpha=round(data.intensity_loc*betaA)+1;
    % Calculate index in color look up table
    if(betaA~=betaC)
        indexColor=round(data.intensity_loc*betaC)+1;
    else
        indexColor=indexAlpha;
    end
    
    r=data.ColorTable_r(indexColor);
    g=data.ColorTable_g(indexColor);
    b=data.ColorTable_b(indexColor);
        
    % calculate current alphaimage
    alphaimage=data.AlphaTable(indexAlpha);  
    
    % Update the current pixel in the shear image buffer
    if(data.Iin_sizez==1), 
        alphaimage=reshape(alphaimage,size(data.Ibuffer(data.px,data.py,1)));
        r=reshape(r,size(data.Ibuffer(data.px,data.py,1)));
        g=reshape(g,size(data.Ibuffer(data.px,data.py,1)));
        b=reshape(b,size(data.Ibuffer(data.px,data.py,1)));
    end
    
    % 2D volume fix because alphaimage becomes a row instead of column
    alphaimage_inv=(1-alphaimage);
        
    data.Ibuffer(data.px,data.py,1)=alphaimage_inv.*data.Ibuffer(data.px,data.py,1)+alphaimage.*r;
    data.Ibuffer(data.px,data.py,2)=alphaimage_inv.*data.Ibuffer(data.px,data.py,2)+alphaimage.*g;
    data.Ibuffer(data.px,data.py,3)=alphaimage_inv.*data.Ibuffer(data.px,data.py,3)+alphaimage.*b;
     
    
function data=updatebuffer_SHADED(data)    
    if(data.imin~=0), data.intensity_loc=data.intensity_loc-data.imin; end
    betaA=(length(data.AlphaTable)-1)/data.imaxmin;
    betaC=(length(data.ColorTable_r)-1)/data.imaxmin;
    
    % Calculate index in alpha transparency look up table
    indexAlpha=round(data.intensity_loc*betaA)+1;
    % Calculate index in color look up table
    if(betaA~=betaC)
        indexColor=round(data.intensity_loc*betaC)+1;
    else
        indexColor=indexAlpha;
    end

    % Rotate the light and view vector
    data.LightVector2=data.Mview\data.LightVector;
    data.LightVector2=data.LightVector2./sqrt(sum(data.LightVector2(1:3).^2));
    data.ViewerVector2=data.Mview\data.ViewerVector;
    data.ViewerVector2=data.ViewerVector2./sqrt(sum(data.ViewerVector2(1:3).^2));

    Ia=1;
    
    Id=data.N(:,:,1)*data.LightVector2(1)+data.N(:,:,2)*data.LightVector2(2)+data.N(:,:,3)*data.LightVector2(3);
    
    % R = 2.0*dot(N,L)*N - L;
    R(:,:,1)=2*Id.*data.N(:,:,1)-data.LightVector2(1); 
    R(:,:,2)=2*Id.*data.N(:,:,2)-data.LightVector2(2); 
    R(:,:,3)=2*Id.*data.N(:,:,3)-data.LightVector2(3);
    
    %Is = max(pow(dot(R,V),3),0);
    Is=-(R(:,:,1)*data.ViewerVector2(1)+R(:,:,2)*data.ViewerVector2(2)+R(:,:,3)*data.ViewerVector2(3)); 
    
    % No spectacular highlights on "shadow" part
    Is(Id<0)=0;
    
    % Specular exponent
    Is=Is.^data.material(4);
   
    % Phong shading values
    Ipar=zeros([size(Id) 2]);
    Ipar(:,:,1)=data.material(1)*Ia+data.material(2)*Id; 
    Ipar(:,:,2)=data.material(3)*Is;
	
    % calculate current alphaimage
    alphaimage=data.AlphaTable(indexAlpha);         
	alphaimage_inv=(1-alphaimage);
	
    % Update the current pixel in the shear image buffer
    data.Ibuffer(data.px,data.py,1)=alphaimage_inv.*data.Ibuffer(data.px,data.py,1)+alphaimage.*(data.ColorTable_r(indexColor).*Ipar(:,:,1)+Ipar(:,:,2));
    data.Ibuffer(data.px,data.py,2)=alphaimage_inv.*data.Ibuffer(data.px,data.py,2)+alphaimage.*(data.ColorTable_g(indexColor).*Ipar(:,:,1)+Ipar(:,:,2));
    data.Ibuffer(data.px,data.py,3)=alphaimage_inv.*data.Ibuffer(data.px,data.py,3)+alphaimage.*(data.ColorTable_b(indexColor).*Ipar(:,:,1)+Ipar(:,:,2));

function data=warp(data)  
% This function warp,  will warp the shear rendered buffer image

% Make Affine matrix
M=zeros(3,3);
M(1,1)=data.Mwarp2Dinv(1,1);
M(2,1)=data.Mwarp2Dinv(2,1);
M(1,2)=data.Mwarp2Dinv(1,2);
M(2,2)=data.Mwarp2Dinv(2,2);
M(1,3)=data.Mwarp2Dinv(1,3)+data.Mshearinv(1,4); 
M(2,3)=data.Mwarp2Dinv(2,3)+data.Mshearinv(2,4);

% Perform the affine transformation
switch(data.WarpInterp)
    case 'nearest', wi=5;
    case 'bicubic', wi=3;
    case 'bilinear', wi=1;
    otherwise, wi=1;
end
data.Iout=affine_transform_2d_double(data.Ibuffer,M,wi,data.ImageSize);

function [Mshear,Mwarp2D,c]=makeShearWarpMatrix(Mview,sizes)
% Function MAKESHEARWARPMATRIX splits a View Matrix in to
% a shear matrix and warp matrix, for efficient 3D volume rendering.
%
% [Mshear,Mwarp2D,c]=makeShearWarpMatrix(Mview,sizes)
%
% inputs,
%   Mview: The 4x4 viewing matrix
%   sizes: The sizes of the volume which will be rendered
%
% outputs,
%  Mshear: The shear matrix
%  Mwarp2D: The warp matrix
%  c: The principal viewing axis 1..6
%
% example,
%
%   Mview=makeViewMatrix([45 45 0],[0.5 0.5 0.5],[0 0 0]);
%   sizes=[512 512];
%   [Mshear,Mwarp2D,c]=makeShearWarpMatrix(Mview,sizes)
%
% Function is written by D.Kroon University of Twente (October 2008)

% Find the principal viewing axis
Vo=[Mview(1,2)*Mview(2,3) - Mview(2,2)*Mview(1,3);
    Mview(2,1)*Mview(1,3) - Mview(1,1)*Mview(2,3);
    Mview(1,1)*Mview(2,2) - Mview(2,1)*Mview(1,2)];

[maxv,c]=max(abs(Vo));

% Choose the corresponding Permutation matrix P
switch(c)
    case 1, %yzx
        P=[0 1 0 0; 0 0 1 0; 1 0 0 0; 0 0 0 1;];
    case 2, % zxy
        P=[0 0 1 0; 1 0 0 0; 0 1 0 0; 0 0 0 1;];
    case 3, % xyz
        P=[1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1;];
end

% Compute the permuted view matrix from Mview and P
Mview_p=Mview/P;

% 180 degrees rotate detection
if(Mview_p(3,3)<0), c=c+3; end

% Compute the shear coeficients from the permuted view matrix
Si = (Mview_p(2,2)* Mview_p(1,3) - Mview_p(1,2)* Mview_p(2,3)) / (Mview_p(1,1)* Mview_p(2,2) - Mview_p(2,1)* Mview_p(1,2));
Sj = (Mview_p(1,1)* Mview_p(2,3) - Mview_p(2,1)* Mview_p(1,3)) / (Mview_p(1,1)* Mview_p(2,2) - Mview_p(2,1)* Mview_p(1,2));

% Compute the translation between the orgins of standard object coordinates
% and intermdiate image coordinates

if((c==1)||(c==4)), kmax=sizes(1)-1; end
if((c==2)||(c==5)), kmax=sizes(2)-1; end
if((c==3)||(c==6)), kmax=sizes(3)-1; end

if ((Si>=0)&&(Sj>=0)), Ti = 0;        Tj = 0;        end
if ((Si>=0)&&(Sj<0)),  Ti = 0;        Tj = -Sj*kmax; end
if ((Si<0)&&(Sj>=0)),  Ti = -Si*kmax; Tj = 0;        end
if ((Si<0)&&(Sj<0)),   Ti = -Si*kmax; Tj = -Sj*kmax; end

% Compute the shear matrix 
Mshear=[1  0 Si Ti;
        0  1 Sj Tj;
        0  0  1  0;
        0  0  0  1];
        
% Compute the 2Dwarp matrix
Mwarp2D=[Mview_p(1,1) Mview_p(1,2) (Mview_p(1,4)-Ti*Mview_p(1,1)-Tj*Mview_p(1,2)); 
         Mview_p(2,1) Mview_p(2,2) (Mview_p(2,4)-Ti*Mview_p(2,1)-Tj*Mview_p(2,2)); 
               0           0                                  1                  ];

% Compute the 3Dwarp matrix
% Mwarp3Da=[Mview_p(1,1) Mview_p(1,2) (Mview_p(1,3)-Si*Mview_p(1,1)-Sj*Mview_p(1,2)) Mview_p(1,4); 
%           Mview_p(2,1) Mview_p(2,2) (Mview_p(2,3)-Si*Mview_p(2,1)-Sj*Mview_p(2,2)) Mview_p(2,4); 
%           Mview_p(3,1) Mview_p(3,2) (Mview_p(3,3)-Si*Mview_p(3,1)-Sj*Mview_p(3,2)) Mview_p(3,4); 
%                 0           0                                  0                        1      ];
% Mwarp3Db=[1 0 0 -Ti;
%           0 1 0 -Tj;
%           0 0 1   0;
%           0 0 0   1];
% Mwarp3D=Mwarp3Da*Mwarp3Db;
% % Control matrix Mview
% Mview_control = Mwarp3D*Mshear*P;
% disp(Mview)
% disp(Mview_control)

