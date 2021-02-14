// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <time.h>
#include <unistd.h>
#include "spi.h"

spi_t *dart_spi_open(const char *path,int mode,int max_speed) {
    spi_t *spi = spi_new();
    int error = spi_open(spi, path, mode,max_speed);
    if (error < 0)
    {
        return 0;
    }
    return spi;
}

spi_t *dart_spi_open_advancded(const char *path,int mode,int max_speed, int bit_order,int bits_per_word,int extra_flags_8bit) {
    spi_t *spi = spi_new();
    int error = spi_open_advanced(spi, path, mode,max_speed,bit_order,bits_per_word,extra_flags_8bit);
    if (error < 0)
    {
        return 0;
    }
    return spi;
}

spi_t *dart_spi_open_advancded2(const char *path,int mode,int max_speed, int bit_order,int bits_per_word,int extra_flags_32bit) {
    spi_t *spi = spi_new();
    int error = spi_open_advanced2(spi, path, mode,max_speed,bit_order,bits_per_word,extra_flags_32bit);
    if (error < 0)
    {
        return 0;
    }
    return spi;
}

int dart_spi_transfer(spi_t *spi,const uint8_t *txbuf,uint8_t *rxbuf,size_t len) {
    return spi_transfer(spi, txbuf, rxbuf,len);
}

int dart_spi_dispose(spi_t *spi)
{
    int error = 0;
    error = spi_close(spi);
    if (error < 0)
    {
        return error;
    }
    spi_free(spi);
    return 0;
}

const char *dart_spi_errmsg(spi_t *spi)
{
    return spi_errmsg(spi);
}

int dart_spi_errno(spi_t *spi)
{
    return spi_errno(spi);
}

int dart_spi_fd(spi_t *spi) {
    return spi_fd(spi);
}

#define BUFFER_LEN (512)
char *dart_spi_info(spi_t *spi) {
    char *info = malloc(BUFFER_LEN);
    int error =  spi_tostring(spi, info, BUFFER_LEN);
    if(error < 0) {
        free(info);
        return NULL;
    } 
    return info;
}

typedef enum SPIproperty {
    MODE,MAX_SPEED,BIT_ORDER,BITS_PER_WORD,EXTRA_FLAGS,EXTRA_FLAGS32,FILE_DESCRIPTOR
} SPIproperty_t;

int dart_get_property(spi_t *spi,SPIproperty_t prop) {
    int value = 0;
    int error = 0;
    uint8_t u8 = 0;
    switch(prop) {
        case MODE:
            error = spi_get_mode(spi,(unsigned int*)&value); 
            break;
        case MAX_SPEED:
            error = spi_get_max_speed(spi,(unsigned int*)&value); 
            break;   
        case BIT_ORDER:
            error = spi_get_bit_order(spi,(spi_bit_order_t *)&value); 
            break;    
        case BITS_PER_WORD:	
            error = spi_get_bits_per_word(spi,&u8);
            value = u8;  
            break;    
        case EXTRA_FLAGS:
            error = spi_get_extra_flags(spi,&u8);
            value = u8; 
            break; 
        case EXTRA_FLAGS32:
            error = spi_get_extra_flags32(spi,(uint32_t *)&value);
            break;    
        case FILE_DESCRIPTOR:
            return spi_fd(spi);
            break;    
    }
    if(error < 0) {
        value = error;
    }
    return value;
}

int dart_set_property(spi_t *spi,SPIproperty_t prop,int value) {
    int error = 0;
    switch(prop) {
        case MODE:
            error = spi_set_mode(spi,value); 
            break;
        case MAX_SPEED:
            error = spi_set_max_speed(spi,value); 
            break;   
        case BIT_ORDER:
            error = spi_set_bit_order(spi,value); 
            break;    
        case BITS_PER_WORD:
            error = spi_set_bits_per_word(spi,value); 
            break;    
        case EXTRA_FLAGS:
            error = spi_set_extra_flags(spi,value); 
            break; 
        case EXTRA_FLAGS32:
            error = spi_set_extra_flags32(spi,value); 
            break;    
        case FILE_DESCRIPTOR:
            break;
    
    }
    return error;
}