unit MJPEGDecoderTypes;
interface
Uses System.Classes;

Type
   pMStream = ^TMemoryStream;
   TStreamProc = Procedure (Stream: pMStream) of object;
   TMessageProc = Procedure (Error: Boolean; Msg: String) of object;
   TStateProc = Procedure (State: Integer) of object;

const
   MJPEG_DisConnected = 0;
   MJPEG_Connected    = 1;
   MJPEG_TimeOut      = 2;

implementation

end.
