#!/usr/bin/perl

sub parse_links{
    $sock = shift;
    $in_channel = shift;
    $in_text = shift;

    if($allow_youtube && $in_text =~ /www.youtube.com\/watch\?/){
	$in_text =~ /v=(.{11})/;
	my $request = $ua->get("http://gdata.youtube.com/feeds/api/videos/$1");
	$request->content =~ /<media:title.*>(.*)<\/media:title>/;
	print $sock "PRIVMSG $in_channel :[youtube] $1\r\n";
    }
    elsif($allow_spotify && $in_text =~ /open\.spotify\.com\/track/){
	$in_text =~ /(http\S*)/;
	my $request = $ua->get("$1");
	$request->content =~ /og:title.*content="(.*)" \/>/;
	my $song = $1;
	$request->content =~ /\/artist\/.*>(.*)</;
	print $sock "PRIVMSG $in_channel :[spotify] $song by $1\r\n";
    }
    elsif($allow_spotify && $in_text =~ /spotify:track:/){
	$in_text =~ /spotify:track:(\S*)/;
	my $link = "http://open.spotify.com/track/" . $1;
	my $request = $ua->get($link);
	$request->content =~ /og:title.*content=(.*)\/>/;
	my $song = $1;
	$request->content =~ /\/artist\/.*>(.*)</;
	print $sock "PRIVMSG $in_channel :[spotify] $song by $1\r\n";
    }
    elsif($allow_news && $in_text =~ /aftonbladet\.se.*article.*\.ab/){
	$in_text =~ /(aftonbladet\.se.*\.ab)/;
	my $request = $ua->get("http://www.$1");
	$request->content =~ /<title>(.*?)\|.*<\/title>/;
	print $sock "PRIVMSG $in_channel :[aftonbladet] $1\r\n";
    }
    elsif($allow_news && $in_text =~ /expressen\.se/){	
	$in_text =~ /(expressen\.se.*)/;
	my $link = $1;
	if($link =~ /\s/){
	    $link =~ /(expressen\.se.*?)\s/;
	    $link = $1;
	}
	my $request = $ua->get("http://www.$link");
	$request->content =~ /<h1 class="rubrik.*>(.*)<\/h1>/;
	print $sock "PRIVMSG $in_channel :[expressen] $1\r\n";
    }
    elsif($in_text =~ /existenz.se\/out/){
	$in_text =~ /id=(\d*)/;
	my $request = $ua->get("http://existenz.se/out.php?id=$1");
	$request->content =~ /<title>(.*)@ Existenz.se/;
	print $sock "PRIVMSG $in_channel :[existenz.se] $1\r\n";
    }
    elsif($in_text =~ /imdb.com\/title\//){
	$in_text =~ /title\/(.{9})/;
	my $request = $ua->get("http://www.imdb.com/title/$1");
	$request->content =~ /<title>(.*)-/;
	my $title = $1;
	$title =~ s/\&ndash;/-/;
	$title =~ s/\&nbsp;/ /;
	$title =~ s/\&#xC5;/Å/;
	$title =~ s/\&#xC4;/Ä/;
	$title =~ s/\&#xD6;/Ö/;
	$title =~ s/\&#xE5;/å/;
	$title =~ s/\&#xE4;/ä/;
	$title =~ s/\&#xF6;/ö/;
	$title =~ s/\&#x26;/\&/;
	print $sock "PRIVMSG $in_channel :[imdb] $title\r\n";
    }
}

1;
