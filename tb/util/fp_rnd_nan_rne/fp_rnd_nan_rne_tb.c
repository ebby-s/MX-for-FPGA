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

DPI_DLLESPEC
int compare_ref_dut(float ref_out, float dut_out){

    if(isnan(ref_out) != isnan(dut_out)){
        return 1;
    }else if(isinf(ref_out) != isinf(dut_out)){
        return 1;
    }else if((isnan(ref_out) != 0) || (isinf(dut_out) != 0)){
        return 0;
    }

    return (ref_out != dut_out);
}

DPI_DLLESPEC
float fp_rnd_rne_ref(int i_num, int i_shift, int i_nan, int width_exp, int width_man, int sat, int e4m3_spec){

    int max_exp = pow(2, width_exp) - 1 - (e4m3_spec ? 0 : 1);  // Largest exponent in element format.
    float max_val = (pow(2, width_man+1) - 1 - (e4m3_spec ? 1 : 0)) * pow(2, max_exp-width_man); // Largest representable value for truncation.

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

    if(i_nan && ((i_num & 0x7f) != 0)){
        num = NAN;
    }else if ((i_nan && ((i_num & 0x7f) == 0)) || (num > max_val)){
        if(sat){
            num = max_val;
        }else if(e4m3_spec){
            num = NAN;
        }else{
            num = INFINITY;
        }
    }

    // if((i_num == 1) && (i_shift == 0)){
    //     printf("Dnm shift: %d\n", width_man-(-eff_exp+1));
    //     printf("Num: %d\n", i_num);
    //     printf("Shift: %d\n", i_shift);
    //     printf("CLZ: %d\n", lz_num);
    //     printf("Align: %d\n", align_num);
        // printf("Out: %f\n", num);
    // }

    return num;
};



