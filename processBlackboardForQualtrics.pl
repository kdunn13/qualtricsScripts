#Kevin Dunn
#1/22/2016
#This program recieves information from blackboard in the form of a csv and outputs a csv formatted for qualtrics


#This variable can be adjusted if the teamsize should be bigger than 7
$maxTeamSize = 7;


if(@ARGV < 1) {
	print ("usage: perl processBlackboardForQualtrics inputFile OutputFile \n");
	print "No input file given, exiting\n";
	exit();
}

if(@ARGV < 2) {
	print ("usage: perl processBlackboardForQualtrics inputFile OutputFile \n");
	print "No output file given, exiting\n";
	exit();
}

if(@ARGV > 2) {
	print ("usage: perl processBlackboardForQualtrics inputFile OutputFile \n");
	print "Too many files given, exiting\n";
	exit();
}

#open first file given for input
open(INPUT, $ARGV[0]) or die "Cannot open $ARGV[0] : $!";
#Open second file given for outputing
open(OUTPUT, ">", $ARGV[1]) or die "Cannot open $ARGV[1] : $!";
open(INSTRUCTOR, "instructor.info.csv");
open(EXCLUDE, "students.to.exclude.csv");

print OUTPUT ("index,LastName,FirstName,netid,email,team,number,points,peer1,peer2,peer3,peer4,peer5,peer6,peer7,netid1,netid2,netid3,netid4,netid5,netid6,netid7\n");

@excludedStudents;
foreach $line (<EXCLUDE>) {
	@excludedStudent = split(/,/, $line);
	$email = $excludedStudent[2];
	$index = index($email, '@');
	$netid = substr($email, 0, $index);
	push(@excludedStudents, ($netid));
}

$numberOfInstructors = 0;
@InstructorInfo;
foreach $line (<INSTRUCTOR>) {
	push(@InstructorInfo, ($line));
	$numberOfInstructors += 1;
}

$Couter = 0;
#for($teamIndex = 0; $teamIndex < @listOfTeams; $teamIndex++) {
for($i = 0; $i < @InstructorInfo; $i++) {
	$line = @InstructorInfo[$i];
	$Counter += 1;
	@instructor = split(/,/, $line);
	$lastName = $instructor[0];
	$firstName = $instructor[1];
	$email = $instructor[2];
#remove the \n from the email
	$email = substr($email, 0, -1); 

	$index = index($email, '@');
	$netid = substr($email, 0, $index);
	print OUTPUT "Instructor_Team", $Counter . "," . $lastName . "," . $firstName  . "," . $netid . "," . $email . "," . "InstuctorTeam" . "," . $Counter . "," . ($numberOfInstructors * 10 - 10);

	for($j = 0; $j < @InstructorInfo; $j++) {
		if($i == $j) {
			print OUTPUT ",";
			next;
		}
		@teamMate = split(/,/, $InstructorInfo[$j]);
		$lastName = $teamMate[0];
		$firstName = $teamMate[1];
		print OUTPUT "," . $lastName . " " . $firstName; 
	}

	for($j = @InstructorInfo; $j < $maxTeamSize; $j++) {
		print OUTPUT (",");
	}

	for($j = 0; $j < @InstructorInfo; $j++) {
		if($i == $j) {
			print OUTPUT ",";
			next;
		}
		@teamMate = split(/,/, $InstructorInfo[$j]);
		$email = $teamMate[2];
#remove the \n from the email
		$email = substr($email, 0, -1); 

		$index = index($email, '@');
		$netid = substr($email, 0, $index);
		print OUTPUT "," . $netid; 
	}

	for($j = @InstructorInfo; $j < $maxTeamSize; $j++) {
		print OUTPUT (",");
	}

	print OUTPUT "\n";
}

$count = 0;
$index = "";
@listOfTeams;
@listOfInput;
$minimumNumberOfFields = -1;

foreach $line (<INPUT>) {
	push(@listOfInput, ($line));
	@student = split(/,/, $line);
	if($minimumNumberOfFields eq -1 or @student < $minimumNumberOfFields) {
		$minimumNumberOfFields = @student;
	}
}

foreach $line (@listOfInput) {
	$count += 1;
	if($count == 1) {
		next;
	};

	#Remove any quotes from input
	$line =~ s/"//g;
	@team = ();
	@student = split(/,/, $line);

	$lastName = $student[0];
	$firstName = $student[1];
	$userName = $student[2];
	$studentID = $student[3];
	$section = $student[6];
	$teamNo = $student[7];
	#These 4 lines handle the case where a team name has a comma in it. It Removes the commas and the quotes
	for($i = 8; $i < (@student - $minimumNumberOfFields) + 8; $i++) {
		$teamNo = $teamNo . $student[$i];
	}

	
	#skip students that are on the excluded list
	if( (grep {$_ eq $userName} @excludedStudents) eq 1) {
		next;
	}

	$email = $userName . "\@utk.edu";
	$points = 0;

#remove the \n from the team
	if(substr($teamNo, -1) eq "\n") {
		$teamNo = substr($teamNo, 0, -1); 
	}

	$index = $teamNo;

	#A team can be uniquely identified by concatinating their teamNo and section id
	$TeamID = $teamNo . $section;

	@teamMember = ($TeamID, $lastName, $firstName, $userName, $email, $teamNo, $memberNo, $points);


	$TeamIndex = -1;
	for($i = 0; $i < @listOfTeams; $i++) {
		if($listOfTeams[$i][0][0] eq $TeamID) {
			$TeamIndex = $i;	
			last;
		}
	}

	#Adding a new teram
	if($TeamIndex == -1) {
		push @team, [@teamMember];
		push @listOfTeams, [@team];
	}
	#Appending the teammate to the old team
	else {
		$team = \@listOfTeams[$TeamIndex];
		push $ { $team }, [@teamMember];
	}

};


#print the team member information
for($teamIndex = 0; $teamIndex < @listOfTeams; $teamIndex++) {
	$teamSize = scalar @{ $listOfTeams[$teamIndex] };
	for($teamMemberIndex = 0; $teamMemberIndex < $teamSize; $teamMemberIndex++) {
		$length = scalar @{ $listOfTeams[$teamIndex][$teamMemberIndex] };
		#Set index
		$listOfTeams[$teamIndex][$teamMemberIndex][0] = $listOfTeams[$teamIndex][$teamMemberIndex][5] . ($teamMemberIndex + 1);
		#set team member number
		$listOfTeams[$teamIndex][$teamMemberIndex][6] = ($teamMemberIndex + 1);
		#set Poitns
		$listOfTeams[$teamIndex][$teamMemberIndex][7] = $teamSize * 10 - 10;
	
		for($attributeIndex = 0; $attributeIndex < $length; $attributeIndex++) {
			print OUTPUT ($listOfTeams[$teamIndex][$teamMemberIndex][$attributeIndex] . ",");
		}

		#Print teamMates names
		for($teamMate = 0; $teamMate < $teamSize; $teamMate++) {
			#Don't print the person's own name
			if($teamMate eq $teamMemberIndex) {
				print OUTPUT (",");
			}
			else {
				#print first name
				print OUTPUT ($listOfTeams[$teamIndex][$teamMate][2] . " ");
				#print last name
				print OUTPUT ($listOfTeams[$teamIndex][$teamMate][1] . ",");
			}
		}
		#Print commas for teammates that don't exist
		for($i = $teamSize; $i < $maxTeamSize; $i++) {
			print OUTPUT (",");
		}

		#print teamMates netIDs
		for($teamMate = 0; $teamMate < $teamSize; $teamMate++) {
			#Don't print the person's own netID
			if($teamMate eq $teamMemberIndex) {
				print OUTPUT (",");
			}
			else {
				print OUTPUT ($listOfTeams[$teamIndex][$teamMate][3] . ",");
			}
		}
		#Print commas for teammates that don't exist
		for($i = $teamSize + 1; $i < $maxTeamSize; $i++) {
			print OUTPUT (",");
		}
		print OUTPUT ("\n");
	}
};

close $INPUT;
close $OUTPUT;
close $EXCLUDE;
close $INSTRUCTOR;
