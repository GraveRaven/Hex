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
        $request->content =~ /<title>(.*) on Spotify/;
        my $song = decode_entities($1);
        print $sock "PRIVMSG $in_channel :[spotify] $song\r\n";
    }
    elsif($allow_spotify && $in_text =~ /spotify:track:/){
        $in_text =~ /spotify:track:(\S*)/;
        my $link = "http://open.spotify.com/track/" . $1;
        my $request = $ua->get($link);
        $request->content =~ /<title>(.*) on Spotify/;
        my $song = decode_entities($1);
        print $sock "PRIVMSG $in_channel :[spotify] $song\r\n";
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
        my $title = decode_entities($1);
        print $sock "PRIVMSG $in_channel :[imdb] $title\r\n";
    }
    elsif($in_text =~ /pastebin.com/){
        $in_text =~ /pastebin.com\/(\S*)/;
        print $1, "\n";
        my $request = $ua->get("http://pastebin.com/$1");
        $request->content =~ /<title>(\S*)/;
        print $sock "PRIVMSG $in_channel :$1\r\n";
    }
    elsif($in_text =~ /^:ducka!/){
        print $sock "PRIVMSG $in_channel :Anka?\r\n";
    }
    elsif($in_text =~ /^:anka?/){
        print $sock "PRIVMSG $in_channel :Ducka!\r\n";
    }
}

1;
