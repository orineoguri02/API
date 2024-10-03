import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:html/parser.dart'; // HTML 파싱을 위해 추가

class InfoPage extends StatefulWidget {
  final String contentId;
  final String contentTypeId;

  const InfoPage({
    super.key,
    required this.contentId,
    required this.contentTypeId,
  });

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  Map<String, dynamic>? _contentDetails;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchContentDetails();
  }

  Future<void> _fetchContentDetails() async {
    try {
      // 공통 정보 조회를 위한 API URL
      final commonResponse = await http.get(
        Uri.parse(
          'http://apis.data.go.kr/B551011/KorWithService1/detailCommon1?serviceKey=K%2Bwrqt0w3kcqkpq5TzBHI8P37Kfk50Rlz1dYzc62tM2ltmIBDY3VG4eiblr%2FQbjw1JSXZYsFQBw4IieHP9cP9g%3D%3D&MobileOS=ETC&MobileApp=AppTest&contentId=${widget.contentId}&contentTypeId=${widget.contentTypeId}&defaultYN=Y&firstImageYN=Y&areacodeYN=Y&catcodeYN=Y&addrinfoYN=Y&mapinfoYN=Y&overviewYN=Y&_type=json',
        ),
        headers: {
          'Accept': 'application/json',
        },
      );

      // 소개 정보 조회를 위한 API URL
      final introResponse = await http.get(
        Uri.parse(
          'http://apis.data.go.kr/B551011/KorWithService1/detailIntro1?serviceKey=K%2Bwrqt0w3kcqkpq5TzBHI8P37Kfk50Rlz1dYzc62tM2ltmIBDY3VG4eiblr%2FQbjw1JSXZYsFQBw4IieHP9cP9g%3D%3D&MobileOS=ETC&MobileApp=AppTest&contentId=${widget.contentId}&contentTypeId=${widget.contentTypeId}&_type=json',
        ),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (commonResponse.statusCode == 200 && introResponse.statusCode == 200) {
        // UTF-8 디코딩 처리
        final commonData = json.decode(utf8.decode(commonResponse.bodyBytes));
        final introData = json.decode(utf8.decode(introResponse.bodyBytes));

        print('Common Response Body: ${utf8.decode(commonResponse.bodyBytes)}');
        print('Intro Response Body: ${utf8.decode(introResponse.bodyBytes)}');

        var commonItems = commonData['response']?['body']?['items']?['item'];
        var introItems = introData['response']?['body']?['items']?['item'];

        // items가 없는 경우 처리
        if (commonItems == null || commonItems.isEmpty) {
          print(
              'No common items found for the given contentId: ${widget.contentId}');
          setState(() {
            _hasError = true;
            _contentDetails = null;
          });
          return;
        }

        if (introItems == null || introItems.isEmpty) {
          print(
              'No intro items found for the given contentId: ${widget.contentId}');
          setState(() {
            _hasError = true;
            _contentDetails = null;
          });
          return;
        }

        var commonItem = commonItems[0]; // 첫 번째 공통 정보 항목 사용
        var introItem = introItems[0]; // 첫 번째 소개 정보 항목 사용

        // 공통 정보와 소개 정보를 병합하여 setState에 반영
        setState(() {
          _contentDetails = {
            'opentimefood': introItem['opentimefood'],
            'seat': commonItem['seat'],
            'tel': commonItem['tel'],
            'parkingfood': introItem['parkingfood'],
            'overview': commonItem['overview'],
            'addr1': commonItem['addr1'],
            'homepage': removeHtmlTags(commonItem['homepage']),
            'infocenterfood': introItem['infocenterfood'], // 소개 정보에서 추가
            'restdate': introItem['restdate'], // 소개 정보에서 추가
            'usetime': introItem['usetime'], // 소개 정보에서 추가
          };
        });
      } else {
        setState(() {
          _hasError = true;
        });
        print(
            'Failed to load data. Status code: ${commonResponse.statusCode} or ${introResponse.statusCode}');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      print('Error fetching content details: ${e.toString()}');
    }
  }

  // HTML 태그 제거 함수
  String removeHtmlTags(String htmlString) {
    final document = parse(htmlString);
    return parse(document.body!.text).documentElement!.text;
  }

  @override
  Widget build(BuildContext context) {
    if (_contentDetails == null) {
      return Center(
        child: _hasError
            ? Text('데이터를 불러오는 중 문제가 발생했습니다.')
            : CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            icon: Icons.access_time,
            title: '영업시간',
            content: _contentDetails?['opentimefood'] ?? '정보 없음',
          ),
          Divider(thickness: 0.7, color: Colors.grey),
          _buildInfoSection(
            icon: Icons.phone,
            title: '대표전화',
            content: _contentDetails?['infocenterfood'] ?? '정보 없음',
          ),
          Divider(thickness: 0.7, color: Colors.grey),
          _buildInfoSection(
            icon: Icons.event_seat,
            title: '기본정보',
            content: _contentDetails?['overview'] ?? '정보 없음',
          ),
          Divider(thickness: 0.7, color: Colors.grey),
          _buildInfoSection(
            icon: Icons.home,
            title: '홈페이지',
            content: _contentDetails?['homepage'] ?? '정보 없음',
          ),
          Divider(thickness: 0.7, color: Colors.grey),
          _buildInfoSection(
            icon: Icons.local_parking,
            title: '주차 정보',
            content: _contentDetails?['parkingfood'] ?? '정보 없음',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.all(23.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 15)),
            ],
          ),
          SizedBox(height: 12),
          Text(content),
        ],
      ),
    );
  }
}
