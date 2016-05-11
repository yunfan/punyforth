0 constant: NULL_MODE
1 constant: STATION_MODE
2 constant: SOFTAP_MODE
3 constant: STATIONAP_MODE
4 constant: MAX_MODE

5000 constant: EWIFI

: wifi-connect ( password ssid  -- | throws:EWIFI )
    STATION_MODE wifi-set-mode 1 <> if
        EWIFI throw
    then
    wifi-set-station-config 1 <> if
        EWIFI throw
    then ;

: wifi-ip ( -- str )
    here 16 allot
    16 over wifi-ip-str ;