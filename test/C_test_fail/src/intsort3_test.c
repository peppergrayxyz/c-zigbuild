// https://zig.guide/working-with-c/translate-c/

#include "intsort.h"

#include "tap.h"

int main(int argc, char* argv[])
{
    int array[] = {1,2,3};
    int_sort(array, sizeof(array) / sizeof(int));
    
    TAP_HEADER();

    TAP_TEST(array[0] == 4, "[0] == 4");
    TAP_TEST(array[1] == 5, "[1] == 5");
    TAP_TEST(array[2] == 6, "[2] == 6");

    TAP_RETURN();
}
