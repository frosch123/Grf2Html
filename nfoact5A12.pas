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
unit nfoact5A12;

interface

uses sysutils, grfbase, nfobase, tables, math, outputsettings;

type
   TSpriteReplacementAction = class(TMultiSpriteAction)
   private
      fNumSprites           : array of integer;
      fTotalSprites         : integer;
      fReal, fRecolor       : boolean;
      function getNumSets: integer;
      function getNumSpritesInSet(setNr: integer): integer;
      function getSprite(setNr, sprNr: integer): TSprite;
   protected
      function getSubSpriteCount: integer; override;
      procedure addSet(spriteCount: integer);
      procedure printActionHeader(var t: textFile; path: string); virtual; abstract;
      procedure printSetHeader(var t: textFile; path: string; setNr: integer); virtual; abstract;
      procedure printSpriteHeader(var t: textFile; path: string; setNr, sprNr: integer); virtual; abstract;
      property numSets: integer read getNumSets;
      property numSpritesInSet[setNr: integer]: integer read getNumSpritesInSet;
      property sprites[setNr, sprNr: integer]: TSprite read getSprite;
   public
      constructor create(spriteNr: integer; allowRealSprites, allowRecolorSprites: boolean);
      function processSubSprite(i: integer; s: TSprite): TSprite; override;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
   end;

   TAction5 = class(TSpriteReplacementAction)
   private
      fType    : byte;
      fOffset  : integer;
   protected
      procedure printActionHeader(var t: textFile; path: string); override;
      procedure printSetHeader(var t: textFile; path: string; setNr: integer); override;
      procedure printSpriteHeader(var t: textFile; path: string; setNr, sprNr: integer); override;
   public
      constructor create(ps: TPseudoSpriteReader);
      property spriteType: byte read fType;
      property spriteOffset: integer read fOffset;
   end;

   TActionA = class(TSpriteReplacementAction)
   private
      fFirstSprite  : array of word;
      function getSpriteID(setNr, sprNr: integer): word;
   protected
      procedure printActionHeader(var t: textFile; path: string); override;
      procedure printSetHeader(var t: textFile; path: string; setNr: integer); override;
      procedure printSpriteHeader(var t: textFile; path: string; setNr, sprNr: integer); override;
   public
      constructor create(ps: TPseudoSpriteReader);
      property numSets;
      property numSpritesInSet;
      property spriteID[setNr, sprNr: integer]: word read getSpriteID;
      property sprites;
   end;

   TAction12 = class(TSpriteReplacementAction)
   private
      fFont       : array of byte;
      fFirstChar  : array of word;
      function getSetFont(setNr: integer): byte;
      function getCharID(setNr, charNr: integer): word;
   protected
      procedure printActionHeader(var t: textFile; path: string); override;
      procedure printSetHeader(var t: textFile; path: string; setNr: integer); override;
      procedure printSpriteHeader(var t: textFile; path: string; setNr, sprNr: integer); override;
   public
      constructor create(ps: TPseudoSpriteReader);
      property numSets;
      property numSpritesInSet;
      property sprites;
      property setFont[setNr: integer]: byte read getSetFont;
      property characterID[setNr, charNr: integer]: word read getCharID;
   end;

implementation

constructor TSpriteReplacementAction.create(spriteNr: integer; allowRealSprites, allowRecolorSprites: boolean);
begin
   inherited create(spriteNr);
   setLength(fNumSprites, 0);
   fTotalSprites := 0;
   fReal := allowRealSprites;
   fRecolor := allowRecolorSprites;
end;

function TSpriteReplacementAction.getSubSpriteCount: integer;
begin
   result := fTotalSprites;
end;

function TSpriteReplacementAction.processSubSprite(i: integer; s: TSprite): TSprite;
var
   psr                                  : TPseudoSpriteReader;
   err                                  : boolean;
begin
   err := false;
   if s is TRealSprite then err := not fReal else
   if s is TPseudoSprite then
   begin
      if fRecolor then
      begin
         psr := TPseudoSpriteReader.create(s as TPseudoSprite);
         s := TRecolorSprite.create(psr);
         psr.free;
      end else err := true;
   end else err := true;
   if err then
   begin
      if fReal and fRecolor then error('Sprite ' + s.printHtmlSpriteNr + ' must be a RealSprite or a RecolorSprite.') else
      if fReal              then error('Sprite ' + s.printHtmlSpriteNr + ' must be a RealSprite.') else
                                 error('Sprite ' + s.printHtmlSpriteNr + ' must be a RecolorSprite.');
   end;
   result := inherited processSubSprite(i, s);
end;

function TSpriteReplacementAction.getNumSets: integer;
begin
   result := length(fNumSprites);
end;

function TSpriteReplacementAction.getNumSpritesInSet(setNr: integer): integer;
begin
   result := fNumSprites[setNr];
end;

function TSpriteReplacementAction.getSprite(setNr, sprNr: integer): TSprite;
var
   i                                    : integer;
begin
   if (setNr >= length(fNumSprites)) or (sprNr >= fNumSprites[setNr]) then result := nil else
   begin
      for i := 0 to setNr - 1 do sprNr := sprNr + fNumSprites[i];
      result := subSprite[sprNr];
   end;
end;

procedure TSpriteReplacementAction.addSet(spriteCount: integer);
var
   i                                    : integer;
begin
   i := length(fNumSprites);
   setLength(fNumSprites, i + 1);
   fNumSprites[i] := spriteCount;
   fTotalSprites := fTotalSprites + spriteCount;
end;

procedure TSpriteReplacementAction.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   setNr                                : integer;
   subNr                                : integer;
   i                                    : integer;
   maxWidth                             : integer;
   colCount                             : integer;
   s                                    : TSprite;
begin
   inherited printHtml(t, path, settings);
   printActionHeader(t, path);
   subNr := 0;
   for setNr := 0 to length(fNumSprites) - 1 do
   begin
      printSetHeader(t, path, setNr);
      if fNumSprites[setNr] = 0 then
      begin
         writeln(t, '<br>');
         continue;
      end;

      maxWidth := settings.action5A12ColWidth;
      for i := 0 to fNumSprites[setNr] - 1 do
      begin
         s := subSprite[subNr + i];
         if s <> nil then
         begin
            if fReal    and (s is TRealSprite)    then maxWidth := max(maxWidth, (s as TRealSprite).width) else
            if fRecolor and (s is TRecolorSprite) then maxWidth := max(maxWidth, 500);
         end;
      end;
      colCount := max(1, settings.aimedWidth div maxWidth);
      if colCount > fNumSprites[setNr] then colCount := fNumSprites[setNr];
      writeln(t, '<table summary="Subsprites" border="1" rules="all"><tr valign="top">');
      for i := 0 to fNumSprites[setNr] - 1 do
      begin
         if (i <> 0) and (i mod colCount = 0) then writeln(t, '</tr><tr valign="top">');
         s := subSprite[subNr];
         write(t, '<td>');
         if s <> nil then
         begin
            write(t, s.printHtmlSpriteAnchor);
            if (fReal and (s is TRealSprite)) or (fRecolor and (s is TRecolorSprite)) then
            begin
               printSpriteHeader(t, path, setNr, i);
               writeln(t, ' - ', s.printHtmlSpriteNr, '<br>');
               s.printHtml(t, path, settings);
            end else
            begin
               write(t, s.printHtmlSpriteNr);
               if fReal and fRecolor then write(t, ' RealSprite or RecolorSprite expected') else
               if fReal              then write(t, ' RealSprite expected') else
                                          write(t, ' RecolorSprite expected');
            end;
         end else write(t, 'missing sprite');
         writeln(t, '</td>');
         inc(subNr);
      end;
      for i := (fNumSprites[setNr] - 1) mod colCount + 1 to colCount - 1 do write(t, '<td></td>');
      writeln(t, '</tr></table>');
   end;
end;


constructor TAction5.create(ps: TPseudoSpriteReader);
var
   hasOffset                            : boolean;
begin
   inherited create(ps.spriteNr, true, true);
   assert(ps.peekByte = $05);
   ps.getByte;
   hasOffset := (ps.peekByte and $80) <> 0;
   fType := ps.getByte and $7F;
   addSet(ps.getExtByte);
   if hasOffset then fOffset := ps.getExtByte else fOffset := 0;
   testSpriteEnd(ps);
end;

procedure TAction5.printActionHeader(var t: textFile; path: string);
begin
   writeln(t, '<b>Action5</b> - Define TTDPatch specific graphics sets<table summary="Properties">');
   writeln(t, '<tr><th align="left">Type:</th><td>0x', intToHex(fType, 2), ' "', TableAction5Type[fType], '"</td></tr>');
   writeln(t, '</table>');
end;

procedure TAction5.printSetHeader(var t: textFile; path: string; setNr: integer);
begin
   writeln(t, 'Sprites ', fOffset, ' to ', fOffset + subSpriteCount - 1, ' (', subSpriteCount, ' sprites)');
end;

procedure TAction5.printSpriteHeader(var t: textFile; path: string; setNr, sprNr: integer);
begin
   write(t, 'Nr. ', sprNr + fOffset);
end;


constructor TActionA.create(ps: TPseudoSpriteReader);
var
   sets, i                              : integer;
begin
   inherited create(ps.spriteNr, true, true);
   assert(ps.peekByte = $0A);
   ps.getByte;
   sets := ps.getByte;
   setLength(fFirstSprite, sets);
   for i := 0 to sets - 1 do
   begin
      addSet(ps.getByte);
      fFirstSprite[i] := ps.getWord;
   end;
   testSpriteEnd(ps);
end;

function TActionA.getSpriteID(setNr, sprNr: integer): word;
begin
   result := fFirstSprite[setNr] + sprNr;
end;

procedure TActionA.printActionHeader(var t: textFile; path: string);
begin
   writeln(t, '<b>ActionA</b> - Modify TTD''s sprites');
end;

procedure TActionA.printSetHeader(var t: textFile; path: string; setNr: integer);
begin
   writeln(t, '<br><b>Set ', setNr, ':</b> Sprites ', fFirstSprite[setNr], ' to ', fFirstSprite[setNr] + numSpritesInSet[setNr] - 1, ' (', numSpritesInSet[setNr], ' sprites)');
end;

procedure TActionA.printSpriteHeader(var t: textFile; path: string; setNr, sprNr: integer);
begin
   write(t, spriteID[setNr, sprNr]);
end;


constructor TAction12.create(ps: TPseudoSpriteReader);
var
   sets, i                              : integer;
begin
   inherited create(ps.spriteNr, true, false);
   assert(ps.peekByte = $12);
   ps.getByte;
   sets := ps.getByte;
   setLength(fFont, sets);
   setLength(fFirstChar, sets);
   for i := 0 to sets - 1 do
   begin
      fFont[i] := ps.getByte;
      addSet(ps.getByte);
      fFirstChar[i] := ps.getWord;
   end;
   testSpriteEnd(ps);
end;

function TAction12.getSetFont(setNr: integer): byte;
begin
   result := fFont[setNr];
end;

function TAction12.getCharID(setNr, charNr: integer): word;
begin
   result := fFirstChar[setNr] + charNr;
end;

procedure TAction12.printActionHeader(var t: textFile; path: string);
begin
   writeln(t, '<b>Action12</b> - Load font glyphs');
end;

procedure TAction12.printSetHeader(var t: textFile; path: string; setNr: integer);
begin
   writeln(t, '<br><b>Set ', setNr, ':</b> Characters 0x', intToHex(fFirstChar[setNr], 4), ' to 0x', intToHex(fFirstChar[setNr] + numSpritesInSet[setNr] - 1, 4), ' (', numSpritesInSet[setNr], ' characters)',
              ' for font 0x', intToHex(fFont[setNr], 2), ' "', TableAction12Font[fFont[setNr]], '"');
end;

procedure TAction12.printSpriteHeader(var t: textFile; path: string; setNr, sprNr: integer);
begin
   writeln(t, '0x', intToHex(characterID[setNr, sprNr], 4));
end;

end.
