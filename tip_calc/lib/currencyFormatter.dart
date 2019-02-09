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
///   - I have offset correctors to work around this
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
/// 2. avoid making any corrections if the string is ESSENTIALLY the same as the previous => speed improvement (might be negligible)
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
        bool enforceMaxDigitsBefore: true,
        int maxDigitsBeforeDecimal: 7,

        bool enforceMaxDigitsAfter: true,
        int maxDigitsAfterDecimal: 2,

        String separator: '.',

        bool maskWithSpacers: true,
        String spacer: ',',

        bool addTagToLeft: true,
        String leftTag: '\$',

        bool addTagToRight: false,
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

    this.addTagToRight = addTagToRight;
    this.rightTag = rightTag;

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

      //TODO... I seems like this isn't really necessary but it allows for more tags... because it lets our separator value to be within the identifier without causing issues
      //remove tags
      if(addTagToLeft){
        oldValue = removeLeftTag(oldValue, leftTag);
        newValue = removeLeftTag(newValue, leftTag);

        printDebug("AFTER LEFT TAG REMOVAL ", oldValue, newValue);
      }

      if(addTagToRight){
        oldValue = removeRightTag(oldValue, rightTag);
        newValue = removeRightTag(newValue, rightTag);

        printDebug("AFTER RIGHT TAG REMOVAL ", oldValue, newValue);
      }

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
      newValue = removeAllButNumbersAndTheSeparator(newValue, separator);

      printDebug("AFTER REMOVING ALL EXCEPT NUMBERS AND THE SEPARATOR", oldValue, newValue);

      // (1) make sure we have AT MOST one separator
      newValue = removeAllButOneSeparator(oldValue, newValue, separator);

      printDebug("AFTER REMOVING ALL EXCEPT THE FIRST SEPARATOR - [BOTH SHOULD BE PARASABLE AS DOUBLES -w/o- correct limits]", oldValue, newValue);

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

        printDebug("AFTER MASK ADDITION", oldValue, newValue);
      }

      //add tags
      if(addTagToLeft){
        oldValue = addLeftTag(oldValue, leftTag);
        newValue = addLeftTag(newValue, leftTag);

        printDebug("AFTER LEFT TAG ADDITION" + leftTag + " <", oldValue, newValue);
      }

      if(addTagToRight){
        oldValue = addRightTag(oldValue, rightTag);
        newValue = addRightTag(newValue, rightTag);

        printDebug("AFTER RIGHT TAG ADDITION" + rightTag + " <", oldValue, newValue);
      }

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

TextEditingValue removeAllButOneSeparator(TextEditingValue oldValue, TextEditingValue newValue, String separator){

  //NOTE: this has been thoroughly tested
  int addedCharacterCount(TextEditingValue oldValue, String newText){
    //newCharCount = oldCharCount - numberOfCharsWeRemoved + numberOfCharsWeAddedThatPassed
    //(newCharCount - oldCharCount) + numberOfCharsWeRemoved = numberOfCharsWeAddedThatPassed
    int countDifference = newText.length - (oldValue.text).length;
    /// NOTE: this only includes the characters removed by selection
    int numberOfCharsWeRemoved = (oldValue.selection.extentOffset) - (oldValue.selection.baseOffset);
    if(numberOfCharsWeRemoved == 0){ //we didn't remove characters by selection
      //so we either removed a SINGLE character by deletion => string shortens by 1
      //OR added characters => string grows by X (the var would be 0 if we added NOT from a selection)
      numberOfCharsWeRemoved = (newText.length < (oldValue.text).length) ? 1 : 0;
    }
    return countDifference + numberOfCharsWeRemoved;
  }

  int addedCharactersThatPassedCount = addedCharacterCount(oldValue, newValue.text);

  printDebug("Between these 2 value there have been " + addedCharactersThatPassedCount.toString() + " that passed", oldValue, newValue);

  if(addedCharactersThatPassedCount > 0){
    String text = newValue.text;
    int baseOffset = oldValue.selection.baseOffset;

    int newBaseOffset = newValue.selection.baseOffset;
    int newExtentOffset = newValue.selection.extentOffset;

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
        int lastAdditionIndex = baseOffset + addedCharactersThatPassedCount;
        /// NOTE: this may seem like it requires (lastAdditionIndex + 1) but it doesn't
        String insertion = text.substring(baseOffset, lastAdditionIndex); //NOTE: this will NEVER be empty
        String afterInsertion = ((lastAdditionIndex) == text.length) ? "" : text.substring(lastAdditionIndex, text.length);

        //remove separators from the back OF THE INSERTION until only the FIRST one is left
        for(int index = insertion.length - 1; insertion.indexOf(separator) != insertion.lastIndexOf(separator); index--){
          if(insertion[index] == separator){ //remove extra separator
            insertion = removeCharAtIndex(insertion, index);

            if(index < newBaseOffset) newBaseOffset--;
            if(index < newExtentOffset) newExtentOffset--;
          }
        }

        //remove the one separator FROM THE INSERTION if it isn't the only one in the string
        if(beforeInsertion.contains(separator) || afterInsertion.contains(separator)){ // NOTE: they will never both meet the requirement
          int separatorIndex = insertion.indexOf(separator);
          insertion = removeCharAtIndex(insertion, separatorIndex);

          if(separatorIndex < newBaseOffset) newBaseOffset--;
          if(separatorIndex < newExtentOffset) newExtentOffset--;
        }

        //return the corrected values
        return correctTextEditingValueOffsets(newTEV((beforeInsertion + insertion + afterInsertion), newBaseOffset, newExtentOffset));
      }
      else return newValue; //one separator
    }
    else return newValue; //no separator
  }
  else return newValue; //we didn't add characters so we could not have had any more separators than we needed
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