import 'dart:convert';

import 'package:cardhub/apicalls/get_all_cards.dart';
import 'package:cardhub/database/dbhelper.dart';
import 'package:flutter/material.dart';
import 'package:cardhub/structures/cards.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../apicalls/logout.dart';

Future<List<Cards>> fetchCardsFromDatabase() async {
  var dbHelper = DBHelper();
  Future<List<Cards>> cards;
  cards = dbHelper.getCardsWithExtraInfo();
  return cards;
}

Future<String> fetchNewCardsFromApi() async {
  final prefs = await SharedPreferences.getInstance();
  String result =
      await GetAllCards().getCardsWithCode(prefs.getString('loginCode')!);
  return result;
}

Image base64ToImage(String base64) {
  return Image.memory(base64Decode(base64));
}

class DisplayCard extends StatefulWidget {
  const DisplayCard({Key? key}) : super(key: key);

  @override
  DisplayCardState createState() => DisplayCardState();
}

class DisplayCardState extends State<DisplayCard> {
  bool isFavorite = false;
  bool sortByTimesClicked = false;
  String sortCountry = 'Slovensko';

  void checkFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    isFavorite = prefs.getBool('isFavorite') ?? false;
  }

  void checkIfSort() async {
    final prefs = await SharedPreferences.getInstance();
    sortByTimesClicked = prefs.getBool('sortByTimesClicked') ?? false;
  }

  void checkCountry() async{
    final prefs = await SharedPreferences.getInstance();
    sortCountry = prefs.getString('sortCountry') ?? '-';
  }

  @override
  void initState() {
    checkFavorite();
    checkIfSort();
    checkCountry();
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return WillPopScope(
      onWillPop: () async{
        bool shouldPop = false;
        QuickAlert.show(
            context: context,
            confirmBtnColor: Colors.green,
            type: QuickAlertType.confirm,
            title: 'Odhlásenie',
            text: 'Naozaj sa odhlásiť?',
            confirmBtnText: 'Áno',
            cancelBtnText: 'Nie',
            barrierDismissible: false,
            onConfirmBtnTap: () async {
              final navigator = Navigator.of(context);
              bool result =
              await InternetConnectionChecker().hasConnection;
              final prefs = await SharedPreferences.getInstance();
              navigator.pop();
              QuickAlert.show(
                  context: context,
                  type: QuickAlertType.success,
                  title: 'Odhlásenie',
                  text: 'Úspešne odhlásený!',
                  confirmBtnText: 'OK',
                  barrierDismissible: false,
                  onConfirmBtnTap: () async {
                    await LogOutApi().logOutWithCode(
                        prefs.getString('loginCode')!, false);
                    await prefs.clear();
                    if (!result) {
                      await prefs.setString(
                          'lateLogOut', prefs.getString('loginCode')!);
                    }
                    shouldPop = true;
                    navigator.pushNamedAndRemoveUntil(
                        '/homePage', (_) => false);
                  });
            },
            onCancelBtnTap: () {
              final navigator = Navigator.of(context);
              navigator.pop(context);
              shouldPop = false;
            });
        return shouldPop;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          bool isInternet = await InternetConnectionChecker().hasConnection;
          if (isInternet) {
            String result = await fetchNewCardsFromApi();
            if (result == 'cardsSuccess') {
              setState(() {});
              QuickAlert.show(
                  context: context,
                  type: QuickAlertType.success,
                  title: 'Karty',
                  text: 'Karty aktualizované!',
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
                title: 'Karty',
                text: 'Nemáš pripojenie na internet!',
                confirmBtnText: 'Pokračovať',
                barrierDismissible: false,
                onConfirmBtnTap: () {
                  Navigator.pop(context);
                });
          }
        },
        triggerMode: RefreshIndicatorTriggerMode.onEdge,
        child: Scaffold(
            bottomNavigationBar: Container(
              color: Colors.blue,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    type: MaterialType.transparency,
                    child: Ink(
                      child: InkWell(
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();

                          if (prefs.containsKey('sortCountry')) {
                            prefs.setString(
                                'sortCountry', sortCountry == 'Slovensko' ? 'Česko' : 'Slovensko');
                            setState(() {
                              sortCountry = prefs.getString('sortCountry')!;
                            });
                          } else {
                            setState(() {
                              prefs.setString(
                                  'sortCountry', 'Česko');
                              sortCountry = 'Česko';
                            });
                          }
                          print(sortCountry);
                        },
                        child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              verticalDirection: VerticalDirection.down,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.currency_exchange,
                                    size: 30,
                                    color: Colors.white),
                                Text(
                                  sortCountry == '-' ? 'Krajina' : sortCountry == 'Slovensko' ? 'Slovensko' : 'Česko',
                                  style: const TextStyle(
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
                          final prefs = await SharedPreferences.getInstance();

                          if (prefs.containsKey('sortByTimesClicked')) {
                            prefs.setBool(
                                'sortByTimesClicked', sortByTimesClicked ? false : true);
                            setState(() {
                              sortByTimesClicked = prefs.getBool('sortByTimesClicked')!;
                            });
                          } else {
                            setState(() {
                              prefs.setBool(
                                  'sortByTimesClicked', true);
                              sortByTimesClicked = true;
                            });
                          }
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
                                    sortByTimesClicked
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    size: 30,
                                    color: Colors.white),
                                const Text(
                                  "Zoradenie",
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
                          final prefs = await SharedPreferences.getInstance();

                          if (prefs.containsKey('isFavorite')) {
                            prefs.setBool(
                                'isFavorite', isFavorite ? false : true);
                            setState(() {
                              isFavorite = prefs.getBool('isFavorite')!;
                            });
                          } else {
                            setState(() {
                              prefs.setBool(
                                  'isFavorite', true);
                              isFavorite = true;
                            });
                          }
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
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_outline,
                                    size: 30,
                                    color: isFavorite ? Colors.redAccent.shade400 : Colors.white),
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
                  Material(
                    type: MaterialType.transparency,
                    child: Ink(
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, "/novakarta");
                        },
                        child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              verticalDirection: VerticalDirection.down,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.add_card_outlined,
                                    size: 30, color: Colors.white),
                                Text(
                                  "Nová karta",
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
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text('Moje karty ${sortCountry == 'Slovensko' ? ' - Slovensko' : ' - Česko'}'),
              actions: [
                IconButton(
                    onPressed: () {
                      QuickAlert.show(
                          context: context,
                          confirmBtnColor: Colors.green,
                          type: QuickAlertType.confirm,
                          title: 'Odhlásenie',
                          text: 'Naozaj sa odhlásiť?',
                          confirmBtnText: 'Áno',
                          cancelBtnText: 'Nie',
                          barrierDismissible: false,
                          onConfirmBtnTap: () async {
                            final navigator = Navigator.of(context);
                            bool result =
                            await InternetConnectionChecker().hasConnection;
                            final prefs = await SharedPreferences.getInstance();
                            navigator.pop();
                            QuickAlert.show(
                                context: context,
                                type: QuickAlertType.success,
                                title: 'Odhlásenie',
                                text: 'Úspešne odhlásený!',
                                confirmBtnText: 'OK',
                                barrierDismissible: false,
                                onConfirmBtnTap: () async {
                                  await LogOutApi().logOutWithCode(
                                      prefs.getString('loginCode')!, false);
                                  await prefs.clear();
                                  if (!result) {
                                    await prefs.setString(
                                        'lateLogOut', prefs.getString('loginCode')!);
                                  }
                                  navigator.pushNamedAndRemoveUntil(
                                      '/homePage', (_) => false);
                                });
                          },
                          onCancelBtnTap: () {
                            final navigator = Navigator.of(context);
                            navigator.pop(context);
                          });
                    },
                    icon: const Icon(Icons.logout))
              ],
            ),
            //passing in the ListView.builder
            body: FutureBuilder<List<Cards>>(
                future: fetchCardsFromDatabase(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<Cards> newCards = snapshot.data!;

                    if(isFavorite){
                      newCards = newCards.where((item) => item.isFavorite == true).toList();
                    } else {
                      newCards = newCards.where((item) => item.isFavorite == false).toList();
                    }
                    if(sortByTimesClicked){
                      newCards.sort((a, b) => b.timesClicked.compareTo(a.timesClicked));
                    }
                    if(!sortByTimesClicked) {
                      newCards.sort((a, b) => a.timesClicked.compareTo(b.timesClicked));
                    }
                    if(sortCountry == 'Slovensko'){
                      newCards = newCards.where((item) => item.countryName == 'Slovensko').toList();
                    }
                    if(sortCountry == 'Česko'){
                      newCards = newCards.where((item) => item.countryName == 'Česko').toList();
                    }
                    if (newCards.isEmpty) {
                      return Container(
                          alignment: AlignmentDirectional.center,
                          child: isFavorite ? Text('Nemáš žiadne obľúbené karty! Skús si nejaké pridať.') : Text('Nemáš žiadne karty! Skús pozrieť obľúbené karty.'));
                    }
                    return GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 2 / 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 1),
                        itemCount: newCards.length,
                        itemBuilder: (BuildContext ctx, index) {
                          return GestureDetector(
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(55),
                                    image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: base64ToImage(
                                            newCards[index].shopLogo)
                                            .image)),
                              ),
                            ),
                            onTap: () async{
                              await DBHelper().updateTimesClicked(newCards[index].cardUuid);
                              navigator.pushNamed("/detailkarty",
                                  arguments: CardDetail(
                                      newCards[index].cardUuid,
                                      ("${newCards[index].cardName} (${newCards[index].countryName})"),
                                      newCards[index].cardImage == '--'
                                          ? true
                                          : false));
                            },
                          );
                        });
                  } else if (snapshot.hasError) {
                    return Container(
                        alignment: AlignmentDirectional.center,
                        child: Text(snapshot.error.toString()));
                  }
                  return Container(
                      alignment: AlignmentDirectional.center,
                      child: const CircularProgressIndicator());
                })),
      ),
    );
  }
}

class CardDetail {
  final String cardUuid;
  final String cardName;
  final bool isManualCode;

  CardDetail(this.cardUuid, this.cardName, this.isManualCode);
}
