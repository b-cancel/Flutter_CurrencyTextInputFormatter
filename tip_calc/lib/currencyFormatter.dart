import 'package:flutter/services.dart';
import 'package:tip_calc/currencyUtils.dart';

/// LEARNED: dart can fail silently
///   1. run sub string with an index that points to characters that a string doesn't cover
///   2. try to += to a string set to null
///   3. double.parse parsing just a period

/// FLUTTER BUGS:
/// 1. I can select the text in the input field but I can't move the start tick, ONLY the end tick
///   - only occurs when your ANDROID phone is plugged in and not when you are running the emulator and using the mouse to simulate touch
/// 2. its possible for baseOffset AND OR extentOffset to be less than 0... which makes no sense
///   - I have offset correctors to work past this
///   - one situation it occurs in consistently is when you clear the field (some values go to -1)

/// FRAMEWORK NOTES:
/// 1.  baseOffset holds the position where the selection begins
/// 2. extentOffset holds the position where the selection ends
/// 3. its possible for extentOffset to be <= than baseOffset
///   - I adjusted the values to avoid this
/// 4. using string.codeUnitAt(i) => if i is 0 through 9 the codes are 48 through 57

/// CURRENCY FORMAT ASSUMPTIONS:
/// 1. on the left of the SEPARATOR you have your whole number
/// 2. on the right of the SEPARATOR you have your fractions of a particular precision
/// 3. the SEPARATOR separates these both
/// 4. the SEPARATOR is just ONE character
/// 5. the SPACER that might be chosen to place every 3 numbers from the SEPARATOR is just ONE character
/// 6. the number is read from left to right

/// OTHER ASSUMPTIONS:
/// 1. we only have a backspace key and not a delete key
/// 2. you want to keep the separator that was typed first... so if you paste multiple separators you keep the one that is furthest to the left
/// 3. the mask if enabled will push the cursor to the right if it ever has to choose between right and left
/// 4. We remove things in this order -> (1) currencyIdentifier (2) Mask -> and add them in the inverse order
/// 5. We ony need to report the new double value IF it doesn't match our previous one

/// NOTE:
/// 1. voice typing has not been tested
/// 2. because there are so many different steps and its all string parsing which tend to have tons of edge cases
///   - I created a [debugMode] variable that can be turned to true to see exactly how the string is bring processed and find the potential bug
///   - this exists just in case but I thoroughly tested the code
/// 3. I didn't try to enforce any minimum values because this doesn't make sense since the field will start off initially as empty
///   - although I do have an "ensureMinDigitsAfterSeparatorString" function to beautify formatting after editing is complete
///     - this ONLY truncates, feel free to implement rounding up or down or using the rules of significant figures

/// FUTURE PLANS:
/// 1. this should function with all these currency codes https://en.wikipedia.org/wiki/ISO_4217
///   - automatically set the most variables possible depending on the selected code
/// 2. avoid making any corrections if the string is ESSENTIALLY the same as the previous
///   - EX: old: 12.34... new is 12.345... OR new is 12.340000

class CurrencyTextInputFormatter extends TextInputFormatter {

  /// --------------------------------------------------VARIABLE PREPARATION--------------------------------------------------

  void Function(double) runAfterComplete;

  bool enforceMaxDigitsBefore;
  int maxDigitsBeforeDecimal; /// NOTE: this should be >= 0

  bool enforceMaxDigitsAfter;
  int maxDigitsAfterDecimal; /// NOTE: this should be >= 0

  String separator; /// NOTE: this should just be ONE character

  /// NOTE: we assume you only want spacer between the digits on the left side
  /// EX: assuming (a) separator = '.' (b) spacer = ','
  /// 12,324,000.002412 => result
  /// 12,324,000.000,241,2 => not result
  /// 12,324,000.0,002,412 => not result
  bool addMaskWithSpacers;
  String spacer; /// NOTE: this should just be ONE character

  bool addTagToLeft;
  String leftTag; /// NOTE: this CAN BE multiple characters (for country codes... EX: $ OR USD)

  bool addTagToRight;
  String rightTag; /// NOTE: this CAN BE multiple characters (for country codes... EX: $ OR USD)

  bool allowLeading0s; /// WHY would you ever want to allow them... gross...

  //USD format is default
  CurrencyTextInputFormatter(
      Function runAfterComplete,
      {
        /// NOTE: this is USD format
        bool enforceMaxDigitsBefore: false,
        int maxDigitsBeforeDecimal: 0,

        bool enforceMaxDigitsAfter: true,
        int maxDigitsAfterDecimal: 2,

        String separator: '.',

        bool maskWithSpacers: true,
        String spacer: ',',

        bool addTagToLeft: true,
        String leftTag: '\$',

        bool addTagToRight: true,
        String rightTag: ' ',

        bool allowLeading0s: false,
      }) {
    this.runAfterComplete = runAfterComplete;

    this.enforceMaxDigitsBefore = enforceMaxDigitsBefore;
    this.maxDigitsBeforeDecimal = maxDigitsBeforeDecimal;

    this.enforceMaxDigitsAfter = enforceMaxDigitsAfter;
    this.maxDigitsAfterDecimal = maxDigitsAfterDecimal;

    this.separator = separator;

    this.addMaskWithSpacers = maskWithSpacers;
    this.spacer = spacer;

    this.addTagToLeft = addTagToLeft;
    this.leftTag = leftTag;

    this.addTagToRight = addTagToLeft;
    this.rightTag = leftTag;

    this.allowLeading0s = allowLeading0s;
  }

  /// --------------------------------------------------MAIN FUNCTION--------------------------------------------------

  /// NOTE: string length is NOT something that can be used to optimize
  /// IF oldValue.text.length == newValue.text.length => it doesn't imply anything
  /// it doesn't imply anything since we can select 1 character and type another character in its place and that new character might break things
  /// else if newValue.text.length > oldValue.text.length => we have added something so we DEFINITELY need to check what that was
  /// else if newValue.text.length < oldValue.text.length => it doesn't imply anything
  /// this is because we could have selected 2 characters and typed another character in its place and that new character might break things
  /// BECAUSE OF THE ABOVE: we can only avoid doing all the checks if the strings are exact matches of each other

  // NOTE: this runs when the field data changes when either (1) you type on keyboard OR (2) you paste text from the clipboard
  // So. We need to plan for both scenarios to avoid bugs
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {

    if(debugMode) print("");

    printDebug("ORIGINAL VALUES", oldValue, newValue);

    if(newValue.text != oldValue.text){ /// NOTE this also includes changes to just our mask (by removing or replacing a spacer)

      /// NOTE: we always mess with both the old and new value BECAUSE
      /// we only want to update the value through the function IF our values are different and not if we just messed with a spacer or a currency identifier

      //save all the variables we need to use to determine how to proceed
      oldValue = correctTextEditingValueOffsets(oldValue);
      newValue = correctTextEditingValueOffsets(newValue);

      printDebug("AFTER INDEX CORRECTION", oldValue, newValue);

      //TODO... I seems like this isn't really necessary but it allow for more identifiers... because it lets our separator value to be within the identifier without causing issues
      //remove identifiers
      /*
      if(addTagToLeft){
        oldValue = removeTag(oldValue, leftTag, true);
        newValue = removeTag(newValue, leftTag, currencyIdentifierOnLeft);

        printDebug("AFTER IDENTIFIER REMOVAL", oldValue, newValue);
      }
      */

      //TODO... I don't think this is really necessary (BUT it might be usable as an optimization)
      //handle masking (assumes that if this is off the string doesn't have a mask)
      if(addMaskWithSpacers){ //NOTE: its important that both of these are masked so that we can get an accurate character count
        oldValue = removeSpacers(oldValue, spacer);
        newValue = removeSpacers(newValue, spacer);

        printDebug("AFTER MASK REMOVAL", oldValue, newValue);
      }

      /// -------------------------MAIN ERROR CORRECTION BELOW-------------------------
      /// NOTE: oldValue is assumed to already follow these rules

      // (0) remove anything that isn't a number or a separator
      // (1) make sure we have AT MOST one separator

      printDebug("AFTER ??? - [BOTH SHOULD BE PARASABLE AS DOUBLES -w/o- correct limits]", oldValue, newValue);

      // (2) remove leading 0s
      if(allowLeading0s == false){
        newValue = removeLeading0s(newValue);

        printDebug("AFTER REMOVE LEADING 0s", oldValue, newValue);
      }

      // (3) ensure limits before decimal
      if(enforceMaxDigitsBefore){
        newValue = ensureMaxDigitsBeforeSeparator(newValue, separator, maxDigitsBeforeDecimal);

        printDebug("AFTER ENSURE DIGITS BEFORE DECIMAL", oldValue, newValue);
      }

      // (4) ensure limits after decimal
      if(enforceMaxDigitsAfter){
        newValue = ensureMaxDigitsAfterSeparator(newValue, separator, maxDigitsAfterDecimal);

        printDebug("AFTER ENSURE DIGITS BEFORE DECIMAL", oldValue, newValue);
      }

      /// -------------------------MAIN ERROR CORRECTION ABOVE-------------------------

      printDebug("AFTER ERROR CORRECTION - [BOTH SHOULD BE PARASABLE AS DOUBLES -with- correct limits]", oldValue, newValue);

      //run passed function that saves our currency as a double
      double oldDouble = convertToDouble(oldValue.text);
      double newDouble = convertToDouble(newValue.text);
      if(oldDouble != newDouble) runAfterComplete(newDouble);

      //handle masking
      if(addMaskWithSpacers){
        if(debugMode) oldValue = addSpacers(oldValue, separator, spacer); //note: this is only for debugging
        newValue = addSpacers(newValue, separator, spacer);

        printDebug("AFTER MASK ADD", oldValue, newValue);
      }

      //add identifiers (if will only not do so if your identifier is nothing)
      /*
      if(addTagToLeft){
        if(debugMode) oldValue = addTag(oldValue, leftTag, currencyIdentifierOnLeft); //note: this is only for debugging
        newValue = addTag(newValue, leftTag, currencyIdentifierOnLeft);

        printDebug("AFTER CURRENCY IDENTIFIER ADD", oldValue, newValue);
      }
      */

      oldValue = correctSingleTextEditingValueOffset(oldValue.text, oldValue.selection.baseOffset);
      newValue = correctSingleTextEditingValueOffset(newValue.text, newValue.selection.baseOffset);

      printDebug("FINAL VALUES", oldValue, newValue);

      if(debugMode) print("");

      //return our processed string
      return newValue;
    }
    else return newValue; //nothing has changed and this ran when it should not have
    /// NOTE: the code above HAS to return newValue exactly otherwise we will indefinitely correct our value
  }
}

/// --------------------------------------------------ERROR CORRECTING FUNCTIONS--------------------------------------------------

/*
TextEditingValue removeAllButNumbersAndSeparator(TextEditingValue value, String separator){
  //prepare variables
  String text = value.text;
  int baseOffset = value.selection.baseOffset;
  int extentOffset = value.selection.extentOffset;

  if(text.length == 0) return value;
  else{
    //NOTE: we deleted back to front so we don't have to constantly adjust the index on deletion
    for(int i = text.length - 1; i >= 0; i--) {
      if (((48 <= text.codeUnitAt(i) && text.codeUnitAt(i) <= 57) || text[i] == separator) == false){
        //---remove whatever is at i
        text = removeCharAtIndex(text, i);

        //---adjust the offset accordingly
        if(i < baseOffset) baseOffset--;
        if(i < extentOffset) extentOffset--;
      }
    }

    //return the corrected values
    return correctTextEditingValueOffsets(
        TextEditingValue(
          text: text,
          selection: TextSelection(baseOffset: baseOffset, extentOffset: extentOffset),
        )
    );
  }
}

String removeAllButOneSeparator(String text, String separator, int baseOffset, int extentOffset, int addedCharCount){
  int firstIndexOfSeparator = text.indexOf(separator);
  if(firstIndexOfSeparator != -1){ //at least 1 separator exists
    if(firstIndexOfSeparator != text.lastIndexOf(separator)) { //at least 2 separators exist
      /// If you DID NOT have any separators before => Which one do you keep? => THE FIRST
      /// If you DID have 1 separator before => Which one do you keep? => THE OLD ONE
      ///   BUT => it isn't all ways possible to identify which is the older one with just oldValue and newValue

      /// EXAMPLE:
      /// oldValue = "12.12"
      /// [1] add by pasting ".12" after the first "12" => newValue = "12[.12].12" = "12.12.12"
      /// [2] add by pasting "2.1" after "12.1" => newValue = "12.1[2.1]2" = "12.12.12"
      /// in [1] you add a period in front of the previous one
      /// in [2] you add a period behind the previous one
      /// in both cases the result is the same

      ///   SO => we must use the base and extent offsets

      // this is safe to use because its impossible to add anything before the baseOffset,
      // in the worst case it will be 0, which covers the edge case of adding 2+ separators into an empty field
      // NOTE: for all the fields below (except insertion) its possible for each of them to be empty in different scenarios
      //  - because of the above we have to make an extra check otherwise substring will duplicate characters at the left end
      String beforeInsertion = (0 == baseOffset) ? "" : text.substring(0, baseOffset);
      int lastAdditionIndex = baseOffset + addedCharCount;
      /// NOTE: this may seem like it requires (lastAdditionIndex + 1) but it doesn't
      String insertion = text.substring(baseOffset, lastAdditionIndex); //NOTE: this will NEVER be empty
      String afterInsertion = ((lastAdditionIndex) == text.length) ? "" : text.substring(lastAdditionIndex, text.length);

      //remove separators from the back OF THE INSERTION until only the FIRST one is left
      for(int index = insertion.length - 1; insertion.indexOf(separator) != insertion.lastIndexOf(separator); index--){
        if(insertion[index] == separator){ //remove extra separator
          insertion = removeCharAtIndex(insertion, index);
        }
      }

      //remove the one separator FROM THE INSERTION if it isn't the only one in the string
      if(beforeInsertion.contains(separator) || afterInsertion.contains(separator)){ // NOTE: they will never both meet the requirement
        insertion = removeCharAtIndex(insertion, insertion.indexOf(separator));
      }

      return (beforeInsertion + insertion + afterInsertion);
    }
    else return text;
  }
  else return text;
}

/// NOTE: assumes the string has AT MOST one separator
/// assumes that you want to remove the separator if there are no values after it
String removeExtraValuesAfterSeparator(String string, int valuesAfterSeparator, {bool showSinglePeriod = false}){
  if(string.contains('.')){
    int indexOfDecimal = string.indexOf('.');
    var beforeSeparator = (0 == indexOfDecimal) ? "" : string.substring(0, indexOfDecimal); //inc, exc
    int longestAllowableStringLength = indexOfDecimal + valuesAfterSeparator + 1;
    int stringLength = (longestAllowableStringLength < string.length) ? longestAllowableStringLength : string.length;
    var separatorToEnd = string.substring(indexOfDecimal, stringLength); //inc, exc
    var result  = beforeSeparator + separatorToEnd;
    if(showSinglePeriod == false){
      result = (valuesAfterSeparator == 0) ? result.substring(0, result.length - 1) : result;
    }
    return result;
  }
  else return string;
}

// NOTE: the newStrLen that is passed here is from the string after all the necessary corrections
int selectionCorrection(int oldBaseOffset, int countOfNewCharsThatPassedFilters){
  print("characters added " + countOfNewCharsThatPassedFilters.toString());
  if(countOfNewCharsThatPassedFilters > 0) return (oldBaseOffset + countOfNewCharsThatPassedFilters); //place the cursor after all the inserted characters
  else return oldBaseOffset;

  //FOR THE ELSE either
  // (1) nothing was added or deleted at oldBaseOffset
  // (2) stuff was deleted starting with oldBaseOffset
  // (3) stuff was trying to get added at oldBaseOffset but didn't pass the tests
  // (4) or (2) AND (3) starting at oldBaseOffset
  // in all cases, going to oldBaseOffset works
}
*/

/// --------------------------------------------------OTHER FUNCTIONS--------------------------------------------------

//TODO... for readability it might be best to define this in the only place its used
//NOTE: this has been thoroughly tested
int addedCharacterCount(TextEditingValue oldValue, String newValue){
  //newCharCount = oldCharCount - numberOfCharsWeRemoved + numberOfCharsWeAddedThatPassed
  //(newCharCount - oldCharCount) + numberOfCharsWeRemoved = numberOfCharsWeAddedThatPassed
  int countDifference = newValue.length - (oldValue.text).length;
  /// NOTE: this only includes the characters removed by selection
  int numberOfCharsWeRemoved = (oldValue.selection.extentOffset) - (oldValue.selection.baseOffset);
  if(numberOfCharsWeRemoved == 0){ //we didn't remove characters by selection
    //so we either removed a SINGLE character by deletion => string shortens by 1
    //OR added characters => string grows by X (the var would be 0 if we added NOT from a selection)
    numberOfCharsWeRemoved = (newValue.length < (oldValue.text).length) ? 1 : 0;
  }
  return countDifference + numberOfCharsWeRemoved;
}

/// --------------------------------------------------VALUE REPORTING FUNCTION--------------------------------------------------

//TODO... can this convert a string with leading 0s? IF not then fix it

/// NOTE: returns -1 if your string has more than 1 separator
double convertToDouble(String str){
  String strWithPeriodSeparator = ""; //set it to something not null so we can add to it

  //loop through the number and assume anything that isn't a number is a separator
  for(int i=0; i<str.length; i++){
    if(48 <= str.codeUnitAt(i) && str.codeUnitAt(i) <= 57) strWithPeriodSeparator = strWithPeriodSeparator + str[i];
    else strWithPeriodSeparator = strWithPeriodSeparator + "."; //replace the separator for a period for easy parsing as a double
  }

  if(strWithPeriodSeparator.indexOf('.') == -1){
    if(strWithPeriodSeparator == "") return 0; //we have no value
    else return double.parse(strWithPeriodSeparator); //no separator exists so its already parsable
  }
  else{
    if(strWithPeriodSeparator == '.') return 0; //we have no value
    else{
      if(strWithPeriodSeparator.indexOf('.') != str.lastIndexOf('.')) return -1; //we have more than 1 separator and this is illegal
      else return double.parse(strWithPeriodSeparator);
    }
  }
}

/// --------------------------------------------------DEBUG MODE--------------------------------------------------

bool debugMode = true;
void printDebug(String description, TextEditingValue oldValue, TextEditingValue newValue){
  if(debugMode){
    print(description + "*************************" + oldValue.text
        + " [" + oldValue.selection.baseOffset.toString() + "->" + oldValue.selection.extentOffset.toString() + "]"
        + " => " + newValue.text
        + " [" + newValue.selection.baseOffset.toString() + "->" + newValue.selection.extentOffset.toString() + "]"
    );
  }
}