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

uses sysutils, classes, contnrs, inifiles, grfbase, newgrf, filectrl;

var
   grf                                  : TObjectList;
   nfo                                  : TObjectList;
   stream                               : TFileStream;

   ini                                  : TIniFile;

   s                                    : string;

   fn                                   : string;
   outPath                              : string;

   iniFile                              : string;
   aimedWidth                           : integer;
   palette                              : (unset, dos, win);
   suppressData                         : boolean;
   printUsage                           : boolean;
   verbose                              : boolean;
   printIni                             : boolean;

   i                                    : integer;

begin
   printAbout;

   fn := '';
   aimedWidth := -1;
   iniFile := '';
   palette := unset;
   suppressData := false;
   printUsage := false;
   verbose := false;
   printIni := false;

   i := 1;
   while (i <= paramCount) do
   begin
      s := paramStr(i);
      inc(i);
      if s[1] = '-' then
      begin
         if s = '-h' then printUsage := true else
         if s = '-v' then verbose := true else
         if s = '--writeini' then printIni := true else
         if s = '--nodata' then suppressdata := true else
         if s = '--ini' then
         begin
            if i > paramCount then
            begin
               writeln('<file> expected.');
               halt;
            end;
            if iniFile = '' then
            begin
               iniFile := paramStr(i);
               inc(i);
            end else
            begin
               writeln('Multiple ini files specified: "', paramStr(i), '".');
               halt;
            end;
         end else
         if s = '-p' then
         begin
            if i > paramCount then
            begin
               writeln('<pal> expected.');
               halt;
            end;
            if paramStr(i) = 'win' then palette := win else
            if paramStr(i) = 'dos' then palette := dos else
            begin
               writeln('Unknown palette: "', paramStr(i), '".');
               halt;
            end;
            inc(i);
         end else
         if s = '-w' then
         begin
            if i > paramCount then
            begin
               writeln('<width> expected.');
               halt;
            end;
            aimedWidth := strToIntDef(paramStr(i), -1);
            if aimedWidth <= 0 then
            begin
               writeln('Invalid width "', paramStr(i), '"');
               halt;
            end;
            inc(i);
         end else
         begin
            writeln('Unknown command line option "', s, '".');
            halt;
         end;
      end else
      begin
         if fn = '' then fn := s else
         begin
            writeln('Multiple input files specified: "', s, '".');
            halt;
         end;
      end;
   end;

   if printUsage or ((fn = '') and (not printIni)) then
   begin
      writeln('Usage: ', extractFilename(paramStr(0)), ' [options] <inputfile>');
      writeln(' <inputfile>   Grf to decode. Important: Encoded .grf (not .nfo).');
      writeln;
      writeln('Options:');
      writeln(' -h            Prints this message and exits.');
      writeln(' --ini <file>  Reads default values from <inifile>. Default "', changeFileExt(extractFilename(paramStr(0)), '.ini'), '".');
      writeln(' --nodata      Skip generation of non-html data files');
      writeln('               (images, binary included data, ...).');
      writeln(' -p <pal>      Specifies the palette to use in decoding: "win" or "dos"');
      writeln(' -v            Prints used options');
      writeln(' -w <width>    Aimed width for content frame in pixels.');
      writeln('               Used to determine number of columns in output.');
      writeln(' --writeini    Prints current options to the file specified by "-ini".');
      halt;
   end;

   if iniFile = '' then iniFile := changeFileExt(paramStr(0), '.ini');

   ini := TIniFile.create(iniFile);
   if ini.readBool('Grf2Html', 'Verbose', false) then verbose := true;
   if palette = unset then
   begin
      if ini.readBool('Grf2Html', 'WinPalette', true) then palette := win else palette := dos;
   end;
   if aimedWidth < 0 then aimedWidth := ini.readInteger('Grf2Html', 'AimedWidth', 1000);
   if aimedWidth <= 10 then aimedWidth := 1000;

   if printIni then
   begin
      ini.writeBool('Grf2Html', 'Verbose', verbose);
      ini.writeBool('Grf2Html', 'WinPalette', palette = win);
      ini.writeInteger('Grf2Html', 'AimedWidth', aimedWidth);
      ini.updateFile;
   end;
   ini.free;

   if verbose then
   begin
      write('Palette: ');
      if palette = win then writeln('win') else writeln('dos');
      writeln('AimedWidth: ', aimedWidth);
   end;

   if fn = '' then halt;

   write('Load "', fn, '"... ');
   try
      stream := TFileStream.create(fn, fmOpenRead);
   except
      writeln('file not found');
      halt;
   end;
   grf := loadGrf(stream, palette = win);
   stream.free;
   if grf = nil then
   begin
      writeln('invalid grf file');
      halt;
   end;
   writeln('done');

   write('Parse newgrf... ');
   nfo := parseNewgrf(grf);
   writeln('done');

   outPath := expandFilename(changeFileExt(fn, '') + '\');
   forceDirectories(outPath + 'data');
   printHtml(outPath, fn, nfo, aimedWidth, suppressData);
   nfo.free;
end.
