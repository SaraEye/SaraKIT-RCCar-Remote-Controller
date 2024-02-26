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

Updated 2012 by Soitjes (soitjes@gmail.com)
- upgraded to Indy 10
- added authentication

Updated 2013 by Johan van den Heijkant (johan@intrologic.nl)
- upgraded for iOS
}

unit MJPEGDecoderUnit;
interface
uses System.Classes, System.SysUtils, IdTCPClient, FMX.Types, System.UITypes, System.DateUtils,
     MJPEGDecoderThread, MJPEGDecoderTypes;

Type
   TMJPEGFrameEvent = procedure(Sender: TObject; Frame: pMStream) of object;
   TMJPEGMessageEvent = procedure(Sender: TObject; Msg: String) of object;
   TMJPEGDecoder = class(TObject)
   private
      FOnFrame: TMJPEGFrameEvent;
      FOnConnected: TNotifyEvent;
      FOnDisconnected: TNotifyEvent;
      FOnTimeOut: TNotifyEvent;

      FOnError: TMJPEGMessageEvent;
      FOnMessage: TMJPEGMessageEvent;
      FConnected: Boolean;
      FURL: String;
      FUser,FPass:string;

      Thread: TMJPEGDecoderThread;
      ConnectTimer: TTimer;
      Connecting: Boolean;
      procedure ConnectTimerTimer(Sender: TObject);
      procedure Reconnect;
      procedure ProcessNewFrame(Frame: pMStream);
      procedure ThreadOnTerminate(Sender: TObject);
      procedure ProcessState(State: Integer);
      procedure ProcessMessage(Error: Boolean; Msg: String);
   public
      constructor Create();
      destructor Destroy; override;
      procedure Connect(URL,User,Pass : String);

      procedure Disconnect;
   published
      // called when a frame is received; you MUST dispose of the frame yourself!
      property OnFrame: TMJPEGFrameEvent read FOnFrame write FOnFrame;

      // called when MJPEGDecoder connects to an MJPEG source
      property OnConnected: TNotifyEvent read FOnConnected write FOnConnected;

      // called when MJPEGDecoder disconnects
      property OnDisconnected: TNotifyEvent read FOnDisconnected write FOnDisconnected;

      // called when MJPEGDecoder connects to an MJPEG source
      property OnTimeOut: TNotifyEvent read FOnTimeOut write FOnTimeOut;

      // called when an error occurs
      property OnError: TMJPEGMessageEvent read FOnError write FOnError;

      // called when a debug message is generated
      property OnMessage: TMJPEGMessageEvent read FOnMessage write FOnMessage;

   end;

implementation

constructor TMJPEGDecoder.Create();
begin
   inherited Create;
   Thread:=nil;
   FConnected:=False;
   Connecting:=False;
   ConnectTimer:=TTimer.Create(Nil);
   ConnectTimer.OnTimer:=ConnectTimerTimer;
   ConnectTimer.Enabled:=False;
   ConnectTimer.Interval:=1000;
end;

destructor TMJPEGDecoder.Destroy;
begin
   try
      inherited;
   Except

   end;

   Thread.Active:=false;
   ConnectTimer.Enabled:=false;
   Thread.Terminate;
   sleep(50);
end;

Procedure TMJPEGDecoder.ThreadOnTerminate(Sender: TObject);
begin
   Thread:=Nil;
   FConnected:=False;
end;

procedure TMJPEGDecoder.ProcessNewFrame(Frame: pMStream);
begin
   if Assigned(FOnFrame) then FOnFrame(Self, Frame);
end;

procedure TMJPEGDecoder.ProcessMessage(Error: Boolean; Msg: String);
begin
   if (not Error) and Assigned(FOnMessage) then FOnMessage(Self, Msg);
   if (Error) and Assigned(FOnError) then FOnError(Self, Msg);
end;

procedure TMJPEGDecoder.ProcessState(State: Integer);
begin
   case State of
      MJPEG_DisConnected: if Assigned(FOnDisConnected) then FOnDisConnected(Self);
      MJPEG_Connected   : if Assigned(FOnConnected) then FOnConnected(Self);
      MJPEG_TimeOut     : if Assigned(FOnTimeOut) then FOnTimeOut(Self);
   end;
end;

procedure TMJPEGDecoder.Reconnect;
begin
   if (not Assigned(Thread)) or (Thread.Finished) then
   begin
      Thread:=TMJPEGDecoderThread.Create(ProcessNewFrame, ProcessState, ProcessMessage);
      Thread.Connect(FURL,FUser,FPass);
      Thread.OnTerminate:=ThreadOnTerminate;
      Thread.Resume;
      Connecting:=False;
   end
   else
   begin
      Thread.Active:=False;
      Connecting:=True;
      ConnectTimer.Enabled:=True;
   end;

end;

procedure TMJPEGDecoder.Connect(URL,User,Pass : String);
var
    s:string;
begin
   FURL:=URL;
   FUser:=User;
   FPass:=Pass;
   Reconnect;
end;

procedure TMJPEGDecoder.ConnectTimerTimer(Sender: TObject);
begin
   If Connecting then Reconnect else ConnectTimer.Enabled:=False;
end;

procedure TMJPEGDecoder.Disconnect;
begin
  if (Assigned(Thread)) then Thread.Active:=False;
  Connecting:=False;
end;


end.
