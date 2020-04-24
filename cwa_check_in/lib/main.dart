import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'ticket.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanner demo boi',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Scanner demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String result = "";
  bool isAlreadyScanned = false;
  String isAlreadyScannedString = "Is already scanned: ";

  Future<http.Response> getScannedHttpRequest(String ticketId) {
    return http.get(
      'https://alexanderhuangen.wixsite.com/mysite/_functions/getScanned/' + ticketId,
      );
  }


  Future<http.Response> setScannedHttpRequest(String ticketId) {
    return http.put(
      'https://alexanderhuangen.wixsite.com/mysite/_functions/setScanned',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, Object>{
        //important to have _id since wix is checking if an object with the same _id property is present in a database collection
        '_id': ticketId,
        'scanned': true
      }),
    );
  }

  Future scanBarcode() async {
      try {
        ScanResult barcode = await BarcodeScanner.scan();
        setState(() => result = barcode.rawContent);

        http.Response response = await getScannedHttpRequest(result);

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
        if (response.statusCode == 200) {
          // If the server did return a 200 GET response,
          // then parse the JSON.
          Ticket object = Ticket.fromJson(json.decode(response.body));
          setState(()=> isAlreadyScanned = object.scanned);
        } else {
          // If the server did not return a 201 CREATED response,
          // then throw an exception.
          throw Exception('Failed to load album');
        }

      } on PlatformException catch (e) {
        if (e.code == BarcodeScanner.cameraAccessDenied) {
          setState(() =>
          this.result = 'The user did not grant the camera permission!');
        } else {
          setState(() => this.result = 'Unknown error: $e');
        }
      } catch(error) {
        print("${error?.toString()}");
      }
    }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("QR Scanner"),
      ),
      body: Center(
        child: Column(
          children:<Widget>[
            Text(
              result,
              style: new TextStyle(fontSize: 30.0),
          ),
            Text(
              isAlreadyScannedString + isAlreadyScanned.toString(),
              style: new TextStyle(fontSize: 30.0),
            ),
          ]
        )
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: scanBarcode,
        icon: Icon(Icons.camera_alt),
        label: Text("Scan"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

