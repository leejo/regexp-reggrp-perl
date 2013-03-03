#!/usr/bin/env perl

use strict;
use warnings;

use lib "lib";

use Test::Class::Load "t/lib";

Test::Class->runtests( @ARGV );
