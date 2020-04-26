
class Ticket {
  String id;
  String eventId;
  String owner;
  bool scanned;

  Ticket({this.id, this.eventId, this.owner, this.scanned});

  factory Ticket.fromJson(Map<String, dynamic> json) {
    Map<String,dynamic> ticket = json["ticket"];

    return Ticket(
      id: ticket['_id'],
      eventId: ticket['event'],
      owner: ticket['member'],
      scanned: ticket['scanned']
    );
  }

  factory Ticket.fromJson2(Map<String, dynamic> json) {
    return Ticket(
        id: json['_id'],
        eventId: json['event'],
        owner: json['member'],
        scanned: json['scanned']
    );
  }


}