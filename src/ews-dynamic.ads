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

--  As a special exception, if other files instantiate generics from
--  this unit, or you link this unit with other files to produce an
--  executable, this unit does not by itself cause the resulting
--  executable to be covered by the GNU General Public License.  This
--  exception does not however invalidate any other reasons why the
--  executable file might be covered by the GNU Public License.

--  $RCSfile$
--  $Revision$
--  $Date$
--  $Author$

with Ada.Strings.Unbounded;
with EWS.HTTP;
with EWS.Types;
with GNAT.Sockets;

package EWS.Dynamic is

   pragma Elaborate_Body;

   function Find
     (For_Request : access HTTP.Request) return HTTP.Response'Class;

   type Dynamic_Response (R : HTTP.Request_P)
      is new HTTP.Response with  private;

   type Creator
      is access function (From_Request : HTTP.Request_P)
                         return Dynamic_Response'Class;

   --  The server will call the given Creator when the given URL is
   --  requested.
   --  in "http://foo.com:1234/bar", for example, the URL is "/bar".
   procedure Register (The_Creator : Creator; For_The_URL : HTTP.URL);

   --  Operations callable by Creator functions.
   procedure Set_Content_Type (This : in out Dynamic_Response;
                               To : Types.Format);
   procedure Set_Content (This : in out Dynamic_Response;
                          To : String);
   procedure Append (This : in out Dynamic_Response;
                     Adding : String);

private

   type Dynamic_Response (R : HTTP.Request_P)
   is new HTTP.Response (R) with record
      Form : Types.Format := Types.Plain;
      Content : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   function Content_Type (This : Dynamic_Response) return String;
   function Content_Length (This : Dynamic_Response) return Integer;
   procedure Write_Content (This : Dynamic_Response;
                            To : GNAT.Sockets.Socket_Type);

end EWS.Dynamic;
