#!/usr/bin/perl

use DBIx::JSON;

my $dsn = "dbname=fpa";
my $obj = DBIx::JSON->new($dsn, "mysql");
$obj->do_select("select * from customers;","id");
$obj->err && die $obj->errstr;
print $obj->get_json;

exit;
