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

* All attributes that isa either Path::Class::Dir or Path::Class::File need to allow 
  coercions from Str

* Change all instances of "use v5.10" to "use v5.14" - I'm using block packages, which 
  requires 5.14.

* I'm not in love with the modules that are determining their own root using FindBin; 
  something else should be doing that.

* TestSound works on Windows, does nothing (good or bad) on Ubuntu
  * at least it worked at some point; I dicked with things since then so I may have messed 
    it up.  Need more testing.  

* MenuItem helpstrings are also not showing up on Ubuntu (but they are on 
  windows).

## Status

Project is young, and needs the typical additions, refactorings, etc.  But what's there should run:

    $ perl bin/app.pl
    
