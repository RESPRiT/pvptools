/*************************************************************************************************
* RESLib by RESPRiT
* Version 0.1
*
* https://github.com/RESPRiT
**************************************************************************************************/
script "RESLib";
//notify TamedTheTurtle;

//-------------------------------------------------------------------------------------------------
// Global Variables

// number range
record range
{
  float max;
  float min;
};

// a date (not the kind you take someone out on)
record date {
	int year;
	int month;
	int day;
};

// MONTHLEN is 0-12 (with 0 being no month) for sake of convenience
string[int] MONTHLENSTR = split_string("0-31-28-31-30-31-30-31-31-30-31-30-31", "-");
int[int] MONTHLEN; 
foreach i, num in MONTHLENSTR {
	MONTHLEN[i] = to_int(num);
}

// constants for comparing dates
int EARLIER = 1;
int EQUAL = 0;
int LATER = -1;

//---------------------------------------------------------
// Date Functions
// All functions use "YYYY-MM-DD" format

/**************************************************************************************************
Function: isLeapYear

Description:
	Checks if a given year is a leap year

Input:
	year	- Year to check
	
Output:
	Returns true if the year is a leap year, false if the year is not
**************************************************************************************************/
boolean isLeapYear(int year) {
	if(year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)) {
		return true;
	} else {
		return false;
	}
}

/**************************************************************************************************
Function: stringToDate

Description:
	Converts a given string into a date

Input:
	dateString	- String to convert
	
Output:
	Returns the given string as a date
**************************************************************************************************/
date stringToDate(string dateString) {
	string[int] splitDate = split_string(dateString, "-");
	date returnDate;
	
	returnDate.year = splitDate[0].to_int();
	returnDate.month = splitDate[1].to_int();
	returnDate.day = splitDate[2].to_int();
	
	return returnDate;
}

/**************************************************************************************************
Function: dateToString

Description:
	Converts a given date into a string

Input:
	toStr	- Date to convert
	
Output:
	Returns the given date as a string
**************************************************************************************************/
string dateToString(date toStr) {
	return toStr.year + "-" + toStr.month + "-" + toStr.day;
}

/**************************************************************************************************
Function: compareDate

Description:
	Compares two given dates in terms of each other

Input:
	date1	- First date to compare
	date2	- Second date to compare to the first
	
Output:
	Returns EARLIER (-1) if date1 is before date2, EQUAL (0) if they are the same date, and
	LATER (1) if date1 is later than date2
**************************************************************************************************/
int compareDate(date date1, date date2) {
	if(date1.year > date2.year) {
		return LATER;
	} else if(date1.year == date2.year) {
		if(date1.month > date2.month) {
			return LATER;
		} else if(date1.month == date2.month) {
			if(date1.day > date2.day) {
				return LATER;
			} else if (date1.day == date2.day) {
				return EQUAL;
			} else {
				return EARLIER;
			}
		} else {
			return EARLIER;
		}
	} else {
		return EARLIER;
	}
}

/**************************************************************************************************
Function: addDate

Description:
	Adds a given number of days to a given date

Input:
	toAdd	- The date to add days to
	day		- Number of days to add
	
Output:
	Returns the resulting date
**************************************************************************************************/
date addDate(date toAdd, int days) {
	date returnDate = toAdd;
	returnDate.day += days;
	
	while(returnDate.day > MONTHLEN[returnDate.month]) {
		if(isLeapYear(returnDate.year) && returnDate.month == 2) {
			returnDate.day -= MONTHLEN[returnDate.month] + 1;
		} else {
			returnDate.day -= MONTHLEN[returnDate.month];
		}
		returnDate.month += 1;

		if(returnDate.month > 12) {
			returnDate.year += 1;
			returnDate.month = 1;
		}
	}
	
	return returnDate;
}

/**************************************************************************************************
Function: subtractDate

Description:
	Subtracts a given number of days from a given date

Input:
	toSub	- The date to subtract days from
	day		- Number of days to subtract
	
Output:
	Returns the resulting date
**************************************************************************************************/
date subtractDate(date toSub, int days) {
	date returnDate = toSub;
	returnDate.day -= days;
	
	while(returnDate.day < 1) {
		if(isLeapYear(returnDate.year) && returnDate.month == 2) {
			returnDate.day += MONTHLEN[returnDate.month] + 1;
		} else {
			returnDate.day += MONTHLEN[returnDate.month];
		}
		
		returnDate.month -= 1;
		
		if(returnDate.month < 1) {
			returnDate.year -= 1;
			returnDate.month = 12;
		}
	}
	
	return returnDate;
}

//---------------------------------------------------------
// Number Functions

/**************************************************************************************************
Function: averange

Description:
	Gives the average value of a range (shamelessly stolen-ish from EatDrink.ash)

Input:
	rangestring	- Range to evaluate
	
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
// Main

void main() {
	# date testdate;
	
	# for i from 0 to 2000 by 1 {
		# testdate = addDate(stringToDate("2015-12-31"), i);
		# print(dateToString(testdate));
	# }
}
