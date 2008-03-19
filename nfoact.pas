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
unit nfoact;

interface

uses sysutils, math, osspecific, grfbase, nfobase, nfoact123, tables, outputsettings;

type
   TAction4 = class(TNewGrfSprite)
   private
      fFeature        : TFeature;
      fLangID         : byte;
      fGenericStrings : boolean;
      fFirstString    : integer;
      fStrings        : array of string;
      function getNumStrings: integer;
      function getTextID(i: integer): integer;
      function getText(i: integer): string;
   public
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
      procedure useAction8(act8: TAction8); override;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property feature: TFeature read fFeature;
      property langID: byte read fLangID;
      property genericStrings: boolean read fGenericStrings;
      property numStrings: integer read getNumStrings;
      property textID[i: integer]: integer read getTextID;
      property text[i: integer]: string read getText;
   end;

   TAction6 = class(TNewGrfSprite)
   private
      fParams  : array of byte;
      fSizes   : array of byte;
      fAdd     : array of boolean;
      fOffsets : array of word;
      function getCount: integer;
      function getParam(i: integer): byte;
      function getParamSize(i: integer): byte;
      function getParamAdd(i: integer): boolean;
      function getOffset(i: integer): integer;
   public
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property count: integer read getCount;
      property param[i: integer]: byte read getParam;
      property paramSize[i: integer]: byte read getParamSize;
      property paramAdd[i: integer]: boolean read getParamAdd;
      property offset[i: integer]: integer read getOffset;
   end;

   TAction79 = class(TNewGrfSprite)
   private
      fVariable    : byte;
      fVarSize     : byte;
      fCondition   : byte;
      fValue       : int64;
      fSkip        : byte;
      fDestination : TSprite;
   public
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property variable: byte read fVariable;
      property varSize: byte read fVarSize;
      property condition: byte read fCondition;
      property value: int64 read fValue;
      property skip: byte read fSkip; // Unmodified value from the grf
      property destination: TSprite read fDestination write fDestination; // Destination Sprite (incl. label dereferencing), nil = end of file
   end;

   TAction7 = class(TAction79)
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
   end;

   TAction9 = class(TAction79)
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
   end;

   TActionB = class(TNewGrfSprite)
   private
      fSeverity         : byte;
      fDuringInit       : boolean;
      fLangID           : byte;
      fMsgID            : byte;
      fMsg              : string;
      fData             : string;
      fParam0, fParam1  : byte;
   public
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
      procedure useAction8(act8: TAction8); override;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property severity: byte read fSeverity;
      property duringInit: boolean read fDuringInit;
      property langID: byte read fLangID;
      property msgID: byte read fMsgID;
      property msg: string read fMsg;
      property data: string read fData;
      property param0: byte read fParam0;
      property param1: byte read fParam1;
   end;

   TActionC = class(TNewGrfSprite)
   private
      fComment: string;
   public
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property comment: string read fComment;
   end;

   TActionDType = (normal, readFromOtherGrf, readPatchVars, GRM);
   TActionD = class(TNewGrfSprite)
   private
      fTarget: byte;
      fOperator: byte;
      fDefined: boolean;
      fSource1: byte;
      fSource2: byte;
      fData: longword;
      fType: TActionDType;
   public
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      // TODO props
   end;

   TActionE = class(TNewGrfSprite)
   private
      fGrfIDs : array of longword;
      fForce  : boolean;
      function getDisableCount: integer;
      function getDisableGrf(i: integer): longword;
   public
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
      procedure useAction8(act8: TAction8); override;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property forceActivated: boolean read fForce;
      property disableCount: integer read getDisableCount;
      property disableGrf[i: integer]: longword read getDisableGrf; // grfs to disable or force-activate
   end;

   TActionF = class;
   TActionFTable = array[0..127] of TActionF;
   TTownNamePartChoice = record
      prob       : byte;
      typ        : (newText, oldPart);
      text       : string;
      part       : byte;
      partDest   : TActionF;
   end;
   TTownNamePart = record
      firstBit   : byte;
      bitCount   : byte;
      choices    : array of TTownNamePartChoice;
      probSum    : integer;
   end;
   TActionF = class(TNewGrfSprite)
   private
      fID         : byte;
      fFinal      : boolean;
      fFinalLangs : array of byte;
      fFinalNames : array of string;
      fParts      : array of TTownNamePart;
      function getFinalNameCount: integer;
      function getFinalNameLang(i: integer): byte;
      function getFinalName(i: integer): string;
      function getNumParts: integer;
      function getPart(i: integer): TTownNamePart;
   public
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader; var actionFTable: TActionFTable);
      procedure useAction8(act8: TAction8); override;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property ID: byte read fID;
      property finalDefinition: boolean read fFinal;
      property finalNameCount: integer read getFinalNameCount;
      property finalNameLang[i: integer]: byte read getFinalNameLang;
      property finalName[i: integer]: string read getFinalName;
      property numParts: integer read getNumParts;
      property part[i: integer]: TTownNamePart read getPart;
   end;

   TAction10 = class(TNewGrfSprite)
   private
      fLabelNr: byte;
      fComment: string;
   public
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property labelNr: byte read fLabelNr;
      property comment: string read fComment;
   end;

   TWaveFormat = record
      channels  : word; {1 = mono, 2 = stereo, ... }
      sampleRate: longword; {Hz}
      resolution: word; {byte per channel and sample}
   end;
   TWaveFile = class(TNewGrfSprite)
   private
      fName        : string;
      fData        : array of byte;
      fFormat      : TWaveFormat;
      fSoundStart  : integer;
      fSampleCount : integer;
      function getSize: integer;
      function getData: pointer;
      function getSoundData: pointer;
   public
      constructor create(aNewGrfFile: TNewGrfFile; bin: TBinaryIncludeSprite);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property name: string read fName write fName;

      property size: integer read getSize; {raw file data}
      property data: pointer read getData;

      property format: TWaveFormat read fFormat;
      property sampleCount: integer read fSampleCount;
      property soundData: pointer read getSoundData; {only the samples}
   end;

   TAction11 = class;
   TSoundImport = class(TNewGrfSprite)
   private
      fParent   : TAction11;
      fGrfID    : longword;
      fSoundNr  : word;
   public
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader; parent: TAction11);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property action11: TAction11 read fParent;
      property grfID: longword read fGrfID;
      property soundNr: word read fSoundNr;
   end;

   TAction11 = class(TMultiSpriteAction)
   private
      fSubSpriteCount: integer;
   protected
      function getSubSpriteCount: integer; override;
   public
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
      function processSubSprite(i: integer; s: TSprite): TSprite; override;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
   end;

   TAction13 = class(TNewGrfSprite)
   private
      fFeature  : TFeature;
      fGrfID    : longword;
      fFirstID  : word;
      fTexts    : array of string;
      function getNumTexts: integer;
      function getTextID(i: integer): word;
      function getText(i: integer): string;
   public
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property grfID: longword read fGrfID;
      property feature: TFeature read fFeature;
      property numTexts: integer read getNumTexts;
      property textID[i: integer]: word read getTextID;
      property text[i: integer]: string read getText;
   end;

implementation

function getLanguageName(act8: TAction8; langID: byte): string;
begin
   if act8 = nil then result := ' (unknown because of missing Action8)' else
   begin
      if act8.grfVersion >= 7 then result := ' "' + TableLanguage[langID] + '"' else
      begin
         result := '';
         if langID and $01 <> 0 then result := result + ' "American"';
         if langID and $02 <> 0 then result := result + ' "English"';
         if langID and $04 <> 0 then result := result + ' "German"';
         if langID and $08 <> 0 then result := result + ' "French"';
         if langID and $10 <> 0 then result := result + ' "Spanish"';
         if result = '' then result := ' (no languages selected)';
      end;
   end;
end;

function getAction79DVariable(variable: byte): string;
begin
   result := '0x' + intToHex(variable, 2) + ' ';
   if variable < $80 then result := result + '"Parameter ' + intToStr(variable) + '"' else
                          result := result + '"' + TableVariables[variable - $80] + '"';
end;


constructor TAction4.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
var
   i                                    : integer;
begin
   inherited create(aNewGrfFile, ps.spriteNr);
   assert(ps.peekByte = $04);
   ps.getByte;
   fFeature := ps.getByte;
   fLangID := ps.getByte;
   fGenericStrings := (fLangID and $80) <> 0;
   fLangID := fLangID and $7F;
   setLength(fStrings, ps.getByte);
   if fGenericStrings then fFirstString := ps.getWord else fFirstString := ps.getByte;
   for i := 0 to length(fStrings) - 1 do fStrings[i] := ps.getString;
   testSpriteEnd(ps);
end;

function TAction4.getNumStrings: integer;
begin
   result := length(fStrings);
end;

function TAction4.getTextID(i: integer): integer;
begin
   result := fFirstString + i;
end;

function TAction4.getText(i: integer): string;
begin
   if (i >= 0) and (i < length(fStrings)) then result := fStrings[i] else result := '';
end;

procedure TAction4.useAction8(act8: TAction8);
begin
   inherited useAction8(act8);
   if act8 = nil then error('No Action8 found. LanguageID not interpretable.');
end;

procedure TAction4.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   s                                    : string;
   i                                    : integer;
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>Action4</b> - Define custom texts');
   writeln(t, '<table summary="Properties">');
   if fFeature = $48 then s := 'generic string' else s := TableFeature[fFeature];
   writeln(t, '<tr><th align="left">Feature</th><td>0x', intToHex(fFeature, 2), ' "', s, '"</td></tr>');
   writeln(t, '<tr><th align="left">Language</th><td>0x', intToHex(fLangID, 2), getLanguageName(fAction8, fLangID), '</td></tr>');
   for i := 0 to length(fStrings) - 1 do
   begin
      if fGenericStrings then s := intToHex(textID[i], 4) else s := intToHex(textID[i], 2);
      writeln(t, '<tr><th align="left">Text 0x', s, '</th><td>', formatTextPrintable(fStrings[i], true), '</td></tr>');
   end;
   writeln(t, '</table>');
end;


constructor TAction6.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
var
   count                                : integer;
   tmp                                  : byte;
begin
   inherited create(aNewGrfFile, ps.spriteNr);
   assert(ps.peekByte = $06);
   ps.getByte;
   setLength(fParams, 0);
   setLength(fAdd, 0);
   setLength(fSizes, 0);
   setLength(fOffsets, 0);
   count := 0;
   repeat
      tmp := ps.getByte;
      if tmp <> $FF then
      begin
         setLength(fParams, count + 1);
         setLength(fAdd, count + 1);
         setLength(fSizes, count + 1);
         setLength(fOffsets, count + 1);
         fParams[count] := tmp;
         fAdd[count] := (ps.peekByte and $80) <> 0;
         fSizes[count] := ps.getByte and $7F;
         fOffsets[count] := ps.getExtByte;
         inc(count);
      end;
   until (tmp = $FF) or (ps.bytesLeft < 0);
   testSpriteEnd(ps);
end;

function TAction6.getCount: integer;
begin
   result := length(fParams);
end;

function TAction6.getParam(i: integer): byte;
begin
   result := fParams[i];
end;

function TAction6.getParamSize(i: integer): byte;
begin
   result := fSizes[i];
end;

function TAction6.getParamAdd(i: integer): boolean;
begin
   result := fAdd[i];
end;

function TAction6.getOffset(i: integer): integer;
begin
   result := fOffsets[i];
end;

procedure TAction6.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   i                                    : integer;
   s                                    : string;
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>Action6</b> - Override bytes in following sprite with parameter, if parameter is defined');
   writeln(t, '<table summary="Properties" border="1" rules="all"><tr><th>Parameter</th><th>Operation</th><th>Number of Bytes</th><th>Offset</th></tr>');
   for i := 0 to length(fParams) - 1 do
   begin
      if fAdd[i] then s := 'add' else s := 'override';
      writeln(t, '<tr><td>0x', intToHex(fParams[i], 2), ' (', fParams[i], ')</td><td>', s, '</td><td>', fSizes[i], '</td><td>0x', intToHex(fOffsets[i], 4), ' (', fOffsets[i], ')</td></tr>');
   end;
   writeln(t, '</table>');
end;


constructor TAction79.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
var
   i                                    : integer;
begin
   inherited create(aNewGrfFile, ps.spriteNr);
   fVariable := ps.getByte;
   fVarSize := ps.getByte;
   fCondition := ps.getByte;
   if fCondition < 2 then fValue := ps.getByte else
   begin
      // Note: value is unsigned
      fValue := 0;
      for i := 0 to fVarSize - 1 do fValue := fValue or (ps.getByte shl (8 * i));
   end;
   fSkip := ps.getByte;
   testSpriteEnd(ps);
end;

procedure TAction79.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   s                                    : string;
   g                                    : string[4];
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>', getShortDesc, '</b> - Skip sprites conditionally');
   writeln(t, '<table summary="Properties">');
   if fCondition in [$0B, $0C] then s := '0x' + intToHex(fVariable, 2) + ' (ignored)' else
                                    s := getAction79DVariable(fVariable);
   writeln(t, '<tr><th align="left">Variable</th><td>', s, '</td></tr>');
   writeln(t, '<tr><th align="left">Size</th><td>', intToStr(fVarSize), '</td></tr>');
   writeln(t, '<tr><th align="left">Condition</th><td>0x', intToHex(fCondition, 2), ' "', TableAction79Condition[fCondition], '"</td></tr>');
   case fCondition of
    $00, $01: s := 'bit ' + intToStr(fValue);
    $0B, $0C: begin
                 // cargo label
                 g := char(fValue and $FF) + char((fValue shr 8) and $FF) + char((fValue shr 16) and $FF) + char((fValue shr 24) and $FF);
                 s := '0x' + intToHex(ord(g[1]), 2) +
                     ' 0x' + intToHex(ord(g[2]), 2) +
                     ' 0x' + intToHex(ord(g[3]), 2) +
                     ' 0x' + intToHex(ord(g[4]), 2) + ' (' + formatTextPrintable(g, false) + ')';
              end;
         else if fVariable = $88 then
              begin
                 s := grfID2Str(fValue and $FFFFFFFF);
                 if fVarSize = 8 then
                 begin
                    g := char((fValue shr 32) and $FF) + char((fValue shr 40) and $FF) + char((fValue shr 48) and $FF) + char((fValue shr 56) and $FF);
                    s := 'base ' + s + '  mask 0x' + intToHex(ord(g[1]), 2) +
                                             ' 0x' + intToHex(ord(g[2]), 2) +
                                             ' 0x' + intToHex(ord(g[3]), 2) +
                                             ' 0x' + intToHex(ord(g[4]), 2);
                 end else s := 'grfid ' + s;
              end else s := '0x' + intToHex(fValue, fVarSize * 2) + ' (' + intToStr(fValue) + ')';
   end;
   writeln(t, '<tr><th align="left">Value</th><td>', s, '</td></tr>');

   if fDestination = nil then
   begin
      if fSkip = 0 then s := 'to end of file' else s := intToStr(skip) + ' sprites (end of file)';
   end else
   begin
      if (fDestination is TAction10) and ((fDestination as TAction10).labelNr = fSkip) then
      begin
         s := 'to label 0x' + intToHex(fSkip, 2);
      end else
      begin
         s := intToStr(fSkip) + ' sprites';
      end;
      s := s + ' (to ' + fDestination.printHtmlSpriteLink('content') + ')';
   end;
   writeln(t, '<tr><th align="left">Skip</th><td>', s, '</td></tr></table>');
end;


constructor TAction7.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
begin
   assert(ps.peekByte = $07);
   ps.getByte;
   inherited create(aNewGrfFile, ps);
end;


constructor TAction9.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
begin
   assert(ps.peekByte = $09);
   ps.getByte;
   inherited create(aNewGrfFile, ps);
end;


constructor TActionB.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
var
   dataNum                              : integer;
   paramNum                             : integer;
   i                                    : integer;
begin
   inherited create(aNewGrfFile, ps.spriteNr);
   assert(ps.peekByte = $0B);
   ps.getByte;
   fDuringInit := (ps.peekByte and $80) <> 0;
   fSeverity := ps.getByte and $7F;
   fLangID := ps.getByte;
   fMsgID := ps.getByte;
   if fMsgID = $FF then fMsg := ps.getString else
   begin
      fMsg := TableActionBMessage[fMsgID];
      while pos('0x80', fMsg) <> 0 do
      begin
         i := pos('0x80', fMsg);
         delete(fMsg, i, 3);
         fMsg[i] := #$80;
      end;
      while pos('0x7B', fMsg) <> 0 do
      begin
         i := pos('0x7B', fMsg);
         delete(fMsg, i, 3);
         fMsg[i] := #$7B;
      end;
   end;
   dataNum := 0;
   paramNum := 0;
   for i := 1 to length(fMsg) do
   begin
      if fMsg[i] = #$80 then
      begin
         inc(dataNum);
         if paramNum <> 0 then error('ActionB message: Found 0x80 after 0x7B');
         if dataNum = 2 then fData := ps.getString;
         if dataNum > 2 then error('ActionB message: More than two 0x80 found');
      end;
      if fMsg[i] = #$7B then
      begin
         inc(paramNum);
         if dataNum <> 2 then error('ActionB message: Found 0x7B before two 0x80');
         if paramNum = 1 then fParam0 := ps.getByte;
         if paramNum = 2 then fParam1 := ps.getByte;
         if paramNum > 2 then error('ActionB message: More than two 0x7B found');
      end;
   end;
   testSpriteEnd(ps);
end;

procedure TActionB.useAction8(act8: TAction8);
begin
   inherited useAction8(act8);
   if act8 = nil then error('No Action8 found. LanguageID not interpretable.');
end;

procedure TActionB.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   s, s2, s3                            : string;
   i                                    : integer;
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>ActionB</b> - Generate error message');
   writeln(t, '<table summary="Properties">');
   if fDuringInit then s := 'yes' else s := 'no';
   writeln(t, '<tr><th align="left">Process during initialization</th><td>', s, '</td></tr>');
   s := TableActionBSeverity[fSeverity, 0];
   s2 := TableActionBSeverity[fSeverity, 1];
   writeln(t, '<tr><th align="left">Severity</th><td>0x', intToHex(fSeverity, 2), ' "', s, '"</td></tr>');
   writeln(t, '<tr><th align="left">Language</th><td>0x', intToHex(fLangID, 2), getLanguageName(fAction8, fLangID), '</td></tr>');
   if fMsgID = $FF then s := ' "custom message"' else s := ' "built-in message"';
   writeln(t, '<tr><th align="left">MessageID</th><td>0x', intToHex(fMsgID, 2), s, '</td></tr>');
   s2 := s2 + ' ' + fMsg;
   s2 := formatTextPrintable(s2, true);

   // Insert <filename> field
   s2 := stringReplace(s2, '&lt;0x80 ' + TableStringCode[$80] + '&gt;', '&lt;filename&gt;', []);

   // Insert <data> field
   s3 := '&lt;0x80 ' + TableStringCode[$80] + '&gt;';
   i := pos(s3, s2);
   if i <> 0 then
   begin
      s := trim(copy(s2, 1, i - 1));
      delete(s2, 1, i + length(s3) - 1);
      s2 := trim(s2);
      s3 := formatTextPrintable(fData, true);

      // TODO: s3 may start with "<UTF-8>".
      //       Though unicode is applied correctly to the single string parts,
      //       the unicode control code looks a bit missplaced in the output.
      //       What to do with it?

      // concatenate strings s + s3 + s2, but do not double "
      if (length(s) > 0) and (s[length(s)] = '"') and (s3[1] = '"') then s := copy(s, 1, length(s) - 1) + copy(s3, 2, length(s3)) else
                                                                         s := s + ' ' + s3;
      if (length(s2) > 0) and (s2[1] = '"') and (s[length(s)] = '"') then s2 := copy(s, 1, length(s) - 1) + copy(s2, 2, length(s2)) else
                                                                          s2 := s + ' ' + s2;
   end;

   // Insert params
   s2 := stringReplace(s2, '&lt;0x7B ' + TableStringCode[$7B] + '&gt;', '&lt;param 0x' + intToHex(param0, 2) + '&gt;', []);
   s2 := stringReplace(s2, '&lt;0x7B ' + TableStringCode[$7B] + '&gt;', '&lt;param 0x' + intToHex(param1, 2) + '&gt;', []);

   writeln(t, '<tr><th align="left">Message</th><td>', s2, '</td></tr></table>');
end;


constructor TActionC.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
var
   i                                    : integer;
begin
   inherited create(aNewGrfFile, ps.spriteNr);
   assert(ps.peekByte = $0C);
   ps.getByte;
   setLength(fComment, ps.bytesLeft);
   for i := 1 to length(fComment) do fComment[i] := char(ps.getByte);
end;

procedure TActionC.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>ActionC</b> - Do nothing<br><b>Comment:</b> ', formatTextPrintable(fComment, false));
end;


constructor TActionD.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
begin
   inherited create(aNewGrfFile, ps.spriteNr);
   assert(ps.peekByte = $0D);
   ps.getByte;
   fTarget := ps.getByte;
   fDefined := (ps.peekByte and $80) <> 0;
   fOperator := ps.getByte and $7F;
   fSource1 := ps.getByte;
   fSource2 := ps.getByte;
   if (fSource2 >= $FE) or (fSource1 = $FF) then fData := ps.getDWord;
   if fSource2 = $FE then
   begin
      if fData and $FF = $FF then
      begin
         if fData = $FFFF then fType := readPatchVars else fType := GRM;
      end else fType := readFromOtherGrf;
   end else fType := normal;
   testSpriteEnd(ps);
end;

procedure TActionD.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   s, d                                 : string;
   p1H, p2H, p1I, p2I, p1U, p2U         : string;
   f, c                                 : string;
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>ActionD</b> - Assign parameters and calculate results<br>');
   if fSource1 = $FF then
   begin
      p1H := '0x' + intToHex(fData, 8);
      p1I := intToStr(longint(fData));
      p1U := intToStr(fData);
   end else
   begin
      p1H := 'var[' + getAction79DVariable(fSource1) + ']';
      p1I := p1H;
      p1U := p1H;
   end;
   if fSource2 = $FF then
   begin
      p2H := '0x' + intToHex(fData, 8);
      p2I := intToStr(longint(fData));
      p2U := intToStr(fData);
   end else
   begin
      p2H := 'var[' + getAction79DVariable(fSource2) + ']';
      p2I := p2H;
      p2U := p2H;
   end;
   d := 'var[' + getAction79DVariable(fTarget) + ']';
   f := TableFeature[(fData shr 8) and $FF];
   c := intToStr(fData shr 16);
   if fDefined then d := d + ' if not defined yet';
   case fType of
      normal          : s := TableActionDOperation[fOperator];
      readFromOtherGrf: begin
                           s := TableActionDOperation[0];
                           p1H := p1H + ' from grfid ' + grfID2Str(fData);
                           p1I := p1H;
                           p1U := p1H;
                        end;
      readPatchVars   : begin
                           s := TableActionDOperation[0];
                           p1H := 'PatchVar[0x' + intToHex(fSource1, 2) + ' "' + TableActionDPatchVars[fSource1] + '"]';
                           p1I := p1H;
                           p1U := p1H;
                        end;
      GRM             : s := TableActionDGRMOperation[fSource1];
   end;
   s := stringReplace(s, '$0$' , d  , [rfReplaceAll]);
   s := stringReplace(s, '$1H$', p1H, [rfReplaceAll]);
   s := stringReplace(s, '$1I$', p1I, [rfReplaceAll]);
   s := stringReplace(s, '$1$' , p1U, [rfReplaceAll]);
   s := stringReplace(s, '$2H$', p2H, [rfReplaceAll]);
   s := stringReplace(s, '$2I$', p2I, [rfReplaceAll]);
   s := stringReplace(s, '$2$' , p2U, [rfReplaceAll]);
   s := stringReplace(s, '$3$' , f  , [rfReplaceAll]);
   s := stringReplace(s, '$4$' , c  , [rfReplaceAll]);
   writeln(t, '<b>Operation:</b> ', s);
end;


constructor TActionE.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
var
   i                                    : integer;
begin
   inherited create(aNewGrfFile, ps.spriteNr);
   assert(ps.peekByte = $0E);
   ps.getByte;
   setLength(fGrfIDs, ps.getByte);
   fForce := false;
   for i := 0 to length(fGrfIDs) - 1 do fGrfIDs[i] := ps.getDWord;
   testSpriteEnd(ps);
end;

function TActionE.getDisableCount: integer;
begin
   result := length(fGrfIDs);
end;

function TActionE.getDisableGrf(i: integer): longword;
begin
   result := fGrfIDs[i];
end;

procedure TActionE.useAction8(act8: TAction8);
var
   i                                    : integer;
begin
   inherited useAction8(act8);
   if act8 = nil then error('Missing Action8: Cannot detect force-activation');
   for i := 0 to length(fGrfIDs) - 1 do
      if fGrfIDs[i] = act8.grfID then
      begin
         fForce := true;
         break;
      end;
end;

procedure TActionE.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   i                                    : integer;
   thisGrf                              : longword;
begin
   inherited printHtml(t, path, settings);
   if fAction8 = nil then thisGrf := $FFFFFFFF else thisGrf := fAction8.grfID;
   writeln(t, '<b>ActionE</b> - Deactivate other graphics files or force activation of current file');
   write(t, '<table summary="Properties"><tr><th align="left">Force activation</th><td>');
   if fForce then write(t, 'yes: ', grfID2Str(thisGrf)) else write(t, 'no');
   writeln(t, '</td></tr><tr valign="top"><th align="left">Disable Grf IDs</th><td>');
   for i := 0 to length(fGrfIDs) - 1 do
   begin
      if i <> 0 then writeln(t, '<br>');
      if fGrfIDs[i] <> thisGrf then write(t, grfID2Str(fGrfIDs[i])) else write(t, '<i>force activation</i>');
   end;
   writeln(t, '</td></tr></table>');
end;


constructor TActionF.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader; var actionFTable: TActionFTable);
var
   i, j                                 : integer;
   tmp                                  : byte;
begin
   inherited create(aNewGrfFile, ps.spriteNr);
   assert(ps.peekByte = $0F);
   ps.getByte;
   fFinal := (ps.peekByte and $80) <> 0;
   fID := ps.getByte and $7F;
   actionFTable[fID] := self; // IDs can be reused, and they can link to themself (though this causes a infinite loop).
   setLength(fFinalLangs, 0);
   setLength(fFinalNames, 0);
   if fFinal then
   begin
      i := -1;
      repeat
         inc(i);
         tmp := ps.getByte;
         if (tmp <> $00) or (i = 0) then
         begin
            setLength(fFinalLangs, i + 1);
            setLength(fFinalNames, i + 1);
            fFinalLangs[i] := tmp and $7F;
            fFinalNames[i] := ps.getString;
         end;
      until (tmp = $00) and (i > 0);
   end;
   setLength(fParts, ps.getByte);
   for i := 0 to length(fParts) - 1 do
      with fParts[i] do
      begin
         setLength(choices, ps.getByte);
         firstBit := ps.getByte;
         bitCount := ps.getByte;
         probSum := 0;
         for j := 0 to length(choices) - 1 do
            with choices[j] do
            begin
               if (ps.peekByte and $80) <> 0 then typ := oldPart else typ := newText;
               prob := ps.getByte and $7F;
               probSum := probSum + prob;
               if typ = newText then text := ps.getString else
               begin
                  part := ps.getByte;
                  if part >= $80 then
                  begin
                     error('Link to invalid ID 0x' + intToHex(part, 2) + '. Bit 7 must not be set.');
                     partDest := nil
                  end else
                  begin
                     partDest := actionFTable[part];
                     if partDest = nil then error('Link to undefined ID 0x' + intToHex(part, 2)) else
                        if partDest = self then error('Recursive link to current ID 0x' + intToHex(part, 2));
                  end;
               end;
            end;
         if probSum = 0 then error('Sum of all probabilities is zero.');
      end;
   testSpriteEnd(ps);
end;

function TActionF.getFinalNameCount: integer;
begin
   result := length(fFinalLangs);
end;

function TActionF.getFinalNameLang(i: integer): byte;
begin
   result := fFinalLangs[i];
end;

function TActionF.getFinalName(i: integer): string;
begin
   result := fFinalNames[i];
end;

function TActionF.getNumParts: integer;
begin
   result := length(fParts);
end;

function TActionF.getPart(i: integer): TTownNamePart;
begin
   result := fParts[i];
end;

procedure TActionF.useAction8(act8: TAction8);
begin
   inherited useAction8(act8);
   if act8 = nil then error('No Action8 found. LanguageID not interpretable.');
end;

procedure TActionF.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   i, j                                 : integer;
   realProb                             : integer;
   realSum                              : integer;
   increment                            : int64;
   offset                               : int64;
   nextThres                            : int64;
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>ActionF</b> - Define new town name styles');
   writeln(t, '<table summary="Properties"><tr><th align="left">ID</th><td>0x', intToHex(fID, 2), '</td></tr>');
   write(t, '<tr><th align="left">Type</th><td>');
   if fFinal then
   begin
      writeln(t, 'final definition</td></tr>');
      writeln(t, '<tr valign="top"><th align="left">Final name</th><td><table summary="Names for final definition" border="1" rules="all"><tr><th>Language</th><th>Name</th></tr>');
      for i := 0 to length(fFinalLangs) - 1 do
      begin
         writeln(t, '<tr><td>0x', intToHex(fFinalLangs[i], 2), getLanguageName(fAction8, fFinalLangs[i]), '</td><td>', formatTextPrintable(fFinalNames[i], true), '</td></tr>');
      end;
      writeln(t, '</table></td></tr>');
   end else writeln(t, 'intermediate definition</td></tr>');
   for i := 0 to length(fParts) - 1 do
      with fParts[i] do
      begin
         realSum := 1 shl bitCount;
         increment := int64(max(1, probSum)) shl (32 - bitCount);
         offset := 0;
         writeln(t, '<tr valign="top"><th align="left">Part ', i, '</th><td>Use bits ', firstBit, ' to ', firstBit + bitCount - 1, ' (', bitCount, ' bits)');
         writeln(t, '<table summary="Values for current part" border="1" rules="all"><tr><th>Probability</th><th>Result</th></tr>');
         for j := 0 to length(choices) - 1 do
            with choices[j] do
            begin
               nextThres := int64(prob) shl 32;
               if offset >= nextThres then realProb := 0 else realProb := 1 + (nextThres - offset - 1) div increment;
               offset := offset + realProb * increment - nextThres;
               write(t, '<tr><td>0x', intToHex(prob, 2), ' (', realProb, '/', realSum, ' = ', realProb * 100 / realSum: 3: 3, '%)</td><td>');
               if typ = newText then write(t, formatTextPrintable(text, true)) else
               begin
                  write(t, 'chain to 0x', intToHex(part, 2), ' (');
                  if partDest = nil then write(t, 'undefined)') else
                                         write(t, partDest.printHtmlSpriteLink('content'), ')');
               end;
               writeln(t, '</td></tr>');
            end;
         writeln(t, '</table>');
      end;
   writeln(t, '</table>');
end;


constructor TAction10.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
var
   i                                    : integer;
begin
   inherited create(aNewGrfFile, ps.spriteNr);
   assert(ps.peekByte = $10);
   ps.getByte;
   fLabelNr := ps.getByte;
   setLength(fComment, ps.bytesLeft);
   for i := 1 to length(fComment) do fComment[i] := char(ps.getByte);
end;

procedure TAction10.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>Action10</b> - Define GOTO label for action 7/9');
   writeln(t, '<table summary="Properties"><tr><th align="left">Label ID</th><td>0x', intToHex(fLabelNr, 2), '</td></tr>');
   writeln(t, '<tr><th align="left">Comment</th><td>', formatTextPrintable(fComment, false), '</td></tr></table>');
end;


constructor TWaveFile.create(aNewGrfFile: TNewGrfFile; bin: TBinaryIncludeSprite);
var
   p                                    : integer;
   size                                 : integer;
   chk                                  : string[4];
   len                                  : longword;
   dataLen                              : longword;
   w                                    : word;
begin
   inherited create(aNewGrfFile, bin.spriteNr);
   fName := bin.name;
   size := bin.size;
   setLength(fData, size);
   move(bin.data^, fData[0], size);

   fSampleCount := 0;
   fSoundStart := 0;
   fFormat.channels := 0;
   fFormat.sampleRate := 0;
   fFormat.resolution := 0;
   dataLen := 0;

   // Parse the wave file: This is a bit sloppy, because we treat all chunks as top-level, and do not really parse the tree structure.
   p := 0;
   while p < size - 8 do
   begin
      chk := char(fData[p]) + char(fData[p + 1]) + char(fData[p + 2]) + char(fData[p + 3]);
      inc(p, 4);
      len := fData[p] or (fData[p + 1] shl 8) or (fData[p + 2] shl 16) or (fData[p + 3] shl 24);
      inc(p, 4);
      if chk = 'RIFF' then
      begin
         if char(fData[p]) + char(fData[p + 1]) + char(fData[p + 2]) + char(fData[p + 3]) = 'WAVE' then
         begin
            inc(p, 4);
            continue; // treat subchunks as top-level
         end;
      end else
      if chk = 'fmt'#32 then
      begin
         if len < 16 then
         begin
            error('Invalid wave file: Format chunk too small');
            exit;
         end;
         if p > size - 16 then break;
         w := fData[p] or (fData[p + 1] shl 8);
         if w <> 1 then
         begin
            error('Invalid wave file: PCM encoding required');
            exit;
         end;
         fFormat.channels := fData[p + 2] or (fData[p + 3] shl 8);
         fFormat.sampleRate := fData[p + 4] or (fData[p + 5] shl 8) or (fData[p + 6] shl 16) or (fData[p + 7] shl 24);
         if fFormat.channels > 0 then fFormat.resolution := (fData[p + 12] or (fData[p + 13] shl 8)) div fFormat.channels;
      end else
      if chk = 'data' then
      begin
         fSoundStart := p;
         dataLen := len;
      end;
      inc(p, (len + 1) and not 1); // skip chunk; the chunks are word aligned. Good old 16bit :)
   end;
   if p <> size then error('Invalid wave file: Unexpected end of file');

   if (fFormat.channels * fFormat.resolution = 0) or (dataLen = 0) then
   begin
      error('Invalid wave file: No sound data found');
      exit;
   end;

   fSampleCount := dataLen div (fFormat.channels * fFormat.resolution);

   if (fFormat.channels <> 1) or (fFormat.resolution <> 1) or
      ((fFormat.sampleRate <> 11025) and (fFormat.sampleRate <> 22050)) then error('Invalid wave file: File must be 8-bit, mono, PCM-encoding with samplerate 11025 or 22050 Hz.');
end;

function TWaveFile.getSize: integer;
begin
   result := length(fData);
end;

function TWaveFile.getData: pointer;
begin
   result := addr(fData[0]);
end;

function TWaveFile.getSoundData: pointer;
begin
   result := addr(fData[fSoundStart]);
end;

procedure TWaveFile.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   f                                    : file;
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>Wave data</b><table summary="Properties"><tr><th align="left">File</th><td><a href="data/', fName, '">', fName, '</a></td></tr>');
   assignFile(f, path + 'data' + directorySeparator + fName);
   rewrite(f, 1);
   blockWrite(f, data^, size);
   closeFile(f);
   write(t, '<tr><th align="left">Format</th><td>', fFormat.sampleRate, ' Hz, ', fFormat.resolution * 8, ' bit, ');
   case fFormat.channels of
      1: write(t, 'mono');
      2: write(t, 'stereo');
    else write(t, fFormat.channels, ' channels');
   end;
   writeln(t, '</td></tr><tr><th align="left">Duration</th><td>');
   if fFormat.sampleRate <> 0 then write(t, (fSampleCount / fFormat.sampleRate): 5: 1, ' seconds');
   writeln(t, '</td></tr></table>');
end;


constructor TSoundImport.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader; parent: TAction11);
begin
   inherited create(aNewGrfFile, ps.spriteNr);
   assert(ps.peekWord = $00FE);
   ps.getWord;
   fParent := parent;
   fGrfID := ps.getDWord;
   fSoundNr := ps.getWord;
   testSpriteEnd(ps);
end;

procedure TSoundImport.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   s                                    : TSprite;
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>Import sound</b><table summary="Properties"><tr><th align="left">GrfID</th><td>', grfID2Str(fGrfID), '</td></tr');
   writeln(t, '<tr><th align="left">Sound</th><td>Nr 0x', intToHex(fSoundNr, 4), ' (', fSoundNr, '), ID 0x', intToHex(fSoundNr + 73, 4), ' (', fSoundNr + 73, ')');
   if (fAction8 <> nil) and (fAction8.grfID = fGrfID) then
   begin
      s := fParent.subSprite[fSoundNr];
      if s <> nil then writeln(t, s.printHtmlSpriteLink('content')) else
                       writeln(t, ' undefined sound');
   end;
   writeln(t, '</td></tr></table>');
end;


constructor TAction11.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
begin
   inherited create(aNewGrfFile, ps.spriteNr);
   assert(ps.peekByte = $11);
   ps.getByte;
   fSubSpriteCount := ps.getWord;
   testSpriteEnd(ps);
end;

function TAction11.getSubSpriteCount: integer;
begin
   result := fSubSpriteCount;
end;

function TAction11.processSubSprite(i: integer; s: TSprite): TSprite;
var
   psr                                  : TPseudoSpriteReader;
   err                                  : boolean;
begin
   err := false;
   if s is TBinaryIncludeSprite then s := TWaveFile.create(fNewGrfFile, s as TBinaryIncludeSprite) else
   if s is TPseudoSprite then
   begin
      psr := TPseudoSpriteReader.create(s as TPseudoSprite);
      if psr.peekWord = $00FE then s := TSoundImport.create(fNewGrfFile, psr, self) else err := true;
      psr.free;
   end else err := true;
   if err then error('Action11: Sprite ' + s.printHtmlSpriteNr + ' must be a BinaryIncludeSprite or a SoundImport-PseudoSprite.');
   result := inherited processSubSprite(i, s);
end;

procedure TAction11.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   i                                    : integer;
   s                                    : TSprite;
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>Action11</b> - Define new sound data');
   writeln(t, '<table summary="Properties" border="1" rules="all"><tr><th>Nr</th><th>Sound ID</th><th>Data</th></tr>');
   for i := 0 to fSubSpriteCount - 1 do
   begin
      s := subSprite[i];
      writeln(t, '<tr valign="top"><th align="left">0x', intToHex(i, 4), ' (', i, ')</th><th align="left">ID 0x', intToHex(i + 73, 4), ' (', i + 73, ')</th><td>');
      write(t, s.printHtmlSpriteAnchor, s.printHtmlSpriteNr, ' - ');
      if (s is TWaveFile) or (s is TSoundImport) then s.printHtml(t, path, settings) else
                                                      writeln(t, 'Invalid sprite type');
      writeln(t, '</td></tr>');
   end;
   writeln(t, '</table>');
end;


constructor TAction13.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
var
   i                                    : integer;
begin
   inherited create(aNewGrfFile, ps.spriteNr);
   assert(ps.peekByte = $13);
   ps.getByte;
   fFeature := ps.getByte;
   fGrfID := ps.getDWord;
   setLength(fTexts, ps.getByte);
   fFirstID := ps.getWord;
   for i := 0 to length(fTexts) - 1 do fTexts[i] := ps.getString;
   testSpriteEnd(ps);
end;

function TAction13.getNumTexts: integer;
begin
   result := length(fTexts);
end;

function TAction13.getTextID(i: integer): word;
begin
   result := fFirstID + i;
end;

function TAction13.getText(i: integer): string;
begin
   result := fTexts[i];
end;

procedure TAction13.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   i                                    : integer;
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>Action13</b> - Translate GRF-specific strings');
   writeln(t, '<table summary="Properties"><tr><th align="left">GrfID</th><td>', grfID2Str(fGrfID), '</td></tr>');
   writeln(t, '<tr><th align="left">Feature</th><td>0x', intToHex(fFeature, 2), ' "', TableFeature[fFeature], '"</td></tr>');
   for i := 0 to length(fTexts) - 1 do
   begin
      writeln(t, '<tr><th align="left">Text ID 0x', intToHex(textID[i], 4), '</th><td>', formatTextPrintable(fTexts[i], true), '</td></tr>');
   end;
   writeln(t, '</table>');
end;

end.
