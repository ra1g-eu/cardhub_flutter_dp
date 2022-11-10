import 'package:cardhub/apicalls/logout.dart';
import 'package:cardhub/pages/add_new_card.dart';
import 'package:cardhub/pages/codescanner.dart';
import 'package:cardhub/pages/create_new_card.dart';
import 'package:cardhub/pages/details_card.dart';
import 'package:cardhub/pages/display_cards.dart';
import 'package:cardhub/pages/edit_existing_card.dart';
import 'package:cardhub/pages/webview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'apicalls/login_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  if(prefs.containsKey('lateLogOut')){
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
        "/homePage": (context) => const MyHomePage(title: "Prihlásenie"),
        "/mojekarty": (context) => const DisplayCard(),
        "/detailkarty": (context) => const DetailCard(),
        "/novakarta": (context) => const AddNewCard(),
        "/novakartadetail": (context) => const CreateNewCard(),
        "/codescanner": (context) => const Scanner(),
        '/detailkartyedit': (context) => const EditExistingCard(),
      },
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'CardHub'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Invoke "debug painting" (press "p" in the console, choose the
            // "Toggle Debug Paint" action from the Flutter Inspector in Android
            // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
            // to see the wireframe for each widget.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            mainAxisAlignment: MainAxisAlignment.start,

            children: <Widget>[
              const SizedBox(
                height: 30,
              ),
              const Text("CardHub", style: TextStyle(fontSize: 40)),
              const SizedBox(
                height: 30,
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 1),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
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
                  padding:
                      const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text("Prihlasovací kód",
                          style: TextStyle(fontSize: 23)),
                      TextField(
                        controller: _controller,
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          OutlinedButton(
                              onPressed: null,
                              style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.amber)),
                              child: const Text("Registrovať sa")),
                          OutlinedButton(
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
                                  bool isInternet = await InternetConnectionChecker().hasConnection;
                                  if(isInternet){
                                    String result = await LoginApi()
                                        .loginWithCode(_controller.text);
                                    if (result == 'loginSuccess') {
                                      final prefs =
                                      await SharedPreferences.getInstance();
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
                                      text: 'Nemáš pripojenie na internet. Skús to neskôr.',
                                    );
                                  }
                                }
                              },
                              child: const Text("Prihlásiť sa"))
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
