return {
	{
		tiles = 500,
		origin = { x=0, y=0 },
		chances = {
			directions = { 2.5, 5, 4, 0, 0, 0 },
			rooms = { hex5 = 1 },
			branch = 0
		},
		contents = {
			{ 'upgrade', 'down', n=1 },
			{ 'upgrade', 'boost', min=1, max=3 },
			{ 'upgrade', 'crystal', n=1 },
			{ 'upgrade', 'multi', n=2 },
			{ 'upgrade', 'blast', n=2 }
		},
		background = {
			{0.06, 0.06, 0.06}, {0.07, 0.06, 0.05}, {0.04, 0.04, 0.04}
		}
	},
	{
		tiles = 1800,
		chances = {
			directions = { 6, 5, 4, 0, 0, 0 },
			rooms = { hex5 = 5, hex3 = 3 },
			branch = 0.02
		},
		contents = {
			{ 'upgrade', 'down', n=1 },
			{ 'upgrade', 'food', min=4, max=7 },
			{ 'jelly', min=2, max=3 }
		},
		background = {
			{0.06, 0.06, 0.06}, {0.07, 0.06, 0.05}, {0.04, 0.04, 0.04}
		}
	},
	{
		tiles = 1800,
		chances = {
			directions = { 8, 2, 2, 0, 0, 1 },
			rooms = { hex5 = 5, hex4 = 4 },
			branch = 0.05
		},
		contents = {
			{ 'upgrade', 'down', n=1 },
			{ 'upgrade', 'food', min=4, max=10 },
			{ 'upgrade', 'crystal', n=1 },
			{ 'turret', 15, n=2 },
		},
		background = {
			{0.06, 0.06, 0.06}, {0.07, 0.06, 0.05}, {0.04, 0.04, 0.04}
		}
	},
	{
		tiles = 1200,
		chances = {
			directions = { 8, 5, 4, 0, 3, 3 },
			rooms = { rhomb=2, hex2=7, hex3=7 },
			branch = 0.007
		},
		contents = {
			{ 'upgrade', 'food', min=3, max=9 },
			{ 'upgrade', 'down', n=1 },
			{ 'upgrade', 'boost', min=1, max=3 },
			{ 'upgrade', 'bounce', n=0.6 },
			{ 'upgrade', 'multi', n=1 },
			{ 'turret', min=2, max=3 },
			{ 'jelly', min=2, max=5 }
		},
		background = {
			{0.06, 0.06, 0.06}, {0.07, 0.06, 0.05}, {0.04, 0.04, 0.04}
		}
	},
	{
		tiles = 1500,
		chances = {
			directions = { 12, 5, 4, 0, 3, 3 },
			rooms = { rhomb=4, hex2=7, hex3=7 },
			branch = 0.01
		},
		contents = {
			-- No food: yam automatically added.
			{ 'upgrade', 'boost', min=1, max=3 },
			{ 'upgrade', 'crystal', min=0, max=1 },
			{ 'upgrade', 'reflect', n=1 },
			{ 'upgrade', 'bounce', n=0.6 },
			{ 'turret', min=3, max=5 },
			{ 'jelly', min=4, max=7 },
		},
		background = {
			{0.06, 0.06, 0.06}, {0.07, 0.06, 0.05}, {0.04, 0.04, 0.04}
		}
	}
}
