{
  xdg.configFile = {
    "fcitx5/config".text = ''
      [Hotkey]
      EnumerateWithTriggerKeys=True
      EnumerateForwardKeys=
      EnumerateBackwardKeys=
      EnumerateSkipFirst=False
      ModifierOnlyKeyTimeout=250

      [Hotkey/TriggerKeys]
      0=Control+space

      [Hotkey/AltTriggerKeys]
      0=Shift_L

      [Hotkey/EnumerateGroupForwardKeys]
      0=Super+space

      [Hotkey/EnumerateGroupBackwardKeys]
      0=Shift+Super+space

      [Hotkey/ActivateKeys]
      0=Hangul_Hanja

      [Hotkey/DeactivateKeys]
      0=Hangul_Romaja

      [Hotkey/PrevPage]
      0=Up

      [Hotkey/NextPage]
      0=Down

      [Hotkey/PrevCandidate]
      0=Shift+Tab

      [Hotkey/NextCandidate]
      0=Tab

      [Hotkey/TogglePreedit]
      0=Control+Alt+P

      [Behavior]
      ActiveByDefault=False
      resetStateWhenFocusIn=No
      ShareInputState=No
      PreeditEnabledByDefault=True
      ShowInputMethodInformation=True
      showInputMethodInformationWhenFocusIn=False
      CompactInputMethodInformation=True
      ShowFirstInputMethodInformation=True
      DefaultPageSize=5
      OverrideXkbOption=False
      CustomXkbOption=
      EnabledAddons=
      DisabledAddons=
      PreloadInputMethod=True
      AllowInputMethodForPassword=False
      ShowPreeditForPassword=False
      AutoSavePeriod=30
    '';

    "fcitx5/profile".text = ''
      [Groups/0]
      Name=Default
      Default Layout=us
      DefaultIM=pinyin

      [Groups/0/Items/0]
      Name=keyboard-us
      Layout=

      [Groups/0/Items/1]
      Name=pinyin
      Layout=us

      [Groups/0/Items/2]
      Name=mozc
      Layout=

      [GroupOrder]
      0=Default
    '';

    "fcitx5/conf/classicui.conf".text = ''
      Vertical Candidate List=False
      WheelForPaging=True
      Font="Sans Serif 12"
      MenuFont="Sans Serif 12"
      TrayFont="Sans Serif 12"
      TrayOutlineColor=#000000
      TrayTextColor=#ffffff
      PreferTextIcon=False
      ShowLayoutNameInIcon=True
      UseInputMethodLanguageToDisplayText=True
      Theme=Tokyonight-Storm
      DarkTheme=Tokyonight-Storm
      UseDarkTheme=True
      UseAccentColor=True
      PerScreenDPI=False
      ForceWaylandDPI=0
      EnableFractionalScale=True
    '';

    "fcitx5/conf/pinyin.conf".text = ''
      ShuangpinProfile=Ziranma
      ShowShuangpinMode=True
      PageSize=7
      SpellEnabled=True
      SymbolsEnabled=True
      ChaiziEnabled=True
      ExtBEnabled=True
      StrokeCandidateEnabled=True
      CloudPinyinEnabled=False
      CloudPinyinIndex=2
      CloudPinyinAnimation=True
      KeepCloudPinyinPlaceHolder=False
      PreeditMode="Composing pinyin"
      PreeditCursorPositionAtBeginning=True
      PinyinInPreedit=False
      Prediction=False
      KeepCurrentContext=True
      PredictionSize=49
      BackspaceBehaviorOnPrediction="Backspace when not using on-screen keyboard"
      SwitchInputMethodBehavior="Commit current preedit"
      SecondCandidate=
      ThirdCandidate=
      UseKeypadAsSelection=False
      BackSpaceToUnselect=True
      Number of sentence=2
      WordCandidateLimit=15
      LongWordLengthLimit=4
      QuickPhraseKey=semicolon
      VAsQuickphrase=True
      FirstRun=False

      [ForgetWord]
      0=Control+7

      [PrevPage]
      0=minus
      1=Up
      2=KP_Up
      3=Page_Up
      4=comma

      [NextPage]
      0=equal
      1=Down
      2=KP_Down
      3=Next
      4=period

      [PrevCandidate]
      0=Shift+Tab

      [NextCandidate]
      0=Tab

      [CurrentCandidate]
      0=space
      1=KP_Space

      [CommitRawInput]
      0=Return
      1=KP_Enter
      2=Control+Return
      3=Control+KP_Enter
      4=Shift+Return
      5=Shift+KP_Enter
      6=Control+Shift+Return
      7=Control+Shift+KP_Enter

      [ChooseCharFromPhrase]
      0=bracketleft
      1=bracketright

      [FilterByStroke]
      0=grave

      [QuickPhraseTriggerRegex]
      0=.(/|@)$
      1=^(www|bbs|forum|mail|bbs)\\.
      2=^(http|https|ftp|telnet|mailto):

      [Fuzzy]
      VE_UE=True
      NG_GN=True
      Inner=True
      InnerShort=True
      PartialFinal=True
      PartialSp=False
      V_U=False
      AN_ANG=False
      EN_ENG=False
      IAN_IANG=False
      IN_ING=False
      U_OU=False
      UAN_UANG=False
      C_CH=False
      F_H=False
      L_N=False
      L_R=False
      S_SH=False
      Z_ZH=False
      Correction=None
    '';

    "fcitx5/conf/chttrans.conf".text = ''
      Engine=OpenCC
      EnabledIM=
      OpenCCS2TProfile=default
      OpenCCT2SProfile=default

      [Hotkey]
      0=Control+Shift+F
    '';

    "fcitx5/conf/punctuation.conf".text = ''
      HalfWidthPuncAfterLetterOrNumber=True
      TypePairedPunctuationsTogether=False
      Enabled=True

      [Hotkey]
      0=Control+period
    '';

    "fcitx5/conf/notifications.conf".text = ''
      HiddenNotifications=
    '';
  };
}
