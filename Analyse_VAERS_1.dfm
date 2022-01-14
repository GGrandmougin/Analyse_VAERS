object Form1: TForm1
  Left = 245
  Top = 186
  Width = 668
  Height = 710
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Lrep_src: TLabel
    Left = 24
    Top = 16
    Width = 84
    Height = 13
    Caption = 'R'#233'pertoire source'
  end
  object Memo1: TMemo
    Left = 24
    Top = 248
    Width = 601
    Height = 401
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
  end
  object BDemarrer: TButton
    Left = 24
    Top = 200
    Width = 75
    Height = 25
    Caption = 'D'#233'marrer'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    OnClick = BDemarrerClick
  end
  object Erep_src: TEdit
    Left = 24
    Top = 40
    Width = 601
    Height = 21
    TabOrder = 2
  end
  object Cbannee: TComboBox
    Left = 24
    Top = 80
    Width = 57
    Height = 21
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ItemHeight = 13
    ItemIndex = 4
    ParentFont = False
    TabOrder = 3
    Text = '2020'
    Items.Strings = (
      '2025'
      '2024'
      '2022'
      '2021'
      '2020')
  end
end
