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
unit newgrf;

interface

uses sysutils, classes, contnrs, grfbase, nfobase, nfoact0, nfoact123, nfoact5A12, nfoact, outputsettings;

const
   grf2HtmlVersion                      : string = 'Grf2Html 0.4';
   dataVersion                          : string = '6th February 2008';

type
   TNewGrfFile = class
   private
      fGrfName     : string;
      fSprites     : TObjectList;
   public
      constructor create(aGrfName: string; grfFile: TObjectList);
      destructor destroy; override;
      procedure printHtml(path: string; settings: TGrf2HtmlSettings);
      property grfName: string read fGrfName write fGrfName;
      property sprites: TObjectList read fSprites;
   end;

procedure printAbout;

implementation

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
   a8                                   : TAction8;
   actionFTable                         : TActionFTable;
   action10Table                        : array[byte] of array of integer;

   src, dst                             : TSprite;
   psr                                  : TPseudoSpriteReader;
begin
   inherited create;
   fGrfName := aGrfName;
   grfFile.ownsObjects := false;
   fSprites := TObjectList.create(true);

   msa := nil;
   ssCnt := 0;
   ssNr := 0;

   a1 := nil;
   a8 := nil;
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
         if i = 0 then dst := TSpriteCountSprite.create(psr) else
         begin
            case psr.peekByte of
               $00: dst := TAction0.create(psr);
               $01: begin
                       a1 := TAction1.create(psr);
                       dst := a1;
                    end;
               $02: dst := TAction2.readAction2(psr, action2Table, a1);
               $03: dst := TAction3.create(psr, action2Table);
               $04: dst := TAction4.create(psr);
               $05: dst := TAction5.create(psr);
               $06: dst := TAction6.create(psr);
               $07: dst := TAction7.create(psr);
               $08: begin
                       dst := TAction8.create(psr);
                       if a8 = nil then a8 := dst as TAction8 else
                                        (dst as TNewGrfSprite).error('Multiple Action8 found. Using first one, ignoring this one.');
                    end;
               $09: dst := TAction9.create(psr);
               $0A: dst := TActionA.create(psr);
               $0B: dst := TActionB.create(psr);
               $0C: dst := TActionC.create(psr);
               $0D: dst := TActionD.create(psr);
               $0E: dst := TActionE.create(psr);
               $0F: dst := TActionF.create(psr, actionFTable);
               $10: begin
                       dst := TAction10.create(psr);
                       j := (dst as TAction10).labelNr;
                       k := length(action10Table[j]);
                       setLength(action10Table[j], k + 1);
                       action10Table[j][k] := i;
                    end;
               $11: dst := TAction11.create(psr);
               $12: dst := TAction12.create(psr);
               $13: dst := TAction13.create(psr);
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
      if fSprites[i] is TNewGrfSprite then (fSprites[i] as TNewGrfSprite).useAction8(a8);
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
   end;
   grfFile.free;
end;

destructor TNewGrfFile.destroy;
begin
   fSprites.free;
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
   i                                    : integer;
   s                                    : TSprite;
   ssCnt, spriteCount                   : integer;
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
   writeln(t, '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">');
   writeln(t, '<html><head>');
   writeln(t, '<title>' + fGrfName + '</title>');
   writeln(t, '<meta http-equiv="content-type" content="text/html; charset=utf-8">');
   writeln(t, '<meta name="generator" content="', grf2HtmlVersion, '">');
   writeln(t, '</head>');
   writeln(t, '<frameset cols="', settings.linkFrameWidth, ',*"><frame src="sprites.html" name="sprites" noresize><frame src="nfo.html" name="content">');
   writeln(t, '<noframes><body><a href="nfo.html">Content of grf</a></body></noframes>');
   writeln(t, '</frameset></html>');
   closeFile(t);

   assignFile(t, path + 'sprites.html');
   setTextBuf(t, b, sizeof(b));
   rewrite(t);
   writeln(t, '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">');
   writeln(t, '<html><head>');
   writeln(t, '<title>Sprites in ', fGrfName, '</title>');
   writeln(t, '<meta http-equiv="content-type" content="text/html; charset=utf-8">');
   writeln(t, '<meta name="generator" content="', grf2HtmlVersion, '">');
   writeln(t, '</head><body><table summary="Sprite Index" width="100%">');

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
      writeln(t, '<tr><td align=right>', i, '</td><td><a href="nfo.html#sprite', i, '" target="content">', s.getShortDesc, '</a></td></tr>');

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

   writeln(t, '</table></body></html>');
   closeFile(t);
end;

end.
