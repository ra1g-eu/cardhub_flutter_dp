import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:cardhub/apicalls/logout.dart';
import 'package:cardhub/pages/add_new_card.dart';
import 'package:cardhub/pages/codescanner.dart';
import 'package:cardhub/pages/create_new_card.dart';
import 'package:cardhub/pages/details_card.dart';
import 'package:cardhub/pages/display_cards.dart';
import 'package:cardhub/pages/edit_existing_card.dart';
import 'package:cardhub/pages/webview_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'apicalls/login_api.dart';
import 'apicalls/register_api.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android,
  );


  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  Trace sharedPrefsTrace = FirebasePerformance.instance.newTrace('main/main()/SharedPrefsGetInstance');
  await sharedPrefsTrace.start();
  final prefs = await SharedPreferences.getInstance();
  await sharedPrefsTrace.stop();
  if (prefs.containsKey('lateLogOut')) {
    await LogOutApi().logOutWithCode(prefs.getString('loginCode')!, true);
    await prefs.remove('loginCode');
    await prefs.remove('lateLogOut');
  }
  final MyApp myApp = MyApp(
    initialRoute: prefs.containsKey('loginCode') ? '/mojekarty' : '/homePage',
  );
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.dark,
    statusBarColor: Colors.black,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(myApp);
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CardHub Flutter',
      initialRoute: initialRoute,
      routes: {
        "/homePage": (context) => const MyHomePage(title: "CardHub"),
        "/mojekarty": (context) => const DisplayCard(),
        "/detailkarty": (context) => const DetailCard(),
        "/novakarta": (context) => const AddNewCard(),
        "/novakartadetail": (context) => const CreateNewCard(),
        "/codescanner": (context) => const Scanner(),
        '/detailkartyedit': (context) => const EditExistingCard(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'CardHub'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _controller = TextEditingController();
  final _registerController = TextEditingController();

  final uniqueId = getCustomUniqueId();
  late final String uniqueSuffix;

  @override
  void initState() {
    uniqueSuffix = uniqueId.substring(3,7).toUpperCase();
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow.shade600,
      appBar: AppBar(
        leading: const Icon(Icons.credit_card_outlined),
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              // Center is a layout widget. It takes a single child and positions it
              // in the middle of the parent.
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(
                      height: 15,
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 1),
                      decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4.0),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                offset: Offset(0.0, 15.0),
                                blurRadius: 15.0),
                            BoxShadow(
                                color: Colors.black12,
                                offset: Offset(0.0, -10.0),
                                blurRadius: 10.0),
                          ]),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, top: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text("Vlož prihlasovací kód:",
                                style: TextStyle(
                                    fontSize: 23, color: Colors.white)),
                            const SizedBox(
                              height: 10,
                            ),
                            TextField(
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      width: 2,
                                      style: BorderStyle.solid,
                                      color: Colors.white24),
                                ),
                              ),
                              controller: _controller,
                            ),
                            const SizedBox(
                              height: 30,
                            ),
                            const SizedBox(
                              height: 30,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                    onPressed: () async {
                                      final navigator = Navigator.of(context);
                                      if (_controller.text.isEmpty) {
                                        QuickAlert.show(
                                          context: context,
                                          type: QuickAlertType.warning,
                                          title: 'Prihlásenie',
                                          text: 'Kód nemôže byť prázdny.',
                                        );
                                      } else {
                                        QuickAlert.show(
                                          context: context,
                                          type: QuickAlertType.loading,
                                          title: 'Prihlásenie',
                                          text: 'Načítavam dáta...',
                                        );
                                        bool isInternet =
                                            await InternetConnectionChecker()
                                                .hasConnection;
                                        if (isInternet) {
                                          String result = await LoginApi()
                                              .loginWithCode(_controller.text);
                                          if (result == 'loginSuccess') {
                                            final prefs =
                                                await SharedPreferences
                                                    .getInstance();
                                            await prefs.setString(
                                                'loginCode', _controller.text);
                                            navigator.pushNamedAndRemoveUntil(
                                                "/mojekarty", (_) => false);
                                          } else if (result == 'apiError') {
                                            navigator.pop();
                                            QuickAlert.show(
                                              context: context,
                                              type: QuickAlertType.error,
                                              title: 'Prihlásenie',
                                              text:
                                                  'Chyba aplikácie. Vývojár bol informovaný.',
                                            );
                                            throw Exception('RegisterApi Error');
                                          } else {
                                            navigator.pop();
                                            QuickAlert.show(
                                              context: context,
                                              type: QuickAlertType.error,
                                              title: 'Prihlásenie',
                                              text: result,
                                            );
                                          }
                                        } else {
                                          navigator.pop();
                                          QuickAlert.show(
                                            context: context,
                                            type: QuickAlertType.error,
                                            title: 'Prihlásenie',
                                            text:
                                                'Nemáš pripojenie na internet. Skús to neskôr.',
                                          );
                                        }
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      elevation: 10,
                                    ),
                                    icon: const Icon(
                                      Icons.login,
                                      color: Colors.green,
                                    ),
                                    label: const Text(
                                      "Prihlásiť sa",
                                      style: TextStyle(
                                          color: Colors.green, fontSize: 20),
                                    ))
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 35,
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 1),
                      decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4.0),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                offset: Offset(0.0, 15.0),
                                blurRadius: 15.0),
                            BoxShadow(
                                color: Colors.black12,
                                offset: Offset(0.0, -10.0),
                                blurRadius: 10.0),
                          ]),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, top: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text("Vytvoriť nový účet:",
                                style: TextStyle(
                                    fontSize: 23, color: Colors.white)),
                            const SizedBox(
                              height: 10,
                            ),
                            TextField(
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                  suffixStyle: const TextStyle(
                                      fontSize: 22, color: Colors.white60),
                                  suffixText: "#$uniqueSuffix",
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        width: 2,
                                        style: BorderStyle.solid,
                                        color: Colors.white24),
                                  ),
                                  hintText: "Vlož vlastný prhlasovací kód"),
                              controller: _registerController,
                            ),
                            const SizedBox(
                              height: 30,
                            ),
                            const SizedBox(
                              height: 30,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final navigator = Navigator.of(context);
                                    if (_registerController.text.isEmpty) {
                                      QuickAlert.show(
                                        context: context,
                                        type: QuickAlertType.warning,
                                        title: 'Vytvorenie účtu',
                                        text: 'Kód nemôže byť prázdny.',
                                      );
                                    } else {
                                      QuickAlert.show(
                                        context: context,
                                        type: QuickAlertType.loading,
                                        title: 'Vytvorenie účtu',
                                        text: 'Načítavam dáta...',
                                      );
                                      bool isInternet = await InternetConnectionChecker().hasConnection;
                                      Future.delayed(const Duration(milliseconds: 500), () async{
                                      if (isInternet) {
                                        String uniqueNewId = "${_registerController.text}#$uniqueSuffix";
                                        print(uniqueNewId);
                                        String result = await RegisterApi().registerWithCode(uniqueNewId);
                                        if (result == 'registerSuccess') {
                                          String result = await LoginApi().loginWithCode(uniqueNewId);
                                          navigator.pop();
                                          QuickAlert.show(
                                            context: context,
                                            type: QuickAlertType.loading,
                                            title: 'Prihlásenie',
                                            text: 'Načítavam dáta...',
                                          );
                                          if(result == 'loginSuccess'){
                                            final prefs =
                                            await SharedPreferences
                                                .getInstance();
                                            await prefs.setString(
                                                'loginCode', uniqueNewId);
                                            navigator.pushNamedAndRemoveUntil(
                                                "/mojekarty", (_) => false);
                                          } else if (result == 'apiError') {
                                            navigator.pop();
                                            QuickAlert.show(
                                              context: context,
                                              type: QuickAlertType.error,
                                              title: 'Prihlásenie',
                                              text:
                                              'Chyba aplikácie. Vývojár bol informovaný.',
                                            );
                                          } else {
                                            navigator.pop();
                                            QuickAlert.show(
                                              context: context,
                                              type: QuickAlertType.error,
                                              title: 'Vytvorenie účtu',
                                              text: result,
                                            );
                                          }
                                        } else if (result == 'apiError') {
                                          navigator.pop();
                                          QuickAlert.show(
                                            context: context,
                                            type: QuickAlertType.error,
                                            title: 'Vytvorenie účtu',
                                            text:
                                            'Chyba aplikácie. Vývojár bol informovaný.',
                                          );
                                        } else {
                                          navigator.pop();
                                          QuickAlert.show(
                                            context: context,
                                            type: QuickAlertType.error,
                                            title: 'Vytvorenie účtu',
                                            text: result,
                                          );
                                        }
                                      } else {
                                        navigator.pop();
                                        QuickAlert.show(
                                          context: context,
                                          type: QuickAlertType.error,
                                          title: 'Vytvorenie účtu',
                                          text:
                                          'Nemáš pripojenie na internet. Skús to neskôr.',
                                        );
                                      }
                                      });
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    elevation: 10,
                                  ),
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.green,
                                  ),
                                  label: const Text(
                                    "Vytvoriť účet",
                                    style: TextStyle(
                                        color: Colors.green, fontSize: 20),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 35,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

String getCustomUniqueId() {
  const String pushChars =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  int lastPushTime = 0;
  List lastRandChars = [];
  int now = DateTime.now().millisecondsSinceEpoch;
  bool duplicateTime = (now == lastPushTime);
  lastPushTime = now;
  List timeStampChars = List<String>.filled(8, '0');
  for (int i = 7; i >= 0; i--) {
    timeStampChars[i] = pushChars[now % 62];
    now = (now / 64).floor();
  }
  if (now != 0) {
    print("Id should be unique");
  }
  String uniqueId = timeStampChars.join('');
  if (!duplicateTime) {
    for (int i = 0; i < 12; i++) {
      lastRandChars.add((Random().nextDouble() * 62).floor());
    }
  } else {
    int i = 0;
    for (int i = 11; i >= 0 && lastRandChars[i] == 62; i--) {
      lastRandChars[i] = 0;
    }
    lastRandChars[i]++;
  }
  for (int i = 0; i < 12; i++) {
    uniqueId += pushChars[lastRandChars[i]];
  }
  return uniqueId;
}
