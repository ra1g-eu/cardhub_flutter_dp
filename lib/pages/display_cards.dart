import 'dart:async';
import 'dart:convert';

import 'package:cardhub/apicalls/get_all_cards.dart';
import 'package:cardhub/database/dbhelper.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:cardhub/structures/cards.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:loader_overlay/loader_overlay.dart';
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
  late bool isFavorite = false;
  late bool sortByTimesClicked = false;
  late String sortCountry = 'Slovensko';
  bool isLoaded = false;
  bool isSearch = false;
  TextEditingController searchQuery = TextEditingController();
  Timer? _debounce;

  getChecks() async {
    final prefs = await SharedPreferences.getInstance();
    isFavorite = prefs.getBool('isFavorite') ?? false;
    sortByTimesClicked = prefs.getBool('sortByTimesClicked') ?? false;
    sortCountry = prefs.getString('sortCountry') ?? '-';
  }

  @override
  initState() {
    isLoaded = false;
    getChecks();
    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return WillPopScope(
      onWillPop: () async {
        bool shouldPop = false;
        final prefs = await SharedPreferences.getInstance();
        String loggedIn = prefs.getString('loginCode')!;
        QuickAlert.show(
            context: context,
            confirmBtnColor: Colors.green,
            type: QuickAlertType.confirm,
            title: 'Odhlásenie',
            text: 'Si prihlásený ako: $loggedIn \n Naozaj sa odhlásiť?',
            confirmBtnText: 'Áno',
            cancelBtnText: 'Nie',
            barrierDismissible: false,
            onConfirmBtnTap: () async {
              final navigator = Navigator.of(context);
              bool result = await InternetConnectionChecker().hasConnection;
              navigator.pop();
              QuickAlert.show(
                  context: context,
                  type: QuickAlertType.success,
                  title: 'Odhlásenie',
                  text: 'Úspešne odhlásený!',
                  confirmBtnText: 'OK',
                  barrierDismissible: false,
                  onConfirmBtnTap: () async {
                    await LogOutApi()
                        .logOutWithCode(prefs.getString('loginCode')!, false);
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
        edgeOffset: 50,
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
        child: LoaderOverlay(
            overlayWholeScreen: true,
            useDefaultLoading: true,
            overlayOpacity: 1,
            overlayColor: Colors.yellow,
            child: Scaffold(
                backgroundColor: Colors.yellow.shade600,
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
                            onTap: () async {
                              Trace sortCountryButtonTrace =
                                  FirebasePerformance.instance.newTrace(
                                      'pages/display_cards/sortCountryButtonTrace');
                              await sortCountryButtonTrace.start();
                              final prefs =
                                  await SharedPreferences.getInstance();

                              if (prefs.containsKey('sortCountry')) {
                                prefs.setString(
                                    'sortCountry',
                                    sortCountry == 'Slovensko'
                                        ? 'Česko'
                                        : 'Slovensko');
                                setState(() {
                                  sortCountry = prefs.getString('sortCountry')!;
                                });
                              } else {
                                setState(() {
                                  prefs.setString('sortCountry', 'Česko');
                                  sortCountry = 'Česko';
                                });
                              }
                              print(sortCountry);
                              await sortCountryButtonTrace.stop();
                            },
                            child: Padding(
                                padding: EdgeInsets.all(10.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  verticalDirection: VerticalDirection.down,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.currency_exchange,
                                        size: 30, color: Colors.white),
                                    Text(
                                      sortCountry == '-'
                                          ? 'Krajina'
                                          : sortCountry == 'Slovensko'
                                              ? 'Slovensko'
                                              : 'Česko',
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
                              Trace sortPopularButtonTrace =
                                  FirebasePerformance.instance.newTrace(
                                      'pages/display_cards/sortPopularButtonTrace');
                              await sortPopularButtonTrace.start();
                              final prefs =
                                  await SharedPreferences.getInstance();

                              if (prefs.containsKey('sortByTimesClicked')) {
                                prefs.setBool('sortByTimesClicked',
                                    sortByTimesClicked ? false : true);
                                setState(() {
                                  sortByTimesClicked =
                                      prefs.getBool('sortByTimesClicked')!;
                                });
                              } else {
                                setState(() {
                                  prefs.setBool('sortByTimesClicked', true);
                                  sortByTimesClicked = true;
                                });
                              }
                              await sortPopularButtonTrace.stop();
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
                              Trace sortFavoriteButtonTrace =
                                  FirebasePerformance.instance.newTrace(
                                      'pages/display_cards/sortFavoriteButtonTrace');
                              await sortFavoriteButtonTrace.start();
                              final prefs =
                                  await SharedPreferences.getInstance();

                              if (prefs.containsKey('isFavorite')) {
                                prefs.setBool(
                                    'isFavorite', isFavorite ? false : true);
                                setState(() {
                                  isFavorite = prefs.getBool('isFavorite')!;
                                });
                              } else {
                                setState(() {
                                  prefs.setBool('isFavorite', true);
                                  isFavorite = true;
                                });
                              }
                              await sortFavoriteButtonTrace.stop();
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
                                        color: isFavorite
                                            ? Colors.redAccent.shade400
                                            : Colors.white),
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
                  backgroundColor: Colors.black,
                  automaticallyImplyLeading: false,
                  title: isSearch
                      ? TextField(
                          onChanged: (value) {
                            if (_debounce?.isActive ?? false) {
                              _debounce?.cancel();
                            }
                            _debounce =
                                Timer(const Duration(milliseconds: 900), () {
                              setState(() {});
                              print(searchQuery.text);
                            });
                          },
                          autofocus: true,
                          maxLines: 1,
                          controller: searchQuery,
                          style: TextStyle(color: Colors.white, fontSize: 19),
                          decoration: const InputDecoration(
                              hintStyle:
                                  TextStyle(color: Colors.white, fontSize: 19),
                              border: UnderlineInputBorder(),
                              hintText: 'Názov karty...'),
                        )
                      : Text(
                          'Moje karty ${sortCountry == 'Slovensko' ? ' - Slovensko' : ' - Česko'}'),
                  actions: [
                    IconButton(
                        onPressed: () async {
                          Trace searchCard = FirebasePerformance.instance
                              .newTrace('pages/display_cards/searchForCard');
                          await searchCard.start();

                          setState(() {
                            isSearch = !isSearch;
                          });
                          searchQuery.text = '';
                          await searchCard.stop();
                        },
                        icon: const Icon(Icons.search)),
                    IconButton(
                      onPressed: () {
                        Navigator.maybePop(context);
                      },
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
                //passing in the ListView.builder
                body: FutureBuilder<List<Cards>>(
                    future: fetchCardsFromDatabase(),
                    builder: (context, snapshot) {
                      if (!isLoaded) {
                        context.loaderOverlay.show();
                      }
                      if (snapshot.hasData) {
                        Future.delayed(
                          const Duration(milliseconds: 800),
                          () {
                            context.loaderOverlay.hide();
                            isLoaded = true;
                          },
                        );

                        List<Cards> newCards = snapshot.data!;
                        if (searchQuery.text != '') {
                          newCards = newCards
                              .where((item) => item.cardName
                                  .toUpperCase()
                                  .contains(searchQuery.text.toUpperCase()))
                              .toList();
                        }

                        if (isFavorite) {
                          newCards = newCards
                              .where((item) => item.isFavorite == true)
                              .toList();
                        } else {
                          newCards = newCards
                              .where((item) => item.isFavorite == false)
                              .toList();
                        }
                        if (sortByTimesClicked) {
                          newCards.sort((a, b) =>
                              b.timesClicked.compareTo(a.timesClicked));
                        }
                        if (!sortByTimesClicked) {
                          newCards.sort((a, b) =>
                              a.timesClicked.compareTo(b.timesClicked));
                        }
                        if (sortCountry == 'Slovensko') {
                          newCards = newCards
                              .where((item) => item.countryName == 'Slovensko')
                              .toList();
                        }
                        if (sortCountry == 'Česko') {
                          newCards = newCards
                              .where((item) => item.countryName == 'Česko')
                              .toList();
                        }
                        if (newCards.isEmpty) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 200, 0, 0),
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  Container(
                                    alignment: AlignmentDirectional.center,
                                    child: isFavorite
                                        ? Text(
                                            'Nemáš žiadne obľúbené karty! Skús si nejaké pridať.')
                                        : Text(
                                            'Nemáš žiadne karty! Skús pozrieť obľúbené karty.'),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                        return GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 200,
                                    childAspectRatio: 2 / 2,
                                    crossAxisSpacing: 5,
                                    mainAxisSpacing: 5,
                                    mainAxisExtent: 250),
                            itemCount: newCards.length,
                            itemBuilder: (BuildContext ctx, index) {
                              return GestureDetector(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 15),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.black,
                                        border: Border.all(),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5))),
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8),
                                    child: Column(
                                      children: <Widget>[
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 3),
                                          alignment: Alignment.topLeft,
                                          child: Text(
                                            newCards[index].cardName,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 21,
                                                overflow: TextOverflow.fade),
                                            textAlign: TextAlign.start,
                                            overflow: TextOverflow.fade,
                                            softWrap: false,
                                          ),
                                        ),
                                        Center(
                                          child: Image(
                                            image: base64ToImage(
                                                    newCards[index].shopLogo)
                                                .image,
                                            fit: BoxFit.fitWidth,
                                            height: 130,
                                            isAntiAlias: true,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                onTap: () async {
                                  await DBHelper().updateTimesClicked(
                                      newCards[index].cardUuid);
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
                        context.loaderOverlay.hide();
                        return Container(
                            alignment: AlignmentDirectional.center,
                            child: Text(snapshot.error.toString()));
                      }

                      return Container(
                          alignment: AlignmentDirectional.center,
                          child: const CircularProgressIndicator());
                    }))),
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
