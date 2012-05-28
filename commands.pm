#!/usr/bin/perl

sub parse_command{
    my $sock = shift;
    my $in_channel = shift;
    my $in_nick = shift;
    my $in_text = shift;

    # Parse out the command and remove the ":"
    (my $command, my $arguments) = split(/ /, $in_text, 2);
    $command = substr $command, 1;

    if($command eq "!score"){
	score($sock, $in_channel, $arguments);
    }# End of !score
    elsif($command eq "!whattowatch"){
	whattowatch($sock, $in_channel);
    }
    elsif($command eq "!allabarnen"){
	allabarnen($sock, $in_channel, $arguments);
    }
    elsif($command eq "!addbarnen"){
	addbarnen($sock, $in_nick, $arguments);
    }
    elsif($command eq "!excuse"){
	excuse($sock, $in_channel);
    }
    elsif($command eq "!hat"){
	hat($sock, $in_channel, $arguments);
    }
    elsif($command eq "!jaghatar"){
	jaghatar($sock, $in_nick, $arguments);
    }
    elsif($command eq "!whattoeat"){
	print $sock "PRIVMSG $in_channel :tomten i tomatsås\r\n";
    }
}

sub score{
    my $sock = shift;
    my $in_channel = shift;
    my $arguments = shift;

    if(!defined($arguments)){
	%points = ();

	my $sth = $dbh->prepare("SELECT winner, count(winner) FROM rps WHERE winner <> 'tie' GROUP BY winner ORDER BY count(winner)");
	$sth->execute;
	
	while(my @wins = $sth->fetchrow_array){
	    $points{$wins[0]} = $wins[1];
	}

	$sth = $dbh->prepare("SELECT looser, count(looser) FROM rps WHERE looser <> 'tie' GROUP BY looser ORDER BY count(looser)");
	$sth->execute;
	while(my @losses = $sth->fetchrow_array){
	    $points{$losses[0]}-= $losses[1];
	}
	

	my @nicks = sort {$points{$b} <=> $points{$a}} keys %points;
	foreach(@nicks){
	    print "$_ $points{$_}\n";
	}
	print $sock "PRIVMSG $in_channel :$nicks[0] leder med $points{$nicks[0]} poäng\r\n";
	print $sock "PRIVMSG $in_channel :$nicks[$#nicks] ligger sist med $points{$nicks[$#nicks]} poäng\r\n";

    }
    else{
	(my $nick1, my $nick2) = split(/ /, $arguments, 2);
	
	if(!defined($nick2)){
	    my $sth = $dbh->prepare("SELECT (SELECT count(*) FROM rps WHERE winner = ?) AS wins, (SELECT count(*) FROM rps WHERE looser = ?) AS loses");
	   
	    $sth->execute($nick1, $nick1);
	    @result = $sth->fetchrow_array;
	    print $sock "PRIVMSG $in_channel :$nick1 har vunnit $result[0] ggr och förlorat $result[1] ggr\r\n";
	}
	else{
	    my $sth = $dbh->prepare("SELECT COUNT(winner) from rps where winner = ? and looser = ?");
	    $sth->execute($nick1, $nick2);
	    my @result = $sth->fetchrow_array;
	    my $nick1_wins = $result[0];
	    #$sth = $dbh->prepare("SELECT count(winner) from rps where winner = ? and looser = ?");
	    $sth->execute($nick2, $nick1);
	    @result = $sth->fetchrow_array;
	    if($nick1_wins > $result[0]){
		print $sock "PRIVMSG $in_channel :$nick1 har vunnit över $nick2 $nick1_wins gånger men bara förlorat $result[0] gånger\r\n";
	    }
	    elsif($nick1_wins < $result[0]){
		print $sock "PRIVMSG $in_channel :$nick2 har vunnit över $nick1 $result[0] gånger men bara förlorat $nick1_wins gånger\r\n";
	    }
	    else{
		if($result[0] == 0){
		    print $sock "PRIVMSG $in_channel :$nick1 och $nick2 har aldrig vunnit mot varandra\r\n";
		}
		else{
		    print $sock "PRIVMSG $in_channel :$nick1 och $nick2 har båda vunnit $result[0] gånger mot varandra\r\n";
		}
	    }
	    
	}
    }
}

sub whattowatch{
    my $sock = shift;
    my $in_channel = shift;

    my $page = $ua->get('http://www.imdb.com/random/title');
    $page->content =~ /<title>(.*)-/;
    my $title = $1;
    #fix encoding
    $title =~ s/\&ndash;/-/;
    $title =~ s/\&nbsp;/ /;
    $title =~ s/\&#xC5;/Å/;
    $title =~ s/\&#xC4;/Ä/;
    $title =~ s/\&#xD6;/Ö/;
    $title =~ s/\&#xE5;/å/;
    $title =~ s/\&#xE4;/ä/;
    $title =~ s/\&#xF6;/ö/;
    $title =~ s/\&#x26;/\&/;
    print $sock "PRIVMSG $in_channel :$title\r\n";
}

sub allabarnen{
    my $sock = shift;
    my $in_channel = shift;
    my $arguments = shift;

    my $sth;
    if(defined $arguments){
	my ($p1, $p2) = split (/ /,$arguments, 2);
	if($p1 eq "av"){
	    $sth = $dbh->prepare('select nick, joke from allabarnen where nick = ? order by rand() limit 1;');
	    $sth->execute($p2);
	}
	else{
	    $sth = $dbh->prepare("select nick, joke from allabarnen where joke like ? order by rand() limit 1;");
	    $sth->execute("%" . $p1 . "%");
	}
    }
    else{
	$sth = $dbh->prepare("select nick, joke from allabarnen order by rand() limit 1;");
	
	if(!$sth->execute){
	    $dbh = sqlconnect();
	    sleep(5);
	    $sth = $dbh->prepare("select nick, joke from allabarnen order by rand() limit 1;");
	    $sth->execute;
	}
    }
    
    my @answer = $sth->fetchrow_array;
    if(defined $answer[0]){
	print $sock "PRIVMSG $in_channel :<$answer[0]> $answer[1]\r\n";
    }
}
sub addbarnen{
    my $sock = shift;
    my $in_nick = shift;
    my $joke = shift;

    my $sth = $dbh->prepare("insert into allabarnen (nick,joke) values (?,?);");
    if(!$sth->execute($in_nick,$joke)){
	sqlconnect();
	sleep(5);
	$sth = $dbh->prepare("insert into allabarnen (nick,joke) values (?,?);");
	$sth->execute($in_nick,$joke);
    }
}

sub excuse{
    my $sock = shift;
    my $in_channel = shift;

    my $sth = $dbh->prepare("select excuse from excuses order by rand() limit 1;");

    if(!$sth->execute){
        $dbh = sqlconnect();
        sleep(5);
	$sth = $dbh->prepare("select excuse from excuses order by rand() limit 1;");
	$sth->execute;
    }
    
    my @answer = $sth->fetchrow_array;
    print $sock "PRIVMSG $in_channel :$answer[0]\r\n";
}
sub hat{
    my $sock = shift;
    my $in_channel = shift;
    my $arguments = shift;
    
    my $sth;
    if(defined $arguments){
	$sth = $dbh->prepare("select nick, hat from hate where nick = ? order by rand() limit 1;");
	if(!$sth->execute($arguments)){
            $dbh = sqlconnect();
            sleep(5);
        }
	$sth = $dbh->prepare("select nick, hat from hate where nick = ? order by rand() limit 1;");
	$sth->execute($arguments);
    }
    else{
	$sth = $dbh->prepare("select nick, hat from hate order by rand() limit 1;");
	
	if(!$sth->execute){
	    $dbh = sqlconnect();
	    sleep(5);
	    $sth = $dbh->prepare("select nick, hat from hate order by rand() limit 1;");
	    $sth->execute;
	}
	
    }
    my @answer = $sth->fetchrow_array;
    print $sock "PRIVMSG $in_channel :$answer[0] hatar $answer[1]\r\n";
}

sub jaghatar{
    my $sock = shift;
    my $in_nick = shift;
    my $arguments = shift;

    my $sth = $dbh->prepare("insert into hate (nick, hat) values (?,?);");

    if(!$sth->execute($in_nick, $arguments)){
	print "reconnect\n";
	$dbh = sqlconnect();
	sleep(5);
	$sth = $dbh->prepare("insert into hate (nick, hat) values (?,?);");
	$sth->execute($in_nick, $arguments)
    }

}

1;
