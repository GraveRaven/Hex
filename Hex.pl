#!/usr/bin/perl
use warnings;
use strict;
use IO::Socket;
use LWP::UserAgent;
use DBI;
use v5.14;
use HTML::Entities;

#my packages
require RPS;
require commands;
require linkparsing;

my $server = "irc.server.com";
my @channels = $#ARGV < 0 ? "#default" : "#" . $ARGV[0];
my $bot_nick = $#ARGV < 1 ? "Hex" : $ARGV[1];
my $admin_mask = "";
my $admin_nick = "default";
my $admin_password = "password";
my $RPS_channel = "#default";
our %last_seen = ();

#ALLOW
our $allow_youtube = 1;
our $allow_spotify = 1;
our $allow_news = 1;

#useragent
our $ua = LWP::UserAgent->new;
$ua->agent("Mozilla/5.0");

#mysql variables
our $sql_database = "Hex";
our $sql_host = "localhost";
our $sql_user = "default";
our $sql_passwd = "password";
our $dbh;

print "Joining $server\n";

my $sock = new IO::Socket::INET::(PeerAddr => $server, PeerPort => 6667, Proto => 'tcp')
    or die "Unable to connect to $server\n";

print $sock "NICK $bot_nick\r\n";
print $sock "USER $bot_nick $server * :$bot_nick\r\n";

while(my $input = <$sock>){
   if($input =~ /004/){
    last;
    }
    elsif($input =~ /433/){
    die "Nickname already in use\n";
    }
}

print $sock "JOIN $channels[0]\r\n";

sub sqlconnect{
    return DBI->connect("dbi:mysql:database=$sql_database;host=$sql_host", $sql_user, $sql_passwd);
}

$dbh = sqlconnect();

while(my $input = <$sock>){
    chop $input; #remove \n
    chop $input; #remove \r
    
    $input =~ s/\s+$//; #remove trailing spaces

    print "$input\n"; #debug output
    
    (my $in_mask, my $in_type, my $in_channel, my $in_text) = split(/ /, $input, 4);
    
    # If its a ping send a pong
    if($in_mask eq "PING"){
    print $sock "PONG $in_type\r\n";
    }
    elsif($in_type eq "JOIN" || $in_type eq "PART" || $in_type eq "QUIT"){
        update_last_seen($in_mask, $in_type);
    }
    elsif($in_type eq "PRIVMSG"){
    
    # Parse out the command and remove the ":"
    (my $command, my $arguments) = split(/ /, $in_text, 2);
    $command = substr $command, 1;

    # Find the nick
    $in_mask =~ /^\:(.*)\!/;
    my $in_nick = $1;

    # Private message to bot
    if($in_channel eq $bot_nick){
        priv_message($command, $arguments, $in_mask, $in_nick);
    }
    # Messages in channels
    else{
        channel_message($in_channel, $in_nick, $in_text);
    }# End of messages in channels
    }# End of "PRIVMSG"
}

sub priv_message{
    my $command = shift;
    my $arguments = shift;
    my $in_mask = shift;
    my $in_nick = shift;

    if($in_mask eq $admin_mask){ # If admin tells me
    if(priv_from_admin($command, $arguments) == 0){
        priv_from_other($command, $arguments, $in_mask, $in_nick);
    }
    
    }# End of messages from admin
    else{ # Other people tell me
    priv_from_other($command, $arguments, $in_mask, $in_nick);
    }# End of messages from other people
}

#returns 1 if something was done
sub priv_from_admin{
    my $command = shift;
    my $arguments = shift;

    if($command eq "!join"){
    
    my @tojoin = split(/ /, $arguments);

    foreach my $channel (@tojoin){
        my $exists = 0; 
        my $nrOfChannels = $#channels;

        for(my $i = 0; $exists == 0 && $i <= $nrOfChannels; $i++){
        
        if($channel eq $channels[$i]){
            $exists = 1;
        }
        }
        
        if($exists){
        print $sock "PRIVMSG $admin_nick :Already in $channel\r\n";
        }
        else{
        print $sock "JOIN $channel\r\n";
        push(@channels, $channel);
        }
    }
    }# End of !join
    elsif($command eq "!part"){
    
    my @topart = split(/ /, $arguments);

    foreach my $channel (@topart){
        my $found = 0;
        for(my $i = 0; $found == 0 && $i <= $#channels; $i++){

        if($channels[$i] eq $channel){
            print $sock "PART $channel\r\n";
            splice(@channels, $i, 1);
            $found = 1;
        }
        }
    }
    
    }# End of !part
    elsif($command eq "!where"){
    foreach(@channels){
        print $sock "PRIVMSG $admin_nick :$_\r\n";
    }
    }# End of !where
    elsif($command eq "!say"){
    (my $channel, my $text) = split(/ /, $arguments, 2); 
    print $sock "PRIVMSG $channel :$text\r\n";
    }# End of !say
    elsif($command eq "!allow"){
    if($arguments eq "spotify"){
        $allow_spotify = 1;
    }
    elsif($arguments eq "youtube"){
        $allow_youtube = 1;
    }
    elsif($arguments eq "new"){
        $allow_news = 1;
    }
    }# End of !allow
    elsif($command eq "!disallow"){
    if($arguments eq "spotify"){
        $allow_spotify = 0;
    }
    elsif($arguments eq "youtube"){
        $allow_youtube = 0;
    }
    elsif($arguments eq "new"){
        $allow_news = 0;
    }
    }# End of disallow
    elsif($command eq "!reload"){
    if($arguments eq "commands"){
        delete $INC{'commands.pm'};
        require commands;
    }
    elsif($arguments eq "links"){
        delete $INC{'linkparsing.pm'};
        require linkparsing;
    }
    }
    else{
    return 0;
    }

    return 1;
}

sub priv_from_other{
    my $command = shift;
    my $arguments = shift;
    my $in_mask = shift;
    my $in_nick = shift;

    if($command eq "!admin"){
    if($arguments eq $admin_password){
        $admin_nick = $in_nick;
        $admin_mask = $in_mask;
        print $sock "PRIVMSG $admin_nick :You are now admin\r\n";
    }
    else{
        print $sock "PRIVMSG $admin_nick :$in_nick tried to guess the admin password with $arguments\r\n";
    }
    }
    elsif(lc($command) eq "sten" || lc($command) eq "sax" || lc($command) eq "påse"){
    playRPS($command, $in_nick);
    }
    else{
    print $sock "PRIVMSG $admin_nick :$in_nick told me $command $arguments\r\n";
    }
}

sub channel_message{
    my $in_channel = shift;
    my $in_nick = shift;
    my $in_text = shift;

    if(substr($in_text, 1, 1) eq "!"){
    parse_command($sock, $in_channel, $in_nick, $in_text);
    }
    else{
    parse_links($sock, $in_channel, $in_text);
    }    
}    
sub playRPS{
    my $choice = shift;
    my $nick = shift;

    if($RPS::phase){
    if($RPS::player1_name eq $nick){
        print $sock "PRIVMSG $nick :Du kan inte spela mot dig själv\r\n";
    }
    else{
        $RPS::player2_name = $nick;
        $RPS::player2_choice = $choice;
        $RPS::phase = 0;
        my $winner = RPS::play();
        
         my $sth = $dbh->prepare("INSERT INTO rps VALUES (?, ?, ?, ?, ?, ?)");

        if($winner == 1){
        $sth->execute($RPS::player1_name, $RPS::player1_choice, $RPS::player2_name, $RPS::player2_choice, $RPS::player1_name, $RPS::player2_name);
        print $sock "PRIVMSG $RPS_channel :$RPS::player1_name vs $RPS::player2_name: $RPS::player1_choice vs $RPS::player2_choice. $RPS::player1_name vinner!\r\n";

        }
        elsif($winner == 2){
        $sth->execute($RPS::player1_name, $RPS::player1_choice, $RPS::player2_name, $RPS::player2_choice, $RPS::player2_name, $RPS::player1_name);
        print $sock "PRIVMSG $RPS_channel :$RPS::player1_name vs $RPS::player2_name: $RPS::player1_choice vs $RPS::player2_choice. $RPS::player2_name vinner!\r\n";
        } 
        else{
        $sth->execute($RPS::player1_name, $RPS::player1_choice, $RPS::player2_name, $RPS::player2_choice, "tie", "tie");
        print $sock "PRIVMSG $RPS_channel :$RPS::player1_name vs $RPS::player2_name: $choice vs $choice. Ingen vinner\r\n";
        }
    }

    }
    else{
    $RPS::player1_name = $nick;
    $RPS::player1_choice = $choice;
    $RPS::phase = 1;
    }
}

sub update_last_seen{
    my $mask = shift;
    my $type = shift;
    (my $nick, my $from) = $mask =~ /^:(.*?)!~([^ ]*)/;
    my $time = `date +"%T %b %d %Y"`;
    print "Adding $time $from $type\n";
    $last_seen{$nick} =  [$time  ,$from, $type];
}
