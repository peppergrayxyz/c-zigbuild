#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "intsort.h"

int main(int argc, char* argv[])
{
    if(argc < 3)
    {
        printf("usage: %s %%d %%d %%d %%d ...\n", argv[0]);
        return EXIT_SUCCESS;
    }

    size_t count = argc - 1;
    int *array = malloc(sizeof(int) * count);

    for(size_t i = 1; i < argc; i++)
    {
        array[i - 1] = atoi(argv[i]);
    }

    int_sort(array, count);

    for(size_t i = 0; i < count; i++)
    {
        printf("%d ", array[i]);
    }
    printf("\n");

    free(array);

    return EXIT_SUCCESS;
}