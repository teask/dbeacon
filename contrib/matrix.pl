#!/usr/bin/env perl

# matrix.pl - displays dbeacon dump information in a matrix et al.
#
# Originally by Hoerdt Micka�l
# Modifications by Hugo Santos

# change this filename to your dump file
my $dump_file = "/home/hugo/work/mcast/dbeacon/dump.xml";

# Program code follows

use CGI;

use Graph::Directed;
use XML::Parser;
use Switch;
use strict;

my $page = new CGI;

print $page->header;

my $attname = $page->param('att');
if (not $attname) {
	$attname = "ttl";
}

my $sessiongroup;
my $ssm_sessiongroup;

my $current_beacon;
my $current_source;
my %adjacency_matrix;
my $parser;
my $g;

$g = new Graph::Directed;
# initialize parser and read the file
$parser = new XML::Parser( Style => 'Tree' );
$parser->setHandlers(Start => \&start_handler);
my $tree = $parser->parsefile($dump_file);

my @V = $g->vertices();

print "<html>\n";

print "
<head>

<meta http-equiv=\"refresh\" content=\"60\" />

<style type=\"text/css\">
body {
	font-family: Verdana, Arial, Helvetica, sans-serif;
	font-size: 100%;
}

table#adj {
	text-align: center;
	border-spacing: 1px;
}
table#adj td.beacname {
	text-align: right;
}
table#adj td {
	padding: 2px;
}
table#adj td.adjacent {
	background-color: #96ef96;
	width: 16pt;
}
table#adj td.blackhole {
	background-color: #000000;
}
table#adj td.noinfo {
	background-color: #ff0000;
}
table#adj td.nossminfo {
	background-color: #b6ffb6;
	width: 16pt;
}
table#adj td.corner {
	background-color: #dddddd;
}

table#beacs td {
	padding: 5px;
}

table#beacs td.name {
	border-left: 2px solid black;
}

table#beacs td.name, table#beacs td.addr, table#beacs td.admincontact, table#beacs td.age {
	border-right: 2px solid black;
}

table#beacs td.addr, table#beacs td.admincontact {
	font-family: Monospace;
}

</style>
</head>
";

print "<body>\n";

print "<h1>IPv6 Multicast Beacon</h1>\n";

my $now = localtime();

print "<h4>Current Server time is $now</h4>\n";

print "<h4>Current stats for $sessiongroup";
if ($ssm_sessiongroup) {
	print " (SSM: $ssm_sessiongroup)";
}
print "</h4>\n";

switch ($attname)
{
  case "loss"	{ print "<h4>Current view is Loss in %</h4>\n" }
  case "delay"	{ print "<h4>Current view is Delay in ms</h4>\n" }
  case "jitter"	{ print "<h4>Current view is Jitter in ms</h4>\n" }
  else		{ $attname = "ttl"; print "<h4>Current view is TTL in number of hops</h4>\n" }
}

my $url = $page->script_name();

print "<p><b>Parameters:</b> [<a href=\"$url?att=ttl\">TTL</a>] [<a href=\"$url?att=loss\">Loss</a>] [<a href=\"$url?att=delay\">Delay</a>] [<a href=\"$url?att=jitter\">Jitter</a>]</p>\n";

print "<table border=\"0\" cellspacing=\"0\" cellpadding=\"0\" id=\"adj\">\n";

print "<tr>\n";
print "<td></td>";
my $c;
my $i = 1;
my @problematic = ();

foreach $c (@V) {
	if (scalar($g->edges($c)) ge 1) {
		print "<td colspan=\"2\">\n";
		print "<b>S$i</b>";
		print "</td>\n";
		$i++;
	} else {
		push(@problematic, $a);
	}
}
print "</tr>\n";

$i = 1;
foreach $a (@V) {
	if (scalar($g->edges($c)) ge 1) {
		print "<tr>";
		print "<td class=\"beacname\">";
		my $name = $g->get_vertex_attribute($a, "name");
		print "$name <b>R$i</b>";
		print "</td>";
		foreach $b (@V) {
			if ($g->has_edge($b, $a)) {
				my $txt;
				my $txtssm;
				my $tdclass = "adjacent";
				my $tdclasssm = "adjacent";
				$txt = $g->get_edge_attribute($b, $a, $attname);
				$txtssm = $g->get_edge_attribute($b, $a, "ssm_" . $attname);
				if (($txt eq "") and ($txtssm eq "")) {
					print "<td colspan=\"2\" class=\"noinfo\">N/A</td>";
				} else {
					if ($txt eq "") {
						$txt = "-";
						$tdclass = "nossminfo";
					} elsif ($txtssm eq "") {
						$txtssm = "-";
						$tdclasssm = "nossminfo";
					}
					print "<td class=\"$tdclass\">$txt</td><td class=\"$tdclasssm\" edge>$txtssm</td>";
				}
			} else {
				if ($a eq $b) {
					print "<td colspan=\"2\" class=\"corner\"></td>";
				} else {
					print "<td colspan=\"2\" class=\"blackhole\"></td>";
				}
			}
		}
		print "<tr>";
		print "\n";
		$i++;
	}
}
print "</table>";

if (scalar(@problematic) ne 0) {
	print "<br /><br />\n";
	print "<h3>Beacons with no connectivity</h3>\n";
	print "<ul>\n";
	my $len = scalar(@problematic);
	for (my $j = 0; $j < $len; $j++) {
		my $prob = $problematic[$j];
		print "<li>$prob</li>\n";
	}
	print "</ul>\n";
}

print "<br /><br />\n";
print "<table cellspacing=\"0\" cellpadding=\"0\" id=\"beacs\">";
print "<tr><th>Beacon Name</th><th>Source Address/Port</th><th>Admin Contact</th><th>Age</th></tr>\n";

foreach $a (@V) {
	my $name = $g->get_vertex_attribute($a, "name");
	my $addr = $g->get_vertex_attribute($a, "addr");
	my $contact = $g->get_vertex_attribute($a, "contact");
	my $age = $g->get_vertex_attribute($a, "age");
	if (not $age) {
		$age = "-";
	} else {
		$age = "$age secs";
	}
	print "<tr><td class=\"name\">$name</td><td class=\"addr\">$addr</td><td class=\"admincontact\">$contact</td><td class=\"age\">$age</td></tr>\n";
}

print "</table>";

print "<br /><br />";

print "<p>If you wish to add a beacon to your site, you may use dbeacon with the following parameters:</p>\n";
print "<p><code>./dbeacon -P -n NAME -b $sessiongroup";
if ($ssm_sessiongroup) {
	print " -S $ssm_sessiongroup";
}
print " -a CONTACT</code></p>\n";

print "</body>";
print "</html>";

sub start_handler {
	my ($p, $tag, %atts) = @_;
	my $name;
	my $value;

	if ($tag eq "beacon") {
		my $fname;
		my $fadmin;
		my $faddr;
		my $fage;
		while (($name, $value) = each %atts) {
			if ($name eq "name") {
				$fname = $value;
			} elsif ($name eq "contact") {
				$fadmin = $value;
			} elsif ($name eq "addr") {
				$faddr = $value;
			} elsif ($name eq "age") {
				$fage = $value;
			} elsif ($name eq "group") {
				$sessiongroup = $value;
			} elsif ($name eq "ssmgroup") {
				$ssm_sessiongroup = $value;
			}
		}

		$current_beacon = $faddr;

		if ($fname ne "") {
			$g->add_vertex($faddr);
			$g->set_vertex_attribute($faddr, "name", $fname);
			$g->set_vertex_attribute($faddr, "contact", $fadmin);
			$g->set_vertex_attribute($faddr, "addr", $faddr);
			$g->set_vertex_attribute($faddr, "age", $fage);
		}
	} elsif ($tag eq "ssm") {
		my $fttl = -1;
		my $floss = -1;
		my $fdelay = -1;
		my $fjitter = -1;
		while (($name, $value) = each %atts) {
			if ($name eq "ttl") {
				$fttl = $value;
			} elsif ($name eq "loss") {
				$floss = $value;
			} elsif ($name eq "delay") {
				$fdelay = $value;
			} elsif ($name eq "jitter") {
				$fjitter = $value;
			}
		}

		if ($current_source ne "") {
			if ($fttl ge 0) {
				$g->set_edge_attribute($current_source, $current_beacon, "ssm_ttl", $fttl);
			}
			if ($floss ge 0) {
				$g->set_edge_attribute($current_source, $current_beacon, "ssm_loss", $floss);
			}
			if ($fdelay ge 0) {
				$g->set_edge_attribute($current_source, $current_beacon, "ssm_delay", $fdelay);
			}
			if ($fjitter ge 0) {
				$g->set_edge_attribute($current_source, $current_beacon, "ssm_jitter", $fjitter);
			}
		}
	} elsif ($tag eq "source") {
		my $fname;
		my $fadmin;
		my $faddr;
		my $fttl = -1;
		my $floss = -1;
		my $fdelay = -1;
		my $fjitter = -1;
		while (($name, $value) = each %atts) {
			if ($name eq "name") {
				$fname = $value;
			} elsif ($name eq "contact") {
				$fadmin = $value;
			} elsif ($name eq "addr") {
				$faddr = $value;
			} elsif ($name eq "ttl") {
				$fttl = $value;
			} elsif ($name eq "loss") {
				$floss = $value;
			} elsif ($name eq "delay") {
				$fdelay = $value;
			} elsif ($name eq "jitter") {
				$fjitter = $value;
			}
		}

		if ($fname ne "") {
			$current_source = $faddr;
			$g->add_vertex($faddr);
			$g->set_vertex_attribute($faddr, "name", $fname);
			$g->set_vertex_attribute($faddr, "contact", $fadmin);
			$g->set_vertex_attribute($faddr, "addr", $faddr);

			$g->add_edge($faddr, $current_beacon);
			if ($fttl ge 0) {
				$g->set_edge_attribute($faddr, $current_beacon, "ttl", $fttl);
			}
			if ($floss ge 0) {
				$g->set_edge_attribute($faddr, $current_beacon, "loss", $floss);
			}
			if ($fdelay ge 0) {
				$g->set_edge_attribute($faddr, $current_beacon, "delay", $fdelay);
			}
			if ($fjitter ge 0) {
				$g->set_edge_attribute($faddr, $current_beacon, "jitter", $fjitter);
			}
		}
	}
}

