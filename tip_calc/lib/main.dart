import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tip_calc/currencyFormatter.dart';

//TODO... show a message if
// (1) the user placed anything except numbers, and the decimal
// (2) the text has 2 decimals or more
//TODO... we should always show money amounts with at least 2 values after the decimal

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tip Calculator',
      home: MyHomePage(title: 'Tip Calculator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  /// --------------------------------------------------VARIABLE PREPARATION--------------------------------------------------

  bool debugMode = true;

  double tipSliderValue = 10.0;

  TextEditingController totalController = new TextEditingController();
  TextEditingController billController = new TextEditingController();
  TextEditingController tipController = new TextEditingController();

  Color gradientLight = const Color.fromARGB(255, 255, 203, 174);
  Color gradientDark = const Color.fromARGB(255, 255, 128, 148); //const Color.fromARGB(255, 205, 139, 149);
  Color textGrey = const Color.fromARGB(255, 205, 205, 205);
  static Color textPeach = const Color.fromARGB(255, 255, 147, 160);

  TextStyle textMediumPeach = TextStyle(
    color: textPeach,
    fontWeight: FontWeight.bold,
    fontSize: 24.0,
  );

  TextStyle textLargePeach = new TextStyle(
    color: textPeach,
    fontWeight: FontWeight.bold,
    fontSize: 48.0,
  );

  String totalString;
  String billString;
  String tipPercentString;

  //TODO... we should be able to set starter values for all of these (make sure to handle exceptions)
  double totalAmount = 0;
  double billAmount = 0;
  double tipPercent = 0; //1% is 1.0

  /// --------------------------------------------------MAIN LOGIC FUNCTIONS--------------------------------------------------

  void updateTotal(double totalAmount){
    //update programmatically (bill gets no update)
    this.totalAmount = totalAmount; //REQUIRED
    double tipAmount = totalAmount - billAmount;
    if(billAmount == 0) tipPercent = 0;
    else tipPercent = (tipAmount / billAmount) * 100;

    //update variables
    updateStrings();

    //actually trigger changes in the form
    tipController.text = tipPercentString;
    if(debugMode) print("UPDATING TOTAL--------------------------------------------------------------------------- " + billString + " + " + tipPercentString + "% = " + totalString);
  }

  void updateBill(double billAmount){

    //update programmatically (percent gets no update)
    this.billAmount = billAmount; //REQUIRED
    double tipAmount = billAmount * tipPercent * .01;
    this.totalAmount = billAmount + tipAmount;

    //update variables
    updateStrings();

    //actually trigger changes in the form
    totalController.text = totalString;
    if(debugMode) print("UPDATING BILL--------------------------------------------------------------------------- " + billString + " + " + tipPercentString + "% = " + totalString);
  }

  void updateTipPercent(double tipPercent){
    //update programmatically (bill gets no update)
    this.tipPercent = tipPercent; //REQUIRED
    double tipAmount = billAmount * tipPercent * .01;
    this.totalAmount = billAmount + tipAmount;

    //update variables
    updateStrings();

    //actually trigger changes in the form
    totalController.text = totalString;
    if(debugMode) print("UPDATING TIP PERCENT--------------------------------------------------------------------------- " + billString + " + " + tipPercentString + "% = " + totalString);
  }

  /// --------------------------------------------------HELPER FUNCTIONS--------------------------------------------------

  /// NOTE: this doesn't update things visually
  void updateStrings(){
    billString = stringDecoration(billAmount, currencyIdentifier: '\$');
    tipPercentString = stringDecoration(tipPercent, currencyIdentifier: '%', currencyIdentifierOnLeft: false);
    totalString = stringDecoration(totalAmount, currencyIdentifier: '\$');
  }

  String stringDecoration(double number, {String currencyIdentifier: '', bool currencyIdentifierOnLeft: true}){
    String numString = addCurrencyMask(number.toString(), '.', ','); //NOTE: I choose to also add this to percent, in case you want to tip 1,000 percent for some reason
    numString = ensureMinDigitsAfterDecimal(numString, '.', (currencyIdentifierOnLeft == false) ? 0 : 2); //TODO... correct this
    //add the identifier after we truncate the values we don't want (since the currency identifier can go on the right)
    numString = addCurrencyIdentifier(numString, currencyIdentifier, currencyIdentifierOnLeft);

    return numString;
  }

  /// NOTE: assumes the string has AT MOST one separator
  String ensureMinDigitsAfterDecimal(String str, String separator, int precision, {bool removeLoneSeparator: true}){ //TODO... check
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

  /// --------------------------------------------------OVERRIDES--------------------------------------------------

  //can be used to limit device orientation
  @override
  void initState(){
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: new BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientLight, gradientDark],
            begin: FractionalOffset.topCenter,
            end: FractionalOffset.bottomCenter,
            stops: [0.0,1.0],
            tileMode: TileMode.clamp,
          ),
        ),
        child: ListView(
          children: <Widget>[
            new Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  new Container(
                    padding: EdgeInsets.only(top: 8.0),
                    alignment: Alignment.center,
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 32.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  new Container(
                    padding: EdgeInsets.only(bottom: 16.0),
                    alignment: Alignment.center,
                    child: Container(
                      decoration: new BoxDecoration(
                        color: textPeach,
                        borderRadius: new BorderRadius.all(const Radius.circular(5.0),
                        ),
                      ),
                      width: 90,
                      height: 4,
                    ),
                  ),
                  billSection(),
                  new Container(
                    padding: EdgeInsets.all(4.0),
                  ),
                  tipSection(),
                  new Container(
                    padding: EdgeInsets.all(4.0),
                  ),
                  splitSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// --------------------------------------------------APP SECTIONS--------------------------------------------------

  Widget billSection(){
    return new Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: new Column(
          children: <Widget>[
            new Container(
                padding: EdgeInsets.only(top: 8.0),
                alignment: Alignment.center,
                child: new Column(
                  children: <Widget>[
                    new Container(
                      child: new Text(
                        "TOTAL",
                        style: new TextStyle(
                          color: textGrey,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                    new Container(
                      child: TextFormField(
                        controller: totalController,
                        textAlign: TextAlign.center,
                        autocorrect: false,
                        keyboardType: TextInputType.number,
                        style: textLargePeach,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(0.0),
                          border: InputBorder.none,
                          hintStyle: textLargePeach,
                          hintText: "\$0.00",
                        ),
                        inputFormatters: [
                          new CurrencyTextInputFormatter(updateTotal),
                        ],
                        onEditingComplete: (){
                          //after we finish editing our value format the value to look pretty
                          FocusScope.of(context).requestFocus(new FocusNode());
                          updateStrings();
                          totalController.text = totalString;
                        },
                      ),
                    ),
                  ],
                )
            ),
            Container(
              padding: EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Expanded(
                    child: new Container(
                      child: new Column(
                        children: <Widget>[
                          new Text(
                            "Bill",
                            style: TextStyle(
                              color: textGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: TextFormField(
                              controller: billController,
                              textAlign: TextAlign.center,
                              autocorrect: false,
                              keyboardType: TextInputType.number,
                              style: textMediumPeach,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(0.0),
                                border: InputBorder.none,
                                hintStyle: textMediumPeach,
                                hintText: "\$0.00",
                              ),
                              inputFormatters: [
                                new CurrencyTextInputFormatter(updateBill),
                              ],
                              onEditingComplete: (){
                                //after we finish editing our value format the value to look pretty
                                FocusScope.of(context).requestFocus(new FocusNode());
                                updateStrings();
                                billController.text = billString;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: new Container(
                      child: new Column(
                        children: <Widget>[
                          new Text(
                            "Tip",
                            style: TextStyle(
                              color: textGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: TextFormField(
                              controller: tipController,
                              textAlign: TextAlign.center,
                              autocorrect: false,
                              keyboardType: TextInputType.number,
                              style: textMediumPeach,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(0.0),
                                border: InputBorder.none,
                                hintStyle: textMediumPeach,
                                hintText: "0.00%",
                                suffixStyle: textMediumPeach,
                              ),
                              inputFormatters: [
                                new CurrencyTextInputFormatter(
                                  updateTipPercent,
                                  currencyIdentifier: '%',
                                  currencyIdentifierOnLeft: false,
                                ),
                              ],
                              onEditingComplete: (){
                                //after we finish editing our value format the value to look pretty
                                FocusScope.of(context).requestFocus(new FocusNode());
                                updateStrings();
                                tipController.text = tipPercentString;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tipSection(){
    return Card(
      child: Container(
        padding: EdgeInsets.all(16.0),
        child: new Column(
          children: <Widget>[
            new Container(
              child: new Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  new Text(
                    "Tip",
                    style: TextStyle(
                      color: textGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  new Text(
                    "20%",
                    style: TextStyle(
                      color: textPeach,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
            ),
            new Container(
              padding: EdgeInsets.only(top: 16),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  suggestedPercentButton(10),
                  suggestedPercentButton(15),
                  suggestedPercentButton(18),
                  suggestedPercentButton(20),
                ],
              ),
            ),
            new Container(
              padding: EdgeInsets.only(top: 16),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: <Widget>[
                  new Container(
                    height: 12,
                    decoration: new BoxDecoration(
                      borderRadius: new BorderRadius.all(const Radius.circular(50.0)),
                      gradient: LinearGradient(
                        colors: [gradientLight, gradientDark],
                        begin: FractionalOffset.centerLeft,
                        end: FractionalOffset.centerRight,
                        stops: [0.0,1.0],
                        tileMode: TileMode.clamp,
                      ),
                    ),
                    child: Slider(
                      activeColor: Colors.transparent,
                      inactiveColor: Colors.transparent,
                      value: tipSliderValue,
                      onChanged: (double newValue) {
                        setState(() {
                          tipSliderValue = newValue;
                        });
                      },
                      min: 0.0,
                      max: 105.0,
                    ),
                  ),
                  IgnorePointer(
                    child: new Container(
                      height: 24,
                      width: 24,
                      decoration: new BoxDecoration(
                        borderRadius: new BorderRadius.all(const Radius.circular(50.0)),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey[500],
                            offset: Offset(0.0, 1.5),
                            blurRadius: 1.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget splitSection(){
    return Card(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              new Container(
                child: new Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    new Text(
                      "Split",
                      style: TextStyle(
                        color: textGrey,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    new Text(
                      "",
                      style: TextStyle(
                        color: textPeach,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    new Container(
                        height: 50,
                        padding: EdgeInsets.all(4.0),
                        decoration: new BoxDecoration(
                          borderRadius: new BorderRadius.all(const Radius.circular(50.0)),
                          gradient: LinearGradient(
                            colors: [gradientLight, gradientDark],
                            begin: FractionalOffset.centerLeft,
                            end: FractionalOffset.centerRight,
                            stops: [0.0,1.0],
                            tileMode: TileMode.clamp,
                          ),
                        ),
                        child: Container(
                          child: new Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              new Container(
                                width: 40,
                                height: 40,
                                decoration: new BoxDecoration(
                                  borderRadius: new BorderRadius.all(
                                    const Radius.circular(50.0),
                                  ),
                                  border: new Border.all(color: Colors.white),
                                ),
                                child: new Icon(
                                  Icons.remove,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                              new Container(
                                child: new Text(
                                  "5",
                                  style: TextStyle(
                                    fontSize: 36,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              new Container(
                                width: 40,
                                height: 40,
                                decoration: new BoxDecoration(
                                  borderRadius: new BorderRadius.all(
                                    const Radius.circular(50.0),
                                  ),
                                  border: new Border.all(color: Colors.white),
                                ),
                                child: new Icon(
                                  Icons.add,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                    ),
                  ],
                ),
              ),
              new Container(
                padding: EdgeInsets.only(top: 8.0),
                child: new Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    new Text(
                      "Split Total",
                      style: TextStyle(
                        color: textGrey,
                        fontWeight: FontWeight.bold,
                        fontSize: 22.0,
                      ),
                    ),
                    new Text(
                      "\$21.03",
                      style: TextStyle(
                        color: textPeach,
                        fontWeight: FontWeight.bold,
                        fontSize: 32.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
    );
  }

  /// --------------------------------------------------HELPER WIDGETS--------------------------------------------------

  Widget suggestedPercentButton(int percent){
    return Expanded(
      child: new Container(
        alignment: Alignment.center,
        margin: EdgeInsets.all(4.0),
        padding: EdgeInsets.all(8.0),
        decoration: new BoxDecoration(
          borderRadius: new BorderRadius.all(const Radius.circular(8.0)),
          gradient: LinearGradient(
            colors: [gradientLight, gradientDark],
            begin: FractionalOffset.topLeft,
            end: FractionalOffset.bottomRight,
            stops: [0.0,1.0],
            tileMode: TileMode.clamp,
          ),
        ),
        child: new Text(
          percent.toString() + "%",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}