

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


#include <ESP8266WiFi.h>
#include <WebSocketsServer.h>
#include <ArduinoJson.h>
#include <stdarg.h>   // needed for the formatted logging helper (logMsgf)

// --- WebSocket Configuration ---
// Create a WebSocket server listening on port 81.
WebSocketsServer webSocket = WebSocketsServer(81);

// =========================== Motor controls ===================================
// Pin assignments. Adjust to match your wiring.
// Use the Dx names (D0..D8) as defined by NodeMCU/ESP8266 boards.
const uint8_t AIN1 = D1;  // left motor direction pin 1
const uint8_t AIN2 = D2;  // left motor direction pin 2
const uint8_t PWMA = D5;  // left motor PWM (speed)

const uint8_t BIN1 = D7;  // right motor direction pin 1
const uint8_t BIN2 = D8;  // right motor direction pin 2
const uint8_t PWMB = D6;  // right motor PWM (speed)

// Simple Motor helper class: encapsulates motor pin setup and common actions.
// This keeps the main code readable and avoids repeated pin code everywhere.
class Motor {
    const char* name;
    int pinIn1, pinIn2, pinPwm, pinLed;

public:
    Motor(const char* motorName, int in1, int in2, int pwm, int led) {
        name = motorName;
        pinIn1 = in1;
        pinIn2 = in2;
        pinPwm = pwm;
        pinLed = led;

        // Configure the pins we need. All outputs for motor control and LED.
        pinMode(pinIn1, OUTPUT);
        pinMode(pinIn2, OUTPUT);
        pinMode(pinPwm, OUTPUT);
        pinMode(pinLed, OUTPUT);
    }

    // Drive forward with given PWM duty (0-255)
    void forward(int pwm) {
        digitalWrite(pinIn1, HIGH);
        digitalWrite(pinIn2, LOW);
        analogWrite(pinPwm, pwm);
        digitalWrite(pinLed, LOW); // LED ON while moving (active-low on some boards)
        log("forward", pwm);
    }

    // Drive backward with given PWM duty (0-255)
    void backward(int pwm) {
        digitalWrite(pinIn1, LOW);
        digitalWrite(pinIn2, HIGH);
        analogWrite(pinPwm, pwm);
        digitalWrite(pinLed, LOW);
        log("backward", pwm);
    }

    // Stop the motor. If brake == true, actively brake by setting both direction pins HIGH.
    void stop(bool brake = false) {
        if (brake) {
            // Active short to brake motor (both direction pins HIGH) — depends on driver behavior.
            digitalWrite(pinIn1, HIGH);
            digitalWrite(pinIn2, HIGH);
        } else {
            // Let motor coast
            digitalWrite(pinIn1, LOW);
            digitalWrite(pinIn2, LOW);
        }
        analogWrite(pinPwm, 0);
        digitalWrite(pinLed, HIGH); // LED OFF while idle (if using active-low LED)
        log(brake ? "stopped (brake)" : "stopped", 0);
    }

private:
    // Simple wrapper to log action to Serial and broadcast to any connected WebSocket clients.
    void log(const char* action, int pwm) {
        String msg = String(name) + " " + action + " at " + String(pwm);
        Serial.println(msg);          // useful during development
        webSocket.broadcastTXT(msg);  // send status to all connected clients (debug console)
    }
};

// Create two Motor instances for left and right drive
Motor rightMotor("Right Motor", BIN1, BIN2, PWMB, LED_BUILTIN);
Motor leftMotor("Left Motor", AIN1, AIN2, PWMA, D0);

// --- WiFi Configuration ---
const char* ssid = "YOUR_WIFI_NAME";
const char* password = "YOUR_WIFI_PASSWORD";



// Optional: static IP configuration. Use only if you know your network supports that address.
// If you use DHCP instead, remove or comment out the WiFi.config(...) call in setup().
IPAddress local_IP(192, 168, 1, 9);    // set to the IP you want for the ESP
IPAddress gateway(192, 168, 1, 1);
IPAddress subnet(255, 255, 255, 0);
IPAddress primaryDNS(8, 8, 8, 8);
IPAddress secondaryDNS(8, 8, 4, 4);

// --- Forward declarations ---
void webSocketEvent(uint8_t clientID, WStype_t type, uint8_t* payload, size_t length);

// --- WebSocket Event Handler ---
// Handles client connect/disconnect and incoming text messages.
void webSocketEvent(uint8_t clientID, WStype_t type, uint8_t* payload, size_t length) {
    switch (type) {

        case WStype_DISCONNECTED:
            // If a client disconnects unexpectedly, stop the motors for safety.
            rightMotor.stop();
            leftMotor.stop();
            logMsgf("[%u] Disconnected, motors stopped!", clientID);
            break;

        case WStype_CONNECTED:
        {
            // Report the remote IP for debugging
            IPAddress ip = webSocket.remoteIP(clientID);
            logMsgf("[%u] Connected from %d.%d.%d.%d", clientID, ip[0], ip[1], ip[2], ip[3]);
            webSocket.sendTXT(clientID, "Welcome to the ESP8266 WebSocket Server!");
        }
            break;

        case WStype_TEXT:
        {
            // Convert payload to a String for parsing
            String msg = String((char*)payload);

            // Parse JSON message using ArduinoJson. Adjust buffer size if messages grow.
            StaticJsonDocument<200> doc;
            DeserializationError error = deserializeJson(doc, msg);
            if (error) {
                // If JSON parsing fails, log error and ignore the message.
                Serial.print("JSON parse failed: ");
                logMsg(error.f_str());
                return;
            }

            // NEW: Handle ping-pong for latency measurement
            if (doc.containsKey("ping_timestamp")) {
                // Echo the message back with "pong_timestamp"
                doc["pong_timestamp"] = doc["ping_timestamp"];
                doc.remove("ping_timestamp");
                String response;
                serializeJson(doc, response);
                webSocket.sendTXT(clientID, response);
                return; // This was a ping, no need to process motor commands
            }


            // Safely extract fields. Use default values if keys are absent.
            bool BLF = doc.containsKey("BLF") ? doc["BLF"].as<bool>() : false;
            bool BLB = doc.containsKey("BLB") ? doc["BLB"].as<bool>() : false;
            bool BRF = doc.containsKey("BRF") ? doc["BRF"].as<bool>() : false;
            bool BRB = doc.containsKey("BRB") ? doc["BRB"].as<bool>() : false;

            int LS = doc.containsKey("LS") ? doc["LS"].as<int>() : 0;
            int RS = doc.containsKey("RS") ? doc["RS"].as<int>() : 0;

            // Control right motor depending on flags (forward/backward) and speed value RS.
            if (BRF) {
                rightMotor.forward(RS);
            } else if (BRB) {
                rightMotor.backward(RS);
            } else {
                rightMotor.stop(false); // coast by default
            }

            // Control left motor depending on flags and LS.
            if (BLF) {
                leftMotor.forward(LS);
            } else if (BLB) {
                leftMotor.backward(LS);
            } else {
                leftMotor.stop(false);
            }
        }
            break;

        default:
            // Other event types can be handled here if needed.
            break;
    }
}

// --- Setup: runs once on boot ---
void setup() {
    Serial.begin(115200);
    // Basic pin setup for status LED and motor pins
    pinMode(LED_BUILTIN, OUTPUT);
    pinMode(D0, OUTPUT);

    pinMode(AIN1, OUTPUT);
    pinMode(AIN2, OUTPUT);
    pinMode(PWMA, OUTPUT);
    pinMode(BIN1, OUTPUT);
    pinMode(BIN2, OUTPUT);
    pinMode(PWMB, OUTPUT);

    logMsg("\n--- ESP8266 WebSocket Server starting ---");

    // Optionally apply static IP configuration. If this fails, code falls back to DHCP.
    if (!WiFi.config(local_IP, gateway, subnet, primaryDNS, secondaryDNS)) {
        logMsg("Failed to configure Static IP, using DHCP...");
    }

    // Connect to Wi-Fi. Blocking loop until connected.
    // During development this is fine; for production consider a non-blocking strategy with retries.
    WiFi.begin(ssid, password);
    Serial.print("Connecting to WiFi");
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }

    logMsg("\nWiFi connected!");
    logMsg("IP address: ");
    logMsg(WiFi.localIP().toString());

    // Start the WebSocket server and register the event handler.
    webSocket.begin();
    webSocket.onEvent(webSocketEvent);
    logMsg("WebSocket server listening on port 81.");
}

// --- Main Loop: call websocket.loop() frequently to process incoming messages ---
void loop() {
    webSocket.loop();
    yield();  // yield to background tasks and feed the watchdog
}

//=============================================== Debug Helpers ================================================
// logMsg: prints to Serial and broadcasts the same message to connected WebSocket clients.
// This is convenient for a simple in-app debug console.
template<typename T>
void logMsg(T val) {
    String msg = String(val);
    Serial.println(msg);
    webSocket.broadcastTXT(msg);
}

// logMsgf: printf-style logger. Small buffer; increase if you need longer formatted strings.
void logMsgf(const char* fmt, ...) {
    char buf[128];  // buffer for formatted string (increase if messages are longer)
    va_list args;
    va_start(args, fmt);
    vsnprintf(buf, sizeof(buf), fmt, args);
    va_end(args);

    // Print to Serial and broadcast to connected clients (reuses logMsg)
    logMsg(buf);
}