Grf2Html ReadMe

About Grf2Html:
   This tool converts TTDPatch [1] NewGrfs [2] into an easier readable html document.
   It should be capable of all(*) NewGrf features up to the date printed by the executable.

   The output is meant to debug your NewGrfs on a semantic level.
   Grf2Html is NOT meant to find syntactical errors of your NFO code. Use NfoRenum [3] instead.
   The generated HTML annotates several codes with their names. These texts are taken from the
   NewGraphicsSpecs [2] and from the source code documentation of TTDPatch [1].

   Grf2Html is published under the terms of GNU General Public License [4].

   Grf2Html makes use of PNG Delphi by Gustavo Daud [5].

(*) See sections about errors and limitations for details.


Usage:
   Run Grf2Html from a console using:
      Grf2Html [options] <inputfile>
   <inputfile>   Grf to decode. Important: Specify an encoded .grf (not a .nfo) file.
   Options:
    -h            Prints this message and exits.
    --ini <file>  Reads default values from <inifile>. Default "Grf2Html.ini".
    --nodata      Skip generation of non-html data files (images, binary included data, ...).
    -p <pal>      Specifies the palette to use in decoding: "win" or "dos"
    -v            Prints used options
    -w <width>    Aimed width for content frame in pixels.
                  Used to determine number of columns in output.
    --writeini    Prints current options to the file specified by "-ini".

   However you can as well add Grf2Html to the explorer (or similiar program of your OS) context menu for files with .grf extention.
   In that case you want probably put your default options into "Grf2Html.ini", though they perhaps already suit your needs.

   The '-nodata' switch speeds the output up a lot. It will skip the generation of any files in the "data\" directory of the output.
   The html output will still link to those files though. This is useful, if you have to decode your grf multiple times with altered
   NFO code, but unchanged images. Note that the bounding box previews of sprite layouts won't be generated either. 


Errors: What to do, if Grf2Html prints error messages into the output?
   Sometimes Grf2Html prints a list of errors into the generated html output.
   In that case Grf2Html had problems understanding the input file.
   If you do not know the source of the errors proceed in the following steps:
     1) Check the NewGrf with NfoRenum [3]. If it prints the same errors it is most likely the NewGrf's fault.
        NfoRenum's error messages will probably be more descriptive.
     2) Check if your version of Grf2Html is up-to-date and capable of understanding the newest NewGrf features, that the NewGrf might use.
        If needed update your copy of Grf2Html.
     3) Else it is probably the fault of Grf2Html.


Limitations:
 - BasicAction2s create hyperlinks to Action1 sets. They always refer to the last Action1.
   This might be wrong, if Action1s are skipped conditionally.
 - ActionB always uses the english built-in-messages. That implies that your inserted texts will not show UTF-8 encodings.

   
[1] see http://www.ttdpatch.net
[2] see http://wiki.ttdpatch.net/tiki-index.php?page=NewGraphicsSpecs
[3] see http://users.tt-forums.net/dalestan/nforenum.
[4] see file "COPYING.txt"
[5] see http://pngdelphi.sourceforge.net

