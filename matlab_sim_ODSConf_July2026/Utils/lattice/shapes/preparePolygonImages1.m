function [TImages, GP] = preparePolygonImages1(GP)

if(GP.use_equal_pixels_value)
    pixel_values = 231*ones(1,50);
else
    pixel_values = randi([35,1000],1,50);
end

% zpad_vec = [2,0];
% goalImage = padarray(goalImage, zpad_vec, 0, 'post');

GP.rot_angles = [0, 90, 180, 270];

nrots = length(GP.rot_angles);
GP.nrots = nrots;

if(GP.use_long_rect_dims == 1)
    ZerosImage = zeros(GP.Nr_w_pad, GP.Nc); % un-intentional "bug" that led to rotation recovery!
else
    Nrc = max([GP.Nr_wo_pad, GP.Nc]);
    ZerosImage = zeros(Nrc, Nrc);
end

GP.xcenter = 0.5*(GP.Nc-1) + 1;
GP.ycenter = 0.5*(GP.Nr_wo_pad-1) + 1;

c0 = GP.xcenter;
r0 = GP.ycenter;

true_rot_idxs = [];
true_rot_angles = [];
true_translations = {};
true_rot_idxs_with_symetry = {};

txy_offset = GP.txy_offset;
%==================================================================================
% Create Basic Shapes (tans) and their rotations
%==================================================================================

pw = 1;

% Shape 1 
%
%        x
%   x x [x]
%        x
%
Image = ZerosImage;
Image(r0-1:r0+1, c0) = pixel_values(pw);
Image(r0, c0-2:c0) = pixel_values(pw);
rot_idx = randi([1,4],1,1); % assuming some random angle position in the center of axis. so rand between 4 angles.
rot_angle = -GP.rot_angles(rot_idx);
Image = imrotate(Image, rot_angle);
true_rot_idxs(pw) = rot_idx;
true_rot_angles(pw) = -rot_angle;
true_rot_idxs_with_symetry{pw} = [rot_idx]; 
for r = 1:nrots
    rotImage = imrotate(Image, GP.rot_angles(r)); 
    TImages.Shapes{pw}.RotatedImages{r} = rotImage; 
    % figure; imagesc(rotImage);
    % dbg = 1;
end
txy = [-5, -2] + txy_offset;
TImages.Shapes{pw}.t_xy = txy;
TImages.Shapes{pw}.mass = 5; % number of non-zero pixels.
true_translations{pw} = txy;
pw = pw + 1;

% dbg = 1;

if(GP.limit_nshapes >= 2)

    % Shape 2
    %
    %     x
    %     x [x]
    %        x
    %        x
    %
    Image = ZerosImage;
    Image(r0:r0+2, c0) = pixel_values(pw);
    Image(r0-1:r0, c0-1) = pixel_values(pw);
    % TImages.Shapes{pw}.RotatedImages{1} = Image; 
    rot_idx = randi([1,4],1,1);
    rot_angle = -GP.rot_angles(rot_idx);
    Image = imrotate(Image, rot_angle);
    true_rot_idxs(pw) = rot_idx;
    true_rot_angles(pw) = -rot_angle;
    true_rot_idxs_with_symetry{pw} = [rot_idx]; 
    for r = 1:nrots
        rotImage = imrotate(Image, GP.rot_angles(r)); 
        TImages.Shapes{pw}.RotatedImages{r} = rotImage; 
    end
    % TImages.Shapes{pw}.t_xy = [-5, 0];
    txy = [-5, 0]  + txy_offset;
    TImages.Shapes{pw}.t_xy = txy;
    TImages.Shapes{pw}.mass = 5; % number of non-zero pixels.
    true_translations{pw} = txy;
    pw = pw + 1;

end

if(GP.limit_nshapes >= 3)

    % Shape 3 
    %
    %           x
    %     x [x] x
    %     x
    %     
    Image = ZerosImage;
    Image(r0, c0-1:c0+1) = pixel_values(pw);
    Image(r0-1, c0+1) = pixel_values(pw);
    Image(r0+1, c0-1) = pixel_values(pw);
    %TImages.Shapes{pw}.RotatedImages{1} = Image; 
    rot_idx = randi([1,4],1,1);
    rot_angle = -GP.rot_angles(rot_idx);
    Image = imrotate(Image, rot_angle);
    true_rot_idxs(pw) = rot_idx;
    true_rot_angles(pw) = -rot_angle;
    % this shape has rotation symetry
    rot_idx_sym = rot_idx + 2; if (rot_idx_sym > 4); rot_idx_sym = rot_idx_sym-4; end
    true_rot_idxs_with_symetry{pw} = [rot_idx, rot_idx_sym]; 
    for r = 1:nrots
        rotImage = imrotate(Image, GP.rot_angles(r)); 
        TImages.Shapes{pw}.RotatedImages{r} = rotImage; 
    end
    % TImages.Shapes{pw}.t_xy = [-7, 2];
    txy = [-7, 2] + txy_offset;
    TImages.Shapes{pw}.t_xy = txy;
    TImages.Shapes{pw}.mass = 5; % number of non-zero pixels.
    true_translations{pw} = txy;
    pw = pw + 1;

end

if(GP.limit_nshapes >= 4)

    % Shape 4 
    %           
    %     x [x] x
    %     x     x
    %     
    Image = ZerosImage;
    Image(r0, c0-1:c0+1) = pixel_values(pw);
    Image(r0+1, c0-1) = pixel_values(pw);
    Image(r0+1, c0+1) = pixel_values(pw);
    %TImages.Shapes{pw}.RotatedImages{1} = Image; 
    rot_idx = randi([1,4],1,1);
    rot_angle = -GP.rot_angles(rot_idx);
    Image = imrotate(Image, rot_angle);
    true_rot_idxs(pw) = rot_idx;
    true_rot_angles(pw) = -rot_angle;
    true_rot_idxs_with_symetry{pw} = [rot_idx]; 
    
    for r = 1:nrots
        rotImage = imrotate(Image, GP.rot_angles(r)); 
        TImages.Shapes{pw}.RotatedImages{r} = rotImage; 
    end
    % TImages.Shapes{pw}.t_xy = [-5, 3];
    txy = [-5, 3] + txy_offset;
    TImages.Shapes{pw}.t_xy = txy;
    TImages.Shapes{pw}.mass = 5; % number of non-zero pixels.
    true_translations{pw} = txy;
    pw = pw + 1;

end

if(GP.limit_nshapes >= 5)

    % Shape 5 
    %
    %        x   
    %     x [x] x
    %     x
    %     
    Image = ZerosImage;
    Image(r0, c0-1:c0+1) = pixel_values(pw);
    Image(r0-1, c0) = pixel_values(pw);
    Image(r0+1, c0-1) = pixel_values(pw);
    % TImages.Shapes{pw}.RotatedImages{1} = Image; 
    rot_idx = randi([1,4],1,1);
    rot_angle = -GP.rot_angles(rot_idx);
    Image = imrotate(Image, rot_angle);
    true_rot_idxs(pw) = rot_idx;
    true_rot_angles(pw) = -rot_angle;
    true_rot_idxs_with_symetry{pw} = [rot_idx];         
    for r = 1:nrots
        rotImage = imrotate(Image, GP.rot_angles(r)); 
        TImages.Shapes{pw}.RotatedImages{r} = rotImage; 
    end
    % TImages.Shapes{pw}.t_xy = [-5, 5];
    txy = [-5, 5] + txy_offset;
    TImages.Shapes{pw}.t_xy = txy;
    TImages.Shapes{pw}.mass = 5; % number of non-zero pixels.
    true_translations{pw} = txy;
    pw = pw + 1;

end

if(GP.limit_nshapes >= 6)

    % Shape 6 
    %
    %     x  x   
    %       [x] x
    %           x
    %     
    Image = ZerosImage;
    Image(r0, c0:c0+1) = pixel_values(pw);
    Image(r0-1, c0-1:c0) = pixel_values(pw);
    Image(r0+1, c0+1) = pixel_values(pw);
    % TImages.Shapes{pw}.RotatedImages{1} = Image; 
    rot_idx = randi([1,4],1,1);
    rot_angle = -GP.rot_angles(rot_idx);
    Image = imrotate(Image, rot_angle);
    true_rot_idxs(pw) = rot_idx;
    true_rot_angles(pw) = -rot_angle;
    true_rot_idxs_with_symetry{pw} = [rot_idx];         
    for r = 1:nrots
        rotImage = imrotate(Image, GP.rot_angles(r)); 
        TImages.Shapes{pw}.RotatedImages{r} = rotImage; 
    end
    % TImages.Shapes{pw}.t_xy = [-2, 5];
    txy = [-2, 5] + txy_offset;
    TImages.Shapes{pw}.t_xy = txy;
    TImages.Shapes{pw}.mass = 5; % number of non-zero pixels.
    true_translations{pw} = txy;
    pw = pw + 1;
       
end

if(GP.limit_nshapes >= 7)

    % Shape 7 
    %
    %           x
    %        x [x] x
    %           x
    %     
    Image = ZerosImage;
    Image(r0, c0-1:c0+1) = pixel_values(pw);
    Image(r0-1:r0+1, c0) = pixel_values(pw);
    % TImages.Shapes{pw}.RotatedImages{1} = Image; 
    rot_idx = randi([1,4],1,1);
    rot_angle = -GP.rot_angles(rot_idx);
    Image = imrotate(Image, rot_angle);
    true_rot_idxs(pw) = rot_idx;
    true_rot_angles(pw) = -rot_angle;
    % this shape has rotation symetry
    true_rot_idxs_with_symetry{pw} = [1,2,3,4]; 
    for r = 1:nrots
        rotImage = imrotate(Image, GP.rot_angles(r)); 
        TImages.Shapes{pw}.RotatedImages{r} = rotImage; 
    end
    % TImages.Shapes{pw}.t_xy = [-3, 6];
    txy = [-3, 6] + txy_offset;
    TImages.Shapes{pw}.t_xy = txy;
    TImages.Shapes{pw}.mass = 5; % number of non-zero pixels.
    true_translations{pw} = txy;
    pw = pw + 1;
        
end

if(GP.limit_nshapes >= 8)

    % Shape 8 
    %
    %          x
    %          x 
    %     x x [x]
    %     
    Image = ZerosImage;
    Image(r0, c0-2:c0) = pixel_values(pw);
    Image(r0-2:r0, c0) = pixel_values(pw);
    % TImages.Shapes{pw}.RotatedImages{1} = Image; 
    rot_idx = randi([1,4],1,1);
    rot_angle = -GP.rot_angles(rot_idx);
    Image = imrotate(Image, rot_angle);
    true_rot_idxs(pw) = rot_idx;
    true_rot_angles(pw) = -rot_angle;
    true_rot_idxs_with_symetry{pw} = [rot_idx]; 
    for r = 1:nrots
        rotImage = imrotate(Image, GP.rot_angles(r)); 
        TImages.Shapes{pw}.RotatedImages{r} = rotImage; 
    end
    % TImages.Shapes{pw}.t_xy = [-6, 9];
    txy = [-6, 9] + txy_offset;
    TImages.Shapes{pw}.t_xy = txy;
    TImages.Shapes{pw}.mass = 5; % number of non-zero pixels.
    true_translations{pw} = txy;
    pw = pw + 1;

end

if(GP.limit_nshapes >= 9)

    % Shape 9 
    %
    %      x
    %     [x] x 
    %      x
    %      x
    %
    Image = ZerosImage;
    Image(r0-1:r0+2, c0) = pixel_values(pw);
    Image(r0, c0+1) = pixel_values(pw);
    % TImages.Shapes{pw}.RotatedImages{1} = Image; 
    rot_idx = randi([1,4],1,1);
    rot_angle = -GP.rot_angles(rot_idx);
    Image = imrotate(Image, rot_angle);
    true_rot_idxs(pw) = rot_idx;
    true_rot_angles(pw) = -rot_angle;
    true_rot_idxs_with_symetry{pw} = [rot_idx]; 
    for r = 1:nrots
        rotImage = imrotate(Image, GP.rot_angles(r)); 
        TImages.Shapes{pw}.RotatedImages{r} = rotImage; 
    end
    % TImages.Shapes{pw}.t_xy = [-5, 7];
    txy = [-5, 7] + txy_offset;
    TImages.Shapes{pw}.t_xy = txy;
    TImages.Shapes{pw}.mass = 5; % number of non-zero pixels.
    true_translations{pw} = txy;
    pw = pw + 1;

end

if(GP.limit_nshapes >= 10)

    % Shape 10 
    %
    %      x [x]
    %      x  x 
    %         x
    %      
    %
    Image = ZerosImage;
    Image(r0:r0+1, c0-1:c0) = pixel_values(pw);
    Image(r0+2, c0) = pixel_values(pw);
    %TImages.Shapes{pw}.RotatedImages{1} = Image; 
    rot_idx = randi([1,4],1,1);
    rot_angle = -GP.rot_angles(rot_idx);
    Image = imrotate(Image, rot_angle);
    true_rot_idxs(pw) = rot_idx;
    true_rot_angles(pw) = -rot_angle;
    true_rot_idxs_with_symetry{pw} = [rot_idx]; 
    for r = 1:nrots
        rotImage = imrotate(Image, GP.rot_angles(r)); 
        TImages.Shapes{pw}.RotatedImages{r} = rotImage; 
    end
    % TImages.Shapes{pw}.t_xy = [-1, 7];
    txy = [-1, 7] + txy_offset;
    TImages.Shapes{pw}.t_xy = txy;
    TImages.Shapes{pw}.mass = 5; % number of non-zero pixels.
    true_translations{pw} = txy;
    pw = pw + 1;

end

if(GP.limit_nshapes >= 11)

    % Shape 11 
    %
    %      x 
    %      x  
    %      x  
    %     [x] x
    %
    Image = ZerosImage;
    Image(r0-3:r0, c0) = pixel_values(pw);
    Image(r0, c0+1) = pixel_values(pw);
    %TImages.Shapes{pw}.RotatedImages{1} = Image; 
    rot_idx = randi([1,4],1,1);
    rot_angle = -GP.rot_angles(rot_idx);
    Image = imrotate(Image, rot_angle);
    true_rot_idxs(pw) = rot_idx;
    true_rot_angles(pw) = -rot_angle;
    true_rot_idxs_with_symetry{pw} = [rot_idx]; 
    for r = 1:nrots
        rotImage = imrotate(Image, GP.rot_angles(r)); 
        TImages.Shapes{pw}.RotatedImages{r} = rotImage; 
    end
    % TImages.Shapes{pw}.t_xy = [0, 9];
    txy = [0, 9] + txy_offset;
    TImages.Shapes{pw}.t_xy = txy;
    TImages.Shapes{pw}.mass = 5; % number of non-zero pixels.
    true_translations{pw} = txy;
    pw = pw + 1;

end

if(GP.limit_nshapes >= 12)

    % Shape 12 
    %
    %      x x [x] x x 
    %      
    %         
    Image = ZerosImage;
    Image(r0, c0-2:c0+2) = pixel_values(pw);
    %TImages.Shapes{pw}.RotatedImages{1} = Image; 
    rot_idx = randi([1,4],1,1);
    rot_angle = -GP.rot_angles(rot_idx);
    Image = imrotate(Image, rot_angle);
    true_rot_idxs(pw) = rot_idx;
    true_rot_angles(pw) = -rot_angle;
    % this shape has rotation symetry
    rot_idx_sym = rot_idx + 2; if (rot_idx_sym > 4); rot_idx_sym = rot_idx_sym-4; end
    true_rot_idxs_with_symetry{pw} = [rot_idx, rot_idx_sym]; 
    for r = 1:nrots
        rotImage = imrotate(Image, GP.rot_angles(r)); 
        TImages.Shapes{pw}.RotatedImages{r} = rotImage; 
    end
    % TImages.Shapes{pw}.t_xy = [4, 9];
    txy = [4, 9] + txy_offset;
    TImages.Shapes{pw}.t_xy = txy;
    TImages.Shapes{pw}.mass = 5; % number of non-zero pixels.
    true_translations{pw} = txy;
    pw = pw + 1;

end

npcs = length(TImages.Shapes);
GP.npcs = npcs;
GP.pixel_values = pixel_values(1:npcs);

% for k = 1:npcs
%     figure; imagesc(TImages.Shapes.Im{k});
% end

%==================================================================================
% Create the Goal shape
%==================================================================================
GoalImage = ZerosImage;

for k = 1:npcs
    rot_idx = true_rot_idxs(k) ;
    Im = TImages.Shapes{k}.RotatedImages{rot_idx} ;
    txy = true_translations{k} ; 
    GoalImage = GoalImage + imtranslate(Im, txy , 'FillValues', 0);
end
nr = GP.Nr_wo_pad;
nc = GP.Nc;
figure; imagesc(GoalImage(1:nr, 1:nc)); title('Goal image (ground truth)');

TImages.Goal = GoalImage;
TImages.true_rot_idxs = true_rot_idxs;
TImages.true_rot_idxs_with_symetry = true_rot_idxs_with_symetry;
TImages.true_rot_angles = true_rot_angles;
TImages.true_translations = true_translations;
TImages.pixel_values  = GP.pixel_values;

% %==================================================================================
% % Find the strongest FFT bins of the Goal image
% %==================================================================================
% [u_k, b_k] = selectOptimizationBins(0, GP);
% [signal_1D] = reshapeTo1D(TImages.Goal) ;         
% signalFFT = calcDft1D_FD(signal_1D, GP.nfft);
% signalFFT = abs(signalFFT(b_k));
% max_abs_fft = max(signalFFT);
% strongest_k = find(signalFFT == max_abs_fft); 
% strongest_k = strongest_k(1);
% strongest_k = b_k(strongest_k);
% GP.strongest_bin_k = strongest_k;

fprintf("\n---> completed PREPS stage 1..\n");

end % of function.