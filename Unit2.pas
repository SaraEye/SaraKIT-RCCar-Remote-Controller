unit Unit2;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation, FMX.Colors, FMX.Objects, FMX.Layouts;

type
  TFrameSetup = class(TFrame)
    ColorPicker1: TColorPicker;
    lRGB: TLabel;
    Label1: TLabel;
    eIP: TEdit;
    btnConnect: TButton;
    Rectangle1: TRectangle;
    btnClose: TButton;
    cReverseV: TCheckBox;
    cReverseH: TCheckBox;
    TrackBarSteering: TTrackBar;
    Label2: TLabel;
    Layout1: TLayout;
    procedure btnCloseClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

procedure TFrameSetup.btnCloseClick(Sender: TObject);
begin
    Visible:=false;
end;

end.
