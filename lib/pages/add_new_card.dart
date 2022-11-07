import 'dart:convert';

import 'package:cardhub/database/dbhelper.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../apicalls/get_shops.dart';
import '../structures/shops.dart';

Future<List<Shops>> fetchShopsFromDatabase() async {
  var dbHelper = DBHelper();
  Future<List<Shops>> shops = dbHelper.getShops();
  return shops;
}

Future<String> fetchNewShopsFromApi() async {
  final prefs = await SharedPreferences.getInstance();
  String result =
      await GetAllShops().getShopsWithCode(prefs.getString('loginCode')!);
  return result;
}

Image base64ToImage(String base64) {
  return Image.memory(
    height: 100,
    width: 100,
    base64Decode(base64),
    fit: BoxFit.contain,
  );
}

class AddNewCard extends StatefulWidget {
  const AddNewCard({Key? key}) : super(key: key);

  @override
  AddNewCardState createState() => AddNewCardState();
}

class AddNewCardState extends State<AddNewCard> {
  late ShopDetail shopDetail;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        bool isInternet = await InternetConnectionChecker().hasConnection;
        if (isInternet) {
          String result = await fetchNewShopsFromApi();
          if (result == 'shopsSuccess') {
            setState(() {});
            QuickAlert.show(
                context: context,
                type: QuickAlertType.success,
                title: 'Obchody',
                text: 'Obchody aktualizované!',
                confirmBtnText: 'Pokračovať',
                barrierDismissible: false,
                onConfirmBtnTap: () async {
                  Navigator.pop(context);
                });
          } else {
            QuickAlert.show(
                context: context,
                type: QuickAlertType.error,
                title: 'Obchody',
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
              title: 'Obchody',
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
          appBar: AppBar(
            automaticallyImplyLeading: true,
            title: const Text('Vytvorenie karty'),
          ),
          //passing in the ListView.builder
          body: FutureBuilder<List<Shops>>(
              future: fetchShopsFromDatabase(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!.isEmpty) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        ListView(
                          padding: EdgeInsets.fromLTRB(0, 200, 0, 0),
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Container(
                              alignment: AlignmentDirectional.center,
                              child:
                                  Text('Potiahni dole pre načítanie obchodov!'),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 250,
                              childAspectRatio: 1,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10),
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, "/novakartadetail",
                                arguments: ShopDetail(
                                    snapshot.data![index].shopId,
                                    snapshot.data![index].shopName,
                                    snapshot.data![index].shopLogo));
                          },
                          child: Card(
                            elevation: 5,
                            shadowColor: Colors.black,
                            clipBehavior: Clip.antiAlias,
                            child: Container(
                                height: 75,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ClipOval(
                                        child: base64ToImage(
                                            snapshot.data![index].shopLogo),
                                      ),
                                      ListTile(
                                        title: Text(
                                          snapshot.data![index].shopName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 19,
                                              letterSpacing: 1.1,
                                              fontFamily: 'Roboto'),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ])),
                          ),
                        );
                      },
                    );
                  }
                } else if (snapshot.hasError) {
                  return Container(
                      alignment: AlignmentDirectional.center,
                      child: Text(snapshot.error.toString()));
                }
                return Container(
                    alignment: AlignmentDirectional.center,
                    child: const CircularProgressIndicator());
              })),
    );
  }
}

class ShopDetail {
  final int shopId;
  final String shopName;
  final String shopLogo;

  ShopDetail(this.shopId, this.shopName, this.shopLogo);
}
