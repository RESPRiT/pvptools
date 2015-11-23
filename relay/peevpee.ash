/*************************************************************************************************
* PvP Relay Override by RESPRiT
* Version 0.0
* 
* https://github.com/RESPRiT
**************************************************************************************************/
script "PvP Relay Over Rice";

//-------------------------------------------------------------------------------------------------
// Global Variables
record mini {
	string title; // Name of the mini
	string desc;  // Description to replace title
};

mini[int] miniList;

//-------------------------------------------------------------------------------------------------
// Helper Functions
boolean load_current_map(string fname, mini[int] map) {
	file_to_map(fname+".txt", map);
	
	if (count(map) == 0) return false;
	
	return true;
}

//-------------------------------------------------------------------------------------------------
// Text Override Functions
buffer miniDesc(buffer page) {
	foreach i, mini in miniList {
		page.replace_string(mini.title, "<font color=\"green\">" + mini.desc + "</font>");
	}
	//page.replace_string("On the Nice List", "<font color=\"green\">Who has earned the most Karma?</font>");
	
	return page;
}

buffer winColor(buffer page) {
	string winText = "align=\"center\"><b>" + my_name() + "</b> wins!";

	if(contains_text(to_lower_case(page), winText)) {
		page.replace_string("align=\"center\"><b>", "align=\"center\"><b><font color=\"blue\">");
		page.replace_string("</b> Wins!", "</b> Wins!</font>");
	} else {
		page.replace_string("align=\"center\"><b>", "align=\"center\"><b><font color=\"red\">");
		page.replace_string("</b> Wins!", "</b> Wins!</font>");
	}
	
	return page;
}

buffer checkOnline(buffer page) {
	//matcher usermatcher = create_matcher("(?<=who\=[\\d]*\">)[\\w|\\s]*(?=(&nbsp;)*?<\/a>)", page);
	//matcher usermatcher = create_matcher("(?<=who\=.\">)[\\w|\\s]*(?=(&nbsp;)*<\/a>)", page);
	matcher usermatcher = create_matcher("(?<=[\\d]*\">)[\\w|\\s]*(?=<\/a> has been)", page);
	
	int i = 0;
	
	while(i < 2) {	
		find(usermatcher);
		print(i + " : " + group(usermatcher));
		
		if(is_online(group(usermatcher))) {
			page.replace_string(group(usermatcher), "<font color=\"green\">" + group(usermatcher) + "</font>");
		}
		i += 1;
	}
	
	return page;
}

buffer enhance(buffer page) {
	if(get_property("pvp_miniDesc").to_boolean()) page = miniDesc(page);
	if(get_property("pvp_winColor").to_boolean()) page = winColor(page);
	//page = checkOnline(page);
	
	return page;
}

//-------------------------------------------------------------------------------------------------
// Main Function
void main() {
	load_current_map("pvp_minis", miniList);
	visit_url().enhance().write();
}
