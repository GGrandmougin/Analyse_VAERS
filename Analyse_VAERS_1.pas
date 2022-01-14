unit Analyse_VAERS_1;

interface
{
- parcourr llots pour concatener lots avec vraissemblement même N°
- fab  fab1 nbfab1 fab2 nbfab2  fab3 nbfab3   mettre dans fab le majoritaire
- faire tlot.incrémente dès le remplissage de ldata
- lors du remplissage de ldata, voir lvax avec même ID
}
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, StrUtils;

const
    fic_data = 'VAERSDATA.CSV';
    fic_vax = 'VAERSVAX.CSV';
    rep_fic = 'VAERS\';
type
  tch_datas = (VAERS_ID,RECVDATE,STATE,AGE_YRS,CAGE_YR,CAGE_MO,SEX,RPT_DATE,SYMPTOM_TEXT,DIED,DATEDIED,L_THREAT,ER_VISIT,HOSPITAL,HOSPDAYS,X_STAY,DISABLE,RECOVD,VAX_DATE,ONSET_DATE,NUMDAYS,LAB_DATA,V_ADMINBY,V_FUNDBY,OTHER_MEDS,CUR_ILL,HISTORY,PRIOR_VAX,SPLTTYPE,FORM_VERS,TODAYS_DATE,BIRTH_DEFECT,OFC_VISIT,ER_ED_VISIT,ALLERGIES);
  tsel_ch_dt = set of tch_datas;


  tlot = class
     nbmorts, nbgraves, nbinvalides, nbeffets : integer;
     numlot : string;
     date : tdatetime;
     fab : string;
     procedure incremente( l_data : tstringlist);
     constructor create(nlot, fabriquant : string); overload;
     destructor destroy_;  overload;
  end;
  TForm1 = class(TForm)
    Memo1: TMemo;
    BDemarrer: TButton;
    Erep_src: TEdit;
    Lrep_src: TLabel;
    Cbannee: TComboBox;
    procedure cree_sortie;
    function lit_lgn_vax(idx : integer): tstringlist;
    function lit_lgn_data(idx : integer): tstringlist;
    procedure affiche(str : string);
    procedure aj_1_ligne ;
    procedure lit_datas;
    procedure lit_vaxs;
    function lit_fic(fic : string): boolean;
    function changedate(date_en : string) : string;
    function getversion: String;
    procedure enregistre(fichier : string);
    procedure str2strlist( txt : string; sl : tstringlist);
    procedure str2stl_glmt(txt: string; sl: tstringlist);
    function strlist2str(sl : tstringlist) : string;
    procedure termine;
    procedure genere_sortie( degre : string);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BDemarrerClick(Sender: TObject);

  private
    { Déclarations privées }
  public
    { Déclarations publiques }
    lentree : tstringlist;
    ldata : tstringlist;
    lvax : tstringlist;  // object tlot dans sl.object[0]
    llots : tstringlist;
    lsortie : tstringlist;
    llgn_entree : tstringlist;
    llgn_sortie : tstringlist;
    slgn_e, slgn_s :string;
    repertoire : string;
    ord_SYMPTOM_TEXT : integer;
  end;

var
  Form1: TForm1;
  precedent : string;
  nbegal : integer = 0;
  nb_incomplets : integer = 0;
  nb_covid_sans_numlot : integer = 0;
  c_dates :  tsel_ch_dt = [RECVDATE,RPT_DATE,VAX_DATE,DATEDIED,TODAYS_DATE];
  date_lim : tdatetime;
  nb_champs : integer;

implementation


{$R *.dfm}

function TForm1.getversion: String;
Var
  fic : string;
  taille    : DWord;
  buffer    : PChar;
  datas : PChar;
  len  : DWord;
Begin
  result:='';
  buffer := nil;
  fic := Application.ExeName;
  taille := GetFileVersionInfoSize(PChar(fic), taille);
  If Taille > 0 then begin
     try
       buffer := AllocMem(taille);
       GetFileVersionInfo(PChar(fic), 0, taille, buffer);
       If VerQueryValue(buffer, PChar('\StringFileInfo\040C04E4\FileVersion'), Pointer(datas), len) then
          result:=datas;
     finally
       if buffer <> nil then
          FreeMem(buffer, taille);
     end;
   end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
    ldata := tstringlist.create;
    lvax := tstringlist.create;
    llots := tstringlist.create;
    llots.Sorted := true;
    lsortie := tstringlist.create;
    lentree := tstringlist.create;
    llgn_entree := tstringlist.create;
    llgn_sortie := tstringlist.create;
    caption := 'Annalyse des données VAERS     V'  + getversion + '    Gérard Grandmougin';
    nb_champs := ord(high(tch_datas)) ;
    ord_SYMPTOM_TEXT := ord(SYMPTOM_TEXT);
end;

procedure TForm1.FormShow(Sender: TObject);
begin
//
end;

procedure TForm1.termine;
procedure videobjets(sl : tstringlist);
var
   i : integer;
begin
   aj_1_ligne ;
   memo1.Refresh;
   for i := sl.count -1 downto 0 do begin
      sl.Objects[i].Free;
      sl.Delete(i);
      if sl.Count mod 10000 = 0 then begin
         memo1.Lines[memo1.lines.count -1 ] := inttostr(sl.count );
         memo1.Refresh;
      end;
   end;
end;
begin
    videobjets(ldata);
    FreeAndNil(ldata);
    affiche('FreeAndNil(ldata)');
    videobjets(lvax);
    FreeAndNil(lvax);
    affiche('FreeAndNil(lvax)');
    videobjets(llots);
    FreeAndNil(llots);
    affiche('FreeAndNil(llots)');
    FreeAndNil(lsortie);
    
    FreeAndNil(lentree);
    
    FreeAndNil(llgn_entree);

    FreeAndNil(llgn_sortie);
    affiche('free: terminé');
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin

    ldata.Free;

    lvax.Free;

    llots.Free;
    lsortie.Free;
    lentree.Free;
    llgn_entree.Free;
    llgn_sortie.Free;
end;


procedure TForm1.str2strlist(txt: string; sl: tstringlist);
begin
   sl.Clear;
   sl.Text := StringReplace(txt, ',' , #13#10 , [rfReplaceAll	] ) ;
end;

procedure TForm1.str2stl_glmt(txt: string; sl: tstringlist);
var
   p : integer;
   texte : string;
function paire_glmt : boolean ;  //paire guillemets
var
   i, j : integer;
   st : string;
begin
   result := true;
   i := posex('"', texte, p + 1);
   if i > 0 then begin
      j := posex('"', texte, i + 1);
      if j > 0 then begin
         st := copy(texte, i + 1 , j - i);
         st := StringReplace(st, ',', ';' , [rfReplaceAll]);
         texte := copy(texte, 1, i) + st + copy(texte, j + 1, length(texte));
         p := j;
         result := false;
      end;
   end;
end;
begin
   p := 0;
   texte := txt + ',';
   repeat
   until paire_glmt ;
   sl.Clear;
   sl.Text := StringReplace(texte, ',' , #13#10 , [rfReplaceAll	] ) ;
end;

function TForm1.strlist2str(sl: tstringlist): string;
begin
   result :=  StringReplace(sl.text , #13#10, ',' , [rfReplaceAll	] ) ;
end;

procedure TForm1.enregistre(fichier : string);
begin
   if lsortie.Count > 1 then begin
      try
         lsortie.SaveToFile(fichier);
      except
         affiche('erreur d''enregistrement du fichier: ' + fichier) ;

      end
   end;
end;

function TForm1.changedate(date_en: string): string;
begin
   if length(trim(date_en)) = 10 then begin
      result := copy(date_en, 4 , 2) + '/' + copy(date_en, 1, 2) + '/' + copy(date_en, 7 , 4 ) ;
   end else result := date_en;
end;

procedure TForm1.BDemarrerClick(Sender: TObject);
begin
   BDemarrer.Enabled := false;
   affiche('Patientez..');
   date_lim := strtodate('31/12/' + cbannee.Text);
   if trim(Erep_src.Text) <>'' then repertoire := trim(Erep_src.Text) else  repertoire := rep_fic;
   if repertoire[length(repertoire)] <> '\' then repertoire := repertoire + '\' ;
   lit_vaxs;
   if (lvax.Count > 0) then lit_datas;
//lsortie.SaveToFile('nb_champs_trouvés.txt');
   if (lvax.Count > 0) and (ldata.Count > 0)  then begin
      cree_sortie;
   end else begin
      affiche('programme non éxécuté complément');
   end;
   termine;
   affiche('terminé') ;
   aj_1_ligne;
end;

procedure TForm1.lit_vaxs;
var
   fic : string;
   i : integer;
   sl : tstringlist;
begin
   lsortie.Clear;
   fic := fic_vax;
   if lit_fic(fic) then begin
      affiche('avancement');
      for i := 1 to lentree.Count -1 do begin
         sl := lit_lgn_vax(i);
         if sl <> nil then begin
            lvax.AddObject( sl.strings[0] , sl); // object tlot dans sl.object[0]
            if lvax.Count mod 1000 = 0 then begin
               memo1.Lines[memo1.lines.count -1 ] := inttostr(lvax.count );
               memo1.Refresh;
            end;
            {if sl.strings[0] = precedent then begin
               inc(nbegal);
               lsortie.add(precedent);
            end;
            precedent := sl.strings[0];}
         end;
      end;
      affiche( inttostr(lvax.Count) + ' enregistrements sélectionnés');
      affiche( inttostr(llots.Count) + ' lots différents');
      {affiche( inttostr(nbegal) + ' id identiques');
      if nbegal > 0 then begin
         //memo1.Lines.AddStrings(lsortie);
         lsortie.SaveToFile('identisues2021.txt');
      end; }
      lvax.Sorted := true;
      affiche('liste triée');
      affiche(inttostr(nb_covid_sans_numlot) + ' nombre d''entrées COVID19 sans numéro de lot');
      if lsortie.Count > 0 then begin
         if lsortie.Count < 20 then begin
            affiche(inttostr(lsortie.Count) + ' lots de fabriquants différent avec numlots identiques');
            memo1.Lines.AddStrings(lsortie);
         end else begin
            fic := repertoire + 'numlots_identiques_' + Cbannee.Text + '.txt';
            affiche(inttostr(lsortie.Count) + ' lots de fabriquants différent avec numlots identiques');
            affiche('liste dans fichier : ' + fic);
            lsortie.SaveToFile(fic);
         end;
      end;
{llots.sorted := false;
for i := 0 to llots.Count - 1 do begin
   llots.Strings[i] := llots.Strings[i] + ',1 ,2,';
end;
llots.SaveToFile(Cbannee.Text + 'listelots.txt');
affiche('liste lots enregistére dans 200Xlistelots.txt');  }
   end;
end;

procedure TForm1.lit_datas;  // pas d'id identiques dans datas 2021
var
   fic : string;
   i : integer;
   sl : tstringlist;
begin
   fic := fic_data;
   if lit_fic(fic) then begin
      affiche('avancement');
      for i := 1 to lentree.Count -1 do begin
         sl := lit_lgn_data(i);
         if sl <> nil then begin
            ldata.AddObject( sl[0] , sl);
            if ldata.Count mod 1000 = 0 then begin
               memo1.Lines[memo1.lines.count -1 ] := inttostr(ldata.count );
               memo1.Refresh;
            end;
         end;
      end;
      affiche( inttostr(ldata.Count) + ' enregistrements sélectionnés');
      aj_1_ligne;
   end;
end;

function TForm1.lit_fic(fic : string): boolean;
var
   fichier : string;
begin
   result := true;
   {if trim(Erep_src.Text) <>'' then fichier := trim(Erep_src.Text) else  fichier := rep_fic;
   if fichier[length(fichier)] <> '\' then fichier := fichier + '\' ;  }
   fichier := repertoire + Cbannee.Text + fic;
   affiche( 'lecture de ' + fichier);
   try
      lentree.LoadFromFile(fichier);
      affiche( inttostr(lentree.Count) + ' lignes d''entrée');
   except
      affiche('problème de lecture du fichier');
      result := false;
   end;
end;


procedure TForm1.affiche(str : string);
begin
   memo1.lines.add(str);
   memo1.refresh;
end;

procedure Tform1.aj_1_ligne ;
begin
   memo1.lines.add('');
   memo1.refresh;
end;

function TForm1.lit_lgn_data(idx: integer): tstringlist;
var
   //c : tsel_ch_dt;
   i : tch_datas;
   j, k : integer;
procedure complete;
var
   l : integer;
begin
   if nb_incomplets = 0 then begin
      affiche(result[0] + ' count = ' + inttostr(result.count));
      aj_1_ligne;
   end ;
   inc(nb_incomplets);
   for l := result.count to nb_champs  do begin
      result.add('');
   end;
end; //ord_SYMPTOM_TEXT
procedure traite_texte;
var
   l, m, nb, d, p : integer;
   ok : boolean;
   st : string ;
begin
   try
      nb := result.Count ;
      l := ord_SYMPTOM_TEXT;
      //ok := false;
      if leftstr(result.Strings[ord_SYMPTOM_TEXT], 1) = '"' then begin
         repeat
            inc(l);
            ok := RightStr(result.Strings[l], 1) = '"';
         until ok or (l >= nb -2) ;
         if ok then begin
            for m := ord_SYMPTOM_TEXT to l do  st := st + result.Strings[m];
            result.Strings[ord_SYMPTOM_TEXT] := st;
            d := l - ord_SYMPTOM_TEXT;
            if l + d < nb then begin
               for m :=  l downto  ord_SYMPTOM_TEXT + 1  do begin
                   dec(nb);
                   result.Strings[m ] := result.Strings[m + d];
                   result.Delete(nb);
               end;
            end else begin
               affiche('dépassement result.count dans traite_texte pour id = ' + result.Strings[0]);
            end;
         end;
      end;
      if (result.Count <> nb_champs + 1)  then begin
        { nb := result.Count ;
         p := ord_SYMPTOM_TEXT ;
         repeat
            inc(p);
            ok := leftStr(result.Strings[l], 1) = '"';
         until ok or (p >= nb -2) ;
         if ok then begin
            l := p;
            repeat
               inc(l);
               ok := RightStr(result.Strings[l], 1) = '"';
            until ok or (l >= nb -2) ;
            if ok then begin
               for m := p to l do  st := st + result.Strings[m];
               result.Strings[p] := st;
               d := l - p;
               for m :=  l + d downto  l + 1  do begin
                   dec(nb);
                   result.Strings[m ] := result.Strings[m + d];
                   result.Delete(nb);
               end;
            end;
         end; }
      end;
   except
      affiche('Erreur  dans traite_texte pour id = ' + result.Strings[0]);
   end;
end;
begin
   result := tstringlist.Create;
   str2stl_glmt(lentree.strings[idx], result);
   k := lvax.IndexOf(result.Strings[0]);
   if k <0 then begin
      FreeAndNil(result)
   end else begin
      if result.Count <> nb_champs + 1 then begin
         //traite_texte;
         affiche(' result.count inccrect ( ' + inttostr(result.Count) + ' ) dans lit_lgn_data pour id = ' + result.Strings[0]);
      end;
      //lsortie.Add(inttostr(result.Count));
      if result.count <= nb_champs then complete;
      result.Add('') ;
      result.Strings[ord_SYMPTOM_TEXT + 1] := inttostr(k);

      for i := low(tch_datas) to high(tch_datas) do begin
         if i in c_dates then begin
            j := ord(i);
            result.Strings[j] := changedate(result.Strings[j]);
         end;
      end;
{      if result.count <= nb_champs then complete;
{      if result.count < nb_champs then complete;
      if result.count > nb_champs then begin  // il faudra dans ce cas une procédure plus complexe que str2strlist  (nouvelle procedure passer en parametre count visé  et lancer procedure alternative ans cettte procedure)
FreeAndNil(result)
end else begin
         result.Add(inttostr(k));
         for i := low(tch_datas) to high(tch_datas) do begin
            if i in c_dates then begin
               j := ord(i);
               result.Strings[j] := changedate(result.Strings[j]);
            end;
         end;
end;}
   end;
end;



procedure tlot.incremente(l_data : tstringlist);
var
   dt : TDate;
   i : integer;
   j : tch_datas;     // VAX_DATE
   grave : boolean;
   st : string;
begin  //  tch_datas = (VAERS_ID,RECVDATE,STATE,AGE_YRS,CAGE_YR,CAGE_MO,SEX,RPT_DATE,SYMPTOM_TEXT,DIED,DATEDIED,L_THREAT,ER_VISIT,HOSPITAL,HOSPDAYS,X_STAY,DISABLE,RECOVD,VAX_DATE,ONSET_DATE,NUMDAYS,LAB_DATA,V_ADMINBY,V_FUNDBY,OTHER_MEDS,CUR_ILL,HISTORY,PRIOR_VAX,SPLTTYPE,FORM_VERS,TODAYS_DATE,BIRTH_DEFECT,OFC_VISIT,ER_ED_VISIT,ALLERGIES);
   inc(nbeffets);
   grave := false;
   if l_data.Strings[ord(DIED)] = 'Y' then inc(nbmorts);
   if l_data.Strings[ord(DISABLE)] = 'Y'  then inc(nbinvalides);
   for j := low(tch_datas) to high(tch_datas) do begin
      if j in [DIED,L_THREAT,HOSPITAL,X_STAY,DISABLE,BIRTH_DEFECT] then begin
         i := ord(j);
         grave := grave or (l_data.Strings[i] = 'Y');
      end;
   end;
   if grave then inc(nbgraves);
   st := l_data.Strings[ord(VAX_DATE)];
   if length(st) = 10 then begin
      try
         dt := strtodate(st);
         if dt < date then date := dt;
      except
      end;   
   end;
end;

function TForm1.lit_lgn_vax(idx: integer): tstringlist;
var
   i : integer;
   lot : tlot;
   st : string;
begin
   result := tstringlist.Create;
   str2strlist(lentree.strings[idx], result);
   st := result.Strings[3];
   if (result.Strings[1] <> 'COVID19') or (st = '') then begin
      if result.Strings[1] = 'COVID19' then inc(nb_covid_sans_numlot);
      FreeAndNil(result);
   end else begin
      st := uppercase(trim(st));
      if pos(' ', st) > 0 then st :=  StringReplace(st , ' ', '', [rfReplaceAll]);
      if copy(st, 1 , 7)  = 'UNKNOWN' then begin
         inc(nb_covid_sans_numlot);
         FreeAndNil(result);
      end else begin
         result.Strings[3] := st;
         i := llots.IndexOf(st);
         if (i >= 0)  { and (tlot(llots.Objects[i]).fab = trim(result.Strings[2]))} then begin
            //result.Add(inttostr(i);
            result.Objects[0] := llots.Objects[i];
         end else begin
            {if i>=0 then begin
               lsortie.Add(result.Strings[3] ); // même N° lot pour 2 fabriquants différents
            end;}
            lot := tlot.create(st, result.Strings[2]);
            //result.Add(inttostr(llots.Count - 1));
            result.Objects[0] := lot;
         end;
      end;
   end;
end;

{ tlot }

constructor tlot.create(nlot, fabriquant : string);
begin
   nbmorts := 0; nbgraves := 0; nbinvalides := 0; nbeffets := 0;
   numlot := trim(nlot);
   date := date_lim;
   fab := trim(fabriquant);
   form1.llots.AddObject(numlot, self);
end;

destructor tlot.destroy_;
begin
   inherited destroy;
end;

procedure TForm1.cree_sortie;
var
   i, j, k, n : integer;
   sl : tstringlist;
   lot : tlot;
begin
   lsortie.Clear;
   affiche('début') ;
   n:= 0;
   k := ord(high(tch_datas)) +1;
   for i := 0 to ldata.Count- 1 do begin
      sl := TStringList(ldata.Objects[i]);
      j := strtointdef(sl.strings[k], -1);
      if (j >= 0) and (j < lvax.count) then begin
         lot := tlot(TStringList(lvax.objects[j]).Objects[0]);
         lot.incremente(sl );
      end else begin
         inc (n);
         if n < 11 then  affiche('valeur d''index incorrecte: ' + inttostr(j));
      end;
      if i mod 1000 = 0 then begin
         memo1.Lines[memo1.lines.count -1 ] := inttostr(i );
         memo1.Refresh;
      end;
   end;
   if nb_incomplets > 0 then affiche( inttostr(nb_incomplets) + ' lignes data incomplètes' );
   if n > 0 then affiche( inttostr(n) + ' valeurs d''index incorectes' );
   affiche('lots renseignés');
   genere_sortie('tous_effets');
   genere_sortie('cas_graves');
   genere_sortie('morts');
end;
{
•
Emergency room (ER_VISIT): If the vaccine recipient required an emergency room or doctor visit a "Y" is placed in this field; otherwise, the field will be blank. If this is the only option checked the report is not considered serious. This is a VAERS 1 form field only.

[DIED,L_THREAT,HOSPITAL,X_STAY,DISABLE,BIRTH_DEFECT]

•
Died (DIED): If the vaccine recipient died a “Y” is used; otherwise, the field will be blank.
•
Date of death (DATEDIED): If the vaccine recipient died there is space in this field to record the date of death; otherwise, the field will be blank.
•
Life threatening (L_THREAT): If the vaccine recipient had a life-threatening event associated with the vaccination a “Y” is placed is used; otherwise, the field will be blank.
•
Emergency room (ER_VISIT): If the vaccine recipient required an emergency room or doctor visit a "Y" is placed in this field; otherwise, the field will be blank. If this is the only option checked the report is not considered serious. This is a VAERS 1 form field only.
•
Hospitalized (HOSPITAL): If the vaccine recipient was hospitalized as a result of the vaccination a “Y” is used; otherwise, the field will be blank.
Revised: September 2021
Page 8 of 13
•
Days hospitalized (HOSPDAYS): If the reporter checked that the vaccine recipient was hospitalized a space is provided in this field to record the number of days hospitalized; otherwise, the field will be blank.
•
Prolonged hospitalization (X_STAY): If a patient's hospitalization is prolonged as a result of the adverse event associated with the vaccination a “Y” will be placed in this field; otherwise, the field will be blank.
•
Disability (DISABLE): If the vaccine recipient was disabled as a result of the vaccination a “Y” is placed in this field; otherwise, the field will be blank.
•
Congenital anomaly or birth defect (BIRTH_DEFECT): If the vaccine recipient had a congenital anomaly or birth defect associated with the vaccination, a “Y” is used; otherwise, the field will be blank. This is a VAERS 2 form field only.
•
Doctor or other healthcare professional office/clinic visit: If the vaccine recipient had a doctor or other healthcare professional office/clinic visit associated with the vaccination a “Y” is used; otherwise, the field will be blank. This is a VAERS 2 form field only.
•
Emergency room/department or urgent care: If the vaccine recipient had an emergency room/department or urgent care visit associated with the vaccination a “Y” is used; otherwise, the field will be blank. This is a VAERS 2 form field only.

}


procedure TForm1.genere_sortie(degre: string);
var
   i, p, n : integer;
   fic, st : string;
   lot : tlot;
begin
{   genere_sortie('tous_effets');
   genere_sortie('cas_graves');
   genere_sortie('morts');}
   p := 2;
   if degre = 'tous_effets' then p := 0;
   if degre = 'cas_graves' then p := 1;
   lsortie.Clear;
   affiche('debut');
   for i := 0 to llots.count - 1 do begin
      lot := tlot(llots.Objects[i]);
      st := datetostr(lot.date) + ',';
      case p of
          0:  n := lot.nbeffets;
          1:  n := lot.nbgraves;
      else
          n := lot.nbmorts;
      end;    
      st := st + lot.numlot + ',' + lot.fab + ',' + inttostr(n);
      lsortie.add(st);
      if i mod 1000 = 0 then begin
         memo1.Lines[memo1.lines.count -1 ] := inttostr(i );
         memo1.Refresh;
      end;
   end;
   fic := repertoire + cbannee.Text + degre + '.csv';
   lsortie.SaveToFile( fic);
   affiche('fichier créé: ' +fic);
end;

end.
