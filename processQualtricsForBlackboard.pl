# Kevin Dunn
# 1/15/2015
# This program takes a csv file representing the results from a qualtrlics survey and formats it for input for blackboard


sub fisher_yates_shuffle {
    my $array = shift;
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    }
}



if(@ARGV < 1) {
	print ("usage: perl processQualtricsForBlackBoard inputFile OutputFile \n");
	print ("No input file given, exiting\n");
	exit();
}


if(@ARGV < 2) {
	print ("usage: perl processQualtricsForBlackBoard inputFile OutputFile \n");
	print ("No output file given, exiting\n");
	exit();
}

if(@ARGV > 2) {
	print ("usage: perl processQualtricsForBlackBoard inputFile OutputFile \n");
	print "Too many files given, exiting\n";
	exit();
}

#open first file given for input
open(INPUT, $ARGV[0]) or die "Cannot open $ARGV[0] : $!";
#Open second file given for outputing
open(OUTPUT, ">", $ARGV[1]) or die "Cannot open $ARGV[1] : $!";

print ("Please input the name of the assignment column\n");
$Assignment = <STDIN>;
#Remove the \n from Assignment
if(substr($Assignment, -1) eq "\n") {
	$Assignment = substr($Assignment, 0, -1);
}

#Remove any commas from Assignment
$Assignment =~ s/,//g;


$count = 0;
@evaluation;
$inQuotes = 0;
#A hash table of arrays composed of scores and reviews keyed on studentid
%Reviews;
#A list of all the students who has completed their survey
@HasCompletedReview;
#A hash table of arrays composed of the first and last names, keyed on student ids
%StudentIDsToNames;
print OUTPUT ("Last Name,First Name,Username,$Assignment,Grading Notes,Notes Format,Feedback to User,Feedback Format\n");

foreach $line (<INPUT>) {
	$count += 1;

	#Skip the second line of input, since it's just instructions for the students
	if($count == 2) {
		next;
	}
	
	#If a line begins with '#' that line should be skipped since it was an incorrect review
	if(substr($line, 0, 1) eq "#") {
		next;
	}
	
	@evaltemp = split(/,/, $line);
	$value = "";
	@Student = ();

	for $item (@evaltemp) {

#If an evalution begins with a quote, that means there's at least 1 comma or quote inside the evaluation that should be taken literally
		if(substr($item, 0, 1) eq "\"") {
			$inQuotes = 1;
		}
#if the last character in the evaluation is a quote, that end the characters that should be taken literally
#technically this should check that the item ends in an odd number of quotes. Unless there is no content other than quotes in the survey, in which case the quotes should be even.
		if((substr($item, -1, 1) eq "\"" and substr($item, -2, 2) ne "\"\"") or substr($item, -3, 3) eq "\"\"\"") {
			$inQuotes = 0;
		}

		if($inQuotes eq 1) {
			$value = $value . $item . ",";
		}
		else {
			$value = $value . $item;
#Remove the starting and ending quotes if they exist
			if(substr($value, 0, 1) eq "\"" and substr($value, -1, 1) eq "\""){
				$value = substr($value, 1);
				$value = substr($value, 0, -1);
			}
			if($count == 1) {
				push (@InputFormat, $value);
			}
			else {
				push (@Student, $value);
			}
			$value = "";
		}
	}
	

#Because the output is in the form: Reviewie, score, commments this grabs the information about the person being reviewed and puts it in a hash table of arrays for later


	@StudentIDs = ();

	
#Create an array containing the netIDs of the people being reviewed
	for ($j = 0; $j < 8; $j++) {
		for ($i = 0; $i < @InputFormat; $i++) {
			$valueContainsNetID = index($InputFormat[$i], "netid$j");
			if($valueContainsNetID != -1) {
				push (@StudentIDs, @Student[$i]);
			}
			break;
		}
	}


	$StudentName = @Student[2];
	@StudentFullName = split(/,/, $StudentName);
#Remove the leading space from the full name
	%StudentIDsToNames;
	$StudentFullName[1] = substr($StudentFullName[1], 1);

#Add input to the hash table called reviews. It will be keyed on netIds and will contain scores and comments
	for ($j = 1; $j < 8; $j++) {
		for ($i = 0; $i < @InputFormat; $i++) {
#			print "$i $InputFormat[$i]\n";

			#Find the score and comment for a student
			$valueContainsOnline = index($InputFormat[$i], "Online_$j");
			if($valueContainsOnline != -1) {
				$Score = @Student[$i];
			}
			$valueContainsO_Peer = index($InputFormat[$i], "O_peer$j");
			if($valueContainsO_Peer != -1) {
				$Comment = @Student[$i];
			}
			if($InputFormat[$i] eq "peer$j") {
				$studentName = @Student[$i];
			}
			if($InputFormat[$i] eq "netid$j") {
				$studentID = @Student[$i];
			}
		}
		if($studentID ne "") {
			push @{ $StudentIDsToNames{$studentID} }, $studentName;
		}
		#Add the score and comment to the hash table
		for ($i = 0; $i < @StudentIDs; $i++) {
			if($i == $j - 1 and $StudentIDs[$i] ne "") {
				push @{ $Reviews{$StudentIDs[$i]} }, $Score, $Comment;
			}
		}
	}

	for ($i = 0; $i < @InputFormat; $i++) {
		if($InputFormat[$i] eq "netid") {
			$StudentID = $Student[$i];
		}
	}
	

	#For the final output, we need a way to connect the students NetID to their name. So this adds the students name to a hash table keyed on netid
#	push @{ $StudentIDsToNames{$StudentID} }, $StudentFullName[0], $StudentFullName[1];
#	push @{ $StudentIDsToNames{$Student[21]} }, $StudentFullName[0], $StudentFullName[1];
	push (@HasCompletedSurvey, $StudentID);
};

for $StudentID (sort keys %Reviews) {
	@Scores = ();
	$TotalPoints = 0;
	$TotalReviews = 0;
	foreach (@{$Reviews{$StudentID}} ) {
		push (@Scores, $_);
	}
	$counter = 0;

	foreach $score (@Scores) {
		if($counter % 2 == 0) {
			$TotalPoints += $score;
			$TotalReviews += 1;
		}
		$counter += 1;
	}

#Calculate the final score and round to 6 decimal places.
	$GroupAverage = 0;
	$FinalScore = $TotalPoints / $TotalReviews / 10.0;

#The group average is rounded to 2 decimal places
	$GroupAverage = sprintf("%.3f", $FinalScore);

#Perl Rounds a number to the nearest even interager when the number ends in 5. So I manually make sure it rounds up when the last number is 5
	if(substr($GroupAverage, -1, 1) eq "5") {
		substr($GroupAverage, -1, 1) = "6";
	}
	$GroupAverage = sprintf("%.2f", $GroupAverage);

#When Excel prints a number less than 0, it doesn't include a 0 before the . So this removes the 0
	$FirstChar = substr($GroupAverage, 0, 1);
	if($FirstChar eq "0") {
		$GroupAverage = substr($GroupAverage, 1);
	}

	$FinalScore = sprintf("%.6f", $FinalScore);
#This gets rid of the trailing 0s that shouldn't be output
	$FinalScore += 0;

#If the student didn't complete their survey, the final score is set to 0
	if( (grep {$_ eq $StudentID} @HasCompletedSurvey) ne 1) {
		$FinalScore = 0;
	}

#If a review has a quote in it, then that means the entire html tag needs to be quoted
	$ReviewContainsQuote = -1;
	$counter = 0;
	$NumberOfCommasInReviews = 0;
	foreach $Review (@Scores) {
#Even numbers in the array are scores, and the odds numbers are the reviews
		if($counter % 2 == 1 and $ReviewContainsQuote ne 1) {
			$ReviewContainsQuote = index($Review, "\"");
			if($ReviewContainsQuote ne -1) {
				$ReviewContainsQuote = 1;
			}
		}
		if($counter % 2 == 1) {
			$NumberOfCommasInReviews += () = $Review =~ /\,/g;
		}
		$counter += 1;
	}

	$name = $StudentIDsToNames{$StudentID}[0];
	@fullName = split(/ /, $name);
	#print ("ID = $StudentID Last name = $temp[0][0] First name = $temp[0][1] \n");
	print OUTPUT ("$fullName[1],$fullName[0],");
	if($ReviewContainsQuote eq 1) {
		print OUTPUT ("$StudentID,$FinalScore,,,\"<html><b><u>Peer Score=</u></b> ");
	}
	else {
		print OUTPUT ("$StudentID,$FinalScore,,,<html><b><u>Peer Score=</u></b> ");
	}

#If the number is less than 1, qualtics adds an extra space
	if($FirstChar eq "0") {
		print OUTPUT (" ");
	}

	print OUTPUT ("$GroupAverage   ");
	$counter = 0;

	@Reviews = ();
	#Output each review preceded by a </br>
	foreach $Review (@Scores) {
		$Review =~ s/\s+$//;
		if($counter % 2 == 1) {
			push (@Reviews, $Review);
		}
		$counter += 1;
	}
	
	fisher_yates_shuffle(\@Reviews);
	
	foreach $Review (@Reviews) {
		print OUTPUT ("</br>$Review");
	}

	#For every review, the is a </br> that ends the output.
	print OUTPUT ("</br>");

	if( (grep {$_ eq $StudentID} @HasCompletedSurvey) ne 1) {
		print OUTPUT ("<b>**DID NOT SUBMIT RATINGS FOR OTHER TEAM MEMBERS. STUDENT RECEVING 0 CREDIT**</b>");
	}
	if($ReviewContainsQuote eq 1) {
		print OUTPUT ("</html>\"");
	}
	else {
		print OUTPUT ("</html>");
	}

	print OUTPUT ("\n");

}


close $INPUT;
close $OUTPUT;
