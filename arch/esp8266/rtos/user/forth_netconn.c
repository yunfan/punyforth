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

int forth_netconn_listen(struct netconn *conn) {
    return netconn_listen(conn);
}

int forth_netconn_bind(struct netconn* conn, char* host, int port) {   
    err_t err; ip_addr_t ip;
    printf("Getting hostname: %s\n", host);
    err = netconn_gethostbyname(host, &ip);
    if (err != ERR_OK) {
        printf("Failed to resolve host %s. Error: %d\n", host, err);
        return err;
    }
    printf("Binding to: %s:%d conn: %p\n", host, port, conn);
    err = netconn_bind(conn, &ip, (u16_t)(port & 0xFFFF));
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
    if (buffer == NULL) {
        return ERR_MEM;
    }
    void* memory = netbuf_alloc(buffer, len16);
    if (memory == NULL) {
        return ERR_MEM;
    }
    memcpy(memory, data, len16);
    err = netconn_send(conn, buffer);
    if (err != ERR_OK) {
        printf("Failed to send data. Conn: %p. Error: %d\n", conn, err);
    }   
    netbuf_delete(buffer);
    return err;
}

int forth_netconn_write(struct netconn* conn, void* data, int len) {
    printf("Writing data len: %d conn: %p\n", len, conn);
    err_t err;
    uint16_t len16 = len;
    err = netconn_write(conn, data, len16, NETCONN_NOCOPY | NETCONN_MORE);
    if (err != ERR_OK) {
        printf("Failed to write data. Conn: %p. Error: %d\n", conn, err);
    }   
    return err;
}

struct recv_res {
    int code;
    struct netbuf* nbuf;
};

struct recv_res forth_netconn_recv(struct netconn* conn) {
    //printf("Receiving from connection: %p\n", conn);
    err_t err;
    struct netbuf *inbuf;
    err = netconn_recv(conn, &inbuf);
    struct recv_res result = { .code = err, .nbuf = inbuf };
    return result;
}

struct netbuf_data_res {
    int size;
    char *buffer;
};

struct netbuf_data_res forth_netbuf_data(struct netbuf *nbuf) {
    printf("Data netbuf: %p\n", nbuf);
    char *buf;
    u16_t size;
    netbuf_data(nbuf, (void **)&buf, &size);        
    struct netbuf_data_res result = { .buffer = buf, .size = size };
    return result;
}

int forth_netbuf_next(struct netbuf *nbuf) {
    printf("Next of netbuf: %p\n", nbuf);
    return netbuf_next(nbuf);
}

void forth_netbufdel(struct netbuf* netbuf) {
    printf("Deleting netbuf: %p\n", netbuf);
    netbuf_delete(netbuf);
}

struct recvinto_res {
    int code;
    int count;
};

struct recvinto_res forth_netconn_recvinto(struct netconn* conn, void* buffer, int size) {
    //printf("receiving buffer %p max size: %d\n", buffer, size);
    err_t err;
    struct netbuf *inbuf;
    int offset = 0;
    while ((err = netconn_recv(conn, &inbuf)) == ERR_OK && size - offset > 0) {
        offset += netbuf_copy(inbuf, buffer + offset, size - offset);
        printf("offs: %d\n", offset);
        netbuf_delete(inbuf);
    }
    struct recvinto_res result = { 
        .code = offset == 0 ? err : ERR_OK, 
        .count = offset
    };
    return result;
}

struct accept_res {
    int code;
    struct netconn* conn;
};

struct accept_res forth_netconn_accept(struct netconn* conn) {
    struct netconn *new_conn;
    err_t code = netconn_accept(conn, &new_conn);
    struct accept_res result = {
        .code =  code,
        .conn = new_conn
    };
    return result;
}
 
void forth_netconn_dispose(struct netconn* conn) {
    printf("Disposing connection %p\n", conn);
    netconn_close(conn);
    netconn_delete(conn);
}

void forth_netconn_close(struct netconn* conn) {
    printf("Closing connection %p\n", conn);
    netconn_close(conn);
}

void forth_netconn_set_recvtimeout(struct netconn* conn, int timeout) {
    netconn_set_recvtimeout(conn, timeout);
}
