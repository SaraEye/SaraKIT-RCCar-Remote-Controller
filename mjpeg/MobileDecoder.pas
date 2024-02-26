unit MobileDecoder;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs, IdCoderMIME,
  FMX.StdCtrls, FMX.Objects, FMX.Layouts, FMX.Memo, FMX.Surfaces,
  MJPEGDecoderUnit, MJPEGDecoderTypes;

type
  TFMobileDecoder = class(TForm)
    Image1: TImage;
    BConnect: TButton;
    BDisconnect: TButton;
    Rectangle1: TRectangle;
    Memo1: TMemo;
    Layout1: TLayout;
    FlowLayout1: TFlowLayout;
    Layout2: TLayout;
    procedure BConnectClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BDisconnectClick(Sender: TObject);
  private
    procedure HandleFrame(Sender: TObject; Frame: pMStream);
    procedure HandleDisconnected(Sender: TObject);
    procedure HandleConnected(Sender: TObject);
    procedure HandleError(Sender: TObject; Error: String);
    procedure HandleMessage(Sender: TObject; Msg: String);
    procedure HandleTimeOut(Sender: TObject);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FMobileDecoder: TFMobileDecoder;
  MJPEGDecoder: TMJPEGDecoder;

implementation
{$R *.fmx}

var
   URL: String='http://192.168.1.90:8082/mjpg/video.mjpg?resolution=640x480&fps=10';
   User: String='';
   Pw: String='';

procedure TFMobileDecoder.HandleFrame(Sender: TObject; Frame: pMStream);
begin
   Image1.Bitmap.LoadFromStream(Frame^);
end;

procedure TFMobileDecoder.HandleConnected(Sender: TObject);
begin
   Memo1.Lines.Add('Connected to '+URL);
end;

procedure TFMobileDecoder.HandleTimeOut(Sender: TObject);
begin
   Memo1.Lines.Add('Frame Timeout');
end;

procedure TFMobileDecoder.HandleDisconnected(Sender: TObject);
begin
   Memo1.Lines.Add('Disconnected');
end;

procedure TFMobileDecoder.HandleError(Sender: TObject; Error: String);
begin
   Memo1.Lines.Add('Error: '+Error);
end;

procedure TFMobileDecoder.HandleMessage(Sender: TObject; Msg: String);
begin
   Memo1.Lines.Add('Info: '+Msg);
end;

// called when an error occurs; Error contains the error message
procedure TFMobileDecoder.FormCreate(Sender: TObject);
begin
   MJPEGDecoder:=TMJPEGDecoder.Create();
   MJPEGDecoder.OnFrame:=HandleFrame;
   MJPEGDecoder.OnDisconnected:=HandleDisconnected;
   MJPEGDecoder.OnConnected:=HandleConnected;
   MJPEGDecoder.OnTimeOut:=HandleTimeOut;
   MJPEGDecoder.OnError:=HandleError;
   MJPEGDecoder.OnMessage:=HandleMessage;
end;

procedure TFMobileDecoder.FormDestroy(Sender: TObject);
begin
   MJPEGDecoder.Free;
end;

procedure TFMobileDecoder.BConnectClick(Sender: TObject);
var
  AuthStr : String;
  Enc : TIdEncoderMIME;
begin
   Enc := TIdEncoderMIME.Create(nil);
   AuthStr := Enc.Encode(User + ':' + pw);
   Enc.Free;

   // put your own IP address, port number, and stream URI here
   MJPEGDecoder.Connect(URL, AuthStr);
end;

procedure TFMobileDecoder.BDisconnectClick(Sender: TObject);
begin
   MJPEGDecoder.Disconnect;
end;


end.
