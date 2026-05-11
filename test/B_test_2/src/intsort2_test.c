// https://zig.guide/working-with-c/translate-c/

#include "intsort.h"

#include "tap.h"

int main(int argc, char* argv[])
{
    int array[] = {4,2,9};
    int_sort(array, sizeof(array) / sizeof(int));
    
    TAP_HEADER();

    TAP_TEST(array[0] == 2, "[0] == 2");
    TAP_TEST(array[1] == 4, "[1] == 4");
    TAP_TEST(array[2] == 9, "[2] == 9");

    TAP_RETURN();
}
