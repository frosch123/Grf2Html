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
unit tables;

interface

uses sysutils, classes, contnrs, nfobase;

type
   TTable = class(TStringList)
   protected
      function getFromTable(i: integer): string;
   public
      property table[i: integer]: string read getFromTable; default;
   end;

var
   TableFeature                         : TTable;
   TablePrimaryObject                   : TTable;
   TableRelatedObject                   : TTable;
   TableLanguage                        : TTable;

   TableAction0General                  : TTable;
   TableAction0Features                 : array[FTrain..FObject] of TTable;

   TableVarAction2Operator              : TTable;
   TableVarAction2General               : TTable;
   TableVarAction2Features              : array[FTrain..FObject] of TTable;
   TableVarAction2Related               : array[FTrain..FObject] of TTable;

   TableRandomAction2Features           : array[FTrain..FObject] of TTable;

   TableAction5Type                     : TTable;

   TableAction79DVariable               : TTable;
   TableAction79Condition               : TTable;

   TableActionBMessage                  : TTable;
   TableActionBSeverity                 : TTable;

   TableActionDOperation                : TTable;
   TableActionDPatchVars                : TTable;
   TableActionDGRMOperation             : TTable;

   TableAction12Font                    : TTable;

implementation

{$R tables.res}

function TTable.getFromTable(i: integer): string;
var
   s                                    : string;
   j                                    : integer;
begin
   s := intToHex(i, pos('=', strings[0]) - 1) + '=';
   for j := 0 to count - 1 do
      if compareText(copy(strings[j], 1, length(s)), s) = 0 then
      begin
         result := strings[j];
         system.delete(result, 1, length(s));
         exit;
      end;
   result := 'unknown';
end;

function loadTable(name: string): TTable;
var
   rs                                   : TResourceStream;
begin
   result := TTable.create;
   rs := TResourceStream.create(hInstance, name, 'txt');
   result.loadFromStream(rs);
   rs.free;
end;

procedure loadAllTables;
begin
   TableFeature                          := loadTable('TableFeature');
   TablePrimaryObject                    := loadTable('TablePrimaryObject');
   TableRelatedObject                    := loadTable('TableRelatedObject');
   TableLanguage                         := loadTable('TableLanguage');

   TableAction0General                   := loadTable('TableAction0General');
   TableAction0Features[FTrain]          := loadTable('TableAction0Trains');
   TableAction0Features[FRoadVeh]        := loadTable('TableAction0RoadVehs');
   TableAction0Features[FShip]           := loadTable('TableAction0Ships');
   TableAction0Features[FAircraft]       := loadTable('TableAction0Aircraft');
   TableAction0Features[FStation]        := loadTable('TableAction0Stations');
   TableAction0Features[FCanal]          := loadTable('TableAction0Canals');
   TableAction0Features[FBridge]         := loadTable('TableAction0Bridges');
   TableAction0Features[FHouse]          := loadTable('TableAction0Houses');
   TableAction0Features[FGlobal]         := loadTable('TableAction0Global');
   TableAction0Features[FIndTile]        := loadTable('TableAction0IndTiles');
   TableAction0Features[FIndustry]       := loadTable('TableAction0Industries');
   TableAction0Features[FCargo]          := loadTable('TableAction0Cargos');
   TableAction0Features[FSound]          := loadTable('TableAction0Sounds');
   TableAction0Features[FAirport]        := nil;
   TableAction0Features[FSignal]         := nil;
   TableAction0Features[FObject]         := loadTable('TableAction0Objects');

   TableVarAction2Operator               := loadTable('TableVarAction2Operator');
   TableVarAction2General                := loadTable('TableVarAction2General');

   TableVarAction2Features[FTrain]       := loadTable('TableVarAction2Vehicles');
   TableVarAction2Related[FTrain]        := loadTable('TableVarAction2Vehicles');
   TableVarAction2Features[FRoadVeh]     := loadTable('TableVarAction2Vehicles');
   TableVarAction2Related[FRoadVeh]      := loadTable('TableVarAction2Vehicles');
   TableVarAction2Features[FShip]        := loadTable('TableVarAction2Vehicles');
   TableVarAction2Related[FShip]         := loadTable('TableVarAction2Vehicles');
   TableVarAction2Features[FAircraft]    := loadTable('TableVarAction2Vehicles');
   TableVarAction2Related[FAircraft]     := loadTable('TableVarAction2Vehicles');

   TableVarAction2Features[FStation]     := loadTable('TableVarAction2Stations');
   TableVarAction2Related[FStation]      := loadTable('TableVarAction2Towns');

   TableVarAction2Features[FCanal]       := loadTable('TableVarAction2Canals');
   TableVarAction2Related[FCanal]        := nil;

   TableVarAction2Features[FBridge]      := nil;
   TableVarAction2Related[FBridge]       := nil;

   TableVarAction2Features[FHouse]       := loadTable('TableVarAction2Houses');
   TableVarAction2Related[FHouse]        := loadTable('TableVarAction2Towns');

   TableVarAction2Features[FGlobal]      := nil;
   TableVarAction2Related[FGlobal]       := nil;

   TableVarAction2Features[FIndTile]     := loadTable('TableVarAction2IndTiles');
   TableVarAction2Related[FIndTile]      := loadTable('TableVarAction2Industries');

   TableVarAction2Features[FIndustry]    := loadTable('TableVarAction2Industries');
   TableVarAction2Related[FIndustry]     := loadTable('TableVarAction2Towns');

   TableVarAction2Features[FCargo]       := nil;
   TableVarAction2Related[FCargo]        := nil;

   TableVarAction2Features[FSound]       := nil;
   TableVarAction2Related[FSound]        := nil;

   TableVarAction2Features[FAirport]     := nil;
   TableVarAction2Related[FAirport]      := nil;

   TableVarAction2Features[FSignal]      := loadTable('TableVarAction2Signals');
   TableVarAction2Related[FSignal]       := nil;

   TableVarAction2Features[FObject]      := nil;
   TableVarAction2Related[FObject]       := nil;

   TableRandomAction2Features[FTrain]    := loadTable('TableRandomAction2Vehicles');
   TableRandomAction2Features[FRoadVeh]  := loadTable('TableRandomAction2Vehicles');
   TableRandomAction2Features[FShip]     := loadTable('TableRandomAction2Vehicles');
   TableRandomAction2Features[FAircraft] := loadTable('TableRandomAction2Vehicles');
   TableRandomAction2Features[FStation]  := loadTable('TableRandomAction2Stations');
   TableRandomAction2Features[FCanal]    := nil;
   TableRandomAction2Features[FBridge]   := nil;
   TableRandomAction2Features[FHouse]    := loadTable('TableRandomAction2Houses');
   TableRandomAction2Features[FGlobal]   := nil;
   TableRandomAction2Features[FIndTile]  := loadTable('TableRandomAction2IndTiles');
   TableRandomAction2Features[FIndustry] := nil;
   TableRandomAction2Features[FCargo]    := nil;
   TableRandomAction2Features[FSound]    := nil;
   TableRandomAction2Features[FAirport]  := nil;
   TableRandomAction2Features[FSignal]   := nil;
   TableRandomAction2Features[FObject]   := nil;

   TableAction5Type                      := loadTable('TableAction5Type');

   TableAction79DVariable                := loadTable('TableAction79DVariable');
   TableAction79Condition                := loadTable('TableAction79Condition');

   TableActionBMessage                   := loadTable('TableActionBMessage');
   TableActionBSeverity                  := loadTable('TableActionBSeverity');

   TableActionDOperation                 := loadTable('TableActionDOperation');
   TableActionDPatchVars                 := loadTable('TableActionDPatchVars');
   TableActionDGRMOperation              := loadTable('TableActionDGRMOperation');

   TableAction12Font                     := loadTable('TableAction12Font');
end;

procedure freeAllTables;
var
   i                                    : integer;
begin
   TableFeature.free;
   TablePrimaryObject.free;
   TableRelatedObject.free;
   TableLanguage.free;

   TableAction0General.free;
   for i := low(TableAction0Features) to high(TableAction0Features) do TableAction0Features[i].free;

   TableVarAction2Operator.free;
   TableVarAction2General.free;
   for i := low(TableVarAction2Features) to high(TableVarAction2Features) do
   begin
      TableVarAction2Features[i].free;
      TableVarAction2Related[i].free;
      TableRandomAction2Features[i].free;
   end;

   TableAction5Type.free;

   TableAction79DVariable.free;
   TableAction79Condition.free;

   TableActionBMessage.free;
   TableActionBSeverity.free;

   TableActionDOperation.free;
   TableActionDPatchVars.free;
   TableActionDGRMOperation.free;

   TableAction12Font.free;
end;

initialization
   loadAllTables;

finalization
   freeAllTables;

end.
