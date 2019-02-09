import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tip_calc/currencyFormatter.dart';
import 'package:tip_calc/currencyUtils.dart';
import 'package:tip_calc/FormHelper.dart'; /// NOTE: slightly updated version of "Flutter_FeatureFilledForms"

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

  String totalString;
  String billString;
  String tipPercentString;

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

    //set initial value of 15
    tipPercent = 15;
    tipSliderValue = 15;
    tipController.text = " 15.00%";

    //create listeners(these format the field once we leave it)
    totalFocusNode.addListener((){
      if(totalFocusNode.hasFocus == false){
        print("total lost focus");
        updateStrings();
        totalController.text = totalString;
      }
    });

    billFocusNode.addListener((){
      if(billFocusNode.hasFocus == false){
        print("bill lost focus");
        updateStrings();
        billController.text = billString;
      }
    });

    tipFocusNode.addListener((){
      if(tipFocusNode.hasFocus == false){
        updateStrings();
        tipController.text = tipPercentString;
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
                        focusNode: totalFocusNode,
                        controller: totalController,
                        textAlign: TextAlign.center,
                        autocorrect: false,
                        keyboardType: TextInputType.number,
                        style: textLargePeach,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(0.0),
                          border: InputBorder.none,
                          hintStyle: textLargePeach,
                          hintText: "\$0.00 ",
                        ),
                        inputFormatters: [
                          new CurrencyTextInputFormatter(updateTotal),
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
                                new CurrencyTextInputFormatter(updateBill),
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
                                  updateTipPercent,
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
    );
  }
}