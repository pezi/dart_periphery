// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "pwm.h"

pwm_t* dart_pwm_open(int chip,int channel)
{
    pwm_t *pwm = pwm_new();
    int error = pwm_open(pwm,chip, channel);
    if (error < 0)
    {
        return 0;
    }
    return pwm;
}

int dart_pwm_dispose(pwm_t *pwm)
{
    int error = 0;
    error = pwm_close(pwm);
    if (error < 0)
    {
        return error;
    }
    pwm_free(pwm);
    return 0;
}

const char *dart_pwm_errmsg(pwm_t *pwm)
{
    return pwm_errmsg(pwm);
}

int dart_pwm_errno(pwm_t *pwm)
{
    return pwm_errno(pwm);
}    

int dart_pwm_enable(pwm_t *pwm) {
    return pwm_enable(pwm);
}

int dart_pwm_disable(pwm_t *pwm) {
    return pwm_enable(pwm);
}


#define BUFFER_LEN (512)
char *dart_pwm_info(pwm_t *pwm) {
    char *info = malloc(BUFFER_LEN);
    int error =  pwm_tostring(pwm, info, BUFFER_LEN);
    if(error < 0) {
        free(info);
        return NULL;
    } 
    return info;
}

typedef enum PWMpropertyEnum {
    PERIOD_NS,DUTY_CYCLE_NS,PERIOD,DUTY_CYCLE,FREQUENCY,POLARITY,CHIP,CHANNEL
} PWMpropertyEnum_t;

typedef struct PWMproperty {
    double doubleValue;
    int64_t longValue;
} PWMproperty_t;

int dart_pwm_set_property(pwm_t *pwm,PWMpropertyEnum_t prop, PWMproperty_t *data) {
    int value = 0;
    switch(prop) {
        case PERIOD_NS:
            value = pwm_set_period_ns(pwm,data->longValue);
            break;
         case DUTY_CYCLE_NS:
            value = pwm_set_duty_cycle_ns(pwm,data->longValue);
            break;
        case PERIOD:
            value = pwm_set_period(pwm,data->doubleValue);
            break;
        case DUTY_CYCLE:
            value = pwm_set_duty_cycle(pwm,data->doubleValue);
            break;
        case FREQUENCY:
            value = pwm_set_frequency(pwm,data->doubleValue);
            break;
        case POLARITY:
            value = pwm_set_polarity(pwm,data->longValue);
            break;
        case CHIP:
        case CHANNEL:
            break;
    }
    return value;
}


int dart_pwm_get_property(pwm_t *pwm,PWMpropertyEnum_t prop,PWMproperty_t *data) {
   
    int error = 0;
    uint64_t ns;
    int ivalue;
    double seconds;
    switch(prop) {
        case PERIOD_NS:
            error =  pwm_get_period_ns(pwm, &ns);
            if(error < 0) {
                return error;
            } else {
                data->longValue = (int64_t)ns;    
            }
            break;
        case DUTY_CYCLE_NS:
            error =  pwm_get_duty_cycle_ns(pwm, &ns);
            if(error < 0) {
                return error;
            } else {
                data->longValue = (int64_t)ns;    
            }
            break;
         case PERIOD:
            error =  pwm_get_period(pwm, &seconds);
            if(error < 0) {
                 return error;
            } else {
                data->doubleValue = seconds;    
            }
            break;
        case DUTY_CYCLE:
            error =  pwm_get_duty_cycle(pwm,  &seconds);
            if(error < 0) {
                return error;
            } else {
                data->doubleValue = seconds;    
            }
            break;
        case FREQUENCY:
             error =  pwm_get_frequency(pwm,  &seconds);
            if(error < 0) {
                return error;
            } else {
                data->doubleValue = seconds;    
            }
            break;
         case POLARITY:
            error =  pwm_get_polarity(pwm, (pwm_polarity_t *)&ivalue);
            if(error < 0) {
                return error;
            } else {
                data->longValue = ivalue;    
            }
            break;    
         case CHIP:
            data->longValue = pwm_chip(pwm);
            break;      
        case CHANNEL:
            data->longValue = pwm_channel(pwm);
            break;

    } 
    return 0;
}
