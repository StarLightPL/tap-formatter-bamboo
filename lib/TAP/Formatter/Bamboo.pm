package TAP::Formatter::Bamboo;

use Moose;
use MooseX::NonMoose;
use XML::LibXML;
use Encode qw(:all);
use Data::Dumper;

use TAP::Formatter::Bamboo::Session;

extends qw(
    TAP::Formatter::Console
);

our $VERSION = '0.01';

has _test_results => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

sub open_test {
    my ($self, $test, $parser) = @_;
    my $session = TAP::Formatter::Bamboo::Session->new( {
        name            => $test,
        formatter       => $self,
        parser          => $parser,
    } );
    return $session;
}

sub summary {
    my ($self, $aggregate) = @_;

    $self->_save_results('results.xml');

    return if $self->silent();

    print { $self->stdout } "ALL DONE\n";
}

sub _save_results {
    my( $self, $file_path ) = @_;

    my $doc = XML::LibXML::Document->createDocument('1.0', 'UTF-8');
    $doc->setStandalone( 1 );
    my $suites = $doc->createElement( 'testsuites' );

    for my $test ( @{$self->_test_results} ) {

        my $suite = $doc->createElement( 'testsuite' );
        $suite->setAttribute( 'name', $test->{description} );
        $suite->setAttribute( 'errors', $test->{parse_errors} );
        $suite->setAttribute( 'failures', $test->{failed} );
        $suite->setAttribute( 'tests', $test->{tests_run} );

        my $output = $doc->createElement( 'system-out' );
        $suite->appendChild( $output );

        my $testcase = $doc->createElement( 'testcase' );
        $testcase->setAttribute( 'name', $test->{description} );
        $testcase->setAttribute( 'time', $test->{end_time} - $test->{start_time} );

        $suite->appendChild( $testcase );

        if( $test->{fail_reasons} ) {
            my $failure = $doc->createElement( 'failure' );
            my $fail_description = '';
            $fail_description .= "Fail reason(s):\n";
            for my $fail ( @{$test->{fail_reasons}} ) {
                $fail_description .= "    $fail\n";
            }
            $fail_description .= "Test output:\n" . $test->{output} . "\n";

            if (not is_utf8($fail_description)) {

                # this will quietly substitute any malformed UTF-8 data it finds
                # if you'd need to make it more facist, pass Encode::FB_CROAK as
                # a third parameter
                $fail_description = encode("UTF-8", $fail_description);
            }

            $failure->appendChild( XML::LibXML::CDATASection->new( $fail_description ) );
            $testcase->appendChild( $failure );
        }

        $suite->appendChild( $testcase );
        $suites->appendChild( $suite );
    }

    $doc->setDocumentElement( $suites );
    $doc->toFile( $file_path, 2 );
    return;
}
1;

=head1 NAME

TAP::Formatter::Bamboo - Harness output delegate for JUnit output

=head1 SYNOPSIS

On the command line, with F<prove>:

  prove --formatter TAP::Formatter::Bamboo ...

Or, in your own scripts:

  use TAP::Harness;
  my $harness = TAP::Harness->new( {
      formatter_class => 'TAP::Formatter::Bamboo',
      merge => 1,
  } );
  $harness->runtests(@tests);

=head1 DESCRIPTION

B<This code is currently in alpha state and is subject to change.>

C<TAP::Formatter::Bamboo> provides JUnit output formatting for C<TAP::Harness>.

By default (e.g. when run with F<prove>), the I<entire> test suite is gathered
together into a single JUnit XML document, which is then displayed on C<STDOUT>.
You can, however, have individual JUnit XML files dumped for each individual
test, by setting c<PERL_TEST_HARNESS_DUMP_TAP> to a directory that you would
like the JUnit XML dumped to.  Note, that this will B<also> cause
C<TAP::Harness> to dump the original TAP output into that directory as well (but
IMHO that's ok as you've now got the data in two parsable formats).

Timing information is included in the JUnit XML, I<if> you specified C<--timer>
when you ran F<prove>.

In standard use, "passing TODOs" are treated as failure conditions (and are
reported as such in the generated JUnit).  If you wish to treat these as a
"pass" and not a "fail" condition, setting C<ALLOW_PASSING_TODOS> in your
environment will turn these into pass conditions.

The JUnit output generated is partial to being grokked by Hudson
(L<http://hudson.dev.java.net/>).  That's the build tool I'm using at the
moment and needed to be able to generate JUnit output for.

=head1 ATTRIBUTES

=over

=item testsuites

List-ref of test suites that have been executed.

=item xml

An C<XML::Generator> instance, to be used to generate XML output.

=back

=head1 METHODS

=over

=item B<open_test($test, $parser)>

Over-ridden C<open_test()> method.

Creates a C<TAP::Formatter::Bamboo::Session> session, instead of a console
formatter session.

=item B<summary($aggregate)>

Prints the summary report (in JUnit) after all tests are run.

=item B<add_testsuite($suite)>

Adds the given XML test C<$suite> to the list of test suites that we've
executed and need to summarize.

=back

=head1 AUTHOR

Graham TerMarsch <cpan@howlingfrog.com>

Many thanks to Andy Armstrong et al. for the B<fabulous> set of tests in
C<Test::Harness>; they became the basis for the unit tests here.

Other thanks go out to those that have provided feedback, comments, or patches:

  Mark Aufflick
  Joe McMahon
  Michael Nachbaur
  Marc Abramowitz
  Colin Robertson
  Phillip Kimmey
  Dave Lambley

=head1 COPYRIGHT

Copyright 2008-2010, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<TAP::Formatter::Console>,
L<TAP::Formatter::Bamboo::Session>,
L<http://hudson.dev.java.net/>,
L<http://jra1mw.cvs.cern.ch:8180/cgi-bin/jra1mw.cgi/org.glite.testing.unit/config/JUnitXSchema.xsd?view=markup&content-type=text%2Fvnd.viewcvs-markup&revision=HEAD>,
L<http://confluence.atlassian.com/display/BAMBOO/JUnit+parsing+in+Bamboo>.

=cut
