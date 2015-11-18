/*************************************************************************************************
* PvP Tools by RESPRiT
* Version 0.0
* 
* TO-DO:
* 	-Parse fight log
*	-Display mini scores
*	-Combat helper (count enemies defeated)
*	-Cleaner Maximizer
*
* https://github.com/RESPRiT
**************************************************************************************************/
script "PvP Tools";
#notify tamedtheturtle; Don't need this yet
import "zlib.ash";

//---------------------------------------------------------
// Configurable Variables

// All are placeholders
int maxPrice = 1000; // Hardcap item cost regardless of adventures given
int PPF = 250; // Price Per Fite
int spendingLimit = 250000;
string maxList = "cold res, init, booze drop, -combat"; // Modifiers to max
int purityLimit = 999;

/**************************************************************************************************
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
			
			if(PPF <= mall_price(rec.item) / itemDuration && 
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


// Main
//maxBuffs(maxList, maxPrice, PPF, pvp_attacks_left());
//cli_execute("outfit pvp");
//maximize("cold res", false);

// defence
// maxBuffs(maxList, 10000, 1);

