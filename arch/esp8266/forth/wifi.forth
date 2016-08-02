0 constant: NULL_MODE
1 constant: STATION_MODE
2 constant: SOFTAP_MODE
3 constant: STATIONAP_MODE
4 constant: MAX_MODE

0 constant: AUTH_OPEN
1 constant: AUTH_WEP
2 constant: AUTH_WPA_PSK
3 constant: AUTH_WPA2_PSK
4 constant: AUTH_WPA_WPA2_PSK
5 constant: AUTH_MAX

5000 constant: EWIFI

: >ipv4 ( octet1 octet2 octet3 octet4 -- n )
    255 and 24 lshift >r
    255 and 16 lshift >r
    255 and  8 lshift >r
    255 and           >r
    r> r> r> r>
    or or or ;
    
: check-status ( status -- | throws:EWIFI )
    1 <> if EWIFI throw then ;
    
\ Connect to an existing Wi-Fi access point with the given ssid and password
\ For example:
\   str: "ap-pass" str: "ap-ssid" wifi-connect
: wifi-connect ( password ssid  -- | throws:EWIFI )
    STATION_MODE wifi-set-mode check-status
    wifi-set-station-config check-status
    wifi-station-connect check-status ;

\ Creates an access point mode with the given properties
\ For example:
\   172 16 0 1 >ipv4 wifi-set-ip
\   1 3 0 AUTH_WPA2_PSK str: "1234567890" str: "my-ssid" wifi-softap
\   4 172 16 0 2 >ipv4 dhcpd-start
: wifi-softap ( max-connections channels hidden authmode password ssid -- | throws:EWIFI )
    SOFTAP_MODE wifi-set-mode check-status
    wifi-set-softap-config check-status ;
    
: wifi-ip ( -- str )
    here 16 allot
    16 over wifi-ip-str ;
