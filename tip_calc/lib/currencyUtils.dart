import 'package:flutter/services.dart';

/// FUTURE PLANS
/// TODO... only if RIGHT to LEFT number systems are a thing
/// TODO... removeTrailing0sString
/// TODO... removeTrailing0s
/// TODO... addLeading0sString
/// TODO... addLeading0s
/// ---
/// TODO... addTrailing0s

/// --------------------------------------------------SPECIFIC TO LEFT TO RIGHT NUMBER SYSTEMS

String removeLeading0sString(String text){
  return removeLeading0s(new TextEditingValue(text: text)).text;
}

TextEditingValue removeLeading0s(TextEditingValue value){ //TODO... final testing
  if(value.text.length == 0) return value;
  else{
    //prepare variables
    String text = value.text;
    int baseOffset = value.selection.baseOffset;
    int extentOffset = value.selection.extentOffset;

    //remove all leading 0s
    while(text.length != 0 && text[0] == '0'){
      //remove the zero
      text = removeCharAtIndex(text, 0);

      //adjust the cursor properly
      if(0 < baseOffset) baseOffset--; //shift left
      if(0 < extentOffset) extentOffset--; //shift left
    }

    return correctTextEditingValueOffsets(newTEV(text, baseOffset, extentOffset));
  }
}

/// NOTE: assumes the string has AT MOST one separator
String addTrailing0sString(String str, String separator, int minDigitsAfterDecimal, {bool removeLoneSeparator: true}){ //TODO... final testing
  if(minDigitsAfterDecimal < 0) return str; //there is no such thing, If I could use an unsigned int here I would
  else{
    //grab the index of the separator
    int separatorIndex = str.indexOf(separator);

    if(minDigitsAfterDecimal == 0){
      if(separatorIndex == -1) return str;
      else return str.substring(0, separatorIndex + ((removeLoneSeparator) ? 0 : 1));
    }
    else{
      //add the separator if you don't already have it
      if(separatorIndex == -1){
        str = str + separator;
        separatorIndex = str.indexOf(separator);
      }

      //add whatever the quantity of characters that you need to to meet the precision requirement
      int desiredLastIndex = separatorIndex + minDigitsAfterDecimal;
      int additionsNeeded = desiredLastIndex - (str.length - 1);
      for(int i = additionsNeeded; i > 0; i--) str = str + '0';

      //return the string with the new number of 0s at the end
      return str;
    }
  }
}

/// --------------------------------------------------ERROR CORRECTING FUNCTIONS--------------------------------------------------

String removeAllButNumbersAndTheSeparatorString(String text, String separator){
  return removeAllButNumbersAndTheSeparator(new TextEditingValue(text: text), separator).text;
}

TextEditingValue removeAllButNumbersAndTheSeparator(TextEditingValue value, String separator){
  //prepare variables
  String text = value.text;
  int baseOffset = value.selection.baseOffset;
  int extentOffset = value.selection.extentOffset;

  if(text.length == 0) return value;
  else{
    //NOTE: we deleted back to front so we don't have to constantly adjust the index on deletion
    for(int index = text.length - 1; index >= 0; index--) {
      if (((48 <= text.codeUnitAt(index) && text.codeUnitAt(index) <= 57) || text[index] == separator) == false){
        //---remove whatever is at i
        text = removeCharAtIndex(text, index);

        //---adjust the offset accordingly
        if(index < baseOffset) baseOffset--;
        if(index < extentOffset) extentOffset--;
      }
    }

    //return the corrected values
    return correctTextEditingValueOffsets(newTEV(text, baseOffset, extentOffset));
  }
}

/// --------------------------------------------------GOOD STRING TO DOUBLE PARSER--------------------------------------------------

/// Handles
/// 1. empty strings
///
/// Already Handled
/// 1. string with leading 0s
int convertToInt(String str){
  if(str == "") return 0;
  else return int.parse(str);
}

/// Handles
/// 1. strings with ANY separator (not just a decimal)
/// 2. empty strings
/// 2. strings with just a separator
/// 4. string with more than 1 separator
///
/// Already Handled
/// 1. string with leading 0s
///
/// NOTE: assumes that anything that isn't a number is a separator
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

/// --------------------------------------------------PREFERENCE LIMIT FUNCTIONS--------------------------------------------------
/// NOTE: all of these expect a string that CAN BE parsable as a double (they MIGHT have leading 0s)
/// which also means they assume the string has AT MOST one separator

String ensureMaxDigitsBeforeSeparatorString(String text, String separator, int maxDigitsBeforeDecimal){
  return ensureMaxDigitsBeforeSeparator(new TextEditingValue(text: text), separator, maxDigitsBeforeDecimal).text;
}

TextEditingValue ensureMaxDigitsBeforeSeparator(TextEditingValue value, String separator, int maxDigitsBeforeSeparator){
  return ensureMaxDigits(value, separator, maxDigitsBeforeSeparator, removeBeforeSeparator: true);
}

String ensureMaxDigitsAfterSeparatorString(String text, String separator, int maxDigitsAfterDecimal){
  return ensureMaxDigitsAfterSeparator(new TextEditingValue(text: text), separator, maxDigitsAfterDecimal).text;
}

TextEditingValue ensureMaxDigitsAfterSeparator(TextEditingValue value, String separator, int maxDigitsAfterSeparator){
  return ensureMaxDigits(value, separator, maxDigitsAfterSeparator, removeBeforeSeparator: false);
}

String ensureMaxDigitsString(String text, String separator, int maxDigits, {bool removeBeforeSeparator}){
  return ensureMaxDigits(new TextEditingValue(text: text), separator, maxDigits, removeBeforeSeparator: removeBeforeSeparator).text;
}

TextEditingValue ensureMaxDigits(TextEditingValue value, String separator, int maxDigits, {bool removeBeforeSeparator}){ //TODO... final testing
  //prepare out variables
  String text = value.text;
  int baseOffset = value.selection.baseOffset;
  int extentOffset = value.selection.extentOffset;

  //grab the string that we care about
  String stringSectionWeCareAbout;
  int separatorIndex = text.indexOf(separator);
  if(separatorIndex == -1) stringSectionWeCareAbout =  (removeBeforeSeparator) ? text : "";
  else{
    if(removeBeforeSeparator) stringSectionWeCareAbout = text.substring(0, separatorIndex); //doesn't include separator
    else{
      int afterSeparatorIndex = separatorIndex + 1;
      stringSectionWeCareAbout = (afterSeparatorIndex < text.length) ? text.substring(afterSeparatorIndex, text.length) : "";
    }
  }

  //operate on strings
  int removalsRequired = stringSectionWeCareAbout.length - maxDigits;
  if(removalsRequired > 0){
    //remove the undesired values
    while(removalsRequired > 0){
      //remove the char from the right place
      int indexToRemove = (removeBeforeSeparator) ? 0 : text.length - 1; //remove from the front or the back
      text = removeCharAtIndex(text, indexToRemove);

      //adjust the cursor properly
      if(indexToRemove < baseOffset) baseOffset--; //shift left
      if(indexToRemove < extentOffset) extentOffset--; //shift left

      //inform changes
      removalsRequired--;
    }

    //return the corrected values
    return correctTextEditingValueOffsets(newTEV(text, baseOffset, extentOffset));
  }
  else return value;
}

/// --------------------------------------------------TAG FUNCTIONS--------------------------------------------------

String addRightTagString(String text, String rightTag){
  return addRightTag(new TextEditingValue(text: text), rightTag).text;
}

TextEditingValue addRightTag(TextEditingValue value, String rightTag){
  return addTag(value, rightTag, tagOnLeft: false);
}

String addLeftTagString(String text, String leftTag){
  return addLeftTag(new TextEditingValue(text: text), leftTag).text;
}

TextEditingValue addLeftTag(TextEditingValue value, String leftTag){
  return addTag(value, leftTag, tagOnLeft: true);
}

String addTagString(String text, String tag, {bool tagOnLeft}){
  return addTag(new TextEditingValue(text: text), tag, tagOnLeft: tagOnLeft).text;
}

/// ASSUMES that we already know the user wants an identifier
TextEditingValue addTag(TextEditingValue value, String tag, {bool tagOnLeft}){ //TODO... final testing
  if(tag == '') return value;
  else{
    //prepare variables
    String text = value.text;
    int baseOffset = value.selection.baseOffset;
    int extentOffset = value.selection.extentOffset;

    //add identifier on the correct side
    if(tagOnLeft){
      text = tag + text;
      //shift both offsets to the right by the length of the currency identifier
      baseOffset += tag.length;
      extentOffset += tag.length;
    }
    else text = text + tag; //requires no shift of cursors

    //return the corrected values
    return correctTextEditingValueOffsets(newTEV(text, baseOffset, extentOffset));
  }
}

String removeRightTagString(String text, String rightTag){
  return removeRightTag(new TextEditingValue(text: text), rightTag).text;
}

TextEditingValue removeRightTag(TextEditingValue value, String rightTag){
  return removeTag(value, rightTag, tagOnLeft: false);
}

String removeLeftTagString(String text, String leftTag){
  return removeLeftTag(new TextEditingValue(text: text), leftTag).text;
}

TextEditingValue removeLeftTag(TextEditingValue value, String leftTag){
  return removeTag(value, leftTag, tagOnLeft: true);
}

String removeTagString(String text, String tag, {bool tagOnLeft}){
  return removeTag(new TextEditingValue(text: text), tag, tagOnLeft: tagOnLeft).text;
}

TextEditingValue removeTag(TextEditingValue value, String tag, {bool tagOnLeft}){ //TODO... final testing
  if(tag == '' || tag == null) return value;
  else{ /// NOTE: although they shouldn't the user might try to mess with the identifier so we have to plan for that
    if(value.text.contains(tag) == false) return value;
    else{
      if(value.text.length == 0) return value;
      else{
        //prepare variables
        String text = value.text;
        int baseOffset = value.selection.baseOffset;
        int extentOffset = value.selection.extentOffset;

        //remove the currency identifier as desired
        int lastIndexToRemove = text.indexOf(tag); //last since we are reading the string from right to left
        int firstIndexToRemove = lastIndexToRemove + tag.length - 1; //we are guaranteed this is not out of bounds

        /// NOTE: we only remove the identifier from where it should be (otherwise it will be considered a user error and removed elsewhere)
        bool identifierOnLeft = (tagOnLeft == true) && (lastIndexToRemove == 0);
        bool identifierOnRight = (tagOnLeft == false) && (firstIndexToRemove == text.length - 1);
        if(identifierOnLeft || identifierOnRight){
          for(int index = text.length - 1; index >= 0; index--) {
            if(lastIndexToRemove <= index && index <= firstIndexToRemove){
              text = removeCharAtIndex(text, index);

              //shift the offset the left
              if(index < baseOffset) baseOffset--;
              if(index < extentOffset) extentOffset--;
            }
          }

          //return the corrected values
          return correctTextEditingValueOffsets(newTEV(text, baseOffset, extentOffset));
        }
        else return value;
      }
    }
  }
}

/// --------------------------------------------------CURRENCY MASK FUNCTIONS--------------------------------------------------

/// NOTE: assume the string has AT MOST one separator
String addSpacersString(String value, String separator, String spacer){
  return addSpacers(TextEditingValue(text: value), separator, spacer).text;
}

/// NOTE: assumes the string has AT MOST one separator
TextEditingValue addSpacers(TextEditingValue value, String separator, String spacer, {bool cursorToRightOfSpacer: true}){ //TODO... final testing
  if(value.text.length == 0) return value;
  else{
    //create references to our variables
    String text = value.text;
    int baseOffset = value.selection.baseOffset;
    int extentOffset = value.selection.extentOffset;

    //prepare some variables before the main loop
    bool passedSeparator = (text.contains(separator)) ? false : true;
    passedSeparator = (separator == '') ? true : false; //because it doesn't exist
    int numbersPassed = 0;

    //define the function we will be using within the loop
    int shiftCursor(int spacerIndex, int cursorIndex, bool cursorToRightOfSpacer){
      if(spacerIndex == cursorIndex){
        if(cursorToRightOfSpacer) return (cursorIndex + 1);
        else return cursorIndex;
      }
      else if(spacerIndex < cursorIndex) return (cursorIndex + 1);
      else return cursorIndex; /// the string shifts past the point where the cursor is
    }

    //read the string from right to left to find the separator and then start adding spacer
    for(int i = text.length - 1; i >= 0; i--){
      if(passedSeparator == false){
        if(text[i] == separator) passedSeparator = true;
      }
      else{
        if(numbersPassed == 3){ //we are the 4th number and can insert a spacer to our right
          int spacerIndex = i + 1;

          //shift the cursor as needed (shift baseOffset and extentOffset separately)
          baseOffset = shiftCursor(spacerIndex, baseOffset, cursorToRightOfSpacer);
          extentOffset = shiftCursor(spacerIndex, extentOffset, cursorToRightOfSpacer);

          text = text.substring(0, spacerIndex) + spacer + text.substring(spacerIndex, text.length); //add a spacer to our right
          numbersPassed = 1; //we have passed ourselves
        }
        else numbersPassed++;
      }
    }

    //return the corrected values
    return correctTextEditingValueOffsets(newTEV(text, baseOffset, extentOffset));
  }
}

String removeSpacerString(String text, String spacer){
  return removeSpacers(new TextEditingValue(text: text), spacer).text;
}

TextEditingValue removeSpacers(TextEditingValue value, String spacer){ //TODO... final testing
  if(value.text.length == 0) return value;
  else{
    //prepare variables
    String text = value.text;
    int baseOffset = value.selection.baseOffset;
    int extentOffset = value.selection.extentOffset;

    //remove all the spacers and shift the offset accordingly
    for(int index = text.length - 1; index >= 0; index--){
      if(text[index] == spacer){
        //remove the character
        text = removeCharAtIndex(text, index);

        //shift the offset the left
        if(index < baseOffset) baseOffset--;
        if(index < extentOffset) extentOffset--;
      }
    }

    //return the string without spacers
    return correctTextEditingValueOffsets(newTEV(text, baseOffset, extentOffset));
  }
}

/// --------------------------------------------------OFFSET FUNCTIONS--------------------------------------------------

TextEditingValue correctSingleTextEditingValueOffset(String text, int offset){
  return correctTextEditingValueOffsets(
      TextEditingValue(
        text: text,
        /// NOTE: I might also be able to use "TextSelection.collapsed()"
        selection: TextSelection(baseOffset: offset, extentOffset: offset),
        /// We don't worry about composing because in no instance is it necessary to select anything for the user
        /// if the user deletes by the delete key they are not expecting anything to be selected regardless of how many characters they had selected or where
        /// else the user adds something by either typing or pasting the user expects the cursor to be at the end of whatever they added
      )
  );
}

/// NOTE: this correct TextEditingValues in a way that I would expect them to do so automatically (but don't)
TextEditingValue correctTextEditingValueOffsets(TextEditingValue value){
  //---define our helper functions
  int lockOffsetWithinRange(String str, int offset){
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

  //---run the correction
  String text = value.text;
  int baseOffset = lockOffsetWithinRange(text, value.selection.baseOffset);
  int extentOffset = lockOffsetWithinRange(text, value.selection.extentOffset);
  var correctOffsets = correctOverlappingOffsets(baseOffset, extentOffset);
  return newTEV(text, correctOffsets[0], correctOffsets[1]);
}

TextEditingValue newTEV(String text, int baseOffset, int extentOffset){
  return TextEditingValue(
    text: text,
    selection: TextSelection(baseOffset: baseOffset, extentOffset: extentOffset),
  );
}

/// --------------------------------------------------OTHER FUNCTIONS--------------------------------------------------

String removeCharAtIndex(String str, int index){
  //tertiary op used for exception where there is no first half
  String firstHalf = (0 == index) ? "" : str.substring(0, index);
  return firstHalf + str.substring(index + 1);
}

/// --------------------------------------------------DEBUG MODE--------------------------------------------------

void printDebug(String description, TextEditingValue oldValue, TextEditingValue newValue, debugMode){
  if(debugMode){
    print(description + "*************************" + oldValue.text
        + " [" + oldValue.selection.baseOffset.toString() + "->" + oldValue.selection.extentOffset.toString() + "]"
        + " => " + newValue.text
        + " [" + newValue.selection.baseOffset.toString() + "->" + newValue.selection.extentOffset.toString() + "]"
    );
  }
}