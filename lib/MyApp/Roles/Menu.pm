
package MyApp::Roles::Menu {
    use v5.14;
    use Moose::Role;
    use Wx qw(:everything);

    has 'parent' => (
        is          => 'rw',
        isa         => 'Wx::Window',
        required    => 1,
    );

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

Assume C<$self> is a MenuBar onto which we want to append the Menu:

 my $menu_item = MyMenuItemClass->new( parent => $self->parent );
 $self->Append( $menu_item, 'My Label' );

=head1 PROVIDED ATTRIBUTES

=head2 required - parent

Menu and MenuBar controls do not have true parents.  However, Menu items are 
often meant to affect a certain dialog or frame.  

When creating a Menu implementing this role, you must pass along the frame or 
dialog on which the menu is being placed, as its parent.

This parent is simply passed from the MenuBar to each Menu item.

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

=head1 SEE ALSO

L<MyApp::Roles::MenuBar>

