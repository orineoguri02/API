import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/screens/map/detailpage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AllPlacesFrame extends StatelessWidget {
  const AllPlacesFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _fetchAllDocuments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          }

          return MapPage(allDocuments: snapshot.data!);
        },
      ),
    );
  }

  Future<List<DocumentSnapshot>> _fetchAllDocuments() async {
    List<String> collections = [
      'cafe',
      'restaurant',
      'park',
      'display',
      'play'
    ];
    List<DocumentSnapshot> allDocuments = [];

    for (String collection in collections) {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection(collection).get();
      allDocuments.addAll(snapshot.docs);
    }

    return allDocuments;
  }
}

class MapPage extends StatefulWidget {
  final List<DocumentSnapshot> allDocuments;

  MapPage({super.key, required this.allDocuments});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final LatLng _center = const LatLng(37.5758772, 126.9768121);
  final Map<String, LatLng> _cityCoordinates = {
    '서울': LatLng(37.5665, 126.9780),
    '대구': LatLng(35.8714, 128.6014),
    '포항': LatLng(36.0190, 129.3435),
    '대전': LatLng(36.3504, 127.3845),
  };
  String _selectedCity = '서울';
  final Set<Marker> _markers = {};

  void _adjustCameraToFitMarkers() {
    if (_markers.isEmpty) return;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (final marker in _markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) {
        minLng = marker.position.longitude;
      }
      if (marker.position.longitude > maxLng) {
        maxLng = marker.position.longitude;
      }
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // 패딩 값
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  Future<void> _createMarkers() async {
    setState(() {
      _markers.clear();
    });

    try {
      for (var doc in widget.allDocuments) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['location'] != null) {
          GeoPoint geoPoint = data['location'];

          Marker marker = Marker(
            markerId: MarkerId(doc.id), // 문서 ID를 마커 ID로 사용
            position: LatLng(geoPoint.latitude, geoPoint.longitude), // 위치 설정
            infoWindow: InfoWindow(
              title: data['name'], // 정보 창 제목
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPage(
                      name: data['name'],
                      subname: '',
                      address: data['address'],
                      id: doc.id,
                      collectionName: doc.reference.parent.id,
                      contentTypeId: '',
                    ), // 컬렉션 이름 추가
                  ),
                );
              },
            ),
          );

          setState(() {
            _markers.add(marker);
          });
        }
      }
      setState(() {
        // 로딩 종료
      });
    } catch (e) {
      print('Error fetching locations: $e');
    } finally {
      setState(() {
        _adjustCameraToFitMarkers();
      });
    }
  }

  void _moveCamera(LatLng position) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position,
            zoom: 12.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 100,
            child: DropdownButton<String>(
              value: _selectedCity,
              isExpanded: true,
              items: _cityCoordinates.keys.map((city) {
                return DropdownMenuItem(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCity = value!;
                  _moveCamera(_cityCoordinates[_selectedCity]!);
                });
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _createMarkers();
            },
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _markers,
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.1,
            maxChildSize: 0.95,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                color: Colors.white,
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.allDocuments.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> data = widget.allDocuments[index]
                        .data() as Map<String, dynamic>;
                    List<String> banner = data['banner'] is List
                        ? List<String>.from(data['banner'])
                        : [];
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(16), // 원하는 패딩 설정
                        elevation: 2, // 그림자 효과
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // 모서리 둥글게
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(
                              name: data['name'] ?? 'No Name',
                              address: data['address'] ?? 'No Address',
                              subname: data['subname'],
                              id: widget.allDocuments[index].id,
                              collectionName: widget
                                  .allDocuments[index].reference.parent.id,
                              contentTypeId: '',
                            ), // 컬렉션 이름 전달
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          if (banner.isNotEmpty)
                            Image.network(
                              banner[0],
                              height: 100,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                    Icons.error); // 이미지 로드 실패 시 에러 아이콘 표시
                              },
                            )
                          else
                            Container(
                              height: 100,
                              width: 100,
                              color: Colors.grey, // 이미지가 없을 때 회색 박스 표시
                              child: Icon(Icons.image_not_supported),
                            ),
                          SizedBox(
                            width: 15,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? 'No Name',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                                Text(
                                  data['subname'] ?? 'No subname',
                                  style: TextStyle(
                                      fontSize: 15, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
