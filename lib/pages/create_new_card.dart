import 'dart:convert';
import 'dart:io';

import 'package:barcode_finder/barcode_finder.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardhub/pages/add_new_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../apicalls/upload_card.dart';

Future<String> uploadCard(CardToUpload cardToUpload) async {
  final prefs = await SharedPreferences.getInstance();
  String response = await UploadCard()
      .uploadCardToDB(prefs.getString('loginCode')!, cardToUpload);
  return response;
}

Image base64ToImage(String base64) {
  return Image.memory(
    height: 150,
    width: 150,
    base64Decode(base64),
    fit: BoxFit.contain,
  );
}

Future<String?> scanFile() async {
  FilePickerResult? pickedFile = await FilePicker.platform.pickFiles();
  if (pickedFile != null) {
    String? filePath = pickedFile.files.single.path;
    if (filePath != null) {
      final file = File(filePath);
      return await BarcodeFinder.scanFile(path: file.path);
    } else {
      return 'Error';
    }
  } else {
    return 'Wrong file';
  }
}

Barcode selectBarcode(bool isQRCode) {
  if (isQRCode) {
    return Barcode.qrCode();
  } else {
    return Barcode.code128();
  }
}

class CreateNewCard extends StatefulWidget {
  const CreateNewCard({Key? key}) : super(key: key);

  @override
  CreateNewCardState createState() => CreateNewCardState();
}

class CreateNewCardState extends State<CreateNewCard> {
  late CardToUpload cardToUpload = CardToUpload('', '', 'Slovensko', 0, '');

  TextEditingController cardDescController = TextEditingController();
  TextEditingController textController = TextEditingController();

  @override
  void dispose() {
    cardDescController.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ShopDetail shopDetail =
        ModalRoute.of(context)?.settings.arguments as ShopDetail;
    return Scaffold(
      appBar: AppBar(
        title: Text('Nová ${shopDetail.shopName} karta'),
      ),
      //passing in the ListView.builder
      body: SingleChildScrollView(
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.only(bottomRight: Radius.circular(35)),
                    image: DecorationImage(
                        image: base64ToImage(shopDetail.shopLogo).image),
                  ),
                  child: null,
                ),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info),
                        title:
                            Text('ID obchodu: ${shopDetail.shopId.toString()}'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: Text('Názov: ${shopDetail.shopName}'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            const Divider(
              height: 2,
              thickness: 1,
              color: Colors.black,
              endIndent: 13,
              indent: 13,
            ),
            const SizedBox(
              height: 15,
            ),
            const Text(
              'Vyber krajinu pre kartu',
              style: TextStyle(fontSize: 20, letterSpacing: 1.2),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 10, 25, 25),
              child: DropdownButton<String>(
                elevation: 2,
                isExpanded: true,
                iconSize: 25,
                value: cardToUpload.cardCountry,
                icon: const Icon(
                  Icons.south_america,
                  size: 25,
                ),
                items: <String>['Slovensko', 'Česko'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    cardToUpload.cardCountry = value!;
                  });
                },
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            const Divider(
              height: 2,
              thickness: 1,
              color: Colors.black,
              endIndent: 13,
              indent: 13,
            ),
            const SizedBox(
              height: 15,
            ),
            const Text(
              'Doplňujúce informácie',
              style: TextStyle(fontSize: 20, letterSpacing: 1.2),
            ),
            Expanded(
              flex: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: TextField(
                  scrollPadding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 15 * 4),
                  minLines: 3,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  maxLength: 500,
                  controller: cardDescController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Vlož doplňujúce informácie karty'),
                  onChanged: (value) {
                    cardToUpload.cardDescription = value;
                  },
                ),
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    var result =
                        await Navigator.pushNamed(context, "/codescanner");
                    if (result == 'scanCancelled') {
                      QuickAlert.show(
                          context: context,
                          type: QuickAlertType.error,
                          title: 'Kód',
                          text: 'Skenovanie zrušené!',
                          confirmBtnText: 'Pokračovať',
                          barrierDismissible: false,
                          onConfirmBtnTap: () async {
                            Navigator.pop(context);
                          });
                    } else {
                      QuickAlert.show(
                          context: context,
                          type: QuickAlertType.success,
                          title: 'Kód',
                          text: 'Kód ${result.toString()} úspešne naskenovaný!',
                          confirmBtnText: 'Pokračovať',
                          barrierDismissible: false,
                          onConfirmBtnTap: () async {
                            Navigator.pop(context);
                          });
                      cardToUpload.cardCode = result.toString();
                      textController.text = cardToUpload.cardCode;
                    }
                  },
                  style: ButtonStyle(
                      elevation: MaterialStateProperty.all<double>(2),
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.blue),
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                          const EdgeInsets.all(15))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Naskenovať kód kamerou',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      Icon(
                        Icons.qr_code_2,
                        color: Colors.white,
                        size: 25,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                OutlinedButton(
                  onPressed: () async {
                    String? res = await scanFile();
                    if (res == 'Wrong file') {
                      QuickAlert.show(
                          context: context,
                          type: QuickAlertType.error,
                          title: 'Kód',
                          text: 'Nepodporovaný súbor! Vyber len obrázok.',
                          confirmBtnText: 'Pokračovať',
                          barrierDismissible: false,
                          onConfirmBtnTap: () async {
                            Navigator.pop(context);
                          });
                    } else {
                      QuickAlert.show(
                          context: context,
                          type: QuickAlertType.success,
                          title: 'Kód',
                          text: 'Nájdený kód: $res',
                          confirmBtnText: 'Pokračovať',
                          barrierDismissible: false,
                          onConfirmBtnTap: () async {
                            Navigator.pop(context);
                          });
                      cardToUpload.cardCode = res!;
                      textController.text = cardToUpload.cardCode;
                    }
                  },
                  style: ButtonStyle(
                      elevation: MaterialStateProperty.all<double>(2),
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.blue),
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                          const EdgeInsets.all(15))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Prečítať kód z obrázku',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      Icon(
                        Icons.image,
                        color: Colors.white,
                        size: 25,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: ButtonStyle(
                      elevation: MaterialStateProperty.all<double>(2),
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.blue),
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                          const EdgeInsets.all(15))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: TextField(
                          maxLines: 1,
                          decoration: const InputDecoration(
                              hintStyle:
                                  TextStyle(fontSize: 20, color: Colors.white),
                              hintText: 'Vlož kód manuálne'),
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                          controller: textController,
                          onChanged: (value) {
                            cardToUpload.cardCode = value;
                          },
                        ),
                      ),
                      const Icon(
                        Icons.add_card,
                        color: Colors.white,
                        size: 25,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                OutlinedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    bool isInternet =
                        await InternetConnectionChecker().hasConnection;
                    if (isInternet) {
                      if (cardToUpload.cardCode.isEmpty) {
                        QuickAlert.show(
                            context: context,
                            type: QuickAlertType.error,
                            title: 'Nová karta',
                            text: 'Kód karty nemôže byť prázdny!',
                            confirmBtnText: 'Pokračovať',
                            barrierDismissible: false,
                            onConfirmBtnTap: () {
                              Navigator.pop(context);
                            });
                      } else {
                        cardToUpload.cardName = '${shopDetail.shopName} karta';
                        cardToUpload.shopId = shopDetail.shopId;
                        String res = await uploadCard(cardToUpload);
                        if (res == 'uploadSuccess') {
                          QuickAlert.show(
                              context: context,
                              type: QuickAlertType.success,
                              title: 'Nová karta',
                              text: 'Karta vytvorená!',
                              confirmBtnText: 'Pokračovať',
                              barrierDismissible: false,
                              onConfirmBtnTap: () async {
                                navigator.pushNamedAndRemoveUntil(
                                    '/mojekarty', (_) => false);
                              });
                        } else {
                          QuickAlert.show(
                              context: context,
                              type: QuickAlertType.error,
                              title: 'Nová karta',
                              text: 'Problém pri vytváraní karty!',
                              confirmBtnText: 'OK',
                              barrierDismissible: false,
                              onConfirmBtnTap: () {
                                Navigator.pop(context);
                              });
                        }
                      }
                    } else {
                      QuickAlert.show(
                          context: context,
                          type: QuickAlertType.error,
                          title: 'Nová karta',
                          text: 'Nemáš pripojenie na internet!',
                          confirmBtnText: 'OK',
                          barrierDismissible: false,
                          onConfirmBtnTap: () {
                            Navigator.pop(context);
                          });
                    }
                  },
                  style: ButtonStyle(
                      elevation: MaterialStateProperty.all<double>(2),
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green),
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                          const EdgeInsets.all(15))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Vytvoriť kartu',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 25,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
              ],
            ),
          ])),
    );
  }
}

class CardToUpload {
  String cardName;
  String cardDescription;
  String cardCountry;
  int shopId;
  String cardCode;

  CardToUpload(this.cardName, this.cardDescription, this.cardCountry,
      this.shopId, this.cardCode);
}
