/*****************************************************************************
  IME制御用 関数群 (IME.ahk)

    グローバル変数 : なし
    各関数の依存性 : なし(必要関数だけ切出してコピペでも使えます)

    AutoHotkey:     v1.0.46以降
    Language:       apanease
    Platform:       Win9x/NT
    Author:         eamat.      http://www6.atwiki.p/eamat/pub/MyScript/
*****************************************************************************
履歴
    2008.07.11 v1.0.47以降の 関数ライブラリスクリプト対応用にファイル名を変更
    2008.12.10 コメント修正
    2009.07.03 IME_GetConverting() 追加 
               Last Found Windowが有効にならない問題修正、他。
    2009.12.03 
      ・IME 状態チェック GUIThreadInfo 利用版 入れ込み
       （IEや秀丸8βでもIME状態が取れるように）
        http://blechmusik.xrea.p/resources/keyboard_layout/Dvorak/inc/IME.ahk
      ・Google日本語入力β 向け調整
        入力モード 及び 変換モードは取れないっぽい
        IME_GET/SET() と IME_GetConverting()は有効
*/

;---------------------------------------------------------------------------
;  汎用関数 (多分どのIMEでもいけるはず)

;-----------------------------------------------------------
; IMEの状態の取得
;   WinTitle="A"    対象Window
;   戻り値          1:ON / 0:OFF
;-----------------------------------------------------------
IME_GET(WinTitle="A")  {
    VarSetCapacity(stGTI, 48, 0)
    NumPut(48, stGTI,  0, "UInt")   ;	DWORD   cbSize;
	hwndFocus := DllCall("GetGUIThreadInfo", Uint,0, Uint,&stGTI)
	             ? NumGet(stGTI,12,"UInt") : WinExist(WinTitle)

    return DllCall("SendMessage"
          , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hwndFocus)
          , UInt, 0x0283  ;Message : WM_IME_CONTROL
          ,  Int, 0x0005  ;wParam  : IMC_GETOPENSTATUS
          ,  Int, 0)      ;lParam  : 0
}

;-----------------------------------------------------------
; IMEの状態をセット
;   SetSts          1:ON / 0:OFF
;   WinTitle="A"    対象Window
;   戻り値          0:成功 / 0以外:失敗
;-----------------------------------------------------------
IME_SET(SetSts, WinTitle="A")    {
    VarSetCapacity(stGTI, 48, 0)
    NumPut(48, stGTI,  0, "UInt")   ;	DWORD   cbSize;
	hwndFocus := DllCall("GetGUIThreadInfo", Uint,0, Uint,&stGTI)
	             ? NumGet(stGTI,12,"UInt") : WinExist(WinTitle)

    return DllCall("SendMessage"
          , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hwndFocus)
          , UInt, 0x0283  ;Message : WM_IME_CONTROL
          ,  Int, 0x006   ;wParam  : IMC_SETOPENSTATUS
          ,  Int, SetSts) ;lParam  : 0 or 1
}

;===========================================================================
; IME 入力モード (どの IMEでも共通っぽい)
;   DEC  HEX    BIN
;     0 (0x00  0000 0000) かな    半英数
;     3 (0x03  0000 0011)         半ｶﾅ
;     8 (0x08  0000 1000)         全英数
;     9 (0x09  0000 1001)         ひらがな
;    11 (0x0B  0000 1011)         全カタカナ
;    16 (0x10  0001 0000) ローマ字半英数
;    19 (0x13  0001 0011)         半ｶﾅ
;    24 (0x18  0001 1000)         全英数
;    25 (0x19  0001 1001)         ひらがな
;    27 (0x1B  0001 1011)         全カタカナ

;  ※ 地域と言語のオプション - [詳細] - 詳細設定
;     - 詳細なテキストサービスのサポートをプログラムのすべてに拡張する
;    が ONになってると値が取れない模様 
;    (Google日本語入力βはここをONにしないと駄目なので値が取れないっぽい)

;-------------------------------------------------------
; IME 入力モード取得
;   WinTitle="A"    対象Window
;   戻り値          入力モード
;--------------------------------------------------------
IME_GetConvMode(WinTitle="A")   {
    VarSetCapacity(stGTI, 48, 0)
    NumPut(48, stGTI,  0, "UInt")   ;	DWORD   cbSize;
	hwndFocus := DllCall("GetGUIThreadInfo", Uint,0, Uint,&stGTI)
	             ? NumGet(stGTI,12,"UInt") : WinExist(WinTitle)

    return DllCall("SendMessage"
          , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hwndFocus)
          , UInt, 0x0283  ;Message : WM_IME_CONTROL
          ,  Int, 0x001   ;wParam  : IMC_GETCONVERSIONMODE
          ,  Int, 0)      ;lParam  : 0
}

;-------------------------------------------------------
; IME 入力モードセット
;   ConvMode        入力モード
;   WinTitle="A"    対象Window
;   戻り値          0:成功 / 0以外:失敗
;--------------------------------------------------------
IME_SetConvMode(ConvMode,WinTitle="A")   {
    VarSetCapacity(stGTI, 48, 0)
    NumPut(48, stGTI,  0, "UInt")   ;	DWORD   cbSize;
	hwndFocus := DllCall("GetGUIThreadInfo", Uint,0, Uint,&stGTI)
	             ? NumGet(stGTI,12,"UInt") : WinExist(WinTitle)

    return DllCall("SendMessage"
          , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hwndFocus)
          , UInt, 0x0283      ;Message : WM_IME_CONTROL
          ,  Int, 0x002       ;wParam  : IMC_SETCONVERSIONMODE
          ,  Int, ConvMode)   ;lParam  : CONVERSIONMODE
}

;===========================================================================
; IME 変換モード (ATOKはver.16で調査、バージョンで多少違うかも)

;   MS-IME  0:無変換 / 1:人名/地名                    / 8:一般    /16:話し言葉
;   ATOK系  0:固定   / 1:複合語              / 4:自動 / 8:連文節
;   WXG              / 1:複合語  / 2:無変換  / 4:自動 / 8:連文節
;   SKK系            / 1:ノーマル (他のモードは存在しない？)
;   Googleβ                                          / 8:ノーマル
;------------------------------------------------------------------
; IME 変換モード取得
;   WinTitle="A"    対象Window
;   戻り値 MS-IME  0:無変換 1:人名/地名               8:一般    16:話し言葉
;          ATOK系  0:固定   1:複合語           4:自動 8:連文節
;          WXG4             1:複合語  2:無変換 4:自動 8:連文節
;------------------------------------------------------------------
IME_GetSentenceMode(WinTitle="A")   {
    VarSetCapacity(stGTI, 48, 0)
    NumPut(48, stGTI,  0, "UInt")   ;	DWORD   cbSize;
	hwndFocus := DllCall("GetGUIThreadInfo", Uint,0, Uint,&stGTI)
	             ? NumGet(stGTI,12,"UInt") : WinExist(WinTitle)

    return DllCall("SendMessage"
          , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hwndFocus)
          , UInt, 0x0283  ;Message : WM_IME_CONTROL
          ,  Int, 0x003   ;wParam  : IMC_GETSENTENCEMODE
          ,  Int, 0)      ;lParam  : 0
}

;----------------------------------------------------------------
; IME 変換モードセット
;   SentenceMode
;       MS-IME  0:無変換 1:人名/地名               8:一般    16:話し言葉
;       ATOK系  0:固定   1:複合語           4:自動 8:連文節
;       WXG              1:複合語  2:無変換 4:自動 8:連文節
;   WinTitle="A"    対象Window
;   戻り値          0:成功 / 0以外:失敗
;-----------------------------------------------------------------
IME_SetSentenceMode(SentenceMode,WinTitle="A")  {
    VarSetCapacity(stGTI, 48, 0)
    NumPut(48, stGTI,  0, "UInt")   ;	DWORD   cbSize;
	hwndFocus := DllCall("GetGUIThreadInfo", Uint,0, Uint,&stGTI)
	             ? NumGet(stGTI,12,"UInt") : WinExist(WinTitle)

    return DllCall("SendMessage"
          , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hwndFocus)
          , UInt, 0x0283          ;Message : WM_IME_CONTROL
          ,  Int, 0x004           ;wParam  : IMC_SETSENTENCEMODE
          ,  Int, SentenceMode)   ;lParam  : SentenceMode
}


;---------------------------------------------------------------------------
;  IMEの種類を選ぶかもしれない関数

;==========================================================================
;  IME 文字入力の状態を返す
;  (パクリ元 : http://sites.google.com/site/agkh6mze/scripts#TOC-IME- )
;    標準対応IME : ATOK系 / MS-IME2002 2007 / WXG / SKKIME
;    その他のIMEは 入力窓/変換窓を追加指定することで対応可能
;
;       WinTitle="A"   対象Window
;       ConvCls=""     入力窓のクラス名 (正規表現表記)
;       CandCls=""     候補窓のクラス名 (正規表現表記)
;       戻り値      1 : 文字入力中 or 変換中
;                   2 : 変換候補窓が出ている
;                   0 : その他の状態
;
;   ※ MS-Office系で 入力窓のクラス名 を正しく取得するにはIMEのシームレス表示を
;      OFFにする必要がある
;      オプション-編集と日本語入力-編集中の文字列を文書に挿入モードで入力する
;      のチェックを外す
;==========================================================================
IME_GetConverting(WinTitle="A",ConvCls="",CandCls="") {

    ;IME毎の 入力窓/候補窓Class一覧 ("|" 区切りで適当に足してけばOK)
    ConvCls .= (ConvCls ? "|" : "")                 ;--- 入力窓 ---
            .  "ATOK\d+CompStr"                     ; ATOK系
            .  "|imepstcnv\d+"                     ; MS-IME系
            .  "|WXGIMEConv"                        ; WXG
            .  "|SKKIME\d+\.*\d+UCompStr"           ; SKKIME Unicode
            .  "|MSCTFIME Composition"              ; Google日本語入力

    CandCls .= (CandCls ? "|" : "")                 ;--- 候補窓 ---
            .  "ATOK\d+Cand"                        ; ATOK系
            .  "|imepstCandList\d+|imepstcand\d+" ; MS-IME 2002(8.1)XP付属
            .  "|mscandui\d+\.candidate"            ; MS Office IME-2007
            .  "|WXGIMECand"                        ; WXG
            .  "|SKKIME\d+\.*\d+UCand"              ; SKKIME Unicode
   CandGCls := "GoogleapaneseInputCandidateWindow" ;Google日本語入力

    VarSetCapacity(stGTI, 48, 0)
    NumPut(48, stGTI,  0, "UInt")   ;	DWORD   cbSize;
	hwndFocus := DllCall("GetGUIThreadInfo", Uint,0, Uint,&stGTI)
	             ? NumGet(stGTI,12,"UInt") : WinExist(WinTitle)

    WinGet, pid, PID,% "ahk_id " hwndFocus
    tmm:=A_TitleMatchMode
    SetTitleMatchMode, RegEx
    ret := WinExist("ahk_class " . CandCls . " ahk_pid " pid) ? 2
        :  WinExist("ahk_class " . CandGCls                 ) ? 2
        :  WinExist("ahk_class " . ConvCls . " ahk_pid " pid) ? 1
        :  0
    SetTitleMatchMode, %tmm%
    return ret
}


;-----------------------------------------------------------
; 使用中のキーボード配列の取得
;-----------------------------------------------------------
Get_Keyboard_Layout()  {
	SetFormat, Integer, H
	hwnd := WinExist("A")
	return DllCall("GetKeyboardLayout"
			        , "Uint", dllCall("GetWindowThreadProcessId", "Uint", hwnd)
			        , "Uint")
}

Get_languege_id(hKL) {
	SetFormat, Integer, H
	return mod(hKL, 0x10000)
}


Get_primary_language_identifier(local_identifier){
	SetFormat, Integer, H
	return mod(local_identifier, 0x100)
}

Get_sublanguage_identifier(local_identifier){
	SetFormat, Integer, H
	return Floor(local_identifier / 0x100)
}

Get_languege_name() {
	locale_id := Get_languege_id(Get_Keyboard_Layout())

	if (5 = StrLen(locale_id)){
		StringRight, locale_id, locale_id, 3
		locale_id := "0x0" . locale_id
	}
	
	;; ロケール ID (LCID) の一覧
	;; http://msdn.microsoft.com/a-p/library/ie/cc392381.aspx
	
	;; Language Identifier Constants and Strings
	;; http://msdn.microsoft.com/en-us/library/windows/desktop/dd318693(v=vs.85).aspx
	
	;; [AHK 1.1.02.00 U32] Error: Expression too long
	;; http://www.autohotkey.com/forum/topic75335.html

	return    (locale_id = "0x0436") ? "af"
			;; : (locale_id = "0x041C") ? "sq"
			;; : (locale_id = "0x3801") ? "ar-ae"
			;; : (locale_id = "0x3C01") ? "ar-bh"
			;; : (locale_id = "0x1401") ? "ar-dz"
			;; : (locale_id = "0x0C01") ? "ar-eg"
			;; : (locale_id = "0x0801") ? "ar-iq"
			;; : (locale_id = "0x2C01") ? "ar-o"
			;; : (locale_id = "0x3401") ? "ar-kw"
			;; : (locale_id = "0x3001") ? "ar-lb"
			;; : (locale_id = "0x1001") ? "ar-ly"
			;; : (locale_id = "0x1801") ? "ar-ma"
			;; : (locale_id = "0x2001") ? "ar-om"
			;; : (locale_id = "0x4001") ? "ar-qa"
			;; : (locale_id = "0x0401") ? "ar-sa"
			;; : (locale_id = "0x2801") ? "ar-sy"
			;; : (locale_id = "0x1C01") ? "ar-tn"
			;; : (locale_id = "0x2401") ? "ar-ye"
			;; : (locale_id = "0x042D") ? "eu"
			;; : (locale_id = "0x0423") ? "be"
			;; : (locale_id = "0x0402") ? "bg"
			;; : (locale_id = "0x0403") ? "ca"
			: (locale_id = "0x0804") ? "zh-cn"
			: (locale_id = "0x0C04") ? "zh-hk"
			: (locale_id = "0x1004") ? "zh-sg"
			: (locale_id = "0x0404") ? "zh-tw"
			;; : (locale_id = "0x041A") ? "hr"
			;; : (locale_id = "0x0405") ? "cs"
			;; : (locale_id = "0x0406") ? "da"
			;; : (locale_id = "0x0413") ? "nl"
			;; : (locale_id = "0x0813") ? "nl-be"
			;; : (locale_id = "0x0C09") ? "en-au"
			;; : (locale_id = "0x2809") ? "en-bz"
			;; : (locale_id = "0x1009") ? "en-ca"
			;; : (locale_id = "0x1809") ? "en-ie"
			;; : (locale_id = "0x2009") ? "en-m"
			;; : (locale_id = "0x1409") ? "en-nz"
			;; : (locale_id = "0x1C09") ? "en-za"
			;; : (locale_id = "0x2C09") ? "en-tt"
			;; : (locale_id = "0x0809") ? "en-gb"
			;; : (locale_id = "0x0409") ? "en-us"
			;; : (locale_id = "0x0425") ? "et"
			;; : (locale_id = "0x0429") ? "fa"
			;; : (locale_id = "0x040B") ? "fi"
			;; : (locale_id = "0x0438") ? "fo"
			;; : (locale_id = "0x040C") ? "fr"
			;; : (locale_id = "0x080C") ? "fr-be"
			;; : (locale_id = "0x0C0C") ? "fr-ca"
			;; : (locale_id = "0x140C") ? "fr-lu"
			;; : (locale_id = "0x100C") ? "fr-ch"
			;; : (locale_id = "0x043C") ? "gd"
			;; : (locale_id = "0x0407") ? "de"
			;; : (locale_id = "0x0C07") ? "de-at"
			;; : (locale_id = "0x1407") ? "de-li"
			;; : (locale_id = "0x1007") ? "de-lu"
			;; : (locale_id = "0x0807") ? "de-ch"
			;; : (locale_id = "0x0408") ? "el"
			;; : (locale_id = "0x040D") ? "he"
			;; : (locale_id = "0x0439") ? "hi"
			;; : (locale_id = "0x040E") ? "hu"
			;; : (locale_id = "0x040F") ? "is"
			;; : (locale_id = "0x0421") ? "in"
			;; : (locale_id = "0x0410") ? "it"
			;; : (locale_id = "0x0810") ? "it-ch"
			: (locale_id = "0x0411") ? "a"
			;; : (locale_id = "0x0412") ? "ko"
			;; : (locale_id = "0x0426") ? "lv"
			;; : (locale_id = "0x0427") ? "lt"
			;; : (locale_id = "0x042F") ? "mk"
			;; : (locale_id = "0x043E") ? "ms"
			;; : (locale_id = "0x043A") ? "mt"
			;; : (locale_id = "0x0414") ? "no"
			;; : (locale_id = "0x0415") ? "pl"
			;; : (locale_id = "0x0816") ? "pt"
			;; : (locale_id = "0x0416") ? "pt-br"
			;; : (locale_id = "0x0417") ? "rm"
			;; : (locale_id = "0x0418") ? "ro"
			;; : (locale_id = "0x0818") ? "ro-mo"
			;; : (locale_id = "0x0419") ? "ru"
			;; : (locale_id = "0x0819") ? "ru-mo"
			;; : (locale_id = "0x0C1A") ? "sr"
			;; : (locale_id = "0x0432") ? "tn"
			;; : (locale_id = "0x0424") ? "sl"
			;; : (locale_id = "0x041B") ? "sk"
			;; : (locale_id = "0x042E") ? "sb"
			;; : (locale_id = "0x040A") ? "es"
			;; : (locale_id = "0x2C0A") ? "es-ar"
			;; : (locale_id = "0x400A") ? "es-bo"
			;; : (locale_id = "0x340A") ? "es-cl"
			;; : (locale_id = "0x240A") ? "es-co"
			;; : (locale_id = "0x140A") ? "es-cr"
			;; : (locale_id = "0x1C0A") ? "es-do"
			;; : (locale_id = "0x300A") ? "es-ec"
			;; : (locale_id = "0x100A") ? "es-gt"
			;; : (locale_id = "0x480A") ? "es-hn"
			;; : (locale_id = "0x080A") ? "es-mx"
			;; : (locale_id = "0x4C0A") ? "es-ni"
			;; : (locale_id = "0x180A") ? "es-pa"
			;; : (locale_id = "0x280A") ? "es-pe"
			;; : (locale_id = "0x500A") ? "es-pr"
			;; : (locale_id = "0x3C0A") ? "es-py"
			;; : (locale_id = "0x440A") ? "es-sv"
			;; : (locale_id = "0x380A") ? "es-uy"
			;; : (locale_id = "0x200A") ? "es-ve"
			;; : (locale_id = "0x0430") ? "sx"
			;; : (locale_id = "0x041D") ? "sv"
			;; : (locale_id = "0x081D") ? "sv-fi"
			;; : (locale_id = "0x041E") ? "th"
			;; : (locale_id = "0x041F") ? "tr"
			;; : (locale_id = "0x0431") ? "ts"
			;; : (locale_id = "0x0422") ? "uk"
			;; : (locale_id = "0x0420") ? "ur"
			;; : (locale_id = "0x042A") ? "vi"
			;; : (locale_id = "0x0434") ? "xh"
			;; : (locale_id = "0x043D") ? "i"
			;; : (locale_id = "0x0435") ? "zu"
			: "unknown"
}

Get_ime_file(){
	;; ImmGetIMEFileName 関数
	;; http://msdn.microsoft.com/a-p/library/cc448001.aspx
	SubKey := Get_reg_Keyboard_Layouts()
	RegRead, ime_file_name, HKEY_LOCAL_MACHINE, %SubKey%, Ime File
	return ime_file_name
}

Get_Layout_Text(){
	SubKey := Get_reg_Keyboard_Layouts()
	RegRead, layout_text, HKEY_LOCAL_MACHINE, %SubKey%, Layout Text
	return layout_text
}

Get_reg_Keyboard_Layouts(){
	hKL := RegExReplace(Get_Keyboard_Layout(), "0x", "")
	return "System\CurrentControlSet\control\keyboard layouts\" . hKL ;"
}
