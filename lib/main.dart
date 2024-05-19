import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Earthquake Data',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> propertiesList = [];

  @override
  void initState() {
    super.initState();
    fetchEarthquakeData();
  }

  Future<void> fetchEarthquakeData() async {
    String url =
        "https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&starttime=2022-03-05&endtime=2022-03-06&limit=10";
    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      List<Map<String, dynamic>> tempList = [];
      for (var feature in jsonData['features']) {
        tempList.add(feature['properties']);
      }
      setState(() {
        propertiesList = tempList;
      });
    } else {
      print('Failed to load data');
    }
  }

  void addEarthquakeData(Map<String, dynamic> newData) {
    setState(() {
      propertiesList.add(newData);
    });
  }

  void updateEarthquakeData(int index, Map<String, dynamic> updatedData) {
    setState(() {
      propertiesList[index] = updatedData;
    });
  }

  void confirmDeleteEarthquakeData(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                deleteEarthquakeData(index);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void deleteEarthquakeData(int index) {
    setState(() {
      propertiesList.removeAt(index);
    });
  }

  Future<void> showEditDialog(int? index) async {
    var isEditing = index != null;
    var data = isEditing
        ? propertiesList[index]
        : {'mag': '', 'place': '', 'type': ''};
    var magnitudeController =
        TextEditingController(text: data['mag'].toString());
    var placeController = TextEditingController(text: data['place']);
    var typeController = TextEditingController(text: data['type']);

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text(isEditing ? 'Edit Earthquake Data' : 'Add Earthquake Data'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: magnitudeController,
                  decoration: InputDecoration(labelText: 'Magnitude'),
                ),
                TextField(
                  controller: placeController,
                  decoration: InputDecoration(labelText: 'Place'),
                ),
                TextField(
                  controller: typeController,
                  decoration: InputDecoration(labelText: 'Type'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                var newData = {
                  'mag': double.tryParse(magnitudeController.text) ?? 0.0,
                  'place': placeController.text,
                  'type': typeController.text
                };

                if (isEditing) {
                  updateEarthquakeData(index, newData);
                } else {
                  addEarthquakeData(newData);
                }
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
        title: Text(
          'Earthquake Data',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showEditDialog(null);
        },
        child: Icon(Icons.add),
        backgroundColor:
            Colors.brown, // Set floating action button color to green
      ),
      body: propertiesList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: propertiesList.length,
              itemBuilder: (context, index) {
                var properties = propertiesList[index];
                var magnitude = properties['mag']?.toStringAsFixed(2) ?? 'N/A';
                var place = properties['place'] ?? 'Unknown location';
                var type = properties['type'] ?? 'N/A';

                // Split place into parts
                var parts = place.split(' of ');
                var distancePart = parts.isNotEmpty ? parts[0] : '';
                var locationParts = parts.length > 1
                    ? parts[1].split(', ')
                    : ['Unknown location'];
                var locationPart1 =
                    locationParts.isNotEmpty ? locationParts[0] : '';
                var locationPart2 =
                    locationParts.length > 1 ? locationParts[1] : '';

                return Card(
                  color: Colors.white, // Set card color to white
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'M $magnitude - $distancePart\n$locationPart1,\n$locationPart2\n$type',
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            showEditDialog(index);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            confirmDeleteEarthquakeData(index);
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailPage(properties: properties),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final Map<String, dynamic> properties;

  DetailPage({required this.properties});

  @override
  Widget build(BuildContext context) {
    var magnitude = properties['mag']?.toStringAsFixed(2) ?? 'N/A';
    var place = properties['place'] ?? 'Unknown location';
    var type = properties['type'] ?? 'N/A';
    var time = properties['time'] != null
        ? DateTime.fromMillisecondsSinceEpoch(properties['time'])
        : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text('Earthquake Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Magnitude: $magnitude',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Location: $place', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Type: $type', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Time: ${time.toString()}', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
