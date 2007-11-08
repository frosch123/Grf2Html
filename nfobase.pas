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
unit nfobase;

interface

uses sysutils, classes, grfbase, outputsettings;

const
   FTrain                               = $00;
   FRoadVeh                             = $01;
   FShip                                = $02;
   FAircraft                            = $03;
   FStation                             = $04;
   FCanal                               = $05;
   FBridge                              = $06;
   FHouse                               = $07;
   FGlobal                              = $08;
   FIndTile                             = $09;
   FIndustry                            = $0A;
   FCargo                               = $0B;
   FSound                               = $0C;
   FAirport                             = $0D;
   FSignal                              = $0E;
   FObject                              = $0F;

type
   TFeature = byte;

   TPseudoSpriteReader = class
   private
      fPS              : TPseudoSprite;
      fPos             : integer;
      function getSpriteNr: integer;
      function getBytesLeft: integer;
      function getSize: integer;
   public
      constructor create(ps: TPseudoSprite);

      function peekByte: byte;
      function peekExtByte: word;
      function peekWord: word;
      function peekDWord: longword;
      function peek(size: integer): longword;
      function peekString: string;

      function getByte: byte;
      function getExtByte: word;
      function getWord: word;
      function getDWord: longword;
      function get(size: integer): longword;
      function getString: string;

      property spriteNr: integer read getSpriteNr;
      property pos: integer read fPos;
      property bytesLeft: integer read getBytesLeft; // -1 if previous commands read over the sprite end
      property size: integer read getSize;
   end;

   TAction8 = class;

   TNewGrfSprite = class(TSprite)
   private
      fErrors    : TStringList;
      function getErrors: TStrings;
   protected
      fAction8   : TAction8;
      procedure testSpriteEnd(ps: TPseudoSpriteReader);
   public
      constructor create(spriteNr: integer);
      destructor destroy; override;
      procedure error(msg: string);
      procedure useAction8(act8: TAction8); virtual;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      function getShortDesc: string; override;
      property errors: TStrings read getErrors;
   end;

   TSpriteCountSprite = class(TNewGrfSprite)
   private
      fSpriteCount: integer;
   public
      constructor create(ps: TPseudoSpriteReader);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      function getShortDesc: string; override;
      property spriteCount: integer read fSpriteCount;
   end;

   TRecolorTable = array[byte] of byte;

   TRecolorSprite = class(TNewGrfSprite)
   private
      fRecolorTable: TRecolorTable;
   public
      constructor create(ps: TPseudoSpriteReader);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property recolorTable: TRecolorTable read fRecolorTable;
   end;

   TMultiSpriteAction = class(TNewGrfSprite)
   private
      fSubSprites     : array of TSprite;
      function getSubSprite(i: integer): TSprite;
   protected
      function getSubSpriteCount: integer; virtual; abstract;
   public
      constructor create(spriteNr: integer);
      destructor destroy; override;
      function processSubSprite(i: integer; s: TSprite): TSprite; virtual;
      property subSprite[i: integer]: TSprite read getSubSprite;
      property subSpriteCount: integer read getSubSpriteCount;
   end;

   TAction8 = class(TNewGrfSprite)
   private
      fGrfVersion : integer;
      fGrfID      : longword;
      fName       : string;
      fDesc       : string;
   public
      constructor create(ps: TPseudoSpriteReader);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property grfVersion: integer read fGrfVersion;
      property grfID: longword read fGrfID;
      property name: string read fName;
      property description: string read fDesc;
   end;

function formatTextPrintable(s: string; parseStringCodes: boolean): string;
function grfID2Str(grfID: longword): string;

implementation

uses tables;

constructor TPseudoSpriteReader.create(ps: TPseudoSprite);
begin
   inherited create;
   fPS := ps;
   fPos := 0;
end;

function TPseudoSpriteReader.getSpriteNr: integer;
begin
   result := fPS.spriteNr;
end;

function TPseudoSpriteReader.getBytesLeft: integer;
var
   size                                 : integer;
begin
   size := fPS.size;
   result := size - fPos;
   if result < 0 then result := -1;
end;

function TPseudoSpriteReader.getSize: integer;
begin
   result := fPS.size;
end;

function TPseudoSpriteReader.peekByte: byte;
begin
   result := getByte;
   dec(fPos);
end;

function TPseudoSpriteReader.peekExtByte: word;
begin
   result := getByte;
   if result = $FF then result := peekWord;
   dec(fPos);
end;

function TPseudoSpriteReader.peekWord: word;
begin
   result := getWord;
   dec(fPos, 2);
end;

function TPseudoSpriteReader.peekDWord: longword;
begin
   result := getDWord;
   dec(fPos, 4);
end;

function TPseudoSpriteReader.peek(size: integer): longword;
begin
   result := get(size);
   dec(fPos, size);
end;

function TPseudoSpriteReader.peekString: string;
var
   p                                    : integer;
begin
   p := fPos;
   result := getString;
   fPos := p;
end;

function TPseudoSpriteReader.getByte: byte;
begin
   // returning 0 at end of sprite is important in several places
   if fPos >= fPS.size then result := 0 else result := fPS.data[fPos];
   inc(fPos);
end;

function TPseudoSpriteReader.getExtByte: word;
begin
   result := getByte;
   if result = $FF then result := getWord;
end;

function TPseudoSpriteReader.getWord: word;
begin
   result := getByte or getByte shl 8;
end;

function TPseudoSpriteReader.getDWord: longword;
begin
   result := getWord or getWord shl 16;
end;

function TPseudoSpriteReader.get(size: integer): longword;
var
   i                                    : integer;
begin
   result := 0;
   for i := 0 to size - 1 do result := result or (getByte shl (i * 8));
end;

function TPseudoSpriteReader.getString: string;
var
   c                                    : char;
begin
   result := '';
   repeat
      c := char(getByte);
      if c <> #0 then result := result + c;
   until c = #0;
end;

constructor TNewGrfSprite.create(spriteNr: integer);
begin
   inherited create(spriteNr);
   fErrors := TStringList.create;
   fAction8 := nil;
end;

destructor TNewGrfSprite.destroy;
begin
   fErrors.free;
   inherited destroy;
end;

procedure TNewGrfSprite.error(msg: string);
begin
   fErrors.add(msg);
end;

procedure TNewGrfSprite.useAction8(act8: TAction8);
begin
   fAction8 := act8;
end;

function TNewGrfSprite.getErrors: TStrings;
begin
   result := fErrors;
end;

procedure TNewGrfSprite.testSpriteEnd(ps: TPseudoSpriteReader);
var
   i                                    : integer;
begin
   i := ps.bytesLeft;
   if i < 0 then error('Sprite too short: Expected ' + intToStr(ps.pos - ps.size) + ' more bytes.');
   if i > 0 then error('Sprite too long: ' + intToStr(i) + ' bytes left.');
end;

procedure TNewGrfSprite.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   i                                    : integer;
begin
   inherited printHtml(t, path, settings);
   if fErrors.count > 0 then
   begin
      writeln(t, '<p><b>Errors:</b><br>');
      for i := 0 to fErrors.count - 1 do writeln(t, fErrors[i], '<br>');
      writeln(t, '</p>');
   end;
end;

function TNewGrfSprite.getShortDesc: string;
begin
   result := className;
   delete(result, 1, 1);
end;

constructor TSpriteCountSprite.create(ps: TPseudoSpriteReader);
begin
   inherited create(ps.spriteNr);
   fSpriteCount := ps.getDWord;
   testSpriteEnd(ps);
end;

procedure TSpriteCountSprite.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>First Sprite</b><br><b>Spritecount</b> ', spriteCount);
end;

function TSpriteCountSprite.getShortDesc: string;
begin
   result := 'SpriteCount';
end;

constructor TRecolorSprite.create(ps: TPseudoSpriteReader);
var
   i                                    : integer;
begin
   inherited create(ps.spriteNr);
   if ps.getByte <> 0 then error('ReColorSprite does not start with 0x00');
   for i := 0 to high(byte) do fRecolorTable[i] := ps.getByte;
   testSpriteEnd(ps);
end;

procedure TRecolorSprite.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   y, x                                 : integer;
   v                                    : byte;
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>RecolorSprite</b>');
   write(t, '<table summary="RecolorSprite"><tr><th>0x</th>');
   for x := 0 to 15 do write(t, '<th>_', intToHex(x, 1), '</th>');
   writeln(t, '</tr>');
   for y := 0 to 15 do
   begin
      write(t, '<tr><th>', intToHex(y, 1), '_</th>');
      for x := 0 to 15 do
      begin
         v := recolorTable[y * 16 + x];
         if v = y * 16 + x then write(t, '<td>__</td>') else write(t, '<td>', intToHex(v, 2), '</td>');
      end;
      writeln(t, '</tr>');
   end;
   writeln(t, '</table>');
end;

constructor TMultiSpriteAction.create(spriteNr: integer);
begin
   inherited create(spriteNr);
   setLength(fSubSprites, 0);
end;

destructor TMultiSpriteAction.destroy;
begin
   setLength(fSubSprites, 0);
   inherited destroy;
end;

function TMultiSpriteAction.getSubSprite(i: integer): TSprite;
begin
   if (i >= 0) and (i < length(fSubSprites)) then result := fSubSprites[i] else result := nil;
end;

function TMultiSpriteAction.processSubSprite(i: integer; s: TSprite): TSprite;
begin
   if length(fSubSprites) = 0 then setLength(fSubSprites, getSubSpriteCount);
   assert((i >= 0) and (i < length(fSubSprites)));
   fSubSprites[i] := s;
   result := s;
end;

constructor TAction8.create(ps: TPseudoSpriteReader);
begin
   inherited create(ps.spriteNr);
   assert(ps.peekByte = $08);
   ps.getByte;
   fGrfVersion := ps.getByte;
   fGrfID := ps.getDWord;
   fName := ps.getString;
   fDesc := ps.getString;
   testSpriteEnd(ps);
end;

procedure TAction8.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>Action8</b> - Register NewGrf<table summary="Properties">');
   writeln(t, '<tr><th align="left">GrfVersion</th><td>', grfVersion, '</td></tr>');
   writeln(t, '<tr><th align="left">GrfID</th><td>', grfID2Str(fGrfID), '</td></tr>');
   writeln(t, '<tr><th align="left">Name</th><td>', formatTextPrintable(name, true), '</td></tr>');
   writeln(t, '<tr><th align="left">Description</th><td>', formatTextPrintable(description, true), '</td></tr>');
   writeln(t, '</table>');
end;

function formatTextPrintable(s: string; parseStringCodes: boolean): string;
var
   i,j                                  : integer;
   quoted                               : boolean;
   unicode                              : boolean;
   charvalue                            : longword;
   charlen                              : byte;
   validchar                            : boolean;
   tmp, tmp2                            : integer;
   s2                                   : string;
begin
   if s = '' then result := '""' else
   begin
      result := '';
      i := 1;
      unicode := parseStringCodes and (length(s) >= 2) and (s[1] = #$C3) and (s[2] = #$9E);
      if unicode then
      begin
         result := result + '&lt;UTF-8&gt;';
         inc(i, 2);
      end;
      quoted := false;
      while i <= length(s) do
      begin
         if unicode then
         begin
            validchar := true;
            // TODO: I sense that the following is not totally correct. But I guess it will work for now.
            //       There are some strange character areas $D800..$DFFF and $FFFE..$FFFF, that I do not understand.
            case s[i] of
              #$00..#$7F: charlen := 1;
              #$C0..#$DF: charlen := 2;
              #$E0..#$EF: charlen := 3;
              #$F0..#$F7: charlen := 4;
                     else begin
                             // invalid encoding
                             charlen := 1;
                             validchar := false;
                          end;
            end;
            for j := 1 to charlen - 1 do
               if (length(s) < i + j) or (ord(s[i + j]) and $C0 <> $80) then
               begin
                  // invalid encoding
                  charlen := 1;
                  validchar := false;
                  break;
               end;

            case charlen of
               1: charvalue :=  ord(s[i    ]); // also allow $80 to $FF of invalid encodings.
               2: charvalue := (ord(s[i    ]) and $1F  shl  6) or ( ord(s[i + 1]) and $3F);
               3: charvalue := (ord(s[i    ]) and $0F  shl 12) or ((ord(s[i + 1]) and $3F) shl  6) or (ord(s[i + 2]) and $3F);
             else charvalue := (ord(s[i    ]) and $07  shl 18) or ((ord(s[i + 1]) and $3F) shl 12) or
                              ((ord(s[i + 2]) and $3F) shl 12) or ( ord(s[i + 3]) and $3F);
            end;

            if validchar then
            begin
               if charvalue < $20 then validchar := false; // control characters
               if (charvalue >= $E000) and (charvalue <= $E0FF) then
               begin
                  // Private use area -> TTDP StringCodes
                  s[i] := char(charvalue - $E000);
                  validchar := false;
               end;
            end;
         end else
         begin
            charlen := 1;
            if parseStringCodes then
            begin
               case ord(s[i]) of
                  $20..$7A: validchar := true;
                  $9E     : begin // Euro character -> $20AC -> $E2 $82 $AC
                               validchar := true;
                               charlen := 3;
                               s[i] := #$AC;
                               insert(#$E2#$82, s, i);
                            end;
                  $9F     : begin // Y umlaut  -> $178 -> $C5 $B8
                               validchar := true;
                               charlen := 2;
                               s[i] := #$B8;
                               insert(#$C5, s, i);
                            end;
                  $B9     : begin // superscript "-1"
                               validchar := true;
                               charlen := 13;
                               s[i] := '>';
                               insert('<sup>-1</sup', s, i);
                            end;
                  $A1..$A9, $AB, $AE, $B0..$B3, $BA..$BB, $BE..$FF:
                            begin // latin1 chars
                               validchar := true;
                               charlen := 2;
                               charvalue := ord(s[i]);
                               s[i] := char($80 or (charvalue and $3F));
                               insert(char($C0 or (charvalue shr 6)), s, i);
                            end;
                   else     validchar := false;
               end;
            end else validchar := (s[i] in [#$20..#$7E]);
         end;
         if validchar then
         begin
            if not quoted then
            begin
               if result = '' then result := '"' else result := result + ' "';
            end;
            quoted := true;
            case s[i] of
               '"': result := result + '""';
               '<': result := result + '&lt;';
               '>': result := result + '&gt;';
               '&': result := result + '&amp;';
               else result := result + copy(s, i, charlen);
            end;
         end else
         begin
            if quoted then result := result + '" ' else
               if result <> '' then result := result + ' ';
            quoted := false;
            if parseStringCodes then
            begin
               case ord(s[i]) of
                  $81: begin
                          charlen := 3;
                          tmp := 0;
                          if i + 1 <= length(s) then tmp := tmp or ord(s[i + 1]);
                          if i + 2 <= length(s) then tmp := tmp or (ord(s[i + 2]) shl 8);
                          result := result + '&lt;0x81 string 0x' + intToHex(tmp,4) + '&gt;';
                       end;
                  $99: begin
                          charlen := 2;
                          if i + 1 <= length(s) then tmp := ord(s[i + 1]) else tmp := 0;
                          result := result + '&lt;0x99 switch to company color 0x' + intToHex(tmp, 2) + '&gt;';
                       end;
                  $9A: begin
                          charlen := 2;
                          if i + 1 <= length(s) then tmp := ord(s[i + 1]) else tmp := 0;
                          result := result + '&lt;0x9A 0x' + intToHex(tmp, 2);
                          case tmp of
                             $00, $01: result := result + ' qword [currency]&gt;';
                                  $02: result := result + ' ignore next color code&gt;';
                                  $03: begin
                                          charlen := 4;
                                          tmp2 := 0;
                                          if i + 2 <= length(s) then tmp2 := tmp2 or ord(s[i + 2]);
                                          if i + 3 <= length(s) then tmp2 := tmp2 or (ord(s[i + 3]) shl 8);
                                          result := result + ' push 0x' + intToHex(tmp2, 4) + '&gt;';
                                       end;
                                  $04: begin
                                          charlen := 3;
                                          if i + 2 <= length(s) then tmp2 := ord(s[i + 2]) else tmp2 := 0;
                                          result := result + ' unprint ' + intToStr(tmp2) + ' characters&gt;';
                                       end;
                             else      result := result + ' unknown&gt;';
                          end;
                       end;
                  else begin
                          s2 := TableStringCode[ord(s[i])];
                          if s2 = 'unknown' then result := result + '0x' + intToHex(ord(s[i]), 2) else
                                                 result := result + '&lt;0x' + intToHex(ord(s[i]), 2) + ' ' + s2 + '&gt;';
                       end;
               end;
            end else result := result + '0x' + intToHex(ord(s[i]), 2);
         end;
         inc(i, charlen);
      end;
      if quoted then result := result + '"';
   end;
end;

function grfID2Str(grfID: longword): string;
var
   s                                    : string[4];
begin
   setLength(s, 4);
   s[1] := char(grfID and $FF);
   s[2] := char((grfID shr 8) and $FF);
   s[3] := char((grfID shr 16) and $FF);
   s[4] := char((grfID shr 24) and $FF);
   result := '0x' + intToHex(ord(s[1]), 2) + ' 0x' + intToHex(ord(s[2]), 2) + ' 0x' + intToHex(ord(s[3]), 2) + ' 0x' + intToHex(ord(s[4]), 2) +
             ' (' + formatTextPrintable(s, false) + ')';
end;

end.
