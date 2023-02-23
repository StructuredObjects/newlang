#include <stdio.h>
#include <stdlib.h>
void test();

int main(int argc, char ** argv)
{
    test();
    char *test[1024];
    strcpy(test, "test");

    if(strcmp("test", test) == 0) {
        printf("Here");
    }

    scanf("%s", test);
    for(int i = 0; i < strlen(test); i++) {
        printf("%s", &test[i]);
    }

}


void test()
{
    printf("Testing function");

}