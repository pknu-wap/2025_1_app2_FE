import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app2_client/models/address_model.dart';
import 'package:app2_client/screens/destination_map_screen.dart';
import 'package:app2_client/constants/api_constants.dart';

class SearchAddressScreen extends StatefulWidget {
  const SearchAddressScreen({Key? key}) : super(key: key);

  @override
  _SearchAddressScreenState createState() => _SearchAddressScreenState();
}

class _SearchAddressScreenState extends State<SearchAddressScreen> {
  final TextEditingController _controller = TextEditingController();
  List<AddressModel> _results = [];
  bool _isLoading = false;

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _results = [];
    });

    final uri = Uri.parse(ApiConstants.kakaoSearchUrl)
        .replace(queryParameters: {'query': query});
    final resp = await http.get(
      uri,
      headers: {'Authorization': ApiConstants.kakaoRestKey},
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      final docs = body['documents'] as List<dynamic>;
      setState(() {
        _results = docs
            .map((e) => AddressModel.fromJson(e))
            .toList();
      });
    } else {
      debugPrint('주소 검색 실패: ${resp.statusCode} ${resp.body}');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주소 검색'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '도로명, 건물명 등으로 검색',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchAddress(_controller.text),
                ),
              ),
              onSubmitted: _searchAddress,
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final addr = _results[i];
                return ListTile(
                  title: Text(addr.addressName),
                  subtitle: Text('(${addr.lat}, ${addr.lng})'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DestinationMapScreen(
                          initialLat: addr.lat,
                          initialLng: addr.lng,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}