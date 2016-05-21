0 constant NULL_MODE
1 constant STATION_MODE
2 constant SOFTAP_MODE
3 constant STATIONAP_MODE
4 constant MAX_MODE

5000 constant WIFI_ERROR

\ redefine this word after you loaded the wifi package
: wifi-config ( -- password ssid )
    s" UNDEFD"      \ password
    s" UNDEFD" ;    \ ssid    

: wifi-connect ( -- )
    STATION_MODE wifi-set-mode 1 <> if
        WIFI_ERROR throw
    then
    s" wifi-config" 11 find link>xt execute
    wifi-set-station-config 1 <> if
        WIFI_ERROR throw
    then ;

