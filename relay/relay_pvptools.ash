/*************************************************************************************************
* PvP Tools Relay by RESPRiT
* Version 0.0
* 
* Adapted from relay_AutoHCCS.ash
* 
* https://github.com/RESPRiT
**************************************************************************************************/
script "PvP Tools Relay";
import "pvptools.ash";

//-------------------------------------------------------------------------------------------------
// Global Variables
record setting {
	string name;
	string type;
	string description;
	string category;
	string color;
	string d;
	string e;
};

setting[int] s;
string[string] fields;
boolean success;

mini[int] miniList;

string general;
string experimental;
string development;

//-------------------------------------------------------------------------------------------------
// Helper Functions
boolean load_current_settings_map(string fname, setting[int] map) {
	file_to_map(fname+".txt", map);
	
	if (count(map) == 0) return false;
	
	return true;
}

boolean load_current_mini_map(string fname, mini[int] map) {
	file_to_map(fname+".txt", map);
	
	if (count(map) == 0) return false;
	
	return true;
}

string generate_html(setting s) {
	string html;
	
	html += "<tr bgcolor=" + s.color + ">";
	
	switch (s.type) {
		case "boolean" :
			html += "<td>"+s.name+"</td><td colspan=2><select name='"+s.name+"'>";
			if (get_property(s.name) == "true") {
				html += "<option value='true' selected='selected'>true</option><option value='false'>false</option>";
			} else {
				html += "<option value='true'>true</option><option value='false' selected='selected'>false</option>";
			}
			html += "</td><td>"+s.description+"</td></tr>";
		break;

		default :      
			html += "<td>"+s.name+"</td><td colspan=2><input type='text' name='"+s.name+"' value='"+get_property(s.name)+"' /></td><td>"+s.description+"</td></tr>";
		break;
	}
	
	return html;
}

// Temporary Test Code
boolean generate_mini_scores() {
	string html;
	
	boolean success = load_current_mini_map("pvp_minis", miniList);
	
	foreach i, mini in miniList {
		writeln("<strong>" + mini.title + "</strong>" + ": " + getMiniScore(mini.title) + "<br>");
	}
	
	writeln("&mdash;");
	
	return success;
}

//-------------------------------------------------------------------------------------------------
// Main Function
void main() {
	load_current_settings_map("pvptools_settings", s);
	fields = form_fields();
	success = count(fields) > 0;
	
	foreach x in fields {
		set_property(x, fields[x]);
	}
	
	writeln("<html><head><title>PvP Tools</title></head><body style=\"font-family: Arial;\"><form action='' method='post'><center><table cellspacing=0 cellpadding=0><tr><td style=\"color: white;\" align=\"center\" bgcolor=\"blue\" colspan=\"4\"><b>PvP Tools Version 0.0</b></td></tr><tr><td style=\"padding: 5px; border: 1px solid blue;\"><center><table><tr><td colspan='4'><center><table><tr><td valign=top></td><td valign=top><center><b>Configure Settings</b></center><p>Here are some cool settings!  Configure them!</td></tr></table></center></td></tr><tr><th>Name of Setting:</th><th>Value:</th><th>Test:</th><th>Description:</th></tr>");
	foreach x in s {
		switch (s[x].category) {
			case "gen" :
				general += generate_html(s[x]);
				break;
				
			case "exp" :
				experimental += generate_html(s[x]);
				break;
				
			case "dev" :
				development += generate_html(s[x]);
				break;
				
			default :
				general += generate_html(s[x]);
				break;
		}
	}
	
	if(length(general).to_boolean()) {
		writeln("<tr><td colspan=4 height=1 bgcolor=black> </td></tr><tr><td colspan='4' align=center>&mdash; <b>General Settings</b> &mdash;</td></tr><tr><td colspan=4 height=1 bgcolor=black> </td></tr>");
		writeln(general);
	}
	
	if(length(experimental).to_boolean()) {
		writeln("<tr><td colspan=4 height=1 bgcolor=black> </td></tr><tr><td colspan='4' align=center>&mdash; <b>Experimental Settings</b> (Use at your own risk!) &mdash;</td></tr><tr><td colspan=4 height=1 bgcolor=black> </td></tr>");
		writeln(experimental);
	}
	
	if(length(development).to_boolean()) {
		writeln("<tr><td colspan=4 height=1 bgcolor=black> </td></tr><tr><td colspan='4' align=center>&mdash; <b>Development Settings</b> (Do <b>NOT</b> touch these if you don't know what you're doing) &mdash;</td></tr><tr><td colspan=4 height=1 bgcolor=black> </td></tr>");
		writeln(development);
	}
	
	generate_mini_scores(); // Temporary test code
	
	writeln("<tr><td colspan='3'><input type='submit' name='' value='Save Changes' /></td></tr></form>");
	
	
	
	writeln("</body></html>");
}