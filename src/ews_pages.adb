--  Copyright (C) Simon Wright <simon@pushface.org>

--  This package is free software; you can redistribute it and/or
--  modify it under terms of the GNU General Public License as
--  published by the Free Software Foundation; either version 2, or
--  (at your option) any later version. This package is distributed in
--  the hope that it will be useful, but WITHOUT ANY WARRANTY; without
--  even the implied warranty of MERCHANTABILITY or FITNESS FOR A
--  PARTICULAR PURPOSE. See the GNU General Public License for more
--  details. You should have received a copy of the GNU General Public
--  License distributed with this package; see file COPYING.  If not,
--  write to the Free Software Foundation, 59 Temple Place - Suite
--  330, Boston, MA 02111-1307, USA.

--  $RCSfile$
--  $Revision$
--  $Date$
--  $Author$

with EWS_Pages_Support;

with Ada.Strings.Unbounded.Text_IO;
with Ada.Text_IO;

with GNAT.IO; use GNAT.IO;
with GNAT.Regpat;

procedure EWS_Pages is


   function To_String
     (In_String : String;
      From : GNAT.Regpat.Match_Array;
      At_Location : Natural) return String;

   procedure Compile (S : String);

   function Get_Contents (Of_File : String) return String;


   function To_String
     (In_String : String;
      From : GNAT.Regpat.Match_Array;
      At_Location : Natural) return String is
   begin
      return In_String (From (At_Location).First .. From (At_Location).Last);
   exception
      when others => return "";
   end To_String;


   function Get_Contents (Of_File : String) return String is
      File : Ada.Text_IO.File_Type;
      Result : Ada.Strings.Unbounded.Unbounded_String;
      use Ada.Text_IO;
      use Ada.Strings.Unbounded;
      use Ada.Strings.Unbounded.Text_IO;
   begin
      Open (File, Mode => In_File, Name => Of_File);
      while not End_Of_File (File) loop
         Result := Result & Get_Line (File);
         Append (Result, ASCII.LF);
      end loop;
      Close (File);
      return To_String (Result);
   end Get_Contents;


   procedure Compile (S : String) is
      use type GNAT.Regpat.Regexp_Flags;

      Next_Tag_Regexp : constant String
        := "(.*?)<ews:([-a-z]+)>";

      Next_Tag_Matcher : constant GNAT.Regpat.Pattern_Matcher :=
        GNAT.Regpat.Compile (Next_Tag_Regexp,
                             Flags => GNAT.Regpat.Case_Insensitive
                               or GNAT.Regpat.Single_Line);

      Next_Tag_Max_Parens : constant GNAT.Regpat.Match_Count :=
        GNAT.Regpat.Paren_Count (Next_Tag_Matcher);

      Matches : GNAT.Regpat.Match_Array (0 .. Next_Tag_Max_Parens);

      Start : Positive := S'First;

      Page : EWS_Pages_Support.Compiled_Page;

      use type GNAT.Regpat.Match_Location;

   begin

      loop

         GNAT.Regpat.Match (Next_Tag_Matcher, S, Matches, Data_First => Start);

         if Matches (0) = GNAT.Regpat.No_Match then
            EWS_Pages_Support.Add_Text (S (Start .. S'Last), To => Page);
            EWS_Pages_Support.Output (Page);
            exit;
         end if;

         EWS_Pages_Support.Add_Text (To_String (S, Matches, 1), To => Page);

         declare
            Tag : constant String := To_String (S, Matches, 2);
            End_Regexp : constant String
              := "(.*?)</ews:" & Tag & ">";
            End_Matcher : constant GNAT.Regpat.Pattern_Matcher :=
              GNAT.Regpat.Compile (End_Regexp,
                                   Flags => GNAT.Regpat.Case_Insensitive
                                     or GNAT.Regpat.Single_Line);
            End_Matches : GNAT.Regpat.Match_Array (0 .. 1);
         begin

            GNAT.Regpat.Match
              (End_Matcher,
               S,
               End_Matches,
               Data_First => Matches (0).Last + 1);

            if End_Matches (0) = GNAT.Regpat.No_Match then
               Put_Line ("no closing tag.");
               raise Program_Error;
            else

               if Tag = "code" then
                  EWS_Pages_Support.Add_Code
                    (To_String (S, End_Matches, 1), To => Page);
               elsif Tag = "with" then
                  EWS_Pages_Support.Add_Context
                    (To_String (S, End_Matches, 1), To => Page);
               else
                  raise Constraint_Error;
               end if;
            end if;

            Start := End_Matches (0).Last + 1;

         end;

      end loop;

   end Compile;


   Test_String : constant String
     := Get_Contents ("t.ewp");


begin
   Compile (Test_String);
end EWS_Pages;