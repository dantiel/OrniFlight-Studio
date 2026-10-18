###
# ORNIFLIGHT STUDIO — Korean message catalog
###
export default
  nav:
    modules:
      basic:    '기본 설정'
      profiles: '비행 프로필'
      servos:   '서보'
      control:  '제어'
      sensors:  '센서'
      system:   '시스템'
      safety:   '안전'
      cli:      'CLI'
    subtabs:
      basic:
        body:    '동체 배치'
        airframe: '기체'
      profiles:
        profiles: '프로필'
      servos:
        servos: '서보'
      control:
        pid:           'PID'
        schlagdynamik: '날갯짓 역학'
        modes:         '모드'
        receiver:      '수신기'
        adjustments:   '조정'
      sensors:
        hardware: '센서'
        gyro:     '자이로'
      system:
        device: '장치'
        ports:  '포트'
        power:  '전원'
        vtx:    'VTX'
        osd:    'OSD'
        voice:  '음성'
        memory: '메모리'
        flash:  '털갈이'
        data:   '데이터'
        app:    '앱'
      safety:
        failsafe: '페일세이프'
      cli:
        cli: 'CLI'

  chrome:
    skip: '콘텐츠로 이동'
    connect: '연결'
    disconnect: '연결 해제'
    selecting: '선택 중…'
    syncing: '동기화 중…'
    connectTooltip: 'WebSerial로 OrniFlight 컨트롤러 연결'
    connectUnsupported: '이 브라우저에서는 WebSerial을 사용할 수 없습니다'
    liveState: '실시간 연결 상태'
    flapFrequency: '현재 날갯짓 주파수'
    batteryVoltage: '비행 배터리 전압'
    version: 'Studio 버전'
    commands: '명령 팔레트 열기 · Ctrl/⌘ K'
    state: '상태 검사기 전환 · Ctrl/⌘ Shift D'
    theme: '밝은/어두운 테마 전환'
    layout: '작업 영역 레이아웃 변경'
    flap: '날갯짓'
    battery: '배터리'
    commandsLabel: '명령'
    stateLabel: '상태'
    primaryNav: '기본 탐색'
    toolbar: 'Studio 도구 모음'

  commands:
    connect: '장치 연결'
    disconnect: '장치 연결 해제'
    toggleTheme: '테마 전환'
    placeholder: '탐색하거나 명령 실행…'
    empty: '일치하는 명령 없음'
    footer: '↑↓ 선택 · ↵ 실행 · Ctrl/⌘ K 전환'
    ariaLabel: 'Studio 명령'

  conn:
    state:
      disconnected: '연결 해제됨'
      scanning: '검색 중…'
      handshaking: '동기화 중…'
      connected: '연결됨'
    breathing: '호흡 중'
    offlineProfile: '오프라인 프로필'
    deviceConnected: '장치 연결됨'
    controller: '컨트롤러'
    simulation: '시뮬레이션'
    armed: '암드됨'
    disarmed: '디스암드됨'

  shell:
    system: '시스템'
    inspector: '검사기'
    module: '모듈'
    connection: '연결'
    source: '소스'
    device: '장치'
    firmware: '펌웨어'
    target: '타깃'
    status: '상태'
    live: '실시간'
    voltage: '전압'
    cpu: 'CPU'

  welcome:
    kicker: 'ORNIFLIGHT STUDIO'
    title: '새를 설정하고 비행을 이해하세요.'
    subtitle: '오프라인 작업 영역을 열거나 OrniFlight 컨트롤러를 연결하세요. 3D 비행 미리보기는 필요할 때만 로드됩니다.'
    connect: '컨트롤러 연결'
    choosing: '컨트롤러 선택…'
    reading: '펌웨어 읽기…'
    offline: '오프라인 작업 영역 열기'
    webSerialNotice: '이 브라우저는 WebSerial을 제공하지 않습니다. 오프라인 프로필은 계속 사용할 수 있습니다.'
    lastController: '마지막 컨트롤러'
    session: '세션'
    noController: '연결된 컨트롤러 없음'
    profilesNote: '프로필과 로그 도구는 펌웨어 없이 작동합니다.'
    step1: '1 · 연결'
    step2: '2 · 비교'
    step3: '3 · 적용'
    intro_markdown: "## 한 마리 새, 세 번의 숨\n\n**동체 배치**는 커널, 믹서, 트림을 정돈합니다. **날갯짓 역학**은 비행 프로필마다 날갯짓을 만듭니다. **서보**는 기어박스 새의 조종면을 이름 붙입니다.\n\n- *직접 구동* — 날개 쌍이 파형 위에서 진동\n- *기어박스* — 방향타, 꼬리, 모터를 고전 서보로"
    legal_html: '<small>OrniFlight Studio — 헤르메스적 비행 계기. 마음 없이는 비행도 없다.</small>'

  mixer:
    kernel:
      servo: '직접 구동'
      gearbox: '기어박스'
    surface:
      rudder: '방향타'
      vtailLeft: 'V-테일 좌'
      vtailRight: 'V-테일 우'
      elevator: '승강타'
      motor: '모터'
    trim:
      leftWing: '좌측 날개'
      rightWing: '우측 날개'
      backLeftWing: '좌측 후방 날개'

  servo:
    input:
      none: '없음'
      stabRoll: '안정 롤'
      stabPitch: '안정 피치'
      stabYaw: '안정 요'
      stabThrottle: '안정 스로틀'
      rcRoll: 'RC 롤'
      rcPitch: 'RC 피치'
      rcYaw: 'RC 요'
      rcThrottle: 'RC 스로틀'
      aux1: 'AUX 1 (채널 5)'
      aux2: 'AUX 2 (채널 6)'
      aux3: 'AUX 3 (채널 7)'
      aux4: 'AUX 4 (채널 8)'
    channel: '서보 {n}'

  servos:
    kicker: '기본 설정 · 서보'
    title: '서보'
    hermes_markdown: "기어박스 새의 **조종면**: 믹서가 선언한 각 방향타, 꼬리, 모터는 이름 붙은 입력 소스와 목표 채널을 받습니다. 날개 쌍——날갯짓 서보——는 *날갯짓 역학*에서 설정합니다."
    simulation: '시뮬레이션'
    device: '장치'
    read: '장치 읽기'
    save: '저장'
    revert: '되돌리기'
    emptyHeading: '조종면 없음'
    emptySub: '이 믹서는 날개 쌍만 가집니다.'
    emptyNote: '이 {mixer} 믹서의 날갯짓 서보는 날갯짓 역학에서 날개 쌍으로 설정합니다——여기가 아닙니다.'
    sectionHeading: '조종면'
    sectionSub: '면마다 입력 소스와 목표 채널——이 믹서의 서보만 ({count}).'
    inputSource: '입력 소스'
    targetChannel: '목표 채널'

  math:
    layer:
      cadence:
        name: '케이던스'
        role: '피치에 반응하는 날갯짓 속도를 정합니다.'
      ferocity:
        name: '격렬함'
        role: '각 날갯짓의 강도를 만듭니다——힘과 활공 느낌.'
      balance:
        name: '균형'
        role: '수평 비행을 위해 추력을 내리기와 올리기 사이에 나눕니다.'
      warp:
        name: '워프'
        role: '롤 제어를 위해 날갯짓 힘을 좌우로 나눕니다.'
      anchor:
        name: '앵커'
        role: '날갯짓이 안정되도록 진동을 감쇠합니다.'
      resonance:
        name: '공명'
        role: '더 깨끗한 신호를 위해 날갯짓 주파수의 진동을 거릅니다.'
      prescience:
        name: '예지'
        role: '수정이 제때 오도록 다음 날갯짓을 예측합니다.'
      espelho:
        name: '에스펠류'
        role: '센서에서 날개 자체 진동을 제거합니다.'
      saudade:
        name: '사우다지'
        role: '각 날갯짓에서 배워 작은 일정 보정을 더합니다.'
      aeroelastic:
        name: '공력탄성'
        role: '활공과 날갯짓 사이에서 제어 강도를 조정합니다.'
    param:
      cadence_gain:
        label: '위상 전진'
        role: '피치 요구를 날갯짓 전진에 연결합니다.'
      ferocity_p_gain:
        label: '격렬함 P'
        role: '피치 요구가 더 큰 추력을 위해 내리기를 강화합니다.'
      ferocity_d_gain:
        label: '격렬함 D'
        role: '속도 감쇠가 복귀를 부드럽게 합니다.'
      ferocity_roll_gain:
        label: '격렬함 롤'
        role: '롤 요구가 힘을 두 날개에 나눕니다.'
      ferocity_yaw_gain:
        label: '격렬함 요'
        role: '요 요구가 힘을 두 날개에 나눕니다.'
      ferocity_downstroke:
        label: '내리기 모양'
        role: '내리기 날카로움——1 부드러운 사인, 100 단단한 드웰.'
      ferocity_upstroke:
        label: '올리기 모양'
        role: '올리기 날카로움——1 부드러운 사인, 100 단단한 드웰.'
      balance_gain:
        label: '추력 편향'
        role: '추력을 내리기와 올리기 사이에 나눕니다.'
      warp_gain:
        label: '워프 차동'
        role: '롤 권한을 위해 힘을 좌우로 나눕니다.'
      warp_yaw_gain:
        label: '워프 요'
        role: '요 권한을 위해 힘을 좌우로 나눕니다.'
      anchor_gain:
        label: '감쇠 앵커'
        role: '날갯짓이 안정되도록 진동을 감쇠합니다.'
      resonance_gain:
        label: '공명 필터'
        role: '신호에서 날갯짓 주파수 진동을 거릅니다.'
      prescience_gain:
        label: '날갯짓 예측'
        role: '주파수로 다음 날갯짓을 예측합니다.'
      espelho_gain:
        label: '노이즈 제거'
        role: '판독에서 날개 자체 노이즈를 제거합니다.'
      saudade_gain:
        label: '날갯짓 기억'
        role: '각 날갯짓에서 작은 일정 보정을 배웁니다.'
      ssff_gain:
        label: 'SSFF'
        role: '날갯짓과 함께 앞먹임; 예지가 지연을 제거합니다.'
      aeroelastic_glide_coefficient:
        label: '활공 스케일'
        role: '활공 중 제어 응답을 스케일합니다.'
      aeroelastic_flap_coefficient:
        label: '날갯짓 스케일'
        role: '날갯짓 중 제어 응답을 스케일합니다.'
    showLayer: '{name} 표시'
    downstroke: '⬇ 내리기'
    upstroke: '⬆ 올리기'
    asymmetry: '비대칭 {value}%'

  airframe:
    field:
      wingSpan:
        label: '날개폭'
        hermes: '기체의 날개폭.'
      chord:
        label: '시위'
        hermes: '평균 날개 시위.'
      totalMass:
        label: '질량'
        hermes: '이륙 질량.'
      cgX:
        label: '무게중심 세로'
        hermes: '무게중심 위치, + 기수 방향.'
      cgZ:
        label: '무게중심 세로'
        hermes: '날개면 위 높이.'
      cgLat:
        label: '무게중심 가로'
        hermes: '롤 균형, + 오른쪽.'
    mount:
      angle:
        label: '장착 각도'
        hermes: '서보의 받음각.'
      station:
        label: '위치'
        hermes: '무게중심 축의 전후 위치.'
      vertical:
        label: '수직'
        hermes: '날개면 위아래 높이.'

  common:
    simulation: '시뮬레이션'
    device: '장치'
    unsaved: '저장 안 됨'
    saved: '저장됨'
    read: '장치 읽기'
    save: '저장'
    revert: '되돌리기'

  pid:
    kicker: '제어 · 비행 제어'
    title: '비행 제어'
    hermes: '제어의 핵심: 네 축에 12개의 PID 게인, 레이트와 필터. ONDAS 안정화는 날갯짓 역학에 삽니다——하나의 진실.'
    simBanner: '시뮬레이션——값이 저장되지 않습니다'
    bank: 'PID 뱅크'
    bankSub: '네 축, 각 세 항——각 축 블록은 컨트롤러의 한 번 날갯짓.'
    rates: '레이트'
    ratesSub: '스틱 응답을 만듭니다——RC 레이트, 슈퍼 레이트, expo.'
    filters: '필터'
    filtersSub: '자이로와 D항 필터링 (MSP 92).'
    ondas: 'ONDAS'
    ondasSub: 'ONDAS 안정화는 날갯짓 역학에서만 유지됩니다——여기에는 참조만 있습니다.'
    ondasNote: '열 결합 단계에 열여덟 조정. PID와 날갯짓 역학이 이중 구동하지 않도록 스위트가 전체 ONDAS 초안을 엽니다.'
    ondasCta: 'ONDAS 열기 → 날갯짓 역학'
    rcRate: 'RC 레이트'
    superRate: '슈퍼 레이트'
    expo: 'Expo'
    gyroDlpf: '자이로 DLPF'
    gyroNotch: '자이로 노치'
    notchQ: '노치 Q'
    dTermDlpf: 'D항 DLPF'

  profiles:
    kicker: '비행 프로필'
    hermes: '오르니톱터 프로필 모드(AUX 박스)로 선택하는 네 프로필. 각각 활공각과 날갯짓 모양을 가집니다——날갯짓 역학은 항상 활성 프로필에 작용합니다.'
    auxBadge: 'AUX · 박스 선택'
    active: '활성'
    profile: '프로필 {n}'
    glide: '활공각'
    stroke: '날갯짓 {stroke} · 복귀 {ret} · 믹스 {mix}'
    editActive: '이 프로필을 날갯짓 역학에서 편집 →'
    editInactive: '활성화하고 날갯짓 역학 열기 →'
    activeNote: '활성 프로필——ONDAS 게인과 날갯짓 모양이 적용됩니다.'
    inactiveNote: '비활성——AUX 박스가 이 프로필을 선택합니다.'

  modes:
    kicker: '제어 · 비행 모드'
    title: '비행 모드'
    hermes: '실시간 채널 흐름에 대응하는 스무 AUX 슬롯——박스, 채널, 900–2100 µs 대역. 채널이 범위에 있으면 행이 켜집니다.'
    noteHeading: '비행 모드'
    noteSub: '실시간 채널 흐름에 대응해 무장한 AUX 범위.'
    noteAcro: '{name}은 암시적——범위가 활성화되지 않을 때의 기본값.'
    rangeHeading: '범위 논리'
    rangeNote: '펌웨어가 MSP 238을 노출하면 추가 열(AND / OR / XOR, 연결 박스)이 나타납니다.'
    rangeWarn: '구형 펌웨어——논리와 연결은 기본값.'
    mainHeading: 'AUX 모드 범위'
    mainSub: '20개 활성화 슬롯——박스, AUX 채널, 900–2100 µs 대역.'

  receiver:
    kicker: '제어 · 수신기'
    title: '수신기'
    hermes: '수신기 문서: 공급자와 펄스 경계, 채널 매핑, 페일세이프 슬롯, 매핑된 실시간 채널 흐름.'
    protocol: 'RX 프로토콜'
    protocolSub: '직렬 수신기 공급자와 펄스 경계 (MSP 44).'
    maxCheck: '최대 체크'
    midRc: '중간 RC'
    minCheck: '최소 체크'
    rxMinPulse: 'RX 최소 펄스'
    rxMaxPulse: 'RX 최대 펄스'
    airmodeThreshold: '에어모드 임계값'
    channelMap: '채널 맵'
    channelMapSub: '논리 입력에서 물리 채널로 (MSP 64).'
    failsafeChannels: '페일세이프 채널'
    failsafeChannelsSub: '채널별 손실 동작——750–2250 µs 슬롯 (MSP 77).'
    channel: '채널 {n}'
    liveChannels: '실시간 채널'
    liveChannelsSub: '물리 채널 흐름——수신기 문서의 매핑된 미리보기.'

  adjustments:
    kicker: '제어 · 조정'
    title: '조정'
    hermes: '비행 중 조절기: 서른 슬롯, 각 6바이트 (MSP 52/53). AUX 채널이 범위에 있으면 슬롯이 무장합니다.'
    heading: '조정 슬롯'
    sub: '채널 범위 900 – 2100 µs, 25 µs 단계; 기능은 펌웨어 테이블을 반영(0 = 없음).'
    note: '저장 시 변경된 슬롯만 SET + EEPROM_WRITE를 보냅니다.'
    slot: '슬롯 {n}'
    function: '기능'
    adjustmentSlot: '조정 슬롯'
    channel: '채널'
    rangeStart: '범위 시작'
    rangeEnd: '범위 끝'
    switchChannel: '전환 채널'

  cli:
    title: 'CLI 터미널'
    subtitle: '비행 컨트롤러의 텍스트 콘솔'
    live: '● 실시간'
    simulation: '◌ 시뮬레이션'
    open: '장치 CLI 열기'
    exit: 'CLI 종료'
    clear: '지우기'
    idle: '─ 대기 ─'
    placeholderLive: '명령 입력——tab으로 완성'
    placeholderSim: '시뮬레이션——help, version, status 시도'
    commandInput: 'CLI 명령 입력'
    output: 'CLI 출력'

  schlagdynamik:
    kicker: '제어 · 날갯짓 역학'
    title: '날갯짓 역학'
    hermes: '날갯짓 안정화: 열 결합 단계에 열여덟 조정——제어 오차에서 위상 잠금 날갯짓 움직임까지. 각 단계는 비행에 무엇을 하는지 설명하고, Espelho 거울이 날갯짓 비대칭을 실시간으로 읽습니다.'
    profileChip: '프로필 {n} · ONDAS 목표'
    espelho: '→ Espelho'
    signalChain: '신호 체인'
    signalChainSub: '비행 방향으로 열 단계——제어 오차에서 날갯짓 움직임까지. 클릭하면 단계를 봅니다.'
    waveform: '파형'
    waveformSub: '파동 커널에서 온 완전한 날갯짓 한 주기——단계들의 고정 앵커.'
    down: '⬇ 내리기 {v}%'
    asymmetry: '비대칭 {v}%'
    up: '⬆ 올리기 {v}%'
    hzLive: '{hz} Hz · 실시간'
    rest: '휴지——날갯짓 주파수 없음'
    espelhoHeading: 'Espelho 비대칭 진단'
    espelhoSub: '거울: 날갯짓 움직임의 |2차 고조파| / |기본파|——비대칭의 지문.'
    debugEspelho: 'DEBUG_ESPELHO'
    simDerived: 'SIM · 날갯짓 파생'
    phase: '위상'

  ornithopter:
    hermes: '동체 배치 · 기체. 새의 구동 측, 관절마다 하나의 보기.'
    craftName: '기체 이름'
    craftNameNote: '시스템 이름은 컨트롤러가 보유하며(MSP_NAME, 16자), 시스템 → 장치에서 관리합니다.'
    editInSystem: '시스템 → 장치에서 편집'
    kernel: '커널'
    kernelNote: '직접 구동 또는 기어박스.'
    studio: 'STUDIO'
    mixerProfile: '믹서 프로필'
    mixerProfileNote: '펌웨어에 따른 GPIO 할당.'
    gpioMap: 'GPIO 맵'
    strokeTime: '날갯짓 시간'
    strokeTimeNote: '펌웨어 servo_travel_time_ms——60° 날갯짓당 밀리초(30–500).'
    tempo: '— 템포 —'
    trims: '트림'
    trimsNote: '중립 입력 시 각 관절의 휴지 위치.'
    bodyHermes: '커널과 믹서: 구동이 날개를 어떻게 당기는지——관절에 직접, 또는 기어박스를 통해.'
    airframeHermes: '날개폭, 질량, 무게중심——날갯짓이 지탱하는 기체.'
    wingArea: '날개 면적 {area} cm²'
    aspectRatio: '가로세로비 {ratio}'
    servoMount: '서보 장착'
    servoMountNote: '각 날개 쌍의 위치: 각도, 위치, 높이.'
    pair: '쌍 {n}'
    footer: '동체 배치는 Studio · GPIO는 펌웨어 · 날개는 하늘.'
    mixerOption: '{name} — {n} 서보'
    simulation: '{name} (시뮬레이션)'

  app:
    kicker: '시스템 · 앱'
    title: '앱 설정'
    subtitle: '언어와 작업 영역 기본 설정——이 브라우저에 저장됩니다.'
    interface: '인터페이스'
    interfaceSub: '이 설정은 브라우저에 저장됩니다. 여기의 어떤 것도 컨트롤러에 기록되지 않습니다.'
    language: '언어'
    languageSub: '인터페이스 언어를 선택하세요. 선택은 이 기기에 기억됩니다.'
    appearance: '모양'
    appearanceSub: '테마와 작업 영역 레이아웃.'
    theme: '테마'
    layout: '작업 영역 레이아웃'
