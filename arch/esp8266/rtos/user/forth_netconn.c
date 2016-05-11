#include <string.h>
#include "espressif/esp_common.h"
#include "FreeRTOS.h"
#include "lwip/api.h"
#include "lwip/ip_addr.h"

#define CACHE_SIZE 256

struct forth_netconn {
    struct netconn* conn;
    char *cache;
    int cache_start;
    int cache_end;
};

int cache_data_len(struct forth_netconn* conn) {
    return conn->cache_end - conn->cache_start; 
}

int cache_free_space(struct forth_netconn* conn) {
    return CACHE_SIZE - conn->cache_end; 
}

struct forth_netconn* make_forth_netconn(struct netconn* conn) {
    if (conn == NULL) return NULL;
    struct forth_netconn *result = malloc(sizeof(struct forth_netconn));
    result->conn = conn;
    result->cache = (char*) malloc(CACHE_SIZE);
    result->cache_start = 0;
    result->cache_end = 0;
    return result;
}

struct forth_netconn* forth_netcon_new(int type) {
    enum netconn_type con_type;
    printf("New netcon type: %d\n", type);
    switch (type) {
        case 1: con_type = NETCONN_UDP; break;
        case 2: con_type = NETCONN_TCP; break;
        default: return NULL;
    }
    struct netconn* conn = netconn_new(con_type);
    printf("Connection ready: %p\n", conn);
    return make_forth_netconn(conn);
}

int forth_netcon_connect(struct forth_netconn* conn, char* host, int port) {   
    err_t err; ip_addr_t ip;
    printf("Getting hostname: %s\n", host);
    err = netconn_gethostbyname(host, &ip);
    if (err != ERR_OK) {
        printf("Failed to resolve host %s. Error: %d\n", host, err);
        return err;
    }
    printf("Connecting to: %s:%d conn: %p\n", host, port, conn);
    err = netconn_connect(conn->conn, &ip, (u16_t)(port & 0xFFFF));
    if (err != ERR_OK) {
        printf("Failed to connect to %s:%d. Error: %d\n", host, port, err);
    }
    return err;
}

int forth_netcon_listen(struct forth_netconn *conn) {
    return netconn_listen(conn->conn);
}

int forth_netcon_bind(struct forth_netconn* conn, char* host, int port) {   
    err_t err; ip_addr_t ip;
    printf("Getting hostname: %s\n", host);
    err = netconn_gethostbyname(host, &ip);
    if (err != ERR_OK) {
        printf("Failed to resolve host %s. Error: %d\n", host, err);
        return err;
    }
    printf("Binding to: %s:%d conn: %p\n", host, port, conn);
    err = netconn_bind(conn->conn, &ip, (u16_t)(port & 0xFFFF));
    if (err != ERR_OK) {
        printf("Failed to connect to %s:%d. Error: %d\n", host, port, err);
    }
    return err;
}

int forth_netcon_send(struct forth_netconn* conn, void* data, int len) {
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
    err = netconn_send(conn->conn, buffer);
    if (err != ERR_OK) {
        printf("Failed to send data. Conn: %p. Error: %d\n", conn, err);
    }   
    netbuf_delete(buffer);
    return err;
}

int forth_netcon_write(struct forth_netconn* conn, void* data, int len) {
    printf("Writing data len: %d conn: %p\n", len, conn);
    err_t err;
    uint16_t len16 = len;
    err = netconn_write(conn->conn, data, len16, NETCONN_NOCOPY | NETCONN_MORE);
    if (err != ERR_OK) {
        printf("Failed to write data. Conn: %p. Error: %d\n", conn, err);
    }   
    return err;
}

struct recv_res {
    int code;
    struct netbuf* nbuf;
};

struct recv_res forth_netcon_recv(struct forth_netconn* conn) {
    //printf("Receiving from connection: %p\n", conn);
    err_t err;
    struct netbuf *inbuf;
    err = netconn_recv(conn->conn, &inbuf);
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

struct recvinto_res fillup_full(void *buffer, int size, struct forth_netconn* conn) {
    memcpy(buffer, conn->cache + conn->cache_start, size);
    conn->cache_start += size;
    struct recvinto_res result = {
        .code = ERR_OK,
        .count = size
    };
    return result;
}

struct recvinto_res fillup_partial(void *buffer, int size, struct forth_netconn * conn) {
    conn->cache_start = 0;
    conn->cache_end = 0;
    struct recvinto_res result = {
        .code = ERR_OK,
        .count = cache_data_len(conn)
    };
    return result;
}

struct recvinto_res forth_netcon_recvinto(struct forth_netconn* conn, void* buffer, int size) {
//    printf("receiving buffer %p max size: %d\n", buffer, size);
    if (size <= cache_data_len(conn)) return fillup_full(buffer, size, conn);
    if (cache_data_len(conn) > 0) return fillup_partial(buffer, size, conn);
    conn->cache_start = 0;
    conn->cache_end = 0;
    err_t err;
    struct netbuf *inbuf;
    while ((err = netconn_recv(conn->conn, &inbuf)) == ERR_OK && cache_free_space(conn) > 0) {
        conn->cache_end += netbuf_copy(inbuf, conn->cache + conn->cache_end, cache_free_space(conn));
        netbuf_delete(inbuf);
    }
    if (conn->cache_end == 0) {
        struct recvinto_res result = { 
            .code = err,
            .count = 0
        };
        return result;
    }
    return size <= cache_data_len(conn)
        ? fillup_full(buffer, size, conn)
        : fillup_partial(buffer, size, conn);
}

struct accept_res {
    int code;
    struct forth_netconn* conn;
};

struct accept_res forth_netcon_accept(struct forth_netconn* conn) {
    struct netconn *new_conn;
    err_t code = netconn_accept(conn->conn, &new_conn);
    if (code == ERR_OK) {
        struct accept_res result = {
            .code = code,
            .conn = make_forth_netconn(new_conn)
        };
        return result;
    } else {
        struct accept_res result = {
            .code = code,
            .conn = NULL
        };
        return result;
    }
}
 
void forth_netcon_close(struct forth_netconn* conn) {
    printf("Closing connection %p\n", conn);
    netconn_close(conn->conn);
}

void forth_netcon_delete(struct forth_netconn* conn) {
    printf("Deleting connection %p\n", conn);
    netconn_delete(conn->conn);
    free(conn->cache);
    free(conn);
}

void forth_netcon_set_recvtimeout(struct forth_netconn* conn, int timeout) {
    netconn_set_recvtimeout(conn->conn, timeout);
}
