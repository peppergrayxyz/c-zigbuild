# Examples

Simple use case as boiler plate for real world apps:


|#| Example | Type | Description | equivalent make command |
|-|-|-|-|-|
|1| a.out | exe | minimal project | ```gcc main.c``` |
|2| hello_word | exe | hello world  | ```gcc -o hello_world hello.c``` |
|3a| libintsort | static lib | library  | ```gcc -c intsort.c -o intsort.o```<br />```ar rcs libintsort.a intsort.o``` |
|3b| libintsort | shared lib | library  | ```gcc -fPIC -c intsort.c -o intsort.o```<br />```gcc -shared -o libintsort.so intsort.o``` |
|3c| libintsort | both libs | library  | 3a & 3b |
|4a| intsort | static lib | library  | 3a & ```gcc main.c ./libintsort.a -o main``` |
|4b| intsort | shared lib | library  | 3b & ```gcc main.c ./libintsort.so -o main``` |
|4c| intsort | both libs | library  | 4a & 4b |
|5| test | test | check [test/A_test_1](test/A_test_1) |  |
