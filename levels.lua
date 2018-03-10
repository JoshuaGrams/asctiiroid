return {
	{
		tiles = 1200,
		chances = {
			directions = { 8, 5, 4, 0, 3, 3 },
			rooms = { four=2, seven=7, nineteen=7 },
			branch = 0.007
		},
		contents = {
			{ 'upgrade', 'boost', min=2, max=5 },
			{ 'upgrade', 'crystal_shield', min=1, max=2 },
			{ 'turret', min=3, max=6 },
			{ 'jelly', min=4, max=8 }
		},
		background = {
			{15, 15, 15}, {18, 15, 12}, {11, 11, 11}
		}
	}
}
