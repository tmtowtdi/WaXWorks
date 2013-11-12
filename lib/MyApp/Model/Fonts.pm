use v5.14;

package MyApp::Model::Fonts {
    use warnings;
    use Moose;
    use Wx qw(:everything);

    ### Variable-width, sans-serif (Arial)
    has 'para_text_1' => (is => 'ro', isa => 'Wx::Font', lazy => 1,
        default => sub{ Wx::Font->new(8,  wxSWISS, wxNORMAL, wxNORMAL, 0)},
    );
    has 'para_text_2' => (is => 'ro', isa => 'Wx::Font', lazy => 1,
        default => sub{ Wx::Font->new(10,  wxSWISS, wxNORMAL, wxNORMAL, 0)},
    );
    has 'para_text_3' => (is => 'ro', isa => 'Wx::Font', lazy => 1,
        default => sub{ Wx::Font->new(12,  wxSWISS, wxNORMAL, wxNORMAL, 0)},
    );
    has 'bold_para_text_1' => (is => 'ro', isa => 'Wx::Font', lazy => 1,
        default => sub{ Wx::Font->new(8,  wxSWISS, wxNORMAL, wxBOLD, 0)},
    );
    has 'bold_para_text_2' => (is => 'ro', isa => 'Wx::Font', lazy => 1,
        default => sub{ Wx::Font->new(10,  wxSWISS, wxNORMAL, wxBOLD, 0)},
    );
    has 'bold_para_text_3' => (is => 'ro', isa => 'Wx::Font', lazy => 1,
        default => sub{ Wx::Font->new(12,  wxSWISS, wxNORMAL, wxBOLD, 0)},
    );
    ### Fixed-width
    has 'modern_text_1' => (is => 'ro', isa => 'Wx::Font', lazy => 1,
        default => sub{ Wx::Font->new(8,  wxMODERN, wxNORMAL, wxNORMAL, 0)},
    );
    has 'modern_text_2' => (is => 'ro', isa => 'Wx::Font', lazy => 1,
        default => sub{ Wx::Font->new(8,  wxMODERN, wxNORMAL, wxNORMAL, 0)},
    );
    has 'modern_text_3' => (is => 'ro', isa => 'Wx::Font', lazy => 1,
        default => sub{ Wx::Font->new(8,  wxMODERN, wxNORMAL, wxNORMAL, 0)},
    );
    has 'bold_modern_text_1' => (is => 'ro', isa => 'Wx::Font', lazy => 1,
        default => sub{ Wx::Font->new(8,  wxMODERN, wxNORMAL, wxBOLD, 0)},
    );
    has 'bold_modern_text_2' => (is => 'ro', isa => 'Wx::Font', lazy => 1,
        default => sub{ Wx::Font->new(8,  wxMODERN, wxNORMAL, wxBOLD, 0)},
    );
    has 'bold_modern_text_3' => (is => 'ro', isa => 'Wx::Font', lazy => 1,
        default => sub{ Wx::Font->new(8,  wxMODERN, wxNORMAL, wxBOLD, 0)},
    );
    ### Headers
    has 'header_1' => (is => 'ro', isa => 'Wx::Font', lazy => 1,
        default => sub{ Wx::Font->new(22,  wxSWISS, wxNORMAL, wxBOLD, 0)},
    );
    has 'header_2' => (is => 'ro', isa => 'Wx::Font', lazy => 1,
        default => sub{ Wx::Font->new(20,  wxSWISS, wxNORMAL, wxBOLD, 0)},
    );
    has 'header_3' => (is => 'ro', isa => 'Wx::Font', lazy => 1,
        default => sub{ Wx::Font->new(18,  wxSWISS, wxNORMAL, wxBOLD, 0)},
    );
    has 'header_4' => (is => 'ro', isa => 'Wx::Font', lazy => 1,
        default => sub{ Wx::Font->new(16,  wxSWISS, wxNORMAL, wxBOLD, 0)},
    );
    has 'header_5' => (is => 'ro', isa => 'Wx::Font', lazy => 1,
        default => sub{ Wx::Font->new(14,  wxSWISS, wxNORMAL, wxBOLD, 0)},
    );

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;


__END__

=head1 NAME

MyApp::Model::Fonts - Named generic font container

=head1 SYNOPSIS

 $fonts = MyApp::Model::Fonts->new();

 ### Set normal text font on a button
 $button = Wx::Button->new( ... );
 $button->SetFont( $fonts->para_text_1 );

 ### Set larger, bold text on a label
 $label = Wx::StaticText->new( ... );
 $label->SetFont( $fonts->bold_para_text_2 );

=head1 DESCRIPTION

Provides generic font names, so your app can use those generic names, and you 
can then edit this module later and customize what those names mean without 
having to change every spot in your code that's accessing a font.

=head1 PROVIDED FONTS

=over 2

=item * Paragraph text - variable width, sans-serif

The point size increases as the number increases; eg para_text_2 is B<larger> 
than para_text_1.

=over 4

=item * para_text_1

=item * para_text_2

=item * para_text_3

=item * bold_para_text_1

=item * bold_para_text_2

=item * bold_para_text_3

=back

=item * Modern text - fixed width, serif

Use this anywhere you'd use a E<lt>preE<gt> tag.

=over 4

=item * modern_text_1

=item * modern_text_2

=item * modern_text_3

=item * bold_modern_text_1

=item * bold_modern_text_2

=item * bold_modern_text_3

=back

=item * Headers - same face as the para text fonts, but larger and bolded

With the headers (unlike with the para_ or modern_ fonts), as the number 
increases, the point size b<decreases>.  This is meant to be similar to 
headers in HTML (an E<lt>H1E<gt> is larger, not smaller, than an 
E<lt>H3E<gt>.)

=over 4

=item * header_1

=item * header_2

=item * header_3

=item * header_4

=item * header_5

=back

=back

=head1 AUTHOR

Jonathan D. Barton <tmtowtdi@gmail.com>

=head1 LICENSE

Copyright 2013 Jonathan D. Barton. All rights reserved.

This library is free software. You can redistribute it and/or modify it under the same terms as perl itself.

