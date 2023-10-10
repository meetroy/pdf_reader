import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String pdfName;

  const PDFViewerScreen(
      {Key? key, required this.pdfPath, required this.pdfName})
      : super(key: key);

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  @override
  void dispose() {
    pdfViewerController.dispose();
    super.dispose();
  }

  PdfViewerController pdfViewerController = PdfViewerController();
  bool isLoading = true;
  int totalPages = 0;
  int indexPages = 0;

  void _sharePDF() async {
    try {
      final pdfFile = File(widget.pdfPath);
      final pdfFileName = widget.pdfPath.split('/').last;

      final Uint8List bytes = await pdfFile.readAsBytes();

      final xFile =
          XFile.fromData(bytes, name: pdfFileName, mimeType: 'application/pdf');

      await Share.shareXFiles([xFile], text: 'Sharing PDF');
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = '${indexPages + 1} of $totalPages';
    final pdfFileName = widget.pdfPath.split('/').last.replaceAll(".pdf", "");

    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: () {
                _sharePDF();
              },
              icon: const Icon(Icons.ios_share_rounded),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Center(
                child: Text(
              page,
              style: const TextStyle(fontSize: 10),
            )),
          ),
        ],
        centerTitle: true,
        title: Text(pdfFileName, style: const TextStyle(fontSize: 15)),
      ),
      body: Stack(
        children: [
          PDFView(
            onRender: (pages) => setState(() {
              totalPages = pages!;
            }),
            onPageChanged: (page, total) => setState(() {
              indexPages = page!;
            }),
            filePath: widget.pdfPath,
            pageFling: false,
            autoSpacing: false,
          )
          // SfPdfViewer.file(
          //   File(widget.pdfPath),
          //   pageSpacing: 2.0,
          //   enableDoubleTapZooming: true,
          //   enableTextSelection: true,
          //   controller: pdfViewerController,
          //   onDocumentLoadFailed: (details) {
          //     setState(() {
          //       isLoading = false;
          //     });
          //   },
          //   onDocumentLoaded: (details) {
          //     setState(() {
          //       isLoading = false;
          //     });
          //   },
          // ),
          // if (isLoading)
          //   Center(
          //       child: SvgPicture.asset(
          //     "assets/logo.svg",
          //     height: 30,
          //     width: 30,
          //   ))
        ],
      ),
    );
  }
}
