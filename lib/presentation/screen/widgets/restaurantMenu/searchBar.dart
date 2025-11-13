import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomeSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const HomeSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  @override
  _HomeSearchBarState createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  final bool _isListening = false;
  late stt.SpeechToText _speech;
  late TextEditingController _controller;
  // String _spokenText = "";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _controller = TextEditingController();
  }

  // void _toggleMic() async {
  //   if (_isListening) {
  //     setState(() {
  //       _isListening = false;
  //     });
  //     _speech.stop();
  //   } else {
  //     setState(() {
  //       _isListening = true;
  //     });
  //     _speech.listen(
  //       onResult: (result) {
  //         setState(() {
  //           _spokenText = result.recognizedWords;
  //           _controller.text = _spokenText;
  //           _controller.selection = TextSelection.fromPosition(
  //             TextPosition(offset: _controller.text.length),
  //           );
  //         });
  //         widget.onChanged(_spokenText);

  //         if (result.finalResult) {
  //           setState(() {
  //             _isListening = false;
  //           });
  //           _speech.stop();
  //         }
  //       },
  //     );
  //   }
  // }

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.black.withOpacity(0.3)),
            
          ),
          child: TextField(
            controller: _controller,
            onChanged: widget.onChanged,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black.withOpacity(0.8),
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              border: InputBorder.none,
              hintText: "Search ${widget.hintText}...",
              hintStyle: GoogleFonts.poppins(
                color: Colors.black.withOpacity(0.7),
                fontSize: 14,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.black),
            ),
          ),
        ),

        if (_isListening)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Listening...",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.greenAccent,
              ),
            ),
          ),
      ],
    );
  }
}
