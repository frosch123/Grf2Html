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

   Grf2Html makes use of PNG Delphi by Gustavo Daud [5].

(*) See sections 5 and 6 about errors and limitations for details.


2) Installation:
   Download the win32 build from
      http://www.tt-forums.net/viewtopic.php?f=26&t=34279
   and extract it to your favorite location.
   About the usage proceed with section 4.


3) Obtaining the source code:
   If you want to compile Grf2Html yourself you need:
     1) A Delphi compiler. Version 5 or above should suffice.
     2) A resource compiler. Usally "brcc32.exe" in your delphi\bin directory.
     3) A SubVersion (svn) client to get the source.
     4) PngDelphi by Gustavo Daud. Either from sourceforge [5] or from
           svn://dumbledore.zernebok.com/projects/3rdparty/pngdelphi
     5) Grf2Html source from
           svn://dumbledore.zernebok.com/projects/grf2html
   To build Grf2Html proceed in these steps:
     1) Compile the resource files in the Grf2Html source directory. I.e. run from console:
           brcc32.exe grfbase.rc
           brcc32.exe tables.rc
     2) Open "grf2html.dpr" with Delphi.
     3) Specify the location of PngDelphi. Depending on your Delphi version/language somewhere like
           Menu->Project->Options->Directories->SearchPath
     4) Press compile.
     5) Optionally run "grf2html --writeini" to create the default ini-file, that is bundled with the normal win32 build.


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

   The '-nodata' switch speeds the output up a lot. It will skip the generation of any files in the "data\" directory of the output.
   The html output will still link to those files though. This is useful, if you have to decode your grf multiple times with altered
   NFO code, but unchanged images. Note that the bounding box previews of sprite layouts won't be generated either.


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
