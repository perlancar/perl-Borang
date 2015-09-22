#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Borang::HTML qw(gen_html_form);

my $res = gen_html_form(
    meta => {
        v => 1.1,
        args => {

            # without caption or summary, argument name will be used as form
            # field caption
            num1 => {
                schema => 'int',
                pos => 0,
            },

            # field length can be guessed from schema (max, min, xmax, xmin,
            # between, xbetween, or default value)
            num2 => {
                schema => ['float', max=>-1e10],
                pos => 1,
            },

            # without caption, summary will be used as form field caption
            text1 => {
                summary => 'A text field',
                pos => 2,
            },

            # field length can be guessed from schema (max_len, min_len,
            # len_between, or default value)
            text2 => {
                summary => 'A longer text field (hint from schema)',
                caption => 'A longer text field',
                schema  => ['str*', max_len=>100],
                pos => 3,
            },

            password1 => {
                summary => 'A password field',
                # even though we don't specify explicitly, borang can guess by
                # looking at the argument name
                #is_password => 1,
                schema => 'str*',
                pos => 4,
            },
        },
    },
);

print $res;
