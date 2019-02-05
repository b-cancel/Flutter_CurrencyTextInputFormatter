import 'package:flutter/services.dart';

/// LEARNED: dart can fail silently
///   1. run subtring with an index that points to characters that a string doesn't cover
///   2. try to += to a string set to null
///   3. double.parse parsing just a period

/// NOTE: I found some FLUTTER BUGS (while using android) that made this asset a pain to make
/// 1. I can select the text in the input field but I can't move the start tick, ONLY the end tick
///   - occurs even without input formatter
///   - BECAUSE of the above I wasn't able to fully test my solution although I did program it so that i should work in all cases
/// 2. its possible for baseOffset AND OR extentOffset to be less than 0... which makes no sense
///   - I adjusted the values to avoid this
/// 3. sometimes our oldValue on the TextInputFormatter does NOT reflect what is in the text field (it runs twice, updates visually with the 1st and in code with the 2nd)
///   REPLICATE BY:
///   a. type 10 numbers in the box
///   b. place a separator between all the numbers
///   c. note how the numbers are properly truncated
///   d. note how any print statement of oldValue and newValue shows up if placed inside of formatEditUpdate

/// FRAMEWORK NOTES:
/// baseOffset holds the position where the selection begins
/// extentOffset holds the position where the selection ends
/// its possible for extentOffset to be <= than baseOffset
///   - I adjusted the values to avoid this
/// str.codeUnitAt(i) if i is 0 through 9 the codes are 48 through 57

/// CURRENCY FORMAT ASSUMPTIONS:
/// 1. on the left of the SEPARATOR you have your whole number
/// 2. on the right of the SEPARATOR you have your fractions of a particular precision
/// 3. the SEPARATOR separates these both
/// 4. the number is read from left to right

/// OTHER ASSUMPTIONS:
/// 1. we only have a backspace key and not a delete key
/// 2. you want to keep the separator that was typed first... so if you paste multiple separators you keep the one that is furthest to the left
/// 3. the mask if enable will push the cursor to the right if it ever has to choose between right and left

/// NOTE: voice typing has not been tested

//TODO... plan for all these currency codes https://en.wikipedia.org/wiki/ISO_4217

class CurrencyTextInputFormatter extends TextInputFormatter {

  void Function(double) runAfterComplete;
  int precision;
  String separator;
  bool maskWithSpacers;
  String spacer;

  //USD format is default
  CurrencyTextInputFormatter(Function runAfterComplete, {int precision: 2, String separator: '.', bool maskWithSpacers: false, String spacer: ','}) {
    this.runAfterComplete = runAfterComplete;
    this.precision = precision;
    this.separator = separator;
    this.maskWithSpacers = maskWithSpacers;
    this.spacer = spacer;
  }

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

    print("editing*************************" + oldValue.text + " => " + newValue.text);

    if(newValue.text != oldValue.text){ /// NOTE this also includes changes to just our mask (by removing or replacing a spacer)

      //save all the variables we need to use to determine how to proceed
      oldValue = correctTextEditingValueOffsets(oldValue);
      String oldText = oldValue.text;
      int oldBaseOffset = oldValue.selection.baseOffset;
      int oldExtentOffset = oldValue.selection.extentOffset;

      newValue = correctTextEditingValueOffsets(newValue);
      String newText = newValue.text;
      int newBaseOffset = newValue.selection.baseOffset;
      int newExtentOffset = newValue.selection.extentOffset;

      //handle masking (assumes that if this is off the string doesn't have a mask)
      if(maskWithSpacers){
        oldValue = removeSpacers(oldText, oldBaseOffset, oldExtentOffset, spacer);
        newValue = removeSpacers(newText, newBaseOffset, newExtentOffset, spacer);
      }

      /// -------------------------MAIN ERROR CORRECTION BELOW-------------------------

      //an optimization we can make if we notice that we are ONLY removing characters
      if(addedCharacterCount(oldText, newText, oldBaseOffset, oldExtentOffset) > 0){
        print("WE MUST HAVE ADDED AND MAYBE REMOVED CHARACTERS");
        print("*************************" + oldValue.text + " => " + newValue.text);

        //-----Operate on OLD string AND new string (characters that where part of the mask, and newly added characters)

        //TODO... inserting a period between alot of numbers makes the cursor go behind where it should (only when truncation is required)
        //TODO... inserting a character after that period does the same (only when truncation is required)

        print("0: " + newText + " selection from " + oldBaseOffset.toString() + " to " + oldExtentOffset.toString());
        // (0) remove everything except NUMBERS AND the SEPARATOR
        /// NOTE: this would also remove the mask if we were using it
        /// NOTE: we could use whitelisting but we used this since some bugs arose from using WhiteListing and another custom formatter and I was trying to avoid them
        var result = removeAllButNumbersAndSeparator(newText, separator, oldBaseOffset, oldExtentOffset);
        newText = result[0];
        oldBaseOffset = result[1];
        oldExtentOffset = result[2];

        //-----Operate ONLY on new string (newly added characters) [so oldBaseOffset is NOT shifted]

        print("1: " + newText + " selection from " + oldBaseOffset.toString() + " to " + oldExtentOffset.toString());
        // (1) make sure that we allow at most one SEPARATOR
        newText = removeAllButOneSeparator(newText, separator, oldBaseOffset, oldExtentOffset, addedCharacterCount(oldText, newText, oldBaseOffset, oldExtentOffset));
        print("2: " + newText + " selection from " + oldBaseOffset.toString() + " to " + oldExtentOffset.toString());
        // (2) TRUNCATE the amount needed dependant on the currency format
        newText = removeExtraValuesAfterSeparator(newText, precision, showSinglePeriod: true);
        oldBaseOffset = (oldBaseOffset < newText.length) ? oldBaseOffset : newText.length; //must not be larger than length
        print("3: " + newText + " selection from " + oldBaseOffset.toString() + " to " + oldExtentOffset.toString());
        // (3) Selection Correction
        /// NOTE: added character count may no longer be accurate
        oldBaseOffset = selectionCorrection(addedCharacterCount(oldText, newText, oldBaseOffset, oldExtentOffset), oldBaseOffset); //TODO... check
        print("4: " + newText + " selection from " + oldBaseOffset.toString() + " to " + oldExtentOffset.toString());
      }
      else{ //we only removed characters (so we could have issues with the mask, IF it exists)
        //-----Calculate how many characters we removed before we remove the mask
        /// NOTE: we know that the old and new string are different AND that we didn't add anything new
        /// So we KNOW that we must have at the very least removed something (it as well be the mask)
        int numberOfCharsRemoved =  oldText.length - newText.length;

        //-----Adjust the oldBaseOffset (again)
        // oldBaseOffset would have already been shifted if removing the mask would have affected it
        oldBaseOffset = oldBaseOffset - numberOfCharsRemoved;
      }

      /// -------------------------MAIN ERROR CORRECTION ABOVE-------------------------

      //run passed function that saves our currency as a double
      runAfterComplete(convertToDouble((newText)));

      //handle masking
      if(maskWithSpacers){
        //TODO... add our mask
        //TODO... make sure that when you add your mask your offsets don't mess up
      }

      print("-----RIGHT BEFORE RETURN " + newText + " cursor " + oldBaseOffset.toString());

      //return our processed string
      return correctNewTextEditingValueOffsets(newText, oldBaseOffset);
    }
    else return newValue; //nothing has changed and this ran when it should not have
    /// NOTE: the code above HAS to return newValue exactly otherwise we will indefinitely correct our value
  }
}

//---------------MAIN helpers

List removeAllButNumbersAndSeparator(String str, String separator, int oldBaseOffset, int oldExtentOffset){
  //-0----1----2----3----4
  //---i0---i1---i2---i3--- (a79a8) //3-4, delete 3

  //NOTE: we deleted back to front so we don't have to constantly adjust the index on deletion
  for(int i = str.length - 1; i >= 0; i--) {
    if (((48 <= str.codeUnitAt(i) && str.codeUnitAt(i) <= 57) || str[i] == separator) == false){
      //---remove whatever is at i
      str = removeCharAtIndex(str, i);

      //---adjust the offset accordingly
      if(i < oldBaseOffset) oldBaseOffset--;
      if(i < oldExtentOffset) oldExtentOffset--;
    }
  }

  //return the modified string along with the modified offsets
  return [
    str,
    (oldBaseOffset < 0) ? 0 : oldBaseOffset,
    (oldExtentOffset > str.length) ? str.length : oldExtentOffset
  ];
}

String removeAllButOneSeparator(String str, String separator, int baseOffset, int extentOffset, int addedCharCount){
  int firstIndexOfSeparator = str.indexOf(separator);
  if(firstIndexOfSeparator != -1){ //at least 1 separator exists
    if(firstIndexOfSeparator != str.lastIndexOf(separator)) { //at least 2 separators exist
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
      String beforeInsertion = (0 == baseOffset) ? "" : str.substring(0, baseOffset);
      int lastAdditionIndex = baseOffset + addedCharCount;
      /// NOTE: this may seem like it requires (lastAdditionIndex + 1) but it doesn't
      String insertion = str.substring(baseOffset, lastAdditionIndex); //NOTE: this will NEVER be empty
      String afterInsertion = ((lastAdditionIndex) == str.length) ? "" : str.substring(lastAdditionIndex, str.length);

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
    else return str;
  }
  else return str;
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

//---------------MASK helpers

/// NOTE: we might be able to easily merge this with "maskWithSpacers", the differences are marked
/// NOTE: assumes the string has AT MOST one separator
/// WARNING: UNTESTED
List getMaskWithSpacersAndCursorIndex(String str, String separator, String spacer, int index){  //-----DIFFERENT
  bool passedSeparator = (str.contains(separator)) ? false : true;
  int numbersPassed = 0;

  //read the string from right to left to find the separator and then start adding spacer
  for(int i = str.length - 1; i >= 0; i--){
    if(passedSeparator == false){
      if(str[i] == separator) passedSeparator = true;
    }
    else{
      if(numbersPassed == 3){ //we are the 4th number and can insert a spacer to our right
        int spacerIndex = i + 1;

        //-----DIFFERENCES START (different then maskWithSpacers)
        print("spacer index:  " + spacerIndex.toString() + " vs " + index.toString());

        /// NOTE: we are CHOOSING to place the cursor to the right of the spacer
        if(spacerIndex == index){
          print("equal");
          index++;
        }
        else if(spacerIndex < index){
          print("less");
          index++;
        }
        else print("above");
        /// ELSE... it doesn't affect anything
        //-----DIFFERENCES END

        str = str.substring(0, spacerIndex) + spacer + str.substring(spacerIndex, str.length); //add a spacer to our right
        numbersPassed = 1;
      }
      else numbersPassed++;
    }
  }

  return [str, index]; //-----DIFFERENT
}

/// NOTE: assumes the string has AT MOST one separator
String addSpacers(String str, String separator, String spacer){
  bool passedSeparator = (str.contains(separator)) ? false : true;
  int numbersPassed = 0;

  //read the string from right to left to find the separator and then start adding spacer
  for(int i = str.length - 1; i >= 0; i--){
    if(passedSeparator == false){
      if(str[i] == separator) passedSeparator = true;
    }
    else{
      if(numbersPassed == 3){ //we are the 4th number and can insert a spacer to our right
        int spacerIndex = i + 1;
        str = str.substring(0, spacerIndex) + spacer + str.substring(spacerIndex, str.length); //add a spacer to our right
        numbersPassed = 1;
      }
      else numbersPassed++;
    }
  }

  return str;
}

/// NOTE: assumes the string has AT MOST one separator
double convertToDouble(String str){
  String strWithPeriodSeparator = "";
  for(int i=0; i<str.length; i++){
    if(48 <= str.codeUnitAt(i) && str.codeUnitAt(i) <= 57) strWithPeriodSeparator = strWithPeriodSeparator + str[i];
    else strWithPeriodSeparator = strWithPeriodSeparator + "."; //replace the separator for a period for easy parsing as a double
  }
  return (strWithPeriodSeparator == '.') ? 0 : double.parse(strWithPeriodSeparator);
}

/// -------------------------EVERYTHING BELOW HAS BEEN CHECKED-------------------------

/// NOTE: we want to modify the offsets to show up in the locations they would if the mask was removed
TextEditingValue removeSpacers(String value, int baseOffset, int extentOffset, String spacer){
  for(int index = value.length -1; index >= 0; index--){
    if(value[index] == spacer){
      //remove the character
      value = removeCharAtIndex(value, index);

      //shift the offset the left
      if(index < baseOffset) baseOffset--;
      if(index < extentOffset) extentOffset--;
    }
  }

  return correctTextEditingValueOffsets(
      TextEditingValue(
        text: value,
        selection: TextSelection(baseOffset: baseOffset, extentOffset: extentOffset),
      )
  );
}

//---------------OFFSET helpers

TextEditingValue correctNewTextEditingValueOffsets(String text, int offset){
  return correctTextEditingValueOffsets(
      TextEditingValue(
        text: text,
        /// NOTE: I'm using this instead of "TextSelection.collapsed()" because at the time of this writing it was causing issues for some reason
        selection: TextSelection(baseOffset: offset, extentOffset: offset),
        /// We don't worry about composing because in no instance is it necessary to select anything for the user
        /// if the user deletes by the delete key they are not expecting anything to be selected regardless of how many characters they had selected or where
        /// else the user adds something by either typing or pasting the user expects the cursor to be at the end of whatever they added
      )
  );
}

/// NOTE: this correct TextEditingValues in a way that I would expect them to do so automatically (but don't)
TextEditingValue correctTextEditingValueOffsets(TextEditingValue value){
  String text = value.text;
  int baseOffset = lockOffsetsWithinRange(text, value.selection.baseOffset);
  int extentOffset = lockOffsetsWithinRange(text, value.selection.extentOffset);
  var correctOffsets = correctOverlappingOffsets(baseOffset, extentOffset);
  return TextEditingValue(
    text: text,
    selection: TextSelection(baseOffset: correctOffsets[0], extentOffset: correctOffsets[1]),
  );
}

int lockOffsetsWithinRange(String str, int offset){
  offset = (offset < 0) ? 0 : offset;
  offset = (str.length < offset) ? str.length : offset;
  return offset;
}

List correctOverlappingOffsets(int baseOffset, int extentOffset){
  if(extentOffset < baseOffset){ //we WANT oldBaseOffset to always be <= oldExtentOffset
    var temp = baseOffset;
    baseOffset = extentOffset;
    extentOffset = temp;
  }
  return [baseOffset, extentOffset];
}

//---------------SIDE helpers

String removeCharAtIndex(String str, int index){
  return str.substring(0, index) + str.substring(index + 1);
}

int addedCharacterCount(String oldValue, String newValue, int oldBaseOffset, int oldExtentOffset){
  //PROCESS
  //newCharCount = oldCharCount - numberOfCharsWeRemoved + numberOfCharsWeAddedThatPassed
  //(newCharCount - oldCharCount) + numberOfCharsWeRemoved = numberOfCharsWeAddedThatPassed
  int countDifference = newValue.length - oldValue.length;
  int numberOfCharsWeRemoved = oldExtentOffset - oldBaseOffset; /// NOTE: this only includes the characters removed by selection
  if(numberOfCharsWeRemoved == 0){ //we didn't remove characters by selection
    //so we either removed a SINGLE character by deletion => string shortens by 1
    //OR added characters => string grows by X (the var would be 0 if we added NOT from a selection)
    numberOfCharsWeRemoved = (newValue.length < oldValue.length) ? 1 : 0;
  }
  return countDifference + numberOfCharsWeRemoved;
}

/// NOTE: assumes the string has AT MOST one separator
String ensureValuesAfterSeparator(String str, String separator, int precision, {bool removeLoneSeparator: true}){
  //grab the index of the separator
  int separatorIndex = str.indexOf(separator);

  //process the string
  if(precision <= 0){
    if(precision < 0){
      if(separatorIndex != -1){
        //remove all the values before the separator
        for(int i = str.length - 1; i >= 0; i--){
          if(str[i] == separator) break; //get out of the loop if needed
          else str = removeCharAtIndex(str, i); //remove the characters at the right of the separator
        }

        //remove the lone separator if desired
        if(removeLoneSeparator) str = removeCharAtIndex(str, separatorIndex);
      }
      /// ELSE... there is numbers to the right of the separator to remove
    }

    /// NOTE: by now the case that occurs when your precision is equal to 0 has been handled

    if(precision == 0) return str;
    else{ /// NOTE: precision is NEGATIVE
      separatorIndex = str.indexOf(separator);

      //if the precision is lower than 0 then you MUST remove the separator
      if(separatorIndex != -1) str = removeCharAtIndex(str, separatorIndex);

      //remove stuff from the back (make sure you don't remove more than the entire string)
      precision = precision * -1; //turn the number positive
      precision = (precision < str.length) ? precision : str.length;
      for(int i = str.length - 1; precision > 0; i--, precision--){
        str = removeCharAtIndex(str, i);
      }

      return str;
    }
  }
  else{ /// NOTE: precision is POSITIVE
    //add the separator if you don't already have it
    if(separatorIndex == -1){
      str = str + separator;
      separatorIndex = str.indexOf(separator);
    }

    //add whatever the quantity of characters that you need to to meet the precision requirement
    int desiredLastIndex = separatorIndex + precision;
    int additionsNeeded = desiredLastIndex - (str.length - 1);
    for(int i = additionsNeeded; i > 0; i--) str = str + '0';

    return str;
  }
}