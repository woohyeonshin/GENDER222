#Requires AutoHotkey v2
#SingleInstance Force
#Include <UIA>

; ============================================================
;  젠데스크 매크로
;  - 왼쪽: 매크로 목록 (이름·단축키 자유롭게, 개수 제한 없음)
;      · [+ 카테고리]로 상위 분류를 만들고, 매크로를 분류 안에 넣을 수 있어요
;      · 분류 줄 맨 앞 ▶/▼ 를 클릭하면 펼치기/접기
;      · 분류 이름을 더블클릭하면 이름 변경 (우클릭 메뉴·[이름 변경] 버튼으로도 가능)
;      · 분류 줄을 고르고 [삭제]로 분류 삭제
;      · [분류 지정]: 고른 매크로를 분류에 넣기 (목록에 없는 이름을 적으면 새 분류가 만들어져요)
;  - 오른쪽: 선택한 매크로의 동작 순서 (위에서부터 차례로 실행)
;  - 동작 바로 추가 (왼쪽에서 매크로를 선택해 둔 상태에서)
;      F1 좌클릭 / F2 우클릭 / F6 복사하기 / F7 붙여넣기 / F8 텍스트입력 / F9 전체선택 : 대상에 마우스 대고 누르기
;      F3 크롬 창 이동 : 이동할 크롬 창 위에 마우스 대고 누르기
;      F4 기다리기 : 1초로 바로 추가 (동작 더블클릭으로 시간 변경)
;  - 입력칸(글 쓰는 칸·드롭다운)을 찍으면 '칸 위쪽 라벨 글자'를 기준으로 찾아요
;      · 칸 자체에 이름이 안 붙어 있어도 돼요 (라벨 글자 + 그 바로 아래 칸)
;      · 동작 목록에는 '라벨 (아래 칸)' 으로 보여요 · 좌표로 찾지 않아요
;      · 같은 라벨이 화면에 여러 개면 몇 번째 것인지도 같이 기억해요
;  - 동작을 고른 뒤 Delete 키 : 그 동작 삭제
;  - 복사 / 붙여넣기 / 복제 (매크로 목록·동작 순서 둘 다)
;      Ctrl+C 복사 · Ctrl+V 붙여넣기(고른 줄 바로 아래에) · Ctrl+D 복제 · 우클릭 메뉴로도 가능
;      · 분류 줄을 고르고 복사하면 그 분류의 매크로를 통째로 복사
;      · 매크로를 복사해서 동작 순서에 붙여넣으면 그 매크로의 동작이 전부 들어가요
;      · 복사한 내용은 클립보드에 글로 들어가서, 다른 PC의 이 프로그램에도 붙여넣을 수 있어요
;  - [+ 키보드 키] 버튼: 키보드의 아무 키(조합 포함)나 직접 눌러서 등록,
;      또는 목록에서 골라 추가 (더블클릭으로 수정)
;  - [+ 텍스트 추출] 버튼: 크롬 화면의 글을 찾아 클립보드에 복사
;      ① 시작어~마침어 통째로 (총 글자수 조건)
;      ② 시작어 뒤에서 원하는 부분만 (첫 숫자부터 / N번째 글자부터 ~ 마침어 앞 / 숫자 끝 / N번째 글자까지)
;      · 쉼표 넣어서/빼고 고르기, 숫자만 남기기 가능
;  - 동작마다 메모: 추가할 때 적거나(옵션), 동작 더블클릭 → 수정 창에서 적기
;  - 동작 더블클릭: 동작 종류·대상·내용·메모를 한 창에서 수정
;  - [내보내기]: 매크로를 골라서 따로 파일(.txt)로 저장
;  - [불러오기]: 내보낸 파일에서 매크로를 골라 가져오기 (뒤에 추가 / 통째로 바꾸기)
;  - 매크로 실행 중 Esc: 중단
;  데이터는 같은 폴더의 macros.txt에 저장됨
; ============================================================

global CFG := A_ScriptDir "\macros.txt"
global Macros := []            ; 각 매크로: {name, hk, cat, steps: [{action, p1, p2, p3, p4, p5, p6(메모), p7(추출 옵션 / 화면 대상 찾기 옵션)}]}
global Cats := []              ; 분류(상위 카테고리) 이름 목록 (만든 순서대로)
global CatCollapsed := Map()   ; 접힌 분류 이름 → true (화면에서만 쓰고 저장하지 않음)
global RowMap := []            ; 매크로 목록 줄 번호 → {kind:"cat", name} 또는 {kind:"macro", idx}
global Registered := []
global MainGui := 0, MacroLV := 0, StepLV := 0
global Running := false, StopFlag := false
global RetryChk := 0, RetryOn := false
global MemoChk := 0, MemoAsk := true   ; 동작 추가할 때 메모 묻기
global EditMode := false       ; 입력 대화상자가 열려 있으면 true → 단축키 비활성화
global StepDlgOpen := false    ; 동작 수정 창이 열려 있으면 true → 단축키 비활성화
global CapHook := 0            ; 키 직접 누르기용 InputHook
global CLIP_HEAD := "; 젠데스크 매크로 복사"   ; 복사할 때 클립보드 맨 윗줄
global EXTRACT_DEFAULT := "between;from=digit;fromN=1;to=end;toN=;comma=keep"   ; 새 텍스트 추출 기본값
global CLICKABLE := [50000, 50002, 50003, 50004, 50005, 50007, 50011, 50013, 50019, 50024]
global ACTION_NAME := Map("left", "좌클릭", "right", "우클릭", "key", "키보드"
    , "window", "크롬 창 이동", "wait", "기다리기", "copy", "복사하기", "paste", "붙여넣기"
    , "type", "텍스트입력", "selectall", "전체선택", "extract", "텍스트 추출")

; 화면 대상(이름으로 찾는 요소)을 쓰는 동작 → 서로 종류를 바꿀 수 있음
global ELEM_ACTIONS := ["left", "right", "copy", "paste", "type", "selectall"]

; 동작 추가용 F키 (매크로 단축키로는 못 씀)
global ADD_KEYS := Map("F1", "left", "F2", "right", "F3", "window", "F4", "wait", "F6", "copy", "F7", "paste", "F8", "type", "F9", "selectall")
global KEY_OF := Map("left", "F1", "right", "F2", "window", "F3", "wait", "F4", "copy", "F6", "paste", "F7", "type", "F8", "selectall", "F9")

; 키보드 키 추가 창의 빠른 선택 목록
global KEY_LIST := ["{Enter}", "{Tab}", "{Esc}", "{Space}", "{Backspace}", "{Delete}"
    , "{Up}", "{Down}", "{Left}", "{Right}", "^a", "^c", "^v", "^z", "^{Enter}"]

; 조합키 이름 → 보낼 때 쓰는 기호
global MOD_SIGN := Map("LControl", "^", "RControl", "^", "Control", "^"
    , "LShift", "+", "RShift", "+", "Shift", "+"
    , "LAlt", "!", "RAlt", "!", "Alt", "!", "LWin", "#", "RWin", "#")

; 화면에 보여 줄 때 쓰는 이름 (없는 건 그대로 표시)
global KEY_KOR := Map("vk15", "한/영", "vk19", "한자", "Escape", "Esc", "Control", "Ctrl"
    , "Media_Play_Pause", "재생/일시정지", "Volume_Up", "볼륨 크게", "Volume_Down", "볼륨 작게"
    , "Volume_Mute", "음소거", "Browser_Back", "브라우저 뒤로", "Browser_Forward", "브라우저 앞으로")

; [키 목록] 창에 보여 줄 키 설명
global KEY_HELP := [
    ["기본", "{Enter}", "엔터"],
    ["기본", "{Tab}", "탭 (다음 칸으로)"],
    ["기본", "{Esc}", "ESC (닫기·취소)"],
    ["기본", "{Space}", "스페이스바"],
    ["기본", "{Backspace}", "백스페이스 (한 글자 지우기)"],
    ["기본", "{Delete}", "Delete"],
    ["기본", "{Insert}", "Insert"],
    ["이동", "{Up}", "↑ 위 화살표"],
    ["이동", "{Down}", "↓ 아래 화살표"],
    ["이동", "{Left}", "← 왼쪽 화살표"],
    ["이동", "{Right}", "→ 오른쪽 화살표"],
    ["이동", "{Home}", "줄 맨 앞으로"],
    ["이동", "{End}", "줄 맨 끝으로"],
    ["이동", "{PgUp}", "Page Up (한 화면 위로)"],
    ["이동", "{PgDn}", "Page Down (한 화면 아래로)"],
    ["이동", "^{Home}", "Ctrl+Home (문서 맨 위)"],
    ["이동", "^{End}", "Ctrl+End (문서 맨 아래)"],
    ["편집", "^a", "Ctrl+A 전체 선택"],
    ["편집", "^c", "Ctrl+C 복사"],
    ["편집", "^v", "Ctrl+V 붙여넣기"],
    ["편집", "^x", "Ctrl+X 잘라내기"],
    ["편집", "^z", "Ctrl+Z 되돌리기"],
    ["편집", "^y", "Ctrl+Y 다시 실행"],
    ["편집", "^s", "Ctrl+S 저장"],
    ["편집", "^f", "Ctrl+F 찾기"],
    ["편집", "+{Enter}", "Shift+Enter (줄바꿈)"],
    ["편집", "^{Enter}", "Ctrl+Enter"],
    ["창·탭", "+{Tab}", "Shift+Tab (이전 칸으로)"],
    ["창·탭", "^{Tab}", "Ctrl+Tab (다음 탭)"],
    ["창·탭", "^+{Tab}", "Ctrl+Shift+Tab (이전 탭)"],
    ["창·탭", "^t", "Ctrl+T 새 탭"],
    ["창·탭", "^w", "Ctrl+W 탭 닫기"],
    ["창·탭", "{F5}", "F5 새로고침"],
    ["창·탭", "!{Tab}", "Alt+Tab 창 전환"],
    ["창·탭", "!{F4}", "Alt+F4 창 닫기"],
    ["창·탭", "{Browser_Back}", "브라우저 뒤로"],
    ["창·탭", "{Browser_Forward}", "브라우저 앞으로"],
    ["기능키", "{F1}", "F1"], ["기능키", "{F2}", "F2"], ["기능키", "{F3}", "F3"],
    ["기능키", "{F4}", "F4"], ["기능키", "{F5}", "F5"], ["기능키", "{F6}", "F6"],
    ["기능키", "{F7}", "F7"], ["기능키", "{F8}", "F8"], ["기능키", "{F9}", "F9"],
    ["기능키", "{F10}", "F10"], ["기능키", "{F11}", "F11"], ["기능키", "{F12}", "F12"],
    ["한글", "{vk15}", "한/영 전환"],
    ["한글", "{vk19}", "한자"],
    ["숫자패드", "{Numpad0}", "숫자패드 0 (1~9도 같은 식)"],
    ["숫자패드", "{NumpadEnter}", "숫자패드 엔터"],
    ["숫자패드", "{NumpadAdd}", "숫자패드 +"],
    ["숫자패드", "{NumpadSub}", "숫자패드 -"],
    ["숫자패드", "{NumpadMult}", "숫자패드 *"],
    ["숫자패드", "{NumpadDiv}", "숫자패드 /"],
    ["숫자패드", "{NumpadDot}", "숫자패드 ."],
    ["조합키", "{Ctrl}", "Ctrl만 한 번"],
    ["조합키", "{Shift}", "Shift만 한 번"],
    ["조합키", "{Alt}", "Alt만 한 번"],
    ["조합키", "{LWin}", "윈도우 키"],
    ["미디어", "{Media_Play_Pause}", "재생/일시정지"],
    ["미디어", "{Volume_Up}", "볼륨 크게"],
    ["미디어", "{Volume_Down}", "볼륨 작게"],
    ["미디어", "{Volume_Mute}", "음소거"],
    ["기타", "{AppsKey}", "메뉴 키 (우클릭 메뉴)"],
    ["기타", "{PrintScreen}", "Print Screen"],
    ["기타", "{CapsLock}", "Caps Lock"],
    ["기타", "{NumLock}", "Num Lock"],
    ["기타", "{ScrollLock}", "Scroll Lock"],
    ["기타", "{Pause}", "Pause"],
    ["반복", "{Tab 3}", "탭 3번 (숫자만 바꾸면 됨)"],
    ["반복", "{Down 5}", "아래 화살표 5번"],
    ["반복", "{Backspace 10}", "백스페이스 10번"],
    ["기호", "{!}", "느낌표 ! 그대로 입력"],
    ["기호", "{+}", "더하기 + 그대로 입력"],
    ["기호", "{^}", "^ 그대로 입력"],
    ["기호", "{#}", "# 그대로 입력"],
    ["기호", "{{}", "{ 그대로 입력"],
    ["기호", "{}}", "} 그대로 입력"]
]

; 편집 모드가 아니고 동작 수정 창도 닫혀 있을 때만 단축키 작동
HotkeyCondition(*) => !EditMode && !StepDlgOpen

; 편집 모드 켜고 끄기 (함수 안에서 바꿔도 전체에 적용되게)
SetEdit(v) {
    global EditMode
    EditMode := v
}

SetStepDlg(v) {
    global StepDlgOpen
    StepDlgOpen := v
}

LoadAll()
BuildGui()
RegisterAllHotkeys()
RegisterAddKeys()
RegisterDeleteKey()
RegisterCopyKeys()

; ============================================================
;  메인 창
; ============================================================
BuildGui() {
    global MainGui, MacroLV, StepLV, RetryChk, MemoChk
    MainGui := Gui("+AlwaysOnTop", "젠데스크 매크로")
    MainGui.SetFont("s10", "맑은 고딕")
    MainGui.MarginX := 10, MainGui.MarginY := 10

    MainGui.AddText("xm w220", "■ 매크로 목록")
    MainGui.AddText("x+15 w540", "■ 동작 순서 (위에서부터 차례로 실행 · 더블클릭하면 수정)")

    MacroLV := MainGui.AddListView("xm w220 r16 -Multi", ["이름", "단축키"])
    MacroLV.ModifyCol(1, 140), MacroLV.ModifyCol(2, 70)
    MacroLV.OnEvent("ItemSelect", (*) => RefreshSteps())
    MacroLV.OnEvent("Click", (l, r) => r ? OnMacroClick(r) : 0)
    MacroLV.OnEvent("DoubleClick", (l, r) => r ? OnMacroDbl(r) : 0)
    MacroLV.OnEvent("ContextMenu", (ctl, item, *) => ShowCopyMenu(ctl, item))

    StepLV := MainGui.AddListView("x+15 yp w540 r16 -Multi", ["#", "동작", "내용", "메모"])
    StepLV.ModifyCol(1, 35), StepLV.ModifyCol(2, 95), StepLV.ModifyCol(3, 245), StepLV.ModifyCol(4, 145)
    StepLV.OnEvent("DoubleClick", (l, r) => r ? EditStep(r) : 0)
    StepLV.OnEvent("ContextMenu", (ctl, item, *) => ShowCopyMenu(ctl, item))

    StepLV.GetPos(&sx, &sy, &sw, &sh)
    y1 := sy + sh + 8, y2 := y1 + 36, y3 := y2 + 36, y4 := y3 + 36, y5 := y4 + 36
    Btn := (x, y, w, text, fn) => MainGui.AddButton(Format("x{} y{} w{} h30", x, y, w), text).OnEvent("Click", fn)

    ; 매크로 · 분류 버튼 (왼쪽)
    Btn(10, y1, 107, "+ 새 매크로", NewMacro)
    Btn(123, y1, 107, "이름 변경", RenameMacro)
    Btn(10, y2, 107, "단축키 설정", SetMacroHotkey)
    Btn(123, y2, 107, "삭제", DeleteMacro)
    Btn(10, y3, 220, "▶ 매크로 실행", RunSelectedMacro)
    Btn(10, y4, 107, "+ 카테고리", NewCategory)
    Btn(123, y4, 107, "분류 지정", SetMacroCat)
    Btn(10, y5, 107, "내보내기", ExportMacros)
    Btn(123, y5, 107, "불러오기", ImportMacros)

    ; 동작 버튼 (오른쪽) - 클릭 계열은 누르면 사용법만 알려 줌
    Btn(sx, y1, 176, "+ 좌클릭 (F1)", (*) => HowTo("left"))
    Btn(sx + 182, y1, 176, "+ 우클릭 (F2)", (*) => HowTo("right"))
    Btn(sx + 364, y1, 176, "+ 크롬 창 이동 (F3)", AddWindowStep)
    Btn(sx, y2, 176, "+ 기다리기 (F4)", AddWaitStep)
    Btn(sx + 182, y2, 176, "+ 복사하기 (F6)", (*) => HowTo("copy"))
    Btn(sx + 364, y2, 176, "+ 붙여넣기 (F7)", (*) => HowTo("paste"))
    Btn(sx, y3, 60, "▲", (*) => MoveStep(-1))
    Btn(sx + 64, y3, 60, "▼", (*) => MoveStep(1))
    Btn(sx + 128, y3, 134, "전체선택 (F9)", (*) => HowTo("selectall"))
    Btn(sx + 266, y3, 134, "텍스트입력 (F8)", (*) => HowTo("type"))
    Btn(sx + 404, y3, 136, "동작 삭제 (Del)", DeleteStep)
    Btn(sx, y4, 176, "+ 키보드 키", AddKeyStep)
    Btn(sx + 182, y4, 176, "+ 텍스트 추출", AddExtractStep)
    Btn(sx + 364, y4, 176, "선택 동작 테스트", TestStep)

    yc := y5 + 42
    RetryChk := MainGui.AddCheckbox(Format("x10 y{} w775", yc)
        , "반응이 없으면 이전 클릭을 5초마다 다시 누르기 (이전 버튼이 화면에 그대로 있을 때만)")
    RetryChk.Value := RetryOn
    RetryChk.OnEvent("Click", (*) => SetRetry(RetryChk.Value))

    MemoChk := MainGui.AddCheckbox(Format("x10 y{} w775", yc + 24)
        , "동작을 추가할 때 메모 적는 창 띄우기 (끄면 메모 없이 바로 추가 · 나중에 더블클릭으로 적어도 돼요)")
    MemoChk.Value := MemoAsk
    MemoChk.OnEvent("Click", (*) => SetMemoAsk(MemoChk.Value))

    MainGui.AddText(Format("x10 y{} w775 cGray", yc + 52)
        , "· 대상에 마우스를 대고 누르면 바로 추가:  F1 좌클릭 · F2 우클릭 · F6 복사하기 · F7 붙여넣기 · F8 텍스트입력`n"
        . "· F9 전체선택 (칸을 누르고 Ctrl+A) · F3 크롬 창 이동 (크롬 창 위에서) · F4 기다리기 1초`n"
        . "· 글 쓰는 칸은 '칸 위쪽 라벨 글자 + 그 아래 칸'으로 기억해요 (칸에 이름이 없어도 돼요)`n"
        . "· [+ 키보드 키]: 아무 키나(Ctrl·Shift·Alt 조합 포함) 직접 눌러서 등록 → 커서가 있는 곳에 보내요`n"
        . "· [+ 텍스트 추출]: 시작어·마침어로 화면 글을 찾아 복사 (시작어 뒤 첫 숫자~마침어 앞만 꺼내기 · 쉼표 빼기 가능)`n"
        . "· 동작을 더블클릭하면 동작 종류(클릭·복사·붙여넣기 등끼리)·대상 이름·내용·메모를 한 창에서 수정`n"
        . "· 동작을 고른 뒤 Delete 키를 누르면 그 동작이 삭제돼요`n"
        . "· 매크로·동작을 고르고 Ctrl+C 복사 · Ctrl+V 붙여넣기(고른 줄 아래에) · Ctrl+D 복제 (우클릭 메뉴로도 돼요)`n"
        . "· [+ 카테고리]: 매크로를 묶을 상위 분류 만들기 · 분류 줄 맨 앞 ▶/▼ 클릭 = 펼치기/접기`n"
        . "· 분류 이름 더블클릭 = 이름 변경 · [분류 지정]: 고른 매크로를 분류에 넣기 · 분류 줄을 고르고 [삭제]로 분류 삭제`n"
        . "· [내보내기]: 매크로를 골라 파일로 따로 저장 · [불러오기]: 그 파일에서 골라 다시 가져오기`n"
        . "· 오른쪽에서 동작을 하나 선택해 두면, 새 동작은 그 아래에 끼워 넣어져요. 실행 중 멈추기: Esc")

    MainGui.OnEvent("Close", (*) => ExitApp())
    RefreshMacros(Macros.Length ? 1 : 0)
    MainGui.Show()
}

; 매크로 목록 다시 그리기
;  sel    : 선택할 매크로 번호 (Macros 기준, 0이면 선택 안 함)
;  selCat : isCat이 true일 때 선택할 분류 이름
RefreshMacros(sel := 0, selCat := "", isCat := false) {
    global RowMap
    MacroLV.Delete()
    RowMap := []

    ; 선택한 매크로가 접힌 분류 안에 있으면 펼쳐서 보이게
    if (sel && sel <= Macros.Length)
        CatCollapsed[Macros[sel].cat] := false

    if Cats.Length {
        groups := Cats.Clone()
        hasNone := false
        for m in Macros {
            if (m.cat = "") {
                hasNone := true
                break
            }
        }
        if hasNone
            groups.Push("")       ; 분류 없는 매크로 묶음 (분류가 하나라도 있을 때만 표시)
        for g in groups {
            n := 0
            for m in Macros {
                if (m.cat = g)
                    n++
            }
            AddCatRow(g, n)
            if IsCollapsed(g)
                continue
            for i, m in Macros {
                if (m.cat = g)
                    AddMacroRow(i, m)
            }
        }
    } else {
        for i, m in Macros
            AddMacroRow(i, m)
    }

    if isCat {
        for r, row in RowMap {
            if (row.kind = "cat" && row.name = selCat) {
                MacroLV.Modify(r, "Select Focus Vis")
                break
            }
        }
    } else if sel {
        for r, row in RowMap {
            if (row.kind = "macro" && row.idx = sel) {
                MacroLV.Modify(r, "Select Focus Vis")
                break
            }
        }
    }
    RefreshSteps()
}

AddCatRow(g, n) {
    global RowMap
    label := (IsCollapsed(g) ? "▶ " : "▼ ") (g = "" ? "(분류 없음)" : g)
    MacroLV.Add(, label, n "개")
    RowMap.Push({kind: "cat", name: g})
}

AddMacroRow(i, m) {
    global RowMap
    MacroLV.Add(, "    " m.name, m.hk = "" ? "-" : m.hk)
    RowMap.Push({kind: "macro", idx: i})
}

IsCollapsed(g) => CatCollapsed.Has(g) && CatCollapsed[g]

; 목록에서 고른 줄 (분류 또는 매크로). 아무것도 안 고르면 0
CurRow() {
    global RowMap
    r := MacroLV.GetNext()
    return (r && r <= RowMap.Length) ? RowMap[r] : 0
}

; 목록에서 고른 매크로 번호 (Macros 기준). 분류를 골랐거나 없으면 0
CurMacro() {
    row := CurRow()
    return (IsObject(row) && row.kind = "macro") ? row.idx : 0
}

; 분류 펼치기 / 접기
ToggleCat(name) {
    CatCollapsed[name] := !IsCollapsed(name)
    RefreshMacros(0, name, true)
}

; 마우스가 목록 줄 맨 앞 ▶/▼ 표시 위에 있는지 (화면 배율에 맞춰 계산)
OnArrow() {
    try {
        CoordMode("Mouse", "Client")
        MouseGetPos(&mx)
        ControlGetPos(&cx, , , , MacroLV)
        return (mx - cx) < Round(30 * A_ScreenDPI / 96)
    }
    return false
}

; 분류 줄 클릭: 맨 앞 ▶/▼ 를 눌렀으면 펼치기 / 접기
OnMacroClick(r) {
    if (r > RowMap.Length)
        return
    row := RowMap[r]
    if (row.kind = "cat" && OnArrow())
        ToggleCat(row.name)
}

; 분류 줄 더블클릭: 이름 변경 ('(분류 없음)'은 펼치기/접기). 매크로 줄 더블클릭: 실행
OnMacroDbl(r) {
    if (r > RowMap.Length)
        return
    row := RowMap[r]
    if (row.kind = "cat") {
        if OnArrow()              ; ▶/▼ 위 더블클릭은 클릭에서 이미 펼치기/접기 처리됨
            return
        if (row.name = "")
            ToggleCat(row.name)
        else
            RenameCat(row.name)
    } else {
        RunMacro(row.idx)
    }
}

RefreshSteps(sel := 0) {
    StepLV.Delete()
    mi := CurMacro()
    if !mi
        return
    for i, s in Macros[mi].steps
        StepLV.Add(, i, ActName(s.action), StepDesc(s), StrReplace(P(s, "p6"), "`n", " "))
    if sel
        StepLV.Modify(sel, "Select Focus Vis")
}

ActName(a) => ACTION_NAME.Has(a) ? ACTION_NAME[a] : a

IndexOf(arr, v) {
    for i, x in arr
        if (x = v)
            return i
    return 0
}

; 긴 글은 한 줄로 줄여서 보여 주기
Short(t) {
    t := StrReplace(t, "`n", " ")
    return StrLen(t) > 25 ? SubStr(t, 1, 25) "…" : t
}

; 화면 대상 이름 (라벨 기준으로 찾는 칸이면 '(아래 칸)'을 붙여서 보여 줌)
TName(s) => s.p1 . (ElemOpt(s).by = "label" ? " (아래 칸)" : "")

StepDesc(s) {
    if (s.action = "wait")
        return s.p1 "ms (" Round(s.p1 / 1000, 1) "초)"
    if (s.action = "copy")
        return TName(s) " → 클립보드"
    if (s.action = "paste") {
        if (P(s, "p4") = "text")
            return TName(s) " ← 글: " Short(P(s, "p5"))
        return TName(s) " ← 클립보드"
    }
    if (s.action = "type")
        return TName(s) " ← " (P(s, "p4") = "clear" ? "[지우고] " : "") Short(P(s, "p5"))
    if (s.action = "selectall")
        return TName(s) " (Ctrl+A)"
    if (s.action = "key")
        return KeyPretty(s.p1)
    if (s.action = "extract")
        return ExtractDesc(s)
    return HasVal(ELEM_ACTIONS, s.action) ? TName(s) : s.p1
}

; 동작에 그 칸이 없으면 빈 값 (예전에 만든 동작 호환용)
P(s, key) => s.HasOwnProp(key) ? s.%key% : ""

; 동작 복사본 (수정 창에서 저장 전까지 원본을 건드리지 않게)
CopyStep(s) => {action: s.action, p1: P(s, "p1"), p2: P(s, "p2"), p3: P(s, "p3")
    , p4: P(s, "p4"), p5: P(s, "p5"), p6: P(s, "p6"), p7: P(s, "p7")}

NeedMacro() {
    mi := CurMacro()
    if !mi
        MsgBox("왼쪽에서 매크로를 먼저 선택해 주세요. (분류를 골랐다면 ▶를 눌러 펼쳐서 매크로를 고르세요)")
    return mi
}

; ============================================================
;  매크로 관리
; ============================================================
NewMacro(*) {
    MainGui.Opt("+OwnDialogs")
    SetEdit(true)
    ib := InputBox("매크로 이름을 적어 주세요.", "새 매크로", "w300 h120", "매크로 " (Macros.Length + 1))
    SetEdit(false)
    if (ib.Result != "OK" || Trim(ib.Value) = "")
        return
    ; 분류를 고른 상태(또는 그 분류의 매크로를 고른 상태)에서 만들면 그 분류 안에 넣기
    cat := ""
    row := CurRow()
    if IsObject(row)
        cat := (row.kind = "cat") ? row.name : Macros[row.idx].cat
    Macros.Push({name: Trim(ib.Value), hk: "", cat: cat, steps: []})
    SaveAll()
    RefreshMacros(Macros.Length)
}

RenameMacro(*) {
    MainGui.Opt("+OwnDialogs")
    row := CurRow()
    if (IsObject(row) && row.kind = "cat") {
        if (row.name = "") {
            MsgBox("'(분류 없음)'은 이름을 바꿀 수 없어요.")
            return
        }
        RenameCat(row.name)
        return
    }
    mi := NeedMacro()
    if !mi
        return
    SetEdit(true)
    ib := InputBox("새 이름을 적어 주세요.", "이름 변경", "w300 h120", Macros[mi].name)
    SetEdit(false)
    if (ib.Result != "OK" || Trim(ib.Value) = "")
        return
    Macros[mi].name := Trim(ib.Value)
    SaveAll()
    RefreshMacros(mi)
}

DeleteMacro(*) {
    MainGui.Opt("+OwnDialogs")
    row := CurRow()
    if (IsObject(row) && row.kind = "cat") {
        if (row.name = "") {
            MsgBox("'(분류 없음)'은 지울 수 없어요. 안의 매크로는 분류 지정으로 옮겨 주세요.")
            return
        }
        DeleteCat(row.name)
        return
    }
    mi := NeedMacro()
    if !mi
        return
    SetEdit(true)
    if MsgBox("'" Macros[mi].name "' 매크로를 통째로 삭제할까요?", "삭제", "YesNo") != "Yes" {
        SetEdit(false)
        return
    }
    SetEdit(false)
    Macros.RemoveAt(mi)
    SaveAll(), RegisterAllHotkeys()
    RefreshMacros(Macros.Length ? Min(mi, Macros.Length) : 0)
}

SetMacroHotkey(*) {
    MainGui.Opt("+OwnDialogs")
    mi := NeedMacro()
    if !mi
        return
    dlg := Gui("+AlwaysOnTop +Owner" MainGui.Hwnd, "단축키 설정")
    dlg.SetFont("s10", "맑은 고딕")
    dlg.AddText("w270", "'" Macros[mi].name "' 단축키`n칸을 클릭하고 쓸 키를 직접 누르세요.")
    hkCtl := dlg.AddHotkey("w270", Macros[mi].hk)
    dlg.AddButton("w85 Default", "저장").OnEvent("Click", DoSave)
    dlg.AddButton("x+8 w85", "해제").OnEvent("Click", DoClear)
    dlg.AddButton("x+8 w85", "취소").OnEvent("Click", (*) => (SetEdit(false), dlg.Destroy()))
    dlg.OnEvent("Close", (*) => SetEdit(false))
    SetEdit(true)
    dlg.Show()

    DoSave(*) {
        key := hkCtl.Value
        if !HotkeyOK(key, mi)
            return
        Macros[mi].hk := key
        Done()
    }
    DoClear(*) {
        Macros[mi].hk := ""
        Done()
    }
    Done() {
        SetEdit(false)
        SaveAll(), RegisterAllHotkeys()
        dlg.Destroy()
        RefreshMacros(mi)
    }
}

IsReserved(key) => ADD_KEYS.Has(key) || key = "Escape" || key = "Esc"

HotkeyOK(key, mi) {
    if (key = "")
        return true
    if IsReserved(key) {
        MsgBox("F1·F2·F3·F4·F6·F7·F8·F9·Esc는 동작 추가용 키라서 고를 수 없어요.")
        return false
    }
    for i, m in Macros {
        if (i != mi && m.hk = key) {
            MsgBox("'" key "'는 이미 '" m.name "'에 쓰고 있어요.")
            return false
        }
    }
    return true
}

; ============================================================
;  분류 (상위 카테고리) 관리
;  - 매크로는 분류 하나에만 속하고, 분류 없이 둘 수도 있어요
;  - 분류를 지워도 그 안의 매크로는 지워지지 않고 '분류 없음'으로 옮겨져요
; ============================================================
EnsureCat(name) {
    global Cats
    if (name != "" && !HasVal(Cats, name))
        Cats.Push(name)
}

NewCategory(*) {
    global Cats
    MainGui.Opt("+OwnDialogs")
    SetEdit(true)
    ib := InputBox("카테고리 이름을 적어 주세요.", "새 카테고리", "w300 h120")
    SetEdit(false)
    if (ib.Result != "OK" || Trim(ib.Value) = "")
        return
    nm := Trim(ib.Value)
    if (nm = "(분류 없음)") {
        MsgBox("'(분류 없음)'은 쓸 수 없는 이름이에요.")
        return
    }
    if HasVal(Cats, nm) {
        MsgBox("'" nm "' 카테고리는 이미 있어요.")
        return
    }
    Cats.Push(nm)
    SaveAll()
    RefreshMacros(0, nm, true)
}

RenameCat(old) {
    global Cats, CatCollapsed
    MainGui.Opt("+OwnDialogs")
    SetEdit(true)
    ib := InputBox("새 카테고리 이름을 적어 주세요.", "카테고리 이름 변경", "w300 h120", old)
    SetEdit(false)
    if (ib.Result != "OK" || Trim(ib.Value) = "")
        return
    nm := Trim(ib.Value)
    if (nm == old)
        return
    ; 대소문자만 바꾸는 경우는 허용 (예: zendesk → Zendesk)
    if (nm = "(분류 없음)" || (nm != old && HasVal(Cats, nm))) {
        MsgBox("'" nm "'은(는) 쓸 수 없거나 이미 있는 이름이에요.")
        return
    }
    for m in Macros {
        if (m.cat = old)
            m.cat := nm
    }
    idx := IndexOf(Cats, old)
    if idx
        Cats[idx] := nm
    if CatCollapsed.Has(old) {
        v := CatCollapsed[old]
        CatCollapsed.Delete(old)
        CatCollapsed[nm] := v
    }
    SaveAll()
    RefreshMacros(0, nm, true)
}

DeleteCat(name) {
    global Cats, CatCollapsed
    MainGui.Opt("+OwnDialogs")
    n := 0
    for m in Macros {
        if (m.cat = name)
            n++
    }
    SetEdit(true)
    ans := MsgBox("'" name "' 카테고리를 지울까요?`n안에 있는 매크로 " n "개는 '분류 없음'으로 옮겨져요. (매크로는 지워지지 않아요)", "카테고리 삭제", "YesNo")
    SetEdit(false)
    if (ans != "Yes")
        return
    for m in Macros {
        if (m.cat = name)
            m.cat := ""
    }
    idx := IndexOf(Cats, name)
    if idx {
        Cats.RemoveAt(idx)
    }
    if CatCollapsed.Has(name)
        CatCollapsed.Delete(name)
    SaveAll()
    RefreshMacros(0)
}

; 고른 매크로를 다른 분류로 옮기기
SetMacroCat(*) {
    MainGui.Opt("+OwnDialogs")
    mi := NeedMacro()
    if !mi
        return
    CatDialog(Macros[mi].cat, (c) => ApplyCat(mi, c))
}

ApplyCat(mi, c) {
    EnsureCat(c)
    Macros[mi].cat := c
    SaveAll()
    RefreshMacros(mi)
}

; 분류 고르는 창 (목록에서 고르거나 새 이름을 적기). onOK(고른 분류 이름) 을 저장 누를 때 불러 줌
CatDialog(cur, onOK) {
    global Cats
    dlg := Gui("+AlwaysOnTop +Owner" MainGui.Hwnd, "분류 지정")
    dlg.SetFont("s10", "맑은 고딕")
    dlg.AddText("w340", "분류를 고르거나 새 분류 이름을 적어 주세요.`n'(분류 없음)'을 고르면 분류에서 빠져요.")
    items := ["(분류 없음)"]
    for c in Cats
        items.Push(c)
    cb := dlg.AddComboBox("w340", items)
    cb.Text := (cur = "") ? "(분류 없음)" : cur
    dlg.AddButton("w167 Default", "저장").OnEvent("Click", DoOK)
    dlg.AddButton("x+6 w167", "취소").OnEvent("Click", (*) => Close())
    dlg.OnEvent("Close", (*) => Close())
    SetEdit(true)
    dlg.Show()

    DoOK(*) {
        v := Trim(cb.Text)
        if (v = "(분류 없음)")
            v := ""
        Close()
        onOK(v)
    }

    Close() {
        SetEdit(false)
        try dlg.Destroy()
    }
}

; ============================================================
;  복사 / 붙여넣기 / 복제
;  - 매크로 목록·동작 순서에 포커스가 있을 때만 Ctrl+C / Ctrl+V / Ctrl+D 가 작동해요
;    (다른 프로그램이나 입력창에서는 원래 복사·붙여넣기 그대로)
;  - 복사한 내용은 클립보드에 글로 들어가요 (macros.txt와 같은 형식)
;    → 다른 PC의 이 프로그램에 붙여넣거나 메신저로 보내도 그대로 쓸 수 있어요
;  - 붙여넣기는 고른 줄 바로 아래에 들어가요 (아무것도 안 골랐으면 맨 끝)
; ============================================================
RegisterCopyKeys() {
    HotIf(CopyKeyCond)
    Hotkey("$^c", (*) => CopyFocused(), "On")
    Hotkey("$^v", (*) => PasteFocused(), "On")
    Hotkey("$^d", (*) => DupFocused(), "On")
    HotIf()
}

CopyKeyCond(*) {
    if (EditMode || StepDlgOpen || Running || !WinActive("ahk_id " MainGui.Hwnd))
        return false
    f := 0
    try f := MainGui.FocusedCtrl
    return IsObject(f) && (f == MacroLV || f == StepLV)
}

CopyFocused() => (MainGui.FocusedCtrl == StepLV) ? CopyStepToClip() : CopyMacroToClip()
PasteFocused() => (MainGui.FocusedCtrl == StepLV) ? PasteStepFromClip() : PasteMacroFromClip()
DupFocused() => (MainGui.FocusedCtrl == StepLV) ? DupStep() : DupMacro()

; 매크로 목록·동작 순서 우클릭 메뉴
ShowCopyMenu(ctl, item) {
    if (EditMode || StepDlgOpen || Running)
        return
    ctl.Focus()
    mn := Menu()
    if (ctl == StepLV) {
        mn.Add("복사`tCtrl+C", (*) => CopyStepToClip())
        mn.Add("붙여넣기 (아래에)`tCtrl+V", (*) => PasteStepFromClip())
        mn.Add("복제 (바로 아래에)`tCtrl+D", (*) => DupStep())
        if item {
            mn.Add()
            mn.Add("수정…", (*) => EditStep(item))
            mn.Add("삭제`tDel", (*) => DeleteStep())
        } else {
            mn.Disable("복사`tCtrl+C")
            mn.Disable("복제 (바로 아래에)`tCtrl+D")
        }
        if !CurMacro()
            mn.Disable("붙여넣기 (아래에)`tCtrl+V")
    } else {
        row := (item && item <= RowMap.Length) ? RowMap[item] : 0
        isCat := IsObject(row) && row.kind = "cat"
        mn.Add(isCat ? "분류 통째로 복사`tCtrl+C" : "복사`tCtrl+C", (*) => CopyMacroToClip())
        mn.Add("붙여넣기 (아래에)`tCtrl+V", (*) => PasteMacroFromClip())
        mn.Add(isCat ? "분류 통째로 복제`tCtrl+D" : "복제 (바로 아래에)`tCtrl+D", (*) => DupMacro())
        if !item {
            mn.Disable("복사`tCtrl+C")
            mn.Disable("복제 (바로 아래에)`tCtrl+D")
        }
        if isCat {
            cn := row.name
            mn.Add()
            mn.Add(IsCollapsed(cn) ? "펼치기" : "접기", (*) => ToggleCat(cn))
            if (cn != "")
                mn.Add("카테고리 이름 변경…", (*) => RenameCat(cn))
        }
    }
    mn.Show()
}

; 고른 줄의 매크로들 (매크로 줄 → 그 매크로 1개, 분류 줄 → 그 분류의 매크로 전부)
; 돌려주는 값: {list, what} 또는 0
PickedMacros() {
    row := CurRow()
    if !IsObject(row) {
        ShowTip("왼쪽에서 매크로(또는 분류)를 먼저 골라 주세요.")
        return 0
    }
    if (row.kind = "macro")
        return {list: [Macros[row.idx]], what: "'" Macros[row.idx].name "'"}
    list := []
    for m in Macros {
        if (m.cat = row.name)
            list.Push(m)
    }
    if !list.Length {
        ShowTip("이 분류에는 매크로가 없어요.")
        return 0
    }
    return {list: list, what: "분류 '" (row.name = "" ? "(분류 없음)" : row.name) "'의 매크로 " list.Length "개"}
}

CopyMacroToClip(*) {
    if !(pk := PickedMacros())
        return
    A_Clipboard := CLIP_HEAD "`n" MacroLines(pk.list, UsedCats(pk.list))
    ShowTip("복사됨: " pk.what "`n원하는 위치를 고르고 Ctrl+V로 붙여넣기", 2000)
}

PasteMacroFromClip(*) {
    d := ParseMacroText(ClipText())
    if !d.macros.Length {
        if d.steps.Length
            ShowTip("복사해 둔 건 '동작'이에요. 오른쪽 동작 순서에 붙여넣어 주세요.", 2500)
        else
            ShowTip("붙여넣을 매크로가 없어요. 먼저 매크로를 고르고 Ctrl+C로 복사해 주세요.", 2500)
        return
    }
    InsertMacros(d.macros, "붙여넣음")
}

DupMacro(*) {
    if !(pk := PickedMacros())
        return
    ; 글로 바꿨다가 다시 읽어서 완전히 따로 노는 복사본을 만듦 (클립보드는 안 건드림)
    InsertMacros(ParseMacroText(MacroLines(pk.list)).macros, "복제함")
}

; 매크로들을 고른 줄 바로 아래에 끼워 넣기
;  - 매크로 줄을 골랐으면 그 매크로 아래, 같은 분류로
;  - 분류 줄을 골랐으면 그 분류 맨 끝에, 그 분류로
;  - 아무것도 안 골랐으면 맨 끝에, 원래 분류 그대로
;  - 이름이 겹치면 (2), (3)… 붙이고, 단축키가 겹치면 비워 둠
InsertMacros(list, verb) {
    row := CurRow()
    pos := Macros.Length + 1, cat := "", useCat := false
    if IsObject(row) {
        useCat := true
        if (row.kind = "cat") {
            cat := row.name
            for i, m in Macros {
                if (m.cat = cat)
                    pos := i + 1
            }
        } else {
            cat := Macros[row.idx].cat
            pos := row.idx + 1
        }
    }
    first := pos, cleared := 0
    for m in list {
        m.name := UniqueName(m.name)
        if (m.hk != "" && (IsReserved(m.hk) || HkUsed(m.hk))) {
            m.hk := ""
            cleared++
        }
        if useCat
            m.cat := cat
        EnsureCat(m.cat)
        Macros.InsertAt(pos++, m)
    }
    SaveAll(), RegisterAllHotkeys()
    RefreshMacros(first)
    msg := verb ": 매크로 " list.Length "개"
    if (list.Length = 1)
        msg := verb ": '" list[1].name "'"
    if cleared
        msg .= "`n(단축키가 겹쳐서 비워 뒀어요 · [단축키 설정]에서 다시 정해 주세요)"
    ShowTip(msg, 2500)
}

CopyStepToClip(*) {
    mi := CurMacro()
    si := mi ? StepLV.GetNext() : 0
    if !si {
        ShowTip("복사할 동작을 오른쪽에서 먼저 골라 주세요.")
        return
    }
    s := Macros[mi].steps[si]
    A_Clipboard := CLIP_HEAD "`n" StepLine(s)
    ShowTip("복사됨: " si "번 " ActName(s.action) "`n원하는 매크로·위치를 고르고 Ctrl+V로 붙여넣기", 2000)
}

PasteStepFromClip(*) {
    mi := CurMacro()
    if !mi {
        ShowTip("왼쪽에서 붙여넣을 매크로를 먼저 골라 주세요.")
        return
    }
    d := ParseMacroText(ClipText())
    list := d.steps.Clone()
    for m in d.macros {           ; 매크로를 복사해 왔으면 그 동작들을 전부 넣음
        for s in m.steps
            list.Push(s)
    }
    if !list.Length {
        ShowTip("붙여넣을 동작이 없어요. 먼저 동작을 고르고 Ctrl+C로 복사해 주세요.", 2500)
        return
    }
    InsertSteps(mi, list, "붙여넣음")
}

DupStep(*) {
    mi := CurMacro()
    si := mi ? StepLV.GetNext() : 0
    if !si {
        ShowTip("복제할 동작을 오른쪽에서 먼저 골라 주세요.")
        return
    }
    InsertSteps(mi, [CopyStep(Macros[mi].steps[si])], "복제함")
}

; 동작들을 고른 동작 바로 아래에 끼워 넣기 (아무것도 안 골랐으면 맨 끝)
InsertSteps(mi, list, verb) {
    steps := Macros[mi].steps
    sel := StepLV.GetNext()
    pos := sel ? sel + 1 : steps.Length + 1
    for s in list
        steps.InsertAt(pos++, s)
    SaveAll()
    RefreshSteps(pos - 1)
    ShowTip(verb ": 동작 " list.Length "개 → '" Macros[mi].name "'", 2000)
}

ClipText() {
    t := ""
    try t := A_Clipboard
    return t
}

; ============================================================
;  내보내기 / 불러오기
;  - 내보내기: 고른 매크로만 따로 파일로 저장 (macros.txt와 같은 형식)
;  - 불러오기: 내보낸 파일(또는 다른 PC의 macros.txt)에서 골라 가져오기
; ============================================================
ExportMacros(*) {
    MainGui.Opt("+OwnDialogs")
    if !Macros.Length {
        MsgBox("내보낼 매크로가 없어요.")
        return
    }
    PickMacrosDialog("매크로 내보내기", "파일로 저장할 매크로를 체크하세요.", Macros, false, DoExport)

    DoExport(list, *) {
        MainGui.Opt("+OwnDialogs")
        def := A_ScriptDir "\매크로_내보내기_" FormatTime(, "yyyyMMdd_HHmm") ".txt"
        SetEdit(true)
        path := FileSelect("S16", def, "매크로 내보내기 - 저장할 곳 고르기", "매크로 파일 (*.txt)")
        SetEdit(false)
        if (path = "")
            return
        SplitPath(path, , , &ext)
        if (ext = "")
            path .= ".txt"
        try {
            f := FileOpen(path, "w", "UTF-8")
            f.Write("; 젠데스크 매크로 내보내기 (" FormatTime(, "yyyy-MM-dd HH:mm") ")`n" MacroLines(list, UsedCats(list)))
            f.Close()
        } catch {
            MsgBox("저장하지 못했어요. 다른 폴더를 골라 보세요.`n" path)
            return
        }
        MsgBox(list.Length "개 매크로를 내보냈어요.`n" path)
    }
}

ImportMacros(*) {
    MainGui.Opt("+OwnDialogs")
    SetEdit(true)
    path := FileSelect(1, A_ScriptDir, "매크로 불러오기 - 파일 고르기", "매크로 파일 (*.txt)")
    SetEdit(false)
    if (path = "")
        return
    try content := FileRead(path, "UTF-8")
    catch {
        MsgBox("파일을 읽지 못했어요.`n" path)
        return
    }
    data := ParseMacroText(content)
    if !data.macros.Length {
        MsgBox("이 파일에는 불러올 매크로가 없어요.`n이 프로그램에서 내보낸 파일(또는 macros.txt)인지 확인해 주세요.")
        return
    }
    SplitPath(path, &fname)
    PickMacrosDialog("매크로 불러오기", "가져올 매크로를 체크하세요.`n파일: " fname, data.macros, true, DoImport)

    DoImport(picked, replace) {
        global Cats
        MainGui.Opt("+OwnDialogs")
        backup := ""
        if replace {
            SetEdit(true)
            ans := MsgBox("지금 목록에 있는 매크로 " Macros.Length "개를 지우고 고른 매크로로 바꿀까요?`n"
                . "(지금 목록은 백업 파일로 남겨 둬요)", "통째로 바꾸기", "YesNo Icon!")
            SetEdit(false)
            if (ans != "Yes")
                return
            if FileExist(CFG) {
                backup := A_ScriptDir "\macros_백업_" FormatTime(, "yyyyMMdd_HHmmss") ".txt"
                try FileCopy(CFG, backup)
                catch
                    backup := ""
            }
            Macros.Length := 0
            Cats := []
        }
        start := Macros.Length
        renamed := [], cleared := []
        for m in picked {
            nm := UniqueName(m.name)
            if (nm != m.name)
                renamed.Push(m.name " → " nm)
            m.name := nm
            ; 동작 추가용 키이거나 이미 쓰는 단축키면 비워 둠
            if (m.hk != "" && (IsReserved(m.hk) || HkUsed(m.hk))) {
                cleared.Push(m.name " (" m.hk ")")
                m.hk := ""
            }
            EnsureCat(m.cat)
            Macros.Push(m)
        }
        SaveAll(), RegisterAllHotkeys()
        RefreshMacros(start + 1)

        msg := picked.Length "개 매크로를 불러왔어요."
        if (backup != "")
            msg .= "`n`n기존 목록 백업: " backup
        if renamed.Length
            msg .= "`n`n이름이 겹쳐서 바꿨어요:`n· " Join(renamed, "`n· ")
        if cleared.Length
            msg .= "`n`n단축키가 겹쳐서 비워 뒀어요 ([단축키 설정]에서 다시 정해 주세요):`n· " Join(cleared, "`n· ")
        MsgBox(msg, "불러오기 완료")
    }
}

; 매크로를 체크해서 고르는 창 (내보내기 / 불러오기 같이 씀)
; onOK(고른 매크로 배열, 통째로바꾸기여부) 를 확인 버튼 누를 때 불러 줌
PickMacrosDialog(title, guide, list, isImport, onOK) {
    dlg := Gui("+AlwaysOnTop +Owner" MainGui.Hwnd, title)
    dlg.SetFont("s10", "맑은 고딕")
    dlg.AddText("w360", guide)
    lv := dlg.AddListView("w360 r12 Checked NoSort -Multi", ["이름", "단축키", "동작 수"])
    for m in list
        lv.Add("Check", m.name, m.hk = "" ? "-" : m.hk, m.steps.Length)
    lv.ModifyCol(1, 200), lv.ModifyCol(2, 80), lv.ModifyCol(3, 60)
    dlg.AddButton("w177", "모두 체크").OnEvent("Click", (*) => lv.Modify(0, "Check"))
    dlg.AddButton("x+6 w177", "모두 해제").OnEvent("Click", (*) => lv.Modify(0, "-Check"))
    rRep := 0
    if isImport {
        dlg.AddRadio("xm w360 Checked", "지금 목록 뒤에 추가하기")
        rRep := dlg.AddRadio("xm w360", "지금 목록을 지우고 이걸로 바꾸기 (기존 목록은 백업)")
    }
    dlg.AddButton("xm w177 Default", isImport ? "불러오기" : "내보내기").OnEvent("Click", DoOK)
    dlg.AddButton("x+6 w177", "취소").OnEvent("Click", (*) => Close())
    dlg.OnEvent("Close", (*) => Close())
    dlg.OnEvent("Escape", (*) => Close())
    SetEdit(true)
    dlg.Show()

    DoOK(*) {
        picked := []
        row := 0
        while (row := lv.GetNext(row, "C"))
            picked.Push(list[row])
        if !picked.Length {
            dlg.Opt("+OwnDialogs")
            MsgBox("매크로를 하나 이상 체크해 주세요.")
            return
        }
        replace := isImport && rRep.Value
        Close()
        onOK(picked, replace)
    }

    Close() {
        SetEdit(false)
        try dlg.Destroy()
    }
}

; 이름이 이미 있으면 뒤에 (2), (3)… 붙이기
UniqueName(name) {
    nm := name, n := 1
    while HasName(nm)
        nm := name " (" (++n) ")"
    return nm
}

HasName(name) {
    for m in Macros
        if (m.name = name)
            return true
    return false
}

HkUsed(key) {
    for m in Macros
        if (m.hk = key)
            return true
    return false
}

Join(arr, sep) {
    out := ""
    for i, v in arr
        out .= (i > 1 ? sep : "") v
    return out
}

HasVal(arr, v) {
    for x in arr
        if (x = v)
            return true
    return false
}

; 매크로 목록에서 쓰는 분류 이름들 (내보낼 때 같이 저장하려고)
UsedCats(list) {
    out := []
    for m in list {
        if (m.cat != "" && !HasVal(out, m.cat))
            out.Push(m.cat)
    }
    return out
}

; ============================================================
;  동작 추가 / 편집
; ============================================================
AddStep(mi, s) {
    ; 메모 묻기 (취소하거나 비워 두면 메모 없이 추가)
    if MemoAsk {
        MainGui.Opt("+OwnDialogs")
        SetEdit(true)
        ib := InputBox("이 동작에 붙일 메모를 적어 주세요. (비워 두거나 취소하면 메모 없이 추가)`n`n"
            . ActName(s.action) " : " Short(StepDesc(s)), "메모", "w380 h160")
        SetEdit(false)
        s.p6 := (ib.Result = "OK") ? Trim(ib.Value) : ""
    } else if !s.HasOwnProp("p6") {
        s.p6 := ""
    }
    steps := Macros[mi].steps
    sel := (CurMacro() = mi) ? StepLV.GetNext() : 0
    if sel {
        steps.InsertAt(sel + 1, s)
        pos := sel + 1
    } else {
        steps.Push(s)
        pos := steps.Length
    }
    SaveAll()
    if (CurMacro() != mi)
        RefreshMacros(mi)
    RefreshSteps(pos)
}

; ---- F키 등록 ----
RegisterAddKeys() {
    HotIf(HotkeyCondition)
    for key, action in ADD_KEYS
        Hotkey("$" key, HotAdd.Bind(action), "On")
    HotIf()
}

; 동작 목록에서 동작을 고른 상태로 Delete 키를 누르면 그 동작 삭제
RegisterDeleteKey() {
    HotIf(DelStepCond)
    Hotkey("$Delete", (*) => DeleteStep(), "On")
    HotIf()
}

DelStepCond(*) {
    if (EditMode || StepDlgOpen || !WinActive("ahk_id " MainGui.Hwnd))
        return false
    return (MainGui.FocusedCtrl == StepLV) && (StepLV.GetNext() > 0)
}

; F키를 누르면 선택한 매크로에 바로 동작 추가
HotAdd(action, *) {
    if Running
        return
    mi := CurMacro()
    if !mi {
        ShowTip("왼쪽에서 매크로를 먼저 선택해 주세요.")
        return
    }
    switch action {
        case "wait":
            AddStep(mi, {action: "wait", p1: 1000, p2: "", p3: "", p4: "", p5: ""})
            ShowTip("추가됨: 기다리기 1초 (더블클릭하면 시간 변경)")
        case "window":
            AddWindowUnderMouse(mi)
        default:
            AddElementUnderMouse(action, mi)
    }
}

; 버튼을 누르면 사용법 안내
HowTo(action) {
    ShowTip("대상에 마우스를 대고 " KEY_OF[action] " 를 누르세요.", 2500)
}

; ---- 좌클릭 / 우클릭 / 복사하기 / 붙여넣기 / 텍스트입력 / 전체선택: 마우스 아래 대상 ----
;  글 쓰는 칸·드롭다운은 '위쪽 라벨 글자 + 그 아래 칸'으로 등록 (p1=라벨, p7="by=label;n=몇번째")
;  그 밖의 버튼·링크는 예전처럼 이름으로 등록
AddElementUnderMouse(action, mi) {
    CoordMode("Mouse", "Screen")
    MouseGetPos(&x, &y, &win)
    if (win = MainGui.Hwnd) {
        ShowTip("매크로 창 말고, 누를 대상 위에 마우스를 대고 눌러 주세요.")
        return
    }
    raw := 0
    try raw := UIA.ElementFromPoint(x, y)

    el := 0, nm := "", tp := "", opt := "", inp := 0
    ; ① 입력칸이면 위쪽 라벨 글자를 기준으로 등록 (칸에 이름이 안 붙어 있어도 돼요)
    try {
        inp := FindInput(raw)
        if inp {
            info := LabelAnchor(inp, win)
            if info {
                el := inp, nm := info.label, tp := inp.Type, opt := "by=label;n=" info.n
            }
        }
    }
    ; ② 아니면 예전처럼 칸·버튼 이름으로
    if !el {
        inpName := ""
        if inp
            try inpName := inp.Name
        if (inp && inpName = "") {
            ShowTip("이 칸은 이름도, 위쪽 라벨 글자도 못 찾았어요.`n라벨이 칸 바로 위에 글자로 보이는지 확인해 주세요.", 3000)
            return
        }
        try el := FindTarget(raw, action = "copy")
        if !el {
            ShowTip("이 위치는 이름이 없어서 등록할 수 없어요.`n조금 옆에 마우스를 대고 다시 눌러 보세요.", 2500)
            return
        }
        nm := el.Name, tp := el.Type
    }
    exe := "chrome.exe"
    try exe := WinGetProcessName("ahk_id " win)
    shown := nm . (opt != "" ? " (아래 칸)" : "")
    if (action = "paste") {
        AskPaste(mi, nm, tp, exe, opt)    ; 무엇을 붙여넣을지 고르는 창
        return
    }
    if (action = "type") {
        ; 넣을 글을 적는 창
        TypeDialog(shown, "", 0, (t, c) => (
            AddStep(mi, {action: "type", p1: nm, p2: tp, p3: exe, p4: c ? "clear" : "", p5: t, p7: opt}),
            ShowTip("추가됨: 텍스트입력 → " shown)))
        return
    }
    AddStep(mi, {action: action, p1: nm, p2: tp, p3: exe, p4: "", p5: "", p7: opt})
    ShowTip("추가됨: " ACTION_NAME[action] " → " shown)
}

; ---- 크롬 창 이동: 마우스 아래 크롬 창 ----
AddWindowUnderMouse(mi) {
    CoordMode("Mouse", "Screen")
    MouseGetPos(, , &win)
    exe := ""
    try exe := WinGetProcessName("ahk_id " win)
    if (exe != "chrome.exe") {
        ShowTip("이동할 크롬 창 위에 마우스를 대고 F3을 눌러 주세요.", 2500)
        return
    }
    t := RegExReplace(WinGetTitle("ahk_id " win), " - (Google Chrome|Chrome)$")
    if (t = "") {
        ShowTip("창 제목을 읽지 못했어요. 다시 해 보세요.")
        return
    }
    AddStep(mi, {action: "window", p1: t, p2: "", p3: "", p4: "", p5: ""})
    ShowTip("추가됨: 크롬 창 이동 → " t "`n(이름을 줄이려면 더블클릭)", 2500)
}

; ---- 붙여넣기: 클립보드 또는 직접 적은 글 ----
AskPaste(mi, name, type, exe, opt := "") {
    shown := name . (opt != "" ? " (아래 칸)" : "")
    PasteDialog(shown, false, "", (useText, t) => (
        AddStep(mi, {action: "paste", p1: name, p2: type, p3: exe
            , p4: useText ? "text" : "clip", p5: useText ? t : "", p7: opt}),
        ShowTip("추가됨: 붙여넣기 → " shown)))
}

; 붙여넣을 내용 고르는 창 (추가할 때 / 수정할 때 같이 씀)
; onOK(글사용여부, 글) 을 저장 버튼 누를 때 불러 줌
PasteDialog(name, useText, text, onOK, owner := 0) {
    dlg := Gui("+AlwaysOnTop +Owner" (owner ? owner.Hwnd : MainGui.Hwnd), "붙여넣기")
    dlg.SetFont("s10", "맑은 고딕")
    dlg.AddText("w360", "붙여넣을 곳: " name)
    r1 := dlg.AddRadio("w360" (useText ? "" : " Checked"), "복사해 둔 내용 붙여넣기 (클립보드)")
    r2 := dlg.AddRadio("w360" (useText ? " Checked" : ""), "아래에 적은 글 붙여넣기 (상용구)")
    ed := dlg.AddEdit("w360 r6", text)
    ed.OnEvent("Change", (*) => (r2.Value := 1))
    dlg.AddButton("w177 Default", "저장").OnEvent("Click", DoOK)
    dlg.AddButton("x+6 w177", "취소").OnEvent("Click", (*) => (SetEdit(false), dlg.Destroy()))
    dlg.OnEvent("Close", (*) => SetEdit(false))
    SetEdit(true)
    dlg.Show()

    DoOK(*) {
        u := r2.Value
        if (u && Trim(ed.Value) = "") {
            dlg.Opt("+OwnDialogs")
            MsgBox("붙여넣을 글을 적어 주세요.")
            return
        }
        t := ed.Value
        SetEdit(false)
        dlg.Destroy()
        onOK(u, t)
    }
}

; ---- 텍스트입력: 넣을 글 적기 (추가할 때 / 더블클릭으로 고칠 때 같이 씀) ----
; onOK(글, 지우기여부) 를 저장 버튼 누를 때 불러 줌
TypeDialog(name, text, clear, onOK, owner := 0) {
    dlg := Gui("+AlwaysOnTop +Owner" (owner ? owner.Hwnd : MainGui.Hwnd), "텍스트입력")
    dlg.SetFont("s10", "맑은 고딕")
    dlg.AddText("w360", "입력할 칸: " name "`n칸에 넣을 글을 적어 주세요. (Enter = 줄바꿈)")
    ed := dlg.AddEdit("w360 r6 WantReturn", text)
    ck := dlg.AddCheckbox("w360", "넣기 전에 칸에 있던 글 지우기")
    ck.Value := clear
    dlg.AddButton("w177", "저장").OnEvent("Click", DoOK)
    dlg.AddButton("x+6 w177", "취소").OnEvent("Click", (*) => (SetEdit(false), dlg.Destroy()))
    dlg.OnEvent("Close", (*) => SetEdit(false))
    SetEdit(true)
    dlg.Show()

    DoOK(*) {
        if (ed.Value = "") {
            dlg.Opt("+OwnDialogs")
            MsgBox("넣을 글을 적어 주세요.")
            return
        }
        t := ed.Value, c := ck.Value
        SetEdit(false)
        dlg.Destroy()
        onOK(t, c)
    }
}

; ---- 텍스트 추출 ----
; 저장 칸: p1 시작어 / p2 마침어 / p3 총 글자수(통째로 방식, 빈칸=상관없음)
;          p4 몇 번째 결과 / p5 "digits"면 숫자만 남김
;          p7 추출 옵션 (예: between;from=digit;fromN=1;to=end;toN=;comma=drop)
;            · whole   : 시작어~마침어 통째로 (예전 방식, p7이 비어 있어도 이 방식)
;            · between : 시작어 뒤에서 일부만 꺼내기 (시작어·마침어 빼고)
;                from = digit(첫 숫자부터) / pos(fromN번째 글자부터)
;                to   = end(마침어 바로 앞까지) / num(숫자가 끝나는 곳까지) / pos(toN번째 글자까지)
;            · comma = keep(쉼표 그대로) / drop(쉼표 빼기)

AddExtractStep(*) {
    MainGui.Opt("+OwnDialogs")
    mi := NeedMacro()
    if !mi
        return
    ExtractDialog({p1: "", p2: "", p3: "", p4: 1, p5: "", p7: EXTRACT_DEFAULT}, (r) => (
        AddStep(mi, {action: "extract", p1: r.p1, p2: r.p2, p3: r.p3, p4: r.p4, p5: r.p5, p7: r.p7}),
        ShowTip("추가됨: 텍스트 추출 → " ExtractDesc(r), 2500)))
}

; p7 글 → 옵션 묶음
ExtOpt(s) {
    o := {mode: "whole", from: "digit", fromN: 1, to: "end", toN: "", comma: "keep"}
    for part in StrSplit(P(s, "p7"), ";") {
        kv := StrSplit(part, "=", , 2)
        if (kv.Length = 1) {
            if (kv[1] = "between" || kv[1] = "whole")
                o.mode := kv[1]
        } else if HasVal(["from", "fromN", "to", "toN", "comma"], kv[1]) {
            o.%kv[1]% := kv[2]
        }
    }
    return o
}

; 추출 조건 적는 창 (추가할 때 / 더블클릭으로 고칠 때 같이 씀)
; onOK({p1..p5, p7}) 를 저장 버튼 누를 때 불러 줌
ExtractDialog(init, onOK, owner := 0) {
    o := ExtOpt(init)
    dlg := Gui("+AlwaysOnTop +Owner" (owner ? owner.Hwnd : MainGui.Hwnd), "텍스트 추출")
    dlg.SetFont("s10", "맑은 고딕")
    dlg.AddText("w430", "크롬 화면에 보이는 글에서 조건에 맞는 부분을 찾아 복사해요.`n"
        . "공백(띄어쓰기)도 한 글자로 세요.   예) 바람의 나라 = 6글자")
    dlg.AddText("xm y+12 w95", "시작어")
    edS := dlg.AddEdit("x+5 yp-3 w330", init.p1)
    dlg.AddText("xm y+10 w95", "마침어")
    edE := dlg.AddEdit("x+5 yp-3 w330", init.p2)

    ; ① 통째로 복사 (예전 방식)
    rOld := dlg.AddRadio("xm y+14 w430", "① 시작어~마침어를 통째로 복사  (시작어·마침어 포함)")
    lblN := dlg.AddText("xm+22 y+6 w73", "총 글자수")
    edN := dlg.AddEdit("x+5 yp-3 w60 Number", init.p3)
    hintN := dlg.AddText("x+8 yp+3 w250 cGray", "공백 포함 · 비우면 길이 상관없음")
    hintN2 := dlg.AddText("xm+22 y+4 w410 cGray", "· 마침어를 비우면 시작어부터 글자수만큼 (예: 010 · 13글자 → 010-1234-5678)")

    ; ② 일부만 꺼내기
    rMid := dlg.AddRadio("xm y+14 w430", "② 시작어 뒤에서 원하는 부분만 꺼내기  (시작어·마침어 빼고)")
    lblF := dlg.AddText("xm+22 y+8 w73", "어디부터")
    ddF := dlg.AddDropDownList("x+5 yp-3 w240", ["시작어 뒤 첫 숫자부터", "시작어 뒤 N번째 글자부터"])
    edF := dlg.AddEdit("x+5 w50 Number", o.fromN)
    lblT := dlg.AddText("xm+22 y+10 w73", "어디까지")
    ddT := dlg.AddDropDownList("x+5 yp-3 w240", ["마침어 바로 앞까지", "숫자가 끝나는 곳까지", "시작어 뒤 N번째 글자까지"])
    edT := dlg.AddEdit("x+5 w50 Number", o.toN)
    hintM := dlg.AddText("xm+22 y+6 w410 cGray"
        , "· N번째: 시작어 바로 뒤 글자가 1번째 (공백도 한 글자)`n"
        . "· 예) 판매가격 : 2,502원 → 시작어 '판' · 마침어 '원'`n"
        . "      · 첫 숫자부터 · 마침어 바로 앞까지  →  2,502`n"
        . "· 마침어를 적으면 '숫자 끝'·'N번째'로 골라도 마침어 앞까지만 찾아요")
    ddF.Value := (o.from = "pos") ? 2 : 1
    ddT.Value := (o.to = "num") ? 2 : (o.to = "pos") ? 3 : 1

    ; 공통
    dlg.AddText("xm y+14 w95", "몇 번째 결과")
    edK := dlg.AddEdit("x+5 yp-3 w60 Number", init.p4 = "" ? 1 : init.p4)
    dlg.AddText("x+8 yp+3 w250 cGray", "같은 조건이 여러 개면 몇 번째 것")
    lblC := dlg.AddText("xm y+12 w95", "쉼표(,)")
    rCk := dlg.AddRadio("x+5 yp w155", "넣어서  (2,502)")
    rCd := dlg.AddRadio("x+5 yp w155", "빼고  (2502)")
    if (o.comma = "drop")
        rCd.Value := 1
    else
        rCk.Value := 1
    ck := dlg.AddCheckbox("xm y+10 w430", "숫자만 남겨서 복사  (예: 010-1234-5678 → 01012345678)")
    ck.Value := (init.p5 = "digits")

    dlg.AddButton("xm y+10 w430", "지금 크롬 화면에서 찾아보기").OnEvent("Click", DoTest)
    res := dlg.AddEdit("xm w430 r2 ReadOnly", "")
    dlg.AddButton("xm w212 Default", "저장").OnEvent("Click", DoOK)
    dlg.AddButton("x+6 w212", "취소").OnEvent("Click", (*) => (SetEdit(false), dlg.Destroy()))
    dlg.OnEvent("Close", (*) => SetEdit(false))

    ; ①·② 는 사이에 다른 칸이 있어서 따로 묶음 → 직접 하나만 켜지게
    rOld.Value := (o.mode != "between")
    rMid.Value := (o.mode = "between")
    rOld.OnEvent("Click", (*) => (rMid.Value := 0, UpdMode()))
    rMid.OnEvent("Click", (*) => (rOld.Value := 0, UpdMode()))
    ddF.OnEvent("Change", (*) => UpdMode())
    ddT.OnEvent("Change", (*) => UpdMode())
    ck.OnEvent("Click", (*) => UpdMode())
    UpdMode()
    SetEdit(true)
    dlg.Show()

    ; 고른 방식에 맞는 칸만 켜기
    UpdMode() {
        mid := rMid.Value
        for c in [lblN, edN, hintN, hintN2]
            c.Enabled := !mid
        for c in [lblF, ddF, lblT, ddT, hintM]
            c.Enabled := mid
        edF.Enabled := mid && ddF.Value = 2
        edT.Enabled := mid && ddT.Value = 3
        for c in [lblC, rCk, rCd]      ; 숫자만 남기면 쉼표는 어차피 빠짐
            c.Enabled := !ck.Value
    }

    Collect() {
        k := Trim(edK.Value)
        opt := (rMid.Value ? "between" : "whole")
            . ";from=" (ddF.Value = 2 ? "pos" : "digit") ";fromN=" Trim(edF.Value)
            . ";to=" (ddT.Value = 2 ? "num" : ddT.Value = 3 ? "pos" : "end") ";toN=" Trim(edT.Value)
            . ";comma=" (rCd.Value ? "drop" : "keep")
        return {p1: Trim(edS.Value), p2: Trim(edE.Value), p3: Trim(edN.Value)
            , p4: (k = "" || k = 0) ? 1 : k, p5: ck.Value ? "digits" : "", p7: opt}
    }

    Check(r) {
        if (r.p1 = "")
            return "시작어를 적어 주세요."
        x := ExtOpt(r)
        if (x.mode = "between") {
            if (x.from = "pos" && !(IsInteger(x.fromN) && x.fromN >= 1))
                return "'몇 번째 글자부터'에 1 이상의 숫자를 적어 주세요."
            if (x.to = "end" && r.p2 = "")
                return "'마침어 바로 앞까지'를 골랐으면 마침어를 적어 주세요."
            if (x.to = "pos") {
                if !(IsInteger(x.toN) && x.toN >= 1)
                    return "'몇 번째 글자까지'에 1 이상의 숫자를 적어 주세요."
                if (x.from = "pos" && Integer(x.toN) < Integer(x.fromN))
                    return "끝 글자 번호가 시작 글자 번호보다 작아요."
            }
            return ""
        }
        if (r.p2 = "" && r.p3 = "")
            return "마침어나 총 글자수 중 하나는 꼭 적어 주세요."
        if (r.p3 != "" && (r.p3 < StrLen(r.p1) || r.p3 < StrLen(r.p2)))
            return "총 글자수가 시작어·마침어보다 짧아요. (공백 포함해서 세 주세요)"
        return ""
    }

    DoTest(*) {
        r := Collect()
        if (err := Check(r)) {
            res.Value := err
            return
        }
        hwnd := WinExist("ahk_exe chrome.exe")
        if !hwnd {
            res.Value := "열려 있는 크롬 창이 없어요."
            return
        }
        res.Value := "찾는 중…"
        c := ExtractOnce(r, hwnd)
        res.Value := (c = "") ? "못 찾았어요. 조건(글자수·띄어쓰기)이나 화면을 확인해 주세요." : "찾음: " c
    }

    DoOK(*) {
        r := Collect()
        if (err := Check(r)) {
            dlg.Opt("+OwnDialogs")
            MsgBox(err)
            return
        }
        SetEdit(false)
        dlg.Destroy()
        onOK(r)
    }
}

; 목록에 보여 줄 추출 조건 설명
ExtractDesc(s) {
    o := ExtOpt(s)
    if (o.mode = "between") {
        t := "'" s.p1 "' 뒤 " (o.from = "pos" ? o.fromN "번째 글자" : "첫 숫자") "부터 ~ "
        t .= (o.to = "num") ? "숫자 끝" : (o.to = "pos") ? o.toN "번째 글자" : "'" s.p2 "' 앞"
        if (o.to != "end" && s.p2 != "")
            t .= " ('" s.p2 "' 전까지만)"
    } else {
        t := "'" s.p1 "' ~ '" (s.p2 = "" ? "(아무거나)" : s.p2) "'"
        t .= (s.p3 = "") ? " · 길이 자유" : " · " s.p3 "글자"
    }
    if (s.p4 != "" && s.p4 != 1)
        t .= " · " s.p4 "번째"
    if (s.p5 = "digits")
        t .= " · 숫자만"
    else if (o.comma = "drop")
        t .= " · 쉼표 빼고"
    return t " → 클립보드"
}

; 조건대로 한 번 찾아보기. 찾으면 글, 못 찾으면 ""
ExtractOnce(s, hwnd) {
    o := ExtOpt(s)
    k := IsInteger(s.p4) && s.p4 > 0 ? Integer(s.p4) : 1
    T := GetScreenText(hwnd)
    if (o.mode = "between") {
        c := FindBetween(T, s.p1, s.p2, o, k)
    } else {
        n := (s.p3 = "") ? 0 : Integer(s.p3)
        c := FindMatch(T, s.p1, s.p2, n, k)
    }
    if (c != "") {
        if (s.p5 = "digits")
            c := RegExReplace(c, "\D")
        else if (o.comma = "drop")
            c := StrReplace(c, ",")
    }
    return c
}

; 크롬 창에 보이는 글 전부 읽어 오기 (페이지 글 + 입력칸에 들어 있는 글)
GetScreenText(hwnd) {
    root := 0
    try root := UIA.ElementFromHandle(hwnd)
    if !root
        return ""
    txt := ""
    ; 1) 페이지 전체 글을 통째로 (띄어쓰기·줄바꿈이 화면 그대로라 가장 정확)
    try {
        for doc in root.FindElements({Type: "Document"})
            try txt .= doc.TextPattern.DocumentRange.GetText(-1) "`n"
    }
    ; 2) 위 방법이 안 되면 글자 요소를 하나씩 모으기
    if (Trim(txt, " `t`r`n") = "") {
        try {
            for el in root.FindElements({Type: "Text"})
                try txt .= el.Name "`n"
        }
    }
    ; 3) 입력칸에 들어 있는 값도 같이
    try {
        for el in root.FindElements({Type: "Edit"})
            try txt .= el.Value "`n"
    }
    return NormText(txt)
}

; 웹 글의 특수 공백을 보통 공백으로 맞추기 (글자수 셀 때 헷갈리지 않게)
NormText(t) {
    t := StrReplace(t, "`r`n", "`n")
    t := StrReplace(t, "`r", "`n")
    t := StrReplace(t, Chr(0xA0), " ")      ; 줄바꿈 없는 공백(&nbsp;)
    t := StrReplace(t, Chr(0x3000), " ")    ; 전각 공백
    t := StrReplace(t, "`t", " ")
    t := StrReplace(t, Chr(0x200B), "")     ; 폭 없는 공백
    t := StrReplace(t, Chr(0xFEFF), "")
    t := StrReplace(t, Chr(0xFFFC), "`n")   ; 그림·버튼 같은 개체 자리
    return t
}

; 시작어로 시작하고 마침어로 끝나는 부분 찾기 (줄바꿈은 넘지 않음)
;   n  : 총 글자수 (공백 포함, 0 이면 상관없음 → 가장 가까운 마침어까지)
;   nth: 몇 번째 결과
FindMatch(T, st, en, n := 0, nth := 1) {
    cnt := 0, pos := 1
    while (i := InStr(T, st, true, pos)) {
        pos := i + 1
        if n {
            c := SubStr(T, i, n)
            if (StrLen(c) != n || InStr(c, "`n"))
                continue
            if (en != "" && SubStr(c, -StrLen(en)) !== en)
                continue
        } else {
            j := InStr(T, en, true, i + StrLen(st))
            if !j
                continue
            c := SubStr(T, i, j + StrLen(en) - i)
            if (InStr(c, "`n") || StrLen(c) > 300)
                continue
        }
        if (++cnt >= nth)
            return c
    }
    return ""
}

; 시작어 뒤에서 일부만 꺼내기 (시작어·마침어는 빼고, 줄바꿈은 넘지 않음)
;   시작어 바로 뒤 글자가 1번째. 마침어를 적었으면 그 앞까지만 살펴봄
FindBetween(T, st, en, o, nth := 1) {
    cnt := 0, pos := 1
    fromN := IsInteger(o.fromN) ? Integer(o.fromN) : 1
    toN := IsInteger(o.toN) ? Integer(o.toN) : 0
    while (i := InStr(T, st, true, pos)) {
        pos := i + 1
        a := i + StrLen(st)                          ; 시작어 바로 뒤
        lineEnd := InStr(T, "`n", true, a)
        rest := SubStr(T, a, (lineEnd ? lineEnd : StrLen(T) + 1) - a)
        rest := SubStr(rest, 1, 300)
        if (en != "") {
            j := InStr(rest, en, true)
            if !j
                continue
            rest := SubStr(rest, 1, j - 1)           ; 마침어 앞까지만
        }
        ; 어디부터
        if (o.from = "pos") {
            p := fromN
        } else {
            p := RegExMatch(rest, "\d")
            if !p
                continue
        }
        if (p < 1 || p > StrLen(rest))
            continue
        ; 어디까지
        switch o.to {
            case "num":     ; 숫자가 끝나는 곳까지 (2,502 / 1.5 처럼 쉼표·점 포함)
                if !RegExMatch(SubStr(rest, p), "^\D*?\d(?:[\d,.]*\d)?", &m)
                    continue
                c := m[0]
            case "pos":
                if (toN < p || toN > StrLen(rest))
                    continue
                c := SubStr(rest, p, toN - p + 1)
            default:        ; 마침어 바로 앞까지
                c := SubStr(rest, p)
        }
        c := Trim(c, " ")
        if (c = "")
            continue
        if (++cnt >= nth)
            return c
    }
    return ""
}

; ---- 키보드 키 (버튼: 직접 누르거나 목록에서 고르기) ----
AddKeyStep(*) {
    MainGui.Opt("+OwnDialogs")
    mi := NeedMacro()
    if !mi
        return
    KeyDialog("{Enter}", (keys) => (
        AddStep(mi, {action: "key", p1: keys, p2: "", p3: "", p4: "", p5: ""}),
        ShowTip("추가됨: 키보드 → " KeyPretty(keys))))
}

; 보낼 키 고르는 창 (추가할 때 / 더블클릭으로 고칠 때 같이 씀)
; onOK(키) 를 저장 버튼 누를 때 불러 줌
KeyDialog(init, onOK, owner := 0) {
    dlg := Gui("+AlwaysOnTop +Owner" (owner ? owner.Hwnd : MainGui.Hwnd), "키보드 키")
    dlg.SetFont("s10", "맑은 고딕")
    dlg.AddText("w290", "보낼 키를 정해 주세요. 지금 커서가 있는 곳(크롬 창)에 보내져요.`n"
        . "[직접 눌러서 넣기]를 누른 뒤 키보드에서 아무 키나 누르면 돼요.`n"
        . "(Ctrl·Shift·Alt·Win 조합도 그대로 눌러 주세요)")
    cb := dlg.AddComboBox("w210", KEY_LIST)
    cb.Text := init
    dlg.AddButton("x+5 w75", "키 목록").OnEvent("Click", (*) => ShowKeyList(cb, dlg, UpdLbl))
    b1 := dlg.AddButton("xm w142", "직접 눌러서 넣기")
    b2 := dlg.AddButton("x+6 w142", "눌러서 뒤에 붙이기")
    lbl := dlg.AddText("xm w290 cBlue", "")
    b1.OnEvent("Click", (*) => CaptureKey(cb, b1, false, lbl))
    b2.OnEvent("Click", (*) => CaptureKey(cb, b2, true, lbl))
    cb.OnEvent("Change", (*) => UpdLbl())
    dlg.AddButton("xm w142 Default", "저장").OnEvent("Click", DoOK)
    dlg.AddButton("x+6 w142", "취소").OnEvent("Click", (*) => (StopCapture(), SetEdit(false), dlg.Destroy()))
    dlg.OnEvent("Close", (*) => (StopCapture(), SetEdit(false)))
    UpdLbl()
    SetEdit(true)
    dlg.Show()

    UpdLbl() {
        lbl.Text := "= " KeyPretty(Trim(cb.Text))
    }

    DoOK(*) {
        keys := Trim(cb.Text)
        if (keys = "") {
            dlg.Opt("+OwnDialogs")
            MsgBox("보낼 키를 골라 주세요.")
            return
        }
        StopCapture()
        SetEdit(false)
        dlg.Destroy()
        onOK(keys)
    }
}

; ---- 키 직접 누르기: 키보드에서 누른 키(조합 포함)를 그대로 받아 오기 ----
; append = true 면 기존 내용 뒤에 붙임
CaptureKey(cb, btn, append, lbl) {
    global CapHook
    if (IsObject(CapHook) && CapHook.InProgress)
        return
    st := {result: "", solo: "", held: Map()}   ; result: 받아 온 키 / solo: 조합키만 눌렀을 때
    oldText := btn.Text
    btn.Text := "키를 누르세요… (10초)"
    ih := InputHook("T10")
    ih.KeyOpt("{All}", "NS")      ; 모든 키를 알림 받고, 다른 프로그램엔 안 가게 막음
    ih.OnKeyDown := Down
    ih.OnKeyUp := Up
    ih.OnEnd := Finish
    CapHook := ih
    ih.Start()

    Down(ih, vk, sc) {
        name := KeyNameOf(vk, sc)
        if MOD_SIGN.Has(name) {       ; Ctrl·Shift·Alt·Win 은 누르고 있는 것만 기억
            st.held[name] := true
            if (st.result = "")
                st.solo := name
            return
        }
        st.solo := ""
        if (st.result = "")
            st.result := ModPrefix(st.held) WrapKey(name)
    }

    Up(ih, vk, sc) {
        name := KeyNameOf(vk, sc)
        if MOD_SIGN.Has(name) {
            if st.held.Has(name)
                st.held.Delete(name)
            ; 조합키만 눌렀다 뗐으면 그 키 자체를 등록 (예: Alt 한 번)
            if (st.result = "" && st.solo = name)
                st.result := ModPrefix(st.held) "{" SoloName(name) "}"
        }
        ; 다 떼고 나면 끝 (손 뗄 때까지 막아서 창에 키가 새지 않게)
        if (st.result != "" && st.held.Count = 0)
            ih.Stop()
    }

    Finish(ih) {
        try btn.Text := oldText
        if (st.result = "") {
            if (ih.EndReason = "Stopped")   ; 창을 닫아서 멈춘 거면 조용히 끝
                return
            ShowTip("아무 키도 받지 못했어요. 다시 눌러 주세요.")
            return
        }
        try {
            cb.Text := append ? Trim(cb.Text) st.result : st.result
            lbl.Text := "= " KeyPretty(Trim(cb.Text))
        }
    }
}

StopCapture() {
    global CapHook
    if (IsObject(CapHook) && CapHook.InProgress)
        CapHook.Stop()
}

; vk·sc 로 키 이름 알아내기 (이름이 없는 키는 vk코드로)
KeyNameOf(vk, sc) {
    name := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
    if (name = "")
        name := GetKeyName(Format("vk{:x}", vk))
    if (name = "" || vk = 0x15 || vk = 0x19)   ; 한/영, 한자 키는 vk코드로 저장
        name := Format("vk{:X}", vk)
    return name
}

; 누르고 있는 조합키 → ^ ! + # (순서 고정, 중복 제거)
ModPrefix(held) {
    out := ""
    for sign in ["^", "!", "+", "#"] {
        for name in held {
            if (MOD_SIGN[name] = sign) {
                out .= sign
                break
            }
        }
    }
    return out
}

; 조합키를 단독으로 보낼 때 이름
SoloName(name) {
    base := RegExReplace(name, "^[LR](?=Control|Shift|Alt|Win)")   ; LControl → Control
    return base = "Control" ? "Ctrl" : base = "Win" ? "LWin" : base
}

; 영문·숫자 한 글자는 그대로, 나머지는 {} 로 감싸기
WrapKey(name) {
    if (StrLen(name) = 1 && RegExMatch(name, "^[a-z0-9]$"))
        return name
    return "{" name "}"
}

; 보낼 키를 사람이 읽기 쉽게 (예: ^+{Tab} → Ctrl+Shift+Tab)
KeyPretty(keys) {
    out := "", mods := "", i := 1, n := StrLen(keys)
    while (i <= n) {
        c := SubStr(keys, i, 1)
        if (i < n && InStr("^+!#", c)) {
            mods .= (c = "^") ? "Ctrl+" : (c = "+") ? "Shift+" : (c = "!") ? "Alt+" : "Win+"
            i += 1
            continue
        }
        if (c = "{") {
            j := InStr(keys, "}", , i + 2)
            if !j
                j := n + 1
            k := SubStr(keys, i + 1, j - i - 1)
            i := j + 1
        } else {
            k := c, i += 1
        }
        rep := ""
        if RegExMatch(k, "^(\S+) (\d+)$", &m)    ; {Tab 3} → Tab ×3
            k := m[1], rep := " ×" m[2]
        if KEY_KOR.Has(k)
            k := KEY_KOR[k]
        else if (StrLen(k) = 1)
            k := StrUpper(k)
        out .= (out = "" ? "" : ", ") mods k rep
        mods := ""
    }
    return out = "" ? keys : out
}

ShowKeyList(cb, owner, onPick := 0) {
    kg := Gui("+AlwaysOnTop +Owner" owner.Hwnd, "키 목록")
    kg.SetFont("s10", "맑은 고딕")
    kg.AddText("w430", "더블클릭하면 바로 들어가요.`n조합 기호:  ^ = Ctrl    + = Shift    ! = Alt    # = Win")
    lv := kg.AddListView("w430 r18 -Multi", ["분류", "입력값", "설명"])
    for row in KEY_HELP
        lv.Add(, row[1], row[2], row[3])
    lv.ModifyCol(1, 65), lv.ModifyCol(2, 120), lv.ModifyCol(3, 220)
    lv.OnEvent("DoubleClick", (l, r) => r ? Pick("replace") : 0)
    kg.AddButton("w210", "이 키로 바꾸기").OnEvent("Click", (*) => Pick("replace"))
    kg.AddButton("x+10 w210", "뒤에 이어 붙이기").OnEvent("Click", (*) => Pick("append"))
    kg.Show()

    Pick(mode) {
        r := lv.GetNext()
        if !r {
            kg.Opt("+OwnDialogs")
            MsgBox("목록에서 키를 먼저 선택해 주세요.")
            return
        }
        val := lv.GetText(r, 2)
        cb.Text := (mode = "append") ? cb.Text val : val
        if onPick                     ; 아래 설명 글도 바로 바뀌게
            onPick()
        kg.Destroy()
    }
}

; 요소에 들어 있는 글자 읽기 (입력칸은 입력된 값, 그 외는 보이는 글자)
ReadText(el) {
    txt := ""
    try txt := el.Value
    if (txt = "") {
        t := 0
        try t := el.Type
        if (t != 50004)
            try txt := el.Name
    }
    return Trim(txt)
}

; 마우스 아래 요소에서 위로 올라가며 이름 있는 클릭 대상을 찾는다
FindTarget(el, allowText := false) {
    Loop 6 {
        if !el
            return 0
        t := 0, n := ""
        try t := el.Type
        try n := el.Name
        if (t = 50030 || t = 50032)
            return 0
        if (n != "" && (HasVal(CLICKABLE, t) || (allowText && t = 50020)))
            return el
        try el := el.Parent
        catch
            return 0
    }
    return 0
}

; ============================================================
;  입력칸 찾기: 칸 위쪽 '라벨 글자'를 기준으로 (좌표 안 씀)
;  - 화면 구조가 [라벨 글자] 바로 아래 [입력칸] 이라서 칸 자체에는 이름이 없을 때 쓰는 방식
;  - 등록할 때: 칸 앞(위)쪽에서 가장 가까운 글자(Text)를 라벨로 정함
;  - 실행할 때: 그 라벨 글자를 찾고, 같은 덩어리 안에서 라벨 '다음에 나오는 첫 입력칸'을 잡음
;  - 같은 라벨이 여러 개면 등록할 때 몇 번째였는지(n)를 기억해서 같은 순서의 것을 잡음
;  - 라벨을 못 찾으면 예전처럼 칸 이름으로 등록 (이름도 없으면 등록 불가)
; ============================================================

; 입력칸 종류: Edit(글 쓰는 칸) / ComboBox(드롭다운)
IsInputType(t) => (t = 50004 || t = 50003)

; 마우스 아래 요소에서 입력칸 찾기 (칸 안쪽을 눌렀어도 가장 바깥 입력칸을 돌려줌)
FindInput(el) {
    best := 0
    Loop 4 {
        if !el
            break
        t := 0
        try t := el.Type
        if IsInputType(t)
            best := el
        else if best
            break
        try el := el.Parent
        catch
            break
    }
    return best
}

; 라벨로 쓸 만한 글인지 (비었거나 * : 같은 기호뿐이거나 너무 긴 글은 제외)
IsLabelText(n) {
    s := Trim(n)
    return (s != "" && StrLen(s) <= 80 && !RegExMatch(s, "^[\s*:：.()\[\]\-・·•]+$"))
}

; 요소 목록 안에서 같은 요소가 몇 번째인지 (없으면 0)
IndexInList(list, el) {
    id := ""
    try id := el.RuntimeId
    if (id = "")
        return 0
    for i, x in list {
        rid := ""
        try rid := x.RuntimeId
        if (rid = id)
            return i
    }
    return 0
}

; 어떤 덩어리 안의 모든 하위 요소를 화면 구조(트리) 순서대로. 너무 크면 빈 목록
NearbyElements(el) {
    all := []
    try all := el.FindAll(UIA.TrueCondition)
    return (all.Length > 600) ? [] : all
}

; 입력칸 바로 앞(위)에 있는 라벨 글자 찾기
;  칸의 부모 → 조부모… 로 올라가며(최대 3단계), 같은 덩어리 안에서 칸 앞쪽의 가장 가까운 글자(Text)를 돌려줌
;  글자보다 먼저 다른 입력칸이 나오면 그건 다른 칸의 라벨이라서 포기("")
FindLabelFor(inp) {
    el := inp
    Loop 3 {
        try el := el.Parent
        catch
            return ""
        all := NearbyElements(el)
        pos := IndexInList(all, inp)
        if !pos
            continue
        i := pos - 1
        while (i >= 1) {
            x := all[i]
            t := 0, n := ""
            try t := x.Type
            try n := x.Name
            if IsInputType(t)
                return ""
            if (t = 50020 && IsLabelText(n))
                return n
            i--
        }
    }
    return ""
}

; 라벨 글자 다음에 나오는 첫 입력칸 찾기 (같은 덩어리 안에서, 최대 3단계 위까지)
NextInputAfter(L) {
    el := L
    Loop 3 {
        try el := el.Parent
        catch
            return 0
        all := NearbyElements(el)
        pos := IndexInList(all, L)
        if !pos
            continue
        i := pos + 1
        while (i <= all.Length) {
            x := all[i]
            t := 0
            try t := x.Type
            if IsInputType(t)
                return x
            i++
        }
    }
    return 0
}

; 화면에서 그 라벨 글자의 '아래 칸'들을 화면 순서대로 모두 찾기 (같은 칸이 겹치면 한 번만)
LabelInputs(root, lbl) {
    out := [], seen := Map()
    labels := []
    try labels := root.FindElements({Type: "Text", Name: lbl})
    for L in labels {
        inp := NextInputAfter(L)
        if !inp
            continue
        id := ""
        try id := inp.RuntimeId
        if (id = "" || seen.Has(id))
            continue
        seen[id] := true
        out.Push(inp)
    }
    return out
}

; 등록할 때: 이 칸의 라벨을 정하고, 그 라벨로 다시 찾았을 때 같은 칸이 나오는지 확인
; 돌려주는 값: {label, n(같은 라벨 중 몇 번째)} 또는 0
LabelAnchor(inp, win) {
    lbl := FindLabelFor(inp)
    if (lbl = "")
        return 0
    root := UIA.ElementFromHandle(win)
    n := IndexInList(LabelInputs(root, lbl), inp)
    return n ? {label: lbl, n: n} : 0
}

; 화면 대상 동작의 찾기 옵션 (p7: "by=label;n=2")
ElemOpt(s) {
    o := {by: "", n: 1}
    for part in StrSplit(P(s, "p7"), ";") {
        kv := StrSplit(part, "=", , 2)
        if (kv.Length = 2) {
            if (kv[1] = "by")
                o.by := kv[2]
            else if (kv[1] = "n" && IsInteger(kv[2]) && kv[2] >= 1)
                o.n := Integer(kv[2])
        }
    }
    return o
}

; ---- 크롬 창 이동 (버튼: 목록에서 고르기) ----
AddWindowStep(*) {
    MainGui.Opt("+OwnDialogs")
    mi := NeedMacro()
    if !mi
        return
    titles := []
    for h in WinGetList("ahk_exe chrome.exe") {
        t := WinGetTitle(h)
        if (t != "")
            titles.Push(RegExReplace(t, " - (Google Chrome|Chrome)$"))
    }
    dlg := Gui("+AlwaysOnTop +Owner" MainGui.Hwnd, "크롬 창 이동 추가")
    dlg.SetFont("s10", "맑은 고딕")
    dlg.AddText("w340", "찾을 창·탭 이름 (일부만 적어도 돼요, 예: Zendesk)`n지금 열린 크롬 창 제목을 목록에서 고를 수도 있어요.")
    cb := dlg.AddComboBox("w340", titles)
    dlg.AddButton("w167 Default", "추가").OnEvent("Click", DoAdd)
    dlg.AddButton("x+6 w167", "취소").OnEvent("Click", (*) => (SetEdit(false), dlg.Destroy()))
    dlg.OnEvent("Close", (*) => SetEdit(false))
    SetEdit(true)
    dlg.Show()

    DoAdd(*) {
        kw := Trim(cb.Text)
        if (kw = "") {
            MsgBox("찾을 창·탭 이름을 적어 주세요.")
            return
        }
        SetEdit(false)
        dlg.Destroy()
        AddStep(mi, {action: "window", p1: kw, p2: "", p3: "", p4: "", p5: ""})
    }
}

; ---- 기다리기 (버튼: 시간 직접 입력) ----
AddWaitStep(*) {
    MainGui.Opt("+OwnDialogs")
    mi := NeedMacro()
    if !mi
        return
    v := AskWaitMs("1000")
    if (v = "")
        return
    AddStep(mi, {action: "wait", p1: v, p2: "", p3: "", p4: "", p5: ""})
}

AskWaitMs(def) {
    SetEdit(true)
    ib := InputBox("몇 밀리초 기다릴까요?  (1000 = 1초)", "기다리기", "w300 h120", def)
    SetEdit(false)
    if (ib.Result != "OK")
        return ""
    v := Trim(ib.Value)
    if (!IsInteger(v) || v < 0) {
        MsgBox("0 이상의 숫자만 적어 주세요.")
        return ""
    }
    return v
}

; ---- 동작 더블클릭: 동작 종류 · 대상 이름 · 내용 · 메모를 한 창에서 수정 ----
; 저장을 누르기 전까지는 복사본(t)만 바뀌고 원본은 그대로
EditStep(si) {
    mi := CurMacro()
    if (!mi || StepDlgOpen)
        return
    s := Macros[mi].steps[si]
    t := CopyStep(s)
    isElem := HasVal(ELEM_ACTIONS, t.action)

    dlg := Gui("+AlwaysOnTop +Owner" MainGui.Hwnd, si "번 동작 수정")
    dlg.SetFont("s10", "맑은 고딕")

    ; 동작 종류
    dlg.AddText("xm w60", "동작")
    names := []
    if isElem {
        for a in ELEM_ACTIONS
            names.Push(ACTION_NAME[a])
    } else {
        names.Push(ActName(t.action))
    }
    dd := dlg.AddDropDownList("x+5 yp-3 w170", names)
    dd.Value := isElem ? IndexOf(ELEM_ACTIONS, t.action) : 1
    if isElem {
        dlg.AddText("x+8 yp+3 w170 cGray", "같은 대상으로 종류만 바꿔요")
    } else {
        dd.Enabled := false
        dlg.AddText("x+8 yp+3 w170 cGray", "이 동작은 종류 변경 불가")
    }
    dd.OnEvent("Change", ChangeAction)

    ; 현재 내용
    dlg.AddText("xm y+14 w60", "내용")
    desc := dlg.AddEdit("x+5 yp-3 w350 r2 ReadOnly -VScroll", StepDesc(t))
    btnTarget := 0
    if isElem {
        btnTarget := dlg.AddButton("xm+65 y+5 w172", "대상 이름 수정…")
        btnTarget.OnEvent("Click", EditTarget)
        btnContent := dlg.AddButton("x+6 w172", "내용 수정…")
    } else {
        btnContent := dlg.AddButton("xm+65 y+5 w350", "내용 수정…")
    }
    btnContent.OnEvent("Click", EditContent)
    UpdButtons()

    ; 메모
    dlg.AddText("xm y+14 w60", "메모")
    memo := dlg.AddEdit("x+5 yp-3 w350 r3", P(t, "p6"))
    dlg.AddText("xm+65 w350 cGray", "어떤 동작인지 알아보기 쉽게 적어 두세요. (실행 중 안내에도 보여요)")

    dlg.AddButton("xm w207 Default", "저장").OnEvent("Click", DoSave)
    dlg.AddButton("x+6 w207", "취소").OnEvent("Click", (*) => Close())
    dlg.OnEvent("Close", (*) => Close())
    dlg.OnEvent("Escape", (*) => Close())
    SetStepDlg(true)
    dlg.Show()
    memo.Focus()

    Upd() {
        try desc.Value := StepDesc(t)
        UpdButtons()
    }

    ; 내용 수정 버튼은 고칠 내용이 있는 동작에서만 켜기
    UpdButtons() {
        btnContent.Enabled := !isElem || t.action = "paste" || t.action = "type"
        btnContent.Text := (t.action = "paste") ? "붙여넣을 내용 수정…"
            : (t.action = "type") ? "입력할 글 수정…"
            : isElem ? "(고칠 내용 없음)" : "내용 수정…"
    }

    ChangeAction(*) {
        na := ELEM_ACTIONS[dd.Value]
        old := t.action
        if (na = old)
            return
        ; 붙여넣기 글 ↔ 텍스트입력 글은 서로 넘겨줌
        txt := (old = "type" || (old = "paste" && t.p4 = "text")) ? t.p5 : ""
        t.action := na
        if (na = "type")
            t.p4 := "", t.p5 := txt
        else if (na = "paste")
            t.p4 := (txt != "") ? "text" : "clip", t.p5 := txt
        else
            t.p4 := "", t.p5 := ""
        Upd()
        if (na = "type" && t.p5 = "")      ; 텍스트입력은 넣을 글이 꼭 있어야 함
            EditContent()
    }

    EditTarget(*) {
        dlg.Opt("+OwnDialogs")
        byLbl := (ElemOpt(t).by = "label")
        msg := byLbl
            ? "칸 위에 보이는 라벨 글자예요. (이 글자 바로 아래 칸을 찾아요)`n라벨 글자가 조금 바뀌었을 때 고쳐 주세요.  (정확히 같아야 찾아요)"
            : "화면에서 찾을 대상의 이름이에요.`n버튼·칸 이름이 조금 바뀌었을 때 고쳐 주세요.  (정확히 같아야 찾아요)"
        ib := InputBox(msg, byLbl ? "라벨 글자" : "대상 이름", "w380 h150", t.p1)
        if (ib.Result = "OK" && Trim(ib.Value) != "")
            t.p1 := Trim(ib.Value)
        Upd()
    }

    EditContent(*) {
        dlg.Opt("+OwnDialogs")
        switch t.action {
            case "wait":
                v := AskWaitMs(t.p1)
                if (v != "")
                    t.p1 := v
            case "window":
                ib := InputBox("찾을 창·탭 이름 (일부만 적어도 돼요)", "크롬 창 이동", "w340 h120", t.p1)
                if (ib.Result = "OK" && Trim(ib.Value) != "")
                    t.p1 := Trim(ib.Value)
            case "key":
                KeyDialog(t.p1, (k) => (t.p1 := k, Upd()), dlg)
            case "extract":
                ExtractDialog(t, (r) => (t.p1 := r.p1, t.p2 := r.p2, t.p3 := r.p3
                    , t.p4 := r.p4, t.p5 := r.p5, t.p7 := r.p7, Upd()), dlg)
            case "type":
                TypeDialog(TName(t), t.p5, t.p4 = "clear", (x, c) => (
                    t.p4 := c ? "clear" : "", t.p5 := x, Upd()), dlg)
            case "paste":
                PasteDialog(TName(t), t.p4 = "text", t.p5, (u, x) => (
                    t.p4 := u ? "text" : "clip", t.p5 := u ? x : "", Upd()), dlg)
        }
        Upd()
    }

    DoSave(*) {
        if (t.action = "type" && t.p5 = "") {
            dlg.Opt("+OwnDialogs")
            MsgBox("텍스트입력은 넣을 글이 필요해요. [입력할 글 수정…]에서 적어 주세요.")
            return
        }
        t.p6 := Trim(memo.Value, " `t`r`n")
        for k in ["action", "p1", "p2", "p3", "p4", "p5", "p6", "p7"]
            s.%k% := t.%k%
        SaveAll()
        Close()
        RefreshSteps(si)
    }

    Close() {
        SetStepDlg(false)
        try dlg.Destroy()
    }
}

; ---- 순서 바꾸기 / 삭제 / 테스트 ----
MoveStep(dir) {
    MainGui.Opt("+OwnDialogs")
    mi := NeedMacro()
    if !mi
        return
    si := StepLV.GetNext()
    if !si {
        MsgBox("옮길 동작을 오른쪽에서 먼저 선택해 주세요.")
        return
    }
    steps := Macros[mi].steps
    ni := si + dir
    if (ni < 1 || ni > steps.Length)
        return
    tmp := steps[si], steps[si] := steps[ni], steps[ni] := tmp
    SaveAll()
    RefreshSteps(ni)
}

DeleteStep(*) {
    MainGui.Opt("+OwnDialogs")
    mi := NeedMacro()
    if !mi
        return
    si := StepLV.GetNext()
    if !si {
        MsgBox("삭제할 동작을 오른쪽에서 먼저 선택해 주세요.")
        return
    }
    steps := Macros[mi].steps
    steps.RemoveAt(si)
    SaveAll()
    RefreshSteps(steps.Length ? Min(si, steps.Length) : 0)
}

TestStep(*) {
    MainGui.Opt("+OwnDialogs")
    mi := NeedMacro()
    if !mi
        return
    si := StepLV.GetNext()
    if !si {
        MsgBox("테스트할 동작을 오른쪽에서 먼저 선택해 주세요.")
        return
    }
    s := Macros[mi].steps[si]
    hwnd := WinExist("ahk_exe chrome.exe")
    ok := false
    deadline := A_TickCount + 3000
    Loop {
        if TryStep(s, &hwnd) {
            ok := true
            break
        }
        if (A_TickCount > deadline)
            break
        Sleep(300)
    }
    if ok
        ShowTip("성공: " ActName(s.action) " " StepDesc(s)
            . (s.action = "extract" ? "`n복사됨: " A_Clipboard : ""), 2500)
    else
        MsgBox("실패: " ActName(s.action) " " StepDesc(s) "`n그 대상이 지금 화면에 보이는지 확인해 주세요.")
}

; ============================================================
;  실행
; ============================================================
RunSelectedMacro(*) {
    MainGui.Opt("+OwnDialogs")
    mi := NeedMacro()
    if mi
        RunMacro(mi)
}

RunMacro(mi, *) {
    global Running, StopFlag
    if Running
        return
    m := Macros[mi]
    if (m.steps.Length = 0) {
        ShowTip("'" m.name "'에 아직 동작이 없어요.")
        return
    }
    Running := true, StopFlag := false
    Hotkey("$Esc", StopRun, "On")
    hwnd := WinExist("ahk_exe chrome.exe")
    ok := true
    prevClick := 0
    for si, s in m.steps {
        ; 성공할 때까지 기다림. Esc를 누르면 false가 돌아와서 멈춤
        if !RunStepUntil(s, &hwnd, prevClick, m.name "  (" si "/" m.steps.Length ")") {
            ok := false
            ShowTip("중단됨: " m.name " (" si "번째 동작)")
            break
        }
        ; 바로 앞 클릭을 기억해 둠 (기다리기는 건너뛰고 그 앞의 클릭을 유지)
        if (s.action = "left" || s.action = "right")
            prevClick := s
        else if (s.action != "wait")
            prevClick := 0
        Sleep(250)
    }
    try Hotkey("$Esc", "Off")
    Running := false
    if ok
        ShowTip("완료: " m.name)
}

StopRun(*) {
    global StopFlag
    StopFlag := true
}

; 실행 중 안내에 보여 줄 한 줄 (메모가 있으면 같이)
StepLabel(s) {
    t := ActName(s.action) " " StepDesc(s)
    if (P(s, "p6") != "")
        t .= "`n메모: " Short(P(s, "p6"))
    return t
}

; 동작 하나를 성공할 때까지 계속 시도. Esc로 멈추면 false
; 앞 클릭이 반응하지 않아 다음 대상이 안 나타나면, 옵션에 따라 앞 클릭을 다시 누름
RunStepUntil(s, &hwnd, prevClick, title) {
    start := A_TickCount
    lastRetry := A_TickCount
    ToolTip(title "`n" StepLabel(s))
    Loop {
        if StopFlag
            return false
        if TryStep(s, &hwnd)
            return true
        waited := (A_TickCount - start) // 1000
        ToolTip(title "`n대기 중: " StepLabel(s) "  (" waited "초)`n멈추려면 Esc")
        if (RetryOn && IsObject(prevClick) && A_TickCount - lastRetry >= 5000) {
            lastRetry := A_TickCount
            ReClick(prevClick, hwnd)
        }
        Sleep(500)
    }
}

; 앞 클릭 대상이 화면에 그대로 있으면(=화면이 안 바뀜) 한 번 더 누른다
ReClick(prev, hwnd) {
    if (!hwnd || !WinExist(hwnd))
        return
    el := FindStepElement(prev, hwnd)
    if el
        ClickElement(el, hwnd, prev.action)
}

; 동작이 가리키는 화면 요소 찾기
;  · 라벨 기준(p7에 by=label): 라벨 글자 다음에 나오는 입력칸을 n번째로 잡음 (좌표 안 씀)
;  · 그 외: 종류 + 이름으로 찾음
FindStepElement(s, hwnd) {
    el := 0
    try {
        root := UIA.ElementFromHandle(hwnd)
        o := ElemOpt(s)
        if (o.by = "label") {
            list := LabelInputs(root, s.p1)
            if (list.Length >= o.n)
                el := list[o.n]
        } else {
            el := root.FindElement({Type: Integer(s.p2), Name: s.p1})
        }
    }
    return el
}

ClickElement(el, hwnd, action) {
    try {
        if (action = "right") {
            MouseClickOn(el, hwnd, "Right")
        } else {
            try el.Click()                      ; 마우스 안 움직이고 누르기
            catch
                MouseClickOn(el, hwnd, "Left")  ; 안 되면 실제 마우스로 누르기
        }
        return true
    } catch {
        return false
    }
}

SetRetry(v) {
    global RetryOn
    RetryOn := v
    SaveAll()
}

SetMemoAsk(v) {
    global MemoAsk
    MemoAsk := v
    SaveAll()
}

; 동작 하나를 한 번 시도. 성공하면 true, 아직 안 되면 false
; hwnd는 '지금 작업 중인 크롬 창'으로, 창 이동 동작이 바꿔 줌
TryStep(s, &hwnd) {
    switch s.action {
        case "wait":
            endTime := A_TickCount + Integer(s.p1)
            while (A_TickCount < endTime) {
                if StopFlag
                    return false
                Sleep(100)
            }
            return true

        case "window":
            h := FindChromeWindow(s.p1)
            if !h
                return false
            hwnd := h
            WinActivate(hwnd)
            WinWaitActive(hwnd, , 1)
            return true

        case "key":   ; 키보드 키: 작업 중인 크롬 창에 키 보내기
            if (!hwnd || !WinExist(hwnd))
                hwnd := WinExist("ahk_exe chrome.exe")
            if !hwnd
                return false
            WinActivate(hwnd)
            WinWaitActive(hwnd, , 1)
            Send(s.p1)
            return true

        case "extract":   ; 텍스트 추출: 화면 글에서 조건에 맞는 부분을 찾아 복사
            if (!hwnd || !WinExist(hwnd))
                hwnd := WinExist("ahk_exe chrome.exe")
            if !hwnd
                return false
            c := ExtractOnce(s, hwnd)
            if (c = "")               ; 아직 화면에 없으면 나타날 때까지 기다림
                return false
            A_Clipboard := c
            return true

        case "copy":
            if (!hwnd || !WinExist(hwnd))
                hwnd := WinExist("ahk_exe " s.p3)
            if !hwnd
                return false
            el := FindStepElement(s, hwnd)
            if !el
                return false
            txt := ReadText(el)
            if (txt = "")            ; 내용이 아직 비어 있으면 채워질 때까지 기다림
                return false
            A_Clipboard := txt
            return true

        case "paste":
            if (!hwnd || !WinExist(hwnd))
                hwnd := WinExist("ahk_exe " s.p3)
            if !hwnd
                return false
            el := FindStepElement(s, hwnd)
            if !el
                return false
            try MouseClickOn(el, hwnd, "Left")   ; 칸을 눌러서 커서를 넣고
            catch
                return false
            Sleep(150)
            if (P(s, "p4") = "text") {
                saved := ClipboardAll()             ; 복사해 둔 내용은 잠깐 보관
                A_Clipboard := P(s, "p5")
                Sleep(100)
                Send("^v")
                Sleep(300)
                A_Clipboard := saved                ; 원래 클립보드로 되돌림
            } else {
                Send("^v")
            }
            return true

        case "type":   ; 텍스트입력: 칸을 눌러 커서를 넣고 글을 직접 타이핑
            if (!hwnd || !WinExist(hwnd))
                hwnd := WinExist("ahk_exe " s.p3)
            if !hwnd
                return false
            el := FindStepElement(s, hwnd)
            if !el
                return false
            try MouseClickOn(el, hwnd, "Left")
            catch
                return false
            Sleep(150)
            if (P(s, "p4") = "clear") {             ; 칸에 있던 글 지우기
                Send("^a")
                Sleep(50)
                Send("{Delete}")
                Sleep(100)
            }
            SendText(P(s, "p5"))                    ; 클립보드는 건드리지 않음
            return true

        case "selectall":   ; 전체선택: 칸을 눌러 커서를 넣고 Ctrl+A
            if (!hwnd || !WinExist(hwnd))
                hwnd := WinExist("ahk_exe " s.p3)
            if !hwnd
                return false
            el := FindStepElement(s, hwnd)
            if !el
                return false
            try MouseClickOn(el, hwnd, "Left")
            catch
                return false
            Sleep(150)
            Send("^a")
            return true

        default:   ; left / right
            if (!hwnd || !WinExist(hwnd))
                hwnd := WinExist("ahk_exe " s.p3)
            if !hwnd
                return false
            el := FindStepElement(s, hwnd)
            if !el
                return false
            return ClickElement(el, hwnd, s.action)
    }
}

; 이름이 들어간 크롬 창을 찾고, 없으면 뒤쪽 탭까지 뒤져서 그 탭으로 전환
FindChromeWindow(kw) {
    SetTitleMatchMode(2)
    hwnd := WinExist(kw " ahk_exe chrome.exe")
    if hwnd
        return hwnd
    for h in WinGetList("ahk_exe chrome.exe") {
        try {
            tab := UIA.ElementFromHandle(h).FindElement({Type: "TabItem", Name: kw, mm: 2})
            WinActivate(h)
            WinWaitActive(h, , 1)
            tab.Click()
            Sleep(400)
            return h
        }
    }
    return 0
}

; 요소 한가운데를 실제 마우스로 클릭
MouseClickOn(el, hwnd, button) {
    WinActivate(hwnd)
    WinWaitActive(hwnd, , 1)
    loc := el.Location
    CoordMode("Mouse", "Screen")
    Click(Format("{} {} {}", Round(loc.x + loc.w / 2), Round(loc.y + loc.h / 2), button))
}

ShowTip(text, ms := 1500) {
    ToolTip(text)
    SetTimer(() => ToolTip(), -ms)
}

; ============================================================
;  단축키 등록
; ============================================================
RegisterAllHotkeys() {
    global Registered
    HotIf(HotkeyCondition)
    for k in Registered
        try Hotkey(k, "Off")
    Registered := []
    for i, m in Macros {
        if (m.hk = "")
            continue
        if IsReserved(m.hk) {
            MsgBox("'" m.name "'의 단축키 " m.hk "는 이제 동작 추가용 키라서 꺼졌어요.`n[단축키 설정]에서 다른 키로 바꿔 주세요.")
            continue
        }
        name := "$" m.hk
        try {
            Hotkey(name, RunMacro.Bind(i), "On")
            Registered.Push(name)
        } catch {
            MsgBox("단축키 등록 실패: " m.hk " (" m.name ")")
        }
    }
    HotIf()
}

; ============================================================
;  저장 / 불러오기 (macros.txt)
;  SETTING 줄: 설정값 (retry·memo)
;  CAT 줄: 분류 이름 (분류만 있고 매크로가 없어도 저장됨)
;  MACRO 줄: MACRO  이름  단축키  분류  ← 탭으로 구분 (분류 칸은 예전 파일에 없으면 분류 없음)
;  STEP 줄: STEP  동작  p1  p2  p3  p4  p5  p6(메모)  p7(추출 옵션 / 화면 대상 찾기 옵션)  ← 탭으로 구분
;  예전 파일(메모 칸·분류 칸·p7 칸 없음)도 그대로 읽힘
;  내보내기 파일·복사한 클립보드 글도 같은 형식 (SETTING 줄만 없음)
;  MACRO 줄 없이 STEP 줄만 있으면 (동작만 복사한 경우) 따로 모아 둠
; ============================================================
Clean(v) => StrReplace(StrReplace(StrReplace(String(v), "`t", " "), "`r", " "), "`n", " ")

; 줄바꿈이 있는 글(상용구·메모)도 한 줄로 저장했다가 되살리기
Enc(v) => StrReplace(StrReplace(StrReplace(StrReplace(String(v), "\", "\\"), "`r", ""), "`n", "\n"), "`t", "\t")

Dec(v) {
    out := "", i := 1, n := StrLen(v)
    while (i <= n) {
        c := SubStr(v, i, 1)
        if (c = "\" && i < n) {
            d := SubStr(v, i + 1, 1)
            out .= (d = "n") ? "`n" : (d = "t") ? "`t" : d
            i += 2
        } else {
            out .= c
            i += 1
        }
    }
    return out
}

; 동작 하나 → STEP 줄
StepLine(s) => "STEP`t" s.action "`t" Enc(P(s, "p1")) "`t" Enc(P(s, "p2")) "`t" Enc(P(s, "p3"))
    . "`t" Enc(P(s, "p4")) "`t" Enc(P(s, "p5")) "`t" Enc(P(s, "p6")) "`t" Enc(P(s, "p7")) "`n"

; STEP 줄을 나눈 칸 → 동작
StepFromFields(f) => {action: f[2], p1: Dec(f[3])
    , p2: f.Length >= 4 ? Dec(f[4]) : ""
    , p3: f.Length >= 5 ? Dec(f[5]) : ""
    , p4: f.Length >= 6 ? Dec(f[6]) : ""
    , p5: f.Length >= 7 ? Dec(f[7]) : ""
    , p6: f.Length >= 8 ? Dec(f[8]) : ""
    , p7: f.Length >= 9 ? Dec(f[9]) : ""}

; 매크로 목록 → CAT / MACRO / STEP 줄 (저장·내보내기·복사 같이 씀)
MacroLines(list, cats := []) {
    txt := ""
    for c in cats
        txt .= "CAT`t" Clean(c) "`n"
    for m in list {
        txt .= "MACRO`t" Clean(m.name) "`t" m.hk "`t" Clean(m.cat) "`n"
        for s in m.steps
            txt .= StepLine(s)
    }
    return txt
}

; 파일 내용 → {macros, cats, steps, retry, memo}
;  steps: MACRO 줄 없이 들어 있는 동작들 (동작만 복사했을 때)
;  retry·memo는 SETTING 줄이 없으면 ""
ParseMacroText(content) {
    res := {macros: [], cats: [], steps: [], retry: "", memo: ""}
    content := LTrim(content, Chr(0xFEFF))
    cur := 0
    Loop Parse content, "`n", "`r" {
        if (Trim(A_LoopField) = "")     ; 빈 줄은 건너뜀
            continue
        f := StrSplit(A_LoopField, "`t")
        if (f.Length = 0)
            continue
        if (f[1] = "SETTING" && f.Length >= 3) {
            if (f[2] = "retry")
                res.retry := (f[3] = "1")
            else if (f[2] = "memo")
                res.memo := (f[3] = "1")
        } else if (f[1] = "CAT" && f.Length >= 2) {
            if (f[2] != "" && !HasVal(res.cats, f[2]))
                res.cats.Push(f[2])
        } else if (f[1] = "MACRO" && f.Length >= 2) {
            cur := {name: f[2], hk: f.Length >= 3 ? f[3] : "", cat: f.Length >= 4 ? f[4] : "", steps: []}
            res.macros.Push(cur)
        } else if (f[1] = "STEP" && f.Length >= 3) {
            if IsObject(cur)
                cur.steps.Push(StepFromFields(f))
            else
                res.steps.Push(StepFromFields(f))
        }
    }
    return res
}

SaveAll() {
    txt := "; 젠데스크 매크로 데이터`n"
    txt .= "SETTING`tretry`t" (RetryOn ? 1 : 0) "`n"
    txt .= "SETTING`tmemo`t" (MemoAsk ? 1 : 0) "`n"
    txt .= MacroLines(Macros, Cats)
    f := FileOpen(CFG, "w", "UTF-8")
    f.Write(txt)
    f.Close()
}

LoadAll() {
    global Macros, Cats, RetryOn, MemoAsk
    Macros := []
    Cats := []
    if !FileExist(CFG)
        return
    d := ParseMacroText(FileRead(CFG, "UTF-8"))
    Macros := d.macros
    for c in d.cats
        EnsureCat(c)
    for m in Macros
        EnsureCat(m.cat)
    if (d.retry != "")
        RetryOn := d.retry
    if (d.memo != "")
        MemoAsk := d.memo
}
