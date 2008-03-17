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
unit spritelayout;

interface

uses sysutils, classes, math, osspecific, grfbase, nfobase, outputsettings;

type
   TTTDPSprite = class
   protected
      fParent   : TNewGrfSprite;
      fSprite   : longword;
      fFlipBit31: boolean;
      fAct1Offs : longword;
      fRecolor  : string;
      fA1Sets   : boolean;
      fAction1  : TSprite;
   public
      constructor create(parent: TNewGrfSprite; sprite: longword; flipBit31: boolean; action1Offset: longword; specialRecolor: string; a1Sets: boolean; action1: TSprite);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
   end;

   TTTDPStationSprite = class(TTTDPSprite)
      constructor create(parent: TNewGrfSprite; sprite: longword; groundSprite: boolean);
   end;

   TTTDPHouseSprite = class(TTTDPSprite)
      constructor create(parent: TNewGrfSprite; sprite: longword; action1: TSprite);
   end;

   TTTDPIndustryTileSprite = class(TTTDPSprite)
      constructor create(parent: TNewGrfSprite; sprite: longword; action1: TSprite);
   end;

   TChildSprite = record
      position  : array[0..1] of integer;
      sprite    : TTTDPSprite;
   end;

   TParentSprite = record
      position   : array[0..2] of integer;
      extent     : array[0..2] of integer;
      sprite     : TTTDPSprite;
      childs     : array of TChildSprite;
   end;

   TSpriteLayout = class
   private
      fParent       : TNewGrfSprite;
      fName         : string;
      fParentSprites: array of TParentSprite;
      function getParentSpriteCount: integer;
      function getParentSprite(i: integer): TParentSprite;
   public
      constructor create(parent:TNewGrfSprite; name: string); // name used for preview image
      destructor destroy; override;
      procedure addParentSprite(x, y, z: integer; w, h, dz: integer; aSprite: TTTDPSprite);
      function addChildSprite(x, y: integer; aSprite: TTTDPSprite): boolean; // false if no parentsprite present
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
      property parentSpriteCount: integer read getParentSpriteCount;
      property parentSprites[i: integer]: TParentSprite read getParentSprite;
   end;


implementation

{$IFDEF FPC}
   uses nfoact123, fpimage, fpcanvas;
{$ELSE}
   uses nfoact123, graphics;
{$ENDIF}

constructor TTTDPSprite.create(parent: TNewGrfSprite; sprite: longword; flipBit31: boolean; action1Offset: longword; specialRecolor: string; a1Sets: boolean; action1: TSprite);
begin
   inherited create;
   fParent := parent;
   fSprite := sprite;
   fFlipBit31 := flipBit31;
   fAct1Offs := action1offset;
   fRecolor := specialRecolor;
   fA1Sets := a1Sets;
   fAction1 := action1;
   if (fAction1 <> nil) and (fParent <> nil) then
   begin
      if (fSprite and $80000000 <> 0) xor fFlipBit31 then (fAction1 as TAction1).registerLink((fSprite and $3FFF) - fAct1Offs, fParent);
   end;
end;

procedure TTTDPSprite.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   nr                                   : longword;
   result                               : string;
begin
   result := '0x' + intToHex(fSprite, 8) + ' (';
   if (fSprite and $80000000 = 0) xor fFlipBit31 then result := result + 'TTD sprite ' + intToStr(fSprite and $3FFF) else
   begin
      nr := (fSprite and $3FFF) - fAct1Offs;
      if fA1Sets then
      begin
         if fAction1 <> nil then
         begin
            result := result + (fAction1 as TAction1).printHtmlLinkToSet(nr, 'content');
         end else
         begin
            result := result + 'Action1 Set ' + intToStr(nr);
         end;
      end else result := result + 'Action1 Sprite ' + intToStr(nr);
   end;
   case fSprite and $C000 of
      $4000: result := result + ' recolors background using ' + intToStr((fSprite shr 16) and $3FFF);
      $8000: begin
                if fSprite and $3FFF0000 = 0 then result := result + fRecolor else
                                                  result := result + ' recolored using ' + intToStr((fSprite shr 16) and $3FFF);
             end;
      $C000: result := result + 'invalid flags 0x0000C000';
   end;
   if fSprite and $40000000 <> 0 then result := result + ' [sprite not affected by transparency]';
   result := result + ')';
   writeln(t, result);
end;

constructor TTTDPStationSprite.create(parent: TNewGrfSprite; sprite: longword; groundSprite: boolean);
begin
   inherited create(parent, sprite, not groundSprite, $42D, ' with company colors', false, nil);
end;

constructor TTTDPHouseSprite.create(parent: TNewGrfSprite; sprite: longword; action1: TSprite);
begin
   inherited create(parent, sprite, false, 0, ' recolored by property 17 or callback 1E', true, action1);
end;

constructor TTTDPIndustryTileSprite.create(parent: TNewGrfSprite; sprite: longword; action1: TSprite);
begin
   inherited create(parent, sprite, false, 0, ' with industry colors', true, action1);
end;

constructor TSpriteLayout.create(parent: TNewGrfSprite; name: string);
begin
   inherited create;
   fParent := parent;
   setLength(fParentSprites, 0);
   fName := name;
end;

destructor TSpriteLayout.destroy;
var
   i, j                                 : integer;
begin
   for i := 0 to length(fParentSprites) - 1 do
   begin
      fParentSprites[i].sprite.free;
      for j := 0 to length(fParentSprites[i].childs) - 1 do fParentSprites[i].childs[j].sprite.free;
      setlength(fParentSprites[i].childs, 0);
   end;
   setlength(fParentSprites, 0);
   inherited destroy;
end;

procedure TSpriteLayout.addParentSprite(x, y, z: integer; w, h, dz: integer; aSprite: TTTDPSprite);
var
   nr                                   : integer;
begin
   nr := length(fParentSprites);
   setLength(fParentSprites, nr + 1);
   with fParentSprites[nr] do
   begin
      position[0] := x;
      position[1] := y;
      position[2] := z;
      extent[0] := w;
      extent[1] := h;
      extent[2] := dz;
      sprite := aSprite;
      setLength(childs, 0);
   end;
end;

function TSpriteLayout.addChildSprite(x, y: integer; aSprite: TTTDPSprite): boolean;
var
   p, c                                 : integer;
begin
   p := length(fParentSprites) - 1;
   result := p >= 0;
   if result then
   begin
      c := length(fParentSprites[p].childs);
      setLength(fParentSprites[p].childs, c + 1);
      with fParentSprites[p].childs[c] do
      begin
         position[0] := x;
         position[1] := y;
         sprite := aSprite;
      end;
   end;
end;

procedure TSpriteLayout.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
   procedure worldToScreen(x, y, z: integer; out sx, sy: integer);
   begin
      sx := (y - x) * 2;
      sy := (y + x) - z;
   end;
var
   i, j                                 : integer;
   bb                                   : TOSIndependentImage;
   bbExt                                : array[0..3] of integer;
   x, y                                 : integer;
   coords                               : array[0..2, 0..1] of integer;
   fn                                   : string;
begin
   if length(fParentSprites) > 0 then
   begin
      fn := fName + '.png';
      if not suppressDataForSprite(settings, fParent.spriteNr) then
      begin
         worldToScreen(16, 0, 0, bbExt[0], y);
         worldToScreen(0, 16, 0, bbExt[1], y);
         worldToScreen(0, 0, 0, x, bbExt[2]);
         worldToScreen(16, 16, 0, x, bbExt[3]);
         for i := 0 to length(fParentSprites) - 1 do
            with fParentSprites[i] do
            begin
               // xmin
               worldToScreen(position[0] + extent[0], position[1]            , position[2]            , x, y);
               if bbExt[0] > x then bbExt[0] := x;

               // xmax
               worldToScreen(position[0]            , position[1] + extent[1], position[2]            , x, y);
               if bbExt[1] < x then bbExt[1] := x;

               // ymin
               worldToScreen(position[0]            , position[1]            , position[2] + extent[2], x, y);
               if bbExt[2] > y then bbExt[2] := y;

               // ymax
               worldToScreen(position[0] + extent[0], position[1] + extent[1], position[2]            , x, y);
               if bbExt[3] < y then bbExt[3] := y;
            end;

         bb := TOSIndependentImage.create(bbExt[1] - bbExt[0] + 1, bbExt[3] - bbExt[2] + 1);
         with bb.canvas do
         begin
            {$IFDEF FPC}
               pen.FPColor := colTransparent;
               brush.FPColor := colTransparent;
            {$ELSE}
               pen.color := $FFFFFF;
               brush.color := $FFFFFF;
            {$ENDIF}
            brush.style := bssolid;
            rectangle(0, 0, bb.width, bb.height);

            // ground tile
            {$IFDEF FPC}
               pen.FPColor := FPColor(0, 0, $FFFF);
            {$ELSE}
               pen.color := $FF0000;
            {$ENDIF}
            worldToScreen( 0,  0,  0, x, y);   moveTo(x - bbExt[0], y - bbExt[2]);
            worldToScreen(16,  0,  0, x, y);   lineTo(x - bbExt[0], y - bbExt[2]);
            worldToScreen(16, 16,  0, x, y);   lineTo(x - bbExt[0], y - bbExt[2]);
            worldToScreen( 0, 16,  0, x, y);   lineTo(x - bbExt[0], y - bbExt[2]);
            worldToScreen( 0,  0,  0, x, y);   lineTo(x - bbExt[0], y - bbExt[2]);

            // bounding boxes
            {$IFDEF FPC}
               pen.FPColor := FPColor(0, 0, 0);
            {$ELSE}
               pen.color := $000000;
            {$ENDIF}
            for i := 0 to length(fParentSprites) - 1 do
               with fParentSprites[i] do
               begin
                  worldToScreen(position[0] + extent[0], position[1] + extent[1], position[2] + extent[2], x           , y           );
                  worldToScreen(position[0]            , position[1] + extent[1], position[2] + extent[2], coords[0, 0], coords[0, 1]);
                  worldToScreen(position[0] + extent[0], position[1]            , position[2] + extent[2], coords[1, 0], coords[1, 1]);
                  worldToScreen(position[0] + extent[0], position[1] + extent[1], position[2]            , coords[2, 0], coords[2, 1]);
                  coords[0, 0] := coords[0, 0] - x;
                  coords[0, 1] := coords[0, 1] - y;
                  coords[1, 0] := coords[1, 0] - x;
                  coords[1, 1] := coords[1, 1] - y;
                  coords[2, 0] := coords[2, 0] - x;
                  coords[2, 1] := coords[2, 1] - y;
                  x := x - bbExt[0];
                  y := y - bbExt[2];
                  moveTo(x, y);
                  lineTo(x + coords[0, 0]               , y + coords[0, 1]               );
                  lineTo(x + coords[0, 0] + coords[1, 0], y + coords[0, 1] + coords[1, 1]);
                  lineTo(x + coords[1, 0]               , y + coords[1, 1]               );
                  lineTo(x                              , y                              );
                  lineTo(x + coords[2, 0]               , y + coords[2, 1]               );
                  moveTo(x + coords[1, 0]               , y + coords[1, 1]               );
                  lineTo(x + coords[1, 0] + coords[2, 0], y + coords[1, 1] + coords[2, 1]);
                  lineTo(x + coords[2, 0]               , y + coords[2, 1]               );
                  lineTo(x + coords[0, 0] + coords[2, 0], y + coords[0, 1] + coords[2, 1]);
                  lineTo(x + coords[0, 0]               , y + coords[0, 1]               );
               end;
         end;

         {$IFNDEF FPC}
            bb.setTransparent($FFFFFF);
         {$ENDIF}
         bb.savePng(path + 'data' + directorySeparator + fn);
         bb.free;
      end;
      writeln(t, '<img align="top" alt="Bounding Box Preview" src="data/', fn, '">');
   end;

   writeln(t, '<table summary="SpriteLayout" border="1" rules="all"><tr><th>ParentSprite</th><th>Position</th><th>Extent<th>ChildSprite</th><th>Position</th></tr>');
   for i := 0 to length(fParentSprites) - 1 do
      with fParentSprites[i] do
      begin
         writeln(t, '<tr valign="top"><td rowspan="', max(1, length(childs)), '">');
         sprite.printHtml(t, path, settings);
         writeln(t, '</td>');
         writeln(t, '<td rowspan="', max(1, length(childs)), '"> &lt; ', position[0], ',', position[1], ',', position[2], ' &gt;</td>');
         writeln(t, '<td rowspan="', max(1, length(childs)), '"> &lt; ', extent[0]  , ',', extent[1]  , ',', extent[2]  , ' &gt;</td>');
         if length(childs) = 0 then writeln(t, '<td></td><td></td></tr>') else
         begin
            for j := 0 to length(childs) - 1 do
               with childs[j] do
               begin
                  if j <> 0 then write(t, '<tr>');
                  writeln(t, '<td>');
                  sprite.printHtml(t, path, settings);
                  writeln(t, '</td><td> &lt; ', position[0], ',', position[1], ' &gt;</td></tr>');
               end;
         end;
      end;
   writeln(t, '</table>');
end;

function TSpriteLayout.getParentSpriteCount: integer;
begin
   result := length(fParentSprites);
end;

function TSpriteLayout.getParentSprite(i: integer): TParentSprite;
begin
   result := fParentSprites[i];
end;

end.
