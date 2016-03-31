#include <string.h>
#include "espressif/esp_common.h"
#include "FreeRTOS.h"
#include "lwip/api.h"
#include "lwip/ip_addr.h"

struct netconn* forth_netconn_new(int type) {
    enum netconn_type con_type;
    printf("New netconn type: %d\n", type);
    switch (type) {
        case 1: con_type = NETCONN_UDP; break;
        case 2: con_type = NETCONN_TCP; break;
        default: return NULL;
    }
    struct netconn* conn = netconn_new(con_type);
    printf("Connection ready: %p\n", conn);
    return conn;
}

int forth_netconn_connect(struct netconn* conn, char* host, int port) {   
    err_t err; ip_addr_t ip;
    printf("Getting hostname: %s\n", host);
    err = netconn_gethostbyname(host, &ip);
    if (err != ERR_OK) {
        printf("Failed to resolve host %s. Error: %d\n", host, err);
        return err;
    }
    printf("Connecting to: %s:%d conn: %p\n", host, port, conn);
    err = netconn_connect(conn, &ip, (u16_t)(port & 0xFFFF));
    if (err != ERR_OK) {
        printf("Failed to connect to %s:%d. Error: %d\n", host, port, err);
    }
    return err;
}

int forth_netconn_send(struct netconn* conn, void* data, int len) {
    printf("Sending data len: %d conn: %p\n", len, conn);
    err_t err;
    uint16_t len16 = len;
    struct netbuf* buffer = netbuf_new();
    memcpy(netbuf_alloc(buffer, len16), data, len16);
    err = netconn_send(conn, buffer);
    if (err != ERR_OK) {
        printf("Failed to send data. Conn: %p. Error: %d\n", conn, err);
    }   
    netbuf_delete(buffer);
    return err;
}

int forth_netconn_write(struct netconn* conn, void* data, int len) {
    printf("Sending data len: %d conn: %p\n", len, conn);
    err_t err;
    uint16_t len16 = len;
    err = netconn_write(conn, data, len16, NETCONN_NOCOPY);
    if (err != ERR_OK) {
        printf("Failed to send data. Conn: %p. Error: %d\n", conn, err);
    }   
    return err;
}

struct recv_res {
    int code;
    char *buffer;
    int size;
};
/*
struct recv_res forth_netconn_recv(struct netconn* conn) {
    printf("Receiving data conn: %p\n", conn);
    err_t err;
    char *buf;
    u16_t size;
    struct netbuf *inbuf;
    while ((err = netconn_recv(conn, &inbuf)) == ERR_OK) {
        do {
            netbuf_data(inbuf, (void **)&buf, &size);        
            printf("Data received. Size: %d. Buf: %p\n", size, buf);
        } while (netbuf_next(inbuf) >= 0);
    }
    netbuf_delete(inbuf);
    struct recv_res result = { .code = err, .size = size, .buffer = buf };
    printf("Received: %.*s\n", size, buf);
    return result;
}
*/

struct recvinto_res {
    int code;
    int count;
};

struct recvinto_res forth_netconn_recvinto(struct netconn* conn, void* buffer, int size) {
    printf("receiving buffer %p max size: %d\n", buffer, size);
    err_t err;
    u16_t count = 0;
    struct netbuf *inbuf;
    err = netconn_recv(conn, &inbuf);
    if (err == ERR_OK) {
        count = netbuf_copy(inbuf, buffer, size);
        printf("Received: %d\n", count);
    }
    netbuf_delete(inbuf);
    struct recvinto_res result = { .code = err, .count = count };
    return result;
}

void forth_netconn_dispose(struct netconn* conn) {
    printf("Disposing connection %p\n", conn);
    netconn_close(conn);
    netconn_delete(conn);
}
