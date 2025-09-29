#!/bin/bash

current_date=$(date +%F)
config_file="$HOME/.config/todo_oz"
# temporary helper file, automatically deleted after execution
output_file="output.txt"

all_flags=("f" "a" "d" "p" "h" "b" "u" "c" "l" "r" "e")
priority_sort_first=0

declare -A flags
for flag in "${all_flags[@]}"; do
    flags["$flag"]=0
done

args=()
while getopts "f:adpbhu:c:lr:e:" opt; do
    case $opt in
    f)  
        task_file="$OPTARG"
        flags["f"]=1
        ;; 
    a)  
        flags["a"]=1
        args=("${@:OPTIND}")
        ;;
    r)  
        flags["r"]=1
        id_remove="$OPTARG"
        ;;
    c)  
        id_complete="$OPTARG"
        flags["c"]=1
        ;;
    p)  
        flags["p"]=1
        ;;
    d) 
        if [ "${flags["p"]}" -eq 1 ]; then
            priority_sort_first=1
        fi
        flags["d"]=1
        ;;
    b)  
        flags["b"]=1
        ;;
    h)  
        flags["h"]=1
        ;;
    l)  
        flags["l"]=1
        ;;
    e)  
        export_file="$OPTARG"
        flags["e"]=1
        ;;
    u)  
        new_default_file="$OPTARG"
        flags["u"]=1
        ;;
    *)
        exit 1
        ;;
    esac
done

if [ "${flags["h"]}" -eq 1 ]; then
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -f <file>                               Load a task file."
    echo "  -a <task> <priority> <date>             Add a new task."
    echo "                                          Priority: high, medium, low."
    echo "                                          Date: in format DD-MM-YYYY."
    echo "  -r <id>                                 Remove a task by its ID."
    echo "  -c <id>                                 Mark a task as completed by its ID."
    echo "  -d                                      Sort tasks by date (ascending)."
    echo "  -p                                      Sort tasks by priority."
    echo "  -l                                      Also show completed tasks."
    echo "  -b                                      Also show tasks with past due dates."
    echo "  -u <file>                               Set the given file as default (saved in configuration)."
    echo "  -e <file>                               Export tasks to a given text file."
    echo "  -h                                      Show this help message."
    echo
    echo "Examples:"
    echo "  $0 -f tasks.txt -a \"Write script\" high 01-10-2025"
    echo "      Add a new task to tasks.txt."
    echo
    echo "  $0 -f tasks.txt -p -d"
    echo "      Show tasks from tasks.txt sorted by priority, then by date."
    echo
    echo "  $0 -u tasks.txt"
    echo "      Set tasks.txt as the default task file."
    echo
    echo "  $0 -l"
    echo "      Show all tasks (including completed ones) from the default file." 
    echo
    echo "  $0 -b -p -e export.txt"
    echo "      Export tasks from the default file, sorted by priority (including past due ones), into export.txt."
    exit 0
fi

if [ "${flags["f"]}" -eq 1 ] && [ ! -f "$task_file" ]; then
    echo "File $task_file does not exist."
    exit 1
fi

# check if config file exists
if [ ! -f "$config_file" ]; then
    touch "$config_file"
fi

# set default task file
if [ "${flags["u"]}" -eq 1 ]; then
    new_default_file_env="TODO_DEFAULT_FILE=\"$new_default_file\""

    if grep -q "TODO_DEFAULT_FILE=" "$config_file"; then
        sed -i "s|^TODO_DEFAULT_FILE=.*|$new_default_file_env|" "$config_file"
    else
        echo "$new_default_file_env" >> "$config_file"
    fi
    task_file=$new_default_file
fi

source "$config_file"   
if [ "${flags["f"]}" -ne 1 ]; then
    if ! grep -q "TODO_DEFAULT_FILE=" "$config_file"; then
        echo "No file provided and no default file set."
        exit 1
    else
        task_file=$TODO_DEFAULT_FILE
    fi
fi

if [ ! -r "$task_file" ]; then
    echo "No read permissions for $task_file."
    exit 1
fi

if [ ! -w "$task_file" ]; then
    echo "No write permissions for $task_file."
    exit 1
fi

# add task
if [ "${flags["a"]}" -eq 1 ]; then
    if [ ${#args[@]} -ne 3 ]; then
        echo "Option -a expects 3 arguments: task, priority, date."
        exit 1
    fi
    perl -e 'use lib "."; use todo; todo::add_task($ARGV[0], $ARGV[1], $ARGV[2], $ARGV[3]);' "$task_file" "${args[@]}"
fi

# complete task
if [ "${flags["c"]}" -eq 1 ]; then
    perl -e 'use lib "."; use todo; todo::complete_task($ARGV[0], $ARGV[1]);' "$task_file" "$id_complete"
fi

# remove task
if [ "${flags["r"]}" -eq 1 ]; then
    touch "${task_file}_copy"
    perl -e 'use lib "."; use todo; todo::remove_task($ARGV[0], $ARGV[1]);' "$task_file" "$id_remove"
    cp "${task_file}_copy" "$task_file"
    rm "${task_file}_copy"
fi

touch $output_file
cp "$task_file" "$output_file"

# filter tasks that are still active (last column = 0)
if [ "${flags["l"]}" -ne 1 ]; then
    awk -F';' '$NF == 0' "$output_file" > temp.txt
    mv temp.txt "$output_file"
fi

# filter tasks that are not overdue
if [ "${flags["b"]}" -ne 1 ]; then
    awk -F';' -v current_date="$current_date" '
        {
            split($4, date_parts, "-")
            formatted_date = date_parts[3] "-" date_parts[2] "-" date_parts[1]
            if (formatted_date >= current_date) {
                print $0
            }
        }
    ' "$output_file" > temp.txt
    mv temp.txt "$output_file"
fi

# sorting by priority and date
if [ "${flags["p"]}" -eq 1 ]; then
    sed 's/;high;/;1;/g; s/;medium;/;2;/g; s/;low;/;3;/g' "$output_file" > temp.txt
    mv temp.txt "$output_file"
fi

if [ "${flags["d"]}" -eq 1 ]; then
    awk -F';' '
        {
            OFS=";" 
            split($4, date_parts, "-")
            formatted_date = date_parts[3] "-" date_parts[2] "-" date_parts[1]
            $4 = formatted_date
            print $0
        }
    ' "$output_file" > temp.txt

    if [ "${flags["p"]}" -ne 1 ]; then
        sort -t';' -k4,4 temp.txt > "$output_file"
    elif [ "$priority_sort_first" -eq 1 ]; then
        sort -t';' -k3,3 -k4,4 temp.txt > "$output_file"
    else
        sort -t';' -k4,4 -k3,3 temp.txt > "$output_file"
    fi

    awk -F';' '
        {
            OFS=";"
            split($4, date_parts, "-")
            formatted_date = date_parts[3] "-" date_parts[2] "-" date_parts[1]
            $4 = formatted_date
            print $0
        }
    ' "$output_file" > temp.txt
    mv temp.txt "$output_file"
elif [ "${flags["p"]}" -eq 1 ]; then
    mv "$output_file" temp.txt
    sort -t';' -k3,3 temp.txt > "$output_file"
fi

if [ "${flags["p"]}" -eq 1 ]; then
    sed 's/;1;/;high;/g; s/;2;/;medium;/g; s/;3;/;low;/g' "$output_file" > temp.txt
    mv temp.txt "$output_file"
fi

# display and export
if [ "${flags["e"]}" -eq 1 ]; then
    perl -e 'use lib "."; use todo; todo::show_tasks($ARGV[0], 0);' "$output_file" > "$export_file"
fi

perl -e 'use lib "."; use todo; todo::show_tasks($ARGV[0], 1);' "$output_file"

rm $output_file
