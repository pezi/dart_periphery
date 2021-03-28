// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "mmio.h"

mmio_t* dart_mmio_open(uint64_t base, int size)
{
    mmio_t *mmio = mmio_new();
    int error =  mmio_open(mmio, (uintptr_t) base,(size_t)size);
    if (error < 0)
    {
        return 0;
    }
    return mmio;
}    

mmio_t* dart_mmio_open_advanced(uint64_t base,int size,const char *path)
{
    mmio_t *mmio = mmio_new();
    int error =  mmio_open_advanced(mmio, (uintptr_t) base,(size_t)size,path);
    if (error < 0)
    {
        return 0;
    }
    return mmio;
}    

void *dart_mmio_ptr(mmio_t *mmio) {
    return mmio_ptr(mmio); 
}

uint64_t dart_mmio_read32(mmio_t *mmio, uint64_t offset) {
    uint32_t value;
    int error = mmio_read32(mmio, (uintptr_t) offset, &value);  
    if(error < 0) {
        return ((uint64_t)-error) << 32;
    }
    return value;
}

uint64_t dart_mmio_read16(mmio_t *mmio, uint64_t offset) {
    uint16_t value;
    int error = mmio_read16(mmio, (uintptr_t) offset, &value);  
    if(error < 0) {
        return ((uint64_t)-error) << 32;
    }
    return value;
}

uint64_t dart_mmio_read8(mmio_t *mmio, uint64_t offset) {
    uint8_t value;
    int error = mmio_read8(mmio, (uintptr_t) offset, &value);  
    if(error < 0) {
        return ((uint64_t)-error) << 32;
    }
    return value;
}

int dart_mmio_read(mmio_t *mmio, uint64_t offset,uint8_t *buf, int len) {
    return mmio_read(mmio, (uintptr_t) offset, buf, (size_t)len);
}

int dart_mmio_write32(mmio_t *mmio, uint64_t offset,int value) {
    return mmio_write32(mmio, (uintptr_t) offset, (uint32_t)value);
}

int dart_mmio_write16(mmio_t *mmio, uint64_t offset,int value) {
    return mmio_write16(mmio, (uintptr_t) offset, (uint16_t)value);
}

int dart_mmio_write8(mmio_t *mmio, uint64_t offset,int value) {
    return mmio_write8(mmio, (uintptr_t) offset, (uint8_t)value);
}

int dart_mmio_write(mmio_t *mmio, uint64_t offset,uint8_t *buf, int len) {
    return mmio_write(mmio, (uintptr_t) offset, buf, (size_t)len);
}

int dart_mmio_base(mmio_t *mmio) {
    return (int)mmio_base(mmio); 
}

int dart_mmio_size(mmio_t *mmio) {
    return (int)mmio_size(mmio); 
}

int dart_mmio_dispose(mmio_t *mmio)
{
    int error = 0;
    error = mmio_close(mmio);
    if (error < 0)
    {
        return error;
    }
    mmio_free(mmio);
    return 0;
}

const char *dart_mmio_errmsg(mmio_t *mmio)
{
    return mmio_errmsg(mmio);
}

int dart_mmio_errno(mmio_t *mmio)
{
    return mmio_errno(mmio);
}    

#define BUFFER_LEN (512)
char *dart_mmio_info(mmio_t *mmio) {
    char *info = malloc(BUFFER_LEN);
    int error =  mmio_tostring(mmio, info, BUFFER_LEN);
    if(error < 0) {
        free(info);
        return NULL;
    } 
    return info;
}
