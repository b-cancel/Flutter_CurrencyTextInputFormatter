import 'package:flutter/material.dart';
import 'package:flutter_range_slider/flutter_range_slider.dart';

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

  TextEditingController totalController = new TextEditingController();
  TextEditingController billController = new TextEditingController();
  TextEditingController tipController = new TextEditingController();

  Color gradientTop = const Color.fromARGB(255, 255, 203, 174);
  Color gradientBottom = const Color.fromARGB(255, 255, 128, 148); //const Color.fromARGB(255, 205, 139, 149);
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

  double totalAmount = 0;
  double billAmount = 0;
  double tipPercent = 0; //1% is 1.0

  void updateTotal(double totalAmount){
    //update programmatically (bill gets no update)
    this.totalAmount = totalAmount; //REQUIRED
    double tipAmount = totalAmount - billAmount;
    if(tipAmount == 0) tipPercent = 0;
    else tipPercent = (tipAmount / billAmount) * 100;

    //update variables
    updateStrings();

    //actually trigger changes in the form
    tipController.text = tipPercentString;
    print("UPDATING TOTAL--------------------------------------------------------------------------- " + billString + " + " + tipPercentString + "% = " + totalString);
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
    print("UPDATING BILL--------------------------------------------------------------------------- " + billString + " + " + tipPercentString + "% = " + totalString);

    //as an added bonus this update our standard rates
    setState(() {

    });
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
    print("UPDATING TIP PERCENT--------------------------------------------------------------------------- " + billString + " + " + tipPercentString + "% = " + totalString);
  }

  void updateStrings(){
    billString = stringDecoration(billAmount, showSpacers: true, currencyIdentifier: '\$ ');
    tipPercentString = stringDecoration(tipPercent, showSpacers: true, currencyIdentifier: ' %', currencyIdentifierOnLeft: false);
    totalString = stringDecoration(totalAmount, showSpacers: true, currencyIdentifier: '\$ ');
  }

  String stringDecoration(double num, {
    bool rightPercent: false,
    bool showSpacers: false,
    String separator: '.',
    String spacer: ',',
    String currencyIdentifier: '',
    bool currencyIdentifierOnLeft: true,
  }){
    String numString = removeExtraValuesAfterSeparator(num.toString(), (rightPercent) ? 0 : 2);
    numString = currencyMask(numString, '.', ',');
    numString = ensureValuesAfterSeparator(numString, '.', (rightPercent) ? 0 : 2);

    if(showSpacers || currencyIdentifier != ''){
      TextEditingValue value = new TextEditingValue(text: numString);
      if(showSpacers) value = addSpacers(value, separator, spacer);
      if(currencyIdentifierOnLeft) value = addIdentifier(value, currencyIdentifier, currencyIdentifierOnLeft);
      numString = value.text;
    }

    return numString;
  }

  /*
  String amountToString(double amount, bool percent){
    String numString = removeExtraValuesAfterSeparator(amount.toString(), 2);
    numString = currencyMask(numString, '.', ',');
    /// NOTE: line below displays everything nicer but it also causes an infinite loop
    /// we could repair this by making the field a text box when we click it and ONLY when we click it
    //numString = ensureValuesAfterSeparator(numString, '.', 2);
    return numString;
  }


  void visualUpdate(){
    //update variables
    billString = amountToString(billAmount, false);
    tipPercentString = amountToString(tipPercent, true);
    totalString = amountToString(totalAmount, false);

    //actually trigger changes in the form
    billController.text = billString;
    tipController.text = tipPercentString;
    totalController.text = totalString;

    print(billString + " percent " + tipPercentString + " = " + totalString);
  }
  */

  Widget standardRow(var str, double num, {bool rightPercent = false}){

    String numString = stringDecoration(num, rightPercent: rightPercent);

    double fontSize = 18.0;
    return new Row(
      children: <Widget>[
        new Text(str, style: TextStyle(fontSize: fontSize)),
        new Text(numString + ((rightPercent) ? " %" : ''), style: TextStyle(fontSize: fontSize)),
      ],
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
    );
  }

  /// NOTE: we KNOW (1) amount and (2) percent is valid
  Widget defaultForm(double amount, double percent, Color c) {

    //make sure the total is valid
    double tipAmount = amount * percent * .01; //TODO... use this as well perhaps
    double total =  tipAmount + amount;

    //return the widget
    return new Card(
      color: c,
      child: new Column(
        children: <Widget>[
          new Container(
            padding: EdgeInsets.all(16.0),
            child: new Column(
              children: <Widget>[
                standardRow("Amount", amount),
                standardRow("+", percent, rightPercent: true),
                new Container(
                  margin: EdgeInsets.only(top: 2.0, bottom: 2.0),
                  height: 2.0,
                  color: Colors.black,
                ),
                standardRow("Total", total),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget suggestionsWidget({bool scrollable: false}){
    var widgets = [
      defaultForm(billAmount, 10, Colors.cyan[700]),
      defaultForm(billAmount, 15, Colors.cyan[500]),
      defaultForm(billAmount, 20, Colors.cyan[300])
    ];
    return new Container(
      padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
      width: double.maxFinite,
      child: (scrollable) ? ListView(children: widgets) : Column(children: widgets),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(16.0),
        decoration: new BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientTop, gradientBottom],
            begin: FractionalOffset.topCenter,
            end: FractionalOffset.bottomCenter,
            stops: [0.0,1.0],
            tileMode: TileMode.clamp,
          ),
        ),
        child: ListView(
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
            new Card(
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
                                hintText: "\$ 0.00",
                              ),
                              inputFormatters: [
                                new CurrencyTextInputFormatter(updateTotal),
                              ],
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
                                        hintText: "\$ 0.00",
                                      ),
                                      inputFormatters: [
                                        new CurrencyTextInputFormatter(updateBill),
                                      ],
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
                                        hintText: "0.00 %",
                                        suffixStyle: textMediumPeach,
                                      ),
                                      inputFormatters: [
                                        new CurrencyTextInputFormatter(
                                          updateTipPercent,
                                          currencyIdentifier: ' %',
                                          currencyIdentifierOnLeft: false,
                                          maskWithSpacers: false,
                                        ),
                                      ],
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
            ),
            Card(
              child: Container(

              ),
            ),
            Card(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: new Column (
                  children: <Widget>[
                    suggestionsWidget()
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}