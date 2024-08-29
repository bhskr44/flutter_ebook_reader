import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_html/flutter_html.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;
import 'package:flutter_tts/flutter_tts.dart'; // Import the flutter_tts package

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EPUB Reader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _htmlContent = '';
  String? EbookTitle;
  final FlutterTts _flutterTts = FlutterTts(); // Create an instance of FlutterTts
  ValueNotifier<bool> _isTtsPlaying = ValueNotifier(false);
  String _currentText = '';
  int _ttsPosition = 0; // Track the last position in the text

  Map<String, String> _htmlFiles = {}; // Map to store the HTML content by file name

  @override
  void initState() {
    super.initState();
    _loadEPUBFromAssets();
  }

  String extractEbookTitle(Archive archive) {
    try {
      // Locate the .opf file in the archive
      final contentOpf = archive.firstWhere(
        (file) => file.name.endsWith('.opf'),
        orElse: () => ArchiveFile('', 0, null),
      );

      if (contentOpf.content != null) {
        // Decode and parse the OPF file content
        final contentOpfBytes = contentOpf.content as List<int>;
        final contentOpfString = utf8.decode(contentOpfBytes);

        // Parse the XML content
        final document = xml.XmlDocument.parse(contentOpfString);

        // Extract the title using XML traversal
        final titleElement = document.findAllElements('dc:title').first;
        final ebookTitle = titleElement.text;

        return ebookTitle;
      } else {
        return '';
      }
    } catch (e) {
      return '';
    }
  }

  void _playPauseTts() async {
    if (_isTtsPlaying.value) {
      // Pause TTS
      await _flutterTts.stop();
      _isTtsPlaying.value = false;
    } else {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.speak(_currentText.substring(_ttsPosition));
      _isTtsPlaying.value = true;
      _flutterTts.setStartHandler(() {
        _isTtsPlaying.value = true;
      });
      _flutterTts.setCompletionHandler(() {
        _isTtsPlaying.value = false;
      });
      _flutterTts.setPauseHandler(() {
        _isTtsPlaying.value = false;
      });
    }
  }

  Future<void> _loadEPUBFromAssets() async {
    try {
      final byteData = await rootBundle.load('assets/sample2.epub');
      final bytes = byteData.buffer.asUint8List();
      final archive = ZipDecoder().decodeBytes(bytes);

      EbookTitle = extractEbookTitle(archive);

      String htmlContent = '';
      final Map<String, Uint8List> images = {};

      for (final file in archive) {
        if ((file.name.endsWith('.html') || file.name.endsWith('.xhtml')) && (file.name != 'toc.xhtml' && file.name != 'toc.html')) {
          final htmlBytes = file.content as List<int>;
          final content = utf8.decode(htmlBytes);
          _htmlFiles[file.name] = content; // Store the HTML content by file name
          htmlContent += content; // Concatenate HTML content
        } else if (file.name.endsWith('.png') || file.name.endsWith('.jpg') || file.name.endsWith('.gif')) {
          images[file.name] = Uint8List.fromList(file.content as List<int>);
        }
      }

      var document = html_parser.parse(htmlContent);

      // Replace image paths in HTML content with base64 data URIs
      var imgTags = document.getElementsByTagName('img');
      for (var imgTag in imgTags) {
        var src = imgTag.attributes['src'];
        if (src != null) {
          var imgName = src;

          if (imgName.contains('../')) {
            imgName = imgName.replaceAll('../', '');
          }

          final imgData = images['OEBPS/$imgName'];
          if (imgData != null) {
            final base64 = base64Encode(imgData);
            imgTag.attributes['src'] = 'data:image/${imgName.split('.').last};base64,$base64';
          }
        }
      }

      // get the links from the document file

      var ahreflink = document.getElementsByTagName('a');
      if (ahreflink.isNotEmpty) {
        for (var link in ahreflink) {
          var href = link.attributes['href'];
          if (href != null) {
            if (href.contains('../')) {
              var newLink = href.replaceAll('../', 'OBEPS/');
              link.attributes['href'] = newLink;
            }
          }
        }
      }

      document = html_parser.parse(htmlContent);

      // Add the contents of the CSS listed in the document file to the head of the HTML content
      var ccclink = document.getElementsByTagName('link');

      if (ccclink.isNotEmpty) {
        String? cssFileName;
        for (var link in ccclink) {
          var rel = link.attributes['rel'];
          if (rel == 'stylesheet') {
            cssFileName = link.attributes['href'];
            if (cssFileName != null) {
              if (cssFileName.contains('../')) {
                cssFileName = cssFileName.replaceAll('../', '');
              }
              // Error handling for the 'firstWhere' method
              var cssFile = archive.firstWhere(
                (file) => file.name == 'OEBPS/$cssFileName',
              );

              if (cssFile != null) {
                final cssBytes = cssFile.content as List<int>;
                final cssContent = utf8.decode(cssBytes);
                var styleElement = dom.Element.tag('style')..text = cssContent;
                document.head?.append(styleElement);
              } else {
                print('CSS file not found: OEBPS/$cssFileName');
              }
            }
          }
        }
      }

      htmlContent = document.outerHtml;

      _currentText = document.body?.text ?? '';

      setState(() {
        _htmlContent = htmlContent.isNotEmpty ? htmlContent : 'No HTML content found.';
      });
    } catch (e) {
      setState(() {
        _htmlContent = 'Error loading EPUB file: $e';
      });
      print("Error: $e");
    }
  }

  // Function to handle link taps
  void _handleLinkTap(String? url) {
    if (url != null && url.isNotEmpty) {
      // Update the HTML content with the new page's content
      setState(() {
        _htmlContent = _htmlFiles[url] ?? 'Page not found';
        _currentText = html_parser.parse(_htmlContent).body?.text ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          EbookTitle ?? 'EPUB Reader',
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _htmlContent.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        Html(
                          data: _htmlContent,
                        ),

                        SizedBox(height: 70),
                      ],
                    )
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            ),
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: ValueListenableBuilder<bool>(
              valueListenable: _isTtsPlaying,
              builder: (context, isPlaying, child) {
                return FloatingActionButton(
                  onPressed: _playPauseTts,
                  child: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
