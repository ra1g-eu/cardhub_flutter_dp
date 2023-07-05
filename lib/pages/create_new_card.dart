import 'dart:convert';
import 'dart:developer';
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
      try {
        var code = await BarcodeFinder.scanFile(path: file.path);

        return code;
      } catch (e) {
        log(e.toString());
        return 'ErrorReadingCode';
      }
    } else {
      return 'Error';
    }
  } else {
    return 'Wrong file';
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
      backgroundColor: Colors.yellow.shade600,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Nová ${shopDetail.shopName} karta'),
      ),
      //passing in the ListView.builder
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(35)),
                    image: DecorationImage(
                        image: base64ToImage(shopDetail.shopLogo).image),
                  ),
                  child: null,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        //background color of dropdown button
                        border: Border.all(
                            color: Colors.black,
                            width: 1,
                            style: BorderStyle.solid),
                        //border of dropdown button
                        borderRadius: BorderRadius.circular(
                            0), //border raiuds of dropdown button
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 5),
                        child: DropdownButton<String>(
                          borderRadius: BorderRadius.all(Radius.circular(0)),
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.w400),
                          dropdownColor: Colors.white,
                          alignment: Alignment.bottomCenter,
                          elevation: 0,
                          underline: Container(),
                          isExpanded: true,
                          iconSize: 25,
                          value: cardToUpload.cardCountry,
                          icon: const Icon(
                            color: Colors.black,
                            Icons.arrow_drop_down_sharp,
                            size: 30,
                          ),
                          items: <String>['Slovensko', 'Česko']
                              .map((String value) {
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
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            Expanded(
              flex: 0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: TextField(
                  scrollPadding: EdgeInsets.only(
                      bottom:
                          MediaQuery.of(context).viewInsets.bottom + 15 * 4),
                  minLines: 3,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  maxLength: 500,
                  controller: cardDescController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              width: 2,
                              style: BorderStyle.solid,
                              color: Colors.black)),
                      hintText: 'Poznámka ku karte'),
                  onChanged: (value) {
                    cardToUpload.cardDescription = value;
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  '3 možnosti vloženia karty',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 22),
                ),
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            ListTile(
              title: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
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
                              text:
                                  'Kód ${result.toString()} úspešne naskenovaný!',
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
                          minimumSize:
                              MaterialStateProperty.all<Size>(Size(80, 100)),
                          elevation: MaterialStateProperty.all<double>(2),
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.blue),
                          padding:
                              MaterialStateProperty.all<EdgeInsetsGeometry>(
                                  const EdgeInsets.all(15))),
                      child: const Text(
                        textAlign: TextAlign.center,
                        softWrap: true,
                        maxLines: 15,
                        'Naskenovať kód kamerou',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        String? res = await scanFile();
                        print("Res error: $res");
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
                        } else if (res == 'ErrorReadingCode') {
                          QuickAlert.show(
                              context: context,
                              type: QuickAlertType.error,
                              title: 'Kód',
                              text: 'Nedokážem prečítať kód z obrázka.',
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
                          minimumSize:
                              MaterialStateProperty.all<Size>(Size(80, 100)),
                          elevation: MaterialStateProperty.all<double>(2),
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.blue),
                          padding:
                              MaterialStateProperty.all<EdgeInsetsGeometry>(
                                  const EdgeInsets.all(15))),
                      child: Text(
                        textAlign: TextAlign.center,
                        softWrap: true,
                        maxLines: 15,
                        'Prečítať kód z obrázku',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: ButtonStyle(
                          elevation: MaterialStateProperty.all<double>(2),
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.blue),
                          padding:
                              MaterialStateProperty.all<EdgeInsetsGeometry>(
                                  const EdgeInsets.all(15))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: TextField(
                              maxLines: 1,
                              decoration: const InputDecoration(
                                  hintStyle: TextStyle(
                                      fontSize: 20, color: Colors.white),
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
                  )
                ],
              ),
            ),
            SizedBox(
              height: 25,
            ),
            ListTile(
              title: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
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
                            cardToUpload.cardName =
                                '${shopDetail.shopName} karta';
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
                          minimumSize:
                              MaterialStateProperty.all<Size>(Size(60, 30)),
                          elevation: MaterialStateProperty.all<double>(2),
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.green),
                          padding:
                              MaterialStateProperty.all<EdgeInsetsGeometry>(
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
