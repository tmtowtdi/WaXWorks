
package MyApp::Roles::Menu {
    use v5.14;
    use Moose::Role;
    use Wx qw(:everything);

    sub FOREIGNBUILDARGS {#{{{
        return;
    }#}}}
    sub BUILD {
        my $self = shift;
        return $self;
    }

    sub sep {#{{{
        my $self = shift;
        return Wx::MenuItem->new($_[0], wxID_SEPARATOR),
    }#}}}

    no Moose::Role;
}

1;

__END__

=head1 NAME

MyApp::Roles::Menu - Menu role

=head1 SYNOPSIS

=head1 PROVIDED METHODS

=head2 sep

If we define a single Moose attribute as a separator and attempt to use that 
item multiple times, wxwidgets will try to delete both on shutdown, producing 
an error when it tries to delete all but the first.

But defining every separator we might want to use as separate Moose attributes 
seems a little unnecessary.

So if you need a separator, simply call sep() to get a brand new one.

=over 4

=item * ARGS

=over 8

=item * none

=back

=item * RETURNS

=over 8

=item * A new Wx::MenuItem object representing a separator.

=back

=back

