#include "svdpi.h"
#include <math.h>
#include <stdlib.h>

double rne(double num){

    double out = num;

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
double conv_inttobf16_ref(int i_fi_num, int bit_width){

    double float_num = i_fi_num;

    int exp_val = log2(abs(i_fi_num));

    float_num *= pow(2, 7-exp_val);

    double rounded = rne(float_num);

    rounded /= pow(2, 7-exp_val);

    // if(i_fi_num == 2){
    //     printf("Num: %d\n", i_fi_num);
    //     printf("Exp: %d\n", exp_val);
    //     printf("NumR: %f\n", float_num);
    //     printf("Out: %f\n", rounded);
    // }

    if(i_fi_num == 0)
        return 0;
    else
        return rounded;
}



