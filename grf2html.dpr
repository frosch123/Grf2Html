(* This file is part of Grf2Html.
 * Copyright 2007 by Christoph Elsenhans.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.unit spritelayout;
 *)
program grf2html;
{$APPTYPE CONSOLE}

uses sysutils, classes, contnrs, inifiles, grfbase, newgrf, filectrl, outputsettings;

var
   grf                                  : TObjectList;
   nfo                                  : TObjectList;
   stream                               : TFileStream;

   pattern, fn                          : string;
   search                               : TSearchRec;
   outPath                              : string;

   settings                             : TGrf2HtmlSettings;
   files                                : TStringList;

   i                                    : integer;

begin
   printAbout;
   files := parseCommandLine(settings);
   for i := 0 to files.count - 1 do
   begin
      pattern := expandFileName(files[i]);
      if findFirst(pattern, faReadOnly or faArchive, search) = 0 then
      begin
         repeat
            fn := extractFileDir(pattern) + '\' + search.name;
            write('Load "', fn, '"... ');
            try
               stream := TFileStream.create(fn, fmOpenRead);
            except
               writeln('error while reading file.');
               halt;
            end;
            grf := loadGrf(stream, settings.winPalette);
            stream.free;
            if grf = nil then writeln('invalid grf file') else
            begin
               writeln('done');
               write('Parse newgrf... ');
               nfo := parseNewgrf(grf);
               writeln('done');
               outPath := expandFilename(changeFileExt(fn, '') + '\');
               forceDirectories(outPath + 'data');
               printHtml(outPath, fn, nfo, settings);
               nfo.free;
            end;
         until findNext(search) <> 0;
      end else writeln('File not found: ', fn);
      findClose(search);
   end;
end.
