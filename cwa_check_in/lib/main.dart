import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'ticket.dart';
import 'event.dart';
import 'package:progress_dialog/progress_dialog.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Scanner demo boi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EventPage(title: "Event-view",),
    );
  }
}

class EventPage extends StatefulWidget{
  EventPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  EventPageState createState() => EventPageState();
}

class EventPageState extends State<EventPage>{

  Future<List<Event>> getEventsFromServer() async {
    http.Response response = await http.get(
      'https://alexanderhuangen.wixsite.com/mysite/_functions/events',
    );
    List<Event> events = new List<Event>();
    //print('Response status: ${response.statusCode}');
    //print('Response body: ${response.body}');
    if (response.statusCode == 200){
      List<dynamic> json_list = jsonDecode(response.body)['events'] as List<dynamic>;
      for(dynamic object in json_list){
          events.insert(0, Event.fromJson(object));
      }
    }
    return events;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Choose event to check in"),

      ),
      body: FutureBuilder(
        future: getEventsFromServer(),
        builder: (context,snapshot){
          if(snapshot.hasData){
            return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (context, index){
                  return Card(
                    child: ListTile(
                      onTap: (){
                        Navigator.push(context ,MaterialPageRoute(builder: (context) => ScanPage(event: snapshot.data[index])));
                        },
                      title: Text(snapshot.data[index].id),
                    ),
                  );
                }
            );} else {
            return Center(child: Column(children: [CircularProgressIndicator(), Text("If loading takes too long: server issues when getting event information")]));
          }
        },)
    );
  }
}


class ScanPage extends StatefulWidget {
  ScanPage({Key key, this.title, this.event }) : super(key: key);

  final String title;
  Event event;
  @override
  ScanPageState createState() => ScanPageState(currentEvent: event);
}



class ScanPageState extends State<ScanPage> {

  ScanPageState({this.currentEvent});
  Event currentEvent;
  String result = "";
  List<Ticket> tickets = List<Ticket>();


  @protected
  @mustCallSuper
  void initState() {
    getScannedFromEventFromServer(currentEvent.id);
  }

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
        //important to have _id since wix is checking if an object with the same _id property is present in a database collection in the WixData.update() method
        '_id': ticketId
      }),
    );
  }

  Future scanBarcode() async {

      ProgressDialog progressDialog = ProgressDialog(context,
        type: ProgressDialogType.Normal,
        isDismissible: false,
      );

      SimpleDialog successDialog = SimpleDialog(backgroundColor: Colors.green,);

      progressDialog.style(insetAnimCurve: Curves.elasticInOut, progressWidget: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent)));

      try {
        ScanResult barcode = await BarcodeScanner.scan();
        setState(() => result = barcode.rawContent);
        progressDialog.show();
        http.Response response = await getScannedHttpRequest(result);

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
        if (response.statusCode == 200) {
          // If the server did return a 200 GET response,
          // then parse the JSON.
          Ticket object = Ticket.fromJson(json.decode(response.body));

          if(object.eventId == currentEvent.id){
            if(object.scanned == false || object.scanned == null){
              print("ticket has not been scanned before");
              response = await setScannedHttpRequest(result);
              print('Response status: ${response.statusCode}');
              print('Response body: ${response.body}');
              if(response.statusCode == 200){
                //success feedback
                object.scanned = true;
                await progressDialog.hide();
                setState(() => tickets.insert(0,object));
              } else {
                await progressDialog.hide();
                alert(context, "Scan failed", "Failed to mark ticket as scanned in database or server offline");
                throw Exception('Failed to mark ticket as scanned in database or server offline');
              }
            } else {
              //already scanned
              await progressDialog.hide();
              alert(context, "Scan failed", "Ticket has already been scanned");
            }
          } else {
            await progressDialog.hide();
            alert(context, "Scan failed", "Event on ticket does not match current event");
          }
        } else {
          // If the server did not return a 200 GET response,
          // then throw an exception.
          await progressDialog.hide();
          alert(context, "Scan failed", "Ticket doesn't exist in database or server offline");
          throw Exception('Failed to load ticket');
        }
        progressDialog.hide();
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

  Future<void> alert(BuildContext context, String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              title,
              style: TextStyle(
                  color: Colors.red.withOpacity(0.6)
              )
          ),
          content: Text(message),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }



  Future getScannedFromEventFromServer(String eventId) async {
    http.Response response = await http.get(
      'https://alexanderhuangen.wixsite.com/mysite/_functions/getScannedFromEvent/' + eventId,
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200){
      List<dynamic> json_list = jsonDecode(response.body)['tickets'] as List<dynamic>;
      for(dynamic object in json_list){
        setState(() {
          tickets.insert(0, Ticket.fromJson2(object));
        });
      }

      print(tickets.length);
    }
    return;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("QR Scanner"),
        backgroundColor: Colors.blueAccent,

    ),
      body: Column(
        children: <Widget>[
          Card(
            child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 4,
                child: Text("Event: " + currentEvent.id),
            ),
          ),
          Expanded(
              child:ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (context, index){
                    return Card(
                      child: ListTile(
                        onTap: (){},
                        title: Text(tickets[index].id),
                      ),
                    );
                  })
          )
        ],
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

