import 'package:cardhub/apicalls/edit_card.dart';
import 'package:cardhub/database/dbhelper.dart';
import 'package:flutter/material.dart';
import 'package:cardhub/structures/cards.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'details_card.dart';
import 'display_cards.dart';

Future<List<Cards>> fetchCardFromDatabase(String cardUuid) async {
  var dbHelper = DBHelper();
  Future<List<Cards>> card = dbHelper.getCardForEdit(cardUuid);
  return card;
}

Future<String> editCard(String cardUuid, CardToEdit cardToEdit) async {
  final prefs = await SharedPreferences.getInstance();
  String result =
      await EditCard().EditCardToDB(prefs.getString('loginCode')!, cardToEdit);
  return result;
}

class EditExistingCard extends StatefulWidget {
  const EditExistingCard({Key? key}) : super(key: key);

  @override
  EditExistingCardState createState() => EditExistingCardState();
}

class EditExistingCardState extends State<EditExistingCard> {
  TextEditingController cardDescController = TextEditingController();
  TextEditingController textController = TextEditingController();
  late final CardToEdit cardToEdit;
  String newCode = 'x';

  @override
  Widget build(BuildContext context) {
    final CardToEdit cardToEdit =
        ModalRoute.of(context)?.settings.arguments as CardToEdit;
    return Scaffold(
        backgroundColor: Colors.yellow.shade600,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text("Úprava ${cardToEdit.cardName}"),
        ),
        //passing in the ListView.builder
        body: FutureBuilder<List<Cards>>(
            future: fetchCardFromDatabase(cardToEdit.cardUuid),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                cardToEdit.cardUuid = snapshot.data![0].cardUuid;
                cardToEdit.cardManualCode = snapshot.data![0].manualCode;
                cardToEdit.cardNotes = snapshot.data![0].cardNotes;
                cardDescController.text = cardToEdit.cardNotes;
                return Material(
                  color: Colors.yellow.shade600,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 15),
                            child: TextField(
                              scrollPadding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom +
                                          15 * 4),
                              minLines: 3,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              maxLength: 500,
                              style:
                                  TextStyle(fontSize: 20, color: Colors.black),
                              controller: cardDescController,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Vlož doplňujúce informácie karty',
                                  hintStyle: TextStyle(
                                      fontSize: 20, color: Colors.black)),
                              onChanged: (value) {
                                cardToEdit.cardNotes = value;
                              },
                            ),
                          ),
                        ),
                        Expanded(
                            flex: 0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 15),
                              child: TextField(
                                maxLines: 1,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.black, width: 2)),
                                    hintStyle: TextStyle(
                                        fontSize: 20, color: Colors.black),
                                    hintText: cardToEdit.cardManualCode),
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                ),
                                controller: textController,
                                onChanged: (value) {
                                  newCode = value;
                                  print("it change");
                                },
                              ),
                            )),
                        SizedBox(
                          height: 25,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.all(15),
                                  backgroundColor: Colors.green,
                                  // side: BorderSide(color: Colors.yellow, width: 5),
                                  textStyle: const TextStyle(
                                      color: Colors.white, fontSize: 23, fontStyle: FontStyle.normal),
                                  shape: BeveledRectangleBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(4))),
                                  shadowColor: Colors.lightBlue,
                                ),
                                onPressed: () async{
                                  if(newCode.isNotEmpty){
                                    bool isInternet = await InternetConnectionChecker().hasConnection;
                                    if(isInternet){
                                      if(newCode == 'x'){
                                        cardToEdit.cardManualCode = cardToEdit.cardManualCode;
                                      } else {
                                        cardToEdit.cardManualCode = newCode;
                                      }
                                      final prefs = await SharedPreferences.getInstance();
                                      String editResult = await editCard(prefs.getString('loginCode')!, cardToEdit);
                                      print(editResult);
                                      if(editResult == "editSuccess"){
                                        QuickAlert.show(
                                            context: context,
                                            type: QuickAlertType.success,
                                            title: 'Editácia karty',
                                            text: 'Karta úspešne editovaná!',
                                            confirmBtnText: 'Pokračovať',
                                            barrierDismissible: false,
                                            onConfirmBtnTap: () {
                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                            });
                                      } else {
                                        QuickAlert.show(
                                            context: context,
                                            type: QuickAlertType.error,
                                            title: 'Editácia karty',
                                            text: 'Vyskytol sa problém!',
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
                                          title: 'Editácia karty',
                                          text: 'Nemáš pripojenie na internet!',
                                          confirmBtnText: 'Pokračovať',
                                          barrierDismissible: false,
                                          onConfirmBtnTap: () {
                                            Navigator.pop(context);
                                          });
                                    }
                                  } else if(textController.text.isEmpty) {
                                    QuickAlert.show(
                                        context: context,
                                        type: QuickAlertType.error,
                                        title: 'Editácia karty',
                                        text: 'Kód karty nemôže byť prázdny!',
                                        confirmBtnText: 'Rozumiem',
                                        barrierDismissible: false,
                                        onConfirmBtnTap: () {
                                          Navigator.pop(context);
                                        });
                                  } else {
                                    QuickAlert.show(
                                        context: context,
                                        type: QuickAlertType.warning,
                                        title: 'Editácia karty',
                                        text: 'Žiadne zmeny neboli vykonané',
                                        confirmBtnText: 'Pokračovať',
                                        barrierDismissible: false,
                                        onConfirmBtnTap: () {
                                          Navigator.pop(context);
                                        });
                                  }
                                },
                                child: Text("Uložiť")),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.all(15),
                                  backgroundColor: Colors.black,
                                  // side: BorderSide(color: Colors.yellow, width: 5),
                                  textStyle: const TextStyle(
                                      color: Colors.white, fontSize: 20, fontStyle: FontStyle.normal),
                                  shape: BeveledRectangleBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(4))),
                                  shadowColor: Colors.lightBlue,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text("Zatvoriť")),
                          ],
                        ),
                      ],
                    ),
                  ),
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
