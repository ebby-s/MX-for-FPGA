#include "svdpi.h"
#include <math.h>



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
float fp_rnd_rne_ref(int i_num, int i_shift, int width_exp, int width_man){

    int max_exp = powf(2, width_exp) - 1;  // Largest exponent in element format.
    float max_val = ((powf(2, width_man+1)-1)*powf(2, -width_man)) * powf(2, max_exp); // Largest representable value for truncation.

    int lz_num = 0;  // Count leading zeros.
    if(i_num != 0){
        lz_num = __builtin_clz(i_num) - 24;
    }

    int align_num = i_num << lz_num;  // Move first 1 to MSB.

    int eff_exp = max_exp - i_shift - lz_num;

    float num = align_num;
    num *= pow(2, -7); // Shift right by BF16 mantissa width.

    // If exp is 1 or more, keep width_man digits.
    if((eff_exp) > 0){
        num *= pow(2, width_man);
        num = rne(num);
        num /= pow(2, width_man);
    }else{
        num *= pow(2, width_man-(-eff_exp+1));
        num = rne(num);
        num /= pow(2, width_man-(-eff_exp+1));
    }

    num *= pow(2, eff_exp);  // Max exp is alighed with i_shift = 0.
    
    if(num > max_val){ // Truncate if large value.
        num = max_val;
    }

    return num;
};

DPI_DLLESPEC
float bf16tomxfp6(float i_bf16, int i_scale, int width_exp, int width_man){

    // Calculate value of E8M0 scale.
    double scale_val = pow(2, (i_scale-127));

    // Sign of input.
    float num_sign = signbit(i_bf16) ? -1 : 1;

    // Calculate largest power of 2 in bf16 number.
    int exp_val = rtni(log2(fabs(i_bf16)));

    // Convert mantissa to int, multiply by 2^7 to keep full 7-bit mantissa.
    int shifted_num = fabs(i_bf16) * pow(2, 7-exp_val);

    // Round and shift.
    float rounded = fp_rnd_rne_ref(shifted_num, log2(scale_val)-exp_val, width_exp, width_man);

    // if(i_bf16 == -4340760173735115897451494931228000256.0){
    //     printf("Input:   %f\n", i_bf16);
    //     printf("lgScale: %f\n", log2f(scale_val));
    //     printf("RTNI:    %f\n", log2(fabs(i_bf16)));
    //     printf("lgMSB:   %d\n", exp_val);
    //     printf("Shift:   %f\n", log2f(scale_val)-exp_val);
    //     printf("Shifted: %d\n", shifted_num);
    //     printf("Rounded: %d\n", rounded);
    // }

    if(i_bf16 == 0)
        return 0;

    return rounded * num_sign;
};

