// ============== ESP82266 side ============
// Quick start guide
// 1) Install the Arduino IDE.
// 2) Add ESP8266 board support:
//    File -> Preferences -> Additional Board Manager URLs:
//    http://arduino.esp8266.com/stable/package_esp8266com_index.json
// 3) Install libraries via Tools -> Manage Libraries:
//    - WebSockets (Markus Sattler)    // WebSocket server/client
//    - ArduinoJson (Benoit Blanchon)  // JSON parsing and serialization
// Optional for quick tests: Firebase ESP8266 Client (Mobizt)

// Opening the project
// - Open 'Arduino IDE Code/web_socket_with_motor_control.ino' in the Arduino IDE.

// Configuration
// Replace these placeholders with your local Wi-Fi credentials.
// const char* ssid     = "YOUR_SSID";       // Wi-Fi network name
// const char* password = "YOUR_PASSWORD";   // Wi-Fi password

// Static IP (optional)
// If you want a fixed IP, edit the IPAddress values in the sketch and keep WiFi.config(...) enabled in setup().
// If you prefer DHCP, comment out the WiFi.config(...) call.

// ============= App side ==============
//Create a 'config.dart' file inside 'lib/config/' with the IP address and port of your ESP8266.

//class Config {
//    static const String ip = 'YOUR_IP_ADDRESS';
//    static const int port = 81;
//}
