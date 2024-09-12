import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/infobar.dart'; // 장소 정보 페이지
import 'package:flutter_application_1/screens/menubar.dart'; // 메뉴 정보 페이지
import 'package:flutter_application_1/screens/reviewbar.dart'; // 리뷰 페이지
import 'package:http/http.dart' as http; // HTTP 요청을 위한 패키지
import 'dart:convert'; // JSON 파싱을 위한 패키지

class DetailPage extends StatefulWidget {
  final String name; // 장소 이름
  final String address; // 장소 주소
  final String subname; // 서브 이름 (장소와 관련된 추가 정보)
  final String id; // 장소 ID
  final String collectionName; // Firestore에서 즐겨찾기 컬렉션 이름

  DetailPage({
    super.key,
    required this.name,
    required this.subname,
    required this.address,
    required this.id,
    required this.collectionName,
  });

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage>
    with SingleTickerProviderStateMixin {
  late final String userId; // Firebase 사용자 ID
  final FavoriteService _favoriteService =
      FavoriteService(); // 즐겨찾기 서비스 클래스 인스턴스
  bool _isFavorited = false; // 해당 장소가 즐겨찾기 목록에 있는지 여부
  late TabController _tabController; // 탭 컨트롤러 (리뷰, 정보, 메뉴 탭)
  List<String> _images = []; // 장소의 이미지 리스트
  String? _contentId; // 장소의 콘텐츠 ID
  String? _contentTypeId; // 장소의 콘텐츠 타입 ID
  bool _hasError = false; // 에러 발생 여부

  @override
  void initState() {
    super.initState();

    // Firebase 사용자 인증 정보 가져오기
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      userId = currentUser.uid; // 인증된 사용자 ID 저장
      _tabController = TabController(length: 3, vsync: this); // 탭 컨트롤러 설정
      _initData(); // 데이터 초기화 함수 호출
    } else {
      // 사용자가 인증되지 않았을 때 에러 상태로 설정
      setState(() {
        _hasError = true;
      });
    }
  }

  // 데이터 초기화를 위한 함수
  Future<void> _initData() async {
    try {
      // 즐겨찾기 상태와 장소 정보 모두 비동기적으로 가져옴
      await Future.wait([
        _checkFavoriteStatus(), // 즐겨찾기 상태 확인
        _fetchContentDetails(), // 장소 정보 가져오기
      ]);
    } catch (e) {
      // 에러가 발생하면 에러 상태로 설정
      setState(() {
        _hasError = true;
      });
      print('Error initializing data: $e');
    }
  }

  // Firestore에서 즐겨찾기 상태 확인 함수
  Future<void> _checkFavoriteStatus() async {
    List<String> favorites = await _favoriteService.getFavorite(userId);
    setState(() {
      _isFavorited = favorites.contains(widget.id); // 즐겨찾기 목록에 현재 장소가 있는지 확인
    });
  }

  // 즐겨찾기 추가/제거 토글 함수
  Future<void> _toggleFavorite() async {
    setState(() {
      _isFavorited = !_isFavorited; // 현재 즐겨찾기 상태를 반전시킴
    });
    try {
      if (_isFavorited) {
        // 즐겨찾기 추가
        await _favoriteService.addFavorite(userId, widget.id);
      } else {
        // 즐겨찾기 제거
        await _favoriteService.removeFavorite(userId, widget.id);
      }
    } catch (e) {
      // 에러 발생 시 상태를 되돌림
      print('Error toggling favorite: $e');
      setState(() {
        _isFavorited = !_isFavorited;
      });
    }
  }

  // 외부 API에서 장소 정보를 가져오는 함수
  Future<void> _fetchContentDetails() async {
    const apiKey =
        'K%2Bwrqt0w3kcqkpq5TzBHI8P37Kfk50Rlz1dYzc62tM2ltmIBDY3VG4eiblr%2FQbjw1JSXZYsFQBw4IieHP9cP9g%3D%3D';
    final apiUrl =
        'http://apis.data.go.kr/B551011/KorWithService1/searchKeyword1?serviceKey=$apiKey&MobileOS=ETC&MobileApp=AppTest&keyword=${widget.name}&numOfRows=10&pageNo=1&_type=json';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // API 응답을 UTF-8로 디코딩 후 JSON으로 변환
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        print(
            'Response Body: ${utf8.decode(response.bodyBytes)}'); // 디버깅용 응답 출력

        var items = decodedData['response']?['body']?['items']?['item'];

        if (items == null || items.isEmpty) {
          // API에서 장소 정보를 찾지 못한 경우
          print('No items found');
          setState(() {
            _contentId = null;
            _contentTypeId = null;
            _images = [];
          });
        } else if (items is List && items.isNotEmpty) {
          // 장소 정보가 리스트일 경우 첫 번째 항목 사용
          var item = items[0];
          setState(() {
            _contentId = item['contentid'].toString();
            _contentTypeId = item['contenttypeid'].toString();
            _images = items
                .where((item) => item['firstimage'] != null)
                .map((item) => item['firstimage'].toString())
                .toList();
          });
        } else if (items is Map) {
          // 장소 정보가 단일 객체일 경우
          var item = items;
          setState(() {
            _contentId = item['contentid'].toString();
            _contentTypeId = item['contenttypeid'].toString();
            _images = [
              if (item['firstimage'] != null) item['firstimage'].toString()
            ];
          });
        } else {
          print('Unexpected data format');
        }
      } else {
        print('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching content details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 에러가 발생한 경우 에러 메시지를 표시
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: Text('상세 정보'),
        ),
        body: Center(
          child: Text('데이터를 불러오는 중 문제가 발생했습니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        leading: Padding(
          padding: const EdgeInsets.only(left: 22, bottom: 40),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            iconSize: 20,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 7),
            Text(widget.name, // 상단에 장소 이름 표시
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(widget.address, style: TextStyle(fontSize: 14)), // 상단에 주소 표시
          ],
        ),
        actions: [
          // 즐겨찾기 아이콘 표시
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: _toggleFavorite, // 즐겨찾기 토글 함수 호출
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite,
                      color: _isFavorited ? Color(0xff4863E0) : Colors.black12,
                      size: 26),
                  SizedBox(height: 4.0),
                  Text('찜하기',
                      style: TextStyle(
                          fontSize: 12,
                          color: _isFavorited
                              ? Color(0xff4863E0)
                              : Colors.black26)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(left: 25.0, top: 8.0, right: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 장소 이미지 표시
            if (_images.isNotEmpty)
              SizedBox(
                height: 190,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15.0),
                        child: Image.network(
                          _images[index],
                          width: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 250,
                              color: Colors.grey,
                              child: Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 8.0),
            // 탭 바 표시 (리뷰, 정보, 메뉴)
            TabBar(
              controller: _tabController,
              indicatorColor: Color(0xff4863E0),
              labelColor: Color(0xff4863E0),
              tabs: const [
                Tab(child: Text('리뷰', style: TextStyle(fontSize: 16))),
                Tab(child: Text('정보', style: TextStyle(fontSize: 16))),
                Tab(child: Text('메뉴', style: TextStyle(fontSize: 16))),
              ],
            ),
            Expanded(
              child: (_contentId != null && _contentTypeId != null)
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        ReviewPage(
                          collectionName: widget.collectionName,
                          id: widget.id,
                          ratingFields: LinkedHashMap<String, String>.from({
                            '총별점': '총점',
                            '출입': '휠체어 출입',
                            '좌석': '휠체어 좌석',
                            '친절': '친절도',
                          }),
                        ),
                        InfoPage(
                          contentId: _contentId!,
                          contentTypeId: _contentTypeId!,
                        ),
                        menubar(
                          collectionName: widget.collectionName,
                          id: widget.id,
                        ),
                      ],
                    )
                  : Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 즐겨찾기 추가 함수
  Future<void> addFavorite(String userId, String storeId) async {
    DocumentReference userRef = _firestore.collection('users').doc(userId);
    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        // 즐겨찾기 컬렉션이 없으면 생성
        transaction.set(userRef, {
          'favorites': [storeId]
        });
      } else {
        // 즐겨찾기 목록에 추가
        List<dynamic> favorites =
            (snapshot.data() as Map<String, dynamic>)['favorites'] ?? [];
        if (!favorites.contains(storeId)) {
          favorites.add(storeId);
          transaction.update(userRef, {'favorites': favorites});
        }
      }
    });
  }

  // 즐겨찾기 목록 가져오기 함수
  Future<List<String>> getFavorite(String userId) async {
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return List<String>.from(data['favorites'] ?? []); // 즐겨찾기 목록 반환
    } else {
      return [];
    }
  }

  // 즐겨찾기 제거 함수
  Future<void> removeFavorite(String userId, String storeId) async {
    DocumentReference userRef = _firestore.collection('users').doc(userId);
    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      List<dynamic> favorites =
          (snapshot.data() as Map<String, dynamic>)['favorites'] ?? [];
      favorites.remove(storeId); // 즐겨찾기 목록에서 제거
      transaction.update(userRef, {'favorites': favorites});
    });
  }
}
