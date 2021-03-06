import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ext_storage/ext_storage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'File Downloader'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

enum FileTypes { mp3, mp4, pdf, jpg, png }

class _MyHomePageState extends State<MyHomePage> {
  bool downloading = false;
  var progress = "";
  final downloadLink = TextEditingController();
  final file_name = TextEditingController();
  bool isInitializingMemory = false;
  FileTypes type = FileTypes.jpg;
  String fileType;

  void getPermission() async {
    print("get permission");
    await Permission.storage.request();
  }

  Widget getViews(String name, FileTypes fixedType, FileTypes relativeType) {
    return Row(
      children: [
        Radio(
          value: relativeType,
          groupValue: fixedType,
          onChanged: (FileTypes value) {
            setState(() {
              fixedType = value;
              fileType = "$name";
            });
          },
        ),
        Text(
          ".$name",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    getPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: downloading
              ? Container(
                  height: 150.0,
                  width: 200.0,
                  child: Card(
                    color: Colors.black,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20.0),
                        Text(
                          "Downloading: $progress%",
                          style: TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                  ),
                )
              : Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextField(
                              autofocus: true,
                              enableInteractiveSelection: true,
                              decoration: InputDecoration(hintText: "paste download link there", labelText: "Link"),
                              controller: downloadLink,
                            ),
                            TextField(
                              autofocus: true,
                              enableInteractiveSelection: true,
                              decoration: InputDecoration(hintText: "paste desired file name", labelText: "name"),
                              controller: file_name,
                            ),
                          ],
                        ),
                      ),
                      RaisedButton(
                        onPressed: () {
                          if (downloadLink.text.length == 0 || file_name.text.length == 0)
                            Fluttertoast.showToast(msg: "empty name/link", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM, timeInSecForIosWeb: 1, backgroundColor: Colors.black26, textColor: Colors.white, fontSize: 16.0);
                          else
                            downloadFile(downloadLink.text, file_name.text, fileType);
                        },
                        child: Text("DOWNLOAD"),
                        textColor: Colors.white,
                        color: Colors.blue,
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 10.0),
                        child: Text(
                          "File types:",
                          style: TextStyle(
                            fontSize: 30.0,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            children: [
                              Radio(
                                value: FileTypes.jpg,
                                groupValue: type,
                                onChanged: (FileTypes value) {
                                  setState(() {
                                    type = value;
                                    fileType = "jpg";
                                  });
                                },
                              ),
                              Text(
                                ".jpg",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                value: FileTypes.pdf,
                                groupValue: type,
                                onChanged: (FileTypes value) {
                                  setState(() {
                                    type = value;
                                    fileType = "pdf";
                                  });
                                },
                              ),
                              Text(
                                ".pdf",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            children: [
                              Radio(
                                value: FileTypes.png,
                                groupValue: type,
                                onChanged: (FileTypes value) {
                                  setState(() {
                                    type = value;
                                    fileType = "png";
                                  });
                                },
                              ),
                              Text(
                                ".png",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                value: FileTypes.mp3,
                                groupValue: type,
                                onChanged: (FileTypes value) {
                                  setState(() {
                                    type = value;
                                    fileType = "mp3";
                                  });
                                },
                              ),
                              Text(
                                ".mp3",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Radio(
                                value: FileTypes.mp4,
                                groupValue: type,
                                onChanged: (FileTypes value) {
                                  setState(() {
                                    type = value;
                                    fileType = "mp4";
                                  });
                                },
                              ),
                              Text(
                                ".mp4",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
    );
  }

  //endregion download image
  Future<void> downloadFile(String link, String name, String fileType) async {
    Dio dio = Dio();

    try {
      var externalDirectoryPath = await ExtStorage.getExternalStoragePublicDirectory(ExtStorage.DIRECTORY_DOWNLOADS);
      print(externalDirectoryPath);
      /*setState(() {
        isInitializingMemory = true;
      });*/

      await dio.download(link, "$externalDirectoryPath/$name.$fileType", onReceiveProgress: (rec, total) {
        print("Rec: $rec,  Total: $total");
        setState(() {
          downloading = true;
          progress = ((rec / total) * 100).toStringAsFixed(0);
        });
        print(progress);
      });
    } catch (e) {
      print(e);
    }
    setState(() {
      downloading = false;
      downloadLink.text = "";
      file_name.text = "";
    });
  }

//endregion
}

/*
Steps to download any file to the phone's storage:
1. install
   dio,   ext_storage and permission_handler dependencies to in pubspec.yaml file
   1)dio is for downloading file via its download link:
      Dio dio = Dio();
      dio.download(url,  path, {some other arguments...})

   2)permission handler is for entering the device's files or locations
   3)ext_storage is minimal flutter plugin that provides external storage path and external public storage path

 */
