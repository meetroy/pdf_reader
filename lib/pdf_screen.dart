import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:external_path/external_path.dart';
import 'package:file_manager/controller/file_manager_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:pdf_reader/data_base_helper.dart';
import 'package:pdf_reader/drawer_helper.dart';
import 'package:pdf_reader/pdf_viewer_screen.dart';
import 'package:pdf_reader/data_controller.dart';
import 'package:pdf_reader/shared_pref_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import 'home_page.dart';

class PDFScreen extends StatefulWidget {
  const PDFScreen({Key? key}) : super(key: key);

  @override
  State<PDFScreen> createState() => _PDFScreenState();
}

class _PDFScreenState extends State<PDFScreen> with WidgetsBindingObserver {
  final FileManagerController fileManagerController = FileManagerController();
  ScrollController controller = ScrollController();
  ValueNotifier<List<String>> pdfFiles = ValueNotifier([]);
  ValueNotifier<List<String>> data = ValueNotifier([]);

  SharedPreferenceController sharedPreferenceController =
      SharedPreferenceController();

  final dbHelper = DatabaseHelper();

  // static const int batchSize = 12;
  // static int offset = 0;

  Future<void> getFiles(String directoryPath) async {
    try {
      var rootDirectory = Directory(directoryPath);
      var directories = rootDirectory.list(recursive: false);

      directories.forEach((element) {
        if (element is File) {
          if (element.path.split(".").last == "pdf") {
            debugPrint("PDF File Name : ${element.path.split("/").last}");

            pdfFiles.value.add(element.path);
            pdfFiles.notifyListeners();
          }
        } else if (directoryPath != "/storage/emulated/0/Android/") {
          getFiles(element.path);
          // final data = await compute(getFiles, element.path);
          // filePaths.addAll(data);
        }
      });
    } catch (e) {
      debugPrint(e.toString());
      pdfFiles.notifyListeners();
    }
  }

  Future<void> scrollListener() async {}

  Future<void> baseDirectory() async {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    AndroidDeviceInfo androidDeviceInfo = await deviceInfoPlugin.androidInfo;
    if (androidDeviceInfo.version.sdkInt < 30) {
      PermissionStatus permissionStatus = await Permission.storage.request();
      if (permissionStatus.isGranted) {
        var rootDirectory = await ExternalPath.getExternalStorageDirectories();
        await getFiles(rootDirectory.first);
        pdfFiles.notifyListeners();
      }
    } else {
      PermissionStatus permissionStatus =
          await Permission.manageExternalStorage.request();
      if (permissionStatus.isGranted) {
        var rootDirectory = await ExternalPath.getExternalStorageDirectories();
        await getFiles(rootDirectory.first);
        // pdfFiles.value = await compute(getFiles, rootDirectory.first);
        // await dbHelper.clearTable();
        // for (String path in pdfFiles.value) {
        //   await dbHelper.insertPDFPath(path);
        //   var data = await dbHelper.getPDFPaths(currentOffset, limit);
        //   debugPrint(data.length.toString());
        // }
        pdfFiles.notifyListeners();
      }
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    controller.addListener(scrollListener);
    pdfFiles.notifyListeners();
    baseDirectory();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(scrollListener);
    super.dispose();
  }

  final DataController myController = Get.put(DataController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerHelper(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              )).then((value) {
            pdfFiles.value.clear();
            baseDirectory();
            pdfFiles.notifyListeners();
          });
        },
      ),
      appBar: AppBar(
        centerTitle: true,
        title: const Text("On This Device", style: TextStyle(fontSize: 15)),
      ),
      body: ValueListenableBuilder(
          valueListenable: pdfFiles,
          builder: (context, value, child) => pdfFiles.value.isEmpty
              ? const Center(child: Text("Fetching PDFs..."),)
              : ListView.builder(
                  controller: controller,
                  itemCount: pdfFiles.value.length,
                  itemBuilder: (context, index) {
                    String fileName = path.basename(pdfFiles.value[index]);
                    return Slidable(
                      closeOnScroll: true,
                      endActionPane: ActionPane(
                        extentRatio: 0.3,
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            autoClose: true,
                            onPressed: (context) {
                              deleteFile(pdfFiles.value[index]);
                            },
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                          ),
                          SlidableAction(
                            autoClose: true,
                            onPressed: (context) {
                              sharePDF(pdfFiles.value[index]);
                            },
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            icon: Icons.share,
                          ),
                        ],
                      ),
                      direction: Axis.horizontal,
                      child: ListTile(
                        onTap: () async {
                          String filePath = pdfFiles.value[index];
                          if (!myController.recentList.contains(filePath)) {
                            myController.recentList.add(filePath);
                            sharedPreferenceController.setStringListValue(
                                "dataList", myController.recentList.toList());
                          }
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PDFViewerScreen(
                                  pdfPath: filePath.toString(),
                                  pdfName: fileName,
                                ),
                              ));
                        },
                        title: Text(
                          fileName,
                          // style: const TextStyle(fontFamily: "Montserrat")
                        ),
                        leading: Image.asset("assets/pdf.png",
                            height: 30, width: 30),
                      ),
                    );
                  },
                )),
    );
  }

  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      await file.delete();
      pdfFiles.value.remove(filePath);
      pdfFiles.notifyListeners();
      myController.recentList.remove(filePath);
      sharedPreferenceController.setStringListValue(
          "dataList", myController.recentList.toList());
    } catch (e) {
      debugPrint("Error deleting file: $e");
    }
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
