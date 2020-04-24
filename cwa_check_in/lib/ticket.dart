import 'package:flutter/cupertino.dart';

class Ticket {
  String id;
  String eventId;
  String owner;
  bool scanned;

  Ticket({@required this.id, @required this.eventId, @required this.owner, @required this.scanned});

  factory Ticket.fromJson(Map<String, dynamic> json) {
    Map<String,dynamic> ticket = json["ticket"];

    return Ticket(
      id: ticket['_id'],
      eventId: ticket['event'],
      owner: ticket['member'],
      scanned: ticket['scanned']
    );
  }



}