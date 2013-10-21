use v5.14;

package MyApp::GUI::Dialog::LogViewer {
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CHOICE EVT_CLOSE EVT_SIZE);

    with 'MyApp::Roles::Platform';

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Dialog';

    has 'sizer_debug' => ( is => 'rw', isa => 'Int', default => 0 );
    ###############
    has 'border_size' => (
        is      => 'ro', 
        isa     => 'Int',
        default => 10,
        documentation => q{
            The amount of space used to separate components from each other and 
            from the edges of the dialog.
        }
    );
    has 'position' => (
        is      => 'rw', 
        isa     => 'Wx::Point',
        default => sub{ Wx::Point->new(10,10) },
        documentation => q{
            Starting position of the LogViewer dialog
        }
    );
    has 'size' => (
        is      => 'rw', 
        isa     => 'Wx::Size',
        default => sub{ Wx::Size->new(650,700) },
        documentation => q{
            Starting size of the LogViewer dialog
        }
    );
    has 'title' => (
        is      => 'ro', 
        isa     => 'Str',
        default => 'Log Viewer',
    );
    ###############
    has 'ttl_record_count' => (
        is      => 'ro',
        isa     => 'Int',
        default => 0,
        traits  => ['Number'],
        handles => {
            set_count => 'set',
        },
        documentation => q{
            The total number of records in the current query.  Changes 
            per-component, so each time a new radio button is chosen.
        }
    );
    has 'page' => (
        is      => 'ro',
        isa     => 'Int',
        default => 1,
        traits  => ['Number'],
        handles => {
            set_page  => 'set',
            prev_page => 'sub',
            next_page => 'add',
        },
        documentation => q{
            The page we're currently on.  Resets to 1 each time the user choses 
            a new component.
        }
    );
    has 'recs_per_page' => (
        is      => 'ro',
        isa     => 'Int',
        default => 100,
    );
    has 'results' => (
        is      => 'rw',
        isa     => 'DBIx::Class::ResultSet',
        documentation => q{
            All records for the currently-selected component.  Changes when the 
            user selects a new radio button.
        }
    );
    has 'schema' => (
        is          => 'ro',
        isa         => 'MyApp::Model::LogsSchema',
        lazy_build  => 1,
    );
    has 'str_show_all' => (
        is      => 'ro',
        isa     => 'Str',
        default => 'All Records',
        documentation => q{
            Used as the first label in the Components choice.
        }
    );
    ###############
    has 'btn_next'          => (is => 'rw', isa => 'Wx::Button',        lazy_build => 1);
    has 'btn_prev'          => (is => 'rw', isa => 'Wx::Button',        lazy_build => 1);
    has 'choice_component'  => (is => 'rw', isa => 'Wx::Choice',        lazy_build => 1);
    has 'components'        => (is => 'rw', isa => 'ArrayRef',          lazy_build => 1);
    has 'lbl_component'     => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_page'          => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'list_log'          => (is => 'rw', isa => 'Wx::ListCtrl',      lazy_build => 1);
    has 'szr_component'     => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1);
    has 'szr_log'           => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1);
    has 'szr_main'          => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1);
    has 'szr_pagination'    => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1);

    sub FOREIGNBUILDARGS {## no critic qw(RequireArgUnpacking) {{{
        my $self = shift;
        my %args = @_;

        my $pos = $args{'position'} // Wx::Point->new(10,10);

        return (
            undef, -1, 
            q{},
            $pos,
            wxDefaultSize,
            wxRESIZE_BORDER|wxDEFAULT_DIALOG_STYLE
        );
    }#}}}
    sub BUILD {
        my $self = shift;

        $self->Show(0);
        $self->SetTitle( $self->title );
        $self->SetSize( $self->size );

        $self->szr_component->Add($self->lbl_component,    0, wxLEFT|wxTOP, $self->border_size);
        $self->szr_component->Add($self->choice_component, 0, wxLEFT|wxTOP, $self->border_size);

        $self->szr_log->Add($self->list_log, 1, wxEXPAND|wxLEFT|wxRIGHT|wxTOP, $self->border_size);

        $self->szr_pagination->Add($self->btn_prev, 0, wxLEFT|wxTOP|wxBOTTOM, $self->border_size);
        $self->szr_pagination->AddStretchSpacer(1);
        $self->szr_pagination->Add($self->lbl_page, 0, wxTOP, $self->border_size);
        $self->szr_pagination->AddStretchSpacer(1);
        $self->szr_pagination->Add($self->btn_next, 0, wxRIGHT|wxTOP|wxBOTTOM, $self->border_size);
        $self->szr_pagination->SetMinSize( $self->GetClientSize->width, -1 );
    
        $self->szr_main->Add($self->szr_component, 0, 0, 0);
        $self->szr_main->Add($self->szr_log, 0, 0, 0);
        $self->szr_main->Add($self->szr_pagination, 0, 0, 0);

        ### Start out with the first component (show all records) selected
        $self->choice_component->Select(0);
        $self->OnChoice();
        ### and with the Message column at max width
        $self->resize_list_headers;

        $self->SetSizer($self->szr_main);
        $self->_set_events();
        $self->Layout();
        $self->Show(1);
        return $self;
    }
    sub _build_btn_next {#{{{
        my $self = shift;
        my $v = Wx::Button->new($self, -1, 
            "Next",
            wxDefaultPosition, 
            Wx::Size->new(50, 30)
        );
        $v->SetFont( wxTheApp->wxresolve(service => '/fonts/para_text_1') );
        my $enabled = ($self->ttl_record_count > $self->recs_per_page) ? 1 : 0;
        $v->Enable($enabled);
        return $v;
    }#}}}
    sub _build_btn_prev {#{{{
        my $self = shift;
        my $v = Wx::Button->new($self, -1, 
            "Prev",
            wxDefaultPosition, 
            Wx::Size->new(50, 30)
        );
        $v->SetFont( wxTheApp->wxresolve(service => '/fonts/para_text_1') );
        $v->Enable(0); # Always start the Prev button disabled.
        return $v;
    }#}}}
    sub _build_choice_component {#{{{
        my $self = shift;

        my $v = Wx::Choice->new(
            $self, -1, 
            wxDefaultPosition, 
            Wx::Size->new(200,30), 
            $self->components,
        );

        #$v->SetSize( $v->GetBestSize );
        return $v;
    }#}}}
    sub _build_components {#{{{
        my $self = shift;

        my $rs = $self->schema->resultset('Logs')->search(
            {},
            {
                columns => [{ component => {distinct => 'me.component'} }],
                order_by => 'component'
                
            }
        );

        my $v = [ $self->str_show_all ];
        while( my $rec = $rs->next ) {
            push @{$v}, $rec->component;
        }

        return $v;
    }#}}}
    sub _build_lbl_component {#{{{
        my $self = shift;
        my $cnt  = shift || 0;;

        my $v = Wx::StaticText->new( $self, -1, 
            q{Filter by component:},
            wxDefaultPosition, 
            Wx::Size->new(-1, 20)
        );
        $v->SetFont( wxTheApp->wxresolve(service => '/fonts/para_text_2') );
        return $v;
    }#}}}
    sub _build_lbl_page {#{{{
        my $self = shift;
        my $cnt  = shift || 0;;

        my $v = Wx::StaticText->new( $self, -1, 
            #q{Page 1},
            $self->get_this_page . q{ / } . $self->get_last_page,
            wxDefaultPosition, 
            Wx::Size->new(-1, 20)
        );
        $v->SetFont( wxTheApp->wxresolve(service => '/fonts/para_text_2') );
        return $v;
    }#}}}
    sub _build_list_log {#{{{
        my $self = shift;

        ### It would be nice to be able to derive the height required by the 
        ### log list by subtracting the heights of the other sizers.
        ###
        ### However, those other sizers have not been laid out yet, so they 
        ### don't have any size yet either.
        ###
        ### So add the individual components to come up with the correct 
        ### starting listbox height.
        my $width  = $self->GetClientSize->width - $self->border_size * 2;
        my $height = $self->GetClientSize->height 
                    ### Choice uses a top border
                    - $self->choice_component->GetSize->height - $self->border_size
                    ### Pagination uses top and bottom borders
                    - $self->btn_prev->GetSize->height - $self->border_size * 2
                    ### Log list uses top and bottom borders
                    - $self->border_size * 2 
                    ;
        my $v = Wx::ListCtrl->new(
            $self, -1, 
            wxDefaultPosition, 
            Wx::Size->new($width, $height),
            wxLC_REPORT
            |wxLC_SINGLE_SEL
            |wxEXPAND
            |wxBORDER_SUNKEN
        );
        $v->InsertColumn(0, 'Date');
        $v->InsertColumn(1, 'Run');
        $v->InsertColumn(2, 'Component');
        $v->InsertColumn(3, 'Message');
        $v->Arrange(wxLIST_ALIGN_TOP);
        wxTheApp->Yield;

        return $v;
    }#}}}
    sub _build_position {#{{{
        my $self = shift;
        return Wx::Point->new(10, 10);
    }#}}}
    sub _build_schema {#{{{
        my $self = shift;
        return wxTheApp->resolve(service => '/DatabaseLog/schema');
    }#}}}
    sub _build_size {#{{{
        my $self = shift;
        my $s = Wx::Size->new(650, 700);
        return $s;
    }#}}}
    sub _build_szr_log {#{{{
        my $self = shift;

        return $self->build_sizer($self, wxHORIZONTAL, 'Log List');
    }#}}}
    sub _build_szr_main {#{{{
        my $self = shift;

        return $self->build_sizer($self, wxVERTICAL, 'Main');
    }#}}}
    sub _build_szr_component {#{{{
        my $self = shift;

        return $self->build_sizer($self, wxHORIZONTAL, 'Component');
    }#}}}
    sub _build_szr_pagination {#{{{
        my $self = shift;
        return $self->build_sizer($self, wxHORIZONTAL, 'Pagination');
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_BUTTON(     $self, $self->btn_prev->GetId,      sub{$self->OnPrev(@_)}          );
        EVT_BUTTON(     $self, $self->btn_next->GetId,      sub{$self->OnNext(@_)}          );
        EVT_CHOICE(     $self, $self->choice_component,     sub{$self->OnChoice(@_)}        );
        EVT_CLOSE(      $self,                              sub{$self->OnClose(@_)}         );
#        EVT_RADIOBOX(   $self, $self->rdo_component->GetId, sub{$self->OnRadio(@_)}         );
        EVT_SIZE(       $self,                              sub{$self->OnResize(@_)}        );
        return 1;
    }#}}}

    sub get_this_page {#{{{
        my $self = shift;
        ### Returns the current page with sufficient leading zeroes to produce 
        ### a number of the same length as the last page count, so we get "001 
        ### / 135" instead of "1 / 135", which would cause the page count to 
        ### jump when we went from page 9 to 10.
        my $lp_len = length $self->get_last_page;
        return sprintf "%0${lp_len}d", $self->page;
    }#}}}
    sub get_last_page {#{{{
        my $self = shift;
        my $lp = int( $self->ttl_record_count / $self->recs_per_page );
        $lp++ if $self->ttl_record_count % $self->recs_per_page;
    }#}}}
    sub resize_list_headers {#{{{
        my $self = shift;
        ### The first three columns' sizes remain static; resize the Message 
        ### column only.
        my $subtract = 0;
        $subtract += $self->list_log->GetColumnWidth($_) for( 0..2 ); 
        my $msg_width = $self->list_log->GetClientSize->width - $subtract;
        $self->list_log->SetColumnWidth(3, $msg_width);
        return 1;
    }#}}}
    sub show_page {#{{{
        my $self = shift;

        $self->list_log->DeleteAllItems;

        my $offset  = $self->page - 1;
        my $start   = $self->recs_per_page * $offset;
        my $end     = $start + $self->recs_per_page - 1;
        my $slice   = $self->results->slice($start, $end);

        my $row = 0;
        while(my $r = $slice->next) {
            $self->list_log->InsertStringItem($row, $r->datetime->dmy . q{ } . $r->datetime->hms);
            $self->list_log->SetItem($row, 1, $r->run);
            $self->list_log->SetItem($row, 2, $r->component);
            $self->list_log->SetItem($row, 3, $r->message);
            $row++;
            wxTheApp->Yield;
        }
        $self->list_log->SetColumnWidth(0, wxLIST_AUTOSIZE);
        $self->list_log->SetColumnWidth(1, wxLIST_AUTOSIZE_USEHEADER);
        $self->list_log->SetColumnWidth(2, wxLIST_AUTOSIZE_USEHEADER);
        $self->list_log->SetColumnWidth(3, wxLIST_AUTOSIZE);

        $self->update_pagination();
    }#}}}
    sub update_pagination {#{{{
        my $self = shift;
        my $cnt  = shift || 0;

        my $next_enabled = ($self->page * $self->recs_per_page <  $self->ttl_record_count) ? 1 : 0;
        $self->btn_next->Enable($next_enabled);

        my $prev_enabled = ($self->page > 1) ? 1 : 0;
        $self->btn_prev->Enable($prev_enabled);

        #my $text = "Page " . $self->page;
        my $text = $self->get_this_page . q{ / } . $self->get_last_page;
        $self->lbl_page->SetLabel($text);
    }#}}}

    sub OnChoice {#{{{
        my $self    = shift;
        my $dialog  = shift;    # Wx::Dialog
        my $event   = shift;    # Wx::CommandEvent

        my $component = $self->choice_component->GetString( $self->choice_component->GetSelection );

        my $search_hr = ( $component eq $self->str_show_all ) 
            ? {}
            : { component => $component };

        my $rs = $self->schema->resultset('Logs')->search(
            $search_hr,
            {
                order_by => [
                    { -desc => ['run'] },
                    { -asc  => ['datetime'] },
                    ### Add 'id' as well so consecutive records with the same 
                    ### timestamp will show up in the correct order.
                    { -asc  => ['id'] },
                ],
            }
        );

        $self->results( $rs );
        $self->set_page(1);
        $self->set_count( $rs->count );
        $self->show_page();

        return 1;
    }#}}}
    sub OnClose {#{{{
        my($self, $dialog, $event) = @_;
        $self->Destroy;
        $event->Skip();
        return 1;
    }#}}}
    sub OnNext {#{{{
        my $self    = shift;
        my $panel   = shift;
        my $event   = shift;

        $self->next_page(1);
        $self->show_page;

        return 1;
    }#}}}
    sub OnResize {#{{{
        my $self    = shift;
        my $dialog  = shift;
        my $event   = shift;    # Wx::SizeEvent

        $self->szr_log->SetMinSize( $self->GetClientSize->width, -1 );
        $self->szr_pagination->SetMinSize( $self->GetClientSize->width, -1 );
        $self->resize_list_headers;

        $self->Layout;
        return 1;
    }#}}}
    sub OnPrev {#{{{
        my $self    = shift;
        my $panel   = shift;
        my $event   = shift;

        $self->prev_page(1);
        $self->show_page;

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

__END__

=head1 NAME

MyApp::GUI::Dialog::LogViewer - Dialog for browsing log entries

=head1 SYNOPSIS

 $pos     = Wx::Position->new( $some_x, $some_y );
 $l_view  = MyApp::GUI::Dialog::LogViewer->new( position => $pos );
 $l_view->Show(1);

=head1 DESCRIPTION

The LogViewer is a paginated list of all of the log entries produced by the 
app.  Entries can be filtered to only show logs produced by the specific app 
component you're currently interested in.

