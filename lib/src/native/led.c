// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "led.h"

led_t* dart_led_open(const char *path)
{
    led_t *led = led_new();
    int error = led_open(led, path);
    if (error < 0)
    {
        return 0;
    }
    return led;
}

int dart_led_dispose(led_t *led)
{
    int error = 0;
    error = led_close(led);
    if (error < 0)
    {
        return error;
    }
    led_free(led);
    return 0;
}

const char *dart_led_errmsg(led_t *led)
{
    return led_errmsg(led);
}

int dart_led_errno(led_t *led)
{
    return led_errno(led);
}    

int dart_led_write(led_t *led, bool value)
{
    int error = led_write(led, value);
    if (error < 0)
    {
        return error;
    }
    return 1;
}

int dart_led_read(led_t *led)
{
    bool value;
    int error = led_read(led, &value);
    if (error < 0)
    {
        return error;
    }
    return value;
}

#define BUFFER_LEN (512)
char *dart_led_info(led_t *led) {
    char *info = malloc(BUFFER_LEN);
    int error =  led_tostring(led, info, BUFFER_LEN);
    if(error < 0) {
        free(info);
        return NULL;
    } 
    return info;
}

#define BUFFER_LEN_NAME (128)
char *dart_led_name(led_t *led) {
    char *name = malloc(BUFFER_LEN_NAME);
    int error =  led_name(led, name, BUFFER_LEN_NAME);
    if(error < 0) {
        free(name);
        return NULL;
    } 
    return name;
}

int dart_led_get_brightness(led_t *led)
{
    int value;
    int error = led_get_brightness(led, (unsigned int *)&value);
    if (error < 0)
    {
        return error;
    }
    return value;
}

int dart_led_get_max_brightness(led_t *led)
{
    int value;
    int error = led_get_max_brightness(led,(unsigned int *) &value);
    if (error < 0)
    {
        return error;
    }
    return value;
}

int dart_led_set_brightness(led_t *led,int value)
{
    return led_set_brightness(led, value);
}





