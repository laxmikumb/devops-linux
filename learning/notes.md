# Linux Fundamentals: Notes

## Block 1: Files and navigation

| Command | What it does |
|---|---|
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

## Quiz answers

(to be filled in at the end of the day)
