{
MJPEG Decoder Class
Copyright 2006, Steve Blinch
http://code.blitzaffe.com

This script is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This script is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along
with this script; if not, write to the Free Software Foundation, Inc.,
59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

Updated 2013 by Johan van den Heijkant (johan@intrologic.nl)
- upgraded for iOS
}

unit MJPEGDecoderThread;

interface

uses System.Classes, System.SysUtils, IdTCPClient, FMX.Types, System.UITypes, System.DateUtils,
     MJPEGDecoderTypes, IdHashMessageDigest, NetEncoding, IdUri;

Type
   TMJPEGDecoderThread = class(TThread)
   private
      FConnected: Boolean;
      FClient: TIdTCPClient;
      FActive: Boolean;
      FHeaders: TStringList;

      FPath,FUser,FPass:string;
      FBasicAuthString,AuthStr:string;

      FrameTime: TDateTime;
      FrameProc: TStreamProc;
      MessageProc: TMessageProc;
      StateProc: TStateProc;
      function CheckConnected: Boolean;
      procedure HandleConnected(Sender: TObject);
      function IsMixedReplace(CType: String): Boolean;
      procedure SendFrame(Frame: pMStream);
      procedure SendEmptyFrame;
      Function GetConnected: Boolean;
      procedure SendState(State: Integer);
      procedure SendMessage(Error: Boolean; Msg: String);
   public
      constructor Create(FrameProcedure: TStreamProc; StateProcedure: TStateProc; MessageProcedure: TMessageProc);
      destructor Destroy; override;
      procedure Execute; override;
      procedure Connect(URL,User,Pass:String);
      procedure Disconnect;
//      Procedure SetBitmap(Bitmap: TBitmap);
   published
      property Active: Boolean read FActive write FActive;
      Property Connected: Boolean read GetConnected;
   end;

implementation

constructor TMJPEGDecoderThread.Create(FrameProcedure: TStreamProc; StateProcedure: TStateProc; MessageProcedure: TMessageProc);
begin
    FrameProc:=FrameProcedure;
    MessageProc:=MessageProcedure;
    StateProc:=StateProcedure;

    FConnected:=False;
    FActive:=False;
    FHeaders:=TStringList.Create;
    FHeaders.NameValueSeparator:=':';

    FClient:=TIdTCPClient.Create(Nil);
    FClient.OnConnected:=HandleConnected;
    FClient.ConnectTimeout:=10000;
    FClient.ReadTimeout:=5000;

    inherited Create(True);
    FreeOnTerminate:=True;
end;

destructor TMJPEGDecoderThread.Destroy;
begin
//dupa czy to tak?

  FClient:=nil;
  FHeaders:=nil;

  inherited;
end;


procedure TMJPEGDecoderThread.Connect(URL,User,Pass:String);
var IP: String;
    PortNr: Integer;
    uri:TIdUri;
begin
    if not FConnected then
    begin
        uri:=TIdUri.Create(URL);
        FClient.Host:=uri.Host;
        if uri.Port='' then
            FClient.Port:=80
        else
            FClient.Port:=uri.Port.ToInteger;
        if uri.Params<>'' then
            FPath:=uri.Path+uri.Document+'?'+uri.Params
        else
            FPath:=uri.Path+uri.Document;
        FUser:=User;
        FPass:=Pass;
        FBasicAuthString:='';
        if User<>'' then
            FBasicAuthString:=TNetEncoding.Base64.Encode(user+':'+Pass);
        FHeaders.Clear;
        FClient.OnConnected:=HandleConnected;
        uri.Free;
    end;
end;

function TMJPEGDecoderThread.GetConnected: Boolean;
begin
    Result:=FConnected;
end;

procedure TMJPEGDecoderThread.Disconnect;
begin
    SendState(MJPEG_DisConnected);
    FClient.Disconnect;
end;

procedure TMJPEGDecoderThread.SendFrame(Frame: pMStream);
begin
    Synchronize(procedure begin FrameProc(Frame); end);
end;

procedure TMJPEGDecoderThread.SendState(State: Integer);
begin
    Synchronize(procedure begin StateProc(State); end);
end;

procedure TMJPEGDecoderThread.SendMessage(Error: Boolean; Msg: String);
begin
    Synchronize(procedure begin MessageProc(Error, Msg); end);
end;

procedure TMJPEGDecoderThread.SendEmptyFrame;
var JPEG: TMemoryStream;
begin
    JPEG:=TMemoryStream.Create;
    SendFrame(@JPEG);
    JPeg.Free;
end;

procedure TMJPEGDecoderThread.HandleConnected(Sender: TObject);
var
    S: String;
    CType: String;
    sl:TStringList;
    LstrCNonce,LstrResponse:string;
    function ResultString(const S: String): String;
    begin
        Result := '';
        with TIdHashMessageDigest5.Create do
        try
            Result:= AnsiLowerCase(HashStringAsHex(s));
        finally
            Free;
        end;
    end;

    function RemoveQuote(const aStr: string):string;
    begin
        if (Length(aStr) >= 2) and (aStr[1] = '"') and (aStr[Length(aStr)] = '"') then
            Result:=Copy(aStr,2,Length(aStr)-2)
        else
            Result := aStr;
    end;

//  dig:TIdDigestAuthentication;
begin
    SendMessage(False, 'Connected, sending request');
//   FClient.IOHandler.WriteLn('GET http://192.168.0.12/videostream.cgi HTTP/1.1');
//   FClient.IOHandler.WriteLn('GET /stream/video.mjpeg HTTP/1.1');
    FClient.IOHandler.WriteLn('GET '+FPath+' HTTP/1.1');
//   if AuthStr <> '' then FClient.IOHandler.WriteLn('Authorization: Basic '+AuthStr);
    if AuthStr<>'' then
    begin
        FClient.IOHandler.WriteLn(AuthStr);
        AuthStr:='';
       FClient.IOHandler.WriteLn;

       while (true) do
       begin
          S:=FClient.IOHandler.ReadLn();
          if (S='') then break;
       end;
       FClient.IOHandler.WriteLn('GET '+FPath+' HTTP/1.1');
    end;

   FClient.IOHandler.WriteLn;

   sl:=TStringList.Create;
   while (true) do
   begin
      S:=FClient.IOHandler.ReadLn();
      if (S='') then break;
      sl.Add(s);
      FHeaders.Add(S)
   end;

//      if (S='') then break;
      if pos('401',sl.Strings[0])>1 then
      begin
        s:=trim(copy(sl.Strings[1],25,1024));
        sl.Text:=StringReplace(s,', ',#13#10,[rfReplaceAll]);
        sl.Insert(0,'username="'+FUser+'"');
        sl.Add('uri="'+FPath+'"');
        LstrCNonce:=ResultString(DateTimeToStr(Now));
        sl.Add('cnonce="'+LstrCNonce+'"');
        sl.Add('nc=00000001');
        LstrResponse:=ResultString(ResultString(FUser+':'+RemoveQuote(sl.Values['realm'])+':'+FPass)+':'+RemoveQuote(sl.Values['nonce'])+':00000001:'+LstrCNonce+':auth:'+ResultString('GET:'+FPath));
        sl.Add('response="'+LstrResponse+'"');
        s:='Authorization: Digest '+stringreplace(sl.Text,#13#10,',',[rfReplaceAll]);
        Delete(s,length(s),1);
        sl.Clear;
        AuthStr:=s;
        sl.Free;
        exit;
      end;

   sl.Free;

   CType:=FHeaders.Values['Content-Type'];

//   if (IsMixedReplace(CType)) then
   if (CType<>'') then
   begin
      FConnected:=True;
      FrameTime:=Time;
      SendState(MJPEG_Connected);
      SendMessage(False, 'Request sent, spawning decoder thread');
   end
   else
   begin
      SendMessage(True, 'MJPEG-Decoder Invalid content type received from server: '+CType);
      SendMessage(True, FHeaders.Text);
      FClient.Disconnect;
   end;
end;


function TMJPEGDecoderThread.IsMixedReplace(CType: String): Boolean;
var p: Integer;
begin
   CType:=Trim(Ctype);
   p:=Pos(';',CType);
   if (p>0) then SetLength(CType,p-1);

   Result:=(CType='multipart/x-mixed-replace');
end;

function TMJPEGDecoderThread.CheckConnected: Boolean;
begin
   try
      if not FClient.Connected then
      begin
          FClient.Disconnect;
          FClient.Connect;
      end;
      Result:=FClient.Connected;
   except
      Result:=False;
   end;
end;

procedure TMJPEGDecoderThread.Execute;
var
  S: String;
  CLength: Integer;
  JPEG: TMemoryStream;
begin
   FActive:=True;
   JPEG:=TMemoryStream.Create;
   try
      CLength:=0;
      while (FActive) do
      begin
         try
            if CheckConnected then
            begin
               // grab a header
               try
                  S:=Trim(LowerCase(FClient.IOHandler.ReadLn));

                  // if it's a content-length line, record the content length
                  if (Copy(S,1,15)='content-length:') then
                  begin
                     Delete(S,1,15);
                     S:=Trim(S);
                     CLength:=StrToIntDef(S,0);
                  end;
               except
                  SendMessage(True, 'MJPEG-Decoder header exception');
               end;

               // if it's a blank line and we have a content-length, then we're good to receive the stream
               if (Length(S)=0) and (CLength>0) then
               begin
                  try
                     JPEG:=TMemoryStream.Create;
//                     JPEG.SetSize(CLength);
                     FClient.IOHandler.ReadStream(JPEG, CLength);
                     SendFrame(@JPEG);
                     JPEG.Free;
                     CLength:=0;
                     FrameTime:=Time;
                     if not FConnected then SendState(MJPEG_Connected);
                     FConnected:=True;
                  Except
                     SendMessage(True, 'MJPEG-Decoder bad frame exception');
                  end;
               end
               else
               begin
                  if FConnected and (SecondSpan(Time, FrameTime)>2) then
                  begin
                     FConnected:=False;
                     SendEmptyFrame;
                     SendState(MJPEG_TimeOut);
                     SendMessage(True, 'MJPEG-Decoder frame timeout');
                  end;
               end;
            end;
         except
            SendMessage(True, 'MJPEG-Decoder thread exception');
            Break;
         end;
      end;

   finally
      SendEmptyFrame;
      Disconnect;
      FActive:=False;
      FConnected:=False;
      Terminate;
   end;
end;

end.
