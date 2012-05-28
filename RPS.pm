#!/usr/bin/perl

use strict;
use warnings;


package RPS;

our $phase = 0;
our $player1_name = "";
our $player2_name = "";
our $player1_choice = "";
our $player2_choice = "";
our %wins = ();
our %losses = ();


#returns 0 if draws 1 if player 1 wins and 2 if player2 wins

sub play{

    if($player1_choice eq "sten"){
	if($player2_choice eq "sax"){
	    $wins{$player1_name}++;
	    $losses{$player2_name}++;
	    return 1;
	}
	elsif($player2_choice eq "påse"){
	    $wins{$player2_name}++;
	    $losses{$player1_name}++;
	    return 2;
	}
    }
    elsif($player1_choice eq "sax"){

	if($player2_choice eq "sten"){
	    $wins{$player2_name}++;
	    $losses{$player1_name}++;
	    return 2;
	}
	elsif($player2_choice eq "påse"){
	    $wins{$player1_name}++;
	    $losses{$player2_name}++;
	    return 1;
	}
    }
    elsif($player1_choice eq "påse"){

	if($player2_choice eq "sten"){
	    $wins{$player1_name}++;
	    $losses{$player2_name}++;
	    return 1;
	}
	elsif($player2_choice eq "sax"){
	    $wins{$player2_name}++;
	    $losses{$player1_name}++;
	    return 2;
	}
    }

    return 0;
}

sub wins{
    return $wins{$_[0]};
}

sub losses{
    return $losses{$_[0]};
}

1;
