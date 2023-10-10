import 'dart:io';

import 'package:file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:pdf_reader/pdf_viewer_screen.dart';
import 'package:path/path.dart' as path;
import 'package:pdf_reader/data_controller.dart';
import 'package:pdf_reader/shared_pref_controller.dart';
import 'package:share_plus/share_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FileManagerController controller = FileManagerController();
  final DataController myController = Get.put(DataController());
  ValueNotifier<List<FileSystemEntity>> data = ValueNotifier([]);

  SharedPreferenceController sharedPreferenceController =
      SharedPreferenceController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControlBackButton(
      controller: controller,
      child: Scaffold(
        appBar: appBar(context),
        body: FileManager(
          controller: controller,
          builder: (context, snapshot) {
            data.value = snapshot;
            return ValueListenableBuilder(
              valueListenable: data,
              builder: (BuildContext context, value, Widget? child) {
                try {
                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                    itemCount: data.value.length,
                    itemBuilder: (context, index) {
                      FileSystemEntity entity = data.value[index];
                      bool isPDF =
                          entity is File && entity.path.endsWith('.pdf');
                      if (data.value.isEmpty) {
                        return const Center(
                          child: Text("No Records Found"),
                        );
                      } else if (isPDF || FileManager.isDirectory(entity)) {
                        return Slidable(
                          closeOnScroll: true,
                          endActionPane: isPDF
                              ? ActionPane(
                                  extentRatio: 0.3,
                                  motion: const ScrollMotion(),
                                  children: [
                                    SlidableAction(
                                      autoClose: true,
                                      onPressed: (context) async {
                                        if (!FileManager.isDirectory(entity)) {
                                          await entity.delete();
                                          data.value.remove(entity);
                                          myController.recentList
                                              .remove(entity.path);
                                          sharedPreferenceController
                                              .setStringListValue(
                                                  "dataList",
                                                  myController.recentList
                                                      .toList());
                                          data.notifyListeners();
                                        }
                                      },
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete,
                                    ),
                                    SlidableAction(
                                      autoClose: true,
                                      onPressed: (context) {
                                        sharePDF(entity.path);
                                      },
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      icon: Icons.share,
                                    ),
                                  ],
                                )
                              : null,
                          child: ListTile(
                            leading: isPDF
                                ? Image.asset("assets/pdf.png",
                                    height: 30, width: 30)
                                : const Icon(Icons.folder),
                            title: Text(FileManager.basename(
                              entity,
                              showFileExtension: true,
                            )),
                            // subtitle: subtitle(entity),
                            subtitle: FileManager.isDirectory(entity)
                                ? const Text("Directory")
                                : const Text("File"),
                            onTap: () async {
                              if (FileManager.isDirectory(entity)) {
                                Directory directory = Directory(entity.path);
                                try {
                                  List<FileSystemEntity> directoryContents =
                                      await directory.list().toList();
                                  bool containsFilesOrSubdirectories =
                                      directoryContents.any((content) {
                                    return content is File ||
                                        FileManager.isDirectory(content);
                                  });
                                  if (containsFilesOrSubdirectories) {
                                    controller.openDirectory(entity);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor: Colors.redAccent,
                                        content: Text(
                                            "The selected directory is empty."),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Colors.redAccent,
                                      content: Text(
                                          "Don't have Access for this Folder or Directory"),
                                    ),
                                  );
                                }
                              } else if (isPDF) {
                                String filePath = data.value[index].path;
                                if (!myController.recentList
                                    .contains(filePath)) {
                                  myController.recentList.add(filePath);
                                  sharedPreferenceController.setStringListValue(
                                      "dataList",
                                      myController.recentList.toList());
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PDFViewerScreen(
                                        pdfPath: entity.path,
                                        pdfName: path.basename(entity.path)),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  );
                } catch (e) {
                  return const Center(
                      child: Text("Don't have access for this folder"));
                }
              },
            );
          },
        ),
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: ValueListenableBuilder<String>(
        valueListenable: controller.titleNotifier,
        builder: (context, title, _) =>
            title == "0" || title == "" ? const Text("Storage") : Text(title),
      ),
    );
  }

  Future<void> sharePDF(String pdfPath) async {
    try {
      final pdfFile = File(pdfPath);
      final pdfFileName = pdfPath.split('/').last;

      final Uint8List bytes = await pdfFile.readAsBytes();

      final xFile =
          XFile.fromData(bytes, name: pdfFileName, mimeType: 'application/pdf');

      await Share.shareXFiles([xFile], text: 'Sharing PDF');
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
    }
  }
}
