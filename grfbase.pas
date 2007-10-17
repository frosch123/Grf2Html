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
unit grfbase;

interface

uses sysutils, windows, classes, graphics, contnrs, pngimage, math, outputsettings;

const
   {TSpriteCompression}
   scUseTransparent                     = $01;
   scStoreCompressed                    = $02;
   scTileCompression                    = $08;
   scNoCropping                         = $40;
   scPseudoSprite                       = $FF;

type
   TByteArray = array[0..high(longint) - 1] of byte;
   TSpriteCompression = byte;

   TSprite = class
   private
      fSpriteNr: integer;
   public
      constructor create(spriteNr: integer);
      function printHtmlSpriteAnchor: string;
      function printHtmlSpriteNr: string;
      function printHtmlSpriteLink: string;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); virtual;
      function getShortDesc: string; virtual; abstract;
      property spriteNr: integer read fSpriteNr;
   end;

   TRealSprite = class(TSprite)
   private
      fRelPos       : TPoint;
      fCompression  : TSpriteCompression;
      fWinPalette   : boolean;
      fWidth        : integer;
      fHeight       : integer;
      fPixelData    : array of array of byte;
   public
      constructor create(spriteNr: integer; w, h: integer; var data; aCompression: TSpriteCompression; relX, relY: integer; useWinPalette: boolean);
      function createBitmap: TBitmap;
      function createPng: TPngObject;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      function getShortDesc: string; override;
      property width: integer read fwidth;
      property height: integer read fheight;
      property compression: TSpriteCompression read fCompression write fCompression;
      property relPos: TPoint read fRelPos write fRelPos;
      property winPalette: boolean read fWinPalette;
   end;
   TPseudoSprite = class(TSprite)
   private
      fData      : array of byte;
      function getSize: integer;
      function getData(i: integer): byte;
   public
      constructor create(spriteNr: integer; aSize: integer; var data);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      function getShortDesc: string; override;
      property size: integer read getSize;
      property data[i: integer]: byte read getData;
   end;
   TBinaryIncludeSprite = class(TSprite)
   private
      fName             : string;
      fData             : array of byte;
      function getSize: integer;
      function getData: pointer;
   public
      constructor create(spriteNr: integer; aName: string; aSize: integer; var data);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      function getShortDesc: string; override;
      property name: string read fName write fName;
      property size: integer read getSize;
      property data: pointer read getData;
   end;

function loadGrf(stream: TStream; useWinPalette: boolean): TObjectList;
procedure savePng(png: TPngObject; fn: string);

implementation

{$R grfbase.res}

type
   TPalette = array[byte] of TRGBQuad;

var
   winPal, dosPal                       : TPalette;

procedure forcePalette(const bmp: HBitmap; pal: TPalette);
var
   screenDC, dc                         : HDC;
   oldBM                                : HBitmap;
begin
   screenDC := getDC(0);
   dc := createCompatibleDC(screenDC);
   oldBM := selectObject(dc, bmp);
   try
      setDIBColorTable(dc, 0, 256, pal);
   finally
      selectObject(dc, oldBM);
      deleteDC(dc);
      releaseDC(0, screenDC);
   end;
end;


constructor TSprite.create(spriteNr: integer);
begin
   inherited create;
   fSpriteNr := spriteNr;
end;

function TSprite.printHtmlSpriteAnchor: string;
begin
   result := '<a name="sprite' + intToStr(spriteNr) + '"></a>';
end;

function TSprite.printHtmlSpriteNr: string;
begin
   result := '#' + intToStr(spriteNr);
end;

function TSprite.printHtmlSpriteLink: string;
begin
   result := '<a href="#sprite' + intToStr(spriteNr) + '">' + printHtmlSpriteNr + ' ' + getShortDesc + '</a>';
end;

procedure TSprite.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
begin
   // nothing to do
end;


constructor TRealSprite.create(spriteNr: integer; w, h: integer; var data; aCompression: TSpriteCompression; relX, relY: integer; useWinPalette: boolean);
var
   y                                    : integer;
begin
   inherited create(spriteNr);
   fCompression := aCompression;
   fRelPos := point(relX, relY);
   fWinPalette := useWinPalette;
   fWidth := max(0, w);
   fHeight := max(0, h);
   setlength(fPixelData,h,w);
   if w > 0 then
   begin
      for y := 0 to h-1 do move(TByteArray(data)[y * w], fPixelData[y][0], w);
   end;
end;

function TRealSprite.createBitmap: TBitmap;
var
   y                                    : integer;
begin
   result := TBitmap.create;
   result.pixelFormat := pf8Bit;
   result.width := fWidth;
   result.height := fHeight;
   // set palette
   if fWinPalette then forcePalette(result.handle, winPal) else forcePalette(result.handle, dosPal);
   // set bitmap data
   if fWidth > 0 then
   begin
      for y := 0 to fHeight - 1 do move(fPixelData[y][0], result.scanLine[y]^, fWidth);
   end;
end;

function TRealSprite.createPng: TPngObject;
var
   bmp                                  : TBitmap;
begin
   bmp := createBitmap;
   result := TPNGObject.create;
   result.assign(bmp);
   bmp.free;
end;

procedure TRealSprite.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   fn                                   : string;
   png                                  : TPNGObject;
begin
   inherited printHtml(t, path, settings);
   fn := 'sprite' + intToStr(spriteNr) + '.png';
   writeln(t, '<img alt="', spriteNr, '" src="data/', fn, '"><br>Rel: &lt;', fRelPos.x, ',', fRelPos.y, '&gt;<br>Compr: 0x', intToHex(fCompression, 2));
   if not settings.suppressData then
   begin
      png := createPng;
      savePng(png, path + 'data\' + fn);
      png.free;
   end;
end;

function TRealSprite.getShortDesc: string;
begin
   result := 'RealSprite';
end;


constructor TPseudoSprite.create(spriteNr: integer; aSize: integer; var data);
begin
   inherited create(spriteNr);
   setLength(fData, aSize);
   move(data, fData[0], aSize);
end;

function TPseudoSprite.getSize: integer;
begin
   result := length(fData);
end;

function TPseudoSprite.getData(i: integer): byte;
begin
   result := fData[i];
end;

procedure TPseudoSprite.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   i                                    : integer;
begin
   inherited printHtml(t, path, settings);
   writeln(t, 'Unknown Pseudo Sprite, NFO hex stream:');
   for i := 0 to size - 1 do
   begin
      if i mod 32 = 0 then writeln(t, '<br>');
      write(t, ' ', intToHex(data[i], 2));
   end;
   writeln(t);
end;

function TPseudoSprite.getShortDesc: string;
begin
   result := 'Unknown PseudoSprite'
end;


constructor TBinaryIncludeSprite.create(spriteNr: integer; aName: string; aSize: integer; var data);
begin
   inherited create(spriteNr);
   fName := aName;
   setLength(fData, aSize);
   move(data, fData[0], aSize);
end;

function TBinaryIncludeSprite.getSize: integer;
begin
   result := length(fData);
end;

function TBinaryIncludeSprite.getData: pointer;
begin
   result := addr(fData[0]);
end;

procedure TBinaryIncludeSprite.printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings);
var
   f                                    : file;
begin
   inherited printHtml(t, path, settings);
   writeln(t, 'Binary Include Sprite: <a href="data/', fName, '">', fName, '</a>');
   if (not settings.suppressData) and (fName <> '') then
   begin
      try
         assignFile(f, path + 'data\' + fName);
         rewrite(f, 1);
      except
         writeln(t,' Error: Could not create file');
         exit;
      end;
      blockWrite(f, data^, size);
      closeFile(f);
   end;
end;

function TBinaryIncludeSprite.getShortDesc: string;
begin
   result := 'BinaryIncludeSprite';
end;


(*
 * Decodes a grf file as documented by Josef Drexler; see GRFCodec at http://www.ttdpatch.net
 *
 * @param stream         The raw grf data
 * @param useWinPalette  If true, use the Windows palette for RealSprites, else the Dos palette.
 * @result               List of RealSprites, PseudoSprites and BinaryIncludeSprites. Nil if the file is not a valid Grf.
 *)
function loadGrf(stream: TStream; useWinPalette: boolean): TObjectList;
var
   readBuf                              : array[0..$1FFFF] of byte;
   readPos                              : integer;
   readSize                             : integer;

   size                                 : integer;
   sizeInFile                           : integer;
   info                                 : TSpriteCompression;

   decomp                               : array[word] of byte;
   decompPos                            : integer;

   xDim, ydim                           : integer;
   xRel, yRel                           : smallint;

   tilePos                              : integer;
   tile                                 : array[word] of byte;

   tmp1, tmp2                           : integer;
   y, cnt, i                            : integer;
   s                                    : string;
begin
   result := TObjectList.create(true);
   readPos := 0;
   readSize := 0;
   repeat
      move(readBuf[readPos], readBuf[0], readSize - readPos);
      readSize := readSize - readPos;
      readPos := 0;
      if readSize < $10000 then readSize := readSize + stream.read(readBuf[readSize], $10000); // read blocks of 64K

      size := readBuf[readPos] or (readBuf[readPos + 1] shl 8);
      readPos := readPos + 2;
      if size = 0 then break; // end of file marker

      info := readBuf[readPos];
      inc(readPos);
      if info = scPseudoSprite then
      begin
         // Test for binary-include-sprite. But not for first sprite.
         if (readBuf[readPos] = $FF) and (result.count > 0) then
         begin
            // binary-include-sprite
            setLength(s, readBuf[readPos + 1]);
            move(readBuf[readPos + 2], s[1], length(s));
            // String termination: readbuf[readpos+2+length(s)] = 0
            result.add(TBinaryIncludeSprite.create(result.count, s, size - 3 - length(s), readBuf[readPos + 3 + length(s)]));
         end else
         begin
            // pseudo- or recolor-sprite
            result.add(TPseudoSprite.create(result.count, size, readBuf[readPos]));
         end;
         readPos := readPos + size;
      end else
      begin
         // real sprite
         ydim := readBuf[readPos];
         xDim := readBuf[readPos + 2] shl 8 or readBuf[readPos + 1];
         xRel := readBuf[readPos + 4] shl 8 or readBuf[readPos + 3]; // result is smallint (16bit signed)
         yRel := readBuf[readPos + 6] shl 8 or readBuf[readPos + 5]; // result is smallint (16bit signed)
         readPos := readPos + 7;

         if info and scStoreCompressed <> 0 then
         begin
            sizeInFile := size + 1;
            size := $10000;
         end else
         begin
            size := size - 8;
            sizeInFile := $10000;
         end;

         decompPos := 0;
         while (decompPos < size) and (readPos < sizeInFile) do
         begin
            tmp1 := readBuf[readPos];
            inc(readPos);
            if tmp1 and $80 = 0 then
            begin
               // verbatim data
               if tmp1 = 0 then tmp1 := $80;
               // copy tmp1 bytes from source to dest
               move(readBuf[readPos], decomp[decompPos], tmp1);
               readPos := readPos + tmp1;
               decompPos := decompPos + tmp1;
            end else
            begin
               // copy old data
               tmp2 := readBuf[readPos] or ((tmp1 and $07) shl 8);
               inc(readPos);
               tmp1 := 16 - ((tmp1 and $78) shr 3);
               // copy tmp1 bytes from position decomppos-tmp2
               // Note: The copied data may overlap with itself.
               for i := 0 to tmp1 - 1 do decomp[decompPos + i] := decomp[decompPos - tmp2 + i];
               decompPos := decompPos + tmp1;
            end;
         end;
         if decompPos > size then
         begin
            // error
            result.free;
            result := nil;
            exit;
         end;
         size := decompPos;

         if info and scTileCompression = 0 then
         begin
            // raw data
            if size <> xDim * ydim then
            begin
               // error
               result.free;
               result := nil;
               exit;
            end;
            result.add(TRealSprite.create(result.count, xDim, ydim, decomp[0], info, xRel, yRel, useWinPalette));
         end else
         begin
            // "tile compression"
            assert(xDim * ydim < sizeof(tile)); // don't know if this assumption is valid
            fillChar(tile, xDim * ydim, 0); // initialize with transparent (0)
            for y := 0 to ydim - 1 do
            begin
               tilePos := decomp[y * 2 + 1] shl 8 + decomp[y * 2];
               repeat
                  tmp1 := decomp[tilePos];
                  tmp2 := decomp[tilePos + 1];
                  cnt := tmp1 and $7F;
                  // copy cnt pixels to (tmp2,y)
                  if (tmp2 + cnt > xDim) or (tilePos + 2 + cnt > size) then
                  begin
                     // error
                     result.free;
                     result := nil;
                     exit;
                  end;
                  move(decomp[tilePos + 2], tile[y * xDim + tmp2], cnt);
                  tilePos := tilePos + 2 + cnt;
               until tmp1 and $80 <> 0;
            end;
            result.add(TRealSprite.create(result.count, xDim, ydim, tile[0], info, xRel, yRel, useWinPalette));
         end;
      end;
   until stream.position - readSize + readPos >= stream.size;
   if stream.position - readSize + readPos <> stream.size - 4 then
   begin
      // error
      result.free;
      result := nil;
      exit;
   end;
end;


procedure savePng(png: TPngObject; fn: string);
var
   stream                               : TMemoryStream;
begin
   (* Encode and save a png image.
    * We first encode the png into a MemoryStream, and write it then into the file in one block.
    * Perhaps this increases speed on some filesystems, though I could not measure a difference on any I tried.
    *)
   stream := TMemoryStream.create;
   png.saveToStream(stream);

   stream.saveToFile(fn); // You laugh, but this line takes 50-90% of the execution time. (depends on OS/FileSystem/Grf)
   (* Some numbers:
    *  Test case: Canadian Station Set, Output: 18929 files, 39 MB
    *
    *  OS         | FileSystem           | DiskUsage | Total time | stream.saveToFile | Rest
    * ------------+----------------------+-----------+------------+-------------------+--------
    *  WinXP      | Fat16 (16K clusters) | 314 MB    | 169.7 s    | 153.4 s  90%      |  16.3 s
    *  WinXP      | NTFS                 |  92 MB    |  50.0 s    |  44.5 s  89%      |   5.5 s
    *  Linux/wine | Ext3                 |  92 MB    |  96.9 s    |  52.7 s  54%      |  44.2 s
    *
    *)

   stream.free;
end;


procedure readPalette(s: TStream; var pal: TPalette);
var
   buf                                  : array[0..255, 0..2] of byte;
   i                                    : integer;
begin
   assert(s.size = sizeof(buf));
   s.readBuffer(buf, sizeof(buf));
   for i := 0 to 255 do
   begin
      pal[i].rgbRed := buf[i, 0];
      pal[i].rgbGreen := buf[i, 1];
      pal[i].rgbBlue := buf[i, 2];
      pal[i].rgbReserved := 0;
   end;
   s.free;
end;

initialization
   readPalette(TResourceStream.create(hInstance, 'pal_win', 'bcp'), winPal);
   readPalette(TResourceStream.create(hInstance, 'pal_dos', 'bcp'), dosPal);
end.
