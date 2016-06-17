0 constant NULL_MODE
1 constant STATION_MODE
2 constant SOFTAP_MODE
3 constant STATIONAP_MODE
4 constant MAX_MODE

5000 constant WIFI_ERROR

: wifi-connect ( password ssid  -- )
    STATION_MODE wifi-set-mode 1 <> if
        WIFI_ERROR throw
    then
    wifi-set-station-config 1 <> if
        WIFI_ERROR throw
    then ;
