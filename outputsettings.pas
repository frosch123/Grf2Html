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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)
unit outputsettings;

interface

uses sysutils, classes, inifiles, contnrs;

type
   TGrf2HtmlSettings = record
      winPalette     : boolean;                  // true = windows palette; false = dos palette
      aimedWidth     : integer;                  // Approximated width of the output in pixels. Used to guess number of columns
      suppressData   : boolean;                  // Do not generate any data files (images, ...)
   end;

function parseCommandLine(out settings: TGrf2HtmlSettings): TStringList;

implementation

type
   TGrf2HtmlOption = class
   protected
      fCommandLine      : string;
      fIniSection       : string;
      fIniKey           : string;
      fVerboseName      : string;
      fParamDesc        : string;
      fDescription      : string;
      fFromCommandLine  : boolean;
   public
      constructor create(commandLine, iniSection, iniKey, verboseName, paramdesc, description: string);
      function readFromCommandLine(paramNr: integer): integer; virtual;
      procedure readFromIni(ini: TCustomIniFile); virtual; abstract;
      procedure saveToIni(ini: TCustomIniFile); virtual; abstract;
      procedure printVerbose; virtual;
      procedure printUsage;
      property commandLineName : string read fCommandLine;
   end;

   TGrf2HtmlOptionSetOnly = class(TGrf2HtmlOption)
   private
      fValue              : ^boolean;
   public
      constructor create(var value: boolean; commandLine, iniSection, iniKey, verboseName, paramdesc, description: string);
      function readFromCommandLine(paramNr: integer): integer; override;
      procedure readFromIni(ini: TCustomIniFile); override;
      procedure saveToIni(ini: TCustomIniFile); override;
      procedure printVerbose; override;
   end;

   TGrf2HtmlOptionInteger = class(TGrf2HtmlOption)
   private
      fValue              : ^integer;
      fMin, fMax          : integer;
   public
      constructor create(var value: integer; commandLine, iniSection, iniKey, verboseName: string; default, min, max: integer; paramdesc, description: string);
      function readFromCommandLine(paramNr: integer): integer; override;
      procedure readFromIni(ini: TCustomIniFile); override;
      procedure saveToIni(ini: TCustomIniFile); override;
      procedure printVerbose; override;
   end;

   TGrf2HtmlOptionString = class(TGrf2HtmlOption)
   private
      fValue              : ^string;
   public
      constructor create(var value: string; commandLine, iniSection, iniKey, verboseName, default, paramdesc, description: string);
      function readFromCommandLine(paramNr: integer): integer; override;
      procedure readFromIni(ini: TCustomIniFile); override;
      procedure saveToIni(ini: TCustomIniFile); override;
      procedure printVerbose; override;
   end;

   TGrf2HtmlOptionPalette = class(TGrf2HtmlOption)
   private
      fValue              : ^boolean;
   public
      constructor create(var value: boolean; commandLine, iniSection, iniKey, verboseName: string; default: boolean; paramdesc, description: string);
      function readFromCommandLine(paramNr: integer): integer; override;
      procedure readFromIni(ini: TCustomIniFile); override;
      procedure saveToIni(ini: TCustomIniFile); override;
      procedure printVerbose; override;
   end;


constructor TGrf2HtmlOption.create(commandLine, iniSection, iniKey, verboseName, paramdesc, description: string);
begin
   inherited create;
   fCommandLine := commandLine;
   fIniSection := iniSection;
   fIniKey := iniKey;
   fVerboseName := verboseName;
   fParamDesc := paramdesc;
   fDescription := description;
   fFromCommandLine := false;
end;

function TGrf2HtmlOption.readFromCommandLine(paramNr: integer): integer;
begin
   if fFromCommandLine then writeln(fCommandLine, ' multiple times defined. Using last one.');
   fFromCommandLine := true;
   result := 0;
end;

procedure TGrf2HtmlOption.printUsage;
var
   i : integer;
   s : string;
begin
   if fCommandLine = '' then exit;
   write(' ', fCommandLine, ' ', fParamDesc);
   i := 1 + length(fCommandLine) + 1 + length(fParamDesc);
   if i < 19 then write(' ':(19 - i));
   s := fDescription;
   while s <> '' do
   begin
      i := pos(#13#10, s);
      if i = 0 then i := length(s) + 1;
      writeln(copy(s, 1, i - 1));
      delete(s, 1, i + 1);
      if s <> '' then write(' ':19);
   end;
end;

procedure TGrf2HtmlOption.printVerbose;
var
   i                                    : integer;
begin
   if fVerboseName = '' then exit;
   write(fVerboseName, ' ');
   for i := length(fVerboseName) to 30 do write('.');
   write(': ');
end;


constructor TGrf2HtmlOptionSetOnly.create(var value: boolean; commandLine, iniSection, iniKey, verboseName, paramdesc, description: string);
begin
   inherited create(commandLine, iniSection, iniKey, verboseName, paramDesc, description);
   fValue := @value;
   fValue^ := false;
end;

function TGrf2HtmlOptionSetOnly.readFromCommandLine(paramNr: integer): integer;
begin
   inherited readFromCommandLine(paramNr);
   fValue^ := true;
   result := 0;
end;

procedure TGrf2HtmlOptionSetOnly.readFromIni(ini: TCustomIniFile);
begin
   if fIniKey <> '' then
   begin
      if ini.readBool(fIniSection, fIniKey, false) then fValue^ := true;
   end;
end;

procedure TGrf2HtmlOptionSetOnly.saveToIni(ini: TCustomIniFile);
begin
   if fIniKey <> '' then
   begin
      ini.writeBool(fIniSection, fIniKey, fValue^);
   end;
end;

procedure TGrf2HtmlOptionSetOnly.printVerbose;
begin
   if fVerboseName = '' then exit;
   inherited printVerbose;
   if fValue^ then writeln('yes') else writeln('no');
end;


constructor TGrf2HtmlOptionInteger.create(var value: integer; commandLine, iniSection, iniKey, verboseName: string; default, min, max: integer; paramdesc, description: string);
begin
   inherited create(commandLine, iniSection, iniKey, verboseName, paramDesc, description);
   fValue := @value;
   fValue^ := default;
   fMin := min;
   fMax := max;
end;

function TGrf2HtmlOptionInteger.readFromCommandLine(paramNr: integer): integer;
var
   v                                    : integer;
begin
   result := 1;
   if paramNr > paramcount then v := low(v) else v := strToIntDef(paramStr(paramNr), low(v));
   if v = low(v) then
   begin
      write(fCommandLine, ': ', fParamDesc, ' expected.');
      if paramNr <= paramCount then writeln(' "', paramStr(paramNr), '" found.') else writeln;
      result := -1;
      exit;
   end;
   if v < fMin then
   begin
      writeln(fCommandLine, ': Ignoring too low value: ', v, '<', fMin);
      exit;
   end;
   if v > fMax then
   begin
      writeln(fCommandLine, ': Ignoring too big value: ', v, '>', fMax);
      exit;
   end;
   fValue^ := v;
   inherited readFromCommandLine(paramNr);
end;

procedure TGrf2HtmlOptionInteger.readFromIni(ini: TCustomIniFile);
var
   v                                    : integer;
begin
   if (fIniKey <> '') and not fFromCommandLine then
   begin
      v := ini.readInteger(fIniSection, fIniKey, fValue^);
      if v < fMin then
      begin
         writeln(fCommandLine, ': Ignoring too low value: ', v, '<', fMin);
         exit;
      end;
      if v > fMax then
      begin
         writeln(fCommandLine, ': Ignoring too big value: ', v, '>', fMax);
         exit;
      end;
      fValue^ := v;
   end;
end;

procedure TGrf2HtmlOptionInteger.saveToIni(ini: TCustomIniFile);
begin
   if fIniKey <> '' then
   begin
      ini.writeInteger(fIniSection, fIniKey, fValue^);
   end;
end;

procedure TGrf2HtmlOptionInteger.printVerbose;
begin
   if fVerboseName = '' then exit;
   inherited printVerbose;
   writeln(fValue^);
end;


constructor TGrf2HtmlOptionString.create(var value: string; commandLine, iniSection, iniKey, verboseName, default, paramdesc, description: string);
begin
   inherited create(commandLine, iniSection, iniKey, verboseName, paramDesc, description);
   fValue := @value;
   fValue^ := default;
end;

function TGrf2HtmlOptionString.readFromCommandLine(paramNr: integer): integer;
begin
   result := 1;
   if paramNr > paramcount then
   begin
      writeln(fCommandLine, ': ', fParamDesc, ' expected.');
      result := -1;
      exit;
   end;
   fValue^ := paramStr(paramNr);
   inherited readFromCommandLine(paramNr);
end;

procedure TGrf2HtmlOptionString.readFromIni(ini: TCustomIniFile);
begin
   if (fIniKey <> '') and not fFromCommandLine then
   begin
      fValue^ := ini.readString(fIniSection, fIniKey, fValue^);
   end;
end;

procedure TGrf2HtmlOptionString.saveToIni(ini: TCustomIniFile);
begin
   if fIniKey <> '' then
   begin
      ini.writeString(fIniSection, fIniKey, fValue^);
   end;
end;

procedure TGrf2HtmlOptionString.printVerbose;
begin
   if fVerboseName = '' then exit;
   inherited printVerbose;
   writeln('"', fValue^, '"');
end;


constructor TGrf2HtmlOptionPalette.create(var value: boolean; commandLine, iniSection, iniKey, verboseName: string; default: boolean; paramdesc, description: string);
begin
   inherited create(commandLine, iniSection, iniKey, verboseName, paramDesc, description);
   fValue := @value;
   fValue^ := default;
end;

function TGrf2HtmlOptionPalette.readFromCommandLine(paramNr: integer): integer;
var
   s                                    : string;
begin
   result := 1;
   if paramNr > paramcount then s := '' else s := paramStr(paramNr);
   if compareText(s, 'win') = 0 then fValue^ := true else
   if compareText(s, 'dos') = 0 then fValue^ := false else
   begin
      write(fCommandLine, ': "win" or "dos" expected.');
      if s <> '' then writeln(' "', s, '" found.') else writeln;
      result := -1;
      exit;
   end;
   inherited readFromCommandLine(paramNr);
end;

procedure TGrf2HtmlOptionPalette.readFromIni(ini: TCustomIniFile);
begin
   if (fIniKey <> '') and not fFromCommandLine then
   begin
      fValue^ := ini.readBool(fIniSection, fIniKey, fValue^);
   end;
end;

procedure TGrf2HtmlOptionPalette.saveToIni(ini: TCustomIniFile);
begin
   if fIniKey <> '' then
   begin
      ini.writeBool(fIniSection, fIniKey, fValue^);
   end;
end;

procedure TGrf2HtmlOptionPalette.printVerbose;
begin
   if fVerboseName = '' then exit;
   inherited printVerbose;
   if fValue^ then writeln('win') else writeln('dos');
end;


function parseCommandLine(out settings: TGrf2HtmlSettings): TStringList;
var
   options                              : TObjectList;
   o                                    : TGrf2HtmlOption;
   ini                                  : TIniFile;
   printUsage                           : boolean;
   iniName                              : string;
   verbose                              : boolean;
   writeIni                             : boolean;
   s                                    : string;
   nr, i, cnt                           : integer;
begin
   result := TStringList.create;
   s := changeFileExt(extractFilename(paramStr(0)), '.ini');
   options := TObjectList.create(true);
   options.add(TGrf2HtmlOptionSetOnly.create(printUsage           , '-h'        , ''        , ''          , ''                                    , ''       , 'Prints this message and exits.'));
   options.add(TGrf2HtmlOptionString .create(iniName              , '--ini'     , ''        , ''          , 'Inifile'    , s                      , '<file>' , 'Reads default values from <file>. Default "' + s + '".'));
   options.add(TGrf2HtmlOptionSetOnly.create(settings.suppressData, '--nodata'  , ''        , ''          , 'Skip data'                           , ''       , 'Skip generation of non-html data files'#13#10'(images, binary included data, ...).'));
   options.add(TGrf2HtmlOptionPalette.create(settings.winPalette  , '-p'        , 'Grf2Html', 'WinPalette', 'Palette'    , true                   , '<pal>'  , 'Specifies the palette to use in decoding: "win" or "dos".'));
   options.add(TGrf2HtmlOptionSetOnly.create(verbose              , '-v'        , 'Grf2Html', 'Verbose'   , ''                                    , ''       , 'Prints used options'));
   options.add(TGrf2HtmlOptionInteger.create(settings.aimedWidth  , '-w'        , 'Grf2Html', 'AimedWidth', 'Aimed width', 1000, 10, high(integer), '<width>', 'Aimed width for content frame in pixels.'#13#10'Used to determine number of columns in output.'));
   options.add(TGrf2HtmlOptionSetOnly.create(writeini             , '--writeini', ''        , ''          , 'Write inifile'                       , ''       , 'Prints current options to the file specified by "-ini".'));

   nr := 1;
   while nr <= paramCount do
   begin
      s := paramStr(nr);
      inc(nr);
      if s[1] = '-' then
      begin
         cnt := -1;
         for i := 0 to options.count - 1 do
         begin
            o := options[i] as TGrf2HtmlOption;
            if compareText(o.commandLineName, s) = 0 then
            begin
               cnt := o.readFromCommandLine(nr);
               if cnt < 0 then halt;
               break;
            end;
         end;
         if cnt < 0 then
         begin
            writeln('Unknown command-line option: ', s);
            halt;
         end;
         nr := nr + cnt;
      end else result.add(s);
   end;

   if printUsage or ((result.count = 0) and not writeIni) then
   begin
      writeln('Usage: ', extractFilename(paramStr(0)), ' [options] <inputfiles ...>');
      writeln(' <inputfile ...>   Grfs to decode. Important: Encoded .grf (not .nfo).');
      writeln;
      writeln('Options:');
      for i := 0 to options.count - 1 do (options[i] as TGrf2HtmlOption).printUsage;
      halt;
   end;

   ini := TIniFile.create(iniName);
   for i := 0 to options.count - 1 do (options[i] as TGrf2HtmlOption).readFromIni(ini);

   if writeIni then
   begin
      for i := 0 to options.count - 1 do (options[i] as TGrf2HtmlOption).saveToIni(ini);
      ini.updateFile;
   end;
   ini.free;

   if verbose then
   begin
      for i := 0 to options.count - 1 do (options[i] as TGrf2HtmlOption).printVerbose;
      writeln;
   end;

   options.free;
end;

end.
