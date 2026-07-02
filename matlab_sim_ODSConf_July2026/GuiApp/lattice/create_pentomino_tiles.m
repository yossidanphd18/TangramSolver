function [TilesInfo] = create_pentomino_tiles(tile_scratch_dims)

if(nargin < 1)
    tile_scratch_dims = [5,5];
end

pw = 1;
BTiles = {};
BNames = {};

% cell value "2" indicates the center w.r.t. rotations.
% we place it at the "center of mass" of the tile, to minimize the span
% when rotated.
%

%============
% Tile 1
%============
tile = [0 0 1;...
        1 2 1;... 
        0 0 1;];
name = 'Tile1';

BTiles{pw} = tile;
BNames{pw} = name;
pw = pw + 1;

%============
% Tile 2	
%============
tile =  [1 0;...
         1 2;... 
         0 1;...
         0 1;];
name = 'Tile2';

BTiles{pw} = tile;
BNames{pw} = name;
pw = pw + 1;

%============
% Tile 3
%============
tile =  [0 0 1;...
         1 2 1;... 
         1 0 0;];
name = 'Tile3';

BTiles{pw} = tile;
BNames{pw} = name;
pw = pw + 1;

%============
% Tile 4
%============
tile =  [1 2 1;...
         1 0 1;];  
name = 'Tile4';

BTiles{pw} = tile;
BNames{pw} = name;
pw = pw + 1;


%============
% Tile 5
%============
tile =  [0 1 0;...
         1 2 1;...
		 1 0 0;];				 
name = 'Tile5';

BTiles{pw} = tile;
BNames{pw} = name;
pw = pw + 1;

%============
% Tile 6
%============
tile =  [1 1 0;...
         0 2 1;...
		 0 0 1;]; 			 
name = 'Tile6';

BTiles{pw} = tile;
BNames{pw} = name;
pw = pw + 1;


%============
% Tile 7
%============
tile =  [0 1 0;...
         1 2 1;...
		 0 1 0;]; 		 
name = 'Tile7';

BTiles{pw} = tile;
BNames{pw} = name;
pw = pw + 1;

%============
% Tile 8
%============
tile =  [0 0 1;...
         0 0 1;...
		 1 1 2;]; 	 
name = 'Tile8';

BTiles{pw} = tile;
BNames{pw} = name;
pw = pw + 1;

%============
% Tile 9
%============
tile =  [1 0;...
         2 1;...
		 1 0;...
		 1 0;];  
name = 'Tile9';

BTiles{pw} = tile;
BNames{pw} = name;
pw = pw + 1;

%============
% Tile 10
%============
tile =  [1 1;...
         1 2;...
	     0 1;]; 				
name = 'Tile10';

BTiles{pw} = tile;
BNames{pw} = name;
pw = pw + 1;

%============
% Tile 11
%============
tile =  [1 0;...
         1 0;...
	     2 0;...
         1 1;]; 			 
name = 'Tile11';

BTiles{pw} = tile;
BNames{pw} = name;
pw = pw + 1;

%============
% Tile 12
%============
tile = [1 1 2 1 1;]; 			 
name = 'Tile12';

BTiles{pw} = tile;
BNames{pw} = name;
pw = pw + 1;

%====================================
% TilesInfo struct
%====================================
TilesInfo.Tiles = BTiles;
TilesInfo.Names = BNames;
TilesInfo.npcs = length(BTiles);
TilesInfo.tile_scratch_dims = tile_scratch_dims;
TilesInfo.max_mass = 5;

% Map names to ids.
keySet = TilesInfo.Names ;
valueSet = 1:length(TilesInfo.Names);
TilesMap = containers.Map(keySet,valueSet);

TilesInfo.TilesMap = TilesMap;

end
