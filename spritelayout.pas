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
unit spritelayout;

interface

uses sysutils, math, windows, classes, graphics, pngimage, grfbase;

type
   TChildSprite = record
      position  : array[0..1] of byte;
      sprite    : longword;
      desc      : string;
   end;

   TParentSprite = record
      position   : array[0..2] of byte;
      extent     : array[0..2] of byte;
      sprite     : longword;
      childs     : array of TChildSprite;
      desc       : string;
   end;

   TSpriteLayout = class
   private
      fName         : string;
      fParentSprites: array of TParentSprite;
      function getParentSpriteCount: integer;
      function getParentSprite(i: integer): TParentSprite;
   public
      constructor create(name: string); // name used for preview image
      procedure addParentSprite(x, y, z: integer; w, h, dz: integer; aSprite: longword; description: string);
      function addChildSprite(x, y: integer; aSprite: longword; description: string): boolean; // false if no parentsprite present
      procedure printHtml(var t: textFile; path: string; suppressData: boolean);
      property parentSpriteCount: integer read getParentSpriteCount;
      property parentSprites[i: integer]: TParentSprite read getParentSprite;
   end;


function getSpriteDescriptionStation(spr: longword; flipBit31: boolean): string;
function getSpriteDescriptionHouse(spr: longword; action1: TSprite): string;
function getSpriteDescriptionIndTile(spr: longword; action1: TSprite): string;

implementation

uses nfoact123;

function getSpriteDescription(spr: longword; flipBit31: boolean; action1Offset: longword; specialRecolor: string; a1Sets: boolean; action1: TAction1): string;
var
   nr                                   : longword;
begin
   result := ' (';
   if (spr and $80000000 = 0) xor flipBit31 then result := result + 'TTD sprite ' + intToStr(spr and $3FFF) else
   begin
      nr := (spr and $3FFF) - action1Offset;
      if a1Sets then
      begin
         if action1 <> nil then
         begin
            result := result + action1.printHtmlLinkToSet(nr);
         end else
         begin
            result := result + 'Action1 Set ' + intToStr(nr);
         end;
      end else result := result + 'Action1 Sprite ' + intToStr(nr);
   end;
   case spr and $C000 of
      $4000: result := result + ' recolors background using ' + intToStr((spr shr 16) and $3FFF);
      $8000: begin
                if spr and $3FFF0000 = 0 then result := result + specialRecolor else
                                              result := result + ' recolored using ' + intToStr((spr shr 16) and $3FFF);
             end;
      $C000: result := result + 'invalid flags 0x0000C000';
   end;
   if spr and $40000000 <> 0 then result := result + ' [sprite not affected by transparency]';
   result := result + ')';
end;

function getSpriteDescriptionStation(spr: longword; flipBit31: boolean): string;
begin
   result := getSpriteDescription(spr, flipBit31, $42D, ' with company colors', false, nil);
end;

function getSpriteDescriptionHouse(spr: longword; action1: TSprite): string;
begin
   result := getSpriteDescription(spr, false, 0, ' recolored by property 17 or callback 1E', true, action1 as TAction1);
end;

function getSpriteDescriptionIndTile(spr: longword; action1: TSprite): string;
begin
   result := getSpriteDescription(spr, false, 0, ' with industry colors', true, action1 as TAction1);
end;


constructor TSpriteLayout.create(name: string);
begin
   inherited create;
   setLength(fParentSprites, 0);
   fName := name;
end;

procedure TSpriteLayout.addParentSprite(x, y, z: integer; w, h, dz: integer; aSprite: longword; description: string);
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
      desc := description;
      setLength(childs, 0);
   end;
end;

function TSpriteLayout.addChildSprite(x, y: integer; aSprite: longword; description: string): boolean;
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
         desc := description;
      end;
   end;
end;

procedure TSpriteLayout.printHtml(var t: textFile; path: string; suppressData: boolean);
   procedure worldToScreen(x, y, z: integer; out sx, sy: integer);
   begin
      sx := (y - x) * 2;
      sy := (y + x) - z;
   end;
var
   i, j                                 : integer;
   bb                                   : TBitmap;
   png                                  : TPNGObject;
   bbExt                                : array[0..3] of integer;
   x, y                                 : integer;
   coords                               : array[0..2, 0..1] of integer;
   fn                                   : string;
begin
   if length(fParentSprites) > 0 then
   begin
      fn := fName + '.png';
      if not suppressData then
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

         bb := TBitmap.create;
         bb.pixelFormat := pf8Bit;
         bb.width := bbExt[1] - bbExt[0] + 1;
         bb.height := bbExt[3] - bbExt[2] + 1;
         with bb.canvas do
         begin
            brush.color := $FFFFFF;
            brush.style := bssolid;
            fillRect(rect(0, 0, bb.width, bb.height));

            // ground tile
            pen.color := $FF0000;
            worldToScreen( 0,  0,  0, x, y);   moveTo(x - bbExt[0], y - bbExt[2]);
            worldToScreen(16,  0,  0, x, y);   lineTo(x - bbExt[0], y - bbExt[2]);
            worldToScreen(16, 16,  0, x, y);   lineTo(x - bbExt[0], y - bbExt[2]);
            worldToScreen( 0, 16,  0, x, y);   lineTo(x - bbExt[0], y - bbExt[2]);
            worldToScreen( 0,  0,  0, x, y);   lineTo(x - bbExt[0], y - bbExt[2]);

            // bounding boxes
            pen.color := $000000;
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

         png := TPNGObject.create;
         png.assign(bb);
         png.saveToFile(path + 'data\' + fn);
         png.free;
         bb.free;
      end;   
      writeln(t, '<img align="top" alt="Bounding Box Preview" src="data/', fn, '">');
   end;

   writeln(t, '<table summary="SpriteLayout" border="1" rules="all"><tr><th>ParentSprite</th><th>Position</th><th>Extent<th>ChildSprite</th><th>Position</th></tr>');
   for i := 0 to length(fParentSprites) - 1 do
      with fParentSprites[i] do
      begin
         writeln(t, '<tr valign="top"><td rowspan="', max(1, length(childs)), '">0x', intToHex(sprite, 8), desc, '</td>');
         writeln(t, '<td rowspan="', max(1, length(childs)), '"> &lt; ', position[0], ',', position[1], ',', position[2], ' &gt;</td>');
         writeln(t, '<td rowspan="', max(1, length(childs)), '"> &lt; ', extent[0]  , ',', extent[1]  , ',', extent[2]  , ' &gt;</td>');
         if length(childs) = 0 then writeln(t, '<td></td><td></td></tr>') else
         begin
            for j := 0 to length(childs) - 1 do
               with childs[j] do
               begin
                  if j <> 0 then write(t, '<tr>');
                  writeln(t, '<td>0x', intToHex(sprite, 8), desc, '</td><td> &lt; ', position[0], ',', position[1], ' &gt;</td></tr>');
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
