
package MyApp::Roles::MenuBar {
    use v5.14;
    use Moose::Role;
    use Wx qw(:everything);

    has 'parent' => (
        is      => 'rw',
        isa     => 'Wx::Frame',
    );

    sub FOREIGNBUILDARGS {#{{{
        return;
    }#}}}
    sub BUILD {
        my $self = shift;
        return $self;
    }

    no Moose::Role;
}

1;

__END__

=head1 NAME

MyApp::Roles::MenuBar - MenuBar role

=head1 SYNOPSIS

Assume C<$self> is a Wx::Frame onto which we want to place the MenuBar:

 $menu_bar = MyMenubarClass->new( parent => $self );
 $self->SetMenuBar( $menu_bar );

=head1 PROVIDED ATTRIBUTES

=head2 required - parent

Menu and MenuBar controls do not have true parents.  However, Menu items are 
often meant to affect a certain dialog or frame.  

When creating a MenuBar implementing this role, you must pass along the frame or 
dialog on which the menu is being placed, as its parent.

That parent attribute must then be passed along to each Menu item added to the 
MenuBar.

=head1 SEE ALSO

L<MyApp::Roles::Menu>

