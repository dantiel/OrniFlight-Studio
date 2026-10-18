###
# ORNIFLIGHT STUDIO — Polish message catalog
###
export default
  nav:
    modules:
      basic:    'Konfiguracja podstawowa'
      profiles: 'Profile lotu'
      servos:   'Serwa'
      control:  'Sterowanie'
      sensors:  'Czujniki'
      system:   'System'
      safety:   'Bezpieczeństwo'
      cli:      'CLI'
    subtabs:
      basic:
        body:    'Plan ciała'
        airframe: 'Płatowiec'
      profiles:
        profiles: 'Profile'
      servos:
        servos: 'Serwa'
      control:
        pid:           'PID'
        schlagdynamik: 'Dynamika machania'
        modes:         'Tryby'
        receiver:      'Odbiornik'
        adjustments:   'Regulacje'
      sensors:
        hardware: 'Czujniki'
        gyro:     'Żyroskop'
      system:
        device: 'Urządzenie'
        ports:  'Porty'
        power:  'Zasilanie'
        vtx:    'VTX'
        osd:    'OSD'
        voice:  'Głos'
        memory: 'Pamięć'
        flash:  'Pierz'
        data:   'Dane'
        app:    'App'
      safety:
        failsafe: 'Failsafe'
      cli:
        cli: 'CLI'

  chrome:
    skip: 'Przejdź do treści'
    connect: 'Połącz'
    disconnect: 'Rozłącz'
    selecting: 'Wybieranie…'
    syncing: 'Synchronizacja…'
    connectTooltip: 'Połącz kontroler OrniFlight przez WebSerial'
    connectUnsupported: 'WebSerial nie jest dostępny w tej przeglądarce'
    liveState: 'Stan połączenia na żywo'
    flapFrequency: 'Aktualna częstotliwość machania'
    batteryVoltage: 'Napięcie akumulatora lotu'
    version: 'Wersja Studio'
    commands: 'Otwórz paletę poleceń · Ctrl/⌘ K'
    state: 'Przełącz inspektor stanu · Ctrl/⌘ Shift D'
    theme: 'Przełącz jasny i ciemny motyw'
    layout: 'Zmień układ obszaru roboczego'
    flap: 'Machnięcie'
    battery: 'Akumulator'
    commandsLabel: 'POLECENIA'
    stateLabel: 'STAN'
    primaryNav: 'Nawigacja główna'
    toolbar: 'Pasek narzędzi Studio'

  commands:
    connect: 'Połącz urządzenie'
    disconnect: 'Rozłącz urządzenie'
    toggleTheme: 'Przełącz motyw'
    placeholder: 'Nawiguj lub wykonaj polecenie…'
    empty: 'Brak pasującego polecenia'
    footer: '↑↓ wybierz · ↵ wykonaj · Ctrl/⌘ K przełącz'
    ariaLabel: 'Polecenia Studio'

  conn:
    state:
      disconnected: 'Rozłączony'
      scanning: 'Szukanie…'
      handshaking: 'Synchronizacja…'
      connected: 'Połączony'
    breathing: 'ODDYCHANIE'
    offlineProfile: 'PROFIL OFFLINE'
    deviceConnected: 'URZĄDZENIE POŁĄCZONE'
    controller: 'Kontroler'
    simulation: 'Symulacja'
    armed: 'UZBROJONY'
    disarmed: 'ROZBROJONY'

  shell:
    system: 'System'
    inspector: 'Inspektor'
    module: 'Moduł'
    connection: 'Połączenie'
    source: 'Źródło'
    device: 'Urządzenie'
    firmware: 'Firmware'
    target: 'Cel'
    status: 'Status'
    live: 'Na żywo'
    voltage: 'Napięcie'
    cpu: 'CPU'

  welcome:
    kicker: 'ORNIFLIGHT STUDIO'
    title: 'Skonfiguruj ptaka. Zrozum lot.'
    subtitle: 'Otwórz przestrzeń offline lub połącz kontroler OrniFlight. Podgląd 3D ładuje się tylko, gdy przestrzeń go potrzebuje.'
    connect: 'Połącz kontroler'
    choosing: 'Wybieranie kontrolera…'
    reading: 'Odczytywanie firmware…'
    offline: 'Otwórz przestrzeń offline'
    webSerialNotice: 'Ta przeglądarka nie udostępnia WebSerial. Profile offline pozostają dostępne.'
    lastController: 'OSTATNI KONTROLER'
    session: 'SESJA'
    noController: 'Brak połączonego kontrolera'
    profilesNote: 'Profile i narzędzia dziennika działają bez firmware.'
    step1: '1 · Połącz'
    step2: '2 · Porównaj'
    step3: '3 · Zastosuj'
    intro_markdown: "## Jeden ptak, trzy oddechy\n\n**Plan ciała** porządkuje jądro, mikser i trymery. **Dynamika machania** kształtuje machanie per profil lotu. **Serwa** nazywa powierzchnie sterowe ptaka z przekładnią.\n\n- *Napęd bezpośredni* — pary skrzydeł oscylują na przebiegu\n- *Przekładnia* — ster, ogon i silnik jako klasyczne serwa"
    legal_html: '<small>OrniFlight Studio — hermetyczny przyrząd lotniczy. Bez umysłu nie ma lotu.</small>'

  mixer:
    kernel:
      servo: 'Napęd bezpośredni'
      gearbox: 'Przekładnia'
    surface:
      rudder: 'Ster kierunku'
      vtailLeft: 'Ogon V lewy'
      vtailRight: 'Ogon V prawy'
      elevator: 'Ster wysokości'
      motor: 'Silnik'
    trim:
      leftWing: 'Skrzydło lewe'
      rightWing: 'Skrzydło prawe'
      backLeftWing: 'Skrzydło lewe tylne'

  servo:
    input:
      none: 'Brak'
      stabRoll: 'Stab. Roll'
      stabPitch: 'Stab. Pitch'
      stabYaw: 'Stab. Yaw'
      stabThrottle: 'Stab. Gaz'
      rcRoll: 'RC Roll'
      rcPitch: 'RC Pitch'
      rcYaw: 'RC Yaw'
      rcThrottle: 'RC Gaz'
      aux1: 'AUX 1 (Kanał 5)'
      aux2: 'AUX 2 (Kanał 6)'
      aux3: 'AUX 3 (Kanał 7)'
      aux4: 'AUX 4 (Kanał 8)'
    channel: 'Serwo {n}'

  servos:
    kicker: 'KONFIGURACJA PODSTAWOWA · SERWA'
    title: 'Serwa'
    hermes_markdown: "**Powierzchnie sterowe** ptaka z przekładnią: każdy ster, ogon lub silnik deklarowany przez mikser otrzymuje nazwane źródło wejścia i kanał docelowy. Pary skrzydeł — serwa machające — konfiguruje się w *Dynamice machania*."
    simulation: 'SYMULACJA'
    device: 'URZĄDZENIE'
    read: 'Odczytaj urządzenie'
    save: 'Zapisz'
    revert: 'Cofnij'
    emptyHeading: 'Brak powierzchni sterowych'
    emptySub: 'Ten mikser ma tylko pary skrzydeł.'
    emptyNote: 'Serwa machające tego miksera {mixer} konfiguruje się jako pary skrzydeł w Dynamice machania — nie tutaj.'
    sectionHeading: 'Powierzchnie sterowe'
    sectionSub: 'Źródło wejścia i kanał docelowy per powierzchnia — tylko serwa tego miksera ({count}).'
    inputSource: 'Źródło wejścia'
    targetChannel: 'Kanał docelowy'

  math:
    layer:
      cadence:
        name: 'Kadencja'
        role: 'Określa szybkość machania w reakcji na pochylenie.'
      ferocity:
        name: 'Zaciekłość'
        role: 'Kształtuje twardość każdego machnięcia — moc vs. szybowanie.'
      balance:
        name: 'Równowaga'
        role: 'Rozdziela ciąg między opadanie i wznoszenie dla poziomego lotu.'
      warp:
        name: 'Warp'
        role: 'Dzieli siłę machania lewo/prawo dla kontroli przechyłu.'
      anchor:
        name: 'Kotwica'
        role: 'Tłumi oscylację, aby machanie ustabilizowało się.'
      resonance:
        name: 'Rezonans'
        role: 'Filtruje wibracje przy częstotliwości machania dla czystszego sygnału.'
      prescience:
        name: 'Przewidywanie'
        role: 'Przewiduje następne machnięcie, aby korekty trafiały na czas.'
      espelho:
        name: 'Espelho'
        role: 'Kasuje własne wibracje skrzydeł w czujnikach.'
      saudade:
        name: 'Saudade'
        role: 'Uczy się z każdego machnięcia i przycina małą stałą korektę.'
      aeroelastic:
        name: 'Aerosprężysty'
        role: 'Dostosowuje siłę sterowania między szybowaniem a machaniem.'
    param:
      cadence_gain:
        label: 'Wyprzedzenie fazy'
        role: 'Wiąże żądanie pochylenia z wyprzedzeniem machnięcia.'
      ferocity_p_gain:
        label: 'Zaciekłość P'
        role: 'Żądanie pochylenia utwardza opadanie dla większego ciągu.'
      ferocity_d_gain:
        label: 'Zaciekłość D'
        role: 'Tłumienie tempa zmiękcza powrót.'
      ferocity_roll_gain:
        label: 'Zaciekłość Roll'
        role: 'Żądanie przechyłu rozdziela siłę między oba skrzydła.'
      ferocity_yaw_gain:
        label: 'Zaciekłość Yaw'
        role: 'Żądanie odchylenia rozdziela siłę między oba skrzydła.'
      ferocity_downstroke:
        label: 'Kształt opadania'
        role: 'Ostrość opadania — 1 miękki sinus, 100 twardy dwell.'
      ferocity_upstroke:
        label: 'Kształt wznoszenia'
        role: 'Ostrość wznoszenia — 1 miękki sinus, 100 twardy dwell.'
      balance_gain:
        label: 'Skos ciągu'
        role: 'Rozdziela ciąg między opadanie a wznoszenie.'
      warp_gain:
        label: 'Różnica warp'
        role: 'Dzieli siłę lewo/prawo dla autorytetu przechyłu.'
      warp_yaw_gain:
        label: 'Warp yaw'
        role: 'Dzieli siłę lewo/prawo dla autorytetu odchylenia.'
      anchor_gain:
        label: 'Kotwica tłumienia'
        role: 'Tłumi oscylację, aby machanie ustabilizowało się.'
      resonance_gain:
        label: 'Filtr rezonansu'
        role: 'Filtruje wibracje przy częstotliwości machania z sygnału.'
      prescience_gain:
        label: 'Przewidywanie machnięcia'
        role: 'Przewiduje następne machnięcie z częstotliwości.'
      espelho_gain:
        label: 'Kasowanie szumu'
        role: 'Kasuje szum własny skrzydeł w odczycie.'
      saudade_gain:
        label: 'Pamięć machnięcia'
        role: 'Uczy się małej stałej korekty z każdego machnięcia.'
      ssff_gain:
        label: 'SSFF'
        role: 'Wyprzedza z machnięciem; przewidywanie usuwa opóźnienie.'
      aeroelastic_glide_coefficient:
        label: 'Skala szybowania'
        role: 'Skaluje odpowiedź sterowania podczas szybowania.'
      aeroelastic_flap_coefficient:
        label: 'Skala machania'
        role: 'Skaluje odpowiedź sterowania podczas machania.'
    showLayer: 'Pokaż {name}'
    downstroke: '⬇ Opadanie'
    upstroke: '⬆ Wznoszenie'
    asymmetry: 'Asymetria {value}%'

  airframe:
    field:
      wingSpan:
        label: 'Rozpiętość'
        hermes: 'Rozpiętość skrzydła.'
      chord:
        label: 'Cięciwa'
        hermes: 'Średnia cięciwa skrzydła.'
      totalMass:
        label: 'Masa'
        hermes: 'Masa startowa.'
      cgX:
        label: 'CG wzdłużne'
        hermes: 'Pozycja CG, + ku nosowi.'
      cgZ:
        label: 'CG pionowe'
        hermes: 'Wysokość nad płaszczyzną skrzydła.'
      cgLat:
        label: 'CG boczne'
        hermes: 'Równowaga przechyłu, + w prawo.'
    mount:
      angle:
        label: 'Kąt montażu'
        hermes: 'Kąt natarcia serwa.'
      station:
        label: 'Pozycja'
        hermes: 'Pozycja przed/za osią CG.'
      vertical:
        label: 'Pionowe'
        hermes: 'Wysokość nad/pod płaszczyzną skrzydła.'

  common:
    simulation: 'SYMULACJA'
    device: 'URZĄDZENIE'
    unsaved: 'NIEZAPISANE'
    saved: 'ZAPISANE'
    read: 'Odczytaj urządzenie'
    save: 'Zapisz'
    revert: 'Cofnij'

  pid:
    kicker: 'STEROWANIE · STEROWANIE LOTEM'
    title: 'Sterowanie lotem'
    hermes: 'Rdzeń sterowania: dwanaście wzmocnień PID na czterech osiach, tempa i filtry. Stabilizacja ONDAS żyje w Dynamice machania — jedna prawda.'
    simBanner: 'SYMULACJA — wartości nie są zapisywane'
    bank: 'Bank PID'
    bankSub: 'Cztery osie, trzy terminy każda — każdy blok osi to jedno machnięcie sterownika.'
    rates: 'Tempa'
    ratesSub: 'Kształtuj reakcję drążka — tempo RC, super tempo, expo.'
    filters: 'Filtry'
    filtersSub: 'Filtrowanie żyroskopu i członu D (MSP 92).'
    ondas: 'ONDAS'
    ondasSub: 'Stabilizacja ONDAS jest utrzymywana tylko w Dynamice machania — tu żyje odniesienie.'
    ondasNote: 'Osiemnaście regulacji w dziesięciu sprzężonych etapach. Aby PID i Dynamika machania nigdy nie sterowały podwójnie, suita otwiera pełny szkic ONDAS.'
    ondasCta: 'Otwórz ONDAS → Dynamika machania'
    rcRate: 'Tempo RC'
    superRate: 'Super tempo'
    expo: 'Expo'
    gyroDlpf: 'Giro DLPF'
    gyroNotch: 'Notch giro'
    notchQ: 'Q notcha'
    dTermDlpf: 'DLPF członu D'

  profiles:
    kicker: 'PROFILE LOTU'
    hermes: 'Cztery profile, wybierane przez tryb profilu ornitoptera (box AUX). Każdy ma kąt szybowania i kształt machania — Dynamika machania działa zawsze na aktywny profil.'
    auxBadge: 'AUX · BOX WYBIERA'
    active: 'AKTYWNY'
    profile: 'Profil {n}'
    glide: 'Kąt szybowania'
    stroke: 'Machnięcie {stroke} · Powrót {ret} · Mix {mix}'
    editActive: 'Edytuj ten profil w Dynamice machania →'
    editInactive: 'Aktywuj i otwórz Dynamikę machania →'
    activeNote: 'Aktywny profil — wzmocnienia ONDAS i kształt machania w mocy.'
    inactiveNote: 'Nieaktywny — box AUX wybiera ten profil.'

  modes:
    kicker: 'STEROWANIE · TRYBY LOTU'
    title: 'Tryby lotu'
    hermes: 'Dwadzieścia slotów AUX przeciw strumieniowi kanałów — box, kanał i pasmo 900–2100 µs. Wiersz świeci, gdy kanał jest w zakresie.'
    noteHeading: 'Tryby lotu'
    noteSub: 'Zakresy AUX uzbrojone przeciw strumieniowi kanałów.'
    noteAcro: '{name} jest domyślny — gdy żaden zakres nie jest aktywny.'
    rangeHeading: 'Logika zakresu'
    rangeNote: 'Dodatkowe kolumny (AND / OR / XOR, powiązany box) pojawiają się, gdy firmware udostępnia MSP 238.'
    rangeWarn: 'Starszy firmware — logika i powiązania na wartościach domyślnych.'
    mainHeading: 'Zakresy trybów AUX'
    mainSub: '20 slotów aktywacji — box, kanał AUX i pasmo 900–2100 µs.'

  receiver:
    kicker: 'STEROWANIE · ODBIORNIK'
    title: 'Odbiornik'
    hermes: 'Dokument odbiornika: dostawca i granice impulsu, mapowanie kanałów, sloty failsafe i mapowany strumień kanałów.'
    protocol: 'Protokół RX'
    protocolSub: 'Dostawca odbiornika szeregowego i granice impulsu (MSP 44).'
    maxCheck: 'Kontrola maks.'
    midRc: 'Środkowe RC'
    minCheck: 'Kontrola min.'
    rxMinPulse: 'Impuls RX min.'
    rxMaxPulse: 'Impuls RX maks.'
    airmodeThreshold: 'Próg airmode'
    channelMap: 'Mapa kanałów'
    channelMapSub: 'Wejścia logiczne do kanałów fizycznych (MSP 64).'
    failsafeChannels: 'Kanały failsafe'
    failsafeChannelsSub: 'Zachowanie utraty per kanał — sloty 750–2250 µs (MSP 77).'
    channel: 'Kanał {n}'
    liveChannels: 'Kanały na żywo'
    liveChannelsSub: 'Strumień kanałów fizycznych — mapowany podgląd dokumentu odbiornika.'

  adjustments:
    kicker: 'STEROWANIE · REGULACJE'
    title: 'Regulacje'
    hermes: 'Regulatory w locie: trzydzieści slotów, po sześć bajtów (MSP 52/53). Slot uzbraja się, gdy jego kanał AUX jest w zakresie.'
    heading: 'Sloty regulacji'
    sub: 'Zakres kanału 900 – 2100 µs w krokach 25 µs; funkcje odzwierciedlają tabelę firmware (0 = brak).'
    note: 'Tylko zmienione sloty wysyłają SET + EEPROM_WRITE przy zapisie.'
    slot: 'Slot {n}'
    function: 'Funkcja'
    adjustmentSlot: 'Slot regulacji'
    channel: 'Kanał'
    rangeStart: 'Początek zakresu'
    rangeEnd: 'Koniec zakresu'
    switchChannel: 'Kanał przełączania'

  cli:
    title: 'Terminal CLI'
    subtitle: 'Konsola tekstowa kontrolera lotu'
    live: '● NA ŻYWO'
    simulation: '◌ SYMULACJA'
    open: 'Otwórz CLI urządzenia'
    exit: 'Wyjdź z CLI'
    clear: 'Wyczyść'
    idle: '─ bezczynny ─'
    placeholderLive: 'wpisz polecenie — tab uzupełnia'
    placeholderSim: 'symulacja — spróbuj help, version, status'
    commandInput: 'Wejście polecenia CLI'
    output: 'Wyjście CLI'

  schlagdynamik:
    kicker: 'STEROWANIE · DYNAMIKA MACHANIA'
    title: 'Dynamika machania'
    hermes: 'Stabilizacja machania: osiemnaście regulacji w dziesięciu sprzężonych etapach — od błędu sterowania do ruchu machania w fazie. Każdy etap wyjaśnia, co robi dla lotu; lustro Espelho czyta asymetrię machania na żywo.'
    profileChip: 'Profil {n} · cel ONDAS'
    espelho: '→ Espelho'
    signalChain: 'Łańcuch sygnału'
    signalChainSub: 'Dziesięć etapów w kierunku lotu — od błędu sterowania do ruchu machania. Kliknięcie przywołuje etap.'
    waveform: 'Przebieg'
    waveformSub: 'Jeden pełny cykl machania z jądra fali — stała kotwica etapów.'
    down: '⬇ Opadanie {v}%'
    asymmetry: 'Asymetria {v}%'
    up: '⬆ Wznoszenie {v}%'
    hzLive: '{hz} Hz · na żywo'
    rest: 'Spoczynek — brak częstotliwości machania'
    espelhoHeading: 'Diagnostyka skosu Espelho'
    espelhoSub: 'Lustro: |2. harmoniczna| / |podstawowa| ruchu machania — odcisk asymetrii.'
    debugEspelho: 'DEBUG_ESPELHO'
    simDerived: 'SIM · pochodne machania'
    phase: 'FAZA'

  ornithopter:
    hermes: 'Plan ciała · Płatowiec. Strona napędu ptaka, jeden widok per przegub.'
    craftName: 'NAZWA STATKU'
    craftNameNote: 'Nazwa systemu jest prowadzona przez kontroler (MSP_NAME, 16 znaków) i utrzymywana w System → Urządzenie.'
    editInSystem: 'Edytuj w System → Urządzenie'
    kernel: 'Jądro'
    kernelNote: 'Napęd bezpośredni lub przekładnia.'
    studio: 'STUDIO'
    mixerProfile: 'Profil miksera'
    mixerProfileNote: 'Przydział GPIO według firmware.'
    gpioMap: 'Mapa GPIO'
    strokeTime: 'Czas machnięcia'
    strokeTimeNote: 'servo_travel_time_ms firmware — milisekundy na machnięcie 60° (30–500).'
    tempo: '— Tempo —'
    trims: 'Trymery'
    trimsNote: 'Pozycja spoczynkowa każdego przegubu przy neutralnym wejściu.'
    bodyHermes: 'Jądro i mikser: jak napęd napina skrzydło — prosto w przegub lub przez przekładnię.'
    airframeHermes: 'Rozpiętość, masa i środek ciężkości — płatowiec, który niesie machnięcie.'
    wingArea: 'Powierzchnia skrzydła {area} cm²'
    aspectRatio: 'Wydłużenie {ratio}'
    servoMount: 'Montaż serwa'
    servoMountNote: 'Pozycja każdej pary skrzydeł: kąt, pozycja, wysokość.'
    pair: 'Para {n}'
    footer: 'Plan ciała w Studio · GPIO w firmware · skrzydła w niebie.'
    mixerOption: '{name} — {n} serw'
    simulation: '{name} (Symulacja)'

  app:
    kicker: 'SYSTEM · APP'
    title: 'Ustawienia aplikacji'
    subtitle: 'Język i preferencje obszaru roboczego — zapisane w tej przeglądarce.'
    interface: 'Interfejs'
    interfaceSub: 'Te ustawienia żyją w twojej przeglądarce. Nic tu nie jest zapisywane na kontrolerze.'
    language: 'Język'
    languageSub: 'Wybierz język interfejsu. Wybór jest zapamiętywany na tym urządzeniu.'
    appearance: 'Wygląd'
    appearanceSub: 'Motyw i układ obszaru roboczego.'
    theme: 'Motyw'
    layout: 'Układ obszaru roboczego'
