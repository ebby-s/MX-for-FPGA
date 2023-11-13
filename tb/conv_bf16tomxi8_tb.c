#include "svdpi.h"
#include <math.h>


typedef union {
  float f;
  struct {
    unsigned int mantissa : 23;
    unsigned int exponent : 8;
    unsigned int sign : 1;
  } fields;
} unpacked_float;

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
}

DPI_DLLESPEC
int bf16tomxi8(float i_bf16, int i_scale){

    // Calculate value of E8M0 scale.
    float scale_val = powf(2, (i_scale-127));

    // Calculate exp field of bf16 number.
    int exp_val = log2f(fabsf(i_bf16));

    if(fabsf(i_bf16) < 1)  // Round towards positive infinity.
        exp_val--;

    // Convert mantissa to int, multiply by 2^7 to keep full 7-bit mantissa.
    int shifted_num = (i_bf16) * powf(2, 7-exp_val);

    // Round and shift.
    int rounded = shift_rnd_rne_ref(shifted_num, log2f(scale_val)-exp_val, 1, 8);

    // if(i_bf16 ==  0){
    //     printf("!!!!!!111\n");
    //     printf("lgScale: %f\n", log2f(scale_val));
    //     printf("lgMSB:   %d\n", exp_val);
    //     printf("Shift:   %f\n", log2f(scale_val)-exp_val);
    //     printf("Shifted: %d\n", shifted_num);
    //     printf("Rounded: %d\n", rounded);
    // }

    return rounded;
}

