#include <stdio.h>

static size_t TAP_COUNT = 0;
static int TAP_RESULT = 0;

#define TAP_HEADER()                                            \
    if(argc >= 3)                                               \
    {                                                           \
        if(argv[1][0] == '1' && argv[1][1] == '\0')             \
        {                                                       \
            printf("TAP version 14\n");                         \
            printf("1..%s\n", argv[2]);                         \
        }                                                       \
        printf("# %s\n", argv[3]);                              \
    }


#define TAP_MESSAGE(message) printf("# " message); printf("\n");

#define TAP_TEST(condition, message)                \
    TAP_COUNT++;                                    \
    printf("  ");                                   \
    if (!(condition))                               \
    {                                               \
        printf("not ");                             \
        TAP_RESULT = 1;                             \
    }                                               \
    printf("ok %d - %s\n", TAP_COUNT, message);     \

#define TAP_RETURN()                                \
    if(argc >= 3)                                   \
    {                                               \
        if (TAP_RESULT != 0)  printf("not ");       \
        printf("ok %s - %s\n", argv[1], argv[3]);   \
    }                                               \
    return TAP_RESULT;                              \
