###
# ORNIFLIGHT STUDIO — Dutch message catalog
###
export default
  nav:
    modules:
      basic:    'Basisconfiguratie'
      profiles: 'Vluchtprofielen'
      servos:   'Servo’s'
      control:  'Besturing'
      sensors:  'Sensoren'
      system:   'Systeem'
      safety:   'Veiligheid'
      cli:      'CLI'
    subtabs:
      basic:
        body:    'Lichaamsplan'
        airframe: 'Vliegwerk'
      profiles:
        profiles: 'Profielen'
      servos:
        servos: 'Servo’s'
      control:
        pid:           'PID'
        schlagdynamik: 'Slagdynamiek'
        modes:         'Modi'
        receiver:      'Ontvanger'
        adjustments:   'Afstellingen'
      sensors:
        hardware: 'Sensoren'
        gyro:     'Gyroscoop'
      system:
        device: 'Apparaat'
        ports:  'Poorten'
        power:  'Energie'
        vtx:    'VTX'
        osd:    'OSD'
        voice:  'Stem'
        memory: 'Geheugen'
        flash:  'De Rui'
        data:   'Gegevens'
        app:    'App'
      safety:
        failsafe: 'Failsafe'
      cli:
        cli: 'CLI'

  chrome:
    skip: 'Naar inhoud'
    connect: 'Verbinden'
    disconnect: 'Verbreken'
    selecting: 'Selecteren…'
    syncing: 'Synchroniseren…'
    connectTooltip: 'Verbind een OrniFlight-controller via WebSerial'
    connectUnsupported: 'WebSerial is niet beschikbaar in deze browser'
    liveState: 'Live verbindingsstatus'
    flapFrequency: 'Huidige slagfrequentie'
    batteryVoltage: 'Vliegaccuspanning'
    version: 'Studioversie'
    commands: 'Open commandopalet · Ctrl/⌘ K'
    state: 'Wissel live statusinspecteur · Ctrl/⌘ Shift D'
    theme: 'Wissel licht en donker thema'
    layout: 'Wijzig werkruimte-indeling'
    flap: 'Slag'
    battery: 'Accu'
    commandsLabel: 'COMMANDO’S'
    stateLabel: 'STATUS'
    primaryNav: 'Primaire navigatie'
    toolbar: 'Studiowerkbalk'

  commands:
    connect: 'Apparaat verbinden'
    disconnect: 'Apparaat verbreken'
    toggleTheme: 'Thema wisselen'
    placeholder: 'Navigeer of voer een commando uit…'
    empty: 'Geen overeenkomstig commando'
    footer: '↑↓ selecteren · ↵ uitvoeren · Ctrl/⌘ K wisselen'
    ariaLabel: 'Studiocommando’s'

  conn:
    state:
      disconnected: 'Verbroken'
      scanning: 'Zoeken…'
      handshaking: 'Synchroniseren…'
      connected: 'Verbonden'
    breathing: 'ADEMHALEND'
    offlineProfile: 'OFFLINEPROFIEL'
    deviceConnected: 'APPARAAT VERBONDEN'
    controller: 'Controller'
    simulation: 'Simulatie'
    armed: 'GEWAPEND'
    disarmed: 'ONTWAPEND'

  shell:
    system: 'Systeem'
    inspector: 'Inspecteur'
    module: 'Module'
    connection: 'Verbinding'
    source: 'Bron'
    device: 'Apparaat'
    firmware: 'Firmware'
    target: 'Target'
    status: 'Status'
    live: 'Live'
    voltage: 'Spanning'
    cpu: 'CPU'

  welcome:
    kicker: 'ORNIFLIGHT STUDIO'
    title: 'Configureer de vogel. Begrijp de vlucht.'
    subtitle: 'Open een offline werkruimte of verbind een OrniFlight-controller. De 3D-voorvertoning laadt alleen als een werkruimte die nodig heeft.'
    connect: 'Controller verbinden'
    choosing: 'Controller kiezen…'
    reading: 'Firmware lezen…'
    offline: 'Offline werkruimte openen'
    webSerialNotice: 'Deze browser stelt geen WebSerial beschikbaar. Offline profielen blijven beschikbaar.'
    lastController: 'LAATSTE CONTROLLER'
    session: 'SESSIE'
    noController: 'Geen controller verbonden'
    profilesNote: 'Profielen en logtools werken zonder firmware.'
    step1: '1 · Verbinden'
    step2: '2 · Vergelijken'
    step3: '3 · Toepassen'
    intro_markdown: "## Eén vogel, drie ademhalingen\n\n**Lichaamsplan** ordent kernel, mixer en trims. **Slagdynamiek** vormt de vleugelslag per vluchtprofiel. **Servo’s** benoemt de stuurvlakken van de tandwielvogel.\n\n- *Directe aandrijving* — vleugelparen oscilleren op de golfvorm\n- *Tandwielkast* — roer, staart en motor als klassieke servo’s"
    legal_html: '<small>OrniFlight Studio — hermetisch vluchtinstrument. Geen vlucht zonder geest.</small>'

  mixer:
    kernel:
      servo: 'Directe aandrijving'
      gearbox: 'Tandwielkast'
    surface:
      rudder: 'Roer'
      vtailLeft: 'V-staart links'
      vtailRight: 'V-staart rechts'
      elevator: 'Hoogteroer'
      motor: 'Motor'
    trim:
      leftWing: 'Vleugel links'
      rightWing: 'Vleugel rechts'
      backLeftWing: 'Vleugel links achter'

  servo:
    input:
      none: 'Geen'
      stabRoll: 'Stab. Roll'
      stabPitch: 'Stab. Pitch'
      stabYaw: 'Stab. Yaw'
      stabThrottle: 'Stab. Gas'
      rcRoll: 'RC Roll'
      rcPitch: 'RC Pitch'
      rcYaw: 'RC Yaw'
      rcThrottle: 'RC Gas'
      aux1: 'AUX 1 (Kanaal 5)'
      aux2: 'AUX 2 (Kanaal 6)'
      aux3: 'AUX 3 (Kanaal 7)'
      aux4: 'AUX 4 (Kanaal 8)'
    channel: 'Servo {n}'

  servos:
    kicker: 'BASISCONFIGURATIE · SERVO’S'
    title: 'Servo’s'
    hermes_markdown: "**Stuurvlakken** van de tandwielvogel: elk roer, elke staart of motor die de mixer verklaart, krijgt een benoemde invoerbron en een doelkanaal. Vleugelparen — de slaande servo’s — worden in *Slagdynamiek* geconfigureerd."
    simulation: 'SIMULATIE'
    device: 'APPARAAT'
    read: 'Apparaat lezen'
    save: 'Opslaan'
    revert: 'Ongedaan maken'
    emptyHeading: 'Geen stuurvlakken'
    emptySub: 'Deze mixer draagt alleen vleugelparen.'
    emptyNote: 'De slaande servo’s van deze {mixer}-mixer worden als vleugelparen in Slagdynamiek geconfigureerd — niet hier.'
    sectionHeading: 'Stuurvlakken'
    sectionSub: 'Invoerbron en doelkanaal per vlak — alleen de servo’s van deze mixer ({count}).'
    inputSource: 'Invoerbron'
    targetChannel: 'Doelkanaal'

  math:
    layer:
      cadence:
        name: 'Cadans'
        role: 'Bepaalt hoe snel de vleugels slaan als reactie op pitch.'
      ferocity:
        name: 'Felheid'
        role: 'Vormt de hardheid van elke slag — kracht vs. zweefgevoel.'
      balance:
        name: 'Balans'
        role: 'Verdeelt de stuwkracht tussen neer- en opslag voor een vlakke vlucht.'
      warp:
        name: 'Warp'
        role: 'Splitst de slagkracht links/rechts voor rolcontrole.'
      anchor:
        name: 'Anker'
        role: 'Dempt oscillatie zodat de slag tot rust komt.'
      resonance:
        name: 'Resonantie'
        role: 'Filtert trilling op de slagfrequentie voor een schoner signaal.'
      prescience:
        name: 'Vooruitzien'
        role: 'Anticipeert de volgende slag zodat correcties op tijd komen.'
      espelho:
        name: 'Espelho'
        role: 'Heeft de eigen trilling van de vleugels op in de sensoren.'
      saudade:
        name: 'Saudade'
        role: 'Leert van elke slag en trimt een kleine constante correctie.'
      aeroelastic:
        name: 'Aero-elastisch'
        role: 'Stelt de stuursterkte af tussen zweven en slaan.'
    param:
      cadence_gain:
        label: 'Fasevoorsprong'
        role: 'Koppelt pitch-vraag aan de voorsprong van de slag.'
      ferocity_p_gain:
        label: 'Felheid P'
        role: 'Pitch-vraag verhardt de neerslag voor meer stuwkracht.'
      ferocity_d_gain:
        label: 'Felheid D'
        role: 'Snelheidsdemping verzacht de terugslag.'
      ferocity_roll_gain:
        label: 'Felheid Roll'
        role: 'Roll-vraag verdeelt de kracht tussen beide vleugels.'
      ferocity_yaw_gain:
        label: 'Felheid Yaw'
        role: 'Yaw-vraag verdeelt de kracht tussen beide vleugels.'
      ferocity_downstroke:
        label: 'Neerslagvorm'
        role: 'Scherpte van de neerslag — 1 zachte sinus, 100 harde dwell.'
      ferocity_upstroke:
        label: 'Opslagvorm'
        role: 'Scherpte van de opslag — 1 zachte sinus, 100 harde dwell.'
      balance_gain:
        label: 'Stuwkracht-bias'
        role: 'Verdeelt de stuwkracht tussen neer- en opslag.'
      warp_gain:
        label: 'Warp-differentiaal'
        role: 'Splitst de kracht links/rechts voor rolgezag.'
      warp_yaw_gain:
        label: 'Warp-yaw'
        role: 'Splitst de kracht links/rechts voor yawgezag.'
      anchor_gain:
        label: 'Dempingsanker'
        role: 'Dempt oscillatie zodat de slag tot rust komt.'
      resonance_gain:
        label: 'Resonantiefilter'
        role: 'Filtert trilling op de slagfrequentie uit het signaal.'
      prescience_gain:
        label: 'Slagvoorspelling'
        role: 'Anticipeert de volgende slag uit de frequentie.'
      espelho_gain:
        label: 'Ruisonderdrukking'
        role: 'Heeft het eigen ruis van de vleugels op in de meting.'
      saudade_gain:
        label: 'Slaggeheugen'
        role: 'Leert een kleine constante correctie van elke slag.'
      ssff_gain:
        label: 'SSFF'
        role: 'Voert vooruit met de slag; vooruitzien verwijdert de vertraging.'
      aeroelastic_glide_coefficient:
        label: 'Zweefschaling'
        role: 'Schaalt de stuurrespons tijdens zweven.'
      aeroelastic_flap_coefficient:
        label: 'Slagschaling'
        role: 'Schaalt de stuurrespons tijdens slaan.'
    showLayer: 'Toon {name}'
    downstroke: '⬇ Neerslag'
    upstroke: '⬆ Opslag'
    asymmetry: 'Asymmetrie {value}%'

  airframe:
    field:
      wingSpan:
        label: 'Spanwijdte'
        hermes: 'Spanwijdte van het vliegwerk.'
      chord:
        label: 'Koorde'
        hermes: 'Gemiddelde vleugelkoorde.'
      totalMass:
        label: 'Massa'
        hermes: 'Startmassa.'
      cgX:
        label: 'CG longitudinaal'
        hermes: 'CG-positie, + richting neus.'
      cgZ:
        label: 'CG verticaal'
        hermes: 'Hoogte boven het vleugelvlak.'
      cgLat:
        label: 'CG lateraal'
        hermes: 'Rolbalans, + naar rechts.'
    mount:
      angle:
        label: 'Montagehoek'
        hermes: 'Invalshoek van de servo.'
      station:
        label: 'Station'
        hermes: 'Positie voor/achter de CG-as.'
      vertical:
        label: 'Verticaal'
        hermes: 'Hoogte boven/onder het vleugelvlak.'

  common:
    simulation: 'SIMULATIE'
    device: 'APPARAAT'
    unsaved: 'NIET OPGESLAGEN'
    saved: 'OPGESLAGEN'
    read: 'Apparaat lezen'
    save: 'Opslaan'
    revert: 'Ongedaan maken'

  pid:
    kicker: 'BESTURING · VLUCHTBESTURING'
    title: 'Vluchtbesturing'
    hermes: 'De besturingskern: twaalf PID-winsten over vier assen, rates en filters. De ONDAS-stabilisatie leeft in Slagdynamiek — één waarheid.'
    simBanner: 'SIMULATIE — waarden worden niet opgeslagen'
    bank: 'PID-bank'
    bankSub: 'Vier assen, drie termen elk — elk asblok is één vleugelslag van de regelaar.'
    rates: 'Rates'
    ratesSub: 'Vorm de stickrespons — RC-rate, super rate, expo.'
    filters: 'Filters'
    filtersSub: 'Gyro- en D-term filtering (MSP 92).'
    ondas: 'ONDAS'
    ondasSub: 'De ONDAS-stabilisatie wordt alleen in Slagdynamiek onderhouden — hier leeft de referentie.'
    ondasNote: 'Achttien afstellingen in tien gekoppelde stadia. Zodat PID en Slagdynamiek nooit dubbel sturen, opent de suite het volledige ONDAS-ontwerp.'
    ondasCta: 'Open ONDAS → Slagdynamiek'
    rcRate: 'RC-rate'
    superRate: 'Super rate'
    expo: 'Expo'
    gyroDlpf: 'Gyro DLPF'
    gyroNotch: 'Gyro-notch'
    notchQ: 'Notch Q'
    dTermDlpf: 'D-term DLPF'

  profiles:
    kicker: 'VLUCHTPROFIELEN'
    hermes: 'Vier profielen, geselecteerd via de ornithopter-profielfunctie (AUX-box). Elk draagt zweefhoek en slagvorm — Slagdynamiek werkt altijd op het actieve profiel.'
    auxBadge: 'AUX · DE BOX SELECTEERT'
    active: 'ACTIEF'
    profile: 'Profiel {n}'
    glide: 'Zweefhoek'
    stroke: 'Slag {stroke} · Terug {ret} · Mix {mix}'
    editActive: 'Bewerk dit profiel in Slagdynamiek →'
    editInactive: 'Activeer en open Slagdynamiek →'
    activeNote: 'Actief profiel — ONDAS-winsten en slagvorm van kracht.'
    inactiveNote: 'Inactief — de AUX-box selecteert dit profiel.'

  modes:
    kicker: 'BESTURING · VLUCHTMODI'
    title: 'Vluchtmodi'
    hermes: 'Twintig AUX-slots tegen de live kanaalstroom — box, kanaal en 900–2100 µs band. Een rij licht op als het kanaal binnen bereik is.'
    noteHeading: 'Vluchtmodi'
    noteSub: 'AUX-bereiken gewapend tegen de live kanaalstroom.'
    noteAcro: '{name} is impliciet — de standaard als geen bereik actief is.'
    rangeHeading: 'Bereiklogica'
    rangeNote: 'Extra kolommen (AND / OR / XOR, gekoppelde box) verschijnen als de firmware MSP 238 blootstelt.'
    rangeWarn: 'Legacy firmware — logica en koppelingen op standaardwaarden.'
    mainHeading: 'AUX-modusbereiken'
    mainSub: '20 activeringsslots — box, AUX-kanaal en 900–2100 µs band.'

  receiver:
    kicker: 'BESTURING · ONTVANGER'
    title: 'Ontvanger'
    hermes: 'Ontvangerdocument: provider en pulsgrenzen, kanaalindeling, failsafe-slots en de gemapte live kanaalstroom.'
    protocol: 'RX-protocol'
    protocolSub: 'Seriële ontvangerprovider en pulsgrenzen (MSP 44).'
    maxCheck: 'Max-check'
    midRc: 'Midden RC'
    minCheck: 'Min-check'
    rxMinPulse: 'RX-minpuls'
    rxMaxPulse: 'RX-maxpuls'
    airmodeThreshold: 'Airmode-drempel'
    channelMap: 'Kanaalindeling'
    channelMapSub: 'Logische ingangen naar fysieke kanalen (MSP 64).'
    failsafeChannels: 'Failsafe-kanalen'
    failsafeChannelsSub: 'Verliesgedrag per kanaal — slots 750–2250 µs (MSP 77).'
    channel: 'Kanaal {n}'
    liveChannels: 'Live kanalen'
    liveChannelsSub: 'Fysieke kanaalstroom — gemapte voorvertoning van het ontvangerdocument.'

  adjustments:
    kicker: 'BESTURING · AFSTELLINGEN'
    title: 'Afstellingen'
    hermes: 'Regelaars in vlucht: dertig slots, zes bytes elk (MSP 52/53). Een slot wapent zich zodra het AUX-kanaal binnen bereik is.'
    heading: 'Afstellingsslots'
    sub: 'Kanaalbereik 900 – 2100 µs in stappen van 25 µs; functies weerspiegelen de firmwaretabel (0 = geen).'
    note: 'Alleen gewijzigde slots sturen SET + EEPROM_WRITE bij opslaan.'
    slot: 'Slot {n}'
    function: 'Functie'
    adjustmentSlot: 'Afstellingsslot'
    channel: 'Kanaal'
    rangeStart: 'Bereikstart'
    rangeEnd: 'Bereikeinde'
    switchChannel: 'Schakelkanaal'

  cli:
    title: 'CLI-terminal'
    subtitle: 'Tekstconsole van de vluchtcontroller'
    live: '● LIVE'
    simulation: '◌ SIMULATIE'
    open: 'Apparaat-CLI openen'
    exit: 'CLI verlaten'
    clear: 'Wissen'
    idle: '─ inactief ─'
    placeholderLive: 'typ een commando — tab vult aan'
    placeholderSim: 'simulatie — probeer help, version, status'
    commandInput: 'CLI-commando-invoer'
    output: 'CLI-uitvoer'

  schlagdynamik:
    kicker: 'BESTURING · SLAGDYNAMIEK'
    title: 'Slagdynamiek'
    hermes: 'De slagstabilisatie: achttien afstellingen in tien gekoppelde stadia — van stuurfout naar fasevergrendelde slagbeweging. Elk stadium legt uit wat het doet voor de vlucht; de Espelho-spiegel leest de slagsasymmetrie live.'
    profileChip: 'Profiel {n} · ONDAS-doel'
    espelho: '→ Espelho'
    signalChain: 'Signaalketen'
    signalChainSub: 'Tien stadia in vliegrichting — van stuurfout naar slagbeweging. Een klik brengt het stadium in beeld.'
    waveform: 'Golfvorm'
    waveformSub: 'Eén volledige slagcyclus uit de golfkern — het vaste anker van de stadia.'
    down: '⬇ Neer {v}%'
    asymmetry: 'Asymmetrie {v}%'
    up: '⬆ Op {v}%'
    hzLive: '{hz} Hz · live'
    rest: 'Rust — geen slagfrequentie'
    espelhoHeading: 'Espelho-scheefheidsdiagnose'
    espelhoSub: 'De spiegel: |2e harmonische| / |grondgolf| van de slagbeweging — de vingerafdruk van asymmetrie.'
    debugEspelho: 'DEBUG_ESPELHO'
    simDerived: 'SIM · slagafgeleid'
    phase: 'FASE'

  ornithopter:
    hermes: 'Lichaamsplan · Vliegwerk. De aandrijfzijde van de vogel, één zicht per gewricht.'
    craftName: 'TOESTELNAAM'
    craftNameNote: 'De systeemnaam wordt door de controller gevoerd (MSP_NAME, 16 tekens) en onderhouden in Systeem → Apparaat.'
    editInSystem: 'Bewerk in Systeem → Apparaat'
    kernel: 'Kernel'
    kernelNote: 'Directe aandrijving of tandwielkast.'
    studio: 'STUDIO'
    mixerProfile: 'Mixerprofiel'
    mixerProfileNote: 'GPIO-toewijzing volgens firmware.'
    gpioMap: 'GPIO-kaart'
    strokeTime: 'Slagtijd'
    strokeTimeNote: 'servo_travel_time_ms van de firmware — milliseconden per 60°-slag (30–500).'
    tempo: '— Tempo —'
    trims: 'Trims'
    trimsNote: 'Rustpositie van elk gewricht bij neutrale invoer.'
    bodyHermes: 'Kernel en mixer: hoe de aandrijving de vleugel spant — direct in het gewricht of via een tandwielkast.'
    airframeHermes: 'Spanwijdte, massa en zwaartepunt — het vliegwerk dat de slag draagt.'
    wingArea: 'Vleugeloppervlak {area} cm²'
    aspectRatio: 'Slankheid {ratio}'
    servoMount: 'Servomontage'
    servoMountNote: 'Positie van elk vleugelpaar: hoek, station, hoogte.'
    pair: 'Paar {n}'
    footer: 'Lichaamsplan in Studio · GPIO in de firmware · vleugels in de lucht.'
    mixerOption: '{name} — {n} servo’s'
    simulation: '{name} (Simulatie)'

  app:
    kicker: 'SYSTEEM · APP'
    title: 'App-instellingen'
    subtitle: 'Taal en werkruimtevoorkeuren — opgeslagen in deze browser.'
    interface: 'Interface'
    interfaceSub: 'Deze instellingen leven in je browser. Niets hiervan wordt naar de controller geschreven.'
    language: 'Taal'
    languageSub: 'Kies de interfacetaal. Je keuze wordt op dit apparaat onthouden.'
    appearance: 'Uiterlijk'
    appearanceSub: 'Thema en werkruimte-indeling.'
    theme: 'Thema'
    layout: 'Werkruimte-indeling'
