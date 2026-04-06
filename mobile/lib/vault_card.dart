import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AICVaultCard extends StatefulWidget {
  final String blurUrl;
  final int price;
  final String mediaId;

  AICVaultCard({required this.blurUrl, required this.price, required this.mediaId});

  @override
  _AICVaultCardState createState() => _AICVaultCardState();
}

class _AICVaultCardState extends State<AICVaultCard> {
  bool _unlocked = false;
  String? _revealedUrl;

  Future<void> _unlock() async {
    final res = await http.post(
      Uri.parse('https://your-api.railway.app/api/unlock'),
      body: jsonEncode({'userId': 'USER_ID_HERE', 'mediaId': widget.mediaId}),
      headers: {'Content-Type': 'application/json'},
    );

    if (res.statusCode == 200) {
      setState(() {
        _unlocked = true;
        _revealedUrl = jsonDecode(res.body)['url'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300, height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(_unlocked ? _revealedUrl! : widget.blurUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: _unlocked ? null : Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.black26),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, color: Colors.amber, size: 50),
                ElevatedButton(
                  onPressed: _unlock,
                  child: Text("UNLOCK: ${widget.price} TOKENS"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
