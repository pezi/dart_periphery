// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>

#include "serial.h"

typedef enum SerialProperty
{
    BAUDRATE,
    DATABITS,
    PARITY,
    STOPBITS,
    XONXOFF,
    RTSCTS,
    VMIN
}  SerialProperty_t;   

int dart_serial_get_property(serial_t *serial,SerialProperty_t property)
{
    int value = 0;
    int error = 0;
    bool bvalue = false;
    switch (property)
    {
    case BAUDRATE:
        error = serial_get_baudrate(serial, (uint32_t *)&value);
        break;
    case DATABITS:
        error = serial_get_databits(serial, (unsigned int *)&value);
        break;
    case PARITY:
        error = serial_get_databits(serial,(serial_parity_t *) &value);
        break;
    case STOPBITS:
        error = serial_get_stopbits(serial,(unsigned int *)&value);
        break;
    case XONXOFF:
        error = serial_get_xonxoff(serial,&bvalue);
        value = bvalue;
        break;
    case RTSCTS:
        error = serial_get_rtscts(serial,&bvalue);
        value = bvalue;
        break;
    case VMIN:
        error = serial_get_vmin(serial,(unsigned int *)&value);
        break;    
    }
    
    if (error < 0)
    {
        return error;
    }
    return (int)value;
}

int dart_serial_set_property(serial_t *serial,SerialProperty_t property,int value)
{
    int error = 0;
    switch (property)
    {
    case BAUDRATE:
        error = serial_set_baudrate(serial, value);
        break;
    case DATABITS:
        error = serial_set_databits(serial, value);
        break;
    case PARITY:
        error = serial_set_databits(serial,(serial_parity_t) value);
        break;
    case STOPBITS:
        error = serial_set_stopbits(serial,value);
        break;
    case XONXOFF:
        error = serial_set_xonxoff(serial,value);
        break;
    case RTSCTS:
        error = serial_set_rtscts(serial,value);
        break;
    case VMIN:
        error = serial_set_vmin(serial,value);
        break;    
    }
    
    if (error < 0)
    {
        return error;
    }
    return (int)value;
}

double dart_serial_get_vtime(serial_t *serial)
{
    float vtime;
    int error = serial_get_vtime(serial,&vtime);
    if(error < 0) {
        return (double)error;
    }
    return (double)vtime;
}

int dart_serial_set_vtime(serial_t *serial,double vtime)
{
    return serial_set_vtime(serial,(float)vtime);
}


serial_t *dart_serial_open(const char *path, int baudrate)
{
    serial_t *serial = serial_new();
    int error = serial_open(serial, path, baudrate);
    if (error < 0)
    {
        return 0;
    }
    return serial;
}

serial_t * dart_serial_open_advanced(const char *path,
                              uint32_t baudrate, unsigned int databits,
                              serial_parity_t parity, unsigned int stopbits,
                              int xonxoff, int rtscts)
{
    serial_t *serial = serial_new();
    int error = serial_open_advanced(serial, path,
                                     baudrate, databits,
                                     parity, stopbits,
                                     xonxoff, rtscts);
    if (error < 0)
    {
        return 0;
    }
    return serial;
}

typedef struct read_event
{
    int count;
    uint8_t *data;
} read_event_t;


read_event_t *dart_serial_read(serial_t *serial, int len, int timeout_ms) {
    uint8_t* data = malloc(len);
    read_event_t* event = (read_event_t *)malloc(sizeof(read_event_t));

    event->count = serial_read(serial, data , len, timeout_ms);
    
    if(event->count <= 0) {
        event->data = NULL;
        free(data);
    } else {
        event->data = data;
    } 
    return event;
}

int dart_serial_write(serial_t *serial,const uint8_t *buf, size_t len) {
    return serial_write(serial,buf,len);
    return len;
}

const char *dart_serial_errmsg(serial_t *serial)
{
    return serial_errmsg(serial);
}

int dart_serial_flush(serial_t *serial)
{
    return serial_flush(serial);
}

int dart_serial_input_waiting(serial_t *serial) {
    unsigned int count;
    int result = serial_input_waiting(serial, &count);
    if(result < 0) {
        return (int)result;
    }
    return count;
}

int dart_serial_output_waiting(serial_t *serial) {
    unsigned int count;
    int result = serial_output_waiting(serial, &count);
    if(result < 0) {
        return (int)result;
    }
    return result;
}

int dart_serial_poll(serial_t *serial,int timeout_ms) {
    return serial_poll(serial, timeout_ms);
}

int dart_serial_errno(serial_t *serial)
{
    return serial_errno(serial);
}

int dart_serial_dispose(serial_t *serial)
{
    int error = 0;
    error = serial_close(serial);
    if (error < 0)
    {
        return error;
    }
    serial_free(serial);
    return 0;
}

int dart_serial_fd(serial_t *serial) {
    return serial_fd(serial);
}

#define BUFFER_LEN (512)
char *dart_serial_info(serial_t *serial) {
    char *info = malloc(BUFFER_LEN);
    int error =  serial_tostring(serial, info, BUFFER_LEN);
    if(error < 0) {
        free(info);
        return NULL;
    } 
    return info;
}

