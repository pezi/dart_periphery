// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <time.h>
#include <unistd.h>
#include "gpio.h"

typedef enum GPIOproperty
{
    DIRECTION,
    EDGE,
    BIAS,
    DRIVE,
    INVERTED,
    GPIO_LINE,
    GPIO_FD,
    GPIO_CHIP_FD
} GPIOproperty_t;

typedef enum GPIOtextProperty
{
    GPIO_NAME,
    GPIO_LABEL,
    GPIO_CHIP_NAME,
    GPIO_CHIP_LABEL,
    GPIO_INFO
} GPIOtextProperty_t;

gpio_t *dart_gpio_open(const char *path, int line, int direction)
{
    gpio_t *gpio = gpio_new();
    int error = gpio_open(gpio, path, line, direction);
    if (error < 0)
    {
        return 0;
    }
    return gpio;
}

gpio_t *dart_gpio_open_advanced(const char *path, int line, int direction, int edge, int bias, int drive, int inverted, const char *label)
{
    gpio_t *gpio = gpio_new();
    gpio_config_t config;
    config.direction = direction;
    config.edge = edge;
    config.bias = bias;
    config.drive = drive;
    config.inverted = inverted;
    config.label = label;
    int error = gpio_open_advanced(gpio, path, line, &config);
    if (error < 0)
    {
        return 0;
    }
    return gpio;
}

gpio_t *dart_gpio_open_name_advanced(const char *path, const char *name, int direction, int edge, int bias, int drive, int inverted, const char *label)
{
    gpio_t *gpio = gpio_new();
    gpio_config_t config;
    config.direction = direction;
    config.edge = edge;
    config.bias = bias;
    config.drive = drive;
    config.inverted = inverted;
    config.label = label;
    int error = gpio_open_name_advanced(gpio, path, name, &config);
    if (error < 0)
    {
        return 0;
    }
    return gpio;
}

gpio_t *dart_gpio_open_sysfs(int line, int direction)
{
    gpio_t *gpio = gpio_new();
    int error = gpio_open_sysfs(gpio, line, direction);
    if (error < 0)
    {
        return 0;
    }
    return gpio;
}

gpio_t *dart_gpio_open_name(const char *path, const char *name, int direction)
{
    gpio_t *gpio = gpio_new();
    int error = gpio_open_name(gpio, path, name, direction);
    if (error < 0)
    {
        return 0;
    }
    return gpio;
}

int dart_gpio_write(gpio_t *gpio, bool value)
{
    int error = gpio_write(gpio, value);
    if (error < 0)
    {
        return error;
    }
    return 1;
}

int dart_gpio_read(gpio_t *gpio)
{
    bool value;
    int error = gpio_read(gpio, &value);
    if (error < 0)
    {
        return error;
    }
    return value;
}

int dart_gpio_poll(gpio_t *gpio, int timeout_ms)
{
    return gpio_poll(gpio, timeout_ms);
}

typedef struct read_event
{
    int error_code;
    gpio_edge_t edge;
    uint64_t timestamp;
} read_event_t;

read_event_t *dart_gpio_read_event(gpio_t *gpio, int timeout_ms)
{
    read_event_t *read_event = (read_event_t *)malloc(sizeof(read_event_t));
    read_event->edge = 0;
    read_event->timestamp = 0;
    read_event->error_code = gpio_read_event(gpio, &read_event->edge, &read_event->timestamp);
    return read_event;
}

typedef struct poll_multiple
{
    int error_code;
    bool *ready;
} poll_multiple_t;

poll_multiple_t *dart_gpio_poll_multiple(gpio_t **gpios, size_t count, int timeout_ms)
{
    poll_multiple_t *poll_event = (poll_multiple_t *)malloc(sizeof(poll_multiple_t));
    poll_event->ready = (bool *)malloc(sizeof(bool) * count);
    poll_event->error_code = gpio_poll_multiple(gpios, count, timeout_ms, poll_event->ready);
    return poll_event;
}

#define BUFFER_LEN (512)
char *dart_gpio_get_text_property(gpio_t *gpio, GPIOtextProperty_t property)
{
    char *info = malloc(BUFFER_LEN);
    int error = 0;
    switch (property)
    {
    case GPIO_NAME:
        error = gpio_name(gpio, info, BUFFER_LEN);
        break;
    case GPIO_LABEL:
        error = gpio_label(gpio, info, BUFFER_LEN);
        break;

    case GPIO_CHIP_NAME:
        error = gpio_chip_name(gpio, info, BUFFER_LEN);
        break;

    case GPIO_CHIP_LABEL:
        error = gpio_chip_label(gpio, info, BUFFER_LEN);
        break;

    case GPIO_INFO:
        error = gpio_tostring(gpio, info, BUFFER_LEN);
        break;
    }
    if (error < 0)
    {
        free(info);
        return NULL;
    }
    return info;
}

int dart_gpio_get_property(gpio_t *gpio, GPIOproperty_t property)
{
    int value = 0;
    int error = 0;
    bool bvalue = false;
    switch (property)
    {
    case DIRECTION:
        error = gpio_get_direction(gpio, (gpio_direction_t *)&value);
        break;
    case EDGE:
        error = gpio_get_edge(gpio, (gpio_edge_t *)&value);
        break;
    case BIAS:
        error = gpio_get_bias(gpio, (gpio_bias_t *)&value);
        break;
    case DRIVE:
        error = gpio_get_drive(gpio, (gpio_drive_t *)&value);
        break;
    case INVERTED:
        error = gpio_get_inverted(gpio, &bvalue);
        value = (int)bvalue;
        break;
    case GPIO_LINE:
        error = value = gpio_line(gpio);
        break;
    case GPIO_FD:
        error = value = gpio_fd(gpio);
        break;
    case GPIO_CHIP_FD:
        error = value = gpio_chip_fd(gpio);
        break;
    }
    if (error < 0)
    {
        return error;
    }
    return (int)value;
}

int dart_gpio_set_property(gpio_t *gpio, GPIOproperty_t property, int value)
{
    switch (property)
    {
    case DIRECTION:
        return gpio_set_direction(gpio, value);
    case EDGE:
        return gpio_set_edge(gpio, value);
    case BIAS:
        return gpio_set_bias(gpio, value);
    case DRIVE:
        return gpio_set_drive(gpio, value);
    case INVERTED:
        return gpio_set_inverted(gpio, value);
    case GPIO_LINE:    
    case GPIO_FD:
    case GPIO_CHIP_FD:
        break;
    }
    return 0;
}

int dart_gpio_dispose(gpio_t *gpio)
{
    int error = 0;
    error = gpio_close(gpio);
    if (error < 0)
    {
        return error;
    }
    gpio_free(gpio);
    return 0;
}

const char *dart_gpio_errmsg(gpio_t *gpio)
{
    return gpio_errmsg(gpio);
}

int dart_gpio_errno(gpio_t *gpio)
{
    return gpio_errno(gpio);
}
