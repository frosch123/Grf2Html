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
unit nfoact123;

interface

uses sysutils, grfbase, nfobase, tables, spritelayout, math, htmlwriter, outputsettings;

type
   TAction1 = class(TMultiSpriteAction)
   private
      fFeature       : TFeature;
      fNumSets       : integer;
      fSpritesPerSet : integer;
      fLinkedFrom    : array of TSpriteSet;
   protected
      function getSubSpriteCount: integer; override;
   public
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
      destructor destroy; override;
      function processSubSprite(i: integer; s: TSprite): TSprite; override;
      procedure registerLink(setNr: integer; from: TNewGrfSprite);
      function printHtmlLinkToSet(setNr: integer; const srcFrame: string; const settings: TGrf2HtmlSettings): string;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property feature: TFeature read fFeature;
      property numSets: integer read fNumSets;
      property spritesPerSet: integer read fSpritesPerSet;
   end;

   TAction2 = class;

   TAction2Dest = record
      value     : word; // CargoID or callback result, $ffxx is transformed to $80xx
      dest      : TAction2; // Referenced CargoID
   end;

   TAction2Table = array[byte] of TAction2;
   TAction2 = class(TNewGrfSprite)
   private
      fFeature    : TFeature;
      fCargoID    : integer;
      fLinkedFrom : TSpriteSet;
   public
      constructor create(aNewGrfFile: TNewGrfFile; spriteNr: integer; feature: TFeature; cargoID: integer);
      destructor destroy; override;
      class function readAction2(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader; var action2Table: TAction2Table; action1: TAction1): TAction2;
      procedure registerLink(from: TNewGrfSprite);
      procedure printLinkedFrom(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
      property feature: TFeature read fFeature;
      property cargoID: integer read fCargoID;
   end;

   TBasicAction2 = class(TAction2)
   private
      fAction1: TAction1;
      fEntries: array[0..1] of array of word;
      function getNumEntries(typ: integer): integer;
      function getEntry(typ, nr: integer): word;
   public
      constructor create(feature: TFeature; cargoID: integer; aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader; action1: TAction1);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property numEntries[typ: integer]: integer read getNumEntries; // typ=0 moving etc..., typ=1 loading etc...
      property entry[typ, nr: integer]: word read getEntry;
      property action1: TAction1 read fAction1;
   end;

   THouseIndTileAction2 = class(TAction2)
   private
      fAction1                 : TAction1;
      fGroundSprite            : TTTDPSprite;
      fSpriteLayout            : TSpriteLayout;
   public
      constructor create(feature: TFeature; cargoID: integer; aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader; action1: TAction1);
      destructor destroy; override;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property groundSprite: TTTDPSprite read fGroundSprite;
      property spritelayout: TSpriteLayout read fSpriteLayout;
   end;

   TIndustryProductionCallback = class(TAction2)
   private
      fUseRegisters            : boolean;
      fInput                   : array[0..2] of word;
      fOutput                  : array[0..1] of word;
      fAgain                   : byte;
      function getInputAmount(i: integer): word;
      function getOutputAmount(i: integer): word;
   public
      constructor create(feature: TFeature; cargoID: integer; aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property useRegisters: boolean read fUseRegisters;
      property inputAmount[i: integer]: word read getInputAmount;
      property outputAmount[i: integer]: word read getOutputAmount;
      property againFlag: byte read fAgain;
   end;

   TVarAction2Term = record
      operator     : byte;
      variable     : byte;
      parameter    : byte;
      proc         : TAction2;
      shift        : byte;
      divMod       : (none, division, modulo);
      andMask      : longword;
      addValue     : longint;
      divModValue  : longint;
   end;
   TVarAction2Case = record
      min, max     : longword;
      dest         : TAction2Dest;
   end;
   TVarAction2 = class(TAction2)
   private
      fRelated : boolean;
      fSize    : integer;
      fFormula : array of TVarAction2Term;
      fCases   : array of TVarAction2Case;
      fDefault : TAction2Dest;
      function getTermCount: integer;
      function getTerm(i: integer): TVarAction2Term;
      function getIsComputedResult: boolean;
      function getNumCases: integer;
      function getCase(i: integer): TVarAction2Case;
   public
      constructor create(feature: TFeature; cargoID: integer; aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader; const action2Table: TAction2Table);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property useRelated: boolean read fRelated;
      property varSize: integer read fSize;
      property termCount: integer read getTermCount;
      property term[i: integer]: TVarAction2Term read getTerm;
      property isComputedResult: boolean read getIsComputedResult;
      property numCases: integer read getNumCases;
      property cases[i: integer]: TVarAction2Case read getCase;
      property defaultCase: TAction2Dest read fDefault;
   end;

   TRandomAction2 = class(TAction2)
   private
      fType       : (current, related, vehicleBackwards, vehicleForwards, vehicleAbsolute, vehicleChain);
      fVehiclePos : byte; // only valid for vehicle*-type; 0 means register 0x100
      fTriggers   : byte;
      fAllTriggers: boolean;
      fRandBit    : integer;
      fRandCount  : integer;
      fCases      : array of TAction2Dest;
      function getNumCases: integer;
      function getCase(i: integer): TAction2Dest;
   public
      constructor create(feature: TFeature; cargoID: integer; aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader; const action2Table: TAction2Table);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property allTriggersNeeded: boolean read fAllTriggers;
      property firstRandomBit: integer read fRandBit;
      property numRandomBits: integer read fRandCount;
      property numCases: integer read getNumCases;
      property cases[i: integer]: TAction2Dest read getCase;
   end;

   TAction3 = class(TNewGrfSprite)
   private
      fFeature   : TFeature;
      fFeatID    : array of integer;
      fCargoBit  : array of byte;
      fDest      : array of TAction2Dest;
      fDefault   : TAction2Dest;
      fLivery    : boolean;
      function getGenericCallback: boolean;
      function getFeatIDCount: integer;
      function getFeatID(i: integer): integer;
      function getDestCnt: integer;
      function getCargoBit(i: integer): integer;
      function getDest(i: integer): TAction2Dest;
   public
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader; const action2Table: TAction2Table);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property feature: TFeature read fFeature;
      property liveryOverride: boolean read fLivery;
      property genericCallback: boolean read getGenericCallback;
      property featIDCount: integer read getFeatIDCount;
      property featId[i: integer]: integer read getFeatID;
      property destinationCount: integer read getDestCnt;
      property cargoBit[i: integer]: integer read getCargoBit;
      property destination[i: integer]: TAction2Dest read getDest;
      property defaultDest: TAction2Dest read fDefault;
   end;

implementation

function checkCallback(var value: word): boolean;
begin
   result := value and $8000 <> 0;
   if result then
   begin
      // callback result
      // "For compatibility with earlier patch versions, FF in the high byte is taken to mean the same thing as 80"
      if value and $FF00 = $FF00 then value := value and $80FF;
   end;
end;

function readAction2Dest(parent: TNewGrfSprite; ps: TPseudoSpriteReader; const action2Table: TAction2Table): TAction2Dest;
begin
   result.value := ps.getWord;
   if checkCallback(result.value) then
   begin
      result.dest := nil;
   end else
   begin
      // normal chain
      if result.value < $100 then result.dest := action2Table[result.value] else
                                  result.dest := nil;
      if result.dest <> nil then
      begin
         result.dest.registerLink(parent);
      end else parent.error('Undefined Action2 CargoID 0x' + intToHex(result.value, 4));
   end;
end;

function printAction2Dest(dest: TAction2Dest; const settings: TGrf2HtmlSettings): string;
begin
   if dest.value and $8000 <> 0 then
   begin
      // callback result
      result := 'return 0x' + intToHex(dest.value and $7FFF, 4);
   end else
   begin
      // normal chain
      result := 'chain to 0x' + intToHex(dest.value, 2);
      if dest.dest <> nil then
      begin
         result := result + ' (' + dest.dest.printHtmlSpriteLink('content', settings) + ')';
      end else result := result + ' (undefined)';
   end;
end;


constructor TAction1.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
var
   i                                    : integer;
begin
   inherited create(aNewGrfFile, ps.spriteNr);
   assert(ps.peekByte = $01);
   ps.getByte;
   fFeature := ps.getByte;
   fNumSets := ps.getByte;
   setLength(fLinkedFrom, fNumSets);
   for i := 0 to fNumSets - 1 do fLinkedFrom[i] := TSpriteSet.create;
   fSpritesPerSet := ps.getExtByte;
   testSpriteEnd(ps);
end;

destructor TAction1.destroy;
var
   i                                    : integer;
begin
   for i := 0 to fNumSets - 1 do fLinkedFrom[i].free;
   setLength(fLinkedFrom, 0);
end;

function TAction1.getSubSpriteCount: integer;
begin
   result := fNumSets * fSpritesPerSet;
end;

function TAction1.processSubSprite(i: integer; s: TSprite): TSprite;
begin
   if not (s is TRealSprite) then error('Action1: Sprite ' + s.printHtmlSpriteNr + ' must be a RealSprite');
   result := inherited processSubSprite(i, s);
end;

function TAction1.printHtmlLinkToSet(setNr: integer; const srcFrame: string; const settings: TGrf2HtmlSettings): string;
var
   inRange                              : boolean;
begin
   inRange := (spriteNr >= settings.range[0]) and (spriteNr <= settings.range[1]);
   if inRange then result := printLinkBegin(srcFrame, 'content', 'nfo.html#sprite' + intToStr(spriteNr) + 'set' + intToStr(setNr)) else result := '';
   result := result + 'Action1 Set ' + intToStr(setNr);
   if inRange then result := result + '</a>';
end;

procedure TAction1.registerLink(setNr: integer; from: TNewGrfSprite);
begin
   if (setNr >= 0) and (setNr < fNumSets) then fLinkedFrom[setNr].add(from) else
                                               from.error('Action1 Set Nr. ' + intToStr(setNr) + ' out of range. (' + intToStr(fNumSets) + ' sets defined)');
end;

procedure TAction1.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   i, j                                 : integer;
   s                                    : TSprite;
   aimedCols                            : integer;
   maxW                                 : integer;
   nr                                   : integer;
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>Action1</b> - Define set of real sprites<br>');
   writeln(t, '<b>Feature</b> 0x', intToHex(fFeature, 2), ' "', TableFeature[fFeature], '"');
   writeln(t, '<br>', fNumSets, ' sets of ', fSpritesPerSet, ' sprites:');

   if fSpritesPerSet * fNumSets = 0 then exit;

   maxW := settings.action1ColWidth;
   for i := 0 to subSpriteCount - 1 do
      if subSprite[i] is TRealSprite then maxW := max(maxW, (subSprite[i] as TRealSprite).width);
   aimedCols := max(1, settings.aimedWidth div maxW);

   if fSpritesPerSet > 1 then
   begin
      if aimedCols > fSpritesPerSet then aimedCols := fSpritesPerSet;
      write(t, '<table summary="Subsprites" border="1" rules="all">');
      for j := 0 to fNumSets - 1 do
      begin
         writeln(t, '<tr valign="top"><th align="left" rowspan="', (fSpritesPerSet + aimedCols - 1) div aimedCols, '"><a name="sprite', spriteNr, 'set', j, '">Set ', j, '</a><br><font size="-2">Linked from: ');
         fLinkedFrom[j].printHtml('content', t, path, settings, true);
         writeln(t, '</font></th>');
         for i := 0 to fSpritesPerSet - 1 do
         begin
            if (i <> 0) and (i mod aimedCols = 0) then writeln(t, '</tr><tr valign="top">');
            s := subSprite[j * fSpritesPerSet + i];
            if s = nil then writeln(t, '<td>', i, '<br>Missing sprite') else
            begin
               write(t, '<td>', s.printHtmlSpriteAnchor, i, ' - ', s.printHtmlSpriteNr, '<br>');
               if s is TRealSprite then s.printHtml(t, path, settings) else
                                        write(t, 'RealSprite expected');
            end;
            writeln(t, '</td>');
         end;
         for i := (fSpritesPerSet - 1) mod aimedCols + 1 to aimedCols - 1 do write(t, '<td></td>');
         writeln(t, '</tr>');
      end;
      writeln(t, '</table>');
   end else
   begin
      if aimedCols > fNumSets then aimedCols := fNumSets;
      writeln(t, '<table summary="Subsprites" border="1" rules="all">');
      for j := 0 to (fNumSets - 1) div aimedCols do
      begin
         writeln(t, '<tr valign="top">');
         for i := 0 to aimedCols - 1 do
         begin
            nr := j * aimedCols + i;
            if nr >= fNumSets then writeln(t, '<td></td>') else
            begin
               s := subSprite[nr];
               if s = nil then writeln(t, '<td>', i, '<br>Missing sprite') else
               begin
                  writeln(t, '<td>', s.printHtmlSpriteAnchor, '<a name="sprite', spriteNr, 'set', nr, '"><b>Set ', nr, '</b></a> - ', s.printHtmlSpriteNr, '<br><font size="-2">Linked from: ');
                  fLinkedFrom[nr].printHtml('content', t, path, settings, true);
                  write(t, '</font><br>');
                  if s is TRealSprite then s.printHtml(t, path, settings) else
                                           write(t, 'RealSprite expected');
               end;
               writeln(t, '</td>');
            end;
         end;
         writeln(t, '</tr>');
      end;
      writeln(t, '</table>');
   end;
end;


constructor TAction2.create(aNewGrfFile: TNewGrfFile; spriteNr: integer; feature: TFeature; cargoID: integer);
begin
   inherited create(aNewGrfFile, spriteNr);
   fFeature := feature;
   fCargoID := cargoID;
   fLinkedFrom := TSpriteSet.create;
end;

destructor TAction2.destroy;
begin
   fLinkedFrom.free;
   inherited destroy;
end;

class function TAction2.readAction2(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader; var action2Table: TAction2Table; action1: TAction1): TAction2;
var
   feature                              : TFeature;
   ID                                   : integer;
begin
   assert(ps.peekByte = $02);
   ps.getByte;
   feature := ps.getByte;
   ID := ps.getByte;
   case ps.peekByte of
      $80, $83, $84               : result := TRandomAction2.create(feature, ID, aNewGrfFile, ps, action2Table);
      $81, $82, $85, $86, $89, $8A: result := TVarAction2.create(feature, ID, aNewGrfFile, ps, action2Table);
      else                          case feature of
                                       FHouse, FIndTile: result := THouseIndTileAction2.create(feature, ID, aNewGrfFile, ps, action1);
                                       FIndustry       : result := TIndustryProductionCallback.create(feature, ID, aNewGrfFile, ps);
                                       else              result := TBasicAction2.create(feature, ID, aNewGrfFile, ps, action1);
                                    end;
   end;
   action2Table[ID] := result;
end;

procedure TAction2.registerLink(from: TNewGrfSprite);
begin
   fLinkedFrom.add(from);
end;

procedure TAction2.printLinkedFrom(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
begin
   write(t, '<font size="-2">Linked from: ');
   fLinkedFrom.printHtml('content', t, path, settings, true);
   writeln(t, '</font>');
end;


constructor TBasicAction2.create(feature: TFeature; cargoID: integer; aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader; action1: TAction1);
var
   i                                    : integer;
begin
   inherited create(aNewGrfFile, ps.spriteNr, feature, cargoID);
   fAction1 := action1;
   if fAction1 = nil then error('Missing Action1');
   setLength(fEntries[0], ps.getByte);
   setLength(fEntries[1], ps.getByte);
   for i := 0 to length(fEntries[0]) - 1 do
   begin
      fEntries[0][i] := ps.getWord;
      if (not checkCallback(fEntries[0][i])) and (fAction1 <> nil) then fAction1.registerLink(fEntries[0][i], self);
   end;
   for i := 0 to length(fEntries[1]) - 1 do
   begin
      fEntries[1][i] := ps.getWord;
      if (not checkCallback(fEntries[1][i])) and (fAction1 <> nil) then fAction1.registerLink(fEntries[1][i], self);
   end;
   if (length(fEntries[0]) <> 1) or (length(fEntries[1]) <> 0) then
   begin
      case fFeature of
         FCargo: error('Cargo Action2 must have num-ent1=1, num-ent2=0');
         FCanal: error('Canal Action2 must have num-ent1=1, num-ent2=0');
      end;
   end;
   testSpriteEnd(ps);
end;

function TBasicAction2.getNumEntries(typ: integer): integer;
begin
   result := length(fEntries[typ]);
end;

function TBasicAction2.getEntry(typ, nr: integer): word;
begin
   result := fEntries[typ][nr];
end;

procedure TBasicAction2.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   i                                    : integer;
   val                                  : word;
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>BasicAction2</b> - Define sprite groups<br>');
   printLinkedFrom(t, path, settings);
   writeln(t, '<table summary="Properties"><tr><th align="left">Feature</th><td>0x', intToHex(fFeature, 2), ' "', TableFeature[fFeature], '"</td></tr>');
   writeln(t, '<tr><th align="left">CargoID</th><td>0x', intToHex(cargoID, 2), '</td></tr>');
   write(t, '<tr><th align="left">');
   case fFeature of
      FCargo  : write(t, 'Cargo symbol');
      FCanal  : write(t, 'Canal graphics');
      FStation: write(t, 'Little cargo');
      else      write(t, 'Moving');
   end;
   writeln(t, '</th><td>');
   for i := 0 to length(fEntries[0]) - 1 do
   begin
      if i <> 0 then write(t, ', ');
      val := fEntries[0][i];
      if val and $8000 <> 0 then
      begin
         if val and $FF00 = $FF00 then val := val and $80FF;
         writeln(t, 'return 0x', intToHex(val and $7FFF, 4));
      end else
      begin
         if fAction1 = nil then writeln(t, 'Action1 Set ' + intToStr(val)) else
                                writeln(t, fAction1.printHtmlLinkToSet(val, 'content', settings));
      end;
   end;
   write(t, '</td></tr>');
   if (fFeature <> FCargo) and (fFeature <> FCanal) then
   begin
      if fFeature = FStation then write(t, '<tr><th align="left">Lots of cargo') else
                                  write(t, '<tr><th align="left">Loading/Unloading');
      writeln(t, '</th><td>');
      for i := 0 to length(fEntries[1]) - 1 do
      begin
         if i <> 0 then write(t, ', ');
         val := fEntries[1][i];
         if val and $8000 <> 0 then
         begin
            if val and $FF00 = $FF00 then val := val and $80FF;
            writeln(t, 'return 0x', intToHex(val and $7FFF, 4));
         end else
         begin
            if fAction1 = nil then writeln(t, 'Action1 Set ' + intToStr(val)) else
                                   writeln(t, fAction1.printHtmlLinkToSet(val, 'content', settings));
         end;
      end;
      write(t, '</td></tr>');
   end;
   writeln(t, '</table');
end;


constructor THouseIndTileAction2.create(feature: TFeature; cargoID: integer; aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader; action1: TAction1);
var
   num                                  : integer;
   spr                                  : longword;
   x, y                                 : shortint;
   z, w, h, dz                          : byte;
   i                                    : integer;
   desc                                 : TTTDPSprite;
begin
   inherited create(aNewGrfFile, ps.spriteNr, feature, cargoID);
   fSpriteLayout := TSpriteLayout.create(self, 'sprite' + intToStr(spriteNr));
   num := ps.getByte;
   fAction1 := action1;
   if fFeature = FHouse then fGroundSprite := TTTDPHouseSprite.create(self, ps.getDWord, fAction1) else
                             fGroundSprite := TTTDPIndustryTileSprite.create(self, ps.getDWord, fAction1);
   if num = 0 then
   begin
      spr := ps.getDWord;
      if fFeature = FHouse then desc := TTTDPHouseSprite.create(self, spr, fAction1) else
                                desc := TTTDPIndustryTileSprite.create(self, spr, fAction1);
      x := ps.getByte;
      y := ps.getByte;
      w := ps.getByte;
      h := ps.getByte;
      dz := ps.getByte;
      fSpriteLayout.addParentSprite(x, y, 0, w, h, dz, desc);
   end else
   begin
      for i := 0 to num - 1 do
      begin
         spr := ps.getDWord;
         if fFeature = FHouse then desc := TTTDPHouseSprite.create(self, spr, fAction1) else
                                   desc := TTTDPIndustryTileSprite.create(self, spr, fAction1);
         x := ps.getByte;
         y := ps.getByte;
         if ps.peekByte = $80 then
         begin
            ps.getByte;
            fSpriteLayout.addChildSprite(x, y, desc);
         end else
         begin
            z := ps.getByte;
            w := ps.getByte;
            h := ps.getByte;
            dz := ps.getByte;
            fSpriteLayout.addParentSprite(x, y, z, w, h, dz, desc);
         end;
      end;
   end;
   testSpriteEnd(ps);
end;

destructor THouseIndTileAction2.destroy;
begin
   fSpriteLayout.free;
   fGroundSprite.free;
   inherited destroy;
end;

procedure THouseIndTileAction2.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>Action2 for houses and industry tiles</b> - Define sprite layout<br>');
   printLinkedFrom(t, path, settings);
   writeln(t, '<table summary="Properties"><tr><th align="left">Feature</th><td>0x', intToHex(fFeature, 2), ' "', TableFeature[fFeature], '"</td></tr>');
   writeln(t, '<tr><th align="left">CargoID</th><td>0x', intToHex(cargoID, 2), '</td></tr>');
   writeln(t, '<tr><th align="left">Ground sprite</th><td>');
   fGroundSprite.printHtml(t, path, settings);
   writeln(t, '</td></tr>');
   writeln(t, '<tr valign="top"><th align="left">Sprite layout</th><td>');
   fSpriteLayout.printHtml(t, path, settings);
   writeln(t, '</td></tr></table>');
end;


constructor TIndustryProductionCallback.create(feature: TFeature; cargoID: integer; aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
var
   tmp                                  : integer;
begin
   inherited create(aNewGrfFile, ps.spriteNr, feature, cargoID);
   tmp := ps.getByte;
   fUseRegisters := tmp = $01;
   case tmp of
    $00: begin
            fInput[0] := ps.getWord;
            fInput[1] := ps.getWord;
            fInput[2] := ps.getWord;
            fOutput[0] := ps.getWord;
            fOutput[1] := ps.getWord;
            fAgain := ps.getByte;
         end;
    $01: begin
            fInput[0] := ps.getByte;
            fInput[1] := ps.getByte;
            fInput[2] := ps.getByte;
            fOutput[0] := ps.getByte;
            fOutput[1] := ps.getByte;
            fAgain := ps.getByte;
         end;
    else error('Unknown industry production callback version 0x' + intToHex(tmp, 2) + '. Stop.');
   end;
   testSpriteEnd(ps);
end;

function TIndustryProductionCallback.getInputAmount(i: integer): word;
begin
   result := fInput[i];
end;

function TIndustryProductionCallback.getOutputAmount(i: integer): word;
begin
   result := fOutput[i];
end;

procedure TIndustryProductionCallback.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   s                                    : string;
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>IndustryProcutionCallback</b> - Define industry production<br>');
   printLinkedFrom(t, path, settings);
   writeln(t, '<table summary="Properties"><tr><th align="left">Feature</th><td>0x', intToHex(fFeature, 2), ' "', TableFeature[fFeature], '"</td></tr>');
   writeln(t, '<tr><th align="left">CargoID</th><td>0x', intToHex(cargoID, 2), '</td></tr>');
   if fUseRegisters then
   begin
      writeln(t, '<tr><th align="left">Cargo input amounts</th><td> reg 0x',
                 intToHex(fInput[0], 2), ', reg 0x',
                 intToHex(fInput[1], 2), ', reg 0x',
                 intToHex(fInput[2], 2), '</td></tr>');
      writeln(t, '<tr><th align="left">Cargo output amounts</th><td> reg 0x',
                 intToHex(fOutput[0], 2), ', reg 0x',
                 intToHex(fOutput[1], 2), '</td></tr>');
      writeln(t, '<tr><th align="left">Again flag</th><td> reg 0x', intToHex(fAgain, 2), '</td></tr>');
   end else
   begin
      writeln(t, '<tr><th align="left">Cargo input amounts</th><td> 0x',
                 intToHex(fInput[0], 4), ' (', fInput[0], '), 0x',
                 intToHex(fInput[1], 4), ' (', fInput[1], '), 0x',
                 intToHex(fInput[2], 4), ' (', fInput[2], ')</td></tr>');
      writeln(t, '<tr><th align="left">Cargo output amounts</th><td> 0x',
                 intToHex(fOutput[0], 4), ' (', fOutput[0], '), 0x',
                 intToHex(fOutput[1], 4), ' (', fOutput[1], ')</td></tr>');
      if fAgain = 0 then s := ' "do not repeat callback"' else s := ' "repeat callback"';
      writeln(t, '<tr><th align="left">Again flag</th><td> 0x', intToHex(fAgain, 2), s, '</td></tr>');
   end;
   writeln(t, '</table>');
end;


constructor TVarAction2.create(feature: TFeature; cargoID: integer; aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader; const action2Table: TAction2Table);
var
   tmp                                  : integer;
   nr, i                                : integer;
   termTyp                              : byte;
begin
   inherited create(aNewGrfFile, ps.spriteNr, feature, cargoID);
   tmp := ps.getByte;
   fRelated := (tmp and 1) = 0;
   case tmp of
      $81, $82: fSize := 1;
      $85, $86: fSize := 2;
      $89, $8A: fSize := 4;
   end;
   nr := 0;
   repeat
      setLength(fFormula, nr + 1);
      with fFormula[nr] do
      begin
         if nr = 0 then operator := $0F else operator := ps.getByte; // first variable has no operator, but op. $0f matches.
         variable := ps.getByte;
         if variable in [$60..$7F] then parameter := ps.getByte else parameter := 0;
         if variable = $7E then proc := action2Table[parameter] else proc := nil;
         if proc <> nil then proc.registerLink(self);
         termTyp := ps.getByte;
         shift := termTyp and $1F;
         case termTyp and $C0 of
            $00: divMod := none;
            $40: divMod := division;
            $80: divMod := modulo;
            else begin
                    error('"Shift-And-Add-Division" and "Shift-And-Add-Modulo" must not be set both.');
                    divMod := none;
                 end;
         end;
         andMask := ps.get(fSize);
         if divMod <> none then
         begin
            addValue := signedCast(ps.get(fSize), fSize);
            divModValue := signedCast(ps.get(fSize), fSize);
         end else
         begin
            addValue := 0;
            divModValue := 0;
         end;
      end;
      inc(nr);
   until (termTyp and $20) = 0;
   setLength(fCases, ps.getByte);
   for i := 0 to length(fCases) - 1 do
      with fCases[i] do
      begin
         dest := readAction2Dest(self, ps, action2Table);
         min := ps.get(fSize);
         max := ps.get(fSize);
      end;
   fDefault := readAction2Dest(self, ps, action2Table);
   testSpriteEnd(ps);
end;

function TVarAction2.getTermCount: integer;
begin
   result := length(fFormula);
end;

function TVarAction2.getTerm(i: integer): TVarAction2Term;
begin
   result := fFormula[i];
end;

function TVarAction2.getIsComputedResult: boolean;
begin
   result := length(fCases) = 0;
end;

function TVarAction2.getNumCases: integer;
begin
   result := length(fCases);
end;

function TVarAction2.getCase(i: integer): TVarAction2Case;
begin
   result := fCases[i];
end;

procedure TVarAction2.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   i                                    : integer;
   s, s2                                : string;
   dest                                 : TAction2Dest;
   v                                    : longint;
   bracketsNeeded                       : boolean;
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>VarAction2</b> - Choose between Action2 chains<br>');
   printLinkedFrom(t, path, settings);
   writeln(t, '<table summary="Properties"><tr><th align="left">Feature</th><td>0x', intToHex(fFeature, 2), ' "', TableFeature[fFeature], '"</td></tr>');
   writeln(t, '<tr><th align="left">CargoID</th><td>0x', intToHex(cargoID, 2), '</td></tr>');
   case fSize of
      1: if fRelated then s := '0x82 byte of '  else s := '0x81 byte of ';
      2: if fRelated then s := '0x86 word of '  else s := '0x85 word of ';
      4: if fRelated then s := '0x8A dword of ' else s := '0x89 dword of ';
   end;
   if (fFeature >= low(TableAction0Features)) and (fFeature <= high(TableAction0Features)) then
   begin
      if fRelated then s := s + '"' + TableRelatedObject[fFeature] + '"' else
                       s := s + '"' + TablePrimaryObject[fFeature] + '"';
   end else
   begin
      if fRelated then s := s + '"related object"' else
                       s := s + '"current object"';
   end;
   writeln(t, '<tr><th align="left">VarAction2 Type</th><td>', s, '</td></tr>');
   writeln(t, '<tr valign="top"><th align="left">Formula</th><td>');
   for i := 0 to length(fFormula) - 1 do
      with fFormula[i] do
      begin
         if i <> 0 then write(t, '<br>');
         bracketsNeeded := false;
         if variable = $1A then
         begin
            v := ($FFFFFFFF shr shift) and andMask;
            if divMod <> none then
            begin
               v := signedCast(v + addValue, fSize);
               if divMod = division then v := v div divModValue else v := v mod divModValue;
            end;
            v := unsignedCast(v, fSize);
            s := '0x' + intToHex(v, 2 * fSize);
         end else
         begin
            if variable = $7E then
            begin
               dest.value := parameter;
               dest.dest := proc;
               s := 'ResultOf[' + printAction2Dest(dest, settings) + ']';
            end else
            begin
               s := TableVariables[variable];
               if (s = 'unknown') and (fFeature >= low(TableAction0Features)) and (fFeature <= high(TableAction0Features)) then
               begin
                  if fRelated then s := TableVarAction2Related[fFeature][variable] else
                                   s := TableVarAction2Features[fFeature][variable];
               end;
               s := 'Var' + intToHex(variable, 2) + '"' + s + '"';
               if variable in [$60..$7F] then s := s + '[0x' + intToHex(parameter, 2) + ']';
               bracketsNeeded := true;
            end;
            if shift <> 0 then
            begin
               if bracketsNeeded then s := '(' + s + ')';
               s := s + ' shr ' + intToStr(shift);
               bracketsNeeded := true;
            end;
            v := $FFFFFFFF shr max(shift, 8 * (4 - fSize)); // Bits that are not already masked out by shift or size
            if longint(andMask) and v <> v then
            begin
               if bracketsNeeded then s := '(' + s + ')';
               s := s + ' and 0x' + intToHex(andMask, 2 * fSize);
               bracketsNeeded := true;
            end;
            if divMod <> none then
            begin
               if addValue <> 0 then
               begin
                  if bracketsNeeded then s := '(' + s + ')';
                  if addValue < 0 then s := s + ' - ' + intToStr(-addValue) else
                                       s := s + ' + ' + intToStr( addValue);
                  bracketsNeeded := true;
               end;
               if divMod = division then
               begin
                  if divModValue <> 1 then
                  begin
                     if bracketsNeeded then s := '(' + s + ')';
                     s := s + ' div<sub>[signed]</sub> ' + intToStr(divModValue);
                     bracketsNeeded := true;
                  end;
               end else
               begin
                  if bracketsNeeded then s := '(' + s + ')';
                  s := s + ' mod<sub>[signed]</sub> ' + intToStr(divModValue);
                  bracketsNeeded := true;
               end;
            end;
         end;

         s2 := TableVarAction2Operator[operator];
         if s2 = 'unknown' then s2 := 'value := unknownOperator[0x' + intToHex(operator, 2) + '](value, $$$)';

         if not bracketsNeeded then s2 := stringReplace(s2, '($$$)', '$$$', [rfReplaceAll]);
         s2 := stringReplace(s2, '$$$', s, [rfReplaceAll]);
         writeln(t, s2);
      end;
   writeln(t, '</td></tr><tr valign="top"><th align="left">Decision</th><td>');
   if length(fCases) = 0 then writeln(t, 'return computed result') else
   begin
      writeln(t, '<table summary="Result" border="1" rules="all"><tr><th>From</th><th>To</th><th></th></tr>');
      for i := 0 to length(fCases) - 1 do
         with fCases[i] do
         begin
            writeln(t, '<tr><td>0x', intToHex(min, 2 * fSize), ' (', min, ')</td><td>0x', intToHex(max, 2 * fSize), ' (', max, ')</td><td>',
                       printAction2Dest(fCases[i].dest, settings), '</td></tr>');
         end;
      writeln(t, '</table>');
   end;
   writeln(t, '</td></tr><tr><th align="left">Default</th><td>', printAction2Dest(fDefault, settings), '</td></tr></table');
end;


constructor TRandomAction2.create(feature: TFeature; cargoID: integer; aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader; const action2Table: TAction2Table);
var
   i                                    : integer;
begin
   inherited create(aNewGrfFile, ps.spriteNr, feature, cargoID);
   case ps.getByte of
      $80: fType := current;
      $83: fType := related;
      $84: begin
              if (feature < FTrain) or (feature > FAircraft) then error('RandomAction2 type 0x84 is only valid for vehicles.');
              case ps.peekByte and $C0 of
                 $00: fType := vehicleBackwards;
                 $40: fType := vehicleForwards;
                 $80: fType := vehicleAbsolute;
                 $C0: fType := vehicleChain;
              end;
              fVehiclePos := ps.getByte and $0F;
           end;
      else assert(false);
   end;
   fAllTriggers := (ps.peekByte and $80) <> 0;
   fTriggers := ps.getByte and $7F;
   fRandBit := ps.getByte;

   setLength(fCases, ps.getByte);
   for i := 0 to length(fCases) - 1 do fCases[i] := readAction2Dest(self, ps, action2Table);

   testSpriteEnd(ps);

   i := length(fCases);
   fRandCount := 0;
   if i = 0 then error('"nrand" must not be zero.') else
   begin
      while i and 1 = 0 do
      begin
         inc(fRandCount);
         i := i shr 1;
      end;
      if i <> 1 then error('"nrand" must be a power of two.')
   end;
end;

function TRandomAction2.getNumCases: integer;
begin
   result := length(fCases);
end;

function TRandomAction2.getCase(i: integer): TAction2Dest;
begin
   result := fCases[i];
end;

procedure TRandomAction2.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   s                                    : string;
   i                                    : integer;
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>RandomAction2</b> - Randomized choice between Action2s<br>');
   printLinkedFrom(t, path, settings);
   writeln(t, '<table summary="Properties"><tr><th align="left">Feature</th><td>0x', intToHex(fFeature, 2), ' "', TableFeature[fFeature], '"</td></tr>');
   writeln(t, '<tr><th align="left">CargoID</th><td>0x', intToHex(cargoID, 2), '</td></tr>');
   case fType of
      current: begin
                  s := '0x80 "';
                  if (fFeature >= low(TableAction0Features)) and
                     (fFeature <= high(TableAction0Features)) then s := s + TablePrimaryObject[fFeature] + '"' else
                                                                   s := s + 'current object"';
               end;
      related: begin
                  s := '0x83 "';
                  if (fFeature >= low(TableAction0Features)) and
                     (fFeature <= high(TableAction0Features)) then s := s + TableRelatedObject[fFeature] + '"' else
                                                                   s := s + 'related object"';
               end;
      else     begin
                  if fVehiclePos = 0 then s := '<register 0x100>' else s := intToStr(fVehiclePos);
                  case fType of
                     vehicleBackwards: s := '0x84 0x' + intToHex(fVehiclePos      , 2) + ' "vehicle at position ' + s + ' after current vehicle"';
                     vehicleForwards:  s := '0x84 0x' + intToHex(fVehiclePos + $40, 2) + ' "vehicle at position ' + s + ' before current vehicle"';
                     vehicleAbsolute:  s := '0x84 0x' + intToHex(fVehiclePos + $80, 2) + ' "vehicle at position ' + s + ' from front"';
                     vehicleChain:     s := '0x84 0x' + intToHex(fVehiclePos + $C0, 2) + ' "vehicle at position ' + s + ' after first vehicle in current chain of vehicles with same ID"';
                  end;
               end;
   end;
   writeln(t, '<tr><th align="left">Trigger source </th><td>', s, '</td></tr>');
   if fAllTriggers then s := 'All of' else s := 'Any of';
   write(t, '<tr><th align="left">Trigger</th><td>', s, ': 0x', intToHex(fTriggers, 2));
   s := '';
   if (fFeature >= low(TableAction0Features)) and (fFeature <= high(TableAction0Features)) then
   begin
      for i := 0 to 6 do
         if fTriggers and (1 shl i) <> 0 then
         begin
            if s <> '' then s := s + ', ';
            s := s + '"' + TableRandomAction2Features[fFeature][i] + '"';
         end;
   end;
   writeln(t, ' ', s, '</td></tr>');
   writeln(t, '<tr><th align="left">Random bits</th><td>', fRandBit, ' to ', fRandBit + fRandCount - 1, ' (', fRandCount, ' bits)</td></tr>');
   writeln(t, '<tr valign="top"><th align="left">Choose between</th><td>');
   for i := 0 to length(fCases) - 1 do
   begin
      if i <> 0 then write(t, ', ');
      writeln(t, printAction2Dest(fCases[i], settings));
   end;
   writeln(t, '</td></tr></table>');
end;


constructor TAction3.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader; const action2Table: TAction2Table);
var
   tmp                                  : integer;
   i                                    : integer;
begin
   inherited create(aNewGrfFile, ps.spriteNr);
   assert(ps.peekByte = $03);
   ps.getByte;
   fFeature := ps.getByte;
   tmp := ps.getByte;
   fLivery := (tmp and $80) <> 0;
   setLength(fFeatID, tmp and $7F);
   if (fFeature >= FTrain) and (fFeature <= FAircraft) then
   begin
      for i := 0 to length(fFeatID) - 1 do fFeatID[i] := ps.getExtByte;
   end else
   begin
      for i := 0 to length(fFeatID) - 1 do fFeatID[i] := ps.getByte;
   end;
   tmp := ps.getByte;
   setLength(fCargoBit, tmp);
   setLength(fDest, tmp);
   for i := 0 to length(fDest) - 1 do
   begin
      fCargoBit[i] := ps.getByte;
      fDest[i] := readAction2Dest(self, ps, action2Table);
   end;
   fDefault := readAction2Dest(self, ps, action2Table);
   testSpriteEnd(ps);

   for i := 0 to length(fFeatID) - 1 do newGrfFile.registerEntity(fFeature, fFeatID[i], self);
end;

function TAction3.getGenericCallback: boolean;
begin
   result := length(fFeatID) = 0;
end;

function TAction3.getFeatIDCount: integer;
begin
   result := length(fFeatID);
end;

function TAction3.getFeatID(i: integer): integer;
begin
   result := fFeatID[i];
end;

function TAction3.getDestCnt: integer;
begin
   result := length(fDest);
end;

function TAction3.getCargoBit(i: integer): integer;
begin
   result := fCargoBit[i];
end;

function TAction3.getDest(i: integer): TAction2Dest;
begin
   result := fDest[i];
end;

procedure TAction3.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   s, s2                                : string;
   i                                    : integer;
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>Action3</b> - Install graphic sets');
   writeln(t, '<table summary="Properties"><tr><th align="left">Feature</th><td>0x',intToHex(fFeature,2),' "', TableFeature[fFeature], '"</td></tr>');
   if genericCallback then s := 'generic feature callback' else
   if liveryOverride  then s := 'livery override' else
                           s := 'normal action3';
   writeln(t, '<tr><th align="left">Type</th><td>', s, '</td></tr>');
   if not genericCallback then
   begin
      s := '';
      for i := 0 to length(fFeatID) - 1 do
      begin
         if (fFeature >= FTrain) and (fFeature <= FAircraft) then
         begin
            s2 := '0x' + intToHex(fFeatID[i], 4);
         end else
         begin
            s2 := '0x' + intToHex(fFeatID[i], 2);
         end;
         if (settings.entityFrame = boolYes) and (newGrfFile.entity[fFeature, fFeatID[i]] <> nil) then s2 := newGrfFile.printEntityLinkBegin('content', fFeature, fFeatID[i]) + s2 + '</a> ';
         s := s + s2;
      end;
      writeln(t, '<tr><th align="left">IDs</th><td>', s, '</td></tr>');
   end;
   for i := 0 to length(fDest) - 1 do
   begin
      writeln(t, '<tr><th align="left">cargobit 0x', intToHex(fCargoBit[i], 2), ' (', fCargoBit[i], ')</th><td>',
                 printAction2Dest(fDest[i], settings), '</td></tr>');
   end;
   writeln(t, '<tr><th align="left">default</th><td>', printAction2Dest(fDefault, settings), '</td></tr></table>');
end;


end.
