#include "svdpi.h"
#include <math.h>
#include <stdlib.h>


float rne(float num){

    float out = num;

    if(round(num) != num){  // If rounding is necessary.

        out = round(num); // Round away from zero.

        if(round(num*2) == (num*2)){ // If at halfway point.

            if((int)out % 2 != 0){  // If output is odd, round towards zero.
                if(out > 0){
                    out -= 1;
                }else{
                    out += 1;
                }
            }
        }
    }

    return out;
};

float rtni(float num){

    float out = num;

    if(round(num) != num){  // If rounding is necessary.

        out = round(num); // Round away from zero.

        if((out - num) > 0){ // If at or above halfway point.
            out -= 1;
        }
    }

    return out;
};

DPI_DLLESPEC
float max_bf16(float i_bf16_vec[32], int k){

    float lrg = 0;

    for(int i=0; i<k; i++){
        if(isfinite(i_bf16_vec[i]))
            lrg = fmaxf(fabsf(i_bf16_vec[i]), lrg);
    }

    return lrg;
};

DPI_DLLESPEC
int detect_nan(float i_bf16_vec[32], int k){

    int nan_detect = 0;

    for(int i=0; i<32; i++){
        if(!isfinite(i_bf16_vec[i]))
            nan_detect |= (1 << i);
    }

    return nan_detect;
}

DPI_DLLESPEC
int shift_rnd_rne_ref(int i_num, int i_shift, int width_diff, int width_o){

    float num = i_num;

    num /= (1 << (i_shift + width_diff));

    if((i_shift + width_diff) >= 32)
        num = 0;

    int rounded = rne(num);

    if(abs(rounded) > ((1<<(width_o-1))-1)){
        if(rounded > 0){
            rounded -= 1;
        }else{
            rounded += 1;
        }
    }

    return rounded;
};

DPI_DLLESPEC
int bf16tomxi8(float i_bf16, int i_scale, int width_diff, int bit_width){

    // Calculate value of E8M0 scale.
    double scale_val = pow(2, (i_scale-127));

    // Calculate largest power of 2 in bf16 number.
    int exp_val = rtni(log2(fabs(i_bf16)));

    // Convert mantissa to int, multiply by 2^7 to keep full 7-bit mantissa.
    int shifted_num = i_bf16 * pow(2, 7-exp_val);

    // Round and shift.
    int rounded = shift_rnd_rne_ref(shifted_num, log2(scale_val)-exp_val, width_diff, bit_width);

    // if(i_bf16 ==  -95563022336.00 && i_scale == 255){
    //     printf("Input:   %f\n", i_bf16);
    //     printf("Scale:   %d\n", i_scale);
    //     printf("lgScale: %f\n", log2(scale_val));
    //     printf("lgMSB:   %d\n", exp_val);
    //     printf("Shift:   %f\n", log2(scale_val)-exp_val);
    //     printf("Shifted: %d\n", shifted_num);
    //     printf("Rounded: %d\n", rounded);
    // }

    if(i_bf16 == 0)
        return 0;

    return rounded;
};

