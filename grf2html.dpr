(* This file is part of Grf2Html.
 * Copyright 2007-2010 by Christoph Elsenhans.
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)
program grf2html;

{$IFNDEF FPC}
   {$APPTYPE CONSOLE}
{$ENDIF}

uses
  sysutils,
  classes,
  contnrs,
{$IFNDEF FPC}
  filectrl,
{$ENDIF}
  tables in 'tables.pas',
  grfbase in 'grfbase.pas',
  nfoact0 in 'nfoact0.pas',
  nfoact5A12 in 'nfoact5A12.pas',
  nfoact123 in 'nfoact123.pas',
  nfoact in 'nfoact.pas',
  nfobase in 'nfobase.pas',
  outputsettings in 'outputsettings.pas',
  spritelayout in 'spritelayout.pas',
  htmlwriter in 'htmlwriter.pas',
  osspecific in 'osspecific.pas';

var
   grf                                  : TObjectList;
   nfo                                  : TNewGrfFile;
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
            fn := extractFileDir(pattern) + directorySeparator + search.name;
            write('Load "', fn, '"... ');
            try
               stream := TFileStream.create(fn, fmOpenRead or fmShareDenyWrite);
            except
               writeln('error while reading file.');
               halt;
            end;
            grf := loadGrf(stream, settings.palette = palWin);
            stream.free;
            if grf = nil then writeln('invalid grf file') else
            begin
               writeln('done');
               write('Parse newgrf... ');
               nfo := TNewGrfFile.create(extractFileName(fn), grf);
               writeln('done');
               outPath := trim(settings.outputPath);
               if outPath = '' then
               begin
                  outPath := expandFilename(changeFileExt(fn, '') + directorySeparator);
               end else
               begin
                  outPath := expandFilename(outPath) + directorySeparator + extractFileName(changeFileExt(fn, '')) + directorySeparator;
               end;
               forceDirectories(outPath + 'data');
               nfo.printHtml(outPath, settings);
               nfo.free;
            end;
         until findNext(search) <> 0;
      end else writeln('File not found: ', pattern);
      findClose(search);
   end;
end.
