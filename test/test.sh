#!/usr/bin/env bash

# 1. get a list of all the sub directories in tests directory
# 2. check each of those, if they contain a file called test.txt
# 3. if there is such a file, read the file
# 4. execute each line in that file as a command from within the sub directory
# 5. store the output of that command in a file. the file location is res/<name of the sub dir>/test_<test number>
# 6. append a new line to the same file with the result value of the command just executed
# 7. compare the file in ref and res and check if they are equal to determine if the test was a success

# Define an array of commands to check
commands=("zig" "darling" "wine" "winedump" "basename" "mapfile" "mkdir" "rm" "eval" "find" "sed" "diff" "stat" "printf")

# Loop through the array and check if each command exists
for cmd in "${commands[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Command '$cmd' is not available."
        exit 1
    fi
done

# Test file
TEST_FILE="test.txt"

# Define paths
TEST_DIR="test"
EXAMPLE_DIR="examples"
TEST_DIR_PREFIX="test_"
DIR_TEST_RES="$TEST_DIR/${TEST_DIR_PREFIX}res"
DIR_TEST_REF="$TEST_DIR/${TEST_DIR_PREFIX}ref"
DIR_ZIG_OUT="zig-out"

# Test counter
test_count=0
skipped_tests=0
failed_tests=0

run_tests()
{
    targetDir="$1"
    targetName=$(basename "$targetDir")

    # Loop through each subdirectory in the tests directory
    for subdir in "$1"/*/; do

        # Ensure it is a directory
        if [ ! -d "$subdir" ]; then continue; fi

        # Compute dir names
        dir_name=$(basename "$subdir")
        test_file="$subdir$TEST_FILE"
        res_subdir="$DIR_TEST_RES/$targetName/$dir_name"
        ref_subdir="$DIR_TEST_REF/$targetName/$dir_name"

        # Ensure it's not test_*
        if [[ "$dir_name" =~ ^"$TEST_DIR_PREFIX".* ]]; then continue; fi

        # Increment the test count
        test_count=$((test_count + 1))

        # Default test
        testCommands=("zig build -Dtargets")

        # If TEST_FILE exists in the subdirectory
        if [ -f "$test_file" ]; then
            # read the test file
            mapfile -t testCommands < "$test_file"
        fi

        # Print the build ouput
        testCommands+=("if [ -d "$DIR_ZIG_OUT" ]; then (cd "$DIR_ZIG_OUT" && find); fi")

        # Print the number of tests
        echo "    1..${#testCommands[@]} # $dir_name"

        # Create result subdirectory if it doesn't exist
        mkdir -p "$res_subdir"
        sub_test_count=0

        # remove previos builds
        rm -rf "$subdir$DIR_ZIG_OUT"

        # track errors
        error=0;

        # Execute the tests
        for command in "${testCommands[@]}"; do

            # Increment the sub test count
            sub_test_count=$((sub_test_count + 1))

            # Compute file names
            ref_file="$ref_subdir/test_$sub_test_count"
            res_file="$res_subdir/test_$sub_test_count"

            # Result file path in res
            echo "command: $command" > $res_file

            # Execute test in subdirectory
            if ( cd "$subdir" && eval "$command" ) &>>"$res_file"; then
                result_value=0
            else
                result_value=$?
            fi

            # Append result value to the result file
            echo "exit-status: $result_value" >> "$res_file"

            # Check if there is a refrence file
            if [ ! -f "$ref_file" ]; then
                echo "    not ok $sub_test_count - $command"
                echo "      ---"
                echo "      message: 'Reference file $ref_file not found'"
                echo "      got: |"
                sed 's/^/        /' "$res_file"
                echo ""
                echo "      ..."

                error=1;
                continue
            fi

            # Compare with reference file
            if diff -u "$ref_file" "$res_file" > /dev/null; then
                # Sub-test is successful
                echo "    ok $sub_test_count - $command"
            else
                # Sub-test failed, output YAML block
                echo "    not ok $sub_test_count - $command"
                echo "      ---"
                echo "      got: |"
                sed 's/^/        /' "$res_file"
                echo "      expected: |"
                sed 's/^/        /' "$ref_file"
                echo "  ..."

                error=1;
            fi
        done

        # Test result
        if [ ! "$error" -eq "0" ]; then 
            printf "not "
            failed_tests=$((failed_tests + 1))
        fi
        printf "ok $test_count - $dir_name\n"

    done
}


# TAP version
echo "TAP version 14"

# Num Tests
numTests=(`stat -c %h $TEST_DIR` - 2)
numExamples=(`stat -c %h $EXAMPLE_DIR` - 2)
echo "1..$(($numTests + numExamples))"

echo "# Tests"
run_tests $TEST_DIR

echo "# Examples"
# run_tests $EXAMPLE_DIR

# Summary
executed_tests=$((test_count-skipped_tests));
passed_tests=$((executed_tests - failed_tests))
success_rate=$([ "$executed_tests" -eq 0 ] && echo 0 || echo "$((passed_tests*100/executed_tests))")
echo "# Total  : $test_count"
echo "# Passed : $passed_tests"
echo "# Failed : $failed_tests"
echo "# Skipped: $skipped_tests"
printf "# Success: %.2f%%\n" "$success_rate"
