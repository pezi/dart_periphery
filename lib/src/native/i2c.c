// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "i2c.h"

i2c_t* dart_i2c_open(const char *path)
{
    i2c_t *i2c = i2c_new();
    int error = i2c_open(i2c, path);
    if (error < 0)
    {
        return 0;
    }
    return i2c;
}

int dart_i2c_dispose(i2c_t *i2c)
{
    int error = 0;
    error = i2c_close(i2c);
    if (error < 0)
    {
        return error;
    }
    i2c_free(i2c);
    return 0;
}

const char *dart_i2c_errmsg(i2c_t *i2c)
{
    return i2c_errmsg(i2c);
}

int dart_i2c_errno(i2c_t *i2c)
{
    return i2c_errno(i2c);
}

// not used - can be done inside the dart code
struct i2c_msg *dart_create_i2c_msg(int address,int flags,int len) {
   struct i2c_msg *msg = malloc(sizeof(struct i2c_msg ));
   msg->addr = (__u16)address;
   msg->flags = (__u16)flags;
   msg->len = (__u16)len;
   msg->buf = (__u8 *)malloc(len);
   return msg;
}   

int dart_i2c_transfer(i2c_t *i2c, struct i2c_msg *msgs, size_t count) {
    return i2c_transfer(i2c, msgs,count);
}

int dart_i2c_fd(i2c_t *i2c) {
    return i2c_fd(i2c);
}

#define BUFFER_LEN (512)
char *dart_i2c_info(i2c_t *i2c) {
    char *info = malloc(BUFFER_LEN);
    int error =  i2c_tostring(i2c, info, BUFFER_LEN);
    if(error < 0) {
        free(info);
        return NULL;
    } 
    return info;
}



