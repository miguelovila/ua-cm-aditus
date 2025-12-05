#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include <HTTPClient.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <WiFi.h>
#include <mbedtls/pk.h>
#include <mbedtls/md.h>
#include <mbedtls/error.h>
#include <mbedtls/base64.h>

// Configuration
// #define DEBUG

// WiFi Configuration
#define WIFI_SSID "Home Wifi"
#define WIFI_PASSWD "CVCV0011223344VCVC"
#define WIFI_CONNECT_TIMEOUT 30
#define WIFI_RETRY_DELAY_MS 500

// BLE Configuration
#define BLE_DEVICE_NAME "Aditus Door"
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define BLE_ADV_MIN_INTERVAL 0x06
#define BLE_ADV_MAX_INTERVAL 0x12
#define ID_CHAR_UUID "5f2e6f9a-6f3d-4a1b-8f0a-7b8b5a3d0b1a"
#define CHALLENGE_CHAR_UUID "6a3d9e2c-2a9a-4c1b-8f0a-7b8b5a3d0b1a"
#define SIGNATURE_CHAR_UUID "7b8b5a3d-0b1a-4c1b-8f0a-6f3d9e2c2a9a"
#define STATUS_CHAR_UUID "8f0a7b8b-5a3d-4c1b-8f0a-6f3d9e2c2a9a"

// API Configuration
#define ESP32_API_KEY "esp32-dev-key-change-in-production"
#define API_BASE_URL "https://aditus-api.mxv.pt/"
#define API_HEALTH_ENDPOINT "/health"
#define HTTP_SUCCESS_CODE 200

// Door Configuration
#define LED_BLINK_DURATION_MS 7000  // 7 seconds
#define LED_BLINK_INTERVAL_MS 100  // Blink every 100ms (fast blinking for door unlock)
#define LED_SLOW_BLINK_INTERVAL_MS 1000  // 1 second slow blink (not registered)
#define REGISTRATION_RETRY_INTERVAL_MS 10000  // 10 seconds retry interval

// State Machine
enum UnlockState
{
  STATE_IDLE,
  STATE_WAITING_FOR_SIGNATURE,
  STATE_AUTHORIZED,
  STATE_DENIED
};
UnlockState currentUnlockState = STATE_IDLE;
String currentChallenge = "";

// LED State Machine
enum LedState
{
  LED_OFF,
  LED_ON_IDLE,
  LED_SLOW_BLINK_CONFIG,
  LED_FAST_BLINK_UNLOCK
};
LedState currentLedState = LED_OFF;
unsigned long ledLastToggle = 0;
bool ledCurrentState = false;
unsigned long unlockStartTime = 0;

// Global Variables
BLEServer *pServer = nullptr;
BLEService *pService = nullptr;
BLECharacteristic *pIdCharacteristic = nullptr;
BLECharacteristic *pChallengeCharacteristic = nullptr;
BLECharacteristic *pSignatureCharacteristic = nullptr;
BLECharacteristic *pStatusCharacteristic = nullptr;

bool deviceConnected = false;
bool oldDeviceConnected = false;
String receivedUserId = "";
String receivedDeviceId = "";

// Registration state
bool isRegistered = false;
int doorId = 0;
String doorName = "";
unsigned long lastRegistrationAttempt = 0;

// State timeout management
unsigned long stateStartTime = 0;
#define SIGNATURE_TIMEOUT_MS 30000  // 30 seconds

// Forward declarations
void unlockDoor();
void logAccessAttempt(bool success);
void updateLedState();

bool init_wifi()
{
#ifdef DEBUG
  Serial.println("[DEBUG] Connecting to WiFi");
#endif

  WiFi.begin(WIFI_SSID, WIFI_PASSWD);

  int retries = WIFI_CONNECT_TIMEOUT;
  while (WiFi.status() != WL_CONNECTED && retries > 0)
  {
    delay(WIFI_RETRY_DELAY_MS);
#ifdef DEBUG
    Serial.print(".");
#endif
    retries--;
  }

  if (WiFi.status() != WL_CONNECTED)
  {
#ifdef DEBUG
    Serial.println("\n[ERROR] WiFi connection failed after timeout");
#endif
    return false;
  }

#ifdef DEBUG
  Serial.println("\n[DEBUG] WiFi connected");
#endif

  Serial.printf("[ INFO] WiFi door IP: %s\n", WiFi.localIP().toString().c_str());
  return true;
}

class MyServerCallbacks : public BLEServerCallbacks
{
  void onConnect(BLEServer *pServer)
  {
    deviceConnected = true;
    Serial.println("[ INFO] BLE Client Connected");
  };

  void onDisconnect(BLEServer *pServer)
  {
    deviceConnected = false;
    currentUnlockState = STATE_IDLE;
    Serial.println("[ INFO] BLE Client Disconnected");
  }
};

class MyCharacteristicCallbacks : public BLECharacteristicCallbacks
{
  void onWrite(BLECharacteristic *pCharacteristic)
  {
    String value = pCharacteristic->getValue();

    if (value.length() > 0)
    {
      if (pCharacteristic == pIdCharacteristic)
      {
        Serial.printf("[DEBUG] ID Characteristic received: %s\n", value.c_str());

        StaticJsonDocument<200> doc;
        DeserializationError error = deserializeJson(doc, value);

        if (error)
        {
          Serial.printf("[ERROR] JSON parsing failed: %s\n", error.c_str());
          return;
        }

        receivedUserId = doc["user_id"].as<String>();
        receivedDeviceId = doc["device_id"].as<String>();

        Serial.printf("[ INFO] Parsed User ID: %s, Device ID: %s\n",
                      receivedUserId.c_str(), receivedDeviceId.c_str());

        // First check access permissions with backend
        if (!checkAccessPermission(receivedUserId))
        {
          Serial.println("[ERROR] Access denied by backend");
          currentUnlockState = STATE_DENIED;
          return;
        }

        // Access allowed - proceed with challenge-response
        String publicKey = getPublicKeyFromBackend(receivedDeviceId);
        if (publicKey.length() > 0)
        {
          currentChallenge = String(random(100000, 999999));
          Serial.printf("[ INFO] Generated challenge: %s\n", currentChallenge.c_str());

          pChallengeCharacteristic->setValue(currentChallenge.c_str());
          pChallengeCharacteristic->notify();
          Serial.println("[ INFO] Challenge sent to app.");
          currentUnlockState = STATE_WAITING_FOR_SIGNATURE;
          stateStartTime = millis();  // Start timeout timer
        }
        else
        {
          Serial.println("[ERROR] Could not retrieve public key from backend");
          pStatusCharacteristic->setValue("DENIED_KEY_FETCH_FAILED");
          pStatusCharacteristic->notify();
          currentUnlockState = STATE_DENIED;
          return;
        }
      }
      else if (pCharacteristic == pSignatureCharacteristic)
      {
        if (currentUnlockState == STATE_WAITING_FOR_SIGNATURE)
        {
          Serial.printf("[DEBUG] Signature received: %s\n", value.c_str());
          String receivedSignature = value;

          // Fetch public key for verification
          String publicKey = getPublicKeyFromBackend(receivedDeviceId);
          if (publicKey.length() == 0)
          {
            Serial.println("[ERROR] Cannot verify without public key");
            currentUnlockState = STATE_DENIED;
            pStatusCharacteristic->setValue("DENIED_KEY_UNAVAILABLE");
            pStatusCharacteristic->notify();
            logAccessAttempt(false);
            return;
          }

          // Verify RSA signature
          if (verifyRSASignature(publicKey, currentChallenge, receivedSignature))
          {
            Serial.println("[ INFO] Cryptographic verification PASSED");
            currentUnlockState = STATE_AUTHORIZED;
            pStatusCharacteristic->setValue("AUTHORIZED");
            pStatusCharacteristic->notify();
            unlockDoor();  // Unlock the door (blink LED)
            logAccessAttempt(true);  // Log successful access
          }
          else
          {
            Serial.println("[ERROR] Cryptographic verification FAILED");
            currentUnlockState = STATE_DENIED;
            pStatusCharacteristic->setValue("DENIED_INVALID_SIGNATURE");
            pStatusCharacteristic->notify();
            logAccessAttempt(false);  // Log failed access
          }
        }
        else
        {
          Serial.println("[WARN] Received signature in wrong state. Ignoring.");
          pStatusCharacteristic->setValue("DENIED_INVALID_STATE");
          pStatusCharacteristic->notify();
        }
      }
    }
  }
};

bool init_ble()
{
#ifdef DEBUG
  Serial.println("[DEBUG] Initializing BLE");
#endif

  BLEDevice::init(BLE_DEVICE_NAME);
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  pService = pServer->createService(SERVICE_UUID);

  pIdCharacteristic = pService->createCharacteristic(ID_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
  pIdCharacteristic->setCallbacks(new MyCharacteristicCallbacks());
  pChallengeCharacteristic = pService->createCharacteristic(CHALLENGE_CHAR_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pSignatureCharacteristic = pService->createCharacteristic(SIGNATURE_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
  pSignatureCharacteristic->setCallbacks(new MyCharacteristicCallbacks());
  pStatusCharacteristic = pService->createCharacteristic(STATUS_CHAR_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);

  pService->start();

  Serial.println("[ INFO] BLE door MAC: " + BLEDevice::getAddress().toString());
  return true;
}

void start_ble_advertising()
{
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(BLE_ADV_MIN_INTERVAL);
  pAdvertising->setMaxPreferred(BLE_ADV_MAX_INTERVAL);
  BLEDevice::startAdvertising();

#ifdef DEBUG
  Serial.println("[DEBUG] Device advertising...");
#endif

  Serial.printf("[ INFO] BLE advertising as: %s\n", doorName.c_str());
}

void update_ble_device_name(String name)
{
  // Stop advertising first
  BLEDevice::stopAdvertising();

  // Deinitialize and reinitialize with new name
  BLEDevice::deinit(false);
  delay(100);

  BLEDevice::init(name.c_str());
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  pService = pServer->createService(SERVICE_UUID);

  pIdCharacteristic = pService->createCharacteristic(ID_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
  pIdCharacteristic->setCallbacks(new MyCharacteristicCallbacks());
  pChallengeCharacteristic = pService->createCharacteristic(CHALLENGE_CHAR_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pSignatureCharacteristic = pService->createCharacteristic(SIGNATURE_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
  pSignatureCharacteristic->setCallbacks(new MyCharacteristicCallbacks());
  pStatusCharacteristic = pService->createCharacteristic(STATUS_CHAR_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);

  pService->start();

  Serial.printf("[ INFO] BLE device name updated to: %s\n", name.c_str());
}

bool test_backend_connection()
{
  WiFiClientSecure secure_client;
  secure_client.setInsecure();

  String url = String(API_BASE_URL) + API_HEALTH_ENDPOINT;
  HTTPClient http;

#ifdef DEBUG
  Serial.printf("[DEBUG] Testing backend connection to: %s\n", url.c_str());
#endif

  if (!http.begin(secure_client, url))
  {
    Serial.printf("[ERROR] Unable to connect to %s\n", url.c_str());
    return false;
  }

  int httpCode = http.GET();
  String response = http.getString();
  http.end();

  if (httpCode == HTTP_SUCCESS_CODE && response.length() > 0)
  {
#ifdef DEBUG
    Serial.printf("[DEBUG] Health check response: %s\n", response.c_str());
#endif
    Serial.println("[ INFO] Backend connection successful");
    return true;
  }

  Serial.printf("[ERROR] HTTP GET failed, code: %d, error: %s\n",
                httpCode, http.errorToString(httpCode).c_str());
  return false;
}

String getPublicKeyFromBackend(String deviceId)
{
  if (WiFi.status() != WL_CONNECTED)
  {
    Serial.println("[ERROR] Not connected to WiFi. Cannot fetch public key.");
    return "";
  }

  WiFiClientSecure secure_client;
  secure_client.setInsecure();

  HTTPClient http;

  StaticJsonDocument<100> requestDoc;
  requestDoc["api_key"] = ESP32_API_KEY;
  String requestBody;
  serializeJson(requestDoc, requestBody);

  String url = String(API_BASE_URL) + "api/devices/" + deviceId + "/public-key";
#ifdef DEBUG
  Serial.printf("[DEBUG] Fetching public key from: %s\n", url.c_str());
#endif

  if (!http.begin(secure_client, url))
  {
    Serial.printf("[ERROR] Unable to connect to %s\n", url.c_str());
    return "";
  }

  http.addHeader("Content-Type", "application/json");
  int httpCode = http.POST(requestBody);

  if (httpCode == HTTP_SUCCESS_CODE)
  {
    DynamicJsonDocument responseDoc(1024);
    DeserializationError error = deserializeJson(responseDoc, http.getString());
    http.end();

    if (error)
    {
      Serial.printf("[ERROR] JSON parsing failed: %s\n", error.c_str());
      return "";
    }

    String publicKey = responseDoc["public_key"].as<String>();
    Serial.printf("[ INFO] Public key retrieved successfully: %s\n", publicKey.c_str());
    return publicKey;
  }
  else
  {
    Serial.printf("[ERROR] HTTP POST failed, code: %d, error: %s\n",
                  httpCode, http.errorToString(httpCode).c_str());
    http.end();
    return "";
  }
}

bool checkAccessPermission(String userId)
{
  if (WiFi.status() != WL_CONNECTED)
  {
    Serial.println("[ERROR] Not connected to WiFi. Cannot check access.");
    return false;
  }

  WiFiClientSecure secure_client;
  secure_client.setInsecure();
  HTTPClient http;

  StaticJsonDocument<256> requestDoc;
  requestDoc["user_id"] = userId.toInt();
  requestDoc["door_id"] = doorId;
  requestDoc["api_key"] = ESP32_API_KEY;

  String requestBody;
  serializeJson(requestDoc, requestBody);

  String url = String(API_BASE_URL) + "api/doors/check-access";

#ifdef DEBUG
  Serial.printf("[DEBUG] Checking access at: %s\n", url.c_str());
  Serial.printf("[DEBUG] Request body: %s\n", requestBody.c_str());
#endif

  if (!http.begin(secure_client, url))
  {
    Serial.printf("[ERROR] Unable to connect to %s\n", url.c_str());
    return false;
  }

  http.addHeader("Content-Type", "application/json");
  int httpCode = http.POST(requestBody);

  if (httpCode == HTTP_SUCCESS_CODE)
  {
    DynamicJsonDocument responseDoc(512);
    DeserializationError error = deserializeJson(responseDoc, http.getString());
    http.end();

    if (error)
    {
      Serial.printf("[ERROR] JSON parsing failed: %s\n", error.c_str());
      return false;
    }

    bool allowed = responseDoc["allowed"].as<bool>();
    const char *reason = responseDoc["reason"];

    Serial.printf("[ INFO] Access check: %s (reason: %s)\n",
                  allowed ? "ALLOWED" : "DENIED", reason);

    if (!allowed)
    {
      String statusMsg = String("DENIED_") + reason;
      pStatusCharacteristic->setValue(statusMsg.c_str());
      pStatusCharacteristic->notify();
    }

    return allowed;
  }
  else
  {
    Serial.printf("[ERROR] HTTP POST failed, code: %d, error: %s\n",
                  httpCode, http.errorToString(httpCode).c_str());
    http.end();
    return false;
  }
}

bool verifyRSASignature(String publicKeyPEM, String challenge, String signatureBase64)
{
  // Decode base64 signature using mbedTLS
  size_t outputLen;
  int signatureLen = signatureBase64.length() * 3 / 4 + 4;  // Add padding
  unsigned char signature[signatureLen];

  int ret = mbedtls_base64_decode(signature, signatureLen, &outputLen,
                                   (const unsigned char *)signatureBase64.c_str(),
                                   signatureBase64.length());

  if (ret != 0)
  {
    Serial.printf("[ERROR] Failed to decode base64 signature: -0x%04x\n", -ret);
    return false;
  }

#ifdef DEBUG
  Serial.printf("[DEBUG] Decoded signature length: %d bytes\n", outputLen);
#endif

  // Initialize mbedtls structures
  mbedtls_pk_context pk;
  mbedtls_pk_init(&pk);

  // Parse public key
  ret = mbedtls_pk_parse_public_key(&pk,
                                     (const unsigned char *)publicKeyPEM.c_str(),
                                     publicKeyPEM.length() + 1);
  if (ret != 0)
  {
    char error_buf[100];
    mbedtls_strerror(ret, error_buf, sizeof(error_buf));
    Serial.printf("[ERROR] Failed to parse public key: -0x%04x (%s)\n", -ret, error_buf);
    mbedtls_pk_free(&pk);
    return false;
  }

#ifdef DEBUG
  Serial.println("[DEBUG] Public key parsed successfully");
#endif

  // Hash the challenge with SHA-256
  unsigned char hash[32];
  mbedtls_md_context_t md_ctx;
  mbedtls_md_init(&md_ctx);
  mbedtls_md_setup(&md_ctx, mbedtls_md_info_from_type(MBEDTLS_MD_SHA256), 0);
  mbedtls_md_starts(&md_ctx);
  mbedtls_md_update(&md_ctx, (const unsigned char *)challenge.c_str(), challenge.length());
  mbedtls_md_finish(&md_ctx, hash);
  mbedtls_md_free(&md_ctx);

#ifdef DEBUG
  Serial.print("[DEBUG] Challenge hash: ");
  for (int i = 0; i < 32; i++)
  {
    Serial.printf("%02x", hash[i]);
  }
  Serial.println();
#endif

  // Verify signature
  ret = mbedtls_pk_verify(&pk, MBEDTLS_MD_SHA256, hash, 32, signature, outputLen);

  mbedtls_pk_free(&pk);

  if (ret == 0)
  {
    Serial.println("[ INFO] RSA signature verification PASSED");
    return true;
  }
  else
  {
    char error_buf[100];
    mbedtls_strerror(ret, error_buf, sizeof(error_buf));
    Serial.printf("[ERROR] RSA signature verification FAILED: -0x%04x (%s)\n", -ret, error_buf);
    return false;
  }
}

void logAccessAttempt(bool success)
{
  if (WiFi.status() != WL_CONNECTED)
  {
    Serial.println("[WARN] Not connected to WiFi. Cannot log access attempt.");
    return;
  }

  WiFiClientSecure secure_client;
  secure_client.setInsecure();
  HTTPClient http;

  StaticJsonDocument<512> requestDoc;
  requestDoc["user_id"] = receivedUserId.toInt();
  requestDoc["door_id"] = doorId;
  requestDoc["device_id"] = receivedDeviceId.toInt();
  requestDoc["action"] = "unlock";
  requestDoc["success"] = success;

  if (!success)
  {
    requestDoc["failure_reason"] = String(pStatusCharacteristic->getValue().c_str());
  }

  requestDoc["ip_address"] = WiFi.localIP().toString();
  requestDoc["api_key"] = ESP32_API_KEY;

  String requestBody;
  serializeJson(requestDoc, requestBody);

  String url = String(API_BASE_URL) + "api/access-logs/";  // Added trailing slash

#ifdef DEBUG
  Serial.printf("[DEBUG] Logging access at: %s\n", url.c_str());
  Serial.printf("[DEBUG] Request body: %s\n", requestBody.c_str());
#endif

  if (!http.begin(secure_client, url))
  {
    Serial.printf("[ERROR] Unable to connect to %s\n", url.c_str());
    return;
  }

  http.addHeader("Content-Type", "application/json");
  http.setFollowRedirects(HTTPC_STRICT_FOLLOW_REDIRECTS);  // Follow redirects
  int httpCode = http.POST(requestBody);

  if (httpCode == HTTP_SUCCESS_CODE || httpCode == 201)
  {
    Serial.println("[ INFO] Access attempt logged successfully");
  }
  else if (httpCode == 308 || httpCode == 301 || httpCode == 302)
  {
    // Handle redirect - get new location
    String redirectUrl = http.getLocation();
    http.end();

    Serial.printf("[WARN] Server redirected to: %s\n", redirectUrl.c_str());
    Serial.println("[WARN] Retrying with redirected URL...");

    // Retry with the redirect URL
    if (http.begin(secure_client, redirectUrl))
    {
      http.addHeader("Content-Type", "application/json");
      httpCode = http.POST(requestBody);

      if (httpCode == HTTP_SUCCESS_CODE || httpCode == 201)
      {
        Serial.println("[ INFO] Access attempt logged successfully (after redirect)");
      }
      else
      {
        Serial.printf("[WARN] Failed to log access after redirect: %d\n", httpCode);
      }
    }
  }
  else
  {
    Serial.printf("[WARN] Failed to log access: %d\n", httpCode);
#ifdef DEBUG
    Serial.printf("[DEBUG] Response: %s\n", http.getString().c_str());
#endif
  }

  http.end();
}

void updateLedState()
{
  unsigned long currentMillis = millis();

  switch (currentLedState)
  {
  case LED_OFF:
    digitalWrite(LED_BUILTIN, LOW);
    break;

  case LED_ON_IDLE:
    // Solid ON when operational and idle
    digitalWrite(LED_BUILTIN, HIGH);
    break;

  case LED_SLOW_BLINK_CONFIG:
    // Slow blink (1 second interval) when not registered
    if (currentMillis - ledLastToggle >= LED_SLOW_BLINK_INTERVAL_MS)
    {
      ledCurrentState = !ledCurrentState;
      digitalWrite(LED_BUILTIN, ledCurrentState ? HIGH : LOW);
      ledLastToggle = currentMillis;
    }
    break;

  case LED_FAST_BLINK_UNLOCK:
    // Fast blink (100ms interval) for 7 seconds during unlock
    if (currentMillis - unlockStartTime >= LED_BLINK_DURATION_MS)
    {
      // Unlock period finished, return to idle state
      currentLedState = LED_ON_IDLE;
      digitalWrite(LED_BUILTIN, HIGH);
      Serial.println("[ INFO] Door lock cycle complete");
    }
    else
    {
      // Continue fast blinking
      if (currentMillis - ledLastToggle >= LED_BLINK_INTERVAL_MS)
      {
        ledCurrentState = !ledCurrentState;
        digitalWrite(LED_BUILTIN, ledCurrentState ? HIGH : LOW);
        ledLastToggle = currentMillis;
      }
    }
    break;
  }
}

void unlockDoor()
{
  Serial.println("[ INFO] UNLOCKING DOOR - Blinking LED");

  // Start fast LED blink
  currentLedState = LED_FAST_BLINK_UNLOCK;
  unlockStartTime = millis();
  ledLastToggle = millis();
  ledCurrentState = false;
}

String get_ble_mac_address()
{
  return BLEDevice::getAddress().toString();
}

bool register_with_backend()
{
  Serial.println("[ INFO] Attempting to register with backend...");

  if (WiFi.status() != WL_CONNECTED)
  {
    Serial.println("[ERROR] Not connected to WiFi. Cannot register.");
    return false;
  }

  String macAddress = get_ble_mac_address();
  macAddress.toUpperCase();  // Normalize to uppercase

  Serial.printf("[ INFO] BLE MAC Address: %s\n", macAddress.c_str());

  WiFiClientSecure secure_client;
  secure_client.setInsecure();
  HTTPClient http;

  StaticJsonDocument<256> requestDoc;
  requestDoc["api_key"] = ESP32_API_KEY;
  requestDoc["mac_address"] = macAddress;

  String requestBody;
  serializeJson(requestDoc, requestBody);

  String url = String(API_BASE_URL) + "api/doors/configure";

#ifdef DEBUG
  Serial.printf("[DEBUG] Registering at: %s\n", url.c_str());
  Serial.printf("[DEBUG] Request body: %s\n", requestBody.c_str());
#endif

  if (!http.begin(secure_client, url))
  {
    Serial.printf("[ERROR] Unable to connect to %s\n", url.c_str());
    return false;
  }

  http.addHeader("Content-Type", "application/json");
  int httpCode = http.POST(requestBody);

  if (httpCode == HTTP_SUCCESS_CODE)
  {
    DynamicJsonDocument responseDoc(256);
    DeserializationError error = deserializeJson(responseDoc, http.getString());
    http.end();

    if (error)
    {
      Serial.printf("[ERROR] JSON parsing failed: %s\n", error.c_str());
      return false;
    }

    doorId = responseDoc["door_id"].as<int>();
    doorName = responseDoc["door_name"].as<String>();

    Serial.printf("[ INFO] Registration successful!\n");
    Serial.printf("[ INFO] Door ID: %d\n", doorId);
    Serial.printf("[ INFO] Door Name: %s\n", doorName.c_str());

    return true;
  }
  else if (httpCode == 404)
  {
    Serial.printf("[ERROR] No door configured for MAC address %s\n", macAddress.c_str());
    Serial.println("[ERROR] Please configure this ESP32 in the backend first.");
    http.end();
    return false;
  }
  else if (httpCode == 403)
  {
    Serial.println("[ERROR] Door is disabled in backend.");
    http.end();
    return false;
  }
  else
  {
    Serial.printf("[ERROR] Registration failed, code: %d, error: %s\n",
                  httpCode, http.errorToString(httpCode).c_str());
    http.end();
    return false;
  }
}

void setup()
{
  Serial.begin(115200);
  randomSeed(micros());
  Serial.println("[ INFO] Booting Aditus Door Controller");

  // Initialize LED GPIO
  pinMode(LED_BUILTIN, OUTPUT);
  currentLedState = LED_OFF;
  digitalWrite(LED_BUILTIN, LOW);  // Start with LED off
  Serial.printf("[ INFO] LED initialized on pin %d\n", LED_BUILTIN);

  // Initialize BLE (but don't start advertising yet)
  if (!init_ble())
  {
    Serial.println("[ERROR] Could not initialize BLE. Restarting...");
    delay(5000);
    ESP.restart();
  }

  // Initialize WiFi
  if (!init_wifi())
  {
    Serial.println("[WARN] Could not initialize WiFi.");
    Serial.println("[WARN] Will retry registration in loop...");
    // Don't halt - retry in loop
    return;
  }

  // Attempt to register with backend
  Serial.println("[ INFO] Attempting initial registration...");
  if (register_with_backend())
  {
    isRegistered = true;

    // Update BLE device name with door name from backend
    update_ble_device_name(doorName);

    // Start BLE advertising
    start_ble_advertising();

    // Set LED to solid ON (operational state)
    currentLedState = LED_ON_IDLE;

    Serial.println("[ INFO] Door controller initialized and registered successfully");
  }
  else
  {
    Serial.println("[WARN] Initial registration failed. Will retry every 10 seconds...");
    Serial.println("[WARN] BLE advertising disabled until registration succeeds.");
    // LED will blink slowly in loop() to indicate not registered
    currentLedState = LED_SLOW_BLINK_CONFIG;
    lastRegistrationAttempt = millis();
  }
}

void loop()
{
  // Update LED state continuously
  updateLedState();

  // Handle registration retry if not registered
  if (!isRegistered)
  {
    // LED is managed by updateLedState() in SLOW_BLINK_CONFIG mode

    // Retry registration every 10 seconds
    if (millis() - lastRegistrationAttempt > REGISTRATION_RETRY_INTERVAL_MS)
    {
      Serial.println("[ INFO] Retrying registration...");

      // Ensure WiFi is connected
      if (WiFi.status() != WL_CONNECTED)
      {
        Serial.println("[WARN] WiFi not connected, attempting reconnection...");
        init_wifi();
      }

      // Attempt registration
      if (WiFi.status() == WL_CONNECTED && register_with_backend())
      {
        isRegistered = true;

        // Update BLE device name with door name from backend
        update_ble_device_name(doorName);

        // Start BLE advertising
        start_ble_advertising();

        // Set LED to solid ON (operational state)
        currentLedState = LED_ON_IDLE;

        Serial.println("[ INFO] Registration successful! Door is now operational.");
      }

      lastRegistrationAttempt = millis();
    }

    // Don't process other logic if not registered
    delay(10);
    return;
  }

  // === From here on, ESP32 is registered and operational ===

  // Handle BLE connection state changes
  if (!deviceConnected && oldDeviceConnected)
  {
    // Client just disconnected, restart advertising
    delay(500);
    pServer->startAdvertising();
    Serial.println("[ INFO] Restarting BLE advertising");
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected)
  {
    oldDeviceConnected = deviceConnected;
  }

  // Monitor WiFi connection and reconnect if needed
  static unsigned long lastWiFiCheck = 0;
  if (millis() - lastWiFiCheck > 30000)  // Check every 30 seconds
  {
    if (WiFi.status() != WL_CONNECTED)
    {
      Serial.println("[WARN] WiFi disconnected, reconnecting...");
      init_wifi();
    }
    lastWiFiCheck = millis();
  }

  // Timeout signature wait state
  if (currentUnlockState == STATE_WAITING_FOR_SIGNATURE)
  {
    if (millis() - stateStartTime > SIGNATURE_TIMEOUT_MS)
    {
      Serial.println("[WARN] Signature timeout, returning to idle");
      pStatusCharacteristic->setValue("DENIED_TIMEOUT");
      pStatusCharacteristic->notify();
      logAccessAttempt(false);  // Log failed attempt
      currentUnlockState = STATE_IDLE;
    }
  }

  delay(10);
}