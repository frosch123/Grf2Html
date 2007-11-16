Grf2Html ReadMe


Contents:
 1 - About Grf2Html
 2 - Installation
 3 - Obtaining the source code
 4 - Usage
 5 - Errors: What to do, if Grf2Html prints error messages into the output?
 6 - Limitations
 7 - Notes


1) About Grf2Html:
   This tool converts TTDPatch [1] NewGrfs [2] into an easier readable html document.
   It should be capable of all(*) NewGrf features up to the date printed by the executable.

   The output is meant to debug your NewGrfs on a semantic level.
   Grf2Html is NOT meant to find syntactical errors of your NFO code. Use NfoRenum [3] instead.
   The generated HTML annotates several codes with their names. These texts are taken from the
   NewGraphicsSpecs [2] and from the source code documentation of TTDPatch [1].

   Grf2Html is published under the terms of GNU General Public License [4].

   The windows version of Grf2Html makes use of PNG Delphi by Gustavo Daud [5].

(*) See sections 5 and 6 about errors and limitations for details.


2) Installation:
   Download the binary build for your operating system from
      http://www.tt-forums.net/viewtopic.php?f=26&t=34279
   and extract it to your favorite location.
   About the usage proceed with section 4.


3) Compiling:
   If you do not want to use the above binaries but want to compile Grf2Html yourself, these are your steps.
   You can compile Grf2Html either on windows with Delphi or with Free Pascal on several operating systems,
   though compiling with Free Pascal is only tested on linux.

3.1) Compiling on windows with Delphi:
   You need:
     1) Delphi 5 or newer.
     2) A resource compiler. Usally "brcc32.exe" in your delphi\bin directory.
     3) A SubVersion (svn) client to get the source.
     4) PngDelphi by Gustavo Daud. Either from sourceforge [5] or from
           svn://dumbledore.zernebok.com/projects/3rdparty/pngdelphi
     5) If your binary should work on older windows versions (like 98) you need the fix for PngDelphi from
           http://sourceforge.net/tracker/index.php?func=detail&aid=1559286&group_id=16012&atid=116012
     6) Grf2Html source from
           svn://dumbledore.zernebok.com/projects/grf2html
   To build Grf2Html proceed in these steps:
     1) Apply the fix for PngDelphi if needed.
     2) Compile the resource files in the Grf2Html source directory. I.e. run from console:
           brcc32.exe grfbase.rc
           brcc32.exe tables.rc
        Typically the .rc extention is associated to brcc32 in explorer.
     3) Open "grf2html.dpr" with Delphi.
     4) Specify the location of PngDelphi. Depending on your Delphi version/language somewhere like
           Menu->Project->Options->Directories->SearchPath
     5) Press compile.
     6) Optionally run "grf2html --writeini" to create the default ini-file, that is bundled with the normal win32 build.

3.2) Compiling on linux with Free Pascal:
   You need:
     1) Free Pascal (fpc). Should be a package of your linux distribution.
     2) A resource compiler. Usally "windres", part of GNU binutils (though not always in the default build) or of mingw.
     3) A SubVersion (svn) client to get the source.
     4) libpng.
     5) Grf2Html source from
           svn://dumbledore.zernebok.com/projects/grf2html
   To build Grf2Html proceed in these steps:
     1) Adjust "Makefile" so it finds "windres". (In mingw it is named different)
     2) Run "make".
     3) Optionally run "./grf2html --writeini" to create the default ini-file, that is bundled with the normal binary.

4) Usage:
   Run Grf2Html from a console using:
      grf2html [options] <inputfiles ...>
   <inputfile ...>   Grfs to decode. Important: Specify an encoded .grf (not a .nfo).
   Options:
    -h               Prints this message and exits.
    --ini <file>     Reads default values from <file>. Default "grf2html.ini".
    --nodata         Skip generation of non-html data files (images, binary included data, ...).
    -p <pal>         Specifies the palette to use in decoding: "win" or "dos".
    -v               Prints used options
    -w <width>       Aimed width for content frame in pixels. Used to determine number of columns in output.
    --writeini       Prints current options to the file specified by "-ini".

   However you can as well add Grf2Html to the explorer (or similiar program of your OS) context menu for files with .grf extention.
   In that case you want probably put your default options into "grf2html.ini", though they perhaps already suit your needs.

   IMPORTANT:
   Depending on your operating- and file-system decoding a NewGrf can take some time. This is because Grf2Html outputs a lot files.
   For example a station NewGrf typically results in some 10000 files of hardly one kilobyte each. You will notice that simply copiing
   the result to a different location will take nearly the same amount of time as generating them in the first place.
   If you run Grf2Html with the '-nodata' switch, the generation of these files is skipped.
   The html output will still link to those files though. This is useful, if you have to decode your NewGrf multiple times with altered
   NFO code, but unchanged images; or if you are not interested in the images at all. Note that the bounding box previews of sprite
   layouts won't be generated either.


5) Errors: What to do, if Grf2Html prints error messages into the output?
   Sometimes Grf2Html prints a list of errors into the generated html output.
   In that case Grf2Html had problems understanding the input file.
   If you do not know the source of the errors proceed in the following steps:
     1) Check the NewGrf with NfoRenum [3]. If it prints the same errors it is most likely the NewGrf's fault.
        NfoRenum's error messages will probably be more descriptive.
     2) Check if your version of Grf2Html is up-to-date and capable of understanding the newest NewGrf features, that the NewGrf might use.
        If needed update your copy of Grf2Html.
     3) Else it is probably the fault of Grf2Html. Post bug reports to:
           http://www.tt-forums.net/viewtopic.php?f=26&t=34279
        Your bugreport should specify the following information:
           1) Which version of Grf2Html did you use.
           2) Which NewGrf causes the error. If the NewGrf is not public available at GrfCrawler, you have to attach the NewGrf to your post.
              If you do not want to post your file there, send it per private message.
           3) A description, what failed. E.g. sprite number, what is wrong, ...


6) Limitations:
    - BasicAction2s create hyperlinks to Action1 sets. They always refer to the last Action1.
      This might be wrong, if Action1s are skipped conditionally.
    - ActionB always uses the english built-in-messages.


7) Notes:
   [1] see http://www.ttdpatch.net
   [2] see http://wiki.ttdpatch.net/tiki-index.php?page=NewGraphicsSpecs
   [3] see http://users.tt-forums.net/dalestan/nforenum.
   [4] see file "COPYING.txt"
   [5] see http://pngdelphi.sourceforge.net
