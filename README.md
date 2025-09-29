# ToDo-List

A lightweight command-line tool written in **Bash** and **Perl** for managing to-do lists.  
It allows you to add, remove, complete, sort, and export tasks with user-defined priorities and due dates.  
The tool supports user configuration, validation of input, and color-coded task display directly in the terminal.

## Features
- Add, remove, and complete tasks with unique IDs  
- Sort tasks by priority or due date  
- Filter overdue or completed tasks  
- Export tasks to a text file  
- User-specific configuration for a default task file  
- Color-coded priority display (`red = high`, `blue = medium`, `green = low`)  

## Usage
```bash
./todo.sh [options]
```
## Options
```bash
  -f <file>                             Load tasks from a specific file.
  -a <task> <priority> <date>           Add a new task.
                                         Priority: high, medium, low.
                                         Date format: DD-MM-YYYY.
  -r <id>                               Remove a task by its ID.
  -c <id>                               Mark a task as completed by its ID.
  -d                                    Sort tasks by due date (ascending).
  -p                                    Sort tasks by priority.
  -l                                    Show completed tasks as well.
  -b                                    Show overdue tasks as well.
  -u <file>                             Set a default task file (saved in config).
  -e <file>                             Export tasks to the specified file.
  -h                                    Display this help message.
```
## Examples
```bash
# Add a new task with high priority and due date
./todo.sh -f example.csv -a "Write script" high 01-10-2025

# Show tasks sorted by priority, then date
./todo.sh -f example.csv -p -d

# Set a default file for tasks
./todo.sh -u example.csv

# Show all tasks, including completed ones
./todo.sh -l

# Export tasks to a text file
./todo.sh -b -p -e export.txt
```
## Implementation details

Bash is used for CLI parsing, configuration handling, and task filtering.  
Perl module (todo.pm) manages data validation, file I/O, and formatted output.  
Tasks are stored in a simple semicolon-separated CSV file with fields:  
```bash
id;task;priority;date;done
```