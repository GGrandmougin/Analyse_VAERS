program Analyse_VAERS;

uses
  Forms,
  Analyse_VAERS_1 in 'Analyse_VAERS_1.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
