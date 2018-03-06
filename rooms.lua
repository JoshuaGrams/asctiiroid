-- A room consists of a list of the tiles which make up the
-- room.  A walker enters at (0, 0). Exits should be at the
-- edge of the room (more or less) in the six directions
-- (clockwise from positive x, which is down-right).

return {
	single = {
		{0,0},
		exits = {
			{1,0}, {0,1}, {-1,1}, {-1,0}, {0,-1}, {1,-1}
		}
	},
	four = {
		{0,0}, {0,1},
		{1,0}, {1,1},
		exits = {
			{2,0}, {1,1}, {0,1}, {-1,1}, {0,0}, {1,1}
		}
	},
	seven = {
		{0,0}, {0,1},
		{1,-1}, {1,0}, {1,1},
		{2,-1}, {2,0},
		exits = {
			{2,0}, {1,1}, {0,1}, {0,0}, {1,-1}, {2,-1}
		}
	},
	nineteen = {
		{0,0}, {0,1}, {0,2},
		{1,-1}, {1,0}, {1,1}, {1,2},
		{2,-2}, {2,-1}, {2,0}, {2,1}, {2,2},
		{3,-2}, {3,-1}, {3,0}, {3,1},
		{4,-2}, {4,-1}, {4,0},
		exits = {
			{2,0}, {1,1}, {0,1}, {0,0}, {1,-1}, {2,-1}
		}
	}
}
