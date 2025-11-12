#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "esp_bt.h"
#include "esp_gap_ble_api.h"
#include "esp_gatts_api.h"
#include "esp_bt_main.h"
#include "esp_gatt_common_api.h"
#include "driver/gpio.h"

#define TAG "MICROWAVE_BLE"
#define DEVICE_NAME "Smart_Microondas_ESP32"
#define LED_PIN 2

// Service and Characteristics UUIDs
#define SERVICE_UUID        0x00FF
#define CHAR_UUID_RX        0xFF01
#define CHAR_UUID_TX        0xFF02

#define GATTS_NUM_HANDLE    6
#define MAX_DATA_LEN        500

static uint16_t handle_table[GATTS_NUM_HANDLE];
static uint16_t conn_id = 0;
static esp_gatt_if_t gatts_if_global = ESP_GATT_IF_NONE;
static bool is_connected = false;

static uint8_t rx_buffer[MAX_DATA_LEN] = {0};
static uint8_t tx_buffer[MAX_DATA_LEN] = {0};

static esp_ble_adv_params_t adv_params = {
    .adv_int_min = 0x20,
    .adv_int_max = 0x40,
    .adv_type = ADV_TYPE_IND,
    .own_addr_type = BLE_ADDR_TYPE_PUBLIC,
    .channel_map = ADV_CHNL_ALL,
    .adv_filter_policy = ADV_FILTER_ALLOW_SCAN_ANY_CON_ANY,
};

static esp_ble_adv_data_t adv_data = {
    .set_scan_rsp = false,
    .include_name = true,
    .include_txpower = true,
    .min_interval = 0x0006,
    .max_interval = 0x0010,
    .appearance = 0x00,
    .manufacturer_len = 0,
    .p_manufacturer_data = NULL,
    .service_data_len = 0,
    .p_service_data = NULL,
    .service_uuid_len = 0,
    .p_service_uuid = NULL,
    .flag = (ESP_BLE_ADV_FLAG_GEN_DISC | ESP_BLE_ADV_FLAG_BREDR_NOT_SPT),
};

static const uint16_t primary_service_uuid = ESP_GATT_UUID_PRI_SERVICE;
static const uint16_t character_declaration_uuid = ESP_GATT_UUID_CHAR_DECLARE;
static const uint16_t character_client_config_uuid = ESP_GATT_UUID_CHAR_CLIENT_CONFIG;

static const uint8_t char_prop_read_write = ESP_GATT_CHAR_PROP_BIT_WRITE | ESP_GATT_CHAR_PROP_BIT_READ;
static const uint8_t char_prop_read_notify = ESP_GATT_CHAR_PROP_BIT_READ | ESP_GATT_CHAR_PROP_BIT_NOTIFY;

static const esp_gatts_attr_db_t gatt_db[GATTS_NUM_HANDLE] = {
    [0] = {{ESP_GATT_AUTO_RSP}, {ESP_UUID_LEN_16, (uint8_t *)&primary_service_uuid, 
            ESP_GATT_PERM_READ, sizeof(uint16_t), sizeof(SERVICE_UUID), (uint8_t *)&SERVICE_UUID}},

    [1] = {{ESP_GATT_AUTO_RSP}, {ESP_UUID_LEN_16, (uint8_t *)&character_declaration_uuid, 
            ESP_GATT_PERM_READ, 1, 1, (uint8_t *)&char_prop_read_write}},
    [2] = {{ESP_GATT_AUTO_RSP}, {ESP_UUID_LEN_16, (uint8_t *)&CHAR_UUID_RX, 
            ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE, MAX_DATA_LEN, sizeof(rx_buffer), rx_buffer}},

    [3] = {{ESP_GATT_AUTO_RSP}, {ESP_UUID_LEN_16, (uint8_t *)&character_declaration_uuid, 
            ESP_GATT_PERM_READ, 1, 1, (uint8_t *)&char_prop_read_notify}},
    [4] = {{ESP_GATT_AUTO_RSP}, {ESP_UUID_LEN_16, (uint8_t *)&CHAR_UUID_TX, 
            ESP_GATT_PERM_READ, MAX_DATA_LEN, sizeof(tx_buffer), tx_buffer}},
    [5] = {{ESP_GATT_AUTO_RSP}, {ESP_UUID_LEN_16, (uint8_t *)&character_client_config_uuid, 
            ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE, sizeof(uint16_t), 0, NULL}},
};

void send_notification(const char *message) {
    if (!is_connected) return;
    
    size_t len = strlen(message);
    if (len > MAX_DATA_LEN) len = MAX_DATA_LEN;
    
    esp_ble_gatts_send_indicate(gatts_if_global, conn_id, handle_table[4], 
                                len, (uint8_t *)message, false);
    
    ESP_LOGI(TAG, "Sent: %s", message);
}

void process_command(const char *command) {
    ESP_LOGI(TAG, "Received: %s", command);
    
    if (strcmp(command, "PING") == 0) {
        send_notification("PONG");
        gpio_set_level(LED_PIN, 1);
        vTaskDelay(pdMS_TO_TICKS(100));
        gpio_set_level(LED_PIN, 0);
    }
    else {
        char response[MAX_DATA_LEN];
        snprintf(response, sizeof(response), "OK:%s", command);
        send_notification(response);
    }
}

static void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param) {
    switch (event) {
    case ESP_GAP_BLE_ADV_DATA_SET_COMPLETE_EVT:
        esp_ble_gap_start_advertising(&adv_params);
        break;
        
    case ESP_GAP_BLE_ADV_START_COMPLETE_EVT:
        if (param->adv_start_cmpl.status == ESP_BT_STATUS_SUCCESS) {
            ESP_LOGI(TAG, "Advertising started");
        }
        break;
        
    default:
        break;
    }
}

static void gatts_event_handler(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if, 
                                esp_ble_gatts_cb_param_t *param) {
    switch (event) {
    case ESP_GATTS_REG_EVT:
        ESP_LOGI(TAG, "GATT server registered");
        esp_ble_gap_set_device_name(DEVICE_NAME);
        esp_ble_gap_config_adv_data(&adv_data);
        esp_ble_gatts_create_attr_tab(gatt_db, gatts_if, GATTS_NUM_HANDLE, 0);
        break;
        
    case ESP_GATTS_CREAT_ATTR_TAB_EVT:
        if (param->add_attr_tab.status == ESP_GATT_OK) {
            ESP_LOGI(TAG, "Attribute table created");
            memcpy(handle_table, param->add_attr_tab.handles, sizeof(handle_table));
            esp_ble_gatts_start_service(handle_table[0]);
        }
        break;
        
    case ESP_GATTS_CONNECT_EVT:
        ESP_LOGI(TAG, "Client CONNECTED");
        conn_id = param->connect.conn_id;
        gatts_if_global = gatts_if;
        is_connected = true;
        
        for (int i = 0; i < 3; i++) {
            gpio_set_level(LED_PIN, 1);
            vTaskDelay(pdMS_TO_TICKS(100));
            gpio_set_level(LED_PIN, 0);
            vTaskDelay(pdMS_TO_TICKS(100));
        }
        
        vTaskDelay(pdMS_TO_TICKS(500));
        send_notification("CONNECTED");
        break;
        
    case ESP_GATTS_DISCONNECT_EVT:
        ESP_LOGI(TAG, "Client DISCONNECTED");
        is_connected = false;
        esp_ble_gap_start_advertising(&adv_params);
        break;
        
    case ESP_GATTS_WRITE_EVT:
        if (param->write.handle == handle_table[2]) {
            char command[MAX_DATA_LEN];
            memcpy(command, param->write.value, param->write.len);
            command[param->write.len] = '\0';
            process_command(command);
        }
        break;
        
    default:
        break;
    }
}

void app_main(void) {
    esp_err_t ret;
    
    ESP_LOGI(TAG, "Starting Smart Microondas BLE...");
    
    gpio_reset_pin(LED_PIN);
    gpio_set_direction(LED_PIN, GPIO_MODE_OUTPUT);
    gpio_set_level(LED_PIN, 0);
    
    ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);
    
    ESP_ERROR_CHECK(esp_bt_controller_mem_release(ESP_BT_MODE_CLASSIC_BT));
    
    esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
    ret = esp_bt_controller_init(&bt_cfg);
    if (ret) {
        ESP_LOGE(TAG, "BT controller init failed: %s", esp_err_to_name(ret));
        return;
    }
    
    ret = esp_bt_controller_enable(ESP_BT_MODE_BLE);
    if (ret) {
        ESP_LOGE(TAG, "BT controller enable failed: %s", esp_err_to_name(ret));
        return;
    }
    
    ret = esp_bluedroid_init();
    if (ret) {
        ESP_LOGE(TAG, "Bluedroid init failed: %s", esp_err_to_name(ret));
        return;
    }
    
    ret = esp_bluedroid_enable();
    if (ret) {
        ESP_LOGE(TAG, "Bluedroid enable failed: %s", esp_err_to_name(ret));
        return;
    }
    
    esp_ble_gatts_register_callback(gatts_event_handler);
    esp_ble_gap_register_callback(gap_event_handler);
    esp_ble_gatts_app_register(0);
    esp_ble_gatt_set_local_mtu(517);
    
    ESP_LOGI(TAG, "BLE initialized!");
    ESP_LOGI(TAG, "Device name: %s", DEVICE_NAME);
    ESP_LOGI(TAG, "Waiting for connection...");
}