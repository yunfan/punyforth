
#ifndef __TCP_SHELL_H__
#define __TCP_SHELL_H__

#ifdef __cplusplus
extern "C" {
#endif

#ifndef MAX_PACKET_SIZE
#define MAX_PACKET_SIZE 1500
#endif

#define FORTH_TCP_PORT 8888

void ICACHE_FLASH_ATTR tcp_shell_init();

int ICACHE_FLASH_ATTR tcp_shell_is_connected();

void ICACHE_FLASH_ATTR tcp_shell_put_char(char ch);

void ICACHE_FLASH_ATTR tcp_shell_put_chars(char* buffer, int bufsize);

char ICACHE_FLASH_ATTR tcp_shell_read_char();

#ifdef __cplusplus
}
#endif

#endif
