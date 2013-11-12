# WaXWorks

## WxPerl Application Toolkit

* Resource Sources and Licenses (this information needs to be moved somewhere less 
  stupid).
  * Icons
    * camel_blue_grid_256.png
      * http://www.iconarchive.com/show/fs-icons-by-franksouza183/Mimetypes-text-x-perl-icon.html
      * GPL
    * folder_256.png
      * http://monolistic.deviantart.com/art/Vista-Folders-3-44410063
      * "No unlicensed/unrequested use other then personal"
    * onion_512.png
      * http://linkboss.deviantart.com/art/Faenza-alt-Perl-file-icon-244179306
      * GPL
    * shiny_camel_512.png
      * http://www.softicons.com/free-icons/toolbar-icons/programmers-pack-iii-icons-by-iconshock/perl-icon
      * Freeware
  * Sounds
    * http://home.comcast.net/~jdeshon2/joewav.html

## Things that need fixifying

* Code and documentation that need to be fixed are marked with the string "CHECK".  ack 
  for that and fix the issues.

* TestSound works on Windows, does nothing (good or bad) on Ubuntu
  * at least it worked at some point; I dicked with things since then so I may have messed 
    it up.  Need more testing.  
  * Check on this again after the switch to wxwidgets 3.0 is made.

* MenuItem helpstrings are also not showing up on Ubuntu (but they are on 
  windows).
  * Check on this again after the switch to wxwidgets 3.0 is made.

* wxwidgets 3.0 is out, and I expect wxperl to switch to using it soon.  When that 
  happens: 
  * Fix the doc link in lib/MyApp.pm
  * Test out Wx::Sound (which doesn't work in Ubuntu with 2.8)
  * Check the menuitem helpstrings.

## Status

Project is young, and needs the typical additions, refactorings, etc.  But what's there should run:

    $ perl bin/app.pl

Items in the Tools menu are meant to either help you out while you're working, or become 
part of your actual app, or both.

Items in the Examples menu are meant as merely that - examples.  Take from it what you 
will, and rip out anything you don't need.

    
