// https://zig.guide/working-with-c/translate-c/

#include "intsort.h"

#include "tap.h"

int main(int argc, char* argv[])
{
    int array[] = {3,1,5};
    int_sort(array, sizeof(array) / sizeof(int));
    
    TAP_HEADER();

    TAP_TEST(array[0] == 1, "[0] == 1");
    TAP_TEST(array[1] == 3, "[1] == 3");
    TAP_TEST(array[2] == 5, "[2] == 5");

    TAP_RETURN();
}
