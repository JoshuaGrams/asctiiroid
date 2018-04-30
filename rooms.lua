-- A room consists of a list of the tiles which make up the
-- room.  A walker enters at (0, 0). Exits should be at the
-- edge of the room (more or less) in the six directions
-- (clockwise from positive x, which is down-right).

return {
	hex = {
		{0,0},
		exits = {
			{1,0}, {0,1}, {-1,1}, {-1,0}, {0,-1}, {1,-1}
		}
	},
	rhomb = {  -- 4 hexes make a rhombus.
		{0,0}, {0,1},
		{1,0}, {1,1},
		exits = {
			{2,0}, {1,1}, {0,1}, {-1,1}, {0,0}, {1,1}
		}
	},
	hex2 = {  -- 7 hexes make a hex with length 2 sides.
		{0,0}, {0,1},
		{1,-1}, {1,0}, {1,1},
		{2,-1}, {2,0},
		exits = {
			{2,0}, {1,1}, {0,1}, {0,0}, {1,-1}, {2,-1}
		}
	},
	hex3 = {  -- 19 hexes make a hex with length 3 sides.
		{0,0}, {0,1}, {0,2},
		{1,-1}, {1,0}, {1,1}, {1,2},
		{2,-2}, {2,-1}, {2,0}, {2,1}, {2,2},
		{3,-2}, {3,-1}, {3,0}, {3,1},
		{4,-2}, {4,-1}, {4,0},
		exits = {
			{2,0}, {1,1}, {0,1}, {0,0}, {1,-1}, {2,-1}
		}
	},
	hex4 = {  -- 37 hexes make a hex with length 4 sides.
		{0,-1}, {0,0}, {0,1}, {0,2},
		{1,-2}, {1,-1}, {1,0}, {1,1}, {1,2},
		{2,-3}, {2,-2}, {2,-1}, {2,0}, {2,1}, {2,2},
		{3,-4}, {3,-3}, {3,-2}, {3,-1}, {3,0}, {3,1}, {3,2},
		{4,-4}, {4,-3}, {4,-2}, {4,-1}, {4,0}, {4,1},
		{5,-4}, {5,-3}, {5,-2}, {5,-1}, {5,0},
		{6,-4}, {6,-3}, {6,-2}, {6,-1},
		exits = {
			{4,0}, {2,1}, {1,0}, {2,-2}, {4,-3}, {5,-2}
		}
	},
	hex5 = {  -- 61 hexes make a hex with length 5 sides.
		{0,-2}, {0,-1}, {0,0}, {0,1}, {0,2},
		{1,-3}, {1,-2}, {1,-1}, {1,0}, {1,1}, {1,2},
		{2,-4}, {2,-3}, {2,-2}, {2,-1}, {2,0}, {2,1}, {2,2},
		{3,-5}, {3,-4}, {3,-3}, {3,-2}, {3,-1}, {3,0}, {3,1}, {3,2},
		{4,-6}, {4,-5}, {4,-4}, {4,-3}, {4,-2}, {4,-1}, {4,0}, {4,1}, {4,2},
		{5,-6}, {5,-5}, {5,-4}, {5,-3}, {5,-2}, {5,-1}, {5,0}, {5,1},
		{6,-6}, {6,-5}, {6,-4}, {6,-3}, {6,-2}, {6,-1}, {6,0},
		{7,-6}, {7,-5}, {7,-4}, {7,-3}, {7,-2}, {7,-1},
		{8,-6}, {8,-5}, {8,-4}, {8,-3}, {8,-2},
		exits = {
			{5,0}, {2,1}, {1,-1}, {3,-4}, {6,-5}, {7,-3}
		}
	},
}
