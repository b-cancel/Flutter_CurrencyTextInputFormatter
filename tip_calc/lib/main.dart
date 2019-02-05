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

  double amount = 0;
  TextEditingController controller = new TextEditingController();

  void updateAmount(double newAmount){
    setState(() {
      amount = newAmount;
    });
  }

  Widget standardRow(var str, double num, {bool rightPercent = false}){

    String numString = removeExtraValuesAfterSeparator(num.toString(), (rightPercent) ? 0 : 2);
    numString = maskWithSpacers(numString, '.', ',');
    numString = ensureValuesAfterSeparator(numString, '.', (rightPercent) ? 0 : 2);

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
      defaultForm(amount, 10, Colors.cyan[700]),
      defaultForm(amount, 15, Colors.cyan[500]),
      defaultForm(amount, 20, Colors.cyan[300])
    ];
    return new Container(
      padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
      width: double.maxFinite,
      child: (scrollable) ? ListView(children: widgets) : Column(children: widgets),
    );
  }

  //NOTE: use this if you want to use a pop up instead
  void _showDialog() {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          contentPadding: EdgeInsets.all(0.0),
          content: suggestionsWidget(scrollable: true),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16.0),
            child: new Column (
              children: <Widget>[
                new Container(
                  child: Form(
                    child: TextFormField(
                      autofocus: true,
                      autocorrect: false,
                      keyboardType: TextInputType.number,
                      controller: controller,
                      decoration: InputDecoration(
                        prefixText: '\$ ',
                        labelText: "Amount Due",
                        helperText: "Type Amount Due",
                        suffix: new GestureDetector(
                          onTap: (){
                            controller.clear();
                            updateAmount(0);
                          },
                          child: new Icon(Icons.close),
                        ),
                        //hintText: "Type Amount Due in USD",
                        //errorText: "error",
                      ),
                      inputFormatters: [
                        new CurrencyTextInputFormatter(updateAmount),
                      ],
                    ),
                  ),
                ),
                suggestionsWidget()
              ],
            ),
          ),
        ],
      ),
    );
  }
}