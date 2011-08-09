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
unit tables;

interface

uses sysutils, classes, contnrs, nfobase;

// Uncomment the following line, if the tables should be checked for validity on load.
{$DEFINE testTables}

(*
 * Format of tables:
 *    ID=Col1@Col2@Col3
 *
 *  ID     hexadecimal ID; same width for all items; sorted ascending.
 *  =      Separator between ID and item.
 *  ColX   Data for column X.
 *  @      Separator between columns.
 *
 * Note: The IDs are so restrictive to prevent typos in the resources.
 *)

type
   TTable = class(TStringList)
   private
      fColumns   : integer;
      fIDLen     : byte;
   protected
      function getFromTable(id, column: integer): string;
   public
      procedure parseTable; virtual;
      property table[id, column: integer]: string read getFromTable; default;
      property columns: integer read fColumns;
   end;
   TSingleColumnTable = class(TTable)
   private
      function getFirstColumn(id: integer): string;
   public
      procedure parseTable; override;
      property firstColumn[id: integer]: string read getFirstColumn; default;
   end;

var
   TableFeature                         : TSingleColumnTable;
   TablePrimaryObject                   : TSingleColumnTable;
   TableRelatedObject                   : TSingleColumnTable;
   TableLanguage                        : TSingleColumnTable;
   TableStringCode                      : TSingleColumnTable;

   TableAction0General                  : TTable;
   TableAction0Features                 : array[FFirst..FLast] of TTable;

   TableVariables                       : TSingleColumnTable; // Variables in VarAction2 (non-feature specific) and Action 7/9/D (minus 0x80).

   TableVarAction2Operator              : TSingleColumnTable;
   TableVarAction2Features              : array[FFirst..FLast] of TSingleColumnTable;
   TableVarAction2Related               : array[FFirst..FLast] of TSingleColumnTable;

   TableRandomAction2Features           : array[FFirst..FLast] of TSingleColumnTable;

   TableAction5Type                     : TSingleColumnTable;

   TableAction79Condition               : TSingleColumnTable;

   TableActionBMessage                  : TSingleColumnTable;
   TableActionBSeverity                 : TTable;

   TableActionDOperation                : TSingleColumnTable;
   TableActionDPatchVars                : TSingleColumnTable;
   TableActionDGRMOperation             : TSingleColumnTable;

   TableAction12Font                    : TSingleColumnTable;

implementation

{$R tables.res}

type
   TTableClass = class of TTable;
   TTableList = record
      name : string;
      typ  : TTableClass;
      table: ^TTable;
   end;

const
   TableList : array[0..(16 + 4 * (FLast + 1)) - 1] of TTableList = (
      (name:'TableFeature'                ; typ:TSingleColumnTable; table:@TableFeature),
      (name:'TablePrimaryObject'          ; typ:TSingleColumnTable; table:@TablePrimaryObject),
      (name:'TableRelatedObject'          ; typ:TSingleColumnTable; table:@TableRelatedObject),
      (name:'TableLanguage'               ; typ:TSingleColumnTable; table:@TableLanguage),
      (name:'TableStringCode'             ; typ:TSingleColumnTable; table:@TableStringCode),

      (name:'TableAction0General'         ; typ:TTable            ; table:@TableAction0General),
      (name:'TableAction0Trains'          ; typ:TTable            ; table:@TableAction0Features[FTrain]),
      (name:'TableAction0RoadVehs'        ; typ:TTable            ; table:@TableAction0Features[FRoadVeh]),
      (name:'TableAction0Ships'           ; typ:TTable            ; table:@TableAction0Features[FShip]),
      (name:'TableAction0Aircraft'        ; typ:TTable            ; table:@TableAction0Features[FAircraft]),
      (name:'TableAction0Stations'        ; typ:TTable            ; table:@TableAction0Features[FStation]),
      (name:'TableAction0Canals'          ; typ:TTable            ; table:@TableAction0Features[FCanal]),
      (name:'TableAction0Bridges'         ; typ:TTable            ; table:@TableAction0Features[FBridge]),
      (name:'TableAction0Houses'          ; typ:TTable            ; table:@TableAction0Features[FHouse]),
      (name:'TableAction0Global'          ; typ:TTable            ; table:@TableAction0Features[FGlobal]),
      (name:'TableAction0IndTiles'        ; typ:TTable            ; table:@TableAction0Features[FIndTile]),
      (name:'TableAction0Industries'      ; typ:TTable            ; table:@TableAction0Features[FIndustry]),
      (name:'TableAction0Cargos'          ; typ:TTable            ; table:@TableAction0Features[FCargo]),
      (name:'TableAction0Sounds'          ; typ:TTable            ; table:@TableAction0Features[FSound]),
      (name:''                            ; typ:TTable            ; table:@TableAction0Features[FAirport]),
      (name:''                            ; typ:TTable            ; table:@TableAction0Features[FSignal]),
      (name:'TableAction0Objects'         ; typ:TTable            ; table:@TableAction0Features[FObject]),
      (name:'TableAction0Railtypes'       ; typ:TTable            ; table:@TableAction0Features[FRailType]),
      (name:'TableAction0AirTiles'        ; typ:TTable            ; table:@TableAction0Features[FAirTile]),

      (name:'TableVariables'              ; typ:TSingleColumnTable; table:@TableVariables),

      (name:'TableVarAction2Operator'     ; typ:TSingleColumnTable; table:@TableVarAction2Operator),

      (name:'TableVarAction2Vehicles'     ; typ:TSingleColumnTable; table:@TableVarAction2Features[FTrain]),
      (name:'TableVarAction2Vehicles'     ; typ:TSingleColumnTable; table:@TableVarAction2Related[FTrain]),
      (name:'TableVarAction2Vehicles'     ; typ:TSingleColumnTable; table:@TableVarAction2Features[FRoadVeh]),
      (name:'TableVarAction2Vehicles'     ; typ:TSingleColumnTable; table:@TableVarAction2Related[FRoadVeh]),
      (name:'TableVarAction2Vehicles'     ; typ:TSingleColumnTable; table:@TableVarAction2Features[FShip]),
      (name:'TableVarAction2Vehicles'     ; typ:TSingleColumnTable; table:@TableVarAction2Related[FShip]),
      (name:'TableVarAction2Vehicles'     ; typ:TSingleColumnTable; table:@TableVarAction2Features[FAircraft]),
      (name:'TableVarAction2Vehicles'     ; typ:TSingleColumnTable; table:@TableVarAction2Related[FAircraft]),

      (name:'TableVarAction2Stations'     ; typ:TSingleColumnTable; table:@TableVarAction2Features[FStation]),
      (name:'TableVarAction2Towns'        ; typ:TSingleColumnTable; table:@TableVarAction2Related[FStation]),

      (name:'TableVarAction2Canals'       ; typ:TSingleColumnTable; table:@TableVarAction2Features[FCanal]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableVarAction2Related[FCanal]),

      (name:'TableVarAction2Bridges'      ; typ:TSingleColumnTable; table:@TableVarAction2Features[FBridge]),
      (name:'TableVarAction2Towns'        ; typ:TSingleColumnTable; table:@TableVarAction2Related[FBridge]),

      (name:'TableVarAction2Houses'       ; typ:TSingleColumnTable; table:@TableVarAction2Features[FHouse]),
      (name:'TableVarAction2Towns'        ; typ:TSingleColumnTable; table:@TableVarAction2Related[FHouse]),

      (name:''                            ; typ:TSingleColumnTable; table:@TableVarAction2Features[FGlobal]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableVarAction2Related[FGlobal]),

      (name:'TableVarAction2IndTiles'     ; typ:TSingleColumnTable; table:@TableVarAction2Features[FIndTile]),
      (name:'TableVarAction2Industries'   ; typ:TSingleColumnTable; table:@TableVarAction2Related[FIndTile]),

      (name:'TableVarAction2Industries'   ; typ:TSingleColumnTable; table:@TableVarAction2Features[FIndustry]),
      (name:'TableVarAction2Towns'        ; typ:TSingleColumnTable; table:@TableVarAction2Related[FIndustry]),

      (name:''                            ; typ:TSingleColumnTable; table:@TableVarAction2Features[FCargo]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableVarAction2Related[FCargo]),

      (name:''                            ; typ:TSingleColumnTable; table:@TableVarAction2Features[FSound]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableVarAction2Related[FSound]),

      (name:''                            ; typ:TSingleColumnTable; table:@TableVarAction2Features[FAirport]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableVarAction2Related[FAirport]),

      (name:'TableVarAction2Signals'      ; typ:TSingleColumnTable; table:@TableVarAction2Features[FSignal]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableVarAction2Related[FSignal]),

      (name:'TableVarAction2Objects'      ; typ:TSingleColumnTable; table:@TableVarAction2Features[FObject]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableVarAction2Related[FObject]),

      (name:'TableVarAction2RailTypes'    ; typ:TSingleColumnTable; table:@TableVarAction2Features[FRailType]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableVarAction2Related[FRailType]),

      (name:'TableVarAction2AirTiles'     ; typ:TSingleColumnTable; table:@TableVarAction2Features[FAirTile]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableVarAction2Related[FAirTile]),

      (name:'TableRandomAction2Vehicles'  ; typ:TSingleColumnTable; table:@TableRandomAction2Features[FTrain]),
      (name:'TableRandomAction2Vehicles'  ; typ:TSingleColumnTable; table:@TableRandomAction2Features[FRoadVeh]),
      (name:'TableRandomAction2Vehicles'  ; typ:TSingleColumnTable; table:@TableRandomAction2Features[FShip]),
      (name:'TableRandomAction2Vehicles'  ; typ:TSingleColumnTable; table:@TableRandomAction2Features[FAircraft]),
      (name:'TableRandomAction2Stations'  ; typ:TSingleColumnTable; table:@TableRandomAction2Features[FStation]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableRandomAction2Features[FCanal]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableRandomAction2Features[FBridge]),
      (name:'TableRandomAction2Houses'    ; typ:TSingleColumnTable; table:@TableRandomAction2Features[FHouse]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableRandomAction2Features[FGlobal]),
      (name:'TableRandomAction2IndTiles'  ; typ:TSingleColumnTable; table:@TableRandomAction2Features[FIndTile]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableRandomAction2Features[FIndustry]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableRandomAction2Features[FCargo]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableRandomAction2Features[FSound]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableRandomAction2Features[FAirport]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableRandomAction2Features[FSignal]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableRandomAction2Features[FObject]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableRandomAction2Features[FRailType]),
      (name:''                            ; typ:TSingleColumnTable; table:@TableRandomAction2Features[FAirTile]),

      (name:'TableAction5Type'            ; typ:TSingleColumnTable; table:@TableAction5Type),

      (name:'TableAction79Condition'      ; typ:TSingleColumnTable; table:@TableAction79Condition),

      (name:'TableActionBMessage'         ; typ:TSingleColumnTable; table:@TableActionBMessage),
      (name:'TableActionBSeverity'        ; typ:TTable            ; table:@TableActionBSeverity),

      (name:'TableActionDOperation'       ; typ:TSingleColumnTable; table:@TableActionDOperation),
      (name:'TableActionDPatchVars'       ; typ:TSingleColumnTable; table:@TableActionDPatchVars),
      (name:'TableActionDGRMOperation'    ; typ:TSingleColumnTable; table:@TableActionDGRMOperation),

      (name:'TableAction12Font'           ; typ:TSingleColumnTable; table:@TableAction12Font)
   );

function TTable.getFromTable(id, column: integer): string;
var
   s                                    : string;
   i, j, p                              : integer;
begin
   if count <> 0 then
   begin
      assert(column < fColumns);
      s := intToHex(id, fIDLen) + '=';
      for j := 0 to count - 1 do
         if compareText(copy(strings[j], 1, length(s)), s) = 0 then
         begin
            result := strings[j];

            i := fIDLen + 1;
            while (i <= length(result)) and (column > 0) do
            begin
               inc(i);
               if result[i] = '@' then dec(column);
            end;
            assert(column = 0);
            system.delete(result, 1, i);

            p := pos('@', result);
            if p <> 0 then system.delete(result, p, length(result));
            exit;
         end;
   end;
   result := 'unknown';
end;

procedure TTable.parseTable;
var
   i                                    : integer;
   s                                    : string;
{$IFDEF testTables}
   j, cnt, lastID, curID                : integer;
{$ENDIF}
begin
   fColumns := 1;
   if count = 0 then exit;
   s := strings[0];
   fIDLen := pos('=', s) - 1;
   assert(fIDLen > 0);
   for i := 1 to length(s) do
      if s[i] = '@' then inc(fColumns);

{$IFDEF testTables}
   lastID := -1;
   for j := 0 to count - 1 do
   begin
      s := strings[j];
      if s = '' then continue;
      assert(length(s) > fIDLen + 1);
      assert(s[fIDLen + 1] = '=');
      cnt := 1;
      for i := 1 to length(s) do
         if s[i] = '@' then inc(cnt);
      assert(cnt = fColumns, 'Invalid column count in row ' + intToStr(j) + ': ' + s);
      curID := strToInt('$' + copy(s, 1, fIDLen));
      assert(curID > lastID, 'Non-ascending IDs in row ' + intToStr(j) + ': ' + s);
      lastID := curID;
   end;
{$ENDIF}
end;

function TSingleColumnTable.getFirstColumn(id: integer): string;
begin
   result := getFromTable(id, 0);
end;

procedure TSingleColumnTable.parseTable;
begin
   inherited parseTable;
   assert(columns = 1);
end;

procedure loadTable(list: TTableList);
var
   rs                                   : TResourceStream;
begin
   list.table^ := list.typ.create;
   if list.name <> '' then
   begin
      rs := TResourceStream.create(hInstance, list.name, 'txt');
      list.table^.loadFromStream(rs);
      rs.free;
      list.table^.parseTable;
   end;
end;

procedure loadAllTables;
var
   i                                    : integer;
begin
   for i := 0 to length(TableList) - 1 do loadTable(TableList[i]);
end;

procedure freeAllTables;
var
   i                                    : integer;
begin
   for i := 0 to length(TableList) - 1 do TableList[i].table^.free;
end;

initialization
   loadAllTables;

finalization
   freeAllTables;

end.
