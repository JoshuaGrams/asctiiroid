return {
	{
		tiles = 1200,
		origin = { x=0, y=0 },
		chances = {
			directions = { 8, 5, 4, 0, 3, 3 },
			rooms = { four=2, seven=7, nineteen=7 },
			branch = 0.007
		},
		contents = {
			{ 'upgrade', 'money', min=3, max=6 },
			{ 'upgrade', 'down', min=1, max=1 },
			{ 'upgrade', 'boost', min=1, max=3 },
			{ 'upgrade', 'bounce', min=0, max=1 },
			{ 'upgrade', 'multi', min=1, max=1 },
			{ 'turret', min=1, max=2 },
			{ 'jelly', min=2, max=5 }
		},
		background = {
			{15, 15, 15}, {18, 15, 12}, {11, 11, 11}
		}
	},
	{
		tiles = 1500,
		chances = {
			directions = { 12, 5, 4, 0, 3, 3 },
			rooms = { four=4, seven=7, nineteen=7 },
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
			{15, 15, 15}, {18, 15, 12}, {11, 11, 11}
		}
	}
}
