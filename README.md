<h1>Introduction</h1>
A Perl programs which implement a subset of the version control system Git.
Git is a very complex program which has many individual commands. This project will implement only a few of the most important commands.
</br>
<h1>Legit Commands</h1>

<h3>legit-init</h3>
The <b>legit-init</b> command creates an empty Legit repository. legit-init should create a directory named <b>legit</b> which it will use to store the repository. It will produce an error message if this directory already exists

<h3>legit-add filenames</h3>
The <b>legit-add</b> command adds the contents of one or more files to the <b>"index"</b>.

Only ordinary files in the current directory can be added, and their names will always start with an alphanumeric character ([a-zA-Z0-9]) and will only contain alpha-numeric characters plus '.', '-' and '_' characters.

<h3>legit-commit -m message</h3>
The <b>legit-commit</b> command saves a copy of all files in the index to the repository.
A message describing the commit will included as part of the commit command.

<h3>legit-log</h3>
The <b>legit-log</b> command prints one line for every commit that has been made to the repository.
Each will should contain the commit number and the commit message.

<h3>legit-show commit:filename</h3>
The <b>legit-show</b> will print the contents of the specified file as of the specified commit.
If the commit is omitted the contents of the file in the index should be printed.

<h3>legit-commit [-a] -m message</h3>
<b>legit-commit</b> can have a <b>-a</b> option which causes all files already in the index to have their contents from the current directory added to the index before the commit.

<h3>legit-rm [--force] [--cached] filenames</h3>
<b>legit-rm</b> removes a file from the index, or from the current directory and the index.
If the <b>--cached</b> option is specified the file is removed only from the index and not from the current directory.

<b>legit-rm</b> like <b>git rm</b> will stop the user accidentally losing work, and will give an error message instead of if the removal would cause the user to lose work.

The <b>--force</b> option overrides this, and will carry out the removal even if the user will lose work.

<h3>legit-status</h3>
<b>legit-status</b> shows the status of files in the current directory, index, and repository.

<h3>legit-branch [-d] [branch-name]</h3>
<b>legit-branch</b> either creates a branch, deletes a branch or lists current branch names.

<h3>legit-checkout branch-name</h3>
<b>legit-checkout</b> switches branches.
Note unlike <b>git</b> you can not specify a commit or a file, you can only specify a branch.
