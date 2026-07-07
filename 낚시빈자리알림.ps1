# ============================================================
#   선상낚시 빈자리 텔레그램 알림  (통합판 / 1회 실행)
#   지원: 팀스카이·팀만수·지오디·금강7호·보스호·마나루·블레스·
#         피싱아일랜드·마스터피싱·슈퍼노바·팀에프·대박  (약 30척)
#
#   - 로컬: "시작하기.bat" 더블클릭 (5분마다 반복 실행)
#   - 클라우드: GitHub Actions가 자동으로 실행 (.github/workflows)
#
#   비밀값(봇토큰·방번호)은 코드에 없음:
#     · 로컬  → "설정.local.txt" 에서 읽음
#     · Actions → Secret(BOT_TOKEN / CHAT_ID) 환경변수에서 읽음
# ============================================================

param([switch]$status)   # -status : 빈자리 알림 대신 "현재 상태"만 단체방에 보냄(작동 확인용)


##############################################################
##                                                          ##
##      ★★★★★  여 기 만  고 치 세 요  ★★★★★              ##
##                                                          ##
##      ↓↓↓  감시할 배와 날짜를 아래에 적으세요  ↓↓↓        ##
##                                                          ##
##      · 배   = 맨 아래 "선박 목록"의 이름 그대로            ##
##      · 날짜 = "연-월-일"  (콤마로 여러 개 가능)           ##
##                                                          ##
##############################################################
$감시목록 = @(
    # 선상24 배 → GitHub 클라우드가 24시간 감시 (PC 꺼져도 OK)
    @{ 배 = "뉴항구호"; 날짜 = @("2026-07-17") }
    # thefishing 계열 배 → 내 PC(시작하기.bat)가 감시 (PC 켜져 있을 때만, 한국 IP 필요)
    @{ 배 = "팀스카이호"; 날짜 = @("2026-07-17") }
)

# ==================  ★ 선박 목록  ==================
#   배 이름을 위 $감시목록에 그대로 넣으세요.
#
#   [ 클라우드가 24시간 감시 ]  ← 선상24 (PC 꺼져 있어도 알림 옴)
#      · 슈퍼노바호
#      · 팀에프원 · 팀에프투
#      · 뉴항구호 · 뉴항구1호
#
#   [ 내 PC가 감시 ]  ← thefishing 계열 (PC 켜져 있을 때만 알림)
#      · 팀스카이호 · 레드스카이호
#      · 팀만수
#      · 지오디
#      · 금강7호
#      · 보스호
#      · 마나루:       은양호 · 루나호 · 영복1호 · 항공모함 · 하진호 · 수연호 · 나르샤호
#      · 블레스:       블레스호 · 퀸블레스호 · 퍼스트호 · 미라클호 · 마그마호
#      · 피싱아일랜드:  아일랜드호 · 블루오션호 · 복성호 · 챌린지호 · 뉴해풍호 · 미카엘호
#      · 마스터피싱:    루피호 · 슈퍼맨호 · 팀루피호
# ===================================================


# ============================================================
#   아래부터는 건드리지 않아도 됩니다.
# ============================================================

$base = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
# 실행 환경: 클라우드(GitHub Actions)면 선상24만, 로컬 PC면 나머지(thefishing 계열)만 담당
$isCloud = -not [string]::IsNullOrEmpty($env:GITHUB_ACTIONS)

# --- 비밀값 로딩: 환경변수(Actions) 우선, 없으면 로컬 설정파일 ---
$BotToken = $env:BOT_TOKEN
$ChatId   = $env:CHAT_ID
if ([string]::IsNullOrWhiteSpace($BotToken)) {
    $설정파일 = Join-Path $base '설정.local.txt'
    if (Test-Path $설정파일) {
        foreach ($line in (Get-Content $설정파일 -Encoding UTF8)) {
            if ($line -match '^\s*BOT_TOKEN\s*=\s*(.+?)\s*$') { $BotToken = $Matches[1] }
            elseif ($line -match '^\s*CHAT_ID\s*=\s*(.+?)\s*$') { $ChatId = $Matches[1] }
        }
    }
}

$선박DB = @{
    "팀스카이호"   = @{ sys='tf_ajax'; base='https://thefishing.kr'; st=623; id=4077; link='https://thefishing.kr/reservation/list.php?uid=4077' }
    "레드스카이호" = @{ sys='tf_ajax'; base='https://thefishing.kr'; st=623; id=4078; link='https://thefishing.kr/reservation/list.php?uid=4078' }
    "팀만수"   = @{ sys='tf_get'; base='https://teammansu.kr';      id=2829; link='https://teammansu.kr/index.php?mid=bk' }
    "지오디"   = @{ sys='tf_get'; base='https://www.teamgod.kr';     id=5295; link='https://www.teamgod.kr/index.php?mid=bk' }
    "금강7호"  = @{ sys='tf_get'; base='http://www.kumkangho.co.kr'; id=1839; link='http://www.kumkangho.co.kr/index.php?mid=bk' }
    "보스호"   = @{ sys='tf_get'; base='http://www.bossfishing.kr';  id=3045; link='http://www.bossfishing.kr/index.php?mid=bk' }
    "은양호"   = @{ sys='tf_get'; base='https://www.manaru.com'; id=3737; link='https://www.manaru.com/index.php?mid=bk' }
    "루나호"   = @{ sys='tf_get'; base='https://www.manaru.com'; id=3738; link='https://www.manaru.com/index.php?mid=bk' }
    "영복1호"  = @{ sys='tf_get'; base='https://www.manaru.com'; id=3745; link='https://www.manaru.com/index.php?mid=bk' }
    "항공모함" = @{ sys='tf_get'; base='https://www.manaru.com'; id=3741; link='https://www.manaru.com/index.php?mid=bk' }
    "하진호"   = @{ sys='tf_get'; base='https://www.manaru.com'; id=3743; link='https://www.manaru.com/index.php?mid=bk' }
    "수연호"   = @{ sys='tf_get'; base='https://www.manaru.com'; id=4273; link='https://www.manaru.com/index.php?mid=bk' }
    "나르샤호" = @{ sys='tf_get'; base='https://www.manaru.com'; id=6176; link='https://www.manaru.com/index.php?mid=bk' }
    "블레스호"   = @{ sys='tf_get'; base='https://www.blessho.com'; id=3288; link='https://www.blessho.com/index.php?mid=bk' }
    "퀸블레스호" = @{ sys='tf_get'; base='https://www.blessho.com'; id=4675; link='https://www.blessho.com/index.php?mid=bk' }
    "퍼스트호"   = @{ sys='tf_get'; base='https://www.blessho.com'; id=6231; link='https://www.blessho.com/index.php?mid=bk' }
    "미라클호"   = @{ sys='tf_get'; base='https://www.blessho.com'; id=6313; link='https://www.blessho.com/index.php?mid=bk' }
    "마그마호"   = @{ sys='tf_get'; base='https://www.blessho.com'; id=6314; link='https://www.blessho.com/index.php?mid=bk' }
    "아일랜드호" = @{ sys='tf_get'; base='http://www.fishingi.net'; id=1444; link='http://www.fishingi.net/index.php?mid=bk' }
    "블루오션호" = @{ sys='tf_get'; base='http://www.fishingi.net'; id=5321; link='http://www.fishingi.net/index.php?mid=bk' }
    "복성호"     = @{ sys='tf_get'; base='http://www.fishingi.net'; id=1442; link='http://www.fishingi.net/index.php?mid=bk' }
    "챌린지호"   = @{ sys='tf_get'; base='http://www.fishingi.net'; id=1446; link='http://www.fishingi.net/index.php?mid=bk' }
    "뉴해풍호"   = @{ sys='tf_get'; base='http://www.fishingi.net'; id=1447; link='http://www.fishingi.net/index.php?mid=bk' }
    "미카엘호"   = @{ sys='tf_get'; base='http://www.fishingi.net'; id=1448; link='http://www.fishingi.net/index.php?mid=bk' }
    "루피호"   = @{ sys='tf_get'; base='https://masterfishing.kr'; id=6132; link='https://masterfishing.kr/index.php?mid=bk' }
    "슈퍼맨호" = @{ sys='tf_get'; base='https://masterfishing.kr'; id=6133; link='https://masterfishing.kr/index.php?mid=bk' }
    "팀루피호" = @{ sys='tf_get'; base='https://masterfishing.kr'; id=6161; link='https://masterfishing.kr/index.php?mid=bk' }
    "슈퍼노바호" = @{ sys='ss24'; base='https://supernova.sunsang24.com'; name='슈퍼노바호'; link='https://supernova.sunsang24.com/' }
    "팀에프원"   = @{ sys='ss24'; base='https://teamf.sunsang24.com';     name='팀에프원';   link='https://teamf.sunsang24.com/' }
    "팀에프투"   = @{ sys='ss24'; base='https://teamf.sunsang24.com';     name='팀에프투';   link='https://teamf.sunsang24.com/' }
    "뉴항구호"   = @{ sys='ss24'; base='https://daebak.sunsang24.com';    name='뉴항구호';   link='https://daebak.sunsang24.com/' }
    "뉴항구1호"  = @{ sys='ss24'; base='https://daebak.sunsang24.com';    name='뉴항구1호';  link='https://daebak.sunsang24.com/' }
}

$ProgressPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
$요일 = @('일','월','화','수','목','금','토')
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'

function 로그($글자) { Write-Host ("[" + (Get-Date).ToString('MM-dd HH:mm:ss') + "] $글자") }

function 웹요청($url, $method='GET', $body=$null) {
    $h = @{ 'Referer' = $url }
    if ($method -eq 'POST') { $h['X-Requested-With'] = 'XMLHttpRequest' }
    return (Invoke-WebRequest -Uri $url -Method $method -Body $body `
                -ContentType 'application/x-www-form-urlencoded; charset=utf-8' `
                -Headers $h -UserAgent $UA -UseBasicParsing -TimeoutSec 30).Content
}

function 텔레그램전송($글자) {
    if ([string]::IsNullOrWhiteSpace($BotToken)) { 로그 "  ! 봇 토큰 미설정 - 전송 생략"; return }
    try {
        $payload = @{ chat_id = $ChatId; text = $글자; disable_web_page_preview = $true } | ConvertTo-Json -Compress
        $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
        Invoke-RestMethod -Uri "https://api.telegram.org/bot$BotToken/sendMessage" -Method Post -ContentType 'application/json; charset=utf-8' -Body $bytes | Out-Null
    } catch { 로그 "  ! 텔레그램 전송 실패: $($_.Exception.Message)" }
}

function 채팅ID찾기 {
    로그 "채팅 ID 찾는 중... (봇을 그룹에 넣고 /start 를 그 방에 입력하세요)"
    try { $r = Invoke-RestMethod -Uri "https://api.telegram.org/bot$BotToken/getUpdates" -Method Get }
    catch { 로그 "봇 토큰 확인 필요. 오류: $($_.Exception.Message)"; return }
    $found = @{}
    foreach ($u in $r.result) {
        $c = $null
        if ($u.message) { $c = $u.message.chat } elseif ($u.edited_message) { $c = $u.edited_message.chat }
        elseif ($u.channel_post) { $c = $u.channel_post.chat } elseif ($u.my_chat_member) { $c = $u.my_chat_member.chat }
        elseif ($u.chat_member) { $c = $u.chat_member.chat }
        if ($c) { $found[[string]$c.id] = "$($c.title)$($c.first_name) [$($c.type)]" }
    }
    if ($found.Count -eq 0) { Write-Host "`n  아직 감지된 대화 없음. 봇 초대 후 그 방에 /start 입력하고 다시 실행." -ForegroundColor Yellow }
    else { Write-Host "`n  찾음! 아래 번호를 CHAT_ID 로 쓰세요:" -ForegroundColor Green; foreach ($k in $found.Keys) { Write-Host "     $k   <-  $($found[$k])" -ForegroundColor Cyan } }
}

# ===== 시스템별 조회기 : 반환 = @{ 'YYYYMMDD' = @{빈자리=$bool; 인원=$n; 상태='문구'} } =====
function Get-TFAjax($info, $ym) {
    $res = @{}
    try { $html = 웹요청 "$($info.base)/reservation/list.view.view.1.ajax.new.php" 'POST' "date6=$ym&st_uid=$($info.st)&pa_uid=$($info.id)" }
    catch { 로그 "  ! 조회실패 $($info.id)/$ym : $($_.Exception.Message)"; return $res }
    $칸들 = [regex]::Split($html, '<div class="dayline">')
    for ($i=1; $i -lt $칸들.Count; $i++) {
        $cell = $칸들[$i]
        $dm = [regex]::Match($cell, '<span class="day[^"]*">(\d+)</span>')
        if (-not $dm.Success) { continue }
        $dt = $ym + ('{0:D2}' -f [int]$dm.Groups[1].Value)
        if ($cell -match '남은인원\s*<span class="num">(\d+)</span>') { $res[$dt] = @{ 빈자리=$true; 인원=[int]$Matches[1]; 상태="빈자리 $($Matches[1])명" } }
        elseif ($cell -match '예약완료') { $res[$dt] = @{ 빈자리=$false; 인원=0; 상태='예약완료' } }
        elseif ($cell -match '출조취소|기상') { $res[$dt] = @{ 빈자리=$false; 인원=0; 상태='출조취소' } }
    }
    return $res
}

function Get-TFGet($info, $ym) {
    $res = @{}; $y = $ym.Substring(0,4); $m = $ym.Substring(4,2); $id = $info.id
    foreach ($d in '01','09','17','25') {
        try { $html = 웹요청 "$($info.base)/index.php?mid=bk&year=$y&month=$m&day=$d&mode=list&PA_N_UID=$id" }
        catch { continue }
        $ms = [regex]::Matches($html, "(?s)admin-right-(\d{8})-$id-0`">(.*?)</div>")
        if ($ms.Count -gt 0) {
            foreach ($x in $ms) {
                $dt = $x.Groups[1].Value; $c = $x.Groups[2].Value
                if ($dt.Substring(0,6) -ne $ym -or $res.ContainsKey($dt)) { continue }
                if ($c -match '예약완료|예약마감') { $res[$dt] = @{ 빈자리=$false; 인원=0; 상태='예약완료' } }
                elseif ($c -match '기상악화|개인사정|배정비|취소|점검') { $res[$dt] = @{ 빈자리=$false; 인원=0; 상태='출조취소/휴무' } }
                elseif ($c -match '남은자리\s*(\d+)명' -or $c -match '>\s*(\d+)명') { $res[$dt] = @{ 빈자리=$true; 인원=[int]$Matches[1]; 상태="빈자리 $($Matches[1])명" } }
            }
        } else {
            $parts = [regex]::Split($html, '<a name="(\d{8})">')
            for ($i=1; $i -lt $parts.Count-1; $i+=2) {
                $dt = $parts[$i]; $seg = $parts[$i+1]
                if ($dt.Substring(0,6) -ne $ym -or $res.ContainsKey($dt)) { continue }
                if ($seg -match '예약완료') { $res[$dt] = @{ 빈자리=$false; 인원=0; 상태='예약완료' } }
                elseif ($seg -match '기상악화') { $res[$dt] = @{ 빈자리=$false; 인원=0; 상태='출조취소/휴무' } }
                elseif ($seg -match 'alt="남은자리\s*(\d+)명"') { $res[$dt] = @{ 빈자리=$true; 인원=[int]$Matches[1]; 상태="빈자리 $($Matches[1])명" } }
            }
        }
    }
    return $res
}

function Get-SS24($info, $ym) {
    $res = @{}
    try { $html = 웹요청 "$($info.base)/ship/schedule_fleet/$ym" }
    catch { 로그 "  ! 조회실패 $($info.name)/$ym : $($_.Exception.Message)"; return $res }
    # 배 제목(<div class="title">배이름</div>)은 각 날짜 셀 '앞'에 나옴.
    # 따라서 각 data-sdate 셀의 배 = 그 셀보다 앞에 있는 가장 가까운 배 제목.
    $titles = [regex]::Matches($html, '<div class="title">\s*([^<]+?)\s*</div>')
    $cells  = [regex]::Matches($html, 'data-sdate="(\d{4}-\d{2}-\d{2})"')
    for ($i=0; $i -lt $cells.Count; $i++) {
        $pos = $cells[$i].Index
        $dt  = $cells[$i].Groups[1].Value -replace '-',''
        $bt = $null
        foreach ($t in $titles) { if ($t.Index -lt $pos) { $bt = $t.Groups[1].Value.Trim() } else { break } }
        if ($bt -ne $info.name) { continue }
        $끝 = if ($i+1 -lt $cells.Count) { $cells[$i+1].Index } else { [Math]::Min($html.Length, $pos+2000) }
        $seg = $html.Substring($pos, $끝-$pos)
        if ($seg -match 'data-status_code="END"') { $res[$dt] = @{ 빈자리=$false; 인원=0; 상태='예약마감' } }
        elseif ($seg -match 'data-status_code="(CHECK|BAD_WEATHER)"') { $res[$dt] = @{ 빈자리=$false; 인원=0; 상태='점검/기상' } }
        elseif ($seg -match '남은자리[\s\S]{0,80}?(\d+)명') { $res[$dt] = @{ 빈자리=$true; 인원=[int]$Matches[1]; 상태="빈자리 $($Matches[1])명" } }
    }
    return $res
}

function 월현황($info, $ym) {
    switch ($info.sys) {
        'tf_ajax' { return Get-TFAjax $info $ym }
        'tf_get'  { return Get-TFGet  $info $ym }
        'ss24'    { return Get-SS24   $info $ym }
    }
    return @{}
}

function 날짜해석($문자) {
    $d = [datetime]::ParseExact($문자.Trim(), 'yyyy-MM-dd', $null)
    return @{ 연월=$d.ToString('yyyyMM'); 일8=$d.ToString('yyyyMMdd'); 표시="$($d.Month)월 $($d.Day)일 ($($요일[[int]$d.DayOfWeek]))"; 원본=$문자.Trim() }
}


# ================= 시작 (1회 실행) =================
Write-Host "`n  🎣 선상낚시 빈자리 알림기" -ForegroundColor Green

if ([string]::IsNullOrWhiteSpace($BotToken)) {
    Write-Host "  ! 봇 토큰이 없습니다. '설정.local.txt' 를 만들거나 BOT_TOKEN 환경변수를 설정하세요." -ForegroundColor Yellow
    exit 1
}
if ([string]::IsNullOrWhiteSpace($ChatId)) { 채팅ID찾기; exit 1 }

# 감시 대상 정리
$대상 = @()
foreach ($항목 in $감시목록) {
    if (-not $선박DB.ContainsKey($항목.배)) { Write-Host "  ! 모르는 배 이름: '$($항목.배)'" -ForegroundColor Yellow; continue }
    $info = $선박DB[$항목.배]
    foreach ($날 in $항목.날짜) {
        try { $정보 = 날짜해석 $날 } catch { Write-Host "  ! 날짜 형식 오류: '$날'" -ForegroundColor Yellow; continue }
        $대상 += @{ 배이름=$항목.배; info=$info; 정보=$정보; 키="$($항목.배)|$($정보.원본)" }
    }
}
if ($대상.Count -eq 0) { Write-Host "  ! 감시할 대상이 없습니다." -ForegroundColor Yellow; exit 1 }

# 환경별 분담: 클라우드=선상24(ss24)만 / 로컬=나머지(thefishing 계열, 한국 IP 필요)
$대상 = @($대상 | Where-Object { if ($isCloud) { $_.info.sys -eq 'ss24' } else { $_.info.sys -ne 'ss24' } })
if ($대상.Count -eq 0) { Write-Host ("  이 환경[" + $(if($isCloud){'클라우드=선상24'}else{'내PC=thefishing'}) + "]에서 감시할 배 없음. 정상 종료.") -ForegroundColor DarkGray; exit 0 }
Write-Host ("  [" + $(if($isCloud){'클라우드'}else{'내 PC'}) + "] 감시 $($대상.Count)건")

# 이전 상태 불러오기 (없으면 첫 실행). 클라우드/로컬 상태파일 분리
$상태파일 = Join-Path $base $(if($isCloud){'상태.cloud.json'}else{'상태.local.json'})
$이전 = @{}
$첫실행 = -not (Test-Path $상태파일)
if (-not $첫실행) {
    try { $obj = Get-Content $상태파일 -Raw -Encoding UTF8 | ConvertFrom-Json
          foreach ($p in $obj.PSObject.Properties) { if ($p.Name -eq '_hb') { continue }; $이전[$p.Name] = [bool]$p.Value } } catch { $첫실행 = $true }
}

$새상태 = @{}
$요약 = @()
$캐시 = @{}
foreach ($t in $대상) {
    $ck = "$($t.info.sys)|$($t.info.base)|$($t.info.id)$($t.info.name)|$($t.정보.연월)"
    if (-not $캐시.ContainsKey($ck)) { $캐시[$ck] = 월현황 $t.info $t.정보.연월 }
    $월 = $캐시[$ck]
    $현재 = if ($월.ContainsKey($t.정보.일8)) { $월[$t.정보.일8] } else { @{ 빈자리=$false; 상태='미개설/없음'; 인원=0 } }
    $새상태[$t.키] = [bool]$현재.빈자리
    $요약 += "$($t.배이름) $($t.정보.표시) → $($현재.상태)"

    if (-not $status -and -not $첫실행 -and $현재.빈자리 -and (-not $이전[$t.키])) {
        텔레그램전송 "🎣 빈자리 알림!`n`n$($t.배이름) — $($t.정보.표시)`n남은자리: $($현재.인원)명`n`n예약 ▶ $($t.info.link)"
        로그 "  ★ 알림 전송: $($t.배이름) $($t.정보.표시) ($($현재.인원)명)"
    }
}
로그 ("확인완료 | " + ($요약 -join "  ·  "))
$환경이름 = if ($isCloud) { '클라우드' } else { '내 PC' }

# -status : 알림/상태저장 없이 "현재 상태"만 보고하고 종료 (작동 확인용)
if ($status) {
    텔레그램전송 ("📋 현재 감시 상태 [$환경이름]`n`n" + (($요약 | ForEach-Object { "· $_" }) -join "`n"))
    로그 "상태 보고 전송 완료"
    exit 0
}

# 하트비트: 하루 1회 "정상 감시 중" 확인 메시지
$오늘 = (Get-Date).ToString('yyyyMMdd')
$지난하트 = if (-not $첫실행 -and $obj) { [string]$obj._hb } else { '' }
$새상태['_hb'] = $오늘

# 상태 저장
try { ($새상태 | ConvertTo-Json -Compress) | Set-Content -Path $상태파일 -Encoding UTF8 } catch { 로그 "  ! 상태 저장 실패: $($_.Exception.Message)" }

if ($첫실행) {
    텔레그램전송 ("🔔 빈자리 감시를 시작했습니다. [$환경이름]`n`n현재 상태:`n" + (($요약 | ForEach-Object { "· $_" }) -join "`n") + "`n`n앞으로 마감된 날에 자리가 나면 바로 알려드릴게요.")
} elseif ($지난하트 -ne $오늘) {
    텔레그램전송 ("📋 정상 감시 중입니다 [$환경이름] (하루 1회 확인)`n`n현재 상태:`n" + (($요약 | ForEach-Object { "· $_" }) -join "`n"))
    로그 "하트비트 전송"
}
