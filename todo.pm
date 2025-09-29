#!/usr/bin/perl

package todo;
use strict;
use warnings;

our @tasks;

sub is_leap_year {
    my ($year) = @_;
    return ($year % 4 == 0 && $year % 100 != 0) || ($year % 400 == 0);
}

sub days_in_month {
    my ($month, $year) = @_;
    my @days_in_month = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

    if ($month == 2) { 
        return is_leap_year($year) ? 29 : 28;
    }
    return $days_in_month[$month - 1];
}

sub is_date_valid {
    my ($date) = @_;
    my ($day, $month, $year) = (0, 0, 0);

    if($date =~ /^(\d{2})[-.](\d{2})[-.](\d{4})$/) {
        ($day, $month, $year) = ($1, $2, $3);

        if($month >= 1 && $month <= 12 && $day >= 1 && $day <= days_in_month($month, $year)) {
            return 1;
        }
    }
    return 0;
}

sub is_priority_valid {
    my ($priority) = @_;

    $priority = lc($priority); #tolower
    if($priority eq "low" || $priority eq "medium" || $priority eq "high") {
        return 1;
    }
    return 0;
}

sub load_tasks {
    my ($file_name) = @_;
    
    @tasks = ();
    open my $fh, '<', "$file_name" or die "Cannot open file $file_name";
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*$/;

        my @fields = split(';', $line); #id, task, priority, date, done
        $fields[2] = lc($fields[2]);
        push @tasks, \@fields;
    }
    close $fh;
}

sub save_tasks {
    my ($file_name) = @_;
    
    open my $fh, '>', $file_name or die "Cannot open file $file_name: $!";
    foreach my $row (@tasks) {
        print $fh join(";", @$row), "\n";
    }
    close $fh;
}

sub show_tasks {
    my ($file_name, $color) = @_;

    my $max_task_length = 50; # task column width

    my $format_high = "| \e[31m%-3s\e[0m | \e[31m%-${max_task_length}s\e[0m | \e[31m%-9s\e[0m | \e[31m%-10s\e[0m |\n"; #red
    my $format_mid = "| \e[34m%-3s\e[0m | \e[34m%-${max_task_length}s\e[0m | \e[34m%-9s\e[0m | \e[34m%-10s\e[0m |\n"; #blue
    my $format_low = "| \e[32m%-3s\e[0m | \e[32m%-${max_task_length}s\e[0m | \e[32m%-9s\e[0m | \e[32m%-10s\e[0m |\n"; #green
    my $format_no_color = "| %-3s | %-${max_task_length}s | %-9s | %-10s |\n"; #no color - for export
    
    print "-" x ($max_task_length + 2) . "-" x 33 . "\n";
    printf "| %-3s | %-${max_task_length}s | %-9s | %-10s |\n", "Id", "Task", "Priority", "Date";
    print "-" x ($max_task_length + 2) . "-" x 33 . "\n";

    load_tasks("$file_name");
    foreach my $row (@tasks) {
        my ($id, $task, $priority, $date, $done) = @$row;

        my $format;
        if($color == 0) {
            $format = $format_no_color;
        }
        elsif($priority eq 'low') {
            $format = $format_low;
        }
        elsif($priority eq 'medium') {
            $format = $format_mid;
        }
        elsif($priority eq 'high') {
            $format = $format_high;
        }

        my $is_first_line = 1;
        # split long task into smaller parts to display correctly on multiple lines
        while (length($task) > $max_task_length) {
            my $task_part = substr($task, 0, $max_task_length);
            $task = substr($task, $max_task_length);

            if ($is_first_line) {
                printf $format, $id, $task_part, $priority, $date;
                $is_first_line = 0;
            } else {
                printf $format, "", $task_part, "", "";
            }
        }

        # remaining part of the task
        if (length($task) > 0) {
            if ($is_first_line) {
                printf $format, $id, $task, $priority, $date;
                $is_first_line = 0;
            } else {
                printf $format, "", $task, "", "";
            }
        }
    }
    print "-" x ($max_task_length + 2) . "-" x 33 . "\n";
}

sub remove_task {
    my ($file_name, $remove_id) = @_;

    load_tasks($file_name);
    open my $fh, '>>', "${file_name}_copy" or die "Cannot open file: $!";
    foreach my $row (@tasks) {
        my ($id, $task, $priority, $date, $done) = @$row;
        if($remove_id != $id) {
            print $fh "$id;$task;$priority;$date;$done\n";
        }
    }

    close $fh;
}

sub add_task {
    my ($file_name, $task, $priority, $date) = @_;

    if(!is_priority_valid($priority)) {
        print "Priority must be one of: low, medium, high\n";
        return 1;
    }

    if(!is_date_valid($date)) {
        print "Date is invalid, it must be in format DD-MM-YYYY\n";
        return 1;
    }

    # find last id
    load_tasks($file_name);
    my $max_id = 0;
    foreach my $row (@tasks) {
        my ($id, $task, $priority, $date, $done) = @$row;
        if($id > $max_id) {
            $max_id = $id;
        }
    }
    $max_id++;

    open my $fh, '>>', $file_name or die "Cannot open file: $!";
    print $fh "\n$max_id;$task;$priority;$date;0";

    close $fh;
}

sub complete_task {
    my ($file_name, $complete_id) = @_;

    load_tasks($file_name);
    foreach my $row (@tasks) {
        my ($id, $task, $priority, $date, $done) = @$row;
        if($complete_id == $id) {
            $row->[4] = 1; # reference to 'done' column
        }
    }
    save_tasks($file_name);
}

1;
