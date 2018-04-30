return {
	{
		tiles = 700,
		origin = { x=0, y=0 },
		chances = {
			directions = { 0, 5, 4, 0, 0, 0 },
			rooms = { hex5 = 1 },
			branch = 0
		},
		contents = {
			{ 'upgrade', 'down', min=1, max=1 },
			{ 'upgrade', 'money', min=2, max=5 },
			{ 'jelly', n=1 }
		},
		background = {
			{0.06, 0.06, 0.06}, {0.07, 0.06, 0.05}, {0.04, 0.04, 0.04}
		}

	},
	{
		tiles = 1200,
		origin = { x=0, y=0 },
		chances = {
			directions = { 8, 5, 4, 0, 3, 3 },
			rooms = { rhomb=2, hex2=7, hex3=7 },
			branch = 0.007
		},
		contents = {
			{ 'upgrade', 'down', min=1, max=1 },
			{ 'upgrade', 'money', min=3, max=6 },
			{ 'upgrade', 'boost', min=1, max=3 },
			{ 'upgrade', 'bounce', n=0.5 },
			{ 'upgrade', 'multi', n=1 },
			{ 'turret', min=1, max=2 },
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
			{ 'upgrade', 'money', min=2, max=7 },
			{ 'upgrade', 'boost', min=1, max=3 },
			{ 'upgrade', 'crystal', min=0, max=1 },
			{ 'upgrade', 'reflect', min=1, max=1 },
			{ 'turret', min=3, max=5 },
			{ 'jelly', min=4, max=7 },
		},
		background = {
			{0.06, 0.06, 0.06}, {0.07, 0.06, 0.05}, {0.04, 0.04, 0.04}
		}
	}
}
