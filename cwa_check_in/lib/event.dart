class Event{
  String id;
  String title;
  String description;
  String location;
  String date;
  String time;


  
  Event({this.id, this.title, this.description, this.location, this.date, this.time});


  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      date: json['date'] as String,
      time: json['time'] as String
    );
  }

}