# Git Practice Notes


## My practice log (short entries I wrote while practising)

- Main moved on while the feature branch existed
- Day 1: learned working tree vs staging area
- HEAD points to the latest commit on the current branch
- git log --oneline --graph shows history as a compact tree
- Good commit message: short, present tense, says what and why
- Second branch: merge commit demo

---

# How to use this document

Each block has four parts: the concepts (why it works the way it does), a command table (what each command does and when to use it), a "which one is better" section for commands that look alike, and a short log of what was done in the real repo. Treat the tables as a reference and the prose as the explanation you give in the demo.

| Block | Topic | Core idea in one line |
|---|---|---|
| 1 | How Git works | Three areas: working tree, staging area, repository |
| 2 | Branches and merging | A branch is a pointer; merge joins two lines of work |
| 3 | Conflicts and history | Resolve clashes, undo safely, mark releases |
| 4 | GitHub team workflow | Remotes, SSH, pull requests, protected main |

---

# Block 1: How Git works

## 1.1 The big idea

Git does not store "versions of a file" one after another. It stores **snapshots** of your whole project. Every commit is a snapshot plus a message, an author, a date, and a link to its parent commit. Because each commit points to its parent, the history is a chain, and that chain is what `git log` shows.

Git keeps your work in three areas, and almost every beginner mistake comes from not knowing which area a change is in.

| Area | What it is | How a change gets in |
|---|---|---|
| Working tree | The actual files on disk that you edit | You save a file in your editor |
| Staging area (also called the index) | A draft of your next commit | `git add` |
| Repository | The permanent history of commits | `git commit` |

The flow is always: **edit, then add, then commit**. The staging area exists so you can build a clean commit. If you changed three files but only two belong to one logical change, you stage just those two and commit them with a message that describes that change alone.

## 1.2 What HEAD is

`HEAD` is a pointer to "where you are now". Normally it points to a branch name (like `main`), and the branch points to the latest commit on that branch. When you make a new commit, Git creates it with the old latest commit as its parent, then moves the branch (and so `HEAD`) forward to the new commit. That is why the graph grows forward only.

`HEAD~1` means "one commit before HEAD", `HEAD~2` means two before, and so on. You will use this with `reset` and `show`.

## 1.3 Command reference

| Command | What it does | When and why to use it |
|---|---|---|
| `git status` | Lists changed, staged and untracked files, and the current branch | Run it before and after almost every command. It tells you which area each change is in |
| `git add <file>` | Moves one file's changes into the staging area | The default. You choose exactly what goes into the commit |
| `git add .` | Stages everything under the current folder | Fast, but it can pick up logs or `.env`. Always read `git status` first |
| `git add -p` | Walks through changes chunk by chunk and asks yes or no for each | When one file has two unrelated edits and you want two separate commits |
| `git commit -m "message"` | Saves the staged snapshot with your message | The normal way to commit |
| `git commit` | Opens your editor for a longer message | When the change needs a body explaining why |
| `git diff` | Working tree compared with staging area | Review your edits before `git add` |
| `git diff --staged` | Staging area compared with the last commit | Review exactly what the next commit will contain |
| `git diff HEAD` | Working tree compared with the last commit | One view of everything changed, staged or not |
| `git log` | Full history with author and date | When you need who and when |
| `git log --oneline` | One line per commit (short hash and message) | Quick scan of history |
| `git log --oneline --graph` | Same, with a drawing of branches and merges | Best everyday view |
| `git log --oneline --graph --all` | Same, but includes every branch and tag | To see all branches together |
| `git log -5` | Only the last 5 commits | Keep output short |
| `git show <hash>` | Shows one commit's message and its changes | To inspect what a commit actually did |

## 1.4 Which one is better when two commands look similar

**`git diff` and `git diff --staged`.** They answer different questions. Before you stage, `git diff` shows your edits. After you stage, `git diff` shows nothing, because the working tree now matches the staging area, and that confuses many beginners. Use `git diff --staged` to see what is about to be committed. If you want everything in one view, `git diff HEAD` is the better choice.

**`git add file` and `git add .`.** `git add file` is safer because it can never include something you did not intend. `git add .` is fine when you have already read `git status` and everything listed belongs in the commit. For the best control, use `git add -p`.

**`git log` and `git log --oneline --graph`.** Use the second for daily work. It is compact and shows branch shape. Use plain `git log` only when you need author and date.

## 1.5 Writing good commit messages

A commit message is a note to your future self and your team. A good one has these qualities:

- The first line is short (about 50 characters), written in the imperative present tense: "Add backup script", not "added stuff" and not "Adding".
- It says what changed, and why if the reason is not obvious.
- It covers one logical change. Small focused commits make `revert` and debugging much easier.
- It avoids empty messages such as `update`, `fix`, `changes` or `asdf`.

## 1.6 What I did in my repo

I started at commit `b296ea2` and made six commits (five required, plus one fix):

```
bf68717 Add the git practice notes
26a069f Note working tree vs staging area
50f0c70 Note what HEAD means
8516745 Note how to read git log
0e1245a Note good commit message rules
9efa2f9 Fix markdown heading in notes     <- HEAD -> main
```

The graph from `git log --oneline --graph` was a straight line of `*` symbols. A straight line means there were no branches or merges yet. Pushing with `git push origin main` moved `origin/main` from `b296ea2` to `9efa2f9`.

## 1.7 Useful extras

| Command | What it does |
|---|---|
| `git restore --staged <file>` | Takes a file out of the staging area but keeps your edits |
| `git commit --amend -m "new message"` | Rewrites the last commit's message. Only do this before pushing |
| `git config --global user.name "Name"` | Sets the author name stored in your commits |
| `git config --global user.email "mail"` | Sets the author email stored in your commits |

---

# Block 2: Branches and merging

## 2.1 The big idea

A branch in Git is only a small movable label that points to a commit. Because it is just a label, creating a branch is instant and free, and that is why teams create one for every feature or fix. You work on the branch without disturbing `main`, and when the work is ready you merge it back.

`HEAD` points to the branch you are on. When you commit, the branch label moves forward and the other branches stay where they were. Merging then brings the commits of one branch into another.

## 2.2 Command reference

| Command | What it does | When and why to use it |
|---|---|---|
| `git branch` | Lists local branches; `*` marks the current one | To check where you are |
| `git branch -a` | Lists local and remote branches | To see what exists on GitHub |
| `git branch -vv` | Lists branches with their last commit and upstream | To see which branches track which remote branch |
| `git switch <name>` | Moves to an existing branch | Everyday branch change |
| `git switch -c <name>` | Creates a branch and moves to it | Start any new piece of work |
| `git merge <branch>` | Merges that branch into the branch you are on | Run it while standing on the branch that should receive the changes |
| `git merge --no-ff <branch>` | Forces a merge commit even when a fast-forward is possible | To keep a visible record that a feature branch existed |
| `git branch -d <name>` | Deletes a branch, but only if it is fully merged | Safe cleanup after a merge |
| `git branch -D <name>` | Force-deletes a branch even if it is not merged | To throw away work you do not want (be careful) |
| `git rm <file>` | Deletes a tracked file and stages the deletion | Removing a file in one step |
| `git mv <old> <new>` | Renames or moves a file and stages the change | Same as `mv` followed by `git add` |

## 2.3 Fast-forward versus merge commit

The kind of merge depends on whether the receiving branch moved while your feature branch existed.

| | Fast-forward | Merge commit |
|---|---|---|
| When it happens | The receiving branch has no new commits since the feature branch was created | Both branches have new commits |
| What Git does | Moves the branch label forward. No new commit | Creates a new commit that has two parents |
| Shape of history | A straight line | A diamond |
| My example | `fa9f95f` (feature/branch-practice) | `cd61b13` (Merge feature/second into main) |

Neither is always better. A fast-forward gives a clean, linear history that is easy to read. A merge commit preserves the fact that work happened in parallel and gives you one commit you can revert to undo the whole feature. Teams that want the record on purpose use `git merge --no-ff`.

## 2.4 Which one is better when two commands look similar

**`git switch` and `git checkout`.** `checkout` is the older command and does several unrelated jobs (changing branches and restoring files). `switch` only changes branches, so it is clearer and harder to misuse. Use `switch` for branches and `restore` for files.

**`git branch -d` and `-D`.** Always try `-d` first. If Git refuses, the branch holds commits that are not merged, and you should stop and check. Use `-D` only when you are sure you want to discard that work.

**`git rm file` and `rm file`.** `git rm` deletes the file and stages the deletion in one step. Plain `rm` deletes the file but you still have to run `git add` or `git commit -a`.

## 2.5 The .gitignore file

`.gitignore` tells Git which files to leave alone. In this task it keeps logs, secrets and backups out of the repository:

```
*.log
.env
backups/
```

Points to remember:

- Put it in the **repository root** so it covers every folder. (My first attempt landed in `git-practice/` because I ran the command from that folder. I fixed it with `git mv`.)
- To test it: `touch test.log .env`, then `git status`. They must not appear.
- It only affects files Git is not already tracking. If a file was committed earlier, run `git rm --cached <file>` to stop tracking it, then commit.
- `ls -A` shows hidden files such as `.gitignore`. Plain `ls` hides them, which is why a stray `.gitignore` can hide in a folder that looks clean.

## 2.6 What I did in my repo

- **Fast-forward:** created `feature/branch-practice`, committed, switched to `main` and merged. Git said "Fast-forward" because `main` had not moved.
- **Merge commit:** created `feature/second` and added a line at the end of `notes.md`. On `main` I added a line near the top. Then `git merge feature/second`. The edits were in different places, so Git merged them with no conflict.

```
*   cd61b13 Merge feature/second into main
|\
| * aa71dda Add merge commit demo note on feature branch
* | a2aca27 Add note on main while feature branch exists
|/
* 36bfa75 Remove branch-demo.md
```

- **Mistakes and fixes:** `.gitignore` was created in the wrong folder and moved with `git mv`. A demo file inside `git-practice/` was removed with `git rm` so that folder holds only `notes.md`.

---

# Block 3: Conflicts and history

## 3.1 Merge conflicts

A conflict happens when two branches changed the **same lines** of the same file and Git cannot decide which version to keep. Git stops the merge, marks the file, and waits for you.

A conflicted file looks like this:

```
<<<<<<< HEAD
Conflict demo: version A
=======
Conflict demo: version B
>>>>>>> feature/conflict-b
```

- Between `<<<<<<< HEAD` and `=======` is the version on the branch you are on.
- Between `=======` and `>>>>>>>` is the version from the branch you are merging in.

To resolve it:

1. Run `git status`. Files marked "both modified" need attention.
2. Open the file and decide what the final text should be: keep one side, the other, or combine both.
3. Delete all three marker lines (`<<<<<<<`, `=======`, `>>>>>>>`). Leaving them in is a classic mistake.
4. `git add <file>` to say it is resolved.
5. `git commit` (or `git merge --continue`) to finish the merge.

If you get stuck, `git merge --abort` puts everything back exactly as it was before the merge. That makes it safe to practise.

## 3.2 Merge versus rebase

Both bring changes from one branch into another, but they build different histories.

| | `git merge main` (on a feature branch) | `git rebase main` (on a feature branch) |
|---|---|---|
| What it does | Joins the two lines with a merge commit | Replays your commits on top of the latest `main` |
| History | Keeps the true branching shape (diamond) | Straight line, as if you started from the latest `main` |
| Existing commits | Not changed | Rewritten (new hashes) |
| Safe on shared branches | Yes | No |

**The golden rule: never rebase commits that other people already have.** Because rebase creates new commits with new hashes, anyone who has the old ones gets a confusing, diverged history. Rebase your own local, unpushed feature branch to tidy it, and merge when the branch is shared.

Which is better? For a private feature branch, rebase gives a cleaner history. For anything shared, or when you want an honest record, merge is the safe choice. Many teams rebase locally and then merge through a pull request.

Basic rebase demo:

```
git switch feature/rebase-demo
git rebase main
```

If a conflict happens during a rebase, fix the file, `git add` it, then `git rebase --continue`. To cancel, `git rebase --abort`.

## 3.3 Stash

`git stash` puts your uncommitted changes on a shelf so you can switch branches with a clean tree, then bring them back later.

| Command | What it does |
|---|---|
| `git stash` | Saves tracked changes and cleans the working tree |
| `git stash -u` | Also stashes untracked files |
| `git stash list` | Shows all stashes |
| `git stash pop` | Re-applies the latest stash and deletes it from the list |
| `git stash apply` | Re-applies the latest stash but keeps it in the list |
| `git stash drop` | Deletes the latest stash without applying it |

`pop` versus `apply`: use `pop` for the normal case. Use `apply` when you want to try the same changes on more than one branch, since the stash stays available.

## 3.4 Undoing things: restore, reset and revert

This is the most important part of the block, because the three commands undo different things.

| Situation | Command | Effect |
|---|---|---|
| Discard edits in a file (not staged) | `git restore <file>` | Working tree file returns to the last commit. **The edits are lost** |
| Unstage a file | `git restore --staged <file>` | Removes it from staging, keeps your edits |
| Undo the last commit, keep changes staged | `git reset --soft HEAD~1` | Commit removed, changes stay staged |
| Undo the last commit, keep changes unstaged | `git reset HEAD~1` (mixed, the default) | Commit removed, changes stay in files |
| Undo the last commit and delete the changes | `git reset --hard HEAD~1` | Commit and changes both gone |
| Undo a commit that is already pushed | `git revert <hash>` | Adds a **new** commit that reverses the old one |

### reset: soft, mixed, hard

`reset` moves the branch pointer backwards. The three modes differ in what they do to the other two areas:

| Mode | Branch pointer | Staging area | Working tree |
|---|---|---|---|
| `--soft` | Moves back | Keeps the changes | Keeps the changes |
| `--mixed` (default) | Moves back | Cleared | Keeps the changes |
| `--hard` | Moves back | Cleared | Cleared (changes deleted) |

`--hard` is the dangerous one because it throws away uncommitted work.

### reset versus revert

- `git reset` **rewrites history** by removing commits. Use it only on commits that exist only on your machine.
- `git revert` **adds a new commit** that undoes an earlier commit. History is kept, so it is safe for commits that are already pushed or shared.

Rule of thumb: not pushed yet, use `reset`. Already pushed, use `revert`.

If a revert would conflict, resolve it like a merge conflict, then `git revert --continue`. To revert a merge commit you must pick a parent: `git revert -m 1 <merge-hash>`.

### The safety net: reflog

If you reset something by mistake, `git reflog` lists every place `HEAD` has been, including commits that no longer appear in `git log`. You can bring one back with `git reset --hard <hash>` or `git switch -c rescue <hash>`. Reflog is local and does not last forever, but it saves you from most accidents.

## 3.5 Tags

A tag is a fixed label on a specific commit, usually used for releases.

| Command | What it does |
|---|---|
| `git tag v1.0` | Creates a **lightweight** tag (just a name) |
| `git tag -a v1.0 -m "first release"` | Creates an **annotated** tag with author, date and message |
| `git tag` | Lists tags |
| `git show v1.0` | Shows the tag details and the commit |
| `git push origin v1.0` | Pushes one tag to GitHub |
| `git push origin --tags` | Pushes all tags |

Annotated tags are the better choice for releases because they record who tagged it and why. Tags are not pushed automatically with `git push`, so remember to push them.

## 3.6 Blame

`git blame <file>` prints each line of a file with the commit, author and date that last changed it. Use it to find out why a line is the way it is, then `git show <hash>` to read that commit. It is for understanding history, not for blaming people.

## 3.7 Which one is better when two commands look similar

- **`git restore file` and `git checkout -- file`:** both discard edits in a file. `restore` is the modern, clearer command.
- **`git stash pop` and `git stash apply`:** `pop` cleans up after itself; `apply` keeps the stash.
- **`git reset --soft` and `git commit --amend`:** both let you redo the last commit. `--amend` is quicker for a small fix; `--soft HEAD~1` is better when you want to re-split the work into new commits.
- **`git commit -am "msg"`:** stages and commits all **tracked** changes in one step. It skips brand-new files, so use `git add` for those.

## 3.8 Practice plan for this block

1. Create a conflict on purpose: two branches change line 2 of `notes.md` differently, merge both, resolve, commit.
2. Make a bad commit, then undo it with `git revert HEAD`.
3. Compare `reset --soft` with `revert` and write when you would use each.
4. Stash a change, switch branches, pop it back.
5. Rebase a feature branch on `main` and compare the graph with a merge.
6. Run `git blame` on `notes.md`.
7. Create the release tag `v1.0`.

---

# Block 4: GitHub team workflow

## 4.1 Remotes

A **remote** is another copy of your repository, usually on GitHub. By convention the main remote is called `origin`. Your local repo and the remote are independent, so changes only travel when you push or pull.

| Command | What it does |
|---|---|
| `git remote -v` | Shows remote names and URLs |
| `git remote add origin <url>` | Connects the local repo to a remote |
| `git remote set-url origin <url>` | Changes a remote's URL (for example HTTPS to SSH) |
| `git clone <url>` | Copies a remote repo to your machine and sets `origin` for you |

## 4.2 Push, pull and fetch

| Command | What it does | When to use it |
|---|---|---|
| `git push origin <branch>` | Uploads your commits to the remote branch | After committing locally |
| `git push -u origin <branch>` | Pushes and remembers the link (upstream) | The first push of a new branch, so later `git push` and `git pull` need no arguments |
| `git fetch` | Downloads new commits but does **not** change your files | To look at what changed before deciding |
| `git pull` | Fetch plus merge into your current branch | Normal way to update |
| `git pull --rebase` | Fetch plus rebase instead of merge | Keeps your history straight when you have local commits |
| `git push origin --delete <branch>` | Deletes a branch on GitHub | Cleanup after a merged PR |
| `git fetch --prune` | Fetches and removes references to deleted remote branches | Keeps `git branch -a` tidy |

### fetch versus pull

`git pull` is really `git fetch` followed by `git merge`. Because `fetch` changes nothing in your working files, it is the safer command: after fetching you can run `git log main..origin/main` to see what is new, and then decide to merge. Use `pull` when you already know you want the changes.

### Rejected pushes

If `git push` is rejected with "fetch first" or "non-fast-forward", the remote has commits you do not have. Run `git pull` (or `git pull --rebase`), fix any conflict, and push again. Avoid `git push --force`. If you must, use `--force-with-lease`, which refuses to overwrite work you have not seen.

## 4.3 SSH keys for GitHub

GitHub no longer accepts account passwords for Git over HTTPS. You can use a personal access token, or an SSH key. An SSH key is a pair of files: a **private key** that stays on your machine and a **public key** that you give to GitHub. Git then proves who you are without typing anything each time.

Steps:

```
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Press Enter to accept the default file (`~/.ssh/id_ed25519`). A passphrase is recommended.

```
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

Copy the whole line printed by the last command. On GitHub go to **Settings, SSH and GPG keys, New SSH key**, paste it, and save. Then test:

```
ssh -T git@github.com
```

You should see a message like "Hi laxmikumb! You've successfully authenticated". Finally switch the repo from HTTPS to SSH:

```
git remote set-url origin git@github.com:laxmikumb/devops-linux.git
git remote -v
```

Never share or commit the private key (`id_ed25519` without `.pub`). Only the `.pub` file goes to GitHub.

| HTTPS with token | SSH key |
|---|---|
| Needs a token pasted or stored in a credential helper | Key lives on your machine, nothing to type |
| Tokens expire and must be renewed | Works until you remove the key |
| Easier through strict firewalls | Better for daily use on your own machine |

SSH is the better long-term choice for your own laptop.

## 4.4 Pull requests

A **pull request (PR)** is a request on GitHub to merge one branch into another. It is where the team reads the diff, comments, and approves before anything reaches `main`.

The full flow:

```
git switch -c feature/x
# edit files
git add <files>
git commit -m "Clear message"
git push -u origin feature/x
```

Then on GitHub: open the repo, click **Compare and pull request**, write a short title and description of what changed and why, and create the PR. Read the **Files changed** tab (reviewing your own diff is part of this task), then merge. Afterwards:

```
git switch main
git pull
git branch -d feature/x
git push origin --delete feature/x
```

GitHub offers three ways to merge a PR:

| Option | Result | Best for |
|---|---|---|
| Create a merge commit | Keeps every commit and adds a merge commit | Preserving full history |
| Squash and merge | Combines all PR commits into one commit on `main` | Many tiny "fix typo" commits, clean `main` |
| Rebase and merge | Replays the commits on `main` with no merge commit | Linear history with every commit kept |

For this task any is acceptable. Squash is popular for a tidy `main`; a merge commit is the most literal record.

## 4.5 Branch protection

Branch protection stops people (including you) from pushing straight to `main`. Teams use it because `main` is what gets deployed: a mistake pushed directly can break production with nobody having looked at it. Requiring a pull request makes every change visible, reviewable, and easy to revert, and lets automated checks run first.

To set it up on GitHub: repository **Settings, Branches, Add branch protection rule** (or **Settings, Rules, Rulesets** on newer layouts). Use the branch name pattern `main`, then tick:

- **Require a pull request before merging**
- Required approvals: leave at 0 when working alone (you cannot approve your own PR). In a team you would set 1 or more.
- **Do not allow bypassing the above settings**, or include administrators, so the rule also applies to you as owner.

After this, `git push origin main` should be rejected, and all work must go through a branch and a PR. Test it once and keep a screenshot or a note of the error message.

One caution: on a **private** repository with a free personal account, branch protection may not be available. If the option is missing or locked, either make the repository public or note that limitation, and follow the PR workflow anyway.

## 4.6 Which one is better when two commands look similar

- **`git fetch` and `git pull`:** `fetch` is safer because it changes nothing locally. `pull` is faster when you trust the incoming changes.
- **`git pull` and `git pull --rebase`:** plain `pull` makes a merge commit when both sides have new commits. `--rebase` keeps your local commits on top in a straight line. For your own branch, `--rebase` gives a cleaner log.
- **`--force` and `--force-with-lease`:** always prefer `--force-with-lease`.
- **HTTPS and SSH:** SSH is better for regular use; HTTPS with a token is fine for a one-off clone.

## 4.7 Practice plan for this block

1. Create an SSH key, add the public key to GitHub, run `ssh -T git@github.com`.
2. Switch `origin` to the SSH URL and confirm with `git remote -v`.
3. Protect `main` so a pull request is required, and confirm a direct push is rejected.
4. Create a branch, commit, `git push -u origin <branch>`, open a PR, review the diff, merge.
5. Pull the merged `main`, delete the branch locally and on GitHub.

---

# Quick comparison sheet

| Goal | Use this | Not this, and why |
|---|---|---|
| Move to a branch | `git switch` | `git checkout`, because it does too many jobs |
| See unstaged edits | `git diff` | |
| See what the next commit contains | `git diff --staged` | plain `git diff` shows nothing after `git add` |
| Join a shared branch | `git merge` | `git rebase`, because it rewrites shared history |
| Tidy my private branch | `git rebase main` | |
| Undo a pushed commit | `git revert` | `git reset`, because it rewrites history others have |
| Undo a local, unpushed commit | `git reset --soft HEAD~1` | |
| Discard edits to a file | `git restore <file>` | `git reset --hard`, because it wipes everything |
| Mark a release | `git tag -a v1.0 -m "..."` | a lightweight tag, because it has no author or message |
| Check what is new on GitHub | `git fetch` | `git pull`, because it changes your files |
| Delete a merged branch | `git branch -d` | `-D`, because it skips the safety check |

# Quiz answers prepared from these blocks

These are model answers to the Git questions in the task. Rewrite them in your own words in `docker/notes.md`.

**1. Merge versus rebase, and when not to rebase.** Merge joins two branches with a merge commit and keeps history exactly as it happened. Rebase replays your commits on top of another branch, giving a straight line but creating new commits. Do not rebase commits that have been pushed and that others may have based work on, because rewriting shared history causes diverged copies.

**2. A password was committed and pushed.** First treat the secret as compromised: change or revoke it immediately, because it stays in history and may already have been copied. Then remove it from the repository (delete it from the file, commit, and if needed rewrite history with a tool such as `git filter-repo` or BFG and force push). Add the file to `.gitignore`, move the value to `.env`, and commit a `.env.example` with placeholders.

**3. `git reset --hard` versus `git revert`.** `reset --hard` moves the branch back and deletes the changes, rewriting history. `revert` adds a new commit that reverses an earlier one and keeps history intact, so it is the safe option for pushed commits.

**4. Why protect `main` and use pull requests.** `main` is the trusted, deployable branch. Protection forces every change through review and checks, prevents accidental or unreviewed pushes and force pushes, and leaves a clear record of who changed what and why.
