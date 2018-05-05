
local intro = {
	"In the wake of an asteroid strike, food supplies are",
	"running low.  Desperate to tide the colony over until the",
	"new hydroponics systems come online, you enter the deadly",
	"asteroid Endor in search of a legendary root vegetable..."
}

local endings = {
	{
		food = -1,
		"You died in the depths of Endor, dooming the colony to a",
		"painful death."
	},
	{
		food = 0,
		"You return nearly empty-handed, helpless to stop the",
		"colony's demise."
	},
	{
		food = 300,
		"Though you found the Yam of Endor, you only managed to bring",
		"back a paltry %food pounds of it.  So despite your desperate",
		"adventure, %n people died, and the rest are quite emaciated."
	},
	{
		food = 700,
		"You brought back %food pounds of the legendary Yam of Endor.",
		"Though the colonists are a bit emaciated, and no-one ever wants",
		"to see another sweet potato, everyone survived thanks to you."
	},
	{
		food = 1500,
		"You returned with %food pounds of the legendary Yam of Endor.",
		"Though no-one ever wants to see another sweet potato, they are",
		"all alive and in good health thanks to your daring and skill."
	}
}

return { intro = intro, endings = endings }
