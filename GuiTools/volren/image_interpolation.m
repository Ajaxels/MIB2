function Iout = image_interpolation(Iin,Tlocalx,Tlocaly,Interpolation,Boundary,ImageSize)
% This function is used to transform an 2D image, in a backwards way with an
% transformation image.
%
%   Iout = image_interpolation(Iin,Tlocalx,Tlocaly,Interpolation,Boundary,ImageSize)
%
% inputs,
%	   Iin : 2D greyscale or color input image
%	   Tlocalx,Tlocaly : (Backwards) Transformation images for all image pixels
%	   Interpolation:
%       'nearest'    - nearest-neighbor interpolation
%       'bilinear'   - bilinear interpolation
%       'bicubic'    - cubic interpolation; the default method
%      Boundary:
%       'zero'       - outside input image are implicilty assumed to be zero
%       'replicate'  - Input array values outside the bounds of the array
%                      are assumed to equal the nearest array border value
%	(optional)
%	   ImageSize:    - Size of output image
% outputs,
%  	   Iout : The transformed image
%
% Function is written by D.Kroon University of Twente (September 2010)

if(~isa(Iin,'double')), Iin=double(Iin); end
if(nargin<6), ImageSize=[size(Iin,1) size(Iin,2)]; end
if(ndims(Iin)==2), lo=1; else lo=3; end

switch(lower(Interpolation))
    case 'nearest'
        xBas0=round(Tlocalx);
        yBas0=round(Tlocaly);
    case 'bilinear'
        xBas0=floor(Tlocalx);
        yBas0=floor(Tlocaly);
        xBas1=xBas0+1;
        yBas1=yBas0+1;
        
        % Linear interpolation constants (percentages)
        tx=Tlocalx-xBas0;
        ty=Tlocaly-yBas0;
        perc0=(1-tx).*(1-ty);
        perc1=(1-tx).*ty;
        perc2=tx.*(1-ty);
        perc3=tx.*ty;
    case 'bicubic'
        xBas0=floor(Tlocalx);
        yBas0=floor(Tlocaly);
        tx=Tlocalx-xBas0;
        ty=Tlocaly-yBas0;
        
        % Determine the t vectors
        vec_tx0= 0.5; vec_tx1= 0.5*tx; vec_tx2= 0.5*tx.^2; vec_tx3= 0.5*tx.^3;
        vec_ty0= 0.5; vec_ty1= 0.5*ty; vec_ty2= 0.5*ty.^2;vec_ty3= 0.5*ty.^3;
        
        % t vector multiplied with 4x4 bicubic kernel gives the to q vectors
        vec_qx0= -1.0*vec_tx1 + 2.0*vec_tx2 - 1.0*vec_tx3;
        vec_qx1=  2.0*vec_tx0 - 5.0*vec_tx2 + 3.0*vec_tx3;
        vec_qx2=  1.0*vec_tx1 + 4.0*vec_tx2 - 3.0*vec_tx3;
        vec_qx3= -1.0*vec_tx2 + 1.0*vec_tx3;
        
        vec_qy0= -1.0*vec_ty1 + 2.0*vec_ty2 - 1.0*vec_ty3;
        vec_qy1=  2.0*vec_ty0 - 5.0*vec_ty2 + 3.0*vec_ty3;
        vec_qy2=  1.0*vec_ty1 + 4.0*vec_ty2 - 3.0*vec_ty3;
        vec_qy3= -1.0*vec_ty2 + 1.0*vec_ty3;
        
        % Determine 1D neighbour coordinates
        xn0=xBas0-1; xn1=xBas0; xn2=xBas0+1; xn3=xBas0+2;
        yn0=yBas0-1; yn1=yBas0; yn2=yBas0+1; yn3=yBas0+2;
    otherwise
        error('image_interpolation:inputs','unknown interpolation method');
end

% limit indexes to boundaries
switch(lower(Interpolation))
    case 'nearest'
        check_xBas0=(xBas0<0)|(xBas0>(size(Iin,1)-1));
        check_yBas0=(yBas0<0)|(yBas0>(size(Iin,2)-1));
        xBas0=min(max(xBas0,0),size(Iin,1)-1);
        yBas0=min(max(yBas0,0),size(Iin,2)-1);
    case 'bilinear'
        check_xBas0=(xBas0<0)|(xBas0>(size(Iin,1)-1));
        check_yBas0=(yBas0<0)|(yBas0>(size(Iin,2)-1));
        check_xBas1=(xBas1<0)|(xBas1>(size(Iin,1)-1));
        check_yBas1=(yBas1<0)|(yBas1>(size(Iin,2)-1));
        xBas0=min(max(xBas0,0),size(Iin,1)-1);
        yBas0=min(max(yBas0,0),size(Iin,2)-1);
        xBas1=min(max(xBas1,0),size(Iin,1)-1);
        yBas1=min(max(yBas1,0),size(Iin,2)-1);
    case 'bicubic'
        check_xn0=(xn0<0)|(xn0>(size(Iin,1)-1));
        check_xn1=(xn1<0)|(xn1>(size(Iin,1)-1));
        check_xn2=(xn2<0)|(xn2>(size(Iin,1)-1));
        check_xn3=(xn3<0)|(xn3>(size(Iin,1)-1));
        check_yn0=(yn0<0)|(yn0>(size(Iin,2)-1));
        check_yn1=(yn1<0)|(yn1>(size(Iin,2)-1));
        check_yn2=(yn2<0)|(yn2>(size(Iin,2)-1));
        check_yn3=(yn3<0)|(yn3>(size(Iin,2)-1));
        xn0=min(max(xn0,0),size(Iin,1)-1);
        xn1=min(max(xn1,0),size(Iin,1)-1);
        xn2=min(max(xn2,0),size(Iin,1)-1);
        xn3=min(max(xn3,0),size(Iin,1)-1);
        yn0=min(max(yn0,0),size(Iin,2)-1);
        yn1=min(max(yn1,0),size(Iin,2)-1);
        yn2=min(max(yn2,0),size(Iin,2)-1);
        yn3=min(max(yn3,0),size(Iin,2)-1);
end

Iout=zeros([ImageSize(1:2) lo]);
for i=1:lo; % Loop incase of RGB
    Iin_one=Iin(:,:,i);
    switch(lower(Interpolation))
        case 'nearest'
            % Get the intensities
            intensity_xyz0=Iin_one(1+xBas0+yBas0*size(Iin,1));
            
            % Set pixels outside the image
            switch(lower(Boundary))
                case 'zero'
                    intensity_xyz0(check_xBas0|check_yBas0)=0;
                otherwise
            end
            
            % Combine the weighted neighbour pixel intensities
            Iout_one=intensity_xyz0;
        case 'bilinear'
            % Get the intensities
            intensity_xyz0=Iin_one(1+xBas0+yBas0*size(Iin,1));
            intensity_xyz1=Iin_one(1+xBas0+yBas1*size(Iin,1));
            intensity_xyz2=Iin_one(1+xBas1+yBas0*size(Iin,1));
            intensity_xyz3=Iin_one(1+xBas1+yBas1*size(Iin,1));
            
            % Set pixels outside the image
            switch(lower(Boundary))
                case 'zero'
                    intensity_xyz0(check_xBas0|check_yBas0)=0;
                    intensity_xyz1(check_xBas0|check_yBas1)=0;
                    intensity_xyz2(check_xBas1|check_yBas0)=0;
                    intensity_xyz3(check_xBas1|check_yBas1)=0;
                otherwise
            end
            
            % Combine the weighted neighbour pixel intensities
            Iout_one=intensity_xyz0.*perc0+intensity_xyz1.*perc1+intensity_xyz2.*perc2+intensity_xyz3.*perc3;
        case 'bicubic'
            % Get the intensities
            Iy0x0=Iin_one(1+xn0+yn0*size(Iin,1));Iy0x1=Iin_one(1+xn1+yn0*size(Iin,1));
            Iy0x2=Iin_one(1+xn2+yn0*size(Iin,1));Iy0x3=Iin_one(1+xn3+yn0*size(Iin,1));
            Iy1x0=Iin_one(1+xn0+yn1*size(Iin,1));Iy1x1=Iin_one(1+xn1+yn1*size(Iin,1));
            Iy1x2=Iin_one(1+xn2+yn1*size(Iin,1));Iy1x3=Iin_one(1+xn3+yn1*size(Iin,1));
            Iy2x0=Iin_one(1+xn0+yn2*size(Iin,1));Iy2x1=Iin_one(1+xn1+yn2*size(Iin,1));
            Iy2x2=Iin_one(1+xn2+yn2*size(Iin,1));Iy2x3=Iin_one(1+xn3+yn2*size(Iin,1));
            Iy3x0=Iin_one(1+xn0+yn3*size(Iin,1));Iy3x1=Iin_one(1+xn1+yn3*size(Iin,1));
            Iy3x2=Iin_one(1+xn2+yn3*size(Iin,1));Iy3x3=Iin_one(1+xn3+yn3*size(Iin,1));
            
            % Set pixels outside the image
            switch(lower(Boundary))
                case 'zero'
                    Iy0x0(check_yn0|check_xn0)=0;Iy0x1(check_yn0|check_xn1)=0;
                    Iy0x2(check_yn0|check_xn2)=0;Iy0x3(check_yn0|check_xn3)=0;
                    Iy1x0(check_yn1|check_xn0)=0;Iy1x1(check_yn1|check_xn1)=0;
                    Iy1x2(check_yn1|check_xn2)=0;Iy1x3(check_yn1|check_xn3)=0;
                    Iy2x0(check_yn2|check_xn0)=0;Iy2x1(check_yn2|check_xn1)=0;
                    Iy2x2(check_yn2|check_xn2)=0;Iy2x3(check_yn2|check_xn3)=0;
                    Iy3x0(check_yn3|check_xn0)=0;Iy3x1(check_yn3|check_xn1)=0;
                    Iy3x2(check_yn3|check_xn2)=0;Iy3x3(check_yn3|check_xn3)=0;
                otherwise
            end
            
            % Combine the weighted neighbour pixel intensities
            Iout_one=vec_qy0.*(vec_qx0.*Iy0x0+vec_qx1.*Iy0x1+vec_qx2.*Iy0x2+vec_qx3.*Iy0x3)+...
                vec_qy1.*(vec_qx0.*Iy1x0+vec_qx1.*Iy1x1+vec_qx2.*Iy1x2+vec_qx3.*Iy1x3)+...
                vec_qy2.*(vec_qx0.*Iy2x0+vec_qx1.*Iy2x1+vec_qx2.*Iy2x2+vec_qx3.*Iy2x3)+...
                vec_qy3.*(vec_qx0.*Iy3x0+vec_qx1.*Iy3x1+vec_qx2.*Iy3x2+vec_qx3.*Iy3x3);
    end
    Iout(:,:,i)=reshape(Iout_one, ImageSize);
end





