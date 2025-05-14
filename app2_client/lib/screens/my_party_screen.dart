import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/party_detail_model.dart';
import '../providers/auth_provider.dart';
import '../services/party_service.dart';

class MyPartyScreen extends StatelessWidget {
  const MyPartyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthProvider>().tokens?.accessToken;

    if (token == null) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('내 파티')),
      body: FutureBuilder<PartyDetail?>(
        future: PartyService.getMyParty(token),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final party = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('출발지: ${party.originAddress}'),
                Text('도착지: ${party.destAddress}'),
                Text('반경: ${party.radius}km'),
                Text('최대 인원: ${party.maxPerson}명'),
                Text('옵션: ${party.partyOption}'),
                const SizedBox(height: 16),
                Text('참여자 목록', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                ...party.members.map((m) => ListTile(
                  title: Text(m.name),
                  subtitle: Text('${m.email} (${m.role})'),
                  leading: Icon(
                    m.gender == 'FEMALE' ? Icons.female : Icons.male,
                    color: m.gender == 'FEMALE' ? Colors.pink : Colors.blue,
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}