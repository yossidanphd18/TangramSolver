function [Challenges] = create_challenges_lattice(TilesInfo, save_folder_path, save2mat)

if nargin < 3
    save2mat = 0;
end

% create the goal challenges and also save them to .mat files.
% 
    pw = 1;
    dims = [31,31];
    % see here : https://puzzler.sourceforge.net/docs/pentominoes.html

    npcs = TilesInfo.npcs;
    
    tile_scratch_size = TilesInfo.tile_scratch_size;
    w0 = floor(max(tile_scratch_size)*0.5) + 1;
    
    % Grid Spec    
    Grid  = []; % Grid information, models the problem.
%     Grid.nr = dims(1);
%     Grid.nc = dims(2);
    Grid.grid_dims = dims;
    Grid.flips = {1, 2}; 
    Grid.rot_angles  = [0, 90, 180, 270];
    Grid.rot_indxs   = [1, 2, 3, 4];
    Grid.origin_x0y0 = [w0, w0]; 
    Grid.tile_scratch_size = tile_scratch_size;
    Grid.w0 = w0;
    
    names = {};
    grids = {};
    
    %=============================
    % Square1 challenge
    %=============================
    SQ1 = zeros(dims);
    SQ1(1:8,1:8) = 1; 
    SQ1(1,1) = 0; 
    SQ1(1,8) = 0;
    SQ1(8,1) = 0; 
    SQ1(8,8) = 0;
    SQ1 = imtranslate(SQ1, [10,10] , 'FillValues', 0);
    Square1.puzzle = SQ1;
    
    % these are the true values for the square1
    true_flips(1:npcs) = 1; 
    true_flips(2:3) = 2; 
    true_rot_idxs = [1,1,2,3,3,2, 1,3,2,2,4,2];
    true_translations = {[4,3], [6,5], [3,6], [5,7], [1,6], [1,1], [6,1], [0,3], [2,2], [4,0], [2,4], [7,4]};
   % move the goal to be more centered (for better goal visualization)
   visual_offset = [8,8];
   for k = 1:length(true_translations)
      txy = true_translations{k};
      txy = txy + visual_offset;
      true_translations{k} = txy;
   end
    Square1.true_flips = true_flips;
    Square1.true_rot_idxs = true_rot_idxs;
    Square1.true_translations = true_translations;
    Square1.npcs = npcs;    
    clear true_flips  true_rot_idxs   true_translations
   
   filename = fullfile(save_folder_path,'Square1.mat');
   check_file_exist = isfile(filename);
   if(save2mat) % if(~check_file_exist)
        save(filename,'Square1');
        %save Square1 Square1        
   end
    %figure; imagesc(SQ1);
    names{pw} = 'Square1';
    grids{pw} = Grid;
    pw = pw + 1;
    
    
    
    %=============================
    % Square2 challenge
    %=============================
    SQ2 = zeros(dims);
    SQ2(1:8,1:8) = 1; 
    SQ2(4:5,4:5) = 0; 
    SQ2 = imtranslate(SQ2, [10,10] , 'FillValues', 0);
    Square2.puzzle = SQ2;
    % these are the true values for the square2
    true_flips(1:npcs) = 1; true_flips(2) = 2;  true_flips(5) = 2; true_flips(9) = 2; true_flips(11) = 2;  
    true_rot_idxs = [2,3,2,2,3, 1, 1, 1,2,1,1,1];
    true_translations = {[6,2], [1,4], [5,6], [0,1], [4,2], [3,6], [2,1], [7,4], [2,7], [7,6], [0,4], [5,0]};
    % move the goal to be more centered (for better goal visualization)
    visual_offset = [8,8];
    for k = 1:length(true_translations)
      txy = true_translations{k};
      txy = txy + visual_offset;
      true_translations{k} = txy;
    end
    Square2.true_flips = true_flips;
    Square2.true_rot_idxs = true_rot_idxs;
    Square2.true_translations = true_translations;
    Square2.npcs = npcs;
    clear true_flips  true_rot_idxs   true_translations
    % save(fullfile(save_folder_path,'Square2.mat'),'Square2');
    filename = fullfile(save_folder_path,'Square2.mat');
    check_file_exist = isfile(filename);
    if(save2mat) % if(~check_file_exist)
        save(filename,'Square2');
        %save Square2 Square2        
    end
    %figure; imagesc(SQ2);
    names{pw} = 'Square2';
    grids{pw} = Grid;
    pw = pw + 1;
            
    %=============================
    % Square3 challenge
    %=============================
    SQ3 = zeros(dims);
    SQ3(1:8,1:8) = 1; 
    SQ3(2,2) = 0; 
    SQ3(2,7) = 0;
    SQ3(7,2) = 0; 
    SQ3(7,7) = 0;
    SQ3 = imtranslate(SQ3, [10,10] , 'FillValues', 0);
    Square3.puzzle = SQ3;
    % these are the true values for the square3
    true_flips(1:npcs) = 1;
    true_rot_idxs = [2,2,1,3,1, 2, 1, 1,1,4,4,2];
    true_translations = {[3,6], [4,0], [2,4], [1,7], [5,2], [5,6], [2,2], [7,7], [0,3], [5,4], [1,0], [7,2]};
    % move the goal to be more centered (for better goal visualization)
    visual_offset = [8,8];
    for k = 1:length(true_translations)
      txy = true_translations{k};
      txy = txy + visual_offset;
      true_translations{k} = txy;
    end
    Square3.true_flips = true_flips;
    Square3.true_rot_idxs = true_rot_idxs;
    Square3.true_translations = true_translations;
    Square3.npcs = npcs;
    clear true_flips  true_rot_idxs   true_translations
    %save(fullfile(save_folder_path,'Square3.mat'),'Square3');
    filename = fullfile(save_folder_path,'Square3.mat');
    check_file_exist = isfile(filename);
    if(save2mat) % if(~check_file_exist)
        save(filename,'Square3');
        %save Square3 Square3        
    end    
    %figure; imagesc(SQ3);
    names{pw} = 'Square3';
    grids{pw} = Grid;
    pw = pw + 1;
        
    %=============================
    % Kangaroo challenge
    %=============================
    % kangaroo already prepared and saved separately.
    Kngroo = load('Kangaroo.mat');
    Kangaroo = Kngroo.Kangaroo;
    clear Kngroo
if(0) % kangaroo already prepared and saved separately.
%     Kangaroo.puzzle = Kngroo.Kangaroo.puzzle;
%     % these are the true values for the kangaroo
%     true_flips(1:npcs) = 1;
%     true_rot_idxs(1:npcs) = 1;
%     true_translations = {[5,4], [6,6], [4,8], [5,9], [5,11], [8,11], [7,12], [4,15], [5,13], [9,14], [10,14], [14,15]};
%     % move the goal to be more centered (for better goal visualization)
%     visual_offset = [0,0];
%     for k = 1:length(true_translations)
%       txy = true_translations{k};
%       txy = txy + visual_offset;
%       true_translations{k} = txy;
%     end
%     Kangaroo.true_flips = true_flips;
%     Kangaroo.true_rot_idxs = true_rot_idxs;
%     Kangaroo.true_translations = true_translations;
%     Kangaroo.npcs = npcs;
%     clear true_flips  true_rot_idxs   true_translations
%     filename = fullfile(save_folder_path,'Kangaroo.mat');
%     check_file_exist = isfile(filename);
%     if(1) % if(~check_file_exist)
%         save(filename,'Kangaroo');
%     end        
end
    names{pw} = 'Kangaroo';
    grids{pw} = Grid;
    pw = pw + 1;
    
    %=============================
    N = length(names);
    names = reshape(names,N,[]);
    grids = reshape(grids,N,[]);

    Challenges = [];
    Challenges.Names = names;
    Challenges.Grids = grids;
    Challenges.Goals = {[],[],[],[]};
    
end


