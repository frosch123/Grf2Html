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

const
   palDos   = 0;
   palWin   = 1;

type
   TGrf2HtmlSettings = record
      palette        : integer;                  // palWin = windows palette; palDos = dos palette
      suppressData   : boolean;                  // Do not generate any data files (images, ...)
      update         : array[0..1] of integer;   // Only generate data files for sprites in this range
      range          : array[0..1] of integer;   // Only generate output for sprites in this range

      // Explicitly used widths (pixels) of columns
      linkFrameWidth           : integer;        // Width of the left frame
      action0subIndexColWidth  : integer;        // Width of the index-columns of StationSpriteLayouts, StationCustomLayouts, IndustryLayouts

      // Estimated widths (pixels) of columns for guessing a suitable number of columns
      aimedWidth               : integer;        // Approximated width of the right frame
      action0FirstColWidth     : integer;        // Estimated width of the first column of Action0s (PropertyName)
      action0ColWidth          : integer;        // Estimated width of Action0 columns with plain data
      action1ColWidth          : integer;        // Estimated minimal width of Action1 columns
      action5A12ColWidth       : integer;        // Estimated minimal width of Action5/A/12 columns
   end;

function parseCommandLine(out settings: TGrf2HtmlSettings): TStringList;
function suppressDataForSprite(const settings: TGrf2HtmlSettings; nr: integer): boolean;

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

   TGrf2HtmlOptionEnum = class(TGrf2HtmlOption)
   private
      fEnums              : TStrings; {TStringList}
      fValue              : ^integer;
   public
      constructor create(var value: integer; commandLine, iniSection, iniKey, verboseName: string; default: integer; paramdesc, description: string);
      destructor destroy; override;
      function readFromCommandLine(paramNr: integer): integer; override;
      procedure readFromIni(ini: TCustomIniFile); override;
      procedure saveToIni(ini: TCustomIniFile); override;
      procedure printVerbose; override;
      property strings: TStrings read fEnums;
   end;

   TGrf2HtmlOptionPalette = class(TGrf2HtmlOptionEnum)
   public
      constructor create(var value: integer);
      procedure readFromIni(ini: TCustomIniFile); override;
      procedure saveToIni(ini: TCustomIniFile); override;
   end;

   TGrf2HtmlOptionRange = class(TGrf2HtmlOption)
   private
      fLow, fHigh         : ^integer;
   public
      constructor create(var l, h: integer; commandLine, iniSection, iniKey, verboseName: string; defl, defh: integer; paramdesc, description: string);
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


constructor TGrf2HtmlOptionEnum.create(var value: integer; commandLine, iniSection, iniKey, verboseName: string; default: integer; paramdesc, description: string);
begin
   inherited create(commandLine, iniSection, iniKey, verboseName, paramDesc, description);
   fValue := @value;
   fValue^ := default;
   fEnums := TStringList.create;
end;

destructor TGrf2HtmlOptionEnum.destroy;
begin
   fEnums.free;
   inherited destroy;
end;

function TGrf2HtmlOptionEnum.readFromCommandLine(paramNr: integer): integer;
var
   s                                    : string;
   v, i                                 : integer;
begin
   result := 1;
   if paramNr > paramcount then s := '' else s := paramStr(paramNr);
   if s <> '' then v := fEnums.indexOf(s) else v := -1;
   if v >= 0 then fValue^ := v else
   begin
      write(fCommandLine, ': ');
      if s = '' then writeln(fParamDesc,' expected.') else writeln('"', s, '" is invalid.');
      write('Valid values: ');
      for i := 0 to fEnums.count - 1 do
      begin
         if i <> 0 then write(', ');
         write('"', fEnums[i], '"');
      end;
      writeln;
      result := -1;
      exit;
   end;
   inherited readFromCommandLine(paramNr);
end;

procedure TGrf2HtmlOptionEnum.readFromIni(ini: TCustomIniFile);
var
   s                                    : string;
   v, i                                 : integer;
begin
   if (fIniKey <> '') and not fFromCommandLine then
   begin
      s := ini.readString(fIniSection, fIniKey, fEnums[fValue^]);
      if s <> '' then v := fEnums.indexOf(s) else v := -1;
      if v >= 0 then fValue^ := v else
      begin
         writeln(fCommandLine, ': Ignoring invalid value "',s, '".');
         write('Valid values: ');
         for i := 0 to fEnums.count - 1 do
         begin
            if i <> 0 then write(', ');
            write('"', fEnums[i], '"');
         end;
         writeln;
      end;
   end;
end;

procedure TGrf2HtmlOptionEnum.saveToIni(ini: TCustomIniFile);
begin
   if fIniKey <> '' then
   begin
      ini.writeString(fIniSection, fIniKey, fEnums[fValue^]);
   end;
end;

procedure TGrf2HtmlOptionEnum.printVerbose;
begin
   if fVerboseName = '' then exit;
   inherited printVerbose;
   writeln(fEnums[fValue^]);
end;


constructor TGrf2HtmlOptionPalette.create(var value: integer);
begin
   inherited create(value, '-p', 'Grf2Html', 'Palette', 'Palette', palWin, '<pal>', 'Specifies the palette to use in decoding: "win" or "dos".');
   strings.add('dos');
   strings.add('win');
end;

procedure TGrf2HtmlOptionPalette.readFromIni(ini: TCustomIniFile);
begin
   if (fIniKey <> '') and not fFromCommandLine then
   begin
      if ini.valueExists('Grf2Html', 'WinPalette') then
      begin
         // Compatibility to older versions of Grf2Html
         if ini.readBool('Grf2Html', 'WinPalette', fValue^ = palWin) then fValue^ := palWin else fValue^ := palDos;
      end else inherited readFromIni(ini);
   end;
end;

procedure TGrf2HtmlOptionPalette.saveToIni(ini: TCustomIniFile);
begin
   // Remove value of older versions of Grf2Html
   ini.deleteKey('Grf2Html', 'WinPalette');
   inherited saveToIni(ini);
end;


constructor TGrf2HtmlOptionRange.create(var l, h: integer; commandLine, iniSection, iniKey, verboseName: string; defl, defh: integer; paramdesc, description: string);
begin
   inherited create(commandLine, iniSection, iniKey, verboseName, paramDesc, description);
   fLow := @l;
   fHigh := @h;
   fLow^ := defl;
   fHigh^ := defh;
end;

function TGrf2HtmlOptionRange.readFromCommandLine(paramNr: integer): integer;
var
   s                                    : string;
   i                                    : integer;
   v1, v2                               : integer;
begin
   result := 1;
   if paramNr > paramcount then s := '' else s := paramStr(paramNr);
   i := pos(':', s);
   if i = 0 then
   begin
      result := -1;
      writeln(fCommandLine, ': Invalid range "', s, '"');
      exit;
   end;
   v1 := strToIntDef(copy(s, 1, i - 1), -1);
   v2 := strToIntDef(copy(s, i + 1, length(s)), -1);
   if (v1 < 0) or (v1 > v2) then
   begin
      result := -1;
      writeln(fCommandLine, ': Invalid range "', s, '"');
      exit;
   end;
   fLow^ := v1;
   fHigh^ := v2;
   inherited readFromCommandLine(paramNr);
end;

procedure TGrf2HtmlOptionRange.readFromIni(ini: TCustomIniFile);
var
   v1, v2                               : integer;
begin
   if (fIniKey <> '') and not fFromCommandLine then
   begin
      v1 := ini.readInteger(fIniSection, fIniKey + '_from', fLow^);
      v2 := ini.readInteger(fIniSection, fIniKey + '_to', fHigh^);
      if (v1 < 0) or (v1 > v2) then
      begin
         writeln(fCommandLine, ': Invalid range ', v1, ' to ', v2);
         exit;
      end;
      fLow^ := v1;
      fHigh^ := v2;
   end;
end;

procedure TGrf2HtmlOptionRange.saveToIni(ini: TCustomIniFile);
begin
   if fIniKey <> '' then
   begin
      ini.writeInteger(fIniSection, fIniKey + '_from', fLow^);
      ini.writeInteger(fIniSection, fIniKey + '_to', fHigh^);
   end;
end;

procedure TGrf2HtmlOptionRange.printVerbose;
begin
   if fVerboseName = '' then exit;
   if (fLow^ = 0) and (fHigh^ = high(integer)) then exit; // Skip if default setting.
   inherited printVerbose;
   writeln(fLow^, ' to ', fHigh^);
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
   s := changeFileExt(paramStr(0), '.ini');
   options := TObjectList.create(true);

   options.add(TGrf2HtmlOptionSetOnly.create(printUsage           , '-h'        , ''        , ''          , ''                                    , ''       , 'Prints this message and exits.'));
   options.add(TGrf2HtmlOptionString .create(iniName              , '--ini'     , ''        , ''          , 'Inifile'    , s                      , '<file>' , 'Reads default values from <file>. Default "' + extractFileName(s) + '".'));
   options.add(TGrf2HtmlOptionSetOnly.create(settings.suppressData, '--nodata'  , ''        , ''          , 'Skip data'                           , ''       , 'Skip generation of non-html data files'#13#10'(images, binary included data, ...).'));
   options.add(TGrf2HtmlOptionPalette.create(settings.palette));
   options.add(TGrf2HtmlOptionRange  .create(settings.range[0], settings.range[1], '-r', '' , ''          , 'Range'      , 0, high(integer)       , '<first>:<last>', 'Only generate output for a range of spritenumbers.'));
   options.add(TGrf2HtmlOptionRange  .create(settings.update[0], settings.update[1], '-u', '' , ''        , 'Updaterange', 0, high(integer)       , '<first>:<last>', 'Only generate non-html data files in a range of sprites.'#13#10'Behaves like ''--nodata'' for sprites outside of the range.'));
   options.add(TGrf2HtmlOptionSetOnly.create(verbose              , '-v'        , 'Grf2Html', 'Verbose'   , ''                                    , ''       , 'Prints used options'));
   options.add(TGrf2HtmlOptionInteger.create(settings.aimedWidth  , '-w'        , 'Grf2Html', 'AimedWidth', 'Aimed width', 1000, 10, high(integer), '<width>', 'Aimed width for content frame in pixels.'#13#10'Used to determine number of columns in output.'));
   options.add(TGrf2HtmlOptionSetOnly.create(writeini             , '--writeini', ''        , ''          , 'Write inifile'                       , ''       , 'Prints current options to the file specified by "-ini".'));

   options.add(TGrf2HtmlOptionInteger.create(settings.linkFrameWidth, ''        , 'Format'  , 'LinkFrameWidth',          '', 200, 1, high(integer), '', ''));
   options.add(TGrf2HtmlOptionInteger.create(settings.action0subIndexColWidth, '', 'Format' , 'Action0SubIndexColWidth', '',  30, 1, high(integer), '', ''));

   options.add(TGrf2HtmlOptionInteger.create(settings.action0FirstColWidth, '',   'Format'  , 'Action0FirstColWidth',    '', 300, 1, high(integer), '', ''));
   options.add(TGrf2HtmlOptionInteger.create(settings.action0ColWidth, '',        'Format'  , 'Action0ColWidth',         '', 100, 10, high(integer), '', ''));
   options.add(TGrf2HtmlOptionInteger.create(settings.action1ColWidth, '',        'Format'  , 'Action1ColWidth',         '', 110, 10, high(integer), '', ''));
   options.add(TGrf2HtmlOptionInteger.create(settings.action5A12ColWidth, '',     'Format'  , 'Action5A12ColWidth',      '', 100, 10, high(integer), '', ''));

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

   if printUsage or ((result.count = 0) and not writeIni and not verbose) then
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

function suppressDataForSprite(const settings: TGrf2HtmlSettings; nr: integer): boolean;
begin
   result := settings.suppressData or (nr < settings.update[0]) or (nr > settings.update[1]);
end;

end.
