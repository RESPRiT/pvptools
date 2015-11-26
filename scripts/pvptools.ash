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
Function: averange

Description:
	Gives the average value of a range (shamelessly stolen-ish from EatDrink.ash)

Input:
	rangestring - Range to evaluate
	
Output:
	*			- Average value
**************************************************************************************************/
float averange(string rangestring)
{
  string[int] splitRange = split_string(rangestring, "-");
  range returnval;
  // If we only got 1 number, return it for both
  if (count(splitRange) == 1)
  {
    returnval.max = to_float(splitRange[0]);
    returnval.min = returnval.max;
    return (returnval.max + returnval.min) / 2;
  }
  else if (splitRange[0]=="")
  {
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
// Mini Helping Functions

// All are placeholders
int maxPrice = 1000; // Hardcap item cost regardless of adventures given
int PPF = 250; // Price Per Fite
int spendingLimit = 250000;
string maxList = "cold res, init, booze drop, -combat"; // Modifiers to max
int purityLimit = 999;

/**************************************************************************************************
Function: maxBuffs

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
	totalPrice	- Total meat spent maximizing
**************************************************************************************************/
int maxBuffs(string toMax, int maxPrice, int PPF, int fites, int eatLimit, int drinkLimit, 	
			int spleenLimit, int purityLimit) {

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
			}
		}
	}
	
	foreach buff in my_effects() {
		
	}
	
	return totalPrice;
}

//@Override
int maxBuffs(string toMax) {
	return maxBuffs(toMax, my_meat(), my_meat(), pvp_attacks_left(), 0, 0, 0, 999);
}

int maxBuffs(string toMax, int maxPrice, int PPF, int fites) {
	return maxBuffs(toMax, maxPrice, PPF, fites, 0, 0, 0, 999);
}

/**************************************************************************************************
Function: uniquelyConsume

To-do:
	-Parse consumable history for list of consumed foods
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
	success		- Was consumption successful
**************************************************************************************************/
boolean uniquelyConsume(string type, int maxPrice, int maxSize, float minAdv, boolean advBuff) {
	boolean[item] consumed;
	boolean success = true;
	
	foreach yummy in $items[] {
		if(my_fullness() >= fullness_limit()) {
			print("Uh, we're done here.", "red");
			return false;
		}

		if(advBuff) {
			if(have_effect($effect[Got Milk]) == 0 && type == "food") {
				cli_execute("use milk of mag");
			} else if(have_effect($effect[Ode to Booze]) == 0){
				if(have_skill($skill[Ode to Booze])) {
					use_skill($skill[Ode to Booze]);
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
			mall_price(yummy) <= maxPrice && !consumed[yummy] && yummy.fullness <= maxSize && 
			averange(yummy.adventures) / yummy.fullness >= minAdv) {
			
			print("Found! " + yummy.to_string(), "blue");
			consumed[yummy] = true;
			buy(1, yummy);
			if(item_type(yummy) == "food") {
				eat(1, yummy);
			} else {
				drink(1, yummy);
			}
		}
	}
	
	return success;
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
	score		- Score of the given mini
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
	success		- Returns true if successful
**************************************************************************************************/
boolean parseFiteLogs() {
	string archive = visit_url("peevpee.php?place=logs&mevs=0&oldseason=0&showmore=1");
	matcher logmatcher = create_matcher("action=log&ff=1&lid=\\d*&place=logs&pwd=" + my_hash(), archive);
	string [string][string][string][string][string][string][string][string][string][string][string][string][string][string] fitedata;

	int i = 0;

	while(find(logmatcher)) {
		i += 1;
		
		if(i > 50) abort("Let's take a break.");
		
		print("-----" + i + "-----");
		
		string fitelog = visit_url("peevpee.php?" + group(logmatcher));
		matcher minimatcher = create_matcher("(?<=nowrap><b>)[\\w|\\s]*(?=<\/b><\/td><td>)", fitelog);
		matcher winnermatcher = create_matcher("(?<=<b>)[\\w|\\s]*(?=<\/b> )", fitelog);
		matcher datematcher = create_matcher("(?<=Fight Replay: ).*(?= [\\d]*:[\\d]*[am|pm])", fitelog);
		matcher timematcher = create_matcher("(?<=[\\d]* )[\\d]*:[\\d]*(am)?(pm)?(?=<\/b>)", fitelog);	
		
		find(datematcher); find(timematcher);
		print("(" + group(datematcher) + " - " + group(timematcher) + ")");
		
		while(find(minimatcher)) {
			if(!find(winnermatcher)) {
				abort("NOPE");
			}
			print(group(minimatcher) + ": " + group(winnermatcher));
		}

		find(winnermatcher);
		print("Overall Winner: " + group(winnermatcher));
		
		print("");
	}

	print("DONE!");
	return false;
}


// Main
if(my_name() == "null") {
	print("BANCER!");
	maxBuffs(maxList, 5000, 500, pvp_attacks_left());
} else {
	maxBuffs(maxList, maxPrice, PPF, pvp_attacks_left());
}
//cli_execute("outfit pvp");
//maximize("cold res", false);

// defence
// maxBuffs(maxList, 10000