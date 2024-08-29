# EPUB Reader with TTS Support

A Flutter application that transforms your reading experience by not only displaying EPUB content but also reading it aloud using Text-to-Speech (TTS). Seamlessly navigate through chapters, enjoy embedded images and styles, and control the reading pace with a user-friendly interface. Ideal for readers who want hands-free content consumption.

## Features

- **EPUB Parsing**: Reads and parses EPUB files to display their content.
- **Text-to-Speech (TTS)**: Integrated TTS functionality to read aloud the text.
- **Interactive HTML Rendering**: Displays HTML content from EPUB files, including embedded images and styles.
- **Link Navigation**: Handles link taps within the content to navigate between different sections or chapters.
- **CSS Support**: Includes CSS from the EPUB files to maintain the original styling.
- **Dynamic Title Extraction**: Extracts and displays the ebook title from the EPUB file's metadata.
- **UI**: Simple, user-friendly interface with a floating action button to control TTS playback.

## Getting Started

To get started with this project, clone the repository and load it into your Flutter environment.

```bash
git clone https://github.com/bhskr44/flutter_ebook_reader.git
cd flutter_ebook_reader
flutter pub get
flutter run
```

## Usage

1. Add your EPUB files to the `assets` folder.
2. Run the app on a supported device or emulator.
3. The app will load the EPUB file, display its content, and provide TTS controls.

## Dependencies

- `flutter_html`: For rendering HTML content.
- `archive`: For decompressing EPUB files.
- `flutter_tts`: For TTS functionality.
- `xml`: For parsing XML content.
- `html`: For HTML parsing and manipulation.

## Contributing

Contributions are welcome! Feel free to submit a pull request or open an issue if you have suggestions or find any bugs.

## License

This project is licensed under the MIT License.

---
