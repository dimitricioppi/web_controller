import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:permission_handler/permission_handler.dart';



// Punto d'ingresso della app: avvia il widget principale
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controllo connettività',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ConnectivityScreen(), // Schermata principale dell'app
    );
  }
}

// Funzione che chiede i permessi necessari per accedere ad un eventale BSSID
Future<void> requestPermissions() async {
  await Permission.location.request();
}

// Widget con stato che gestisce la connessione di rete
class ConnectivityScreen extends StatefulWidget {
  const ConnectivityScreen({super.key});

  @override
  ConnectivityScreenState createState() => ConnectivityScreenState();
}

class ConnectivityScreenState extends State<ConnectivityScreen> {

  // Stato iniziale della connessione
  String connectivityStatus = "Premi il pulsante per controllare la connessione";
  String bssid = "BSSID non disponibile";

  // Controlla la connessione di rete del dispositivo
  Future<void> checkConnectivity() async {

    await requestPermissions(); // Richiede i permessi prima di verificare la connessione
    setState(() {
      connectivityStatus = "Verifica connessione in corso...";
      bssid = "Attendere...";
    });

    ConnectivityResult result = await Connectivity().checkConnectivity();

    if (result == ConnectivityResult.none) {
      setState(() {
        connectivityStatus = "Nessuna rete disponibile";
        bssid = "Non disponibile";
      });
    } else{
      verifyInternetConnection(result);
    }
  }

  Future<void> verifyInternetConnection(ConnectivityResult result) async {
    bool hasInternetAccess = await InternetConnectionChecker().hasConnection.timeout(
      const Duration(seconds: 2),
      onTimeout: () => false,
    );

    String wifiBSSID = (result == ConnectivityResult.wifi) ? await getBSSID() : "Non disponibile";

    setState(() {
      connectivityStatus = hasInternetAccess
          ? getConnectivityText(result)
          : "Connesso alla rete, ma senza accesso a Internet";
      bssid = wifiBSSID;
    });
  }

  // Determina il tipo di connessione attuale
  String getConnectivityText(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return "Connesso via Wi-Fi";
      case ConnectivityResult.mobile:
        return "Connesso via rete mobile";
      case ConnectivityResult.ethernet:
        return "Connesso via cavo (Ethernet)";
      default:
        return "Stato sconosciuto";
    }
  }

  // Recupera il BSSID (indirizzo della rete Wi-Fi) se disponibile
  Future<String> getBSSID() async {
    final info = NetworkInfo();
    String? wifiBSSID = await info.getWifiBSSID();
    return wifiBSSID ?? "BSSID non disponibile"; // Se non disponibile, ritorna valore di default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stato connettività")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mostra lo stato della connessione
            Text(connectivityStatus, style: const TextStyle(fontSize: 25)),
            const SizedBox(height: 20),

            // Mostra il BSSID della rete Wi-Fi (se disponibile)
            Text("BSSID: $bssid", style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),

            // Pulsante per eseguire il controllo della connessione
            ElevatedButton(
              onPressed: checkConnectivity,
              child: const Text("Controlla connessione"),
            ),
          ],
        ),
      ),
    );
  }
}
