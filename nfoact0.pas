(* This file is part of Grf2Html.
 * Copyright 2007-2008 by Christoph Elsenhans.
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
unit nfoact0;

interface

uses sysutils, nfobase, tables, math, spritelayout, outputsettings;

type
   TAction0 = class;

   TAction0SpecialProperty = class
   protected
      fAction0             : TAction0;
   public
      constructor create(action0: TAction0);
      procedure printHtmlBegin(var t: textFile; path: string; const settings: TGrf2HtmlSettings; const propName: string; numIDs: integer); virtual;
      procedure printHtmlPre(var t: textFile; path: string; const settings: TGrf2HtmlSettings; const propName: string; const ID: string); virtual;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); virtual; abstract;
      procedure printHtmlPost(var t: textFile; path: string; const settings: TGrf2HtmlSettings); virtual;
      procedure printHtmlEnd(var t: textFile; path: string; const settings: TGrf2HtmlSettings); virtual;
   end;

   TAction0SpecialPropertyArrayItem = class(TAction0SpecialProperty)
      constructor create(action0: TAction0; ps: TPseudoSpriteReader; ID, nr: integer); virtual;
      class function itemCount(ps: TPseudoSpriteReader): integer; virtual; abstract; // Number of items; -1 = use MoreItems
      class function moreItems(ps: TPseudoSpriteReader): boolean; virtual; abstract;
   end;

   TAction0SpecialPropertyArrayItemClass = class of TAction0SpecialPropertyArrayItem;

   // Used for StationSpriteLayouts, StationCustomyLayouts, IndustryLayouts
   TAction0SpecialPropertyArray = class(TAction0SpecialProperty)
   private
      fItems                    : array of TAction0SpecialPropertyArrayItem;
      function getCount: integer;
      function getItem(i: integer): TAction0SpecialPropertyArrayItem;
   public
      constructor create(action0: TAction0; ps: TPseudoSpriteReader; ID: integer; typ: TAction0SpecialPropertyArrayItemClass);
      destructor destroy; override;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property count: integer read getCount;
      property item[i: integer]: TAction0SpecialPropertyArrayItem read getItem;
   end;

   TAction0SnowlineHeight = class(TAction0SpecialProperty)
   private
      fSnowline           : array[0..11, 0..31] of byte;
      function getSnowline(month, day: integer): byte;
   public
      constructor create(action0: TAction0; ps: TPseudoSpriteReader);
      procedure printHtmlPre(var t: textFile; path: string; const settings: TGrf2HtmlSettings; const propName: string; const ID: string); override;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property snowline[month, day: integer]: byte read getSnowline; // month and day start with 0
   end;

   // Used for HouseCargoWatch, IndustryRandomSound
   TAction0ByteArray = class(TAction0SpecialProperty)
   private
      fData          : array of byte;
      function getCount: integer;
      function getData(i: integer): byte;
   public
      constructor create(action0: TAction0; ps: TPseudoSpriteReader);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property count: integer read getCount;
      property data[i: integer]: byte read getData;
   end;

   TAction0StationSpriteLayout = class(TAction0SpecialPropertyArrayItem)
   private
      fTTDLayout               : boolean;
      fGroundSprite            : TTTDPStationSprite;
      fSpriteLayout            : TSpriteLayout;
   public
      constructor create(action0: TAction0; ps: TPseudoSpriteReader; ID, nr: integer); override;
      destructor destroy; override;
      class function itemCount(ps: TPseudoSpriteReader): integer; override;
      class function moreItems(ps: TPseudoSpriteReader): boolean; override;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property useTTDSpriteLayout: boolean read fTTDLayout;
      property groundSprite: TTTDPStationSprite read fGroundSprite;
      property spritelayout: TSpriteLayout read fSpriteLayout;
   end;

   TAction0StationCustomLayout = class(TAction0SpecialPropertyArrayItem)
   private
      fCustomLayout            : array of array of byte;
      function getPlatformCount: integer;
      function getPlatformLength: integer;
      function getTileLayout(platform, tile: integer): byte;
   public
      constructor create(action0: TAction0; ps: TPseudoSpriteReader; ID, nr: integer); override;
      class function itemCount(ps: TPseudoSpriteReader): integer; override;
      class function moreItems(ps: TPseudoSpriteReader): boolean; override;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property platformCount: integer read getPlatformCount;
      property platformLength: integer read getPlatformLength;
      property tileLayout[platform, tile: integer]: byte read getTileLayout;
   end;

   // Table 0..5: MiddleParts; Index0: Rail, Road, Mono, Magl; Index1: X, Y;       Index2: Back&Floor, Front, Pillars, unused
   // Table 6:    EndParts;    Index0: Rail, Road, Mono, Magl; Index1: flat, ramp; Index2: North X, North Y, South X, South Y
   TBridgeLayoutTable = array[0..3, 0..1, 0..3] of longword;

   TAction0BridgeLayout = class(TAction0SpecialProperty)
   private
      fFirstTable       : byte;
      fTables           : array of TBridgeLayoutTable;
      function getTableCount: integer;
      function getTableNr(i: integer): byte;
      function getTableData(i: integer): TBridgeLayoutTable;
   public
      constructor create(action0: TAction0; ps: TPseudoSpriteReader);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property tableCount: integer read getTableCount;
      property tableNr[i: integer]: byte read getTableNr;
      property tableData[i: integer]: TBridgeLayoutTable read getTableData;
   end;

   TIndustryLayoutTile = record
      position         : array[0..1] of shortint;
      typ              : (oldTile, newTile, empty);
      tile             : word;
   end;

   TAction0GrfIDOverrideForEngines = class(TAction0SpecialProperty)
   private
      fSrc, fDest                 : longword;
   public
      constructor create(action0: TAction0; ps: TPseudoSpriteReader);
      procedure printHtmlBegin(var t: textFile; path: string; const settings: TGrf2HtmlSettings; const propName: string; numIDs: integer); override;
      procedure printHtmlPre(var t: textFile; path: string; const settings: TGrf2HtmlSettings; const propName: string; const ID: string); override;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      procedure printHtmlEnd(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property SrcID: longword read fSrc;
      property DestID: longword read fDest;
   end;

   TAction0IndustryLayout = class(TAction0SpecialPropertyArrayItem)
   private
      fTiles              : array of TIndustryLayoutTile;
      function getTileCount: integer;
      function getTile(i: integer): TIndustryLayoutTile;
   public
      constructor create(action0: TAction0; ps: TPseudoSpriteReader; ID, nr: integer); override;
      class function itemCount(ps: TPseudoSpriteReader): integer; override;
      class function moreItems(ps: TPseudoSpriteReader): boolean; override;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property tileCount: integer read getTileCount;
      property tile[i: integer]: TIndustryLayoutTile read getTile;
   end;

   TAction0DataType = (a0unsigned, a0signed, a0hex, a0str, a0special);
   TAction0Data = record
      size      : shortint; // -1 for special, 1 - 4 plain
      typ       : TAction0DataType;
      case shortint of
          0: (plainunsigned: longword);
          1: (plainsigned  : longint);
         -1: (special: TAction0SpecialProperty);
   end;

   TAction0 = class(TNewGrfSprite)
   private
      fFeature   : TFeature;
      fProps     : array of byte;
      fNumIDs    : integer;
      fFirstID   : integer;
      fData      : array of array of TAction0Data;
      function getNumProps: integer;
      function getProp(i: integer): byte;
      function getFeatID(i: integer): integer;
      function getData(propNr, IDNr: integer): TAction0Data;
   protected
      function getPropFromTable(p: byte; out format: string): string;
   public
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
      destructor destroy; override;
      procedure secondPass; override;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property feature: TFeature read fFeature;
      property numProps: integer read getNumProps;
      property prop[i: integer]: byte read getProp;
      property numFeatIds: integer read fNumIDs;
      property featId[i: integer]: integer read getFeatID;
      property data[propNr, IDNr: integer]: TAction0Data read getData;
   end;

implementation

constructor TAction0SpecialProperty.create(action0: TAction0);
begin
   inherited create;
   fAction0 := action0;
end;

procedure TAction0SpecialProperty.printHtmlBegin(var t: textFile; path: string; const settings: TGrf2HtmlSettings; const propName: string; numIDs: integer);
begin
   // nothing
end;

procedure TAction0SpecialProperty.printHtmlPre(var t: textFile; path: string; const settings: TGrf2HtmlSettings; const propName: string; const ID: string);
begin
   writeln(t, '<br><b>', propName, ' - ', ID, '</b><br>');
end;

procedure TAction0SpecialProperty.printHtmlPost(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
begin
   // nothing
end;

procedure TAction0SpecialProperty.printHtmlEnd(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
begin
   // nothing
end;

constructor TAction0SpecialPropertyArrayItem.create(action0: TAction0; ps: TPseudoSpriteReader; ID, nr: integer);
begin
   inherited create(action0);
end;

constructor TAction0SpecialPropertyArray.create(action0: TAction0; ps: TPseudoSpriteReader; ID: integer; typ: TAction0SpecialPropertyArrayItemClass);
var
   i                                    : integer;
   c                                    : integer;
begin
   inherited create(action0);
   c := typ.itemCount(ps);
   if c = -1 then
   begin
      setLength(fItems, 0);
      i := 0;
      while typ.moreItems(ps) do
      begin
         setLength(fItems, i + 1);
         fItems[i] := typ.create(action0, ps, ID, i);
         inc(i);
      end;
   end else
   begin
      setLength(fItems, c);
      for i := 0 to c - 1 do fItems[i] := typ.create(action0, ps, ID, i);
   end;
end;

destructor TAction0SpecialPropertyArray.destroy;
var
   i                                    : integer;
begin
   for i := 0 to length(fItems) - 1 do fItems[i].free;
   setlength(fItems, 0);
   inherited destroy;
end;

function TAction0SpecialPropertyArray.getCount: integer;
begin
   result := length(fItems);
end;

function TAction0SpecialPropertyArray.getItem(i: integer): TAction0SpecialPropertyArrayItem;
begin
   result := fItems[i];
end;

procedure TAction0SpecialPropertyArray.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   i                                    : integer;
begin
   writeln(t, '<table summary="Property value" width="100%" border="1" rules="all">');
   for i := 0 to length(fItems) - 1 do
   begin
      writeln(t, '<tr valign="top"><th align="left" width="', settings.action0subIndexColWidth, '">', i, '</th><td>');
      fItems[i].printHtml(t, path, settings);
      writeln(t, '</td></tr>');
   end;
   writeln(t, '</table>');
end;

constructor TAction0SnowlineHeight.create(action0: TAction0; ps: TPseudoSpriteReader);
var
   i, j                                 : integer;
begin
   inherited create(action0);
   for i := 0 to 11 do
      for j := 0 to 31 do
         fSnowline[i, j] := ps.getByte;
end;

function TAction0SnowlineHeight.getSnowline(month, day: integer): byte;
begin
   result := fSnowline[month, day];
end;

procedure TAction0SnowlineHeight.printHtmlPre(var t: textFile; path: string; const settings: TGrf2HtmlSettings; const propName: string; const ID: string);
begin
   // nothing
end;

procedure TAction0SnowlineHeight.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
const
   months                               : array[0..11] of string = ('January', 'February', 'March',
                                                                    'April', 'May', 'June',
                                                                    'July', 'August', 'September',
                                                                    'October', 'November', 'December');
   monthLen                             : array[0..11] of integer = (31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
var
   i, j                                 : integer;
begin
   // TODO this breaks all tables
   write(t, '<br><b>SnowLineHeight Table</b><table summary="Property value" border="1" rules="all"><tr><th>Month</th>');
   for i := 0 to 31 do write(t, '<th>', i + 1, '.</th>');
   writeln(t, '</tr>');
   for i := 0 to 11 do
   begin
      write(t, '<tr><th align="left">', months[i], '</th>');
      for j := 0 to 31 do
      begin
         if j < monthLen[i] then write(t, '<td>0x', intToHex(fSnowline[i, j], 2), ' (', fSnowline[i, j], ')</td>') else
                                 write(t, '<td><i>0x', intToHex(fSnowline[i, j], 2), ' (', fSnowline[i, j], ')</i></td>');
      end;
      writeln(t, '</tr>');
   end;
   writeln(t, '</table>');
end;

constructor TAction0ByteArray.create(action0: TAction0; ps: TPseudoSpriteReader);
var
   i                                    : integer;
begin
   inherited create(action0);
   setLength(fData, ps.getByte);
   for i := 0 to length(fData) - 1 do fData[i] := ps.getByte;
end;

function TAction0ByteArray.getCount: integer;
begin
   result := length(fData);
end;

function TAction0ByteArray.getData(i: integer): byte;
begin
   result := fData[i];
end;

procedure TAction0ByteArray.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   i                                    : integer;
begin
   write(t, length(fData), ' entries: ');
   for i := 0 to length(fData) - 1 do
   begin
      if i = 0 then write(t, '0x', intToHex(fData[i], 2)) else
                    write(t, ', 0x', intToHex(fData[i], 2));
   end;
   writeln(t, '<br>');
end;

constructor TAction0StationSpriteLayout.create(action0: TAction0; ps: TPseudoSpriteReader; ID, nr: integer);
var
   tmp                                  : longword;
   x, y, z                              : shortint;
   w, h, dz                             : byte;
   spr                                  : longword;
begin
   inherited create(action0, ps, ID, nr);
   fGroundSprite := nil;
   fSpriteLayout := TSpriteLayout.create(action0, 'sprite' + intToStr(action0.spriteNr) + 'id' + intToStr(ID) + 'nr' + intToStr(nr));
   tmp := ps.getDWord;
   fTTDLayout := tmp = 0;
   if not fTTDLayout then
   begin
      fGroundSprite := TTTDPStationSprite.create(action0, tmp, true);
      repeat
         tmp := ps.getByte;
         if tmp <> $80 then
         begin
            x := tmp;
            y := ps.getByte;
            if ps.peekByte <> $80 then
            begin
               z := ps.getByte;
               w := ps.getByte;
               h := ps.getByte;
               dz := ps.getByte;
               spr := ps.getDWord;
               fSpriteLayout.addParentSprite(x, y, z, w, h, dz, TTTDPStationSprite.create(action0, spr, false));
            end else
            begin
               ps.getByte; // z pos
               ps.getByte; // x ext
               ps.getByte; // y ext
               ps.getByte; // z ext
               spr := ps.getDWord;
               if not fSpriteLayout.addChildSprite(x, y, TTTDPStationSprite.create(action0, spr, false)) then fAction0.error('StationSpriteLayout: First Sprite in a layout must not be a ChildSprite.');
            end;
         end;
      until (tmp = $80) or (ps.bytesLeft < 0);
   end;
end;

destructor TAction0StationSpriteLayout.destroy;
begin
   fSpriteLayout.free;
   inherited destroy;
end;

class function TAction0StationSpriteLayout.itemCount(ps: TPseudoSpriteReader): integer;
begin
   result := ps.getExtByte;
end;

class function TAction0StationSpriteLayout.moreItems(ps: TPseudoSpriteReader): boolean;
begin
   result := false; // use ItemCount
end;

procedure TAction0StationSpriteLayout.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
begin
   if fTTDLayout then writeln(t, '<b>TTD Sprite Layout</b>') else
   begin
      writeln(t, '<b>Custom Sprite Layout</b><br><b>Ground sprite:</b> ');
      fGroundSprite.printHtml(t, path, settings);
      fSpriteLayout.printHtml(t, path, settings);
   end;
end;

constructor TAction0StationCustomLayout.create(action0: TAction0; ps: TPseudoSpriteReader; ID, nr: integer);
var
   i, j, n, m                           : integer;
begin
   inherited create(action0, ps, ID, nr);
   n := ps.getByte;
   m := ps.getByte;
   setLength(fCustomLayout, m, n);
   for i := 0 to m - 1 do
      for j := 0 to n - 1 do
         fCustomLayout[i, j] := ps.getByte;
end;

class function TAction0StationCustomLayout.itemCount(ps: TPseudoSpriteReader): integer;
begin
   result := -1; // use MoreItems
end;

class function TAction0StationCustomLayout.moreItems(ps: TPseudoSpriteReader): boolean;
begin
   result := ps.peekWord <> 0;
   if not result then ps.getWord;
end;

function TAction0StationCustomLayout.getPlatformCount: integer;
begin
   result := length(fCustomLayout);
end;

function TAction0StationCustomLayout.getPlatformLength: integer;
begin
   if length(fCustomLayout) > 0 then result := length(fCustomLayout[0]) else result := 0;
end;

function TAction0StationCustomLayout.getTileLayout(platform, tile: integer): byte;
begin
   result := fCustomLayout[platform][tile];
end;

procedure TAction0StationCustomLayout.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   i, j                                 : integer;
begin
   write(t, '<table summary="Station Custom Layout" border="1" rules="all"><th></th>');
   for i := 0 to platformLength - 1 do write(t, '<th>Part ', i, '</th>');
   writeln(t, '</tr>');
   for i := 0 to length(fCustomLayout) - 1 do
   begin
      write(t, '<tr><th align="left">Platform ', i, '</th>');
      for j := 0 to length(fCustomLayout[i]) - 1 do write(t, '<td>0x', intToHex(fCustomLayout[i, j], 2), ' (', fCustomLayout[i, j], ')</td>');
      writeln(t, '</tr>');
   end;
   writeln(t, '</table>');
end;

constructor TAction0BridgeLayout.create(action0: TAction0; ps: TPseudoSpriteReader);
var
   i, j, k, l                           : integer;
begin
   inherited create(action0);
   fFirstTable := ps.getByte;
   setLength(fTables, ps.getByte);
   for i := 0 to length(fTables) - 1 do
      for j := 0 to 3 do
         for k := 0 to 1 do
            for l := 0 to 3 do
               fTables[i][j, k, l] := ps.getDWord;
end;

function TAction0BridgeLayout.getTableCount: integer;
begin
   result := length(fTables);
end;

function TAction0BridgeLayout.getTableNr(i: integer): byte;
begin
   result := fFirstTable + i;
end;

function TAction0BridgeLayout.getTableData(i: integer): TBridgeLayoutTable;
begin
   result := fTables[i];
end;

procedure TAction0BridgeLayout.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
const
   tableNames                           : array[0..6] of string = (
      'Table 0: Middle tile, First from North',
      'Table 1: Middle tile, First from South',
      'Table 2: Middle tile, Even positions from North, Odd positions from South',
      'Table 3: Middle tile, Odd positions from North, Even positions from South',
      'Table 4: Middle tile, Center for bridges with 3, 7, 11, ... middle tiles',
      'Table 6: Middle tile, Center for bridges with 5, 9, 13, ... middle tiles',
      'Table 7: Bridge ramps'
   );
   rowNames                             : array[0..3] of string = ('Railroad', 'Road', 'Monorail', 'Maglev');
var
   i, j, k                              : integer;
   s                                    : string;
begin
   writeln(t, '<table summary="Property value" width="100%" rules="none">');
   for i := 0 to length(fTables) - 1 do
   begin
      if tableNr[i] in [0..6] then s := tableNames[tableNr[i]] else s := 'TableNr out of range';
      writeln(t, '<tr><th colspan="2" align="left">', s, '</th></tr><tr><td width="30"></td><td>');
      if tableNr[i] = 6 then
      begin
         writeln(t, '<table summary="Bridge Sprite Table" border="1" rules="all"><tr><th></th>' +
                    '<th>North X Flat</th><th>North Y Flat</th><th>South X Flat</th><th>South Y Flat</th>' +
                    '<th>North X Ramp</th><th>North Y Ramp</th><th>South X Ramp</th><th>South Y Ramp</th></tr>');
      end else
      begin
         writeln(t, '<table summary="Bridge Sprite Table" border="1" rules="all"><tr><th></th>' +
                    '<th>Back+Floor X</th><th>Front X</th><th>Pillars X</th><th>unused</th>' +
                    '<th>Back+Floor Y</th><th>Front Y</th><th>Pillars Y</th><th>unused</th></tr>');
      end;
      for j := 0 to 3 do
      begin
         write(t, '<tr><th align="left">', rowNames[j], '</th>');
         for k := 0 to 7 do write(t, '<td>0x', intToHex(fTables[i][j, k div 4, k mod 4], 8), '</td>');
         writeln(t, '</tr>');
      end;
      writeln(t, '</table></td></tr>');
   end;
   writeln(t, '</table>');
end;


constructor TAction0GrfIDOverrideForEngines.create(action0: TAction0; ps: TPseudoSpriteReader);
begin
   inherited create(action0);
   fSrc := ps.getDWord;
   fDest := ps.getDWord;
end;

procedure TAction0GrfIDOverrideForEngines.printHtmlBegin(var t: textFile; path: string; const settings: TGrf2HtmlSettings; const propName: string; numIDs: integer);
begin
   writeln(t, '<br><b>', propName, '</b><table border="1" rules="all"><tr><th>Engines from</th><th>override engines in</th></tr>');
end;

procedure TAction0GrfIDOverrideForEngines.printHtmlPre(var t: textFile; path: string; const settings: TGrf2HtmlSettings; const propName: string; const ID: string);
begin
   // nothing
end;

procedure TAction0GrfIDOverrideForEngines.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
begin
   writeln(t, '<tr><td>', grfID2Str(fSrc), '</td><td>', grfID2Str(fDest), '</td></tr>');
end;

procedure TAction0GrfIDOverrideForEngines.printHtmlEnd(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
begin
   writeln(t, '</table>');
end;


constructor TAction0IndustryLayout.create(action0: TAction0; ps: TPseudoSpriteReader; ID, nr: integer);
var
   cnt                                  : integer;
   tmp1, tmp2, tmp3                     : byte;
begin
   inherited create(action0, ps, ID, nr);
   setLength(fTiles, 0);
   cnt := 0;
   repeat
      tmp1 := ps.getByte;
      tmp2 := ps.getByte;
      if (tmp1 <> $00) or (tmp2 <> $80) then
      begin
         setLength(fTiles, cnt + 1);
         fTiles[cnt].position[0] := tmp1;
         fTiles[cnt].position[1] := tmp2;
         tmp3 := ps.getByte;
         case tmp3 of
            $FF: fTiles[cnt].typ := empty;
            $FE: begin
                    fTiles[cnt].typ := newTile;
                    fTiles[cnt].tile := ps.getWord;
                 end;
            else begin
                    fTiles[cnt].typ := oldTile;
                    fTiles[cnt].tile := tmp3;
                 end;
         end;
         inc(cnt);
      end;
   until ((tmp1 = $00) and (tmp2 = $80)) or (ps.bytesLeft < 0);
end;

class function TAction0IndustryLayout.itemCount(ps: TPseudoSpriteReader): integer;
begin
   result := ps.getByte;
   ps.getDWord; // total size
end;

class function TAction0IndustryLayout.moreItems(ps: TPseudoSpriteReader): boolean;
begin
   result := false; // use ItemCount
end;

function TAction0IndustryLayout.getTileCount: integer;
begin
   result := length(fTiles);
end;

function TAction0IndustryLayout.getTile(i: integer): TIndustryLayoutTile;
begin
   result := fTiles[i];
end;

procedure TAction0IndustryLayout.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   xMin, yMin, xMax, yMax, x, y, i      : integer;
   layout                               : array of array of integer;
   s                                    : string;
begin
   if length(fTiles) > 0 then
   begin
      xMin := high(xMin);
      xMax := low(xMax);
      yMin := high(yMin);
      yMax := low(yMax);
      for i := 0 to length(fTiles) - 1 do
      begin
         x := fTiles[i].position[0];
         y := fTiles[i].position[1];
         if x < 0 then inc(y); // "If xoffs is negative, yoffs must be one lower than the wanted value." <- reverse this
         if xMin > x then xMin := x;
         if xMax < x then xMax := x;
         if yMin > y then yMin := y;
         if yMax < y then yMax := y;
      end;
      setLength(layout, xMax - xMin + 1, yMax - yMin + 1);
      for x := 0 to xMax - xMin do
         for y := 0 to yMax - yMin do
            layout[x, y] := -1;

      for i := 0 to length(fTiles) - 1 do
      begin
         x := fTiles[i].position[0];
         y := fTiles[i].position[1];
         if x < 0 then inc(y); // "If xoffs is negative, yoffs must be one lower than the wanted value." <- reverse this
         layout[x - xMin, y - yMin] := i;
      end;

      write(t, '<table summary="Industry Layout" border="1" rules="all">',
                '<colgroup span="2"></colgroup><colgroup span="', yMax - yMin + 1, '" width="*"></colgroup>',
                '<tr><th colspan="2" rowspan="2"></th><th colspan="', yMax - yMin + 1, '"> Y </th></tr><tr>');
      for y := 0 to yMax - yMin do write(t, '<th>', yMin + y, '</th>');
      writeln(t, '</tr>');
      for x := 0 to xMax - xMin do
      begin
         if x = 0 then write(t, '<tr><th rowspan="', xMax - xMin + 1, '"> X </th>') else write(t, '<tr>');
         write(t, '<th>', xMin + x, '</th>');
         for y := 0 to yMax - yMin do
         begin
            if layout[x, y] = -1 then write(t, '<td></td>') else
               with fTiles[layout[x, y]] do
               begin
                  case typ of
                     oldTile: write(t, '<td>old 0x', intToHex(tile, 2), '</td>');
                     newTile: begin
                                 s := '0x' + intToHex(tile, 4);
                                 if (settings.entityFrame = boolYes) and (fAction0.newGrfFile.entity[FIndTile, tile] <> nil) then s := fAction0.newGrfFile.printEntityLinkBegin('content', fIndTile, tile) + s + '</a>';
                                 write(t, '<td>new ', s, '</td>');
                              end;
                     empty  : write(t, '<td>clear</td>');
                  end;
               end;
         end;
         writeln(t, '</tr>');
      end;
      writeln(t, '</table>');
   end;
end;


constructor TAction0.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
var
   i, j, k, tmp                         : integer;
   prop                                 : integer;
   size                                 : integer;
   typ                                  : TAction0DataType;
   s                                    : string;
   extendedByte                         : boolean;
begin
   inherited create(aNewGrfFile, ps.spriteNr);
   assert(ps.peekByte = $00);
   ps.getByte;
   fFeature := ps.getByte;
   setLength(fProps, ps.getByte);
   fNumIDs := ps.getByte;
   setLength(fData, length(fProps), fNumIDs);
   fFirstID := ps.getExtByte;
   for i := 0 to length(fProps) - 1 do
   begin
      prop := ps.getByte;
      fProps[i] := prop;

      getPropFromTable(prop, s);
      if s = 'unknown' then
      begin
         error('Unknown Property 0x' + intToHex(prop, 2) + ' for Feature 0x' + intToHex(fFeature, 2) + ' "' + TableFeature[fFeature] + '". Action0 processing stopped.');
         exit;
      end;

      typ := a0unsigned;
      tmp := pos('I', s);
      if tmp <> 0 then
      begin
         typ := a0signed;
         delete(s, tmp, 1);
      end;
      tmp := pos('H', s);
      if tmp <> 0 then
      begin
         typ := a0hex;
         delete(s, tmp, 1);
      end;
      tmp := pos('S', s);
      if tmp <> 0 then
      begin
         typ := a0str;
         delete(s, tmp, 1);
      end;

      extendedByte := false;
      tmp := pos('+', s);
      if tmp <> 0 then 
      begin
         extendedByte := true;
         delete(s, tmp, 1);
      end;

      size := strToIntDef(s, -1);
      if size = -1 then typ := a0special;
      for j := 0 to fNumIDs - 1 do
      begin
         if (size = -1) or (size > 4) then
         begin
            assert(not extendedByte);
            fData[i, j].size := -1;
            fData[i, j].typ := a0special;
            // Have to hardcode these :(
            case fFeature of
               FStation : case prop of
                             $09: fData[i, j].special := TAction0SpecialPropertyArray.create(self, ps, fFirstID + j, TAction0StationSpriteLayout);
                             $0E: fData[i, j].special := TAction0SpecialPropertyArray.create(self, ps, fFirstID + j, TAction0StationCustomLayout);
                             else assert(false, 'TableAction0Stations corrupted');
                          end;
               FBridge  : if prop = $0D then fData[i, j].special := TAction0BridgeLayout.create(self, ps) else
                                             assert(false, 'TableAction0Bridges corrupted');
               FHouse   : if prop = $20 then
                          begin
                             // Houses, cargo acceptance watch list
                             fData[i, j].special := TAction0ByteArray.create(self, ps);
                          end else assert(false, 'TableAction0Houses corrupted');
               FGlobal  : case prop of
                             $10: begin
                                     if fFirstID + j <> 0 then error('Snow line height table is only valid for ID 0');
                                     fData[i, j].special := TAction0SnowlineHeight.create(self, ps);
                                  end;
                             $11: fData[i, j].special := TAction0GrfIDOverrideForEngines.create(self, ps);
                             else assert(false, 'TableAction0Global corrupted');
                          end;
               FIndustry: case prop of
                             $0A: fData[i, j].special := TAction0SpecialPropertyArray.create(self, ps, fFirstID + j, TAction0IndustryLayout);
                             $15: fData[i, j].special := TAction0ByteArray.create(self, ps); // Industry, random sound effects
                             else assert(false, 'TableAction0Industries corrupted');
                          end;
               else       assert(false, 'TableAction0xxx corrupted');
            end;
         end else
         begin
            assert((not extendedByte) or (size = 1));
            if extendedByte and (ps.peekByte = $FF) then
            begin
               ps.getByte;
               size := 2;
            end;
            fData[i, j].size := size;
            fData[i, j].typ := typ;
            fData[i, j].plainunsigned := 0;
            for k := 0 to size - 1 do fData[i, j].plainunsigned := fData[i, j].plainunsigned + (ps.getByte shl (8 * k));
            if typ = a0signed then fData[i, j].plainsigned := signedCast(fData[i, j].plainunsigned, size);
         end;
      end;
   end;
   testSpriteEnd(ps);

   for i := 0 to fNumIDs - 1 do newGrfFile.registerEntity(fFeature, fFirstID + i, self);
end;

destructor TAction0.destroy;
var
   i, j                                 : integer;
begin
   if fNumIDs > 0 then
   begin
      for i := 0 to length(fProps) - 1 do
      begin
         if fData[i, 0].typ = a0special then
            for j := 0 to length(fData[i]) - 1 do
               fData[i, j].special.free;
      end;
   end;
   inherited destroy;
end;

procedure TAction0.secondPass;
var
   i                                    : integer;
begin
   inherited secondPass;
   if fFeature <> FHouse then exit;
   if (newGrfFile <> nil) and (newGrfFile.action8 <> nil) then exit;
   for i := 0 to length(fProps) - 1 do
      if fProps[i] = $20 then
      begin
         error('Cargo acceptance watch list: Missing Action8, cannot determine meaning of listentrys.');
         exit;
      end;
end;

function TAction0.getPropFromTable(p: byte; out format: string): string;
begin
   format := TableAction0General[p, 0];
   result := TableAction0General[p, 1];
   if format = 'unknown' then
   begin
      if (fFeature >= low(TableAction0Features)) and (fFeature <= high(TableAction0Features)) and
         (TableAction0Features[fFeature] <> nil) then
      begin
         format := TableAction0Features[fFeature][p, 0];
         result := TableAction0Features[fFeature][p, 1];
      end;
   end;
end;

function TAction0.getNumProps: integer;
begin
   result := length(fProps);
end;

function TAction0.getProp(i: integer): byte;
begin
   result := fProps[i];
end;

function TAction0.getFeatID(i: integer): integer;
begin
   result := fFirstID + i;
end;

function TAction0.getData(propNr, IDNr: integer): TAction0Data;
begin
   result := fData[propNr, IDNr];
end;

procedure TAction0.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   i, j, k                              : integer;
   len                                  : integer;
   s, s2                                : string;
   aimedCols                            : integer;
   colNr                                : integer;
   hasPlain                             : boolean;
begin
   inherited printHtml(t, path, settings);
   writeln(t, '<b>Action0</b> - Define Properties<br><b>Feature</b> 0x', intToHex(fFeature, 2), ' "', TableFeature[fFeature], '"');

   if fFirstID + fNumIDs - 1 > $FF then len := 4 else len := 2;

   aimedCols := max(2, (settings.aimedWidth - settings.action0FirstColWidth) div settings.action0ColWidth); // only a guess
   hasPlain := false;
   if fNumIDs > 0 then
   begin
      for j := 0 to length(fProps) - 1 do
      begin
         if fData[j, 0].typ <> a0special then
         begin
            hasPlain := true;
            break;
         end;
      end;
   end;

   if hasPlain then
   begin
      colNr := 0;
      while colNr < fNumIDs do
      begin
         if colNr <> 0 then write(t, '<br>');
         write(t, '<table summary="Properties" border="1" rules="all"><tr><th>Property</th>');
         for i := colNr to min(colNr + aimedCols, fNumIDs) - 1 do
         begin
            s2 := 'ID 0x' + intToHex(fFirstID + i, len) + ' (' + intToStr(fFirstID + i) + ')';
            if (settings.entityFrame = boolYes) and (newGrfFile.entity[fFeature, fFirstId + i] <> nil) then s2 := newGrfFile.printEntityLinkBegin('content', fFeature, fFirstId + i) + s2 + '</a>';
            write(t, '<th>', s2, '</th>');
         end;
         writeln(t, '</tr>');
         for j := 0 to length(fProps) - 1 do
            if fData[j, 0].size in [0..4] then
            begin
               s := getPropFromTable(fProps[j], s2);
               writeln(t, '<tr valign="top"><th align="left">0x', intToHex(fProps[j], 2), ' "', s, '"</th>');
               for i := colNr to min(colNr + aimedCols, fNumIDs) - 1 do
               begin
                  write(t, '<td>0x', intToHex(unsignedCast(fData[j, i].plainunsigned, fData[j, i].size), 2 * fData[j, i].size));
                  case fData[j, i].typ of
                     a0unsigned: write(t, ' (', fData[j, i].plainunsigned, ')');
                     a0signed:   write(t, ' (', fData[j, i].plainsigned, ')');
                     a0str: begin
                               setLength(s2, fData[j, i].size);
                               for k := 1 to fData[j, i].size do s2[k] := char(fData[j, i].plainunsigned shr ((k - 1) * 8));
                               write(t, ' (', formatTextPrintable(s2, false), ')');
                            end;
                  end;
                  writeln(t, '</td>');
               end;
               writeln(t, '</tr>');
            end;
         writeln(t, '</table>');
         colNr := colNr + aimedCols;
      end;
   end;

   if fNumIDs > 0 then
   begin
      for j := 0 to length(fProps) - 1 do
      begin
         if fData[j, 0].typ = a0special then
         begin
            s := getPropFromTable(fProps[j], s2);
            fData[j, 0].special.printHtmlBegin(t, path, settings, s, fNumIDs);
            for i := 0 to fNumIDs - 1 do
            begin
               s2 := 'ID 0x' + intToHex(fFirstID + i, len) + ' (' + intToStr(fFirstID + i) + ')';
               if (settings.entityFrame = boolYes) and (newGrfFile.entity[fFeature, fFirstId + i] <> nil) then s2 := newGrfFile.printEntityLinkBegin('content', fFeature, fFirstId + i) + s2 + '</a>';
               fData[j, i].special.printHtmlPre(t, path, settings, s, s2);
               fData[j, i].special.printHtml(t, path, settings);
               fData[j, i].special.printHtmlPost(t, path, settings);
            end;
            fData[j, 0].special.printHtmlEnd(t, path, settings);
         end;
      end;
   end;
end;

end.
