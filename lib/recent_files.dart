import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:pdf_reader/pdf_viewer_screen.dart';
import 'package:pdf_reader/data_controller.dart';
import 'package:pdf_reader/shared_pref_controller.dart';

class RecentFile extends StatefulWidget {
  const RecentFile({
    Key? key,
  }) : super(key: key);

  @override
  State<RecentFile> createState() => _RecentFileState();
}

class _RecentFileState extends State<RecentFile> {
  SharedPreferenceController sharedPreferenceController =
      SharedPreferenceController();
  final DataController myController = Get.put(DataController());

  List<String> dataList = [];

  @override
  void initState() {
    getList();
    super.initState();
  }

  Future<void> getList() async {
    List<String> newDataList =
        await sharedPreferenceController.getStringListValue("dataList");
    setState(() {
      dataList = newDataList.reversed.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recent"),
        centerTitle: true,
      ),
      body: Center(
        child: ListView.separated(
          itemCount: dataList.length,
          itemBuilder: (context, index) {
            String fileName = path.basename(dataList[index]);
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                onTap: () {
                  String filePath = dataList[index];
                  // if (filePath != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PDFViewerScreen(
                        pdfPath: filePath.toString(),
                        pdfName: fileName,
                      ),
                    ),
                  );
                },
                title: Text(fileName),
                leading: Image.asset("assets/pdf.png", height: 30, width: 30),
              ),
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return const Divider(
              height: 4,
              thickness: 2.0,
            );
          },
        ),
      ),
    );
  }
}
