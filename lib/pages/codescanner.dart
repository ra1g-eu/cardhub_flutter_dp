import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class Scanner extends StatefulWidget {
  const Scanner();

  @override
  ScannerState createState() => ScannerState();
}

class ScannerState extends State<Scanner> with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  var qrText = "";
  late QRViewController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context, "scanCancelled");
            },
            icon: const Icon(Icons.keyboard_backspace),
          ),
        ),
        body: Stack(
          alignment: Alignment.topLeft,
          children: <Widget>[
            QRView(
              key: qrKey,
              onQRViewCreated: (r) => _onQRViewCreated(r, context),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width,
                    color: Colors.grey.shade800,
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      'Naskenuj kód karty',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.normal,
                        letterSpacing: 1.1,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ));
  }

  void _onQRViewCreated(
      QRViewController controller, BuildContext context) async {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      ScaffoldMessenger.of(context).clearSnackBars();
      setState(() {
        qrText = scanData.code.toString();
      });
      if(qrText != ""){
        controller.pauseCamera();
        controller.stopCamera();
        Navigator.pop(context, qrText);
      }

    });

  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
