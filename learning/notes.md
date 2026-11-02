# Linux Fundamentals: Notes

## Block 1: Files and navigation

Command :What it does 

| `pwd` | Prints the current directory |
| `ls -la` | Lists all files (including hidden) with permissions, owner and size |
| `cd /etc` | Moves into the `/etc` directory (absolute path) |
| `cd -` | Jumps back to the previous directory |
| `apt update && apt install -y tree` | Refreshes the package list, then installs `tree` |
| `mkdir -p ~/devops/{app,logs,backup,scripts}` | Creates the folder and all four subfolders in one command |
| `tree ~/devops` | Shows the folder structure as a tree |
| `touch app/index.html logs/app.log` | Creates empty files |
| `cp app/index.html backup/index.html.bak` | Copies a file |
| `mv logs/app.log logs/old.log` | Renames a file (move to the same folder with a new name) |
| `cp -r app backup/app_copy` | Copies a whole folder, including its contents |
| `rm backup/index.html.bak` | Deletes a file |
| `ln -s ~/devops/app app_link` | Creates a symlink (shortcut) pointing to the `app` folder |
| `cd ..` | Moves up one level to the parent directory |
| `cd -` | Returns to the previous directory and prints it |
| `cd` (no argument) | Goes to the home directory (~) from anywhere |
| `~` and `/` | `~` is home (/root for root); `/` is the top of the filesystem tree |
| `ln -s target linkname` | Creates a symlink; used to enable Nginx sites and switch release versions |

## Block 2: Viewing and editing files

### Creating and counting

Command : What it does 

| `cd ~/devops/logs` | Moves into the logs folder to work there. |
| `seq 1 50 > sample.log` | `seq 1 50` prints the numbers 1 to 50, one per line. `>` redirects that output into `sample.log` instead of the screen (overwrites if it exists). Used to make a practice file. |
| `seq 1 200 > big.log` | Same idea with 200 lines, long enough that it does not fit on one screen. |
| `wc -l sample.log` | "Word count" with `-l`: counts the lines in a file. `-w` counts words, `-c` counts bytes. Output: `50 sample.log`. |

### Viewing files

Command : What it does 

| `cat sample.log` | Prints the whole file. Fine for small files and for feeding pipes. |
| `head sample.log` | Shows the first 10 lines (the default). |
| `head -n 5 sample.log` | Shows the first 5 lines. `-n` sets the number of lines. |
| `tail sample.log` | Shows the last 10 lines (the default). Most useful for logs, because new entries are at the bottom. |
| `tail -n 5 sample.log` | Shows the last 5 lines. |
| `head -n 25 sample.log \| tail -n 11` | Prints lines 15 to 25. `head` takes the first 25 lines, `tail` keeps the last 11 of them. Formula for lines A to B: `head -n B file \| tail -n (B-A+1)`. |
| `sed -n '15,25p' sample.log` | Another way to print lines 15 to 25. `-n` turns off default printing and `15,25p` prints only that range. |
| `less big.log` | Opens a file in a scrollable, read-only viewer. Better than `cat` for large files, because it opens instantly and lets you search. |

### Redirection and pipes

Command :What it does

| `echo "first line" > app.log` | Writes text into a file. `>` overwrites the file if it exists, or creates it. |
| `echo "second line" >> app.log` | `>>` appends to the end of the file instead of overwriting. |
| `cat app.log` | Checks what the file now contains. |
| `cat sample.log \| grep 5` | Pipe `\|` sends the output of one command into the next. Here only lines containing 5 are kept. |
| `cat sample.log \| wc -l` | Counts the lines of the piped output (prints 50). |
| `ls ~/devops \| wc -l` | Counts how many items are in the folder. |
| `grep "15" big.log \| less` | Filters with grep first, then pages through the result in less. |
| `ls /nonexistent > out.log 2>&1` | `>` sends normal output (stream 1) to out.log. `2>&1` sends errors (stream 2) to the same place as stream 1. Without it, the error message would still appear on screen. |

`>` vs `>>`: `>` overwrites, `>>` appends. Both create the file if it does not exist.

### Watching a log live (tail -f task)

Command :What it does 

| `tail -f ~/devops/logs/app.log` | Run in terminal 2. Shows the last 10 lines, then keeps waiting and prints new lines as they are added. Ctrl+C stops it. |
| `for i in $(seq 1 20); do echo "log line $i" >> ~/devops/logs/app.log; sleep 1; done` | Run in terminal 1. A loop that runs 20 times: appends one line to the log, then waits 1 second. It simulates an application writing a log. The lines appeared live in terminal 2. |

### Editing files

Command : What it does

| `nano ~/devops/app/index.html` | Beginner-friendly editor. Type directly. `Ctrl+O` then Enter saves, `Ctrl+X` exits. Shortcuts are shown at the bottom of the screen. |
| `vim ~/devops/app/index.html` | Modal editor. It opens in normal mode where keys are commands. Press `i` to insert text, `Esc` to go back to normal mode, `:wq` + Enter to save and quit, `:q!` + Enter to quit without saving. |

nano vs vim: nano is easy and you can type immediately. vim has modes, is harder to learn but much faster for experts, and is often the only editor available on minimal servers.


## Quiz answers

(to be filled in at the end of the day)
