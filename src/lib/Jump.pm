package Jump;
use Dancer2;
use LWP::Protocol::socks;
use LWP::UserAgent;
use Data::Dumper;
use Encode;
use Net::Ping;
use IO::Socket::IP;

our $VERSION = '0.1';

my $ua_onion = new LWP::UserAgent(agent => 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.5) Gecko/20060719 Firefox/1.5.0.5');
my $ua_i2p = $ua_onion->clone();
$ua_onion->proxy([qw(http https)] => 'socks://localhost:9050');
$ua_i2p->proxy([qw(http)] => 'http://localhost:4444');
$ua_i2p->proxy([qw(https)] => 'http://localhost:4445');

sub jump {
    my $addr = body_parameters->get('addr');
    my $type = body_parameters->get('type');
    print Dumper($type);
    if ($type =~ /onion/) {
        $addr =~ s/http:\/\///g;
        $addr =~ s/.onion//g;
        redirect '/onion/' . $addr;
    } else {
        $addr =~ s/http:\/\///g;
        $addr =~ s/.i2p//g;
        redirect '/i2p/' . $addr;
    }
}

# some search and replaces to make relative links work
sub sr {
    my ($res, $addr) = @_;
    $res =~ s/.onion//g;
    $res =~ s/href="\//href="\/onion\/$addr\//g;
    $res =~ s/href="http:\/\//href="\/onion\//g;
    $res =~ s/src="\//src="\/onion\/$addr\//g;
    return $res;
}

sub sr_i2p {
    my ($res, $addr) = @_;
    $res =~ s/.i2p//g;
    $res =~ s/href="\//href="\/i2p\/$addr\//g;
    $res =~ s/href="http:\/\//href="\/i2p\//g;
    $res =~ s/src="\//src="\/i2p\/$addr\//g;
    return $res;
}

# handler for the root of the website (single html page)
sub first_level {
    my $addr = route_parameters->get('addr');
    my $address = "http://" . $addr . ".onion";
    my $response = $ua_onion->get($address);
    my $res = $response->content;
    $res = decode_utf8($response->content);
    $res = sr($res, $addr);
    return $res;
}

sub first_level_i2p {
    my $addr = route_parameters->get('addr');
    my $address = "http://" . $addr . ".i2p";
    my $response = $ua_i2p->get($address);
    my $res = $response->content;
    $res = decode_utf8($response->content);
    $res = sr_i2p($res, $addr);
    return $res;
}

# handler for additional resources
sub full_path {
    my ($path_) = splat;
    my @path_ = @{$path_};
    my $path = join('/', @path_);
    my $addr = route_parameters->get('addr');
    my $fullpath = "http://" . $addr . ".onion" . "/" . $path;
    my $response = $ua_onion->get($fullpath);
    my $res = $response->content;
    if ($response->content_type =~ /^text\/html/) {
        $res = decode_utf8($res);
        $res = sr($res, $addr);
        return $res;
    } elsif ($response->content_type =~ /^text\/css/) {
        $res =~ s/url\(\//url\(\/onion\/$addr\//g;
        send_file(\$res, content_type => 'text/css');
    } else {
        send_file(\$res, content_type => $response->content_type);
    }
}

sub full_path_i2p {
    my ($path_) = splat;
    my @path_ = @{$path_};
    my $path = join('/', @path_);
    my $addr = route_parameters->get('addr');
    my $fullpath = "http://" . $addr . ".i2p" . "/" . $path;
    my $response = $ua_i2p->get($fullpath);
    my $res = $response->content;
    if ($response->content_type =~ /^text\/html/) {
        $res = decode_utf8($res);
        $res = sr_i2p($res, $addr);
        return $res;
    } elsif ($response->content_type =~ /^text\/css/) {
        $res =~ s/url\(\//url\(\/i2p\/$addr\//g;
        send_file(\$res, content_type => 'text/css');
    } else {
        send_file(\$res, content_type => $response->content_type);
    }
}

get '/' => sub {
    my $onion_router = 'dead';
    my $i2p_router = 'dead';
    
    # check port availability to find out if corresponding service is running
    my $socket = IO::Socket::IP->new(PeerAddr => 'localhost', PeerPort => 9050);
    if ($socket) {
        $onion_router = 'alive';
        $socket->close();
    }
    
    $socket = IO::Socket::IP->new(PeerAddr => 'localhost', PeerPort => 4444);
    if ($socket) {
        $i2p_router = 'alive';
        $socket->close();
    }
    
    template 'front' => { 
        'title' => 'Jump',
        'onion_router' => $onion_router,
        'i2p_router' => $i2p_router
    };
};

get '/onion/:addr' => sub { first_level() };
get '/onion/:addr/' => sub { first_level() };

get '/onion/:addr/**' => sub { full_path() };
get '/onion/:addr/**/' => sub { full_path() };

get '/i2p/:addr' => sub { first_level_i2p() };
get '/i2p/:addr/' => sub { first_level_i2p() };

get '/i2p/:addr/**' => sub { full_path_i2p() };
get '/i2p/:addr/**/' => sub { full_path_i2p() };

post '/jump' => sub { jump() };

true;
