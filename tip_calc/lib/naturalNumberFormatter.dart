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
/// 1. the SPACER that might be chosen to place every 3 numbers from the SEPARATOR is just ONE character
/// 2. the number is read from left to right

/// OTHER ASSUMPTIONS:
/// 1. we only have a backspace key and not a delete key
/// 2. the mask if enabled will push the cursor to the right if it ever has to choose between right and left
/// 3. We ony need to report the new int value IF it doesn't match our previous one

/// NOTE:
/// 1. voice typing has not been tested
/// 2. because there are so many different steps and its all string parsing which tend to have tons of edge cases
///   - I created a [debugMode] variable that can be turned to true to see exactly how the string is bring processed and find the potential bug
///   - this exists just in case but I thoroughly tested the code
/// 3. I didn't try to enforce any minimum values because this doesn't make sense since the field will start off initially as empty
///   - although I do have an "ensureMinDigitsAfterSeparatorString" function to beautify formatting after editing is complete
///     - this ONLY truncates, feel free to implement rounding up or down or using the rules of significant figures

class NaturalNumberFormatter extends TextInputFormatter {

  bool debugMode = true;

  /// --------------------------------------------------VARIABLE PREPARATION--------------------------------------------------

  void Function(int) runAfterComplete;

  /// NOTE: we assume you only want spacer between the digits on the left side
  /// EX: assuming (a) separator = '.' (b) spacer = ','
  /// 12,324,000.002412 => result
  /// 12,324,000.000,241,2 => not result
  /// 12,324,000.0,002,412 => not result
  bool addMaskWithSpacers;
  String spacer; /// NOTE: this should just be ONE character

  bool allowLeading0s;

  bool enforceMaxDigits;
  int maxDigits; /// NOTE: this should be >= 0

  //USD format is default
  NaturalNumberFormatter(
      Function runAfterComplete,
    {
      bool addMaskWithSpacers: true,
      String spacer: ',',

      bool allowLeading0s: false,

      bool enforceMaxDigits: true,
      int maxDigits: 7,
    }) {
    this.runAfterComplete = runAfterComplete;

    this.addMaskWithSpacers = addMaskWithSpacers;
    this.spacer = spacer;

    this.allowLeading0s = allowLeading0s;

    this.enforceMaxDigits = true;
    this.maxDigits = 7;
  }

  /// --------------------------------------------------MAIN FUNCTION--------------------------------------------------

  // NOTE: this runs when the field data changes when either (1) you type on keyboard OR (2) you paste text from the clipboard
  // So. We need to plan for both scenarios to avoid bugs
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {

    //correct strange offsets
    oldValue = correctTextEditingValueOffsets(oldValue);
    newValue = correctTextEditingValueOffsets(newValue);

    //remove masking
    if(addMaskWithSpacers){ //NOTE: its important that both of these are masked so that we can get an accurate character count
      oldValue = removeSpacers(oldValue, spacer);
      newValue = removeSpacers(newValue, spacer);

      printDebug("AFTER MASK REMOVAL", oldValue, newValue, debugMode);
    }

    //remove anything dumb
    newValue = removeAllButNumbersAndTheSeparator(newValue, '');

    printDebug("AFTER EVERYTHING EXCEPT NUMBER REMOVAL", oldValue, newValue, debugMode);

    //remove leading 0s
    if(allowLeading0s == false){
      newValue = removeLeading0s(newValue);

      printDebug("AFTER REMOVE LEADING 0s", oldValue, newValue, debugMode);
    }

    //ensure limits before decimal
    if(enforceMaxDigits){
      newValue = ensureMaxDigitsBeforeSeparator(newValue, '', maxDigits);

      printDebug("AFTER ENSURE DIGITS BEFORE DECIMAL", oldValue, newValue, debugMode);
    }

    /// --------------------------------------------------ALL FILTERS APPLIED

    //run passed function that saves our currency as a double
    int oldInt = convertToInt(oldValue.text);
    int newInt = convertToInt(newValue.text);
    if(oldInt != newInt) runAfterComplete(newInt);

    printDebug("AFTER VALUE REPORTING", oldValue, newValue, debugMode);

    /// --------------------------------------------------ALL MASKS NOW WILL BE APPLIED

    //handle masking
    if(addMaskWithSpacers){
      if(debugMode) oldValue = addSpacers(oldValue, '', spacer); //note: this is only for debugging
      newValue = addSpacers(newValue, '', spacer);

      printDebug("FINAL: AFTER MASK ADDITION", oldValue, newValue, debugMode);
    }

    //final correction before returning
    return correctSingleTextEditingValueOffset(newValue.text, newValue.selection.baseOffset);
  }
}