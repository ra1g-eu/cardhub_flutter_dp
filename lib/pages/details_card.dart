import 'dart:convert';
import 'dart:io';

import 'package:barcode_finder/barcode_finder.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardhub/database/dbhelper.dart';
import 'package:cardhub/pages/webview_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/material.dart';
import 'package:cardhub/structures/cards.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../apicalls/delete_card.dart';
import 'display_cards.dart';

Future<List<Cards>> fetchCardFromDatabase(String cardUuid) async {
  var dbHelper = DBHelper();
  Future<List<Cards>> card = dbHelper.getSingleCard(cardUuid);
  return card;
}

Future<String> deleteCardFromDatabase(String cardUuid) async {
  final prefs = await SharedPreferences.getInstance();
  String result = await DeleteCard()
      .deleteCardWithCode(prefs.getString('loginCode')!, cardUuid);
  return result;
}

Future<bool> isFavorite(String cardUuid) async {
  bool isFavorite = await DBHelper().isCardFavorite(cardUuid);
  return isFavorite;
}

Future<void> incrementTimesClicked(String cardUuid) async {}

Barcode selectBarcode(bool isQRCode) {
  if (isQRCode) {
    return Barcode.qrCode();
  } else {
    return Barcode.code128();
  }
}

Image base64ToImage(String base64) {
  return Image.memory(
    base64Decode(base64),
    height: double.infinity,
    width: double.infinity,
    alignment: Alignment.center,
  );
}

class DetailCard extends StatefulWidget {
  const DetailCard({Key? key}) : super(key: key);

  @override
  DetailCardState createState() => DetailCardState();
}

class DetailCardState extends State<DetailCard>
    with SingleTickerProviderStateMixin {
  late Animation<double> _animation;
  late AnimationController _animationController;

  bool isQRCode = true;
  bool isCardFavorite = false;
  TextEditingController cardDescController = TextEditingController();
  TextEditingController textController = TextEditingController();
  late final CardToEdit cardToEdit;
  String cardNotes = '';
  String cardUrl = '';
  late final CardDetail cardDetails;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      cardDetails = ModalRoute.of(context)?.settings.arguments as CardDetail;

      isCardFavorite = await isFavorite(cardDetails.cardUuid);
      setState(() {});
    });

    isQRCode = true;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    final curvedAnimation =
        CurvedAnimation(curve: Curves.easeInOut, parent: _animationController);
    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final CardDetail cardDetail =
        ModalRoute.of(context)?.settings.arguments as CardDetail;
    return Scaffold(
        bottomNavigationBar: Container(
          color: Colors.black,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Material(
                type: MaterialType.transparency,
                child: Ink(
                  child: InkWell(
                    onTap: () {
                      QuickAlert.show(
                          context: context,
                          cancelBtnTextStyle: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                          showCancelBtn: true,
                          type: QuickAlertType.warning,
                          title: cardDetail.cardName,
                          text:
                              'Naozaj vymazať túto kartu? Vymaže sa pre všetkých používateľov.',
                          confirmBtnText: 'Vymazať',
                          cancelBtnText: 'Nie',
                          barrierDismissible: true,
                          onConfirmBtnTap: () async {
                            Navigator.pop(context);
                            bool isInternet =
                                await InternetConnectionChecker().hasConnection;
                            if (isInternet) {
                              String result = await deleteCardFromDatabase(
                                  cardDetail.cardUuid);
                              if (result == 'deleteSuccess') {
                                QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.success,
                                    title: 'Karty',
                                    text: 'Karta úspešne vymazaná!',
                                    confirmBtnText: 'Pokračovať',
                                    barrierDismissible: false,
                                    onConfirmBtnTap: () {
                                      Navigator.pop(context);
                                      Navigator.of(context).pop(true);
                                    });
                              } else if (result == 'deleteFail') {
                                QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.error,
                                    title: 'Karty',
                                    text: 'Karta nebola vymazaná!',
                                    confirmBtnText: 'Pokračovať',
                                    barrierDismissible: false,
                                    onConfirmBtnTap: () {
                                      Navigator.pop(context);
                                    });
                              } else {
                                QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.error,
                                    title: 'Karty',
                                    text: 'Karta nemohla byť vymazaná!',
                                    confirmBtnText: 'Pokračovať',
                                    barrierDismissible: false,
                                    onConfirmBtnTap: () {
                                      Navigator.pop(context);
                                    });
                              }
                            } else {
                              QuickAlert.show(
                                  context: context,
                                  type: QuickAlertType.error,
                                  title: 'Karta',
                                  text: 'Nemáš pripojenie na internet!',
                                  confirmBtnText: 'Pokračovať',
                                  barrierDismissible: false,
                                  onConfirmBtnTap: () {
                                    Navigator.pop(context);
                                  });
                            }
                          },
                          onCancelBtnTap: () {
                            Navigator.pop(context);
                          });
                    },
                    child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          verticalDirection: VerticalDirection.down,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.delete_forever,
                                size: 30, color: Colors.white),
                            Text(
                              "Vymazať",
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            )
                          ],
                        )),
                  ),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: Ink(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => WebViewPage(url: cardUrl)));
                    },
                    child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          verticalDirection: VerticalDirection.down,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.open_in_new,
                                size: 30, color: Colors.white),
                            Text(
                              "Letáky",
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            )
                          ],
                        )),
                  ),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: Ink(
                  child: InkWell(
                    onTap: () {
                      cardNotes.isEmpty
                          ? QuickAlert.show(
                              context: context,
                              type: QuickAlertType.warning,
                              title: 'Poznámky',
                              text: 'Táto karta nemá žiadne poznámky!',
                              confirmBtnText: 'Zatvoriť')
                          : showGeneralDialog(
                              barrierDismissible: false,
                              context: context,
                              transitionDuration: Duration(milliseconds: 200),
                              pageBuilder: (bc, ania, anis) {
                                return SizedBox.expand(
                                  child: Container(
                                    height: MediaQuery.of(context).size.height,
                                    color: Colors.black,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 65, 0, 0),
                                      child: Card(
                                        color: Colors.black,
                                        elevation: 0,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            const ListTile(
                                              leading: Icon(
                                                Icons.notes,
                                                color: Colors.white,
                                                size: 30,
                                              ),
                                              title: Text(
                                                'Poznámky',
                                                style: TextStyle(
                                                    fontSize: 23,
                                                    color: Colors.white),
                                              ),
                                            ),
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 15,
                                                      vertical: 25),
                                              alignment: Alignment.topLeft,
                                              child: Text(
                                                cardNotes,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18),
                                              ),
                                            ),
                                            Expanded(
                                              child: Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: ButtonBar(
                                                  children: <Widget>[
                                                    OutlinedButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      style: OutlinedButton.styleFrom(
                                                          padding:
                                                              const EdgeInsets
                                                                      .symmetric(
                                                                  horizontal:
                                                                      25,
                                                                  vertical: 10),
                                                          backgroundColor:
                                                              Colors.yellow
                                                                  .shade600,
                                                          foregroundColor:
                                                              Colors.blue),
                                                      child: const Text(
                                                        'Zatvoriť',
                                                        style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 19),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              });
                    },
                    child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          verticalDirection: VerticalDirection.down,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.comment, size: 30, color: Colors.white),
                            Text(
                              "Poznámky",
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            )
                          ],
                        )),
                  ),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: Ink(
                  child: InkWell(
                    onTap: () async {
                      setState(() => isCardFavorite = !isCardFavorite);
                      await DBHelper()
                          .setCardFavorite(cardDetail.cardUuid, isCardFavorite);
                    },
                    child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          verticalDirection: VerticalDirection.down,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCardFavorite
                                  ? Icons.favorite_outlined
                                  : Icons.favorite_border_outlined,
                              size: 30,
                              color: isCardFavorite
                                  ? Colors.redAccent.shade200
                                  : Colors.white,
                            ),
                            const Text(
                              "Obľúbené",
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            )
                          ],
                        )),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: cardDetail.isManualCode
            ? FloatingActionButton(
                onPressed: () {
                  setState(() {
                    isQRCode = !isQRCode;
                  });
                },
                backgroundColor: Colors.black,
                child: Icon(
                  !isQRCode ? Icons.qr_code : Icons.numbers,
                  color: Colors.white,
                ),
              )
            : null,
        backgroundColor: Colors.yellow.shade600,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(cardDetail.cardName),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, "/detailkartyedit",
                    arguments:
                        CardToEdit(cardDetail.cardUuid, cardDetail.cardName));
              },
              icon: const Icon(Icons.edit_note_sharp, size: 25),
            )
          ],
        ),
        //passing in the ListView.builder
        body: FutureBuilder<List<Cards>>(
            future: fetchCardFromDatabase(cardDetail.cardUuid),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                cardNotes = snapshot.data![0].cardNotes;
                cardUrl = snapshot.data![0].countryName == 'Slovensko'
                    ? snapshot.data![0].shopUrlSk
                    : snapshot.data![0].shopUrlCz;
                return cardDetail.isManualCode
                    ? InteractiveViewer(
                        panEnabled: true,
                        // Set it to false to prevent panning.
                        boundaryMargin: const EdgeInsets.all(2),
                        minScale: 0.5,
                        maxScale: 4,
                        child: BarcodeWidget(
                          padding: const EdgeInsets.all(90),
                          barcode: selectBarcode(isQRCode),
                          // Barcode type and settings
                          data: snapshot.data![0].manualCode,
                          // Content
                          width: double.infinity,
                          height: !isQRCode ? 350 : double.infinity,
                        ),
                      )
                    : InteractiveViewer(
                        panEnabled: true,
                        // Set it to false to prevent panning.
                        boundaryMargin: const EdgeInsets.all(2),
                        minScale: 0.5,
                        maxScale: 4,
                        child: base64ToImage(snapshot.data![0].cardImage),
                      );
              } else if (snapshot.hasError) {
                return Container(
                    alignment: AlignmentDirectional.center,
                    child: Text(snapshot.error.toString()));
              }
              return Container(
                  alignment: AlignmentDirectional.center,
                  child: const CircularProgressIndicator());
            }));
  }
}

class CardToEdit {
  String cardName;
  String cardUuid;
  String cardNotes;
  String cardManualCode;

  CardToEdit(this.cardUuid, this.cardName,
      [this.cardNotes = '', this.cardManualCode = '']);
}
