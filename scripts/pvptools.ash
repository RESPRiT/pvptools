/*************************************************************************************************
* PvP Tools by RESPRiT
* Version 0.1
* 
* TO-DO:
* 	-Search "To-do" to see details in function headers
*
* https://github.com/RESPRiT
**************************************************************************************************/
script "PvP Tools";
#notify tamedtheturtle; Don't need this yet
import "zlib.ash";

//-------------------------------------------------------------------------------------------------
// Global Variables

// PvP Minigame
record mini {
	string title; // Name of the mini
	string desc;  // Description to replace title
	string season;
};

// General usage range (mainly for food/booze handling)
record range
{
  float max;
  float min;
};

//---------------------------------------------------------
// Helper Functions

/**************************************************************************************************
Function: getSeasonNumber

Description:
	Returns the current season number

Input:
	None.
	
Output:
	Returns the current season number
**************************************************************************************************/
int getSeasonNumber() {
	string informationBooth = visit_url("peevpee.php?place=rules");
	matcher seasonMatcher = create_matcher("<b>Current Season: </b>(\\d+)",informationBooth);
	
	seasonMatcher.find();
	return group(seasonMatcher,1).to_int();
}



/**************************************************************************************************
Function: averange

Description:
	Gives the average value of a range (shamelessly stolen-ish from EatDrink.ash)

Input:
	rangestring - Range to evaluate
	
Output:
	Returns the average value
**************************************************************************************************/
float averange(string rangestring) {
	string[int] splitRange = split_string(rangestring, "-");
	range returnval;
	// If we only got 1 number, return it for both
	if(count(splitRange) == 1) {
		returnval.max = to_float(splitRange[0]);
		returnval.min = returnval.max;
		return (returnval.max + returnval.min) / 2;
	} else if (splitRange[0]=="") {
		returnval.max = (-1.0) * to_float(splitRange[1]) ;
		returnval.min = returnval.max;
		return (returnval.max + returnval.min) / 2;
	}
	// Return the 2 numbers
	returnval.min = to_float(splitRange[0]);
	returnval.max = to_float(splitRange[1]);
	return (returnval.max + returnval.min) / 2;
}

//---------------------------------------------------------
// Information Functions

/**************************************************************************************************
Function: getMiniScore

To-do:
	-Everything

Description:
	Returns the current score of a given PvP minigame
	
Input:
	mini		- Name of the mini
	
Output:
	Returns the score of the given mini
**************************************************************************************************/
float getMiniScore(string mini) {
	return 0.0; // Placeholder
}

/**************************************************************************************************
Function: parseFiteLogs

To-do:
	-Store gathered info
	-Fix ties
	-Get defending vs attacking

Description:
	Iterates through the archive to obtain individual fight data. Data is exported to a text map.
	
Input:
	None.
	
Output:
	Returns true if successful
**************************************************************************************************/
boolean parseFiteLogs(int count, boolean CLIprint) {
	string archive = visit_url("peevpee.php?place=logs&mevs=0&oldseason=0&showmore=1");
	matcher logmatcher = create_matcher("action=log&ff=1&lid=\\d*&place=logs&pwd=" + my_hash(), archive);
	//string [string][string][string][string][string][string][string][string][string][string][string][string][string][string] fitedata; // NOPE

	boolean[string] test;
	boolean[string] test2;
	
	int i = 0;

	print("Starting parsing", "blue");
	while(find(logmatcher)) {
		i += 1;
		
		if(i > count) {
			print("Let's take a break.");
			break;
		}
		
		if(CLIprint) print("-----" + i + "-----");
		
		string fitelog = visit_url("peevpee.php?" + group(logmatcher));
		matcher minimatcher = create_matcher("(?<=nowrap><b>)[\\w|\\s|\"|&|;|#|'|\.|\(|\)|?|!|-]*(?=<\/b><\/td><td>)", fitelog);
		matcher winnermatcher = create_matcher("(?<=<b>)[\\w|\\s]*(?=<\/b> )", fitelog);
		matcher datematcher = create_matcher("(?<=Fight Replay: ).*(?= [\\d]*:[\\d]*[am|pm])", fitelog);
		matcher timematcher = create_matcher("(?<=[\\d]* )[\\d]*:[\\d]*(am)?(pm)?(?=<\/b>)", fitelog);	
		
		find(datematcher); find(timematcher);
		if(CLIprint) print("(" + group(datematcher) + " - " + group(timematcher) + ")");
		
		while(find(minimatcher)) {
			if(!find(winnermatcher)) {
				abort("NOPE");
			}
			if(CLIprint) print(group(minimatcher) + ": " + group(winnermatcher));
			if(group(minimatcher) == "Spirit of Gnoel" && to_lower_case(group(winnermatcher)) != my_name() && !test[group(winnermatcher)]) {
				test[group(winnermatcher)] = true;
			}
		}

		find(winnermatcher);
		if(CLIprint) print("Overall Winner: " + group(winnermatcher));
		
		if(to_lower_case(group(winnermatcher)) != my_name()) {
			test2[group(winnermatcher)] = true;
		}
		
		if(CLIprint) print("");
	}

	foreach winner in test {
		print(winner, "blue");
	}
	
	foreach winner in test2 {
		print(winner, "green");
	}
	
	print("DONE!");
	return false;
}

boolean parseFiteLogs(int count) {
	return parseFiteLogs(count, false);
}

/**************************************************************************************************
Function: parseConsumptionLogs

To-do:
	-Don't force complete rescan

Description:
	Iterates through the player's consumption logs and records consumed consumables to a map

Input:
	None.
	
Output:
	Returns true if successful
**************************************************************************************************/
boolean parseConsumptionLogs() {
	int season = getSeasonNumber();
	int[int] seasonStartDate;
	seasonStartDate[0] = (season + 1) / 6 + 2012;
	seasonStartDate[1] = (season * 2 + 3) % 12;
	seasonStartDate[2] = 1;

	boolean[item] yummyData;
	string yummyFile = "pvp_" + my_name() + "_yummyData_" + season + ".txt";
	if(!file_to_map(yummyFile, yummyData)) {
		return false;
	}
	
	string yummylogs = visit_url("showconsumption.php?recent=1");
	matcher consumablematcher = create_matcher(";'>([\\w|\\s|\"|&|;|#|'|\.|-]*)<\/a>&nbsp;&nbsp;", yummylogs);
	matcher datematcher = create_matcher("<small>([\\d|-]*) \\d+:\\d+[a|p]m<\/small>", yummylogs);
	
	while(find(consumablematcher) && find(datematcher)) {
		print("FOUND: " + group(consumablematcher, 1) + ": " + group(datematcher, 1));
	
		string dateString = group(datematcher, 1);
		string[int] splitDate = split_string(dateString, "-");
		
		item consumable = group(consumablematcher, 1).to_item();
		
		if(splitDate[0].to_int() > seasonStartDate[0]) { // hmm.......
			print(" DING! " + splitDate[0] + " : " + seasonStartDate[0], "blue");
			yummyData[consumable] = true;
		} else if(splitDate[0].to_int() == seasonStartDate[0]) {
			if(splitDate[1].to_int() > seasonStartDate[1]) {
				print(" DING! " + splitDate[1] + " : " + seasonStartDate[1], "orange");
				yummyData[consumable] = true;
			} else if(splitDate[1].to_int() == seasonStartDate[1]) {
				if(splitDate[2].to_int() >= seasonStartDate[2]) {
					print(" DING! " + splitDate[2] + " : " + seasonStartDate[2], "green");
					yummyData[consumable] = true;
				} else {
					print(" AWW! " + splitDate[2] + " : " + seasonStartDate[2], "red");
				}
			}
		}
	}
	
	if(!map_to_file(yummyData, yummyFile)) {
		return false;
	}
	
	return true;
} 

//---------------------------------------------------------
// Mini Helping Functions

/**************************************************************************************************
Function: maxBuffs

To-do:
	-Better mp regen
	-Buffbot Support?
	-Weighting?

Description:
	Uses the maximizer to maximize a given list of modifiers

Input:
	toMax		- String of modifiers to maximize, separate by commas
	maxPrice	- Max mall price of individual items
	PPF			- Max price per fite
	fites		- Number of fites to buff up foreach
	eatLimit	- Max fullness to fill
	drinkLimit	- Max drunkness to fill
	spleenLimit	- Max spleen to fill
	purityLimit	- Max number of effects
	
Output:
	Returns the total meat spent maximizing
**************************************************************************************************/
int maxBuffs(string toMax, int maxPrice, int PPF, int fites, int eatLimit, int drinkLimit, 	
			int spleenLimit, int purityLimit, int spendingLimit, boolean daily) {

	int totalPrice = 0;

	foreach i, rec in maximize(toMax, maxPrice, 2, true, false) {
		int effectCount = modifier_eval("E");
		
		if(effectCount >= purityLimit) {
			break;
		}
		
		if(rec.item != $item[none] && rec.item != $item[d20] && contains_text(rec.display, "use") 
			&& is_tradeable(rec.item)) {
			
			float itemDuration = numeric_modifier(rec.item, "Effect Duration");
			int itemAmount = ceil((fites - have_effect(rec.effect)) / itemDuration);
			
			print("PPF: " + PPF + ", mall_price:" + mall_price(rec.item)/itemDuration);
			
			if(PPF >= (mall_price(rec.item) / itemDuration) && 
				my_meat() >= mall_price(rec.item) * itemAmount && 
				totalPrice + mall_price(rec.item) * itemAmount < spendingLimit) {
				
				int meatBefore = my_meat();
				buy(itemAmount, rec.item);
				totalPrice += meatBefore - my_meat();
				use(itemAmount, rec.item);
			}
		} else if(rec.skill != $skill[none] && !contains_text(rec.display, "soulsauce")) {
			while(have_effect(rec.effect) < fites && my_mp() >= mp_cost(rec.skill)) {
				use_skill(rec.skill);
				if(my_mp() < mp_cost(rec.skill)) {
					restore_mp(mp_cost(rec.skill));
				}
			}
		} else if(rec.item == $item[d20]) {
			print("Time for d20's wild ride!", "blue");
			
			while(have_effect($effect[Natural 20]) == 0) {
				cli_execute("uneffect Natural 1");
				buy(1, $item[d20]);
				use(1, $item[d20]);
				
				if(have_effect($effect[Natural 1]) >= 1) {
					print("Bad roll!", "red");
					cli_execute("uneffect Natural 1");
				} else if (have_effect($effect[Natural 20]) >= 1) {
					print("Good roll!", "blue");
					break;
				}
			}
		}
	}
	
	if(daily && pvp_attacks_left() < 100) {
		if(my_fullness() + 4 < fullness_limit()) {
			cli_execute("eat very hot lunch");
		}
	}
	
	if(daily && pvp_attacks_left() < 50) {
		if(my_fullness() < fullness_limit()) {
			cli_execute("eat meat stick");
		}
		
		if(have_effect($effect[Silent Running]) == 0) cli_execute("swim sprints");
	}
	
	if(daily && pvp_attacks_left() < 30) {
		if(have_effect($effect[infernal thirst]) == 0) cli_execute("summon infernal thirst");
		if(have_effect($effect[Hustlin']) == 0 ) {
			cli_execute("pool 3");
			cli_execute("pool 3");
			cli_execute("pool 3");
		}
	}
	
	if(daily && pvp_attacks_left() < 20) {
		if(have_effect($effect[Brother Smothers's Blessing]) == 0) cli_execute("friars booze");
		if(have_effect($effect[White-boy Angst]) == 0) cli_execute("concert white");
		if(have_effect($effect[Racing!]) == 0) cli_execute("play buff init");
	}
	
	if(daily && pvp_attacks_left() < 5) {
		if(have_effect($effect[Video... Games?]) == 0) cli_execute("use defective game grid token");
	}
	
	// poison!!
	cli_execute("uneffect a little bit poisoned");
	cli_execute("uneffect hardly poisoned at all");
	cli_execute("uneffect majorly poisoned");
	cli_execute("uneffect really quite poisoned");
	cli_execute("uneffect somewhat poisoned");
	
	return totalPrice;
}

//@Override
int maxBuffs(string toMax) {
	return maxBuffs(toMax, my_meat(), my_meat(), pvp_attacks_left(), 0, 0, 0, 999, 999999999, false);
}

int maxBuffs(string toMax, int maxPrice, int PPF, int fites) {
	return maxBuffs(toMax, maxPrice, PPF, fites, 0, 0, 0, 999, 999999999, false);
}

/**************************************************************************************************
Function: uniquelyConsume

To-do:
	-More flags (total to consume, etc)
	-Buffbot needs better handling

Description:
	Consumes unique boozes or foods to help the player's unique consumable mini
	
Input:
	type		- Consumable type
	maxPrice	- Maximum item cost to consider
	maxSize		- Maximum consumable space to fill (fullness, drunkness)
	minAdv		- Minimum adventures per consumable space to consider (ie adv/full, adv/drunk)
	advBuff		- Whether or not to acquire adventure boosting buff (Got Milk and Ode to Booze)
	
Output:
	Returns true if successful
**************************************************************************************************/
boolean uniquelyConsume(string type, int maxPrice, int maxSize, int maxFill, float minAdv, boolean advBuff, boolean useMayo) {
	boolean[item] consumed;
	int season = getSeasonNumber();
	string yummyFile = "pvp_" + my_name() + "_yummyData_" + season + ".txt";
	if(!file_to_map(yummyFile, consumed)) {
		return false;
	}
	
	foreach yummy in $items[] {
		if(useMayo && (my_inebriety() >= maxFill || my_inebriety() >= inebriety_limit())) {
			set_property("choiceAdventure1076", 6);
			cli_execute("use mayo minder");
			set_property("choiceAdventure1076", 0);
			print("Uh, we're done here?", "red");
			break;
		} else if(!useMayo && my_fullness() >= maxFill) {
			print("Uh, we're done here!", "red");
			break;
		}

		if(advBuff) {
			if(have_effect($effect[Got Milk]) == 0 && type == "food") {
				cli_execute("use milk of mag");
			} else if(have_effect($effect[Ode to Booze]) == 0 && type == "booze"){
				if(have_skill($skill[The Ode to Booze])) {
					use_skill($skill[The Ode to Booze]);
				} else {
					chat_private("buffy", "ode to booze");
					wait(15);
					if(have_effect($effect[Ode to Booze]) == 0) {
						print("Nothing from Buffy yet, I'm going to wait a bit more.", "green");
						wait(15);
					}
					if(have_effect($effect[Ode to Booze]) == 0) {
						abort("No Ode! Nooooooo-de!");
					}
				}
			}
		}
		
		if(is_tradeable(yummy) && item_type(yummy) == type && yummy != $item[none] && 
			mall_price(yummy) <= maxPrice && mall_price(yummy) != -1 && !consumed[yummy] && 
			yummy.fullness <= maxSize && averange(yummy.adventures) / yummy.fullness >= minAdv) {
			
			print("Found! " + yummy.to_string(), "blue");
			buy(1, yummy);
			
			if(useMayo) {
				if(item_amount($item[mayodiol]) == 0) {
					buy(1, $item[mayodiol]);
				}
				set_property("choiceAdventure1076", 2);
				cli_execute("use mayo minder");
				set_property("choiceAdventure1076", 0);
			} else {
				set_property("choiceAdventure1076", 6);
				cli_execute("use mayo minder");
				set_property("choiceAdventure1076", 0);
			}
			
			boolean success;
			if(item_type(yummy) == "food") {
				success = eat(1, yummy);
			} else {
				success = drink(1, yummy);
			}
			
			if(success) {
				consumed[yummy] = true;
			}
		}
	}
	
	print("Finished!", "blue");
	
	if(!map_to_file(consumed, yummyFile)) {
		return false;
	}
	
	return true;
}

//maxBuffs(string toMax, int maxPrice, int PPF, int fites, int eatLimit, int drinkLimit, 	
//			int spleenLimit, int purityLimit, int spendingLimit)

//uniquelyConsume(string type, int maxPrice, int maxSize, int maxFill, float minAdv, boolean advBuff, boolean useMayo)

// Main
boolean main(string doWhat) {
	switch(doWhat) {
		case 'unique':
			parseConsumptionLogs();
			uniquelyConsume("food", 5000, 2, 9, 3, true, true);
			break;
		case 'logs':
			parseFiteLogs(100, true);
			break;
		case 'buff':
			maxBuffs("cold res, init, booze drop, -combat", 5000, 250, pvp_attacks_left(), 0, 0, 0, 999, 999999999, true);
			break;
		case 'capbuff':
			maxBuffs("cold res, init, booze drop, -combat", 5000, 250, 1, 0, 0, 0, 999, 999999999, false);
			break;
	}
	return true;
}
