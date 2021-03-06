/*************************************************************************************************
* PvP Tools by RESPRiT
* Version 0.2
* 
* TO-DO:
* 	-Search "To-do" to see details in function headers
*
* https://github.com/RESPRiT
**************************************************************************************************/
script "PvP Tools";
#notify tamedtheturtle; Don't need this yet
import "reslib.ash";

//-------------------------------------------------------------------------------------------------
// Global Variables

// PvP Minigame
record miniInfo {
	string title; // Name of the mini
	string desc;  // Description to replace title
	boolean state; // State-based or not
	boolean greater; // Greater score wins or not
};

// Fite Mini Results
record miniResults {
	boolean win;
	float score;
};

record lookupInfo {
	boolean win;
	boolean greater;
	float score;
	int latest;
};

// PvP Fite
record fite {
	string opponent;
	boolean offense;
	string date;
	string time;
	miniResults[string] minis;
	boolean win;
	int fame;
	int swagger;
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
Function: getSeasonStart

Description:
	Returns an array of the year/month/day of the season start

Input:
	None.
	
Output:
	Returns the latest fite number in the fite data
**************************************************************************************************/
date getSeasonStart() {
	date seasonStartDate;
	
	seasonStartDate.year = (getSeasonNumber() + 1) / 6 + 2012;
	seasonStartDate.month = (getSeasonNumber() * 2 + 3) % 12;
	seasonStartDate.day = 1;
	
	return seasonStartDate;
}

/**************************************************************************************************
Function: getLatestFite

Description:
	Returns the latest fite number in the fite data

Input:
	None.
	
Output:
	Returns the latest fite number in the fite data, returns -1 if unsuccessful
**************************************************************************************************/
int getLatestSavedFite() {
	int latest = -1;
	fite[int] fiteData;
	
	file_to_map("pvp_" + my_name() + "_fiteData_" + getSeasonNumber() + ".txt", fiteData);
	
	foreach num in fiteData {
		if(num > latest) {
			latest = num;
		}
	}
	
	return latest;
}

/**************************************************************************************************
Function: getLatestFite

Description:
	Returns the latest fite number in the pvp archives

Input:
	None.
	
Output:
	Returns the latest fite number in the pvp archives, returns -1 if unsuccessful
**************************************************************************************************/
int getLatestFite() {
	string archive = visit_url("peevpee.php?place=logs&mevs=0&oldseason=0&showmore=1");
	matcher logmatcher = create_matcher("action=log&ff=1&lid=(\\d*)&place=logs&pwd=" + my_hash(), 
		archive);
	
	if(find(logmatcher)) {
		return to_int(group(logmatcher, 1));
	} else {
		return -1;
	}
}

/**************************************************************************************************
Function: hasMayo

Description:
	Returns whether or not the player has the mayo clinic installed

Input:
	None.
	
Output:
	Returns whether or not the player has the mayo clinic installed
**************************************************************************************************/
boolean hasMayo() {
	string workshed = visit_url("campground.php?action=workshed");
	
	if(contains_text(to_lower_case(workshed), "mayo")) {
		return true;
	} else {
		return false;
	}
}

//---------------------------------------------------------
// Information Functions

/**************************************************************************************************
Function: getMiniInfo

Description:
	Returns the mini info of a given PvP minigame
	
Input:
	mini	- Name of the mini
	
Output:
	Returns the mini info of the given mini
**************************************************************************************************/
boolean getMiniInfo() {
	string booth = visit_url("peevpee.php?place=rules");
	int i = 0; // counter
	miniInfo[int] miniData;
	
	// There really isn't a great way to make regex readable
	matcher infomatcher = create_matcher("<td valign=\"top\" nowrap><b>" + 
								"([\\w|\\s|\|&|;|#|'|\.|\,|\(|\)|!|?|\*|\/|\-]*)" + 
								"<\/b><\/td><td valign=\"top\">" +
								"([\\w|\\s|\|&|;|#|'|\.|\,|\(|\)|!|?|\*|\/|\-]*)" + 
								"<\/td><td valign=\"top\" align=\"center\" colspan=\"1\">" + 
								"([\\d|\,]*)" + 
								"<\/td><td valign=\"top\" align=\"center\">" + "([\\d|\,]*)" +
								"<\/td>",
								booth);
	while(find(infomatcher)) {
		miniData[i].title = group(infomatcher, 1);
		miniData[i].desc = group(infomatcher, 2);
		miniData[i].state = to_boolean(get_property("pvp_mini_" + i + "_state"));
		miniData[i].greater = to_boolean(get_property("pvp_mini_" + i + "_greater"));
		# returnMini.score = to_float(group(infomatcher, 3));
		# returnMini.HCscore = to_float(group(infomatcher, 4));
		i += 1;
	}
	
	map_to_file(miniData, "pvp_miniData_" + getSeasonNumber() + ".txt");
	
	return true;
}

/**************************************************************************************************
Function: getMiniScore

Description:
	Returns the score of a given mini
	
Input:
	id	- The ID number of the mini
	HC	- Whether or not the player is in hardcore
	
Output:
	Returns the score of the given mini
**************************************************************************************************/
float getMiniScore(int id, boolean HC) {	
	string booth = visit_url("peevpee.php?place=rules");
	int i = 0; // counter
	miniInfo[int] miniData;
	file_to_map("pvp_miniData_" + getSeasonNumber() + ".txt", miniData);
	
	// There really isn't a great way to make regex readable
	matcher infomatcher = create_matcher("<td valign=\"top\" nowrap><b>" + 
								"([\\w|\\s|\|&|;|#|'|\.|\,|\(|\)|!|?|\*|\/|\-]*)" + 
								"<\/b><\/td><td valign=\"top\">" +
								"([\\w|\\s|\|&|;|#|'|\.|\,|\(|\)|!|?|\*|\/|\-]*)" + 
								"<\/td><td valign=\"top\" align=\"center\" colspan=\"1\">" + 
								"([\\d|\,]*)" + 
								"<\/td><td valign=\"top\" align=\"center\">" + "([\\d|\,]*)" +
								"<\/td>",
								booth);
	while(find(infomatcher)) {
		if(id == i) {
			if(HC) {
				return to_float(group(infomatcher, 4));
			} else if(miniData[i].greater) {
				if(to_float(group(infomatcher, 3)) > to_float(group(infomatcher, 4))) {
					return to_float(group(infomatcher, 3));
				} else {
					return to_float(group(infomatcher, 4));
				}
			} else {
				if(to_float(group(infomatcher, 3)) < to_float(group(infomatcher, 4))) {
					return to_float(group(infomatcher, 3));
				} else {
					return to_float(group(infomatcher, 4));
				}
			}
		}
		i += 1;
	}
	
	return -999;
}

/**************************************************************************************************
Function: miniToInt

Description:
	Returns the corresponding mini ID of a given mini title
	
Input:
	name	- Name of the mini
	
Output:
	Returns the corresponding mini ID of a given mini title
**************************************************************************************************/
int miniToInt(string name) {
	miniInfo[int] miniData;
	
	file_to_map("pvp_miniData_" + getSeasonNumber() + ".txt", miniData);
	
	foreach i, mini in miniData {
		if(contains_text(to_lower_case(mini.title), to_lower_case(name))) {
			return i;
		}
	}
	
	return -1;
}

boolean playerLookup(string player) {
	fite[int] fiteData;
	lookupInfo[string] playerInfo;
	miniInfo[int] miniData;

	file_to_map("pvp_miniData_" + getSeasonNumber() + ".txt", miniData);
	file_to_map("pvp_" + my_name() + "_fiteData_" + getSeasonNumber() + ".txt", fiteData);
	
	print("I am thinking...");
	foreach num, fite in fiteData {
		if(to_lower_case(fite.opponent) == to_lower_case(player)) {
			print("DING!");
			foreach mini, results in fite.minis {
				if(playerInfo[mini].latest < num) {
					boolean test = results.win != miniData[miniToInt(mini)].greater;
					print(mini + " - " + results.score + " - " + test);
					playerInfo[mini].latest = num;
					playerInfo[mini].win = results.win;
					playerInfo[mini].score = results.score;
					playerInfo[mini].greater = results.win != miniData[miniToInt(mini)].greater;
				}
			}
		}
	}
	
	print("Results for " + player + ":", "green");
	foreach mini, info in playerInfo {
		string strbuff = mini + ": ";
		string color = "blue";
		
		if(info.win) {
			strbuff += "WIN! - ";
		} else {
			strbuff += "LOSE! - ";
			color = "red";
		}
		
		if(info.greater) {
			strbuff += ">";
		} else {
			strbuff += "<";
		}
		
		strbuff += info.score + " (Based off of fight #" + info.latest + ")";
		print(strbuff, color);
	}
	
	return true;
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
boolean parseFiteLogs(int count, boolean CLIprint, boolean override) {
	string archive = visit_url("peevpee.php?place=logs&mevs=0&oldseason=0&showmore=1");
	matcher logmatcher = create_matcher("action=log&ff=1&lid=(\\d*)&place=logs&pwd=" + my_hash(), 
		archive);
	fite[int] fiteData;
	file_to_map("pvp_" + my_name() + "_fiteData_" + getSeasonNumber() + ".txt", fiteData);
	
	//peevpee.php?action=log&ff=1&lid=855860&place=logs&pwd=91c8994ea59ea1fa4be18aa948a03a50
	//peevpee.php?action=log&ff=1&lid=0&place=logs&pwd=91c8994ea59ea1fa4be18aa948a03a50
	
	boolean[string] test;
	boolean[string] test2;
	
	int i = 0;
	//int latest = getLatestFite();
	
	print("Starting parsing", "blue");
	while(find(logmatcher)) {
		int fitenum = to_int(group(logmatcher, 1));
		i += 1;
		
		if(i > count) {
			print("Let's take a break.");
			break;
		}
		
		if(fiteData[fitenum].date == "" || override) {
			if(CLIprint) print("-----" + i + " : " + fitenum + "-----");
			
			string fitelog = visit_url("peevpee.php?action=log&ff=1&lid=" + fitenum + 
				"&place=logs&pwd=" + my_hash());
			matcher playermatcher = create_matcher("who=[\\d]*\">([\\w|\\s]*)<\/a>", fitelog);
			matcher minimatcher = create_matcher("nowrap><b>([\\w|\\s|\"|&|;|#|'|\.|\(|\)|?|!|-]*)<\/b><\/td><td>", fitelog);
			matcher winnermatcher = create_matcher("<b>([\\w|\\s]*)<\/b> ", fitelog);
			matcher datematcher = create_matcher("Fight Replay: (.*) [\\d]*:[\\d]*[a|p]", fitelog);
			matcher timematcher = create_matcher("[\\d]* ([\\d]*:[\\d]*(am)?(pm)?)<\/b>", fitelog);	
			matcher famematcher = create_matcher("([\\w|\\s]*) (lost)?(gained)? fame:<\/td><td>([\\d]*)", fitelog);
			matcher swaggermatcher = create_matcher("gained ([\\d]) swagger", fitelog);
			
			find(playermatcher);
			
			if(to_lower_case(group(playermatcher, 1)) == my_name()) {
				fiteData[fitenum].offense = true;
				find(playermatcher);
				fiteData[fitenum].opponent = group(playermatcher, 1);
				if(find(swaggermatcher)) {
					fiteData[fitenum].swagger = to_int(group(swaggermatcher, 1));
				}
			} else {
				fiteData[fitenum].offense = false;
				fiteData[fitenum].opponent = group(playermatcher, 1);
			}
			
			find(datematcher); find(timematcher);
			print("peevpee.php?action=log&ff=1&lid=" + fitenum + "&place=logs&pwd=" + my_hash());
			if(CLIprint) print("(" + group(datematcher, 1) + " - " + group(timematcher, 1) + ")");
			fiteData[fitenum].date = group(datematcher, 1);
			fiteData[fitenum].time = group(timematcher, 1);
			
			while(find(minimatcher)) {
				if(!find(winnermatcher)) {
					abort("NOPE");
				}
				if(CLIprint) print(group(minimatcher, 1) + ": " + group(winnermatcher, 1));
				if(to_lower_case(group(winnermatcher, 1)) == my_name()) {
					fiteData[fitenum].minis[group(minimatcher, 1)].win = true;
				} else {
					fiteData[fitenum].minis[group(minimatcher, 1)].win = false;
				}
			}

			find(winnermatcher);
			if(CLIprint) print("Overall Winner: " + group(winnermatcher, 1));
			
			if(to_lower_case(group(winnermatcher, 1)) == my_name()) {
				fiteData[fitenum].win = true;
			} else {
				fiteData[fitenum].win = false;
			}
			
			if(find(famematcher)) {
				if(to_lower_case(group(famematcher, 1)) == my_name()) {
					fiteData[fitenum].fame = to_int(group(famematcher, 4));
				} else {
					find(famematcher);
					fiteData[fitenum].fame = -1 * to_int(group(famematcher, 4));
				}
			}
			
			if(CLIprint) print("");
		}
	}
	
	map_to_file(fiteData, "pvp_" + my_name() + "_fiteData_" + getSeasonNumber() + ".txt");
	
	print("DONE!");
	return false;
}

boolean parseFiteLogs(int count) {
	return parseFiteLogs(count, false, false);
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
boolean parseConsumptionLogs(int daysAgo) {
	boolean[item] yummyData;
	string yummyFile = "pvp_" + my_name() + "_yummyData_" + getSeasonNumber() + ".txt";
	if(!file_to_map(yummyFile, yummyData)) {
		return false;
	}
	
	string yummylogs = visit_url("showconsumption.php?recent=1");
	matcher consumablematcher = create_matcher(";'>([\\w|\\s|\"|&|;|#|'|\.|-]*)<\/a>&nbsp;&nbsp;", 
		yummylogs);
	matcher datematcher = create_matcher("<small>([\\d|-]*) \\d+:\\d+[a|p]m<\/small>", yummylogs);
	
	while(find(consumablematcher) && find(datematcher)) {
		print("FOUND: " + group(consumablematcher, 1) + ": " + group(datematcher, 1));
	
		string dateString = group(datematcher, 1);
		date yummyDate = stringToDate(dateString);
		date dateAgo = subtractDate(stringToDate(format_date_time("yyyyMMdd", 
			today_to_string(), "yyyy-MM-dd")), daysAgo);
		item consumable = group(consumablematcher, 1).to_item();
		
		if(compareDate(yummyDate, getSeasonStart()) >= 0 && 
				compareDate(yummyDate, dateAgo) >= 0) {
			print(" DING! " + dateString + " : " + dateToString(getSeasonStart()), "blue");
			yummyData[consumable] = true;
		} else {
			yummyData[consumable] = false;
		}
	}
	
	if(!map_to_file(yummyData, yummyFile)) {
		return false;
	}
	
	set_property("pvp_last_consume_update", today_to_string());
	
	return true;
} 

boolean parseConsumptionLogs() {
	return parseConsumptionLogs(99);
}

//---------------------------------------------------------
// Mini Helping Functions

/**************************************************************************************************
Function: maxBuffs

To-do:
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
			&& is_tradeable(rec.item) && rec.score > 0) {
			
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
		} else if(rec.item == $item[d20] && mall_price($item[d20]) * 2 < PPF) {
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
	
	if(daily && pvp_attacks_left() < 50) {
		if(have_effect($effect[Silent Running]) == 0) cli_execute("swim sprints");
		if(have_effect($effect[Cold Sweat]) == 0) cli_execute("mom cold");
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
	return maxBuffs(toMax, my_meat(), my_meat(), pvp_attacks_left(), 0, 0, 0, 999, 999999999, 
		false);
}

int maxBuffs(string toMax, int maxPrice, int PPF, int fites) {
	return maxBuffs(toMax, maxPrice, PPF, fites, 0, 0, 0, 999, 999999999, false);
}

/**************************************************************************************************
Function: uniquelyConsume

To-do:
	-More flags (total to consume, etc)
	-Buffbot needs better handling
	-Needs to purge AT buffs if at max
	-Some checks are not very elegant
	-How well is overeating/drinking handled? Not well I think

Description:
	Consumes unique boozes or foods to help the player's unique consumable mini
	
Input:
	type		- Consumable type
	maxPrice	- Maximum item cost to consider
	maxSize		- Maximum consumable space to fill (fullness, drunkness)
	minAdv		- Minimum adventures per consumable space to consider 
				  (ie adv/full, adv/drunk)
	advBuff		- Whether or not to acquire adventure boosting buff 
				  (Got Milk and Ode to Booze)
	useMayo		- Attempt to use the mayo clinic to convert some full to drunk
	
Output:
	Returns true if successful
**************************************************************************************************/
boolean uniquelyConsume(string type, int maxPrice, int maxSize, int maxFill, float minAdv, 
		boolean advBuff, boolean useMayo) {
	boolean[item] consumed;
	boolean success;
	int season = getSeasonNumber();
	int fillSize;
	string yummyFile = "pvp_" + my_name() + "_yummyData_" + season + ".txt";
	
	if(!file_to_map(yummyFile, consumed)) {
		return false;
	}
	
	foreach yummy in $items[] {
		if(useMayo && hasMayo() && (my_inebriety() >= maxFill || my_inebriety() 
				>= inebriety_limit())) {
			set_property("choiceAdventure1076", 6); // set minder choice to nothing
			cli_execute("use mayo minder");			// set minder 
			set_property("choiceAdventure1076", 0); // set minder choice to default (prompt user)
			print("Uh, we're done here?", "red");
			break;
		} else if((type == "food" && my_fullness() >= maxFill) || 
					(type == "booze" && my_inebriety() >= maxFill)) {
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
		
		if(item_type(yummy) == "food") {
			fillSize = yummy.fullness;
		} else if(item_type(yummy) == "booze") {
			fillSize = yummy.inebriety;
		}
		
		if(is_tradeable(yummy) && item_type(yummy) == type && yummy != $item[none] && 
				!consumed[yummy] && fillSize <= maxSize && fillSize > 0 && 
				averange(yummy.adventures) / fillSize >= minAdv && mall_price(yummy) <= maxPrice 
				&& mall_price(yummy) > 0) {
			//cli_execute("use magicberry");
			print("Found! " + yummy.to_string(), "blue");
			buy(1, yummy);
			
			if(useMayo) {
				if(item_amount($item[mayodiol]) == 0) {
					buy(1, $item[mayodiol]);
				}
				set_property("choiceAdventure1076", 2); // set minder choice to drunk
				cli_execute("use mayo minder");			// set minder to drunk
				set_property("choiceAdventure1076", 0); // set minder choice to default
			} else if (hasMayo()){
				// I should be reverting to user's original settings, not nothing
				set_property("choiceAdventure1076", 6);
				cli_execute("use mayo minder");
				set_property("choiceAdventure1076", 0);
			}
			
			if(item_type(yummy) == "food") {
				success = eat(1, yummy);
			} else if(item_type(yummy) == "booze"){
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

//---------------------------------------------------------
// PvP Automation Functions

/**************************************************************************************************
Function: autoPvP

To-do:
	-Record fite data
	-Implement win/lose message handling

Description:
	Automates a pvp attack given a set of parameters
	
Input:
	fites	- Number of fites to execute
	type	- Type of attack
	stance	- Stance to attack with (0-11, usually)
	who		- Player to attack specifically (or attack a tougher opponent with "tough")
	
Output:
	Returns true if successful
**************************************************************************************************/
boolean autoPvP(int fites, string type, string stance, string who) {
	//&winmessage=test1
	//&losemessage=test2
	int currentFites = pvp_attacks_left();
	int callOut = 0;
	int ranked = 1;
	
	string typeStr = "null";
	string fiteBuffer;
	
	fite[int] fiteData;
	file_to_map("pvp_" + my_name() + "_fiteData_" + getSeasonNumber() + ".txt", fiteData);
	
	if(pvp_attacks_left() == 0) {
		print("You don't have any fights left!", "red");
		return false;
	}
	
	// ambiguous type handling
	if(contains_text(type, "flowers")) {
		typeStr = "flowers";
		callOut += 1;
	} 
	if(contains_text(type, "loot")) {
		typeStr = "lootwhatever";
		callOut += 1;
	} 
	if(contains_text(type, "fame")) {
		typeStr = "fame";
		callOut += 1;
	}
	if(typeStr == "null") {
		print("That isn't a valid attack type.", "red");
		return false;
	}
	
	if(callOut > 1) {
		print("I see what you did there... just so you know, I picked your attack type based on " +
				"this precedence: Fame > Loot > Flowers", "green");
	}
	
	if(who == "tough") ranked = 2;
	
	if(who != "" && who != "tough2") {
		if(typeStr == "fame") {
			print("You can't attack a specific player for fame.", "red");
			return false;
		}
		fiteBuffer = visit_url("peevpee.php?action=fight&place=fight&pwd&ranked=" + 
					"&stance=" + stance +
					"&attacktype=" + typeStr +
					"&who=" + who);
		
		matcher minimatcher = create_matcher("nowrap><b>([\\w|\\s|\"|&|;|#|'|\.|\(|\)|?|!|-]*)<\/b><\/td><td>", fiteBuffer);
		float[string] scores;
		
		while(find(minimatcher)) {
			string miniName = group(minimatcher, 1);
			scores[miniName] = getMiniScore(miniToInt(miniName), in_hardcore());
		}
		
		foreach mini, num in scores {
			print("passing fite: " + getLatestFite());
			print("passing mini: " + mini);
			print("passing score: " + num);
			fiteData[getLatestFite()].minis[mini].score = num;
		}
	} else {
		while(pvp_attacks_left() > currentFites - fites) {
			string url = "peevpee.php?action=fight&place=fight&pwd&ranked=" + ranked +
						"&stance=" + stance +
						"&attacktype=" + typeStr +
						"&who=";
			fiteBuffer = visit_url(url);
		
			matcher minimatcher = create_matcher("nowrap><b>([\\w|\\s|\"|&|;|#|'|\.|\(|\)|?|!|-]*)<\/b><\/td><td>", fiteBuffer);
			float[string] scores;
			
			while(find(minimatcher)) {
				string miniName = group(minimatcher, 1);
				scores[miniName] = getMiniScore(miniToInt(miniName), in_hardcore());
			}
			
			foreach mini, num in scores {
				print("passing fite: " + getLatestFite());
				print("passing mini: " + mini);
				print("passing score: " + num);
				fiteData[getLatestFite()].minis[mini].score = num;
			}
		}
	}
	
	map_to_file(fiteData, "pvp_" + my_name() + "_fiteData_" + getSeasonNumber() + ".txt");
	
	print("Done!", "blue");
	return true;
}

//---------------------------------------------------------
// Main Function
//
//maxBuffs(string toMax, int maxPrice, int PPF, int fites, int eatLimit, int drinkLimit, 	
//			int spleenLimit, int purityLimit, int spendingLimit)
//uniquelyConsume(string type, int maxPrice, int maxSize, int maxFill, float minAdv, boolean advBuff, boolean useMayo)
// args can be better right? Surely
void main(string params) {
	string[int] args = split_string(params, " ");
	string doWhat = args[0];
	int arglen = 0;
	
	foreach arg in args {
		arglen += 1;
	}
	
	print(arglen);
	
	if(to_int(doWhat) > 0 && arglen >= 3) {
		string who = "";
	
		if(arglen > 3) {
			for i from 3 to arglen - 1 {
				who += args[i];
				if(i < arglen - 1) {
					who += " ";
				}
			}
		}
		//autoPvP(int fites, string type, string stance, string who)
		autoPvP(to_int(doWhat), args[1], args[2], who);
	} else {
		switch(doWhat) {
			case 'unique':
				if(get_property("pvp_last_consume_update") != today_to_string()) {
					if(arglen > 1) {
						parseConsumptionLogs(to_int(args[1]));
					} else {
						parseConsumptionLogs();
					}
				}
				uniquelyConsume("booze", 5000, 1, 14, 1, true, false);
				break;
			case 'logs':
				int fites;
				
				if(arglen == 1) {
					fites = 1000;
				} else {
					fites = to_int(args[1]);
				}
				parseFiteLogs(fites, false, true);
				break;
			case 'eatlogs':
				print("Yummy logs!", "green");
				if(arglen > 1) {
					print(to_int(args[1]), "blue");
					parseConsumptionLogs(to_int(args[1]));
				} else {
					parseConsumptionLogs();
				}
				break;
			case 'buff':
				maxBuffs("item", 5000, 100, pvp_attacks_left(), 0, 0, 0, 999, 999999999, false);
				break;
			case 'capbuff':
				maxBuffs("item", 5000, 100, 1, 0, 0, 0, 999, 999999999, false);
				break;	
			case 'lookup':
				string who = "";
				
				for i from 1 to arglen - 1 {
					who += args[i];
					if(i < arglen - 1) {
						who += " ";
					}
				}
				playerLookup(who);
				break;
			default:
				print("Invalid command!", "blue");
				break;
		}
	}
}
