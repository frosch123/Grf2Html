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

uses sysutils, classes, contnrs, grfbase, htmlwriter, outputsettings;

const
   grf2HtmlVersion                      : string = 'Grf2Html 0.5';
   dataVersion                          : string = '26th March 2008';

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
   TAction8 = class;

   TSpriteSet = class
   private
      fSprites    : TList;
      function findPosition(nr: integer): integer;
   public
      constructor create;
      destructor destroy; override;
      procedure printHtml(const srcFrame: string; var t: textFile; path: string; const settings: TGrf2HtmlSettings; singleLine: boolean);
      procedure add(s: TSprite);
      function hasInRange(min, max:integer) : boolean;
   end;

   TEntityList = class
   private
      fIDs    : array of integer;
      fEntity : array of TSpriteSet;
      function getID(i: integer) : integer;
      function getEntity(i: integer): TSpriteSet;
      function getCount: integer;
   public
      constructor create;
      destructor destroy; override;
      function findEntity(id: integer; createNew: boolean = false): TSpriteSet;
      property count : integer read getCount;
      property ID[i: integer]: integer read getID;
      property entity[i: integer]: TSpriteSet read getEntity;
   end;

   TNewGrfFile = class
   private
      fGrfName     : string;
      fSprites     : TObjectList;
      fAction8     : TAction8;
      fEntity      : array[TFeature] of TEntityList;
      function getEntity(f: TFeature; id: integer): TSpriteSet;
   public
      constructor create(aGrfName: string; grfFile: TObjectList);
      destructor destroy; override;
      procedure printHtml(path: string; settings: TGrf2HtmlSettings);
      procedure registerEntity(f: TFeature; id: integer; s: TSprite);
      function printEntityLinkBegin(const srcFrame: string; f: TFeature; id: integer) : string;
      property grfName: string read fGrfName write fGrfName;
      property sprites: TObjectList read fSprites;
      property action8: TAction8 read fAction8;
      property entity[f: TFeature; id: integer]: TSpriteSet read getEntity;
   end;

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

   TNewGrfSprite = class(TSprite)
   private
      fErrors    : TStringList;
      fNewGrfFile: TNewGrfFile;
      function getErrors: TStrings;
   protected
      procedure testSpriteEnd(ps: TPseudoSpriteReader);
   public
      constructor create(aNewGrfFile: TNewGrfFile; spriteNr: integer);
      destructor destroy; override;
      procedure error(msg: string);
      procedure secondPass; virtual;
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      function getShortDesc: string; override;
      property errors: TStrings read getErrors;
      property newGrfFile: TNewGrfFile read fNewGrfFile;
   end;

   TSpriteCountSprite = class(TNewGrfSprite)
   private
      fSpriteCount: integer;
   public
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      function getShortDesc: string; override;
      property spriteCount: integer read fSpriteCount;
   end;

   TRecolorTable = array[byte] of byte;

   TRecolorSprite = class(TNewGrfSprite)
   private
      fRecolorTable: TRecolorTable;
   public
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
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
      constructor create(aNewGrfFile: TNewGrfFile; spriteNr: integer);
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
      constructor create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
      procedure printHtml(var t: textFile; path: string; const settings: TGrf2HtmlSettings); override;
      property grfVersion: integer read fGrfVersion;
      property grfID: longword read fGrfID;
      property name: string read fName;
      property description: string read fDesc;
   end;

function formatTextPrintable(s: string; parseStringCodes: boolean): string;
function grfID2Str(grfID: longword): string;
function signedCast(v: longword; size: integer): longint;
function unsignedCast(v: longword; size: integer): longword;
procedure printAbout;

implementation

uses nfoact, nfoact0, nfoact123, nfoact5A12, tables;

(*
 * Parses a Newgrf file.
 * @param aGrfName Filename of the grf (only used for printing it into the output)
 * @param grfFile  List of RealSprites, PseudoSprites and BinaryIncludeSprites generated by loadGrf (will be freed !).
 * @result         List of parsed NewgrfSprites, RealSprites, BinaryIncludeSprites and PseudoSprites (if unknown action).
 *)
constructor TNewGrfFile.create(aGrfName: string; grfFile: TObjectList);
var
   i, j, k                              : integer;

   msa                                  : TMultiSpriteAction;
   ssNr, ssCnt                          : integer;

   a1                                   : TAction1;
   action2Table                         : TAction2Table;
   actionFTable                         : TActionFTable;
   action10Table                        : array[byte] of array of integer;

   src, dst                             : TSprite;
   psr                                  : TPseudoSpriteReader;
begin
   inherited create;
   fGrfName := aGrfName;
   fAction8 := nil;
   for i := low(TFeature) to high(TFeature) do fEntity[i] := TEntityList.create;

   grfFile.ownsObjects := false;
   fSprites := TObjectList.create(true);

   msa := nil;
   ssCnt := 0;
   ssNr := 0;

   a1 := nil;
   for i := 0 to 255 do
   begin
      setLength(action10Table[i], 0);
      action2Table[i] := nil;
   end;
   for i := 0 to 127 do actionFTable[i] := nil;

   // Process NewGrf
   for i := 0 to grfFile.count - 1 do
   begin
      src := grfFile[i] as TSprite;
      if ssCnt > 0 then
      begin
         dst := msa.processSubSprite(ssNr, src);
         inc(ssNr);
         if ssNr = ssCnt then
         begin
            ssCnt := 0;
            ssNr := 0;
            msa := nil;
         end;
      end else
      if src is TPseudoSprite then
      begin
         psr := TPseudoSpriteReader.create(src as TPseudoSprite);
         if i = 0 then dst := TSpriteCountSprite.create(self, psr) else
         begin
            case psr.peekByte of
               $00: dst := TAction0.create(self, psr);
               $01: begin
                       a1 := TAction1.create(self, psr);
                       dst := a1;
                    end;
               $02: dst := TAction2.readAction2(self, psr, action2Table, a1);
               $03: dst := TAction3.create(self, psr, action2Table);
               $04: dst := TAction4.create(self, psr);
               $05: dst := TAction5.create(self, psr);
               $06: dst := TAction6.create(self, psr);
               $07: dst := TAction7.create(self, psr);
               $08: begin
                       dst := TAction8.create(self, psr);
                       if fAction8 = nil then fAction8 := dst as TAction8 else
                                              (dst as TNewGrfSprite).error('Multiple Action8 found. Using first one, ignoring this one.');
                    end;
               $09: dst := TAction9.create(self, psr);
               $0A: dst := TActionA.create(self, psr);
               $0B: dst := TActionB.create(self, psr);
               $0C: dst := TActionC.create(self, psr);
               $0D: dst := TActionD.create(self, psr);
               $0E: dst := TActionE.create(self, psr);
               $0F: dst := TActionF.create(self, psr, actionFTable);
               $10: begin
                       dst := TAction10.create(self, psr);
                       j := (dst as TAction10).labelNr;
                       k := length(action10Table[j]);
                       setLength(action10Table[j], k + 1);
                       action10Table[j][k] := i;
                    end;
               $11: dst := TAction11.create(self, psr);
               $12: dst := TAction12.create(self, psr);
               $13: dst := TAction13.create(self, psr);
               else dst := src;
            end;
         end;
         psr.free;
      end else dst := src;

      fSprites.add(dst);
      if src <> dst then src.free;

      if dst is TMultiSpriteAction then
      begin
         msa := dst as TMultiSpriteAction;
         ssCnt := msa.subSpriteCount;
         ssNr := 0;
      end;
   end;
   if ssCnt > 0 then msa.error('Unexpected end of file: ' + intToStr(ssCnt - ssNr) + ' more sprites expected.');

   // Set up Action7/9 destinations and Action8 links
   for i := 0 to fSprites.count - 1 do
   begin
      if fSprites[i] is TAction79 then
         with fSprites[i] as TAction79 do
         begin
            j := skip;
            if length(action10Table[j]) > 0 then
            begin
               // jump to label
               destination := fSprites[action10Table[j][0]] as TSprite;
               for k := 0 to length(action10Table[j]) - 1 do
               begin
                  if action10Table[j][k] > i then
                  begin
                     destination := fSprites[action10Table[j][k]] as TSprite;
                     break;
                  end;
               end;
            end else
            begin
               // skip sprites
               if (j > 0) and (i + j + 1 < fSprites.count) then destination := fSprites[i + 1 + j] as TSprite;
            end;
         end;
      if fSprites[i] is TNewGrfSprite then (fSprites[i] as TNewGrfSprite).secondPass;
   end;
   grfFile.free;
end;

destructor TNewGrfFile.destroy;
var
   i                                    : integer;
begin
   fSprites.free;
   for i := low(TFeature) to high(TFeature) do fEntity[i].free;
   inherited destroy;
end;

(*
 * Generates a html file out of a Newgrf.
 * @param path         Path, where to store the output. With trailing backslash.
 * @param grfName      Filename of Grf, used for some titles.
 * @param newgrf       List of parsed Sprites.
 * @param aimedWidth   Approximated width for output in pixels. Used to guess number of columns in some tables.
 * @param suppressData If true, do not generate any files except the actual html files.
 *)
procedure TNewGrfFile.printHtml(path: string; settings: TGrf2HtmlSettings);
var
   t, t2                                : textFile;
   b, b2                                : array[word] of byte; // text file buffers
   i, j                                 : integer;
   s                                    : TSprite;
   str                                  : string;
   ssCnt, spriteCount                   : integer;
   first                                : boolean;
begin
   if settings.range[0] < 0 then settings.range[0] := 0;
   if settings.range[1] >= sprites.count then settings.range[1] := sprites.count - 1;
   if settings.range[1] >= settings.range[0] then
   begin
      // Enlarge settings.range to include whole MultiSpriteActions
      for i := settings.range[1] downto 0 do
      begin
         if sprites[i] is TMultiSpriteAction then
         begin
            ssCnt := (sprites[i] as TMultiSpriteAction).subSpriteCount;
            if (i < settings.range[0]) and (i + ssCnt >= settings.range[0]) then settings.range[0] := i;
            if i + ssCnt > settings.range[1] then settings.range[1] := i + ssCnt;
         end;
      end;

      if settings.range[1] >= sprites.count then settings.range[1] := sprites.count - 1;
      spriteCount := settings.range[1] - settings.range[0] + 1;
   end else spriteCount := 0;

   assignFile(t, path + 'index.html');
   rewrite(t);
   writeln(t, '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN">');
   writeln(t, '<html><head>');
   writeln(t, '<title>' + fGrfName + '</title>');
   writeln(t, '<meta http-equiv="content-type" content="text/html; charset=utf-8">');
   writeln(t, '<meta name="generator" content="', grf2HtmlVersion, '">');
   writeln(t, '</head>');
   write(t, '<frameset');
   if (settings.indexFrame = boolYes) or (settings.entityFrame = boolYes) then writeln(t, ' cols="', settings.linkFrameWidth, ',*">') else
                                                                               writeln(t, '>');
   if (settings.indexFrame = boolYes) and (settings.entityFrame = boolYes) then writeln(t, ' <frameset rows="*,*" noresize>');
   if settings.indexFrame  = boolYes then writeln(t, '  <frame src="sprites.html" name="sprites">');
   if settings.entityFrame = boolYes then writeln(t, '  <frame src="entities.html" name="entities">');
   if (settings.indexFrame = boolYes) and (settings.entityFrame = boolYes) then writeln(t, ' </frameset>');
   writeln(t, ' <frame src="nfo.html" name="content">');
   writeln(t, '<noframes><body><a href="nfo.html">Content of grf</a></body></noframes>');
   writeln(t, '</frameset></html>');
   closeFile(t);

   if settings.entityFrame = boolYes then
   begin
      assignFile(t, path + 'entities.html');
      rewrite(t);
      writeln(t, '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">');
      writeln(t, '<html><head>');
      writeln(t, '<title>Entities in ', fGrfName, '</title>');
      writeln(t, '<meta http-equiv="content-type" content="text/html; charset=utf-8">');
      writeln(t, '<meta name="generator" content="', grf2HtmlVersion, '">');
      writeln(t, '</head><body>');

      for i := low(TFeature) to high(TFeature) do
      if fEntity[i].count > 0 then
      begin
         first := true;
         str := TableFeature[i];
         if str = 'unknown' then str := 'Unknown Feature 0x' + intToHex(i, 2);
         for j := 0 to fEntity[i].count - 1 do
         begin
            // Skip entities if no sprites of it are in the output range
            if not fEntity[i].entity[j].hasInRange(settings.range[0], settings.range[1]) then continue;

            if first then writeln(t, '<p><font size="+2"><b>', str, '</b></font><table width="100%" rules="rows" border="1">');
            first := false;
            writeln(t, '<tr valign="top"><th align="left"><a name="feat', intToHex(i, 2), 'id', intToHex(fEntity[i].ID[j], 4), '">0x', intToHex(fEntity[i].ID[j], 2), '</th><td>');
            fEntity[i].entity[j].printHtml('entities', t, path, settings, false);
            writeln(t, '</td></tr>');
         end;
         if not first then writeln(t, '</table></p>');
      end;

      writeln(t, '</body></html>');
      closeFile(t);
   end;

   if settings.indexFrame = boolYes then
   begin
      assignFile(t, path + 'sprites.html');
      setTextBuf(t, b, sizeof(b));
      rewrite(t);
      writeln(t, '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">');
      writeln(t, '<html><head>');
      writeln(t, '<title>Sprites in ', fGrfName, '</title>');
      writeln(t, '<meta http-equiv="content-type" content="text/html; charset=utf-8">');
      writeln(t, '<meta name="generator" content="', grf2HtmlVersion, '">');
      writeln(t, '</head><body><table summary="Sprite Index" width="100%">');
   end;

   assignFile(t2, path + 'nfo.html');
   setTextBuf(t2, b2, sizeof(b2));
   rewrite(t2);
   writeln(t2, '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">');
   writeln(t2, '<html><head>');
   writeln(t2, '<title>', fGrfName, '</title>');
   writeln(t2, '<meta http-equiv="content-type" content="text/html; charset=utf-8">');
   writeln(t2, '<meta name="generator" content="', grf2HtmlVersion, '">');
   writeln(t2, '</head><body><table summary="Grf Content" width="100%" border="1" rules="rows">');

   ssCnt := 0;
   write('Generating html  0%');
   for i := settings.range[0] to settings.range[1] do
   begin
      if i * 100 div spriteCount <> (i - 1) * 100 div spriteCount then write(#13'Generating html', (i * 100 div spriteCount): 3, '%');

      s := fSprites[i] as TSprite;
      if (settings.indexFrame = boolYes) and ((ssCnt = 0) or (settings.subSpritesInIndex = boolYes)) then
      begin
         writeln(t, '<tr><td align=right>', i, '</td><td>', s.printHtmlSpriteLink('sprites', settings, false), '</td></tr>');
      end;

      if ssCnt > 0 then dec(ssCnt) else
      begin
         writeln(t2, '<tr valign="top"><td align=right>', s.printHtmlSpriteAnchor, s.printHtmlSpriteNr, '</td><td>');
         try
            s.printHtml(t2, path, settings);
         except
            on E: Exception do
               begin
                  writeln('Exception: ', E.message);
                  writeln(t, '<tr><td colspan="2">Exception: ', E.message, '</td></tr>');
                  writeln(t2, '<br><br>Exception: ', E.message);
                  closeFile(t);
                  closeFile(t2);
                  halt;
               end;
         end;
         writeln(t2, '</td></tr>');
      end;

      if s is TMultiSpriteAction then ssCnt := (s as TMultiSpriteAction).subSpriteCount;
   end;

   writeln(#13'Generating html finished');

   writeln(t2, '</table>Generated by ', grf2HtmlVersion, '</body></html>');
   closeFile(t2);

   if settings.indexFrame = boolYes then
   begin
      writeln(t, '</table></body></html>');
      closeFile(t);
   end;
end;

function TNewGrfFile.getEntity(f: TFeature; id: integer): TSpriteSet;
begin
   result := fEntity[f].findEntity(id);
end;

procedure TNewGrfFile.registerEntity(f: TFeature; id: integer; s: TSprite);
begin
   // Global properties have nothing in common. Do not register them.
   if f <> FGlobal then fEntity[f].findEntity(id, true).add(s);
end;

function TNewGrfFile.printEntityLinkBegin(const srcFrame: string; f: TFeature; id: integer) : string;
begin
   result := printLinkBegin(srcFrame, 'entities', 'entities.html#feat' + intToHex(f, 2) + 'id' + intToHex(id, 4));
end;


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


constructor TNewGrfSprite.create(aNewGrfFile: TNewGrfFile; spriteNr: integer);
begin
   inherited create(spriteNr);
   fErrors := TStringList.create;
   fNewGrfFile := aNewGrfFile;
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

procedure TNewGrfSprite.secondPass;
begin
   // nothing to do
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


constructor TSpriteCountSprite.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
begin
   inherited create(aNewGrfFile, ps.spriteNr);
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


constructor TRecolorSprite.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
var
   i                                    : integer;
begin
   inherited create(aNewGrfFile, ps.spriteNr);
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


constructor TMultiSpriteAction.create(aNewGrfFile: TNewGrfFile; spriteNr: integer);
begin
   inherited create(aNewGrfFile, spriteNr);
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


constructor TAction8.create(aNewGrfFile: TNewGrfFile; ps: TPseudoSpriteReader);
begin
   inherited create(aNewGrfFile, ps.spriteNr);
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


constructor TSpriteSet.create;
begin
   inherited create;
   fSprites := TList.create;
end;

destructor TSpriteSet.destroy;
begin
   fSprites.free;
   inherited destroy;
end;

function TSpriteSet.findPosition(nr: integer): integer;
var
   first, last                          : integer;
   spr                                  : integer;
begin
   first := 0;
   last := fSprites.count;
   while first < last do
   begin
      result := (first + last) div 2;
      spr := TSprite(fSprites[result]).spriteNr;
      if spr = nr then exit;
      if spr < nr then first := result + 1 else last := result;
   end;
   result := first;
end;

procedure TSpriteSet.add(s: TSprite);
var
   p                                    : integer;
begin
   p := findPosition(s.spriteNr);
   if p >= fSprites.count then fSprites.add(s) else
      if fSprites[p] <> s then fSprites.insert(p,s);
end;

procedure TSpriteSet.printHtml(const srcFrame: string; var t: textFile; path: string; const settings: TGrf2HtmlSettings; singleLine: boolean);
var
   i                                    : integer;
begin
   if fSprites.count = 0 then writeln(t, '-') else
   begin
      for i := 0 to fSprites.count - 1 do
      begin
         if i <> 0 then
         begin
            if singleLine then write(t, ', ') else writeln(t, '<br>');
         end;
         write(t, TSprite(fSprites[i]).printHtmlSpriteLink(srcFrame, settings));
      end;
      writeln(t);
   end;
end;

function TSpriteSet.hasInRange(min, max:integer) : boolean;
var
   i, nr                                : integer;
begin
   result := true;
   for i := 0 to fSprites.count - 1 do
   begin
      nr := TSprite(fSprites[i]).spriteNr;
      if (nr >= min) and (nr <= max) then exit;
   end;
   result := false;
end;


constructor TEntityList.create;
begin
   inherited create;
   setLength(fIDs, 0);
   setLength(fEntity, 0);
end;

destructor TEntityList.destroy;
var
   i                                    : integer;
begin
   for i := 0 to length(fEntity) - 1 do fEntity[i].free;
   inherited destroy;
end;

function TEntityList.findEntity(id: integer; createNew: boolean = false): TSpriteSet;
var
   i, j                                 : integer;
begin
   i := 0;
   while (i < length(fIDs)) and (fIDs[i] < id) do inc(i);

   if (i >= length(fIDs)) or (fIDs[i] <> id) then
   begin
      if not createNew then
      begin
         result := nil;
         exit;
      end;

      setLength(fIDs, length(fIDs) + 1);
      setLength(fEntity, length(fIDs) + 1);
      for j := length(fIDs) - 1 downto i + 1 do
      begin
         fIDs[j] := fIDs[j - 1];
         fEntity[j] := fEntity[j - 1];
      end;
      fIDs[i] := id;
      fEntity[i] := TSpriteSet.create;
   end;

   result := fEntity[i];
end;

function TEntityList.getID(i: integer) : integer;
begin
   result := fIDs[i];
end;

function TEntityList.getEntity(i: integer): TSpriteSet;
begin
   result := fEntity[i];
end;

function TEntityList.getCount: integer;
begin
   result := length(fIDs);
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
                  $01: begin
                          charlen := 2;
                          if i + 1 <= length(s) then tmp := ord(s[i + 1]) else tmp := 0;
                          result := result + '&lt;0x01 X offset 0x' + intToHex(tmp, 2) + ' (' + intToStr(tmp) + ')&gt;';
                       end;
                  $1F: begin
                          charlen := 3;
                          if i + 1 <= length(s) then tmp := ord(s[i + 1]) else tmp := 0;
                          if i + 2 <= length(s) then tmp2 := ord(s[i + 2]) else tmp2 := 0;
                          result := result + '&lt;0x1F X offset 0x' + intToHex(tmp , 2) + ' (' + intToStr(tmp ) + '); ' +
                                                      'Y offset 0x' + intToHex(tmp2, 2) + ' (' + intToStr(tmp2) + ')&gt;';
                       end;
                  $81: begin
                          charlen := 3;
                          tmp := 0;
                          if i + 1 <= length(s) then tmp := tmp or ord(s[i + 1]);
                          if i + 2 <= length(s) then tmp := tmp or (ord(s[i + 2]) shl 8);
                          result := result + '&lt;0x81 string 0x' + intToHex(tmp, 4) + '&gt;';
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

function unsignedCast(v: longword; size: integer): longword;
begin
   result := v and ($FFFFFFFF shr (8 * (4 - size)));
end;

function signedCast(v: longword; size: integer): longint;
begin
   if size < 4 then
   begin
      v := unsignedCast(v, size);
      result := v;
      if v shr (8 * size - 1) <> 0 then result := result - 1 shl (8 * size);
   end else result := v;
end;

procedure printAbout;
begin
   writeln(grf2HtmlVersion);
   writeln('Copyright 2007-2008 by Christoph Elsenhans.');
   writeln;
   writeln('This program comes with ABSOLUTELY NO WARRANTY.');
   writeln('This is free software, and you are welcome to redistribute it');
   writeln('under certain conditions; see "COPYING.txt" for details.');
   writeln;
   writeln('Based on TTDPatch documentation and NewGraphicsSpecs from ', dataVersion); // they have written all the texts :)
   writeln('Visit http://wiki.ttdpatch.net/tiki-index.php?page=NewGraphicsSpecs');
   writeln;
   {$IFNDEF FPC}
      writeln('This tool makes use of PNG Delphi by Gustavo Daud'); // the author wants to get mentioned
      writeln('Visit http://pngdelphi.sourceforge.net');
      writeln;
   {$ENDIF}
end;

end.
