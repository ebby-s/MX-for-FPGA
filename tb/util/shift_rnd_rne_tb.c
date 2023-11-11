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



