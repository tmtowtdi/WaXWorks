use v5.14;

package MyApp::Roles::Platform::Dialog::NonScrolled {
    use Moose::Role;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw();

    with 'MyApp::Roles::Platform';

    has 'page_sizer'    => (is => 'rw', isa => 'Wx::BoxSizer',  lazy_build => 1, documentation => 'horizontal'  );
    has 'main_sizer'    => (is => 'rw', isa => 'Wx::Sizer',     lazy_build => 1, documentation => 'vertical'    );
    has 'title'         => (is => 'rw', isa => 'Str',           lazy_build => 1);
    has 'position'      => (is => 'rw', isa => 'Wx::Point',     lazy_build => 1);
    has 'size'          => (is => 'rw', isa => 'Wx::Size',      lazy_build => 1);

    sub FOREIGNBUILDARGS {## no critic qw(RequireArgUnpacking) {{{
        my $self = shift;
        my %args = @_;

        my $pos = $args{'position'} // Wx::Point->new(10,10);

        return (
            #undef,
            wxTheApp->main_frame,
            -1,
            q{},
            $pos,
            wxDefaultSize,
            wxRESIZE_BORDER|wxDEFAULT_DIALOG_STYLE
        );
    }#}}}
    sub BUILD {
        my $self = shift;
        return $self;
    }
    sub _build_main_sizer {#{{{
        my $self = shift;
        my $v = $self->build_sizer($self, wxVERTICAL, 'Main Sizer');
        return $v;
    }#}}}
    sub _build_page_sizer {#{{{
        my $self = shift;
        my $v = $self->build_sizer($self, wxHORIZONTAL, 'Page Sizer');
        return $v;
    }#}}}
    sub _build_position {#{{{
        my $self = shift;
        return Wx::Point->new(10, 10);
    }#}}}
    sub _build_size {#{{{
        my $self = shift;
        return wxDefaultSize;
    }#}}}
    sub _build_title {#{{{
        my $self = shift;
        return 'Dialog Title';
    }#}}}
    sub _set_events { }

    sub make_non_resizable {#{{{
        my $self = shift;
        my $style = $self->GetWindowStyleFlag;

        $style = ($style ^ wxRESIZE_BORDER);
        $self->SetWindowStyle($style);
        return 1;
    }#}}}
    sub make_resizable {#{{{
        my $self = shift;
        my $style = $self->GetWindowStyleFlag;

        $style = ($style | wxRESIZE_BORDER);
        $self->SetWindowStyle($style);
        return 1;
    }#}}}

    sub init_screen {#{{{
        my $self = shift;

=head2 init_screen

Must be called by your extending class's BUILD sub after everything else is set up.

Just putting the code here inside NonScrolled.pm's BUILD sub does work OK on Windows, 
but does not work OK on Ubuntu.  So don't just arbitrarily think better of this method 
without testing it there first.

=cut

        $self->page_sizer->Add(
            $self->main_sizer,
            1,
            wxEXPAND|wxALL,     # 0,
            5,                  # border size,
        );
        $self->SetSizer($self->page_sizer);
        $self->Layout;
        return 1;
    }#}}}

    no Moose::Role;
}

1;

__END__

=head1 NAME

MyApp::Roles::Platform::Dialog::NonScrolled - A non-scrolled dialog with margins.

=head1 DESCRIPTION

Elements added to Dialogs get pushed right next to the borders of the Dialog 
window.  This role wraps the entire Dialog with some margin-creating sizers.

=head1 SYNOPSIS

 package MyDialog;
 use Moose;
 use MooseX::NonMoose::InsideOut;
 extends 'Wx::Dialog';
 with 'MyApp::Roles::Platform::Dialog::NonScrolled';

 sub BUILD {
  my $self = shift;

  # title and size attributes are provided by NonScrolled.pm, but you're not
  # likely to enjoy the default values, so your extending class should set
  # its own values.  These attributes are lazy, so your extending class can
  # provide _build_*() methods for them:
  $self->SetTitle( $self->title );
  $self->SetSize( $self->size );

  # main_sizer is a vertical Wx::Sizer provided by NonScrolled.  Your
  # extending class's Wx components should be added to that sizer:
  $self->main_sizer->Add( $self->button, 0, 0, 0 );

  # This sets your main_sizer up inside the provided page_sizer and properly 
  # lays out the page..
  $self->init_screen();

  return $self;
 }
 sub _build_title { return 'My Title' }
 sub _build_size  { return Wx::Size->new($some_width, $some_height) }

 # That main_sizer is itself added to a page_sizer, which maintains the
 # dialog-wide left margin.  This happens automatically, so your extending
 # class does not need to touch page_sizer.

 # Constructor:
 my $object = EXTENDING_CLASS->new();

 # Optional - make your dialog non-resizable (default is resizable):
 $object->make_non_resizable;

 # Whoops - crap I didn't mean to do that...
 $object->make_resizable;

=head2 position (optional)

A Wx::Point object defining the NW corner of the dialog.  Defaults to (10,10).

=cut

