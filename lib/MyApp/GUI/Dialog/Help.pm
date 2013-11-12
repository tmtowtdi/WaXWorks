use v5.14;

package MyApp::GUI::Dialog::Help {
    use Browser::Open;
    use File::Spec;
    use File::Util;
    use Moose;
    use MooseX::NonMoose::InsideOut;
    use Template;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CLOSE EVT_HTML_LINK_CLICKED EVT_SIZE EVT_TEXT_ENTER);

    ### Required for the wxHW_SCROLLBAR* constants.  They should be exported 
    ### by the Wx :everything tag, but they're not.
    use Wx::Html;

    use MyApp::Model::SearchIndex::Help;
    with 'MyApp::Roles::Platform';
    extends 'Wx::Dialog';


    has 'sizer_debug'   => (is => 'rw', isa => 'Int',   default => 0        );
    has 'title'         => (is => 'rw', isa => 'Str',   default => 'Help'   );

    has 'border_size'   => (is => 'ro', isa => 'Int',   default => 02       );
    has 'nav_img_h'     => (is => 'rw', isa => 'Int',   default => 32       );
    has 'nav_img_w'     => (is => 'rw', isa => 'Int',   default => 32       );
    has 'search_box_h'  => (is => 'rw', isa => 'Int',   default => 30       );
    has 'search_box_w'  => (is => 'rw', isa => 'Int',   default => 150      );
    has 'home_spacer_w' => (is => 'rw', isa => 'Int',   default => 10       );

    has 'szr_html'      => (is => 'rw', isa => 'Wx::Sizer', lazy_build => 1, documentation => 'vertical'    );
    has 'szr_main'      => (is => 'rw', isa => 'Wx::Sizer', lazy_build => 1, documentation => 'vertical'    );
    has 'szr_navbar'    => (is => 'rw', isa => 'Wx::Sizer', lazy_build => 1, documentation => 'horizontal'  );

    has 'bmp_home' => (
        is          => 'rw',
        isa         => 'Wx::BitmapButton',
        lazy_build  => 1,
    );
    has 'bmp_left' => (
        is          => 'rw',
        isa         => 'Wx::BitmapButton',
        lazy_build  => 1,
    );
    has 'bmp_right' => (
        is          => 'rw',
        isa         => 'Wx::BitmapButton',
        lazy_build  => 1,
    );
    has 'bmp_search' => (
        is          => 'rw',
        isa         => 'Wx::BitmapButton',
        lazy_build  => 1,
    );
    has 'help_idx'  => (
        is          => 'rw',
        isa         => 'MyApp::Model::SearchIndex::Help',  
        default     => sub{ MyApp::Model::SearchIndex::Help->new( root => wxTheApp->root_dir ) },
    );
    has 'history' => (
        is          => 'rw',
        isa         => 'ArrayRef',
        default     => sub{[$_[0]->index_file]},
    );
    has 'history_idx' => (
        is          => 'rw',
        isa         => 'Int',
        default     => 0
    );
    has 'html_window' => (
        is          => 'rw',
        isa         => 'Wx::HtmlWindow',
        lazy_build  => 1,
    );
    has 'index_file' => (
        is          => 'rw',
        isa         => 'Str',
        lazy        => 1,
        default     => 'index.html',
    );
    has 'prev_click_href' => (
        is          => 'rw',
        isa         => 'Str',
        lazy        => 1,
        default     => q{},
    );
    has 'size'  => (
        is      => 'rw',
        isa     => 'Wx::Size',  
        default => sub{ Wx::Size->new( 500, 600 ) },
    );
    has 'tmpl_vars' => (
        is          => 'rw',
        isa         => 'HashRef',
        lazy_build  => 1,
        documentation => q{
            Hashref of variables that get passed to each template before processing.
        }
    );
    has 'tt' => (
        is          => 'rw',
        isa         => 'Template',
        lazy_build  => 1,
    );
    has 'txt_search' => (
        is          => 'rw',
        isa         => 'Wx::TextCtrl',
        lazy_build  => 1,
    );


    sub FOREIGNBUILDARGS {## no critic qw(RequireArgUnpacking) {{{
        my $self = shift;
        my %args = @_;

        return (
            undef, -1, 
            q{},        # the title
            wxDefaultPosition,
            Wx::Size->new(600, 700),
            wxRESIZE_BORDER|wxDEFAULT_DIALOG_STYLE
        );
    }#}}}
    sub BUILD {
        my $self = shift;

        $self->Show(0);

        ### Create the nav and search bar
        $self->make_navbar();
        $self->szr_navbar->SetMinSize( $self->GetClientSize->width, -1 ); 

        ### Create the HTML help window
        $self->szr_html->Add($self->html_window, 1, wxEXPAND, 0);
        $self->szr_html->SetMinSize(
            $self->get_html_width, 
            $self->get_html_height,
        ); 

        ### Add both to the main sizer
        $self->szr_main->AddSpacer(5);
        $self->szr_main->Add($self->szr_navbar, 0, wxEXPAND|wxLEFT|wxRIGHT, $self->border_size);
        $self->szr_main->AddSpacer(5);
        $self->szr_main->Add($self->szr_html, 1, wxEXPAND|wxALL, $self->border_size);

        ### Explode horribly if the index file is unavailable
        unless( $self->load_html_file($self->index_file) ) {
            wxTheApp->poperr("GONG!  Unable to load help files!", "GONG!");
            $self->Destroy;
            return;
        }

        $self->SetTitle( $self->title );
        $self->SetSizer( $self->szr_main );
        $self->Layout();
        $self->_set_events();
        $self->Show(1);

        return $self;
    };
    sub _build_bmp_home {#{{{
        my $self = shift;

        #my $img = wxTheApp->wxbb->resolve( service => '/assets/images/help/home.png');
        my $img = wxTheApp->assets->image_from_zip('images/help/home.png');

        $img->Rescale($self->nav_img_w - 10, $self->nav_img_h - 10);    # see build_bmp_left
        my $bmp = Wx::Bitmap->new($img);
        my $v = Wx::BitmapButton->new(
            $self, -1, 
            $bmp,
            wxDefaultPosition,
            Wx::Size->new($self->nav_img_w, $self->nav_img_h),
            wxBU_AUTODRAW 
        );
        return $v;
    }#}}}
    sub _build_bmp_left {#{{{
        my $self = shift;
        #my $img = wxTheApp->wxbb->resolve( service => '/assets/images/help/arrow-left.png');
        my $img = wxTheApp->assets->image_from_zip('images/help/arrow-left.png');
        ### On Ubuntu, there's a margin inside the button.  If the image is 
        ### the same size as the button, that margin obscures part of the 
        ### image.  So the image must be a bit smaller than the button.
        $img->Rescale($self->nav_img_w - 10, $self->nav_img_h - 10);
        my $bmp = Wx::Bitmap->new($img);
        my $v = Wx::BitmapButton->new(
            $self, -1, 
            $bmp,
            wxDefaultPosition,
            Wx::Size->new($self->nav_img_w, $self->nav_img_h),
            wxBU_AUTODRAW 
        );
        return $v;
    }#}}}
    sub _build_bmp_right {#{{{
        my $self = shift;
        #my $img = wxTheApp->wxbb->resolve( service => '/assets/images/help/arrow-right.png');
        my $img = wxTheApp->assets->image_from_zip('images/help/arrow-right.png');
        $img->Rescale($self->nav_img_w - 10, $self->nav_img_h - 10);    # see build_bmp_left
        my $bmp = Wx::Bitmap->new($img);
        return Wx::BitmapButton->new(
            $self, -1, 
            $bmp,
            wxDefaultPosition,
            Wx::Size->new($self->nav_img_w, $self->nav_img_h),
            wxBU_AUTODRAW 
        );
    }#}}}
    sub _build_bmp_search {#{{{
        my $self = shift;
        #my $img = wxTheApp->wxbb->resolve( service => '/assets/images/help/search.png');
        my $img = wxTheApp->assets->image_from_zip('images/help/search.png');
        $img->Rescale($self->nav_img_w - 10, $self->nav_img_h - 10);    # see build_bmp_left
        my $bmp = Wx::Bitmap->new($img);
        my $v = Wx::BitmapButton->new(
            $self, -1, 
            $bmp,
            wxDefaultPosition,
            Wx::Size->new($self->nav_img_w, $self->nav_img_h),
            wxBU_AUTODRAW 
        );
        return $v;
    }#}}}
    sub _build_html_window {#{{{
        my $self = shift;

        my $v = Wx::HtmlWindow->new(
            $self, -1, 
            wxDefaultPosition, 
            wxDefaultSize,
            #Wx::Size->new($self->get_html_width, $self->get_html_height),
            wxHW_SCROLLBAR_AUTO
            |wxSIMPLE_BORDER
        );
        return $v;
    }#}}}
    sub _build_szr_html {#{{{
        my $self = shift;
        my $v = $self->build_sizer($self, wxVERTICAL, 'Help');
        return $v;
    }#}}}
    sub _build_szr_main {#{{{
        my $self = shift;
        my $v = $self->build_sizer($self, wxVERTICAL, 'Main Sizer');
        return $v;
    }#}}}
    sub _build_szr_navbar {#{{{
        my $self = shift;
        my $v = $self->build_sizer($self, wxHORIZONTAL, 'Nav bar');
        return $v;
    }#}}}
    sub _build_tt {#{{{
        my $self = shift;
        my $tt = Template->new(
            ABSOLUTE        => 1,
            INCLUDE_PATH    => wxTheApp->dirs->html,
            INTERPOLATE     => 1,
            OUTPUT_PATH     => wxTheApp->dirs->html,
            WRAPPER         => 'tmpl/wrapper',
        );
        return $tt;
    }#}}}
    sub _build_tmpl_vars {#{{{
        my $self = shift;
        return {
            dir_sep     => File::Util->SL,
            html_dir    => wxTheApp->dirs->html,
        };
    }#}}}
    sub _build_txt_search {#{{{
        my $self = shift;
        my $v = Wx::TextCtrl->new(
            $self, -1, 
            q{},
            wxDefaultPosition, 
            Wx::Size->new($self->search_box_w, $self->search_box_h),
            wxTE_PROCESS_ENTER
        );
        $v->SetToolTip("Type search terms and hit <enter> or click the search button");
        return $v;
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_CLOSE(              $self,                              sub{$self->OnClose(@_)}         );
        EVT_BUTTON(             $self,  $self->bmp_home->GetId,     sub{$self->OnHomeNav(@_)}       );
        EVT_BUTTON(             $self,  $self->bmp_left->GetId,     sub{$self->OnLeftNav(@_)}       );
        EVT_BUTTON(             $self,  $self->bmp_right->GetId,    sub{$self->OnRightNav(@_)}      );
        EVT_BUTTON(             $self,  $self->bmp_search->GetId,   sub{$self->OnSearchNav(@_)}     );
        EVT_HTML_LINK_CLICKED(  $self,  $self->html_window->GetId,  sub{$self->OnLinkClicked(@_)}   );
        EVT_SIZE(               $self,                              sub{$self->OnResize(@_)}        );
        EVT_TEXT_ENTER(         $self,  $self->txt_search->GetId,   sub{$self->OnSearchNav(@_)}     );
        return 1;
    }#}}}

    sub clean_text {#{{{
        my $self = shift;
        my $text = shift;
        $text = " $text";
        $text =~ s/[\r\n]/ /g;
        $text =~ s/\s{2,}/ /g;
        $text =~ s/\s+$//;
        return $text;
    }#}}}
    sub get_docs {#{{{
        my $self    = shift;
        my $kandi   = HTML::Strip->new();
        my $docs    = {};
        my $dir     = wxTheApp->dirs->html;
        foreach my $f(glob("\"$dir\"/*.html")) {
            my $html = read_file($f);

            my $content = $kandi->parse( $html );
            $kandi->eof;

            ### The templates we're parsing are not full HTML documents, since 
            ### the wrapper contains our header and footer.  Tack on opening 
            ### and closing html and body tags to the content to make XPath 
            ### happy.
            my $x = HTML::TreeBuilder::XPath->new();
            $x->parse("<html><body>$html</body></html>");
            my $title   = $x->findvalue('/html/body/h1') || 'No Title';
            my $summary = $self->get_doc_summary($x) || 'No Summary';

            $docs->{$f} = {
                content     => $content,
                summary     => $summary,
                title       => $title,
            }
        }
        return $docs;
    }#}}}
    sub get_doc_summary {#{{{
        my $self  = shift;
        my $xpath = shift;

        my @nodeset = $xpath->findnodes('/html/body/*');
        my $summary  = q{};
        NODE:
        for my $n(@nodeset) {
            next if $n->getName =~ /^h/i;   # skip headers
            $summary .= $self->clean_text($n->getValue);
            last NODE if length $summary > $self->summary_length;
        }
        return $summary;
    }#}}}
    sub get_html_width {#{{{
        my $self = shift;
        return $self->GetClientSize->width;
    }#}}}
    sub get_html_height {#{{{
        my $self = shift;
        return (
            $self->GetClientSize->height
                - $self->bmp_left->GetSize->height, 
        );
    }#}}}
    sub load_html_file {#{{{
        my $self = shift;
        my $file = shift || return;

        ### If $file is already a FQ path, link directly to it.  Otherwise, 
        ### prepend it with our html dir.
        my $dir  = quotemeta wxTheApp->dirs->html;
        my $fqfn = ( $file =~ m/^$dir/ ) ? $file : join q{/}, (wxTheApp->dirs->html, $file);
        unless(-e $fqfn) {
            wxTheApp->poperr("$fqfn: No such file or directory");
            return;
        }

        my $output  = q{};
        $self->tt->process($file, $self->tmpl_vars, \$output);
        $self->html_window->SetPage($output);
        return 1;
    }#}}}
    sub make_navbar {#{{{
        my $self = shift;

        $self->clear_szr_navbar;
        $self->szr_navbar->Add($self->bmp_left, 0, 0, 0);
        $self->szr_navbar->Add($self->bmp_right, 0, 0, 0);
        $self->szr_navbar->Add($self->home_spacer_w, 0, 0);
        $self->szr_navbar->Add($self->bmp_home, 0, 0, 0);
        $self->szr_navbar->AddStretchSpacer(1);

        ### The search button we're trying to line the text box up with 
        ### doesn't quite reach the bottom of the sizer.
        ### So using ALIGN_BOTTOM on the text box means its bottom will be 
        ### about a pixel below the bottom of the button, which is ugly.
        ### Instead, we'll add headspace equal to the difference between the 
        ### button's height and the search box's height minus 1, just above 
        ### the text box.
        $self->szr_navbar->Add(
            $self->txt_search, 0, wxTOP, 
            ($self->bmp_search->GetSize->height - $self->search_box_h - 1)
        );

        $self->szr_navbar->Add($self->bmp_search, 0, 0, 0);

        $self->txt_search->SetFocus;
        return 1;
    }#}}}

    sub OnClose {#{{{
        my $self    = shift;
        my $dialog  = shift;
        my $event   = shift;
        $self->Destroy;
        $event->Skip();
        return 1;
    }#}}}
    sub OnHomeNav {#{{{
        my $self    = shift;    # MyApp::GUI::Dialog::Help
        my $dialog  = shift;    # MyApp::GUI::Dialog::Help
        my $event   = shift;    # Wx::CommandEvent

        $self->history_idx( $self->history_idx + 1 );
        $self->history->[ $self->history_idx ] = $self->index_file;
        $self->prev_click_href( $self->index_file );
        $self->load_html_file( $self->index_file );
        return 1;
    }#}}}
    sub OnLeftNav {#{{{
        my $self    = shift;    # MyApp::GUI::Dialog::Help
        my $dialog  = shift;    # MyApp::GUI::Dialog::Help
        my $event   = shift;    # Wx::CommandEvent

        return if $self->history_idx == 0;

        my $page = $self->history->[ $self->history_idx - 1 ];
        $self->history_idx( $self->history_idx - 1 );
        $self->prev_click_href( $page );
        $self->load_html_file( $page );
        return 1;
    }#}}}
    sub OnLinkClicked {#{{{
        my $self    = shift;    # MyApp::GUI::Dialog::Help
        my $dialog  = shift;    # MyApp::GUI::Dialog::Help
        my $event   = shift;    # Wx::HtmlLinkEvent

        my $info = $event->GetLinkInfo;

        if( $info->GetHref =~ /^http/ ) {# Deal with real URLs {{{
            ### retval of Browser::Open::open_browser
            ###     - retval == undef --> no open cmd found
            ###     - retval != 0     --> open cmd found but error encountered
            ### Browser::Open must be v0.04 to work on Windows.
            my $ok = Browser::Open::open_browser($info->GetHref);

            if( $ok ) {
                wxTheApp->poperr(
                    "App encountered an error while attempting to open the URL in your web browser.  The URL you were attempting to reach was '" . $info->GetHref . q{'.},
                    "Error opening web browser"
                );
            }
            elsif(not defined $ok) {
                wxTheApp->poperr(
                    "App was unable to open the URL in your web browser.  The URL you were attempting to reach was '" . $info->GetHref . q{'.},
                    "Unable to open web browser"
                );
            }

            return 1;
        }#}}}

        ### Each link click is triggering this event twice.
        if( $self->prev_click_href eq $info->GetHref ) {
            return 1;
        }
        $self->prev_click_href( $info->GetHref );

        ### If the user has backed up through their history and then clicked a 
        ### link, we need to diverge to an alternate timeline - truncate the 
        ### history so the current location is the furthest point.
        $#{$self->history} = $self->history_idx;

        push @{$self->history}, $info->GetHref;
        $self->history_idx( $self->history_idx + 1 );
        $self->load_html_file($info->GetHref);
        return 1;
    }#}}}
    sub OnResize {#{{{
        my $self = shift;

        $self->szr_navbar->SetMinSize( $self->GetClientSize->width, -1 ); 
        $self->szr_html->SetMinSize  ( $self->get_html_width, $self->get_html_height ); 

        ### Layout to force the navbar to update
        ### This must happen before the html window gets resized to avoid ugly 
        ### flashing.
        $self->Layout;

        #$self->html_window->SetSize( Wx::Size->new($self->get_html_width, $self->get_html_height) );
        return 1;
    }#}}}
    sub OnRightNav {#{{{
        my $self    = shift;    # MyApp::GUI::Dialog::Help
        my $dialog  = shift;    # MyApp::GUI::Dialog::Help
        my $event   = shift;    # Wx::CommandEvent

        return if $self->history_idx == $#{$self->history};

        my $page = $self->history->[ $self->history_idx + 1];
        $self->history_idx( $self->history_idx + 1 );
        $self->prev_click_href( $page );
        $self->load_html_file( $page );
        return 1;
    }#}}}
    sub OnSearchNav {#{{{
        my $self    = shift;    # MyApp::GUI::Dialog::Help
        my $dialog  = shift;    # MyApp::GUI::Dialog::Help
        my $event   = shift;    # Wx::CommandEvent

        my $term = $self->txt_search->GetValue;
        unless($term) {
            wxTheApp->popmsg("Searching for nothing isn't going to return many results.");
            return;
        }

        unless( $self->help_idx->searcher ) {
            wxTheApp->poperr(
                "The help documentation has not been indexed yet, so searching is not possible.\n"
                . "Close this help window and run bin/update_help.pl.\n\n"
                . "Then re-open the help window and search will work.",
                "Search Index Empty"
            );
            return;
        }

        my $hits = $self->help_idx->searcher->hits( query => $term );
        my $vars = {
            term => $term,
        };
        while ( my $hit = $hits->next ) {
            my $hr = {
                content     => $hit->{'content'},
                filename    => $hit->{'filename'},
                summary     => $hit->{'summary'},
                title       => $hit->{'title'},
            };
            push @{$vars->{'hits'}}, $hr;
        }

        my $output = q{};
        $self->tt->process('tmpl/hitlist.tmpl', $vars, \$output);
        $self->html_window->SetPage($output);
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

=head1 NAME

MyApp::GUI::Dialog::Help - Dialog for navigating, searching, and displaying 
app-specific help files.

=head1 SYNOPSIS

 $dialog = MyApp::GUI::Dialog::Help->new();

=head1 DESCRIPTION

MyApp::GUI::Dialog::Help allows you to add help documentation to your app by 
simply creating HTML files.  You can add new or edit existing help 
documentation while the app is running, and view your changes immeidately by 
simply re-navigating to your changed document (the Help browser does not have 
a reload button, as that would only be useful to the developer, and its 
existence might confuse the end-user).

Once you're happy with the state of your new documents, they can be indexed by 
running C<bin/update_help.pl>.  To search for your new documents, simply close 
and re-open the help browser; it's not necessary to restart the entire app.

=head1 CREATING AND EDITING HELP FILES

Help files live in the directory pointed to by MyApp::Model::Dirs::html().
These files are actually templates.

The help files are actually L<Template::Toolkit> templates, and their content 
is surrounded by a wrapper template.  This wrapper template lives in a 
subdirectory (C<tmpl/>) of the directory in which the rest of the help 
templates live.  So, to change the overall look of all of your help pages, simply 
edit C<HELP_DIRECTORY/tmpl/wrapper>.

The help browser itself is pretty rudimentary, HTML-wise, and has no concept 
of style sheets, so your HTML needs to be very simple. 

