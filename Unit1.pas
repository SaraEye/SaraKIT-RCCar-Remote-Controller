unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Objects, FMX.StdCtrls, FMX.Colors, FMX.Edit, FMX.Controls.Presentation,
  MJPEGDecoderUnit, MJPEGDecoderTypes, System.Net.Socket, IniFiles, System.IOUtils, FMX.Layouts,
{$IFDEF ANDROID}
  Androidapi.JNIBridge,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.Os,
  Androidapi.JNI.JavaTypes,
  Androidapi.Helpers,
  FMX.Platform.Android,
{$ENDIF}
  Unit2;


type
  PackRec=packed record
    mode:integer;
    X:integer;
    Y:integer;
    data:integer;
    r:integer;
    g:integer;
    b:integer;
    bool:Boolean;
  end;

  TRCSocket = class(TObject)
    private
        FClientSocket: TSocket;
        Connected : Boolean;
        ip:string;
        port:word;
    protected
        procedure Connect;
    public
        constructor Create;
        destructor Destroy;
        procedure Send(data : PackRec; len : Integer);
  end;

  TfrmMain = class(TForm)
    TimerMove: TTimer;
    lPos: TLine;
    Line2: TLine;
    lPos2: TLine;
    Line3: TLine;
    btnSetup: TButton;
    FrameSetup: TFrameSetup;
    Circle1: TCircle;
    StyleBook1: TStyleBook;
    Circle2: TCircle;
    ImageBackground1: TImage;
    ImageCam: TImage;
    chkCamera: TCheckBox;
    LayoutCam: TLayout;
    LayoutV: TLayout;
    LayoutH: TLayout;
    btnA: TButton;
    btnB: TButton;
    btnC: TButton;
    lVertical: TLabel;
    lHorizontal: TLabel;
    ImageBackground2: TImage;
    btnMode: TButton;
    procedure FormDestroy(Sender: TObject);
    procedure HandleFrame(Sender: TObject; Frame: pMStream);
    procedure btnConnectClick(Sender: TObject);
    procedure TimerMoveTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnSetupClick(Sender: TObject);
    procedure FormTouch(Sender: TObject; const Touches: TTouches;
      const Action: TTouchAction);
    procedure FrameSetupbtnConnectClick(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure SaveParam;
    procedure FrameSetupbtnCloseClick(Sender: TObject);
    procedure LayoutVMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure LayoutVMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure LayoutVMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure LayoutHMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure LayoutHMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure LayoutHMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure btnModeClick(Sender: TObject);
    procedure chkCameraChange(Sender: TObject);
    procedure btnClick(Sender: TObject);
    procedure FrameSetupColorPicker1Tap(Sender: TObject; const Point: TPointF);
    procedure FrameSetupColorPicker1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FrameSetupColorPicker1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Send(Data : PackRec; Len : Integer);
  end;

var
  frmMain: TfrmMain;
  MJPEGDecoder: TMJPEGDecoder;
  mc:PackRec; //1 - send mouse/touch pos, 2 - send buttons, 3 - led color
  bdata:PackRec;
  mlButton:boolean=false;
  mrButton:boolean=false;
  mButtonP:TPoint;
  mlButton2:boolean=false;
  mrButton2:boolean=false;
  mButtonP2:TPoint;
  RCSocket:TRCSocket;
  LayoutCamHeight:single;

implementation

type
  THackControl = type TControl;

{$R *.fmx}

{$IFDEF ANDROID}
function GetStatusBarHeight: Integer;
var
  Resources: JResources;
  ResourceId: Integer;
begin
  Resources := TAndroidHelper.Context.getResources;
  ResourceId := Resources.getIdentifier(StringToJString('status_bar_height'), StringToJString('dimen'), StringToJString('android'));
  if ResourceId > 0 then
    Result := Resources.getDimensionPixelSize(ResourceId)
  else
    Result := 0; // Default fallback if resource not found
end;
{$ENDIF}

procedure TfrmMain.FormTouch(Sender: TObject; const Touches: TTouches; const Action: TTouchAction);
var
  I: Integer;
  LabelTouch: TLabel;
  x,y : Integer;
  p1,p2 : boolean;
  sth: integer;
begin
    if (FrameSetup.Visible) then
        exit;

    sth:=0;
{$IFDEF ANDROID}
    sth:=GetStatusBarHeight;
{$ENDIF}
    p1:=false;
    p2:=false;
    for I := Low(Touches) to High(Touches) do
    begin
        x:=trunc(Touches[I].Location.X);
        y:=trunc(Touches[I].Location.Y);
        if (ObjectAtPoint(Touches[I].Location)<>nil) then
        begin
            if (PtInRect(LayoutH.BoundsRect,Touches[I].Location)) then
            begin
                p1:=true;
                LayoutHMouseMove(nil,[],x-LayoutH.BoundsRect.Left,y-LayoutH.BoundsRect.Top);
            end;

            if (PtInRect(LayoutV.BoundsRect,Touches[I].Location)) then
            begin
                if (btnMode.Tag<>0) then
                    p1:=true;
                p2:=true;
                LayoutVMouseMove(nil,[],x-LayoutV.BoundsRect.Left,y-LayoutV.BoundsRect.Top);
            end;
        end;
    end;
    if (p1=False) then
        LayoutHMouseUp(nil,TMouseButton.mbLeft,[],0,0);
    if (p2=False) then
        LayoutVMouseUp(nil,TMouseButton.mbLeft,[],0,0);
end;


procedure TfrmMain.FrameSetupbtnConnectClick(Sender: TObject);
begin
    SaveParam;
    btnConnectClick(Sender);
end;

procedure TfrmMain.FrameSetupColorPicker1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
    FrameSetupColorPicker1Tap(Sender,PointF(0,0));
end;

procedure TfrmMain.FrameSetupColorPicker1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
    FrameSetupColorPicker1Tap(Sender,PointF(0,0));
end;

procedure TfrmMain.FrameSetupColorPicker1Tap(Sender: TObject; const Point: TPointF);
var r,g,b:integer;
begin
    If FrameSetup.Visible=false then
        exit;
    r:=TAlphaColorRec(FrameSetup.ColorPicker1.Color).r;
    g:=TAlphaColorRec(FrameSetup.ColorPicker1.Color).g;
    b:=TAlphaColorRec(FrameSetup.ColorPicker1.Color).b;

    mc.mode:=3;
    mc.r:=r;
    mc.g:=g;
    mc.b:=b;
    bdata:=mc;
    FrameSetup.lRGB.Text:=Format('RGB: %3d %3d %3d',[r,g,b]);
    TimerMove.Enabled:=true;
end;

procedure TfrmMain.FrameSetupbtnCloseClick(Sender: TObject);
begin
    SaveParam;
    FrameSetup.btnCloseClick(Sender);
end;

procedure TfrmMain.Send(data : PackRec; Len : Integer);
begin
    if RCSocket<>nil then
        RCSocket.Send(data,sizeof(mc));
end;

procedure TfrmMain.HandleFrame(Sender: TObject; Frame: pMStream);
var
    bmp:TBitmap;
begin
    try
        ImageCam.BeginUpdate;
        bmp:=TBitmap.Create;
        bmp.LoadFromStream(Frame^);
        //bmp.FlipVertical;
        ImageCam.Bitmap.SetSize(bmp.Width div 2, bmp.Height);
        ImageCam.Bitmap.CopyFromBitmap(bmp,Rect(0,0, bmp.Width div 2, bmp.Height),0,0);
        //Image2.Bitmap.CopyFromBitmap(bmp,Rect(bmp.Width div 2,0,bmp.Width div 2,bmp.Height),0,0);
        ImageCam.EndUpdate;
        FreeAndNil(bmp);
    except
    end;
end;

procedure TfrmMain.LayoutHMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
    if Button=TMouseButton.mbLeft then
    begin
        mlButton:=true;
        LayoutHMouseMove(nil,[ssLeft],X,Y);
    end;
end;

procedure TfrmMain.LayoutHMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  mx,my,sp:integer;
  w:real;
begin
  {$IFNDEF MSWINDOWS}
  mlButton:=true;
  {$ENDIF}

  if (mlButton) then
  begin
    //set cursor
    lPos.Position.X:=x-(lPos.Width / 2);
    lPos.Position.Y:=y-(lPos.Height /2);

    //x=-100 to 100; y=-100 to 100
    mc.mode:=1;
    mc.Y:=bdata.Y;
    w:=LayoutH.Width*0.7;
    X:=X-(LayoutH.Width*0.3)/2;
    mc.X:=trunc(100*(X-(w / 2 ))/(w/2));
    mc.X:=mc.X+trunc(FrameSetup.TrackBarSteering.Value);
    if (mc.X>100)  then mc.X:=100;
    if (mc.X<-100) then mc.X:=-100;
    if (FrameSetup.cReverseH.IsChecked) then mc.X:=-mc.X;

    bdata:=mc;
    lHorizontal.Text:=Format('H:%3d',[mc.X]);
    TimerMove.Enabled:=true;
  end;
end;

procedure TfrmMain.LayoutHMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
    mrButton:=false;
    mlButton:=false;
    lPos.Position.X:=LayoutH.Width/2-(lPos.Width / 2);
    lPos.Position.Y:=LayoutH.Height/2-(lPos.Height /2);
    mc.mode:=1;
    mc.X:=trunc(FrameSetup.TrackBarSteering.Value);
    mc.Y:=bdata.Y;
    bdata:=mc;
    lHorizontal.Text:=Format('H:%3d',[mc.X]);
    send(mc,sizeof(mc));
end;

procedure TfrmMain.LayoutVMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
    if Button=TMouseButton.mbLeft then
    begin
        mlButton2:=true;
        LayoutVMouseMove(nil,[ssLeft],X,Y);
    end;
end;

procedure TfrmMain.LayoutVMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  mx,my,sp:integer;
  h,w: real;
begin
  {$IFNDEF MSWINDOWS}
  mlButton2:=true;
  {$ENDIF}

  if (mlButton2) then
  begin
    //set cursor
    lPos2.Position.X:=x-(lPos2.Width / 2);
    lPos2.Position.Y:=y-(lPos2.Height /2);

    //x=-100 to 100; y=-100 to 100
    mc.mode:=1;
    mc.X:=bdata.X;

    if (btnMode.Tag<>0) then
    begin
        w:=LayoutV.Width*0.6;
        X:=X-(LayoutV.Width*0.4)/2;
        mc.X:=trunc(100*(X-(w / 2 ))/(w/2));
        mc.X:=mc.X+trunc(FrameSetup.TrackBarSteering.Value);
        if (mc.X>100)  then mc.X:=100;
        if (mc.X<-100) then mc.X:=-100;
        if (FrameSetup.cReverseH.IsChecked) then mc.X:=-mc.X;
        lHorizontal.Text:=Format('H:%3d',[mc.X]);
    end;

    h:=LayoutV.Height*0.7;
    Y:=Y-(LayoutV.Height*0.3)/2;
    mc.Y:=-trunc(100*(Y-(h / 2 ))/(h/2));
    if (mc.Y>100)  then mc.Y:=100;
    if (mc.Y<-100) then mc.Y:=-100;
    if (FrameSetup.cReverseV.IsChecked) then mc.Y:=-mc.Y;

    bdata:=mc;
    lVertical.Text:=Format('V:%3d',[mc.Y]);
    TimerMove.Enabled:=true;
  end;
end;

procedure TfrmMain.LayoutVMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
    mrButton2:=false;
    mlButton2:=false;
    lPos2.Position.X:=LayoutV.Width/2-(lPos2.Width / 2);
    lPos2.Position.Y:=LayoutV.Height/2-(lPos2.Height /2);
    mc.mode:=1;
    mc.X:=bdata.X;
    if (btnMode.Tag<>0) then mc.X:=0;
    mc.Y:=0;
    bdata:=mc;
    lVertical.Text:=Format('V:%3d',[mc.Y]);
    send(mc,sizeof(mc));
end;

procedure TfrmMain.TimerMoveTimer(Sender: TObject);
begin
  TimerMove.Enabled:=false;
  send(bdata,sizeof(mc));
end;

procedure TfrmMain.btnClick(Sender: TObject);
begin
    TimerMove.Enabled:=false;
    sleep(20);
    mc.mode:=2;
    mc.data:=TButton(sender).Tag;
    send(mc,sizeof(mc));
    TimerMove.Enabled:=True;
end;

procedure TfrmMain.btnConnectClick(Sender: TObject);
begin
    if RCSocket=nil then
        RCSocket:=TRCSocket.Create;
    RCSocket.ip:=FrameSetup.eIP.Text;
    FrameSetup.Visible:=false;
end;

procedure TfrmMain.btnModeClick(Sender: TObject);
begin
    if LayoutCamHeight=0 then
        LayoutCamHeight:=LayoutCam.Height;
    btnMode.Tag:=not btnMode.Tag;
    if (btnMode.Tag=0) then
    begin
        btnMode.Text:='Two Finger';
        ImageBackground2.Visible:=false;
        LayoutH.Visible:=true;
        Line3.Visible:=true;
        LayoutCam.Height:=LayoutCamHeight;
    end
    else
    begin
        btnMode.Text:='One Finger';
        ImageBackground2.Visible:=true;
        LayoutH.Visible:=false;
        Line3.Visible:=false;
        LayoutCam.Height:=LayoutH.Height+LayoutCamHeight;
    end;
end;

procedure TfrmMain.btnSetupClick(Sender: TObject);
begin
    FrameSetup.visible:=true;
end;

procedure TfrmMain.chkCameraChange(Sender: TObject);
begin
    ImageCam.Visible:=chkCamera.IsChecked;

    if chkCamera.IsChecked then
    begin
        MJPEGDecoder:=TMJPEGDecoder.Create();
        MJPEGDecoder.OnFrame:=HandleFrame;
    //    MJPEGDecoder.OnMessage:=HandleMessage;
        MJPEGDecoder.Connect('http://'+FrameSetup.eIp.Text+':7777','','');
    end
    else
    begin
        if MJPEGDecoder<>nil then
        begin
            MJPEGDecoder.OnFrame:=nil;
            MJPEGDecoder.Disconnect;
        end;
        MJPEGDecoder:=nil;
    end;

end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
    Ini:TMemIniFile;
    FilePath: string;
begin
{$IFDEF ANDROID}
    LayoutH.OnMouseMove:=nil;
    LayoutV.OnMouseMove:=nil;
{$ENDIF}
    FilePath := TPath.Combine(TPath.GetDocumentsPath, 'RemoteEye.ini');
    Ini:=TMemIniFile.Create(FilePath,TEncoding.UTF8);
    FrameSetup.eIP.Text:=ini.ReadString('setup','ip','192.168.1.244');
    FrameSetup.cReverseV.IsChecked:=ini.ReadBool('setup','reverseV',false);
    FrameSetup.cReverseH.IsChecked:=ini.ReadBool('setup','reverseH',false);
    chkCamera.IsChecked:=Ini.ReadBool('setup', 'camera',false);
    ini.Free;
    FrameSetup.Visible:=true;
end;

procedure TfrmMain.SaveParam;
var
  Ini: TMemIniFile;
  FilePath: string;
begin
  FilePath := TPath.Combine(TPath.GetDocumentsPath, 'RemoteEye.ini');
  Ini := TMemIniFile.Create(FilePath, TEncoding.UTF8);
  try
    Ini.WriteString('setup', 'ip', FrameSetup.eIP.Text);
    Ini.WriteBool('setup', 'reverseV', FrameSetup.cReverseV.IsChecked);
    Ini.WriteBool('setup', 'reverseH', FrameSetup.cReverseH.IsChecked);
    Ini.WriteBool('setup', 'camera', chkCamera.IsChecked);
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
    if MJPEGDecoder<>nil then
    begin
        MJPEGDecoder.OnFrame:=nil;
        MJPEGDecoder.Disconnect;
    end;
end;

procedure TfrmMain.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
    LayoutHMouseUp(nil,TMouseButton.mbLeft,[ssLeft],0,0);
    LayoutVMouseUp(nil,TMouseButton.mbLeft,[ssLeft],0,0);
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
    LayoutHMouseUp(nil,TMouseButton.mbLeft,[ssLeft],0,0);
    LayoutVMouseUp(nil,TMouseButton.mbLeft,[ssLeft],0,0);
end;

procedure TRCSocket.Connect;
begin
    FClientSocket.Connect(string.Empty, ip+#0, string.Empty, port);
    Connected := True;
end;

constructor TRCSocket.Create;
begin
    inherited Create();
    ip:='192.168.1.152';
    port:=9001;
    FClientSocket := TSocket.Create(TSocketType.TCP);
end;

destructor TRCSocket.Destroy;
begin
    inherited Destroy();
    FClientSocket := nil;
end;

procedure TRCSocket.Send(data : PackRec; len : Integer);
begin
    If Connected=false then Connect();
    FClientSocket.Send(data,len);
end;

end.

