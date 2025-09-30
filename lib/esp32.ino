#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// Define ESP32 hardware serial port for SIM808
#define SIM808_TX 33  // ESP32 TX connected to SIM808 RX
#define SIM808_RX 32  // ESP32 RX connected to SIM808 TX
#define PWRKEY 27     // SIM808 Power Key pin (adjust if needed)

// BLE Configuration
#define SERVICE_UUID "12345678-1234-1234-1234-123456789abc"
#define CHARACTERISTIC_UUID "87654321-4321-4321-4321-cba987654321"
#define DEVICE_NAME "GPSTRACK-0309250010"

// Initialize hardware serial for SIM808
HardwareSerial sim808(2);
String smsMessage = "";
String phoneNumber = "+639940176150";  // Replace with your phone number

static unsigned long lastSMSTime = 0;
const unsigned long SMS_INTERVAL = 4 * 60 * 60 * 1000;  // 4 hours in milliseconds

// BLE Variables
BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// BLE Server Callbacks
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("BLE Device Connected");
  };

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("BLE Device Disconnected");
  }
};

// BLE Characteristic Callbacks
class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    String value = pCharacteristic->getValue();
    if (value.length() > 0) {
      Serial.println("Received from BLE: " + value);

      // Handle commands from smartphone app
      if (value == "GET_ID") {
        pCharacteristic->setValue(DEVICE_NAME);
        pCharacteristic->notify();
        Serial.println("Sent Device ID: " + String(DEVICE_NAME));
      } else if (value.startsWith("SET_PHONE:")) {
        phoneNumber = value.substring(10);
        pCharacteristic->setValue("Phone number updated");
        pCharacteristic->notify();
        Serial.println("Phone number updated to: " + phoneNumber);
      }
    }
  }
};

void initBLE() {
  // Create the BLE Device
  BLEDevice::init(DEVICE_NAME);

  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create the BLE Service
  BLEService* pService = pServer->createService(SERVICE_UUID);

  // Create a BLE Characteristic
  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_INDICATE);

  // Set the callback for characteristic
  pCharacteristic->setCallbacks(new MyCallbacks());

  // Add a descriptor for notifications
  pCharacteristic->addDescriptor(new BLE2902());

  // Set initial value (device ID)
  pCharacteristic->setValue(DEVICE_NAME);

  // Start the service
  pService->start();

  // Start advertising
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);
  BLEDevice::startAdvertising();

  Serial.println("BLE Server started and advertising...");
  Serial.println("Device Name: " + String(DEVICE_NAME));
}

String getGPSLocation() {
  sim808.println("AT+CGNSINF");
  delay(1000);

  if (sim808.find("+CGNSINF:")) {
    String gpsData = sim808.readStringUntil('\n');

    // Parse GPS: +CGNSINF: <mode>,<status>,<lat>,<lon>,...
    int firstComma = gpsData.indexOf(',');
    int secondComma = gpsData.indexOf(',', firstComma + 1);
    int thirdComma = gpsData.indexOf(',', secondComma + 1);
    int fourthComma = gpsData.indexOf(',', thirdComma + 1);

    String lat = gpsData.substring(secondComma + 1, thirdComma);
    String lon = gpsData.substring(thirdComma + 1, fourthComma);

    if (lat.length() > 3 && lon.length() > 3 && lat != "0.000000" && lon != "0.000000") {
      return lat + "," + lon;
    }
  }
  return "No GPS Fix";
}

void powerOnSIM808() {
  pinMode(PWRKEY, OUTPUT);
  digitalWrite(PWRKEY, LOW);
  delay(1000);  // PWRKEY must be held LOW for at least 1 second
  digitalWrite(PWRKEY, HIGH);
  delay(3000);  // Wait for the module to initialize
  digitalWrite(PWRKEY, LOW);
  delay(5000);
}

void setup() {
  Serial.begin(115200);                                    // Serial Monitor
  sim808.begin(115200, SERIAL_8N1, SIM808_RX, SIM808_TX);  // SIM808 UART

  // Initialize BLE
  initBLE();

  powerOnSIM808();

  Serial.println("===== ESP32 + SIM808 Test Start =====");

  // Basic GSM init
  Serial.println("Sending AT...");
  if (sendCommand("AT", "OK", 2000)) {
    Serial.println("SIM808 is responding!");
  } else {
    Serial.println("ERROR: No response to AT command.");
  }

  Serial.println("Turning GPS ON...");
  if (sendCommand("AT+CGNSPWR=1", "OK", 2000)) {
    Serial.println("GPS powered ON.");
  } else {
    Serial.println("ERROR: Cannot power GPS.");
  }

  Serial.println("Setting GPS NMEA output...");
  if (sendCommand("AT+CGNSSEQ=RMC", "OK", 2000)) {
    Serial.println("GPS sequence set.");
  } else {
    Serial.println("ERROR: Failed to set GPS sequence.");
  }

  delay(2000);
  sendSMS("Device Ready");
  Serial.println("===== Setup Finished =====");
}

void loop() {

  // Handle BLE connection changes
  if (!deviceConnected && oldDeviceConnected) {
    String gpsLocation = getGPSLocation();
    if (gpsLocation != "No GPS Fix") {
      String smsText = String(DEVICE_NAME) + " GPS Location: https://maps.google.com/?q=" + gpsLocation;
      sendSMS(smsText);
      Serial.println("Periodic GPS SMS sent: " + smsText);
    } else {
      sendSMS("No GPS fix available for periodic SMS");
      Serial.println("No GPS fix available for periodic SMS");
    }

    delay(500);                   // Give the bluetooth stack the chance to get things ready
    pServer->startAdvertising();  // Restart advertising
    Serial.println("Start advertising");
    oldDeviceConnected = deviceConnected;
  }

  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  // Send GPS data over SMS every 4 hours when BLE is disconnected
  if (!deviceConnected) {

    if (millis() - lastSMSTime > SMS_INTERVAL) {
      String gpsLocation = getGPSLocation();
      if (gpsLocation != "No GPS Fix") {
        String smsText = String(DEVICE_NAME) + " GPS Location: https://maps.google.com/?q=" + gpsLocation;
        sendSMS(smsText);
        Serial.println("Periodic GPS SMS sent: " + smsText);
      } else {
        sendSMS("No GPS fix available for periodic SMS");
        Serial.println("No GPS fix available for periodic SMS");
      }
      lastSMSTime = millis();
    }
  }

  // Handle serial communication
  if (Serial.available()) sim808.write(Serial.read());
  if (sim808.available()) Serial.write(sim808.read());
}

// Function to send an AT command and print response
bool sendCommand(String cmd, String ack, uint16_t timeout) {
  sim808.println(cmd);
  Serial.println(">> " + cmd);  // Debug print of command sent

  long int time = millis();
  while ((millis() - time) < timeout) {
    if (sim808.find(ack.c_str())) {
      Serial.println("<< " + ack + " received");
      return true;
    }
  }
  Serial.println("<< " + ack + " NOT received");
  return false;
}

void sendSMS(String message) {
  if (message.length() == 0) {
    Serial.println("ERROR: No message to send.");
    return;
  }
  if (phoneNumber == "+63XXXXXXXXXX") {
    Serial.println("ERROR: Invalid phone number.");
    return;
  }
  smsMessage = message;

  // Send SMS
  Serial.println("Preparing to send SMS...");
  if (sendCommand("AT+CMGF=1", "OK", 2000)) {
    Serial.println("SMS Text Mode OK.");
  } else {
    Serial.println("ERROR: Cannot set SMS mode.");
  }

  Serial.println("Sending SMS to phone...");
  if (sendCommand("AT+CMGS=\"" + phoneNumber + "\"", ">", 2000)) {
    sim808.print(smsMessage);
    delay(100);
    sim808.write(26);  // Ctrl+Z to send
    Serial.println("Message sent: " + smsMessage);
  } else {
    Serial.println("ERROR: SMS command failed.");
  }
}