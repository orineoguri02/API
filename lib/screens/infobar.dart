import 'package:flutter/material.dart';

class InfoPage extends StatelessWidget {
  final String contentId;
  final String contentTypeId;
  final Map<String, dynamic>? contentDetails; // 콘텐츠 정보

  const InfoPage({
    super.key,
    required this.contentId,
    required this.contentTypeId,
    this.contentDetails, // 콘텐츠 정보를 받음
  });

  @override
  Widget build(BuildContext context) {
    if (contentDetails == null) {
      return Center(
        child: Text('정보를 불러오는 중입니다.'),
      );
    }

    var openTime = contentDetails!['opentimefood'] as String?;
    var call = contentDetails!['chkcreditcardfood'] as String?;
    var seat = contentDetails!['seat'] as String?;
    var menu = contentDetails!['infocenterfood'] as String?;
    var parking = contentDetails!['parkingfood'] as String?;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            icon: Icons.access_time,
            title: '영업시간',
            content: openTime ?? '정보 없음',
          ),
          Divider(thickness: 0.7, color: Colors.grey),
          _buildInfoSection(
            icon: Icons.phone,
            title: '카드 결제 여부',
            content: call ?? '정보 없음',
          ),
          Divider(thickness: 0.7, color: Colors.grey),
          _buildInfoSection(
            icon: Icons.event_seat,
            title: '좌석 정보',
            content: seat ?? '정보 없음',
          ),
          Divider(thickness: 0.7, color: Colors.grey),
          _buildInfoSection(
            icon: Icons.restaurant_menu,
            title: '메뉴 정보',
            content: menu ?? '정보 없음',
          ),
          Divider(thickness: 0.7, color: Colors.grey),
          _buildInfoSection(
            icon: Icons.local_parking,
            title: '주차 정보',
            content: parking ?? '정보 없음',
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
