unit helper;

interface

uses
  regexpr, classes, SysUtils, IdTCPConnection, IdTCPClient, IdHTTP, IdIOHandler,
  IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL, PNGImage, ExtCtrls;

function AuthVK(Login, Pass: string): string;
{
  Автризация ВКонтакте
  Принимает Логин и Пароль
  Возвращает SessionID или null
}
function QiwiAuth(Login, Password: string): string;
{
  Автризация Qiwi
  Принимает Логин и Пароль
  Возвращает TGT-Ticket или null
}
function QiwiSTTicket(TGTTicket: string): string;
function Pars(T_, ForS, _T: string): string;
{ Обычный парс текста.
  Парсит между указаными строками,
  парсит первый попавшийся текст, а второй последуюший.
  Пример: T_ -- Начало от которого парсить
  ForS -- Текст из которого парсим
  _T -- Конец текста.
  <div>MAIN</div>
  <div>MAIN2</div>
  <div>MAIN3</div>
  <div> -- Является началом
  </div> -- Является концом
  То что мы спарим - MAIN
}
Procedure ParsList(T_, ForS, _T: string; Data: TStringlist; dell: boolean);
{ Парсит лист текста.
  Парсит между указаными строками,
  парсит весь попавшийся текст.
  Пример: T_ -- Начало от которого парсить
  ForS -- Текст из которого парсим
  _T -- Конец текста.
  <div>MAIN</div>
  <div>MAIN2</div>
  <div>MAIN3</div>
  <div> -- Является началом
  </div> -- Является концом
  То что мы спарим:
  MAIN
  MAIN2
  MAIN3
}
function CryptText(text, Password: string; decode: boolean): string;
{
  Шифровка
}

function AuthWM(Login, Password, AnsCaptcha, Cookies: String;
  IMG: TImage): String;

{
  Автризация WebMoney
  Принимает Логин, Пароль, Ответ капчи, куки, изображение
  Возвращает Cookies или Null
  Вызывается 2а раза!
  Первый раз возвращает Cookies, которые нужно будет указать во второй раз:
  Cookies:=AuthWM('','','','',img1)
  Второй раз:
  AuthWM(Login,Password,AnsCaptcha,Cookies,nil)
}
implementation

function Pars(T_, ForS, _T: string): string;
var
  a, b: integer;
begin
  Result := '';
  if (T_ = '') or (ForS = '') or (_T = '') then
    Exit;
  a := Pos(T_, ForS);
  if a = 0 then
    Exit
  else
    a := a + Length(T_);
  ForS := Copy(ForS, a, Length(ForS) - a + 1);
  b := Pos(_T, ForS);
  if b > 0 then
    Result := Copy(ForS, 1, b - 1);
end;

function QiwiAuth(Login, Password: string): string;
var
  http: tidhttp;
  ssl: TIdSSLIOHandlerSocketOpenSSL;
  HTML, Ticket: string;
  Data: TStringStream;
Begin
  http := TIdHTTP.Create(nil);
  ssl := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  Data := TStringStream.Create;
  http.IOHandler := ssl;
  http.HandleRedirects := true;
  http.Request.UserAgent :=
    'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36';
  http.ReadTimeout := 5000;
  http.ConnectTimeout := 5000;
  http.Get('https://qiwi.com/');
  Data.WriteString('{"login":"'+Login+'","password":"'+Password+'"}');
  http.Request.ContentType := 'application/json';
  try
    HTML := http.Post('https://auth.qiwi.com/cas/tgts', Data);
    Ticket := Pars('ticket":"', HTML, '"');
      if Ticket<>'' then   Result:=Ticket else Result:='null';
  except
    Result := 'null';
  end;
  Data.Free;
  ssl.Free;
  http.Free;
End;

function QiwiSTTicket(TGTTicket: string): string;
var
  http: tidhttp;
  ssl: TIdSSLIOHandlerSocketOpenSSL;
  HTML, Ticket: string;
  Data: TStringStream;
Begin
  http := TIdHTTP.Create(nil);
  ssl := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  Data := TStringStream.Create;
  http.IOHandler := ssl;
  http.HandleRedirects := true;
  http.Request.UserAgent :=
    'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36';
  http.ReadTimeout := 5000;
  http.ConnectTimeout := 5000;
  Data.WriteString('{ "service":"http://t.qiwi.com/j_spring_cas_security_check","ticket":"'+TGTTicket+'"}');
  http.Request.ContentType := 'application/json';
  try
    HTML := http.Post('https://auth.qiwi.com/cas/sts', Data);
    Ticket := Pars('ticket":"', HTML, '"');
      if Ticket<>'' then   Result:=Ticket else Result:='null';
  except
    Result := 'null';
  end;
  Data.Free;
  ssl.Free;
  http.Free;
End;

function AuthVK(Login, Pass: string): string;
var
  http: tidhttp;
  ssl: TIdSSLIOHandlerSocketOpenSSL;
  HTML: string;
begin
  http := tidhttp.Create(nil);
  ssl := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  http.Request.UserAgent :=
    'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.95 Safari/537.36 OPR/15.0.1147.153';
  http.IOHandler := ssl;
  try
    HTML := http.Get
      ('https://oauth.vk.com/token?grant_type=password&client_id=2274003&client_secret=hHbZxrka2uZ6jB1inYsH&username='
      + Login + '&password=' + Pass + '&captcha_key=&captcha_sid=');
    if Pos('token', HTML) <> 0 then
    begin
      Result := Pars('{"access_token":"', HTML, '","expires');
    end
    else
      Result := 'null';
  except
    Result := 'null';
  end;
  http.Free;
  ssl.Free;
end;

Procedure ParsList(T_, ForS, _T: string; Data: TStringlist; dell: boolean);
var
  rege: TRegExpr;
Begin
  rege := TRegExpr.Create;
  rege.Expression := (T_ + '(.*?)' + _T);
  if rege.Exec(ForS) then
    repeat
      if dell then
        Data.Add(rege.Match[1])
      else
        Data.Add(rege.Match[0]) until not rege.ExecNext;
      rege.Free;
    End;

  function CryptText(text, Password: string; decode: boolean): string;
  var
    i, PasswordLength: integer;
    sign: integer;
  begin
    try
      begin
        PasswordLength := Length(Password);
        if PasswordLength = 0 then
          Exit;
        if decode then
          sign := -4815
        else
          sign := 4815;
        for i := 1 to Length(text) do
          text[i] := chr(ord(text[i]) + sign *
            ord(Password[i mod PasswordLength + 11]));
      end;
      Result := text;
    except
      on E: Exception do
        Result := 'Error';
    end;
  end;

  function AuthWM(Login, Password, AnsCaptcha, Cookies: String;
    IMG: TImage): String;
  var
    ssl: TIdSSLIOHandlerSocketOpenSSL;
    http: tidhttp;
    HTML, s: string;
    Data: TStringlist;
    Captcha: TMemoryStream;
    PNG: TPNGImage;
  Begin
    http := tidhttp.Create(nil);
    ssl := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    Data := TStringlist.Create;
    http.IOHandler := ssl;
    http.HandleRedirects := true;
    http.Request.UserAgent :=
      'Opera/9.80 (Windows NT 6.1; Win64; x64) Presto/2.12.388 Version/12.17';
    http.ReadTimeout := 5000;
    http.ConnectTimeout := 5000;
    http.Request.CustomHeaders.Add('Origin: https://login.wmtransfer.com');
    if not(Cookies <> '') then
    Begin
      Captcha := TMemoryStream.Create;
      HTML := http.Get('https://www.webmoney.ru/');
      s := Pars('<a href="https://login.wmtransfer.com/GateKeeper.aspx?',
        HTML, '"');
      HTML := http.Get('https://login.wmtransfer.com/GateKeeper.aspx?' + s);
      s := Pars('id="Captcha-image" src="/captcha.ashx?', HTML, '"');
      http.Get('https://login.wmtransfer.com/captcha.ashx?' + s, Captcha);
      PNG := TPNGImage.Create;
      Captcha.Position := 0;
      PNG.LoadFromStream(Captcha);
      IMG.Picture.Bitmap.Assign(PNG);
      PNG.Free;
      Captcha.Free;
      s := Pars('<form action="/GateKeeper/Password/', HTML, '"');
      Result := '<html>' + s + '<html>' + '<cookies>' +
        http.Request.RawHeaders.Values['Cookie'] + '<cookies>';
    End
    Else
    Begin
      s := Pars('<html>', Cookies, '<html>');
      http.Request.CustomHeaders.Add('Cookie:' + Pars('<cookies>',
        Cookies + ';', '<cookies>'));
      Data.Add('Login=' + Login);
      Data.Add('Password=' + Password);
      Data.Add('Captcha=' + AnsCaptcha);
      http.HandleRedirects := true;
      try
        HTML := http.Post('https://login.wmtransfer.com/GateKeeper/Password/'
          + s, Data);
      except
        HTML := http.Get
          ('https://login.wmtransfer.com/GateKeeper/Completed/' + s);
      end;
      if Pos('<dt id="logged-user-name">', HTML) <> 0 then
      Begin
        Data.Clear;
        ParsList('<input type="hidden" name="', HTML, '" />', Data, true);
        Data.text := StringReplace(Data.text, '" value="', '=',
          [rfReplaceAll, rfIgnoreCase]);
        try
          HTML := http.Post
            ('https://mini.webmoney.ru/wm-login.aspx?lang=ru-RU&rnd=', Data);
        except
          http.HandleRedirects := true;
          HTML := http.Get
            ('https://mini.webmoney.ru/wm-login.aspx?lang=ru-RU&rnd=');
        end;
        s := Copy(http.Request.RawHeaders.text,
          Pos('Cookie: ', http.Request.RawHeaders.text) + 8,
          Length(http.Request.RawHeaders.text));
        Result := '<cookie>' + http.Request.RawHeaders.Values['Cookie'] + '; ' +
          s + '</cookie>' + '<data>' + Data.text + '</data>';
      End
      else
        Result := 'Null';
    End;
    Data.Free;
    http.Free;
    ssl.Free;
  End;

initialization

end.
