#!/usr/bin/perl -w
use File::Compare;
use File::Copy::Recursive qw(dircopy);
use File::Path 'rmtree';

$repository = ".legit";

#if there are no argument exists, print usage
if (@ARGV == 0) {
    usage();
    exit 1;
}

# init - command creates an empty legit repository.
$command = shift @ARGV;

# get the $current_branch
if (open FILE, '<', ".legit/.currBranch/branch") {
    for ($line = <FILE>) {
        $current_branch = $line;
    }
} else {
    #means current_branch doesn't exist, haven't commit yet
    $current_branch = "null";
}

# legit.pl init
# if .legit has already exist, return error message
# otherwise create a empty .legit
if ($command eq "init") {
    # check if $respository has already exist or not
    if (-e $repository) {
        die "legit.pl: error: .legit already exists\n";
    }
    mkdir $repository;
    print "Initialized empty legit repository in .legit\n";
}

# add filenames
# add command adds the contents of one or more files to the "index"
elsif ($command eq "add") {
    if (! -e $repository) {
        die "legit.pl: error: no .legit directory containing legit repository exists\n";
    }
    # nothing added
    die "legit.pl: error: internal error Nothing specified, nothing added.\n"if @ARGV == 0;
    addToIndex(@ARGV);
}

# saves a copy of all files in the index to the repository.
elsif ($command eq "commit") {
    if (! -e $repository) {
        die "legit.pl: error: no .legit directory containing legit repository exists\n";
    }

    if (@ARGV == 0) {
        die "usage: legit.pl commit [-a] -m commit-message\n";
    }
    #if branch haven't exist, create a new branch called master
    if ($current_branch eq "null") {
        $current_branch = "master";
        mkdir "$repository/$current_branch" or die "can not create $current_branch: $!\n";

        # create a dic called .currBranch to save the details of current branch
        if (! -e "$repository/.currBranch") {
            mkdir "$repository/.currBranch" or die;
        }

        #create a file called "branch" to store the current branch
        $branch_file = "branch";
        open my $branch, '>', "$repository/.currBranch/$branch_file";
        print $branch $current_branch;
    }

    # find the last commit repository
    $count = 0;
    $snapshot = $repository.$count;
    while (-e "$repository/$current_branch/$snapshot") {
        $count++;
        $snapshot = "$repository$count";
    }
    $tmp = $count - 1;

    # commit -m message
    if ($ARGV[0] eq "-m") {
        die "usage: legit.pl commit [-a] -m commit-message\n" if @ARGV != 2;

        # if there doesn't have .tmp file
        # check if there has anything new added to the tmp that different as last commit
        if (check_commit("$repository/.tmp", "$repository/$current_branch/$repository$tmp") == 0) {
            die "nothing to commit\n";
        }

        #get the commit message
        $comment = $ARGV[1];
        $comment =~ s/^'+//g;
        $comment =~ s/'+$//g;
        legitCommit($snapshot);

    # commit [-a] -m
    } elsif ($ARGV[0] eq "-a" && $ARGV[1] eq "-m") {
        die "usage: legit.pl commit [-a] -m commit-message\n" if (@ARGV != 3);
        # means nothing to commit;
        $flag = 0;
        for $file (glob "$repository/.tmp/*") {
            $file_in_index = $file;
            $file =~ s/$repository\/.tmp\///g;
            if (-e "$file" && check_same_file("$file", "$file_in_index") == 0) {
                $flag = 1;
                last;
            }
        }

        if ($flag == 0 && check_commit("$repository/.tmp", "$repository/$current_branch/$repository$tmp") == 0) {
            die "nothing to commit\n";
        }

        $comment = $ARGV[2];
        $comment =~ s/^'+//g;
        $comment =~ s/'+$//g;

        # all files already in the index to have their contents from the current
        # directory added to the index before the commit.
        my @files;
        for $file (glob "$repository/.tmp/*") {
            $file =~ s/$repository\/.tmp\///g;
                #add files in the index to the array
            push @files, $file;
        }
        # added to the index first
        addToIndex(@files);
        legitCommit($snapshot);

    }

    # save commit message to the folder of new snapshot
    $log_file = "log";
    open my $log, '>', "$repository/$current_branch/$snapshot/$log_file";
    print $log $comment;

    print "Committed as commit $count\n";
}

# legit.pl log
# prints one line for every commit that has been made to the repository.
elsif ($command eq "log") {
    # error handling
    if (! -e $repository) {
        die "legit.pl: error: no .legit directory containing legit repository exists\n";
    }
    $lastCommit = get_last_commit($current_branch);
    if ($lastCommit eq "null") {
        die "legit.pl: error: your repository does not have any commits yet\n";
    }

    die "usage: legit.pl log\n" if (@ARGV != 0);
    # create a hashtable to store each commit messages
    my %commit;
    for $file (glob ".legit/$current_branch/.legit*") {
        # means this files are floders which store the commit
        if ($file =~ /[0-9]+/) {
            # open the log file, read the commit message from the log file
            open FILE, '<', "$file/log" or die;
            while ($line = <FILE>) {
                $comment = $line;
            }

            # add it to the hashtable to store commit message
            # key is commit number, content is commit message for this commit
            $file =~ s/$repository\/$current_branch\/.legit//g;
            $file_number = $file;

            if (!exists $commit{$file_number}) {
                $commit{$file_number} = $comment;
            }
        }
    }
    # print the hashtable
    print_log_hash(%commit);
}

# show commit:filename
elsif ($command eq "show") {
    if (! -e $repository) {
        die "legit.pl: error: no .legit directory containing legit repository exists\n";
    }
    $lastCommit = get_last_commit($current_branch);
    if ($lastCommit eq "null") {
        die "legit.pl: error: your repository does not have any commits yet\n";
    }

    die "usage: legit.pl show <commit>:<filename>\n" if @ARGV != 1;
    # has invalid object
    if (! ($ARGV[0] =~ /:/)) {
        die "legit.pl: error: invalid object $ARGV[0]\n";
    }
    # get the commit_number and the file want to show
    my ($commit_number, $file) = split(/:/, $ARGV[0]);

    # check if the file name is valid
    if (! ($file =~ /^[a-zA-Z\.\-_]+$/)) {
        die "legit.pl: error: invalid filename '$file'\n";
    }

    # if the commit is omitted, the contentd of the file in the index should be printed
    # which means print the file in the .tmp file
    if ($ARGV[0] =~ /^:/) {
        show_file_in_index(".legit/.tmp", "$file");
    } else {
        # show the file in a specific commit
        show_file_in_commit(".legit/$current_branch/.legit$commit_number", "$file");
    }
}

# legit.pl rm removes a file from the index,
# or from the current directory and the index.
elsif ($command eq "rm") {
    if (! -e $repository) {
        die "legit.pl: error: no .legit directory containing legit repository exists\n";
    }
    # get the last commit folder
    $lastCommit = get_last_commit($current_branch);
    my @toDelete;

    # rm --cached [filename]
    # remove file from the index and not from the current directory
    # if the error message occur, doesn't delete anything
    if ($ARGV[0] eq "--cached" && !($ARGV[1] eq "--force")) {
        shift @ARGV;
        for $file (@ARGV) {
            $file_in_index = "$repository/.tmp/$file";
            $file_in_repo = "$repository/$current_branch/$lastCommit/$file";

            # file want to be deleted exist in the index
            if (-e "$file_in_index") {
                # file in the current directory is the same as that in index or last commit
                # added it to the toDelete array
                if (check_same_file("$file_in_index", "$file") == 1 || check_same_file("$file_in_index", "$file_in_repo") == 1) {
                    push @toDelete, $file_in_index;
                } elsif (-e "$file_in_index" && ! -e "$file" && ! -e "$file_in_repo") {
                    push @toDelete, $file_in_index;
                } else {
                    die "legit.pl: error: '$file' in index is different to both working file and repository\n";
                }
            } else {
                die "legit.pl: error: '$file' is not in the legit repository\n";
            }
        }

        # no error message occur
        # all the files in the command line can be removed successfully
        for $file (@toDelete) {
            unlink("$file");
        }

    # rm --force --cached
    # force remove file from the index without error checking
    # except the file doesn't exist in the index
    } elsif (($ARGV[0] eq "--force" && $ARGV[1] eq "--cached") || ($ARGV[0] eq "--cached" && $ARGV[1] eq "--force")) {
        shift @ARGV;
        shift @ARGV;
        for $file (@ARGV) {
            $file_in_index = "$repository/.tmp/$file";
            if (-e "$file_in_index") {
                push @toDelete, $file_in_index;
            } else {
                die "legit.pl: error: '$file' is not in the legit repository\n";
            }
        }
        for $file (@toDelete) {
            unlink("$file");
        }
    # rm --force [filename]
    # force remove file from index and last commit without error checking
    # except the file doesn't exist in the index
    } elsif ($ARGV[0] eq "--force" && ! ($ARGV[1] eq "--cached")) {
        shift @ARGV;
        for $file (@ARGV) {
            $file_in_index = "$repository/.tmp/$file";
            if (-e "$file_in_index") {
                push @toDelete, $file_in_index;
            } else {
                die "legit.pl: error: '$file' is not in the legit repository\n";
            }
        }

        # no error message occur
        # all the files in the command line can be removed successfully
        for $file (@toDelete) {
            #remove from the index
            unlink("$file");
            #remove from the current directory
            $file =~ s/$repository\/.tmp\///g;
            unlink("$file");
        }
    # rm [filename]
    } else {
        # from the current directory and the index.
        legit_rm(@ARGV);
    }
}


# legit.pl status shows the status of files in the current directory, index, and repository.
elsif ($command eq "status") {
    if (! -e $repository) {
        die "legit.pl: error: no .legit directory containing legit repository exists\n";
    }

    # create a hashtable to store the status of each file
    my %files;
    $lastCommit = get_last_commit($current_branch);

    # if there doesn't have any commit yet
    if ($lastCommit eq "null") {
        die "legit.pl: error: your repository does not have any commits yet\n";
    }
    # added files exist in the current directory
    # the name of file is the key, the status of file is content
    for $file (glob "*") {
        if ($file =~ /^[a-zA-Z0-9\.\-_]+$/ && ! ($file =~ /^legit.pl/)) {
            $status = checkStatus($file);
            if (!exists $files{$file}) {
                $status = checkStatus($file);
                $files{$file} = $status;
            }
        }
    }
    # if the file be deleted by 'rm' or 'file-deleted'
    # we also need to get this file status by checking the index folder and last commit folder
    %files = addFileToHash(".tmp*", %files);
    %files = addFileToHash("$current_branch/$lastCommit*", %files);

    # print the status of all the files
    foreach my $f (sort keys %files) {
        print "$f - $files{$f}\n";
    }
}

# legit.pl branch [-d] [branch-name]
elsif ($command eq "branch") {
    if (! -e $repository) {
        die "legit.pl: error: no .legit directory containing legit repository exists\n";
    }
    $lastCommit = get_last_commit($current_branch);
    if ($lastCommit eq "null") {
        die "legit.pl: error: your repository does not have any commits yet\n";
    }

    if (@ARGV == 0) {
        # lists current branch names
        printBranch();
    }
    #delete a branch
      elsif (@ARGV == 2 && $ARGV[0] eq "-d") {
          $delete_branch = $ARGV[1];
          deleteBranch($delete_branch);
    #create a new branch
    } elsif (@ARGV == 1 && !($ARGV[0] eq "-d")) {
          $new_branch = $ARGV[0];
          createBranch($new_branch);
    } else {
        die "usage: legit.pl branch [-d] <branch>\n";
    }
}

# legit.pl checkout branch-name
elsif ($command eq "checkout") {
    if (! -e $repository) {
        die "legit.pl: error: no .legit directory containing legit repository exists\n";
    }
    $lastCommit = get_last_commit($current_branch);

    if ($lastCommit eq "null") {
        die "legit.pl: error: your repository does not have any commits yet\n";
    }

    die "usage: legit.pl checkout <branch>\n" if (@ARGV != 1);

    $currBranch = $ARGV[0];
    #if branch doesn't exist
    if (! -e "$repository/$currBranch") {
        die "legit.pl: error: unknown branch '$currBranch'\n";
    } else {
        #write the new branch to the file in .legit/.currBranch/branch
        open my $branch, '>', "$repository/.currBranch/branch";
        print $branch $currBranch;
        print "Switched to branch '$currBranch'\n";
    }
} elsif ($command eq "merge") {

} else {
    usage();
}

#================================#
# Helper function
#================================#

# list all the current branches
sub printBranch {
    # if there are no master branch exist, throws error message
    if (! -e "$repository/master") {
        die "legit.pl: error: your repository does not have any commits yet\n";
    }
    # create array to store the branch names
    my @branches;
    for $branch (glob "$repository/*") {
        $branch =~ s/^.legit\///g;
        push @branches, $branch;
    }
    # sort the branch names in array in alphabetical order
    @branches = sort @branches;
    for $branch (@branches) {
        print "$branch\n";
    }
}

# create new branch
# if the name of new branch already exist, throws error messag
# else create a new copy of master branch named by new branch name
sub createBranch {
    my ($branchName) = @_;
    if (-e "$repository/$branchName") {
        die "legit.pl: error: branch '$branchName' already exists\n";
    }
    dircopy("$repository/master","$repository/$branchName") or die("$!\n");
}

# delete the branch
# if the branch want to be deleted doesn't exist, throw error message
# if the branch want to be deleted is master, throw error message
# else delete the whole branch
sub deleteBranch {
    my ($deleteBranchName) = @_;
    if (! -e "$repository/$deleteBranchName") {
        die "legit.pl: error: branch 'b1' does not exist\n";
    } elsif ($deleteBranchName eq "master") {
        die "legit.pl: error: can not delete branch 'master'\n";
    } else {
        #rmdir -r ("$repository/$deleteBranchName");
        rmtree([ "$repository/$deleteBranchName" ]);
        print "Deleted branch '$deleteBranchName'\n";
    }
}

# get the last commit of a specific branch
sub get_last_commit {
    #the the last commit of current branch
    my ($current_branch) = @_;
    my $index = 0;
    my $commit = $repository.$index;
    while (-e "$repository/$current_branch/$commit") {
        $index++;
        $commit = "$repository$index";
    }
    $index = $index - 1;
    # didn't have any commit yet
    if ($index < 0) {
        $commit = "null";
    } else {
        $commit = "$repository$index";
    }
    return $commit;
}

# copy a file from source to destination
sub copy_file {
    my ($source, $destination) = @_;
    open my $in, '<', $source or die "legit.pl: error: can not open '$source'\n";
    open my $out, '>', $destination or die "Cannot open $destination: $!";

    while ($line = <$in>) {
        print $out $line;
    }

    close $in;
    close $out;
}

# check if two folders contain the same files
# if two folder is the same, return 0, otherwise return 1
sub check_commit {
    my ($folder1, $folder2) = @_;

    if (! -e $folder1) {
        return 0;
    }
    # if two folders didn't have same file numbers, they are different
    my $num1 = get_files_number($folder1);
    my $num2 = get_files_number($folder2) - 1;
    return 1 if ($num1 != $num2);

    # two folders has same file number, compare the file content
    # if file in folder1 doesn't exist in folder2, they are different, return 1
    # if file in folder1 also exist in folder2 but has different content, return 1
    for $file (glob "$folder1/*") {
        $original = $file;
        $file =~ s/^.legit\/.tmp\///g;
        if (-e "$folder2/$file") {
            if (check_same_file("$original", "$folder2/$file") == 0) {
                return 1;
            }
        } else {
            return 1;
        }
    }
    return 0;
}

# get the file numbers in the folder
sub get_files_number {
    my ($folder) = @_;
    my $num = 0;
    for $file(glob "$folder/*") {
        if (-e $file) {
            $num++;
        }
    }
    return $num;
}

# print the hashtable contains commit messages by order
sub print_log_hash {
    my (%hash) = @_;
    foreach my $commit_number (sort { $b <=> $a } keys %hash) {
        print "$commit_number $hash{$commit_number}\n";
    }
}

# show file in the index folder
# if the file doesn't exist, throws error message
# otherwise read the file then print it
sub show_file_in_index {
    my ($folder, $file_name) = @_;
    open FILE, '<', "$folder/$file_name" or die "legit.pl: error: '$file_name' not found in index\n";
    while ($line = <FILE>) {
        print "$line";
    }
}

# show file in a specific commit folder
sub show_file_in_commit {
    my ($folder, $file_name) = @_;
    $commit_number = $folder;
    $commit_number =~ s/[.a-zA-Z\/]//g;
    # if the commit folder doesn't exist, throws error message
    if (! -e "$folder") {
        die "legit.pl: error: unknown commit '$commit_number'\n";
    } else {
        # read the file and print the content
        # if the file doesn't exist, throw error message
        open FILE, '<', "$folder/$file_name" or die "legit.pl: error: '$file_name' not found in commit $commit_number\n";
        while ($line = <FILE>) {
            print "$line";
        }
    }
}

# compare if two files is the same or not
# return 1 if two files are same, otherwise, return 0
sub check_same_file {
    my ($file1, $file2) = @_;
    if (-e $file2) {
        # use compare ($f1, $f2) function, return 0 if two files is the same
        if (compare("$file1","$file2") == 0) {
	           return 1;
    	} else {
            return 0;
        }
    }
    return 0;
}

# ./legit rm command line
sub legit_rm {
    my (@files) = @_;
    $lastCommit = get_last_commit($current_branch);
    my @toDelete;
    for $file (@files) {
        my $file_in_index = "$repository/.tmp/$file";
        my $file_in_repo = "$repository/$current_branch/$lastCommit/$file";

        # file is not in the current directory
        # if the delete file not in the working file
        # compare the file with the last commit
        if (! -e "$file") {
            # if the file exist in the index and last commit and they are the same
            # add it to the toDelete array waiting to delete
            # othereise, throws error message
            if (-e $file_in_index && $lastCommit eq "null") {
                push @toDelete, $file_in_index;
                next;
            }

            if (-e "$file_in_index" && -e "$file_in_repo") {
                if (check_same_file("$file_in_index", "$file_in_repo") == 1) {
                    push @toDelete, $file_in_index;
                } else {
                    die "legit.pl: error: '$file' has changes staged in the index\n";
                }

            # if the file exist in index but not in the last commit
            } elsif (-e "$file_in_index" && ! -e "$file_in_repo") {
                die "legit.pl: error: '$file' has changes staged in the index\n";

            # if the file doesn't exist in index and last commit
            } else {
                die "legit.pl: error: '$file' is not in the legit repository\n";
            }

        # file exists in the current directory
        } else {
            # file exists in index and last commit
            if (-e "$file_in_index" && -e "$file_in_repo") {
                # file in the index, last commit and current directory are the same
                # added to the toDelte array waiting to delete
                if (check_same_file("$file_in_index", "$file_in_repo") == 1 &&
                    check_same_file("$file_in_index", "$file") == 1 && check_same_file("$file_in_repo", "$file") == 1) {
                    push @toDelete, $file_in_index;

                # file in the index is different to that in the last commit
                # but the file in the index is same to the file in the current directory
                # which means the file has changed staged, cannot be delete
                # throws error message
                } elsif (check_same_file("$file_in_index", "$file_in_repo") == 0 &&
                         check_same_file("$file_in_index", "$file") == 1){
                      die "legit.pl: error: '$file' has changes staged in the index\n";
                # file in the index is different to both current directory and last commit
                # throws error message
                } elsif (check_same_file("$file_in_index", "$file_in_repo") == 0 &&
                         check_same_file("$file_in_index", "$file") == 0) {
                      die "legit.pl: error: '$file' in index is different to both working file and repository\n";

                # file in the index is different to current directory but same to the last commit
                } elsif (check_same_file("$file_in_index", "$file") == 0){
                    die "legit.pl: error: '$file' in repository is different to working file\n";
                }

            # file only in the index file but not in the last commit
            } elsif (-e "$file_in_index" && ! -e "$file_in_repo") {
                die "legit.pl: error: '$file' has changes staged in the index\n";

            # file doesn't exist in index and last commit
            } else {
                die "legit.pl: error: '$file' is not in the legit repository\n";
            }
        }
    }

    for $file (@toDelete) {
        unlink("$file");
        #delete from current file
        $file =~ s/$repository\/.tmp\///g;
        unlink("$file");
    }

}

# check the status of a specific file
sub checkStatus {
    my ($file) = @_;

    # ge the last commit of current_branch
    my $lastCommit = get_last_commit($current_branch);

    my $status;
    my $file_in_index = "$repository/.tmp/$file";
    my $file_in_repo = "$repository/$current_branch/$lastCommit/$file";

    # file exist in the current directory
    if (-e "$file") {
        # file doesn't exist in the index
        # then means this file is untracked
        if (! -e $file_in_index) {
            $status = "untracked";

        # file exists in the index
        } else {
            # file exist in index but doesn't in repository
            if (! -e $file_in_repo) {
                $status = "added to index";

            # file exist in index and last commit
            } else {
                # files in the current directory and index are different
                # files in the index and last commit is the same
                if (check_same_file("$file", "$file_in_index") == 0 && check_same_file("$file_in_index", "$file_in_repo") == 0) {
                    $status = "file changed, different changes staged for commit";
                # files in the current directory and the file in the index is the same
                # files in the index and the file in the last commit is different
                # which means if commit, files in the last commit will change
                } elsif (check_same_file("$file", "$file_in_index") == 1 && check_same_file("$file_in_index", "$file_in_repo") == 0) {
                    $status = "file changed, changes staged for commit";

                # files in the current directory and the file in the index is different
                # files in the index and the file in the last commit is same
                # which means if commit, the file in the last commit stay the same
                } elsif (check_same_file("$file", "$file_in_index") == 0 && check_same_file("$file_in_index", "$file_in_repo") == 1) {
                    $status = "file changed, changes not staged for commit";

                # file in current directory, index and last commit is the same
                } else {
                    $status = "same as repo";
                }
            }
        }

    # file doesn't exist in the current file
    } else {
        # file doesn't exists in the index and current directory but exists in the last commit
        # which means this file been removed by ./legit rm file
        if (! -e $file_in_index && -e $file_in_repo) {
            $status = "deleted";

        # file doesn't exist in the current directory, but exist in the index and last commit
        } elsif (-e $file_in_index && -e $file_in_repo) {
            $status = "file deleted";
        } elsif (-e $file_in_index && ! -e $file_in_repo) {
            $status = "added to index";
        } else {
            $status = 0;
        }
    }

    return $status;
}

# add file to the hashtable which save file name as a key and file status as the content
sub addFileToHash {
    my ($dictionary, %files) = @_;
    for $dic (glob "$repository/$dictionary") {
        # get rid of . and ..
        next if ($dic =~ /\.$/);
        for $file (glob "$dic/*") {
            $file =~ s/$dic\///g;
            if ($file =~ /^[a-zA-Z0-9.\-_]+$/ && !($file =~ /\blog\b/)) {
                if (!exists $files{$file}) {
                    $status = checkStatus($file);
                    $files{$file} = $status;
                    #if the status equal 0 means used to --force [] file
                    if ($status eq "0") {
                        #delete file from the files hashtable
                        delete $files{$file};
                    }
                }
            }
        }
    }
    return %files;
}

# add files to the index
# also include if the file in the current direct deleted, add means also remove it
# from the index and last commit
sub addToIndex {
    #get the folder name of current repository
    my (@files) = @_;
    $lastCommit = get_last_commit($current_branch);
    my @toAdd;
    my @toRemove;
    #make an .tmp folder to store the file in the .legit, as a index file
    mkdir "$repository/.tmp";
    for $file (@files) {
        if ($file =~ /^[a-zA-Z0-9.\-_]+$/) {
            # if the file exist, add it to waiting list to be added to index
            if (-e "$file") {
                push @toAdd, $file;
            } else {
                # check if the file is in index or last commit
                # if it doesn't exist in both which means this file is non-exist
                if (! -e "$repository/.tmp/$file" && ! -e "$repository/$current_branch/$lastCommit/$file") {
                    die "legit.pl: error: can not open '$file'\n";
                }

                # file has been deleted in current directory
                # also need to be removed from index and last commit directory
                push @toRemove, $file;
            }
        } else {
            die "legit.pl: error: invalid filename '$file'\n";
        }
    }

    # if there has something need to added to the index, create index directory
    for $file (@toAdd) {
        copy_file($file, "$repository/.tmp/$file");
    }
    legit_rm(@toRemove);
}

# create a new directory of snapshot to store the files
# and copy file from the index to the new snapshot
sub legitCommit {
    my ($snapshot) = @_;
    #create a new snapshot
    mkdir "$repository/$current_branch/$snapshot" or die "can not create $snapshot: $!\n";
    #add files from .tmp folder to the new created snapshot
    for $file (glob "$repository/.tmp/*") {
        $original = $file;
        $file =~ s/$repository\/.tmp\///g;
        copy_file($original, "$repository/$current_branch/$snapshot/$file");
    }
}

# print out the basic info of ./legit
sub usage {
    print <<eof;;
Usage: legit.pl <command> [<args>]

These are the legit commands:
   init       Create an empty legit repository
   add        Add file contents to the index
   commit     Record changes to the repository
   log        Show commit log
   show       Show file at particular state
   rm         Remove files from the current directory and from the index
   status     Show the status of files in the current directory, index, and repository
   branch     list, create or delete a branch
   checkout   Switch branches or restore current directory files
   merge      Join two development histories together
eof
}

