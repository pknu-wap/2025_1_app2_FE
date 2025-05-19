import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app2_client/models/party_model.dart';
import 'package:provider/provider.dart';
import 'package:app2_client/providers/auth_provider.dart';
import '../services/party_service.dart';

class PartyJoinModal extends StatelessWidget {
  final PartyModel pot;

  const PartyJoinModal({
    Key? key,
    required this.pot,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, ctl) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: ctl,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                pot.creatorName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('yyyy/MM/dd HH:mm').format(pot.createdAt),
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text('남은 자리: ${pot.remainingSeats}명'),
              const SizedBox(height: 12),
              Text('출발: ${pot.originAddress}'),
              Text('도착: ${pot.destAddress}'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await PartyService.attendParty(
                      partyId: pot.id,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('파티에 참가했습니다!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('참가 실패: $e')),
                    );
                  }
                },
                child: const Text('팟 신청하기'),
              ),
            ],
          ),
        );
      },
    );
  }
}