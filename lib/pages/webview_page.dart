import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({Key? key, required this.url}) : super(key: key);

  @override
  State<WebViewPage> createState() => _WebViewPageState();
  final String url;
}

class _WebViewPageState extends State<WebViewPage> {
  final controller = Completer<WebViewController>();
  @override
  void dispose() {
    super.dispose();
  }



  var loadingPercentage = 0;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: callAsyncFetch(),
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.data == true) {
            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Colors.black,
                toolbarHeight: 45,
                centerTitle: true,
                // Add from here ...
                actions: [
                Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.close, size: 30),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
                ],
                // ... to here.
              ),
              body: SafeArea(
                child: Stack(
                  children: [
                    WebView(
                      initialUrl: widget.url,
                      // Add from here ...
                      onWebViewCreated: (webViewController) {
                        controller.complete(webViewController);
                      },
                      // ... to here.
                      onPageStarted: (url) {
                        setState(() {
                          loadingPercentage = 0;
                        });
                      },
                      onProgress: (progress) {
                        setState(() {
                          loadingPercentage = progress;
                        });
                      },
                      onPageFinished: (url) {
                        setState(() {
                          loadingPercentage = 100;
                        });
                      },
                      javascriptMode: JavascriptMode.unrestricted,
                    ),
                    if (loadingPercentage < 100)
                      LinearProgressIndicator(
                        value: loadingPercentage / 100.0,
                      ),
                  ],
                ),
              ), // Add the controller argument
            );
          } else {
            return const CircularProgressIndicator();
          }
        }
    );
  }

  callAsyncFetch() async{

    bool isInternet = await InternetConnectionChecker().hasConnection;

    return isInternet;
  }
}