use strict;
use warnings;

use inc::Module::Install;

all_from        'lib/Regexp/RegGrp.pm';
test_requires   'Test::More' => 0;

repository 'http://github.com/nevesenin/regexp-reggrp-perl';
bugtracker 'http://github.com/nevesenin/regexp-reggrp-perl/issues';

WriteAll();
