import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tip_calc/currencyFormatter.dart';
import 'package:tip_calc/currencyUtils.dart';
import 'package:tip_calc/FormHelper.dart'; /// NOTE: slightly updated version of "Flutter_FeatureFilledForms"

/// FUNCTIONALITY DESCRIBED
/// there are 5 different things that you can set
/// 1. bill amount
/// 2. tip percent
/// 3. total amount
/// 4. split count
/// 5. split result
///
/// when BILL changes
///   - 2 AND 4 stay the same since they are set manually
///   - 3 changes => causes 5 to change
/// when TIP changes
///   - 1 AND 4 stay the same since they are set manually
///   - 3 changes => causes 5 to change
/// when TOTAL changes
///   - 1 AND 4 stay the same since they are set manually
///   - 2 AND 5 changes
/// when SPLIT COUNT changes
///   - 1 AND 2 AND 3 stay the same since they are set manually
///   - 5 changes
/// when SPLIT RESULT changes
///   - 4 AND 1 stay the same
///   - 2 changes => causes 3 to change

//TODO... show a message if
// (1) the user placed anything except numbers, and the decimal
// (2) the text has 2 decimals or more
//TODO... automatically scroll to the field you have selected
//TODO... only update a fields default if there is something actually different

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

  double screenEdgeToCardPadding = 16;
  double cardEdgeToInfoPadding = 16;
  double whiteThumbButtonRadius = 12;

  /// --------------------------------------------------VARIABLE PREPARATION--------------------------------------------------

  bool debugMode = true;

  FocusNode totalFocusNode = new FocusNode();
  FocusNode billFocusNode = new FocusNode();
  FocusNode tipFocusNode = new FocusNode();

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

  double totalAmount = 0;
  double billAmount = 0;

  double tipPercent = 0; //1 is 1.0%
  double tipSliderValue = 0;
  double tipSliderMin = 0;
  double tipSliderMax = 50;

  String totalString;
  String billString;
  String tipPercentString;

  /// --------------------------------------------------UPDATE FIELD FUNCTIONS--------------------------------------------------

  void updatedTotalField(double totalAmount){
    //update programmatically (bill gets no update)
    this.totalAmount = totalAmount; //REQUIRED
    double tipAmount = totalAmount - billAmount;
    if(billAmount == 0) tipPercent = 0;
    else tipPercent = (tipAmount / billAmount) * 100;

    reformatTipPercentField();
    if(debugMode) print("UPDATING TOTAL--------------------------------------------------------------------------- " + billString + " + " + tipPercentString + "% = " + totalString);
  }

  void updatedBillField(double billAmount){

    //update programmatically (percent gets no update)
    this.billAmount = billAmount; //REQUIRED
    double tipAmount = billAmount * tipPercent * .01;
    this.totalAmount = billAmount + tipAmount;

    reformatTotalField();
    if(debugMode) print("UPDATING BILL--------------------------------------------------------------------------- " + billString + " + " + tipPercentString + "% = " + totalString);
  }

  void updatedTipPercentField(double tipPercent, {bool updateSlider: true}){
    //update programmatically (bill gets no update)
    this.tipPercent = tipPercent; //REQUIRED
    double tipAmount = billAmount * tipPercent * .01;
    this.totalAmount = billAmount + tipAmount;

    if(updateSlider){
      setState(() {
        //update tip and make sure its in range
        tipSliderValue = tipPercent;
        tipSliderValue = (tipSliderValue < tipSliderMin) ? tipSliderMin : tipSliderValue;
        tipSliderValue = (tipSliderValue > tipSliderMax) ? tipSliderMax : tipSliderValue;
      });
    }

    reformatTotalField();
    if(debugMode) print("UPDATING TIP PERCENT--------------------------------------------------------------------------- " + billString + " + " + tipPercentString + "% = " + totalString);
  }

  /// --------------------------------------------------REFORMAT FIELD FUNCTIONS--------------------------------------------------

  void reformatTotalField({double newValue: -1}){
    if(newValue != -1) updatedTotalField(newValue);

    //update variables
    updateStrings();

    //actually trigger changes in the form
    totalController.text = totalString;
  }

  void reformatBillField({double newValue: -1}){
    if(newValue != -1) updatedBillField(newValue);

    //update variables
    updateStrings();

    //actually trigger changes in the form
    billController.text = billString;
  }

  void reformatTipPercentField({double newValue: -1, updateSlider: true}){
    if(newValue != -1) updatedTipPercentField(newValue, updateSlider: updateSlider);

    //update variables
    updateStrings();

    //actually trigger changes in the form
    tipController.text = tipPercentString;
  }

  /// --------------------------------------------------HELPER FUNCTIONS--------------------------------------------------

  /// NOTE: this doesn't update things visually
  void updateStrings(){
    billString = stringDecoration(billAmount, tag: '\$');
    tipPercentString = stringDecoration(tipPercent, tag: '%', percent: true);
    totalString = stringDecoration(totalAmount, tag: '\$');
  }

  String stringDecoration(double number, {String tag, bool percent: false}){
    String numberString = number.toString();
    numberString = ensureMaxDigitsAfterSeparatorString(numberString, '.', 2); //defines max
    numberString = addTrailing0sString(numberString, '.', 2); //defines min
    numberString = addSpacersString(numberString, '.', ','); //NOTE: I choose to also add this to percent, in case you want to tip 1,000 percent for some reason
    //NOTE: these tags ' ' are so that our number is center
    numberString = addLeftTagString(numberString, (percent) ? ' ' : '\$');
    numberString = addRightTagString(numberString, (percent) ? '%' : ' ');
    return numberString;
  }

  /// --------------------------------------------------OVERRIDES--------------------------------------------------

  @override
  void initState(){
    //init our parent before ourselves to avoid any strange behavior
    super.initState();

    //can be used to limit device orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    //set initial value of 15
    tipPercent = 15;
    tipSliderValue = 15;
    tipController.text = " 15.00%";

    //create listeners(these format the field once we leave it)
    totalFocusNode.addListener((){
      if(totalFocusNode.hasFocus == false){
        reformatTotalField();
      }
    });

    billFocusNode.addListener((){
      if(billFocusNode.hasFocus == false){
        reformatBillField();
      }
    });

    tipFocusNode.addListener((){
      if(tipFocusNode.hasFocus == false){
        reformatTipPercentField();
      }
    });
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
              padding: EdgeInsets.all(screenEdgeToCardPadding),
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
        padding: EdgeInsets.all(cardEdgeToInfoPadding),
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
                        focusNode: totalFocusNode,
                        controller: totalController,
                        textAlign: TextAlign.center,
                        autocorrect: false,
                        keyboardType: TextInputType.number,
                        style: textLargePeach,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintStyle: textLargePeach,
                          hintText: "\$0.00 ",
                        ),
                        inputFormatters: [
                          new CurrencyTextInputFormatter(updatedTotalField),
                        ],
                        onEditingComplete: (){
                          FocusScope.of(context).requestFocus(new FocusNode());
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
                              focusNode: billFocusNode,
                              controller: billController,
                              textAlign: TextAlign.center,
                              autocorrect: false,
                              keyboardType: TextInputType.number,
                              style: textMediumPeach,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(0.0),
                                border: InputBorder.none,
                                hintStyle: textMediumPeach,
                                hintText: "\$0.00 ",
                              ),
                              inputFormatters: [
                                new CurrencyTextInputFormatter(updatedBillField),
                              ],
                              onEditingComplete: (){
                                FocusScope.of(context).requestFocus(new FocusNode());
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
                              focusNode: tipFocusNode,
                              controller: tipController,
                              textAlign: TextAlign.center,
                              autocorrect: false,
                              keyboardType: TextInputType.number,
                              style: textMediumPeach,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(0.0),
                                border: InputBorder.none,
                                hintStyle: textMediumPeach,
                                hintText: " 0.00%",
                                suffixStyle: textMediumPeach,
                              ),
                              inputFormatters: [
                                new CurrencyTextInputFormatter(
                                  updatedTipPercentField,
                                  leftTag: ' ',
                                  rightTag: '%',
                                ),
                              ],
                              onEditingComplete: (){
                                FocusScope.of(context).requestFocus(new FocusNode());
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
        padding: EdgeInsets.all(cardEdgeToInfoPadding),
        child: new Column(
          children: <Widget>[
            new Container(
              alignment: Alignment.center,
              child: new Text(
                "Tip",
                style: TextStyle(
                  color: textGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),
            new Container(
              padding: EdgeInsets.only(top: 8),
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
              padding: EdgeInsets.only(top: 16.5),
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
                        reformatTipPercentField(newValue: tipSliderValue, updateSlider: false);
                      },
                      min: tipSliderMin,
                      max: tipSliderMax, //50
                      divisions: tipSliderMax.toInt(), //50
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(
                    calcX(context, tipSliderValue, tipSliderMin, tipSliderMax)
                    , 0),
                    child: IgnorePointer(
                      child: new Container(
                        height: whiteThumbButtonRadius * 2,
                        width: whiteThumbButtonRadius * 2,
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double calcX(BuildContext context, double tipSliderValue, double tipSliderMin, double tipSliderMax){
    //get the screens width and then slowly arrive at the widgets width
    double screenWidth = MediaQuery.of(context).size.width;
    //somehow works for both orientations so its probably a hidden padding within one of the pre-made widgets
    double numberWeGotFromExperimentation = 32;
    double sliderWidth = screenWidth - (screenEdgeToCardPadding * 2) - (cardEdgeToInfoPadding * 2) - numberWeGotFromExperimentation;

    //set thumb position to be as var as tipSliderValue is given min and max
    return ((tipSliderValue / tipSliderMax) * sliderWidth);
  }

  Widget splitSection(){
    return Card(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              new Container(
                alignment: Alignment.center,
                child: new Text(
                  "Split",
                  style: TextStyle(
                    color: textGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 8),
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
      child: GestureDetector(
        onTap: () => reformatTipPercentField(newValue: percent.toDouble()),
        child: new Container(
          alignment: Alignment.center,
          margin: EdgeInsets.all(4.0),
          padding: EdgeInsets.all(8.0),
          decoration: new BoxDecoration(
            borderRadius: new BorderRadius.all(const Radius.circular(8.0)),
            gradient: LinearGradient(
              colors: [gradientLight, gradientDark],
              begin: FractionalOffset.bottomRight,
              end: FractionalOffset.topLeft,
              stops: [0.0,1.0],
              tileMode: TileMode.clamp,
            ),
          ),
          child: new Text(
            percent.toString() + "%",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
      ),
    );
  }
}