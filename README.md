# Flutter-ESP8266 RC Controller

**Real-time remote control for an RC car — Flutter frontend, ESP8266 backend, WebSockets for low-latency control.**

---

## Highlights
- **Real-time control:** Persistent WebSocket link for low-latency command roundtrips.
- **End-to-end IoT:** Mobile UI <--> ESP8266 microcontroller <--> motor drivers.
- **Hardware:**
    - **Microcontroller:** ESP8266
    - **Motor Drivers:** 2x TB6612FNG for 4-wheel drive.
    - **Power System:** Custom 14.6V (4S) battery pack, regulated by two buck converters, with a custom-built 4x TP405 charging solution.

---

## Key Features
- **Bidirectional Communication:** Utilizes WebSockets for a persistent, low-latency, two-way connection.
- **Custom UI Components:** A custom `VerticalSlider` widget was built from scratch for precise speed control.
- **In-app Debug Console:** Displays real-time telemetry and WebSocket connection status for easy troubleshooting.
- **Modular Hardware Design:** The hardware is built with a modular philosophy. No critical components are soldered directly, allowing for easy maintenance and upgrades.

---

## How to use?

### 1. ESP8266 Side (The Car)

**Quick Start Guide:**
1.  **Install the Arduino IDE.**
2.  **Add ESP8266 board support:**
    - Go to `File -> Preferences -> Additional Board Manager URLs`.
    - Add: `http://arduino.esp8266.com/stable/package_esp8266com_index.json`
3.  **Install Libraries:**
    - Go to `Tools -> Manage Libraries` and install:
        - `WebSockets` by Markus Sattler
        - `ArduinoJson` by Benoit Blanchon
4.  **Open the Project:**
    - Open `lib/Arduino IED Code/web_socket_with_motor_control.ino` in the Arduino IDE.
5.  **Configure Wi-Fi Credentials:**
    - In the `.ino` file, replace the placeholder Wi-Fi credentials with your own:
      ```cpp
      const char* ssid     = "YOUR_SSID";       // Wi-Fi network name
      const char* password = "YOUR_PASSWORD";   // Wi-Fi password
      ```
6.  **Set IP Address (Optional but Recommended):**
    - For a stable connection, it's best to assign a static IP. Edit the `IPAddress` values in the sketch and ensure `WiFi.config(...)` is enabled in the `setup()` function.
    - If you prefer DHCP, comment out the `WiFi.config(...)` line.
7.  **Upload the code** to your ESP8266.


### 2. Flutter App Side (The Controller)

1.  **Clone the repository.**
2.  **Create a `config.dart` file** inside `lib/config/` with the IP address and port of your ESP8266.
    ```dart
    class Config {
      // This should be the IP address of your ESP8266.
      static const String ip = 'YOUR_IP_ADDRESS'; // e.g., '192.168.1.9'

      // The port must match the port in the ESP8266 code (default is 81).
      static const int port = 81;
    }
    ```
3.  **Run the app.**
    ```bash
    flutter pub get
    flutter run
    ```
