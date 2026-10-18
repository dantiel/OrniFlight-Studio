###
# ORNIFLIGHT STUDIO — Turkish message catalog
###
export default
  nav:
    modules:
      basic:    'Temel kurulum'
      profiles: 'Uçuş profilleri'
      servos:   'Servolar'
      control:  'Kontrol'
      sensors:  'Sensörler'
      system:   'Sistem'
      safety:   'Güvenlik'
      cli:      'CLI'
    subtabs:
      basic:
        body:    'Gövde planı'
        airframe: 'Gövde'
      profiles:
        profiles: 'Profiller'
      servos:
        servos: 'Servolar'
      control:
        pid:           'PID'
        schlagdynamik: 'Kanat dinamiği'
        modes:         'Modlar'
        receiver:      'Alıcı'
        adjustments:   'Ayarlar'
      sensors:
        hardware: 'Sensörler'
        gyro:     'Jiroskop'
      system:
        device: 'Cihaz'
        ports:  'Portlar'
        power:  'Güç'
        vtx:    'VTX'
        osd:    'OSD'
        voice:  'Ses'
        memory: 'Bellek'
        flash:  'Tüy Dökümü'
        data:   'Veri'
        app:    'Uygulama'
      safety:
        failsafe: 'Failsafe'
      cli:
        cli: 'CLI'

  chrome:
    skip: 'İçeriğe atla'
    connect: 'Bağlan'
    disconnect: 'Bağlantıyı kes'
    selecting: 'Seçiliyor…'
    syncing: 'Eşitleniyor…'
    connectTooltip: 'OrniFlight denetleyicisini WebSerial ile bağla'
    connectUnsupported: 'WebSerial bu tarayıcıda kullanılamıyor'
    liveState: 'Canlı bağlantı durumu'
    flapFrequency: 'Mevcut kanat çırpma frekansı'
    batteryVoltage: 'Uçuş aküsü voltajı'
    version: 'Studio sürümü'
    commands: 'Komut paletini aç · Ctrl/⌘ K'
    state: 'Durum denetçisini aç · Ctrl/⌘ Shift D'
    theme: 'Açık ve koyu temayı değiştir'
    layout: 'Çalışma alanı düzenini değiştir'
    flap: 'Kanat'
    battery: 'Akü'
    commandsLabel: 'KOMUTLAR'
    stateLabel: 'DURUM'
    primaryNav: 'Birincil gezinme'
    toolbar: 'Studio araç çubuğu'

  commands:
    connect: 'Cihazı bağla'
    disconnect: 'Cihaz bağlantısını kes'
    toggleTheme: 'Temayı değiştir'
    placeholder: 'Gezin veya komut çalıştır…'
    empty: 'Eşleşen komut yok'
    footer: '↑↓ seç · ↵ çalıştır · Ctrl/⌘ K değiştir'
    ariaLabel: 'Studio komutları'

  conn:
    state:
      disconnected: 'Bağlantı yok'
      scanning: 'Aranıyor…'
      handshaking: 'Eşitleniyor…'
      connected: 'Bağlı'
    breathing: 'NEFES ALIYOR'
    offlineProfile: 'ÇEVRİMDIŞI PROFİL'
    deviceConnected: 'CİHAZ BAĞLI'
    controller: 'Denetleyici'
    simulation: 'Simülasyon'
    armed: 'SİLAHLI'
    disarmed: 'SİLAHSIZ'

  shell:
    system: 'Sistem'
    inspector: 'Denetçi'
    module: 'Modül'
    connection: 'Bağlantı'
    source: 'Kaynak'
    device: 'Cihaz'
    firmware: 'Firmware'
    target: 'Hedef'
    status: 'Durum'
    live: 'Canlı'
    voltage: 'Voltaj'
    cpu: 'CPU'

  welcome:
    kicker: 'ORNIFLIGHT STUDIO'
    title: 'Kuşu yapılandır. Uçuşu anla.'
    subtitle: 'Çevrimdışı bir çalışma alanı aç veya bir OrniFlight denetleyicisi bağla. 3D önizleme yalnızca gerektiğinde yüklenir.'
    connect: 'Denetleyiciyi bağla'
    choosing: 'Denetleyici seçiliyor…'
    reading: 'Firmware okunuyor…'
    offline: 'Çevrimdışı çalışma alanı aç'
    webSerialNotice: 'Bu tarayıcı WebSerial sunmuyor. Çevrimdışı profiller kullanılabilir.'
    lastController: 'SON DENETLEYİCİ'
    session: 'OTURUM'
    noController: 'Bağlı denetleyici yok'
    profilesNote: 'Profiller ve günlük araçları firmware olmadan çalışır.'
    step1: '1 · Bağlan'
    step2: '2 · Karşılaştır'
    step3: '3 · Uygula'
    intro_markdown: "## Tek kuş, üç nefes\n\n**Gövde planı** çekirdeği, mikseri ve trimi düzenler. **Kanat dinamiği** kanat vuruşunu uçuş profili başına şekillendirir. **Servolar** dişli kuşun kontrol yüzeylerini adlandırır.\n\n- *Doğrudan tahrik* — kanat çiftleri dalga biçiminde salınır\n- *Dişli kutusu* — dümen, kuyruk ve motor klasik servo olarak"
    legal_html: '<small>OrniFlight Studio — hermetik uçuş aleti. Akıl olmadan uçuş olmaz.</small>'

  mixer:
    kernel:
      servo: 'Doğrudan tahrik'
      gearbox: 'Dişli kutusu'
    surface:
      rudder: 'Dümen'
      vtailLeft: 'V kuyruk sol'
      vtailRight: 'V kuyruk sağ'
      elevator: 'İrtifa dümeni'
      motor: 'Motor'
    trim:
      leftWing: 'Sol kanat'
      rightWing: 'Sağ kanat'
      backLeftWing: 'Sol arka kanat'

  servo:
    input:
      none: 'Yok'
      stabRoll: 'Stab. Yatış'
      stabPitch: 'Stab. Yunuslama'
      stabYaw: 'Stab. Sapma'
      stabThrottle: 'Stab. Gaz'
      rcRoll: 'RC Yatış'
      rcPitch: 'RC Yunuslama'
      rcYaw: 'RC Sapma'
      rcThrottle: 'RC Gaz'
      aux1: 'AUX 1 (Kanal 5)'
      aux2: 'AUX 2 (Kanal 6)'
      aux3: 'AUX 3 (Kanal 7)'
      aux4: 'AUX 4 (Kanal 8)'
    channel: 'Servo {n}'

  servos:
    kicker: 'TEMEL KURULUM · SERVOLAR'
    title: 'Servolar'
    hermes_markdown: "Dişli kuşun **kontrol yüzeyleri**: mikserin bildirdiği her dümen, kuyruk veya motor adlandırılmış bir giriş kaynağı ve hedef kanal alır. Kanat çiftleri — çırpan servolar — *Kanat dinamiğinde* yapılandırılır."
    simulation: 'SİMÜLASYON'
    device: 'CİHAZ'
    read: 'Cihazı oku'
    save: 'Kaydet'
    revert: 'Geri al'
    emptyHeading: 'Kontrol yüzeyi yok'
    emptySub: 'Bu mikser yalnızca kanat çiftleri taşır.'
    emptyNote: 'Bu {mixer} mikserinin çırpan servoları Kanat dinamiğinde kanat çiftleri olarak yapılandırılır — burada değil.'
    sectionHeading: 'Kontrol yüzeyleri'
    sectionSub: 'Yüzey başına giriş kaynağı ve hedef kanal — yalnızca bu mikserin servoları ({count}).'
    inputSource: 'Giriş kaynağı'
    targetChannel: 'Hedef kanal'

  math:
    layer:
      cadence:
        name: 'Kadans'
        role: 'Yunuslamaya tepki olarak kanat vuruş hızını belirler.'
      ferocity:
        name: 'Vahşilik'
        role: 'Her vuruşun sertliğini şekillendirir — güç vs. süzülme hissi.'
      balance:
        name: 'Denge'
        role: 'Düz uçuş için itkiyi iniş ve çıkış arasında dağıtır.'
      warp:
        name: 'Warp'
        role: 'Yatış kontrolü için vuruş gücünü sol/sağ böler.'
      anchor:
        name: 'Çapa'
        role: 'Vuruşun sabitlenmesi için salınımı söndürür.'
      resonance:
        name: 'Rezonans'
        role: 'Daha temiz sinyal için vuruş frekansındaki titreşimi filtreler.'
      prescience:
        name: 'Öngörü'
        role: 'Düzeltmeler zamanında gelsin diye sonraki vuruşu öngörür.'
      espelho:
        name: 'Espelho'
        role: 'Kanatların kendi titreşimini sensörlerden giderir.'
      saudade:
        name: 'Saudade'
        role: 'Her vuruştan öğrenir ve küçük sabit bir düzeltme uygular.'
      aeroelastic:
        name: 'Aeroelastik'
        role: 'Süzülme ile çırpma arasında kontrol gücünü ayarlar.'
    param:
      cadence_gain:
        label: 'Faz ilerlemesi'
        role: 'Yunuslama isteğini vuruş ilerlemesine bağlar.'
      ferocity_p_gain:
        label: 'Vahşilik P'
        role: 'Yunuslama isteği inişi daha fazla itki için sertleştirir.'
      ferocity_d_gain:
        label: 'Vahşilik D'
        role: 'Hız sönümlemesi dönüşü yumuşatır.'
      ferocity_roll_gain:
        label: 'Vahşilik Yatış'
        role: 'Yatış isteği gücü iki kanat arasında dağıtır.'
      ferocity_yaw_gain:
        label: 'Vahşilik Sapma'
        role: 'Sapma isteği gücü iki kanat arasında dağıtır.'
      ferocity_downstroke:
        label: 'İniş biçimi'
        role: 'İniş keskinliği — 1 yumuşak sinüs, 100 sert dwell.'
      ferocity_upstroke:
        label: 'Çıkış biçimi'
        role: 'Çıkış keskinliği — 1 yumuşak sinüs, 100 sert dwell.'
      balance_gain:
        label: 'İtki yanlılığı'
        role: 'İtkiyi iniş ve çıkış arasında dağıtır.'
      warp_gain:
        label: 'Warp farkı'
        role: 'Yatış otoritesi için gücü sol/sağ böler.'
      warp_yaw_gain:
        label: 'Warp sapma'
        role: 'Sapma otoritesi için gücü sol/sağ böler.'
      anchor_gain:
        label: 'Sönüm çapası'
        role: 'Vuruşun sabitlenmesi için salınımı söndürür.'
      resonance_gain:
        label: 'Rezonans filtresi'
        role: 'Sinyaldeki vuruş frekansı titreşimini filtreler.'
      prescience_gain:
        label: 'Vuruş tahmini'
        role: 'Frekans üzerinden sonraki vuruşu öngörür.'
      espelho_gain:
        label: 'Gürültü giderme'
        role: 'Okumadaki kanat öz gürültüsünü giderir.'
      saudade_gain:
        label: 'Vuruş belleği'
        role: 'Her vuruştan küçük sabit bir düzeltme öğrenir.'
      ssff_gain:
        label: 'SSFF'
        role: 'Vuruşla ileri besler; öngörü gecikmeyi giderir.'
      aeroelastic_glide_coefficient:
        label: 'Süzülme ölçeği'
        role: 'Süzülürken kontrol tepkisini ölçekler.'
      aeroelastic_flap_coefficient:
        label: 'Çırpma ölçeği'
        role: 'Çırparken kontrol tepkisini ölçekler.'
    showLayer: '{name} göster'
    downstroke: '⬇ İniş'
    upstroke: '⬆ Çıkış'
    asymmetry: 'Asimetri {value}%'

  airframe:
    field:
      wingSpan:
        label: 'Açıklık'
        hermes: 'Kanat açıklığı.'
      chord:
        label: 'Kord'
        hermes: 'Ortalama kanat kirişi.'
      totalMass:
        label: 'Kütle'
        hermes: 'Kalkış kütlesi.'
      cgX:
        label: 'CG boylamasına'
        hermes: 'CG konumu, + buruna doğru.'
      cgZ:
        label: 'CG dikey'
        hermes: 'Kanat düzleminin üzerindeki yükseklik.'
      cgLat:
        label: 'CG yanal'
        hermes: 'Yatış dengesi, + sağa.'
    mount:
      angle:
        label: 'Montaj açısı'
        hermes: 'Servonun geliş açısı.'
      station:
        label: 'Konum'
        hermes: 'CG ekseninin önü/arkası.'
      vertical:
        label: 'Dikey'
        hermes: 'Kanat düzleminin üstü/altı yükseklik.'

  common:
    simulation: 'SİMÜLASYON'
    device: 'CİHAZ'
    unsaved: 'KAYDEDİLMEDİ'
    saved: 'KAYDEDİLDİ'
    read: 'Cihazı oku'
    save: 'Kaydet'
    revert: 'Geri al'

  pid:
    kicker: 'KONTROL · UÇUŞ KONTROLÜ'
    title: 'Uçuş kontrolü'
    hermes: 'Kontrol çekirdeği: dört eksende on iki PID kazancı, oranlar ve filtreler. ONDAS stabilizasyonu Kanat dinamiğinde yaşar — tek gerçek.'
    simBanner: 'SİMÜLASYON — değerler kaydedilmez'
    bank: 'PID bankası'
    bankSub: 'Dört eksen, her biri üç terim — her eksen bloğu denetleyicinin bir kanat vuruşu.'
    rates: 'Oranlar'
    ratesSub: 'Stick tepkisini şekillendir — RC rate, super rate, expo.'
    filters: 'Filtreler'
    filtersSub: 'Jiro ve D terimi filtreleme (MSP 92).'
    ondas: 'ONDAS'
    ondasSub: 'ONDAS stabilizasyonu yalnızca Kanat dinamiğinde korunur — burada yalnızca referans yaşar.'
    ondasNote: 'On bağlı aşamada on sekiz ayar. PID ve Kanat dinamiği asla iki kez sürmesin diye takım tam ONDAS taslağını açar.'
    ondasCta: 'ONDAS aç → Kanat dinamiği'
    rcRate: 'RC rate'
    superRate: 'Super rate'
    expo: 'Expo'
    gyroDlpf: 'Jiro DLPF'
    gyroNotch: 'Jiro notch'
    notchQ: 'Notch Q'
    dTermDlpf: 'D terimi DLPF'

  profiles:
    kicker: 'UÇUŞ PROFİLLERİ'
    hermes: 'Ornitopter profil moduyla (AUX kutusu) seçilen dört profil. Her biri süzülme açısı ve vuruş biçimi taşır — Kanat dinamiği her zaman aktif profilde çalışır.'
    auxBadge: 'AUX · KUTU SEÇER'
    active: 'AKTİF'
    profile: 'Profil {n}'
    glide: 'Süzülme açısı'
    stroke: 'Vuruş {stroke} · Dönüş {ret} · Mix {mix}'
    editActive: 'Bu profili Kanat dinamiğinde düzenle →'
    editInactive: 'Etkinleştir ve Kanat dinamiğini aç →'
    activeNote: 'Aktif profil — ONDAS kazançları ve vuruş biçimi yürürlükte.'
    inactiveNote: 'Pasif — AUX kutusu bu profili seçer.'

  modes:
    kicker: 'KONTROL · UÇUŞ MODLARI'
    title: 'Uçuş modları'
    hermes: 'Canlı kanal akışına karşı yirmi AUX yuvası — kutu, kanal ve 900–2100 µs bandı. Kanal aralıkta olduğunda satır yanar.'
    noteHeading: 'Uçuş modları'
    noteSub: 'Canlı kanal akışına karşı kurulu AUX aralıkları.'
    noteAcro: '{name} örtük — hiçbir aralık aktif değilken varsayılan.'
    rangeHeading: 'Aralık mantığı'
    rangeNote: 'Ek sütunlar (AND / OR / XOR, bağlı kutu) firmware MSP 238 sunduğunda görünür.'
    rangeWarn: 'Eski firmware — mantık ve bağlar varsayılan değerlerde.'
    mainHeading: 'AUX mod aralıkları'
    mainSub: '20 etkinleştirme yuvası — kutu, AUX kanalı ve 900–2100 µs bandı.'

  receiver:
    kicker: 'KONTROL · ALICI'
    title: 'Alıcı'
    hermes: 'Alıcı belgesi: sağlayıcı ve darbe sınırları, kanal eşleme, failsafe yuvaları ve eşlenmiş canlı kanal akışı.'
    protocol: 'RX protokolü'
    protocolSub: 'Seri alıcı sağlayıcısı ve darbe sınırları (MSP 44).'
    maxCheck: 'Maks kontrol'
    midRc: 'Orta RC'
    minCheck: 'Min kontrol'
    rxMinPulse: 'RX min darbe'
    rxMaxPulse: 'RX maks darbe'
    airmodeThreshold: 'Airmode eşiği'
    channelMap: 'Kanal haritası'
    channelMapSub: 'Mantıksal girişlerden fiziksel kanallara (MSP 64).'
    failsafeChannels: 'Failsafe kanalları'
    failsafeChannelsSub: 'Kanal başına kayıp davranışı — 750–2250 µs yuvaları (MSP 77).'
    channel: 'Kanal {n}'
    liveChannels: 'Canlı kanallar'
    liveChannelsSub: 'Fiziksel kanal akışı — alıcı belgesinin eşlenmiş önizlemesi.'

  adjustments:
    kicker: 'KONTROL · AYARLAR'
    title: 'Ayarlar'
    hermes: 'Uçuş içi düzenleyiciler: otuz yuva, her biri altı bayt (MSP 52/53). AUX kanalı aralıkta olduğunda yuva kurulur.'
    heading: 'Ayar yuvaları'
    sub: 'Kanal aralığı 900 – 2100 µs, 25 µs adımlarla; işlevler firmware tablosunu yansıtır (0 = yok).'
    note: 'Kaydederken yalnızca değişen yuvalar SET + EEPROM_WRITE gönderir.'
    slot: 'Yuva {n}'
    function: 'İşlev'
    adjustmentSlot: 'Ayar yuvası'
    channel: 'Kanal'
    rangeStart: 'Aralık başlangıcı'
    rangeEnd: 'Aralık sonu'
    switchChannel: 'Anahtar kanalı'

  cli:
    title: 'CLI Terminali'
    subtitle: 'Uçuş denetleyicisinin metin konsolu'
    live: '● CANLI'
    simulation: '◌ SİMÜLASYON'
    open: 'Cihaz CLI aç'
    exit: 'CLI çık'
    clear: 'Temizle'
    idle: '─ boşta ─'
    placeholderLive: 'komut yaz — tab tamamlar'
    placeholderSim: 'simülasyon — help, version, status dene'
    commandInput: 'CLI komut girişi'
    output: 'CLI çıktısı'

  schlagdynamik:
    kicker: 'KONTROL · KANAT DİNAMİĞİ'
    title: 'Kanat dinamiği'
    hermes: 'Kanat stabilizasyonu: on bağlı aşamada on sekiz ayar — kontrol hatasından faz kilitli vuruş hareketine. Her aşama uçuş için ne yaptığını açıklar; Espelho aynası vuruş asimetrisini canlı okur.'
    profileChip: 'Profil {n} · ONDAS hedefi'
    espelho: '→ Espelho'
    signalChain: 'Sinyal zinciri'
    signalChainSub: 'Uçuş yönünde on aşama — kontrol hatasından vuruş hareketine. Bir tık aşamayı görünüme getirir.'
    waveform: 'Dalga biçimi'
    waveformSub: 'Dalga çekirdeğinden tam bir vuruş döngüsü — aşamaların sabit çapası.'
    down: '⬇ İniş {v}%'
    asymmetry: 'Asimetri {v}%'
    up: '⬆ Çıkış {v}%'
    hzLive: '{hz} Hz · canlı'
    rest: 'Dinlenme — vuruş frekansı yok'
    espelhoHeading: 'Espelho Eğrilik Tanısı'
    espelhoSub: 'Ayna: vuruş hareketinin |2. harmonik| / |temel| — asimetrinin parmak izi.'
    debugEspelho: 'DEBUG_ESPELHO'
    simDerived: 'SIM · vuruş türevli'
    phase: 'FAZ'

  ornithopter:
    hermes: 'Gövde planı · Gövde. Kuşun tahrik tarafı, eklem başına bir görünüm.'
    craftName: 'ARAÇ ADI'
    craftNameNote: 'Sistem adı denetleyici tarafından taşınır (MSP_NAME, 16 karakter) ve Sistem → Cihazda korunur.'
    editInSystem: 'Sistem → Cihazda düzenle'
    kernel: 'Çekirdek'
    kernelNote: 'Doğrudan tahrik veya dişli kutusu.'
    studio: 'STUDIO'
    mixerProfile: 'Mikser profili'
    mixerProfileNote: 'Firmware göre GPIO ataması.'
    gpioMap: 'GPIO haritası'
    strokeTime: 'Vuruş süresi'
    strokeTimeNote: 'Firmware servo_travel_time_ms — 60° vuruş başına milisaniye (30–500).'
    tempo: '— Tempo —'
    trims: 'Trimler'
    trimsNote: 'Nötr girişte her eklemin dinlenme konumu.'
    bodyHermes: 'Çekirdek ve mikser: tahrikin kanadı nasıl gerdiği — doğrudan ekleme veya dişli kutusuyla.'
    airframeHermes: 'Açıklık, kütle ve ağırlık merkezi — vuruşun taşıdığı gövde.'
    wingArea: 'Kanat alanı {area} cm²'
    aspectRatio: 'Aspect oranı {ratio}'
    servoMount: 'Servo montajı'
    servoMountNote: 'Her kanat çiftinin konumu: açı, konum, yükseklik.'
    pair: 'Çift {n}'
    footer: 'Studio\'da gövde planı · firmware\'de GPIO · gökyüzünde kanatlar.'
    mixerOption: '{name} — {n} servo'
    simulation: '{name} (Simülasyon)'

  app:
    kicker: 'SİSTEM · UYGULAMA'
    title: 'Uygulama ayarları'
    subtitle: 'Dil ve çalışma alanı tercihleri — bu tarayıcıda saklanır.'
    interface: 'Arayüz'
    interfaceSub: 'Bu ayarlar tarayıcınızda yaşar. Buradan hiçbir şey denetleyiciye yazılmaz.'
    language: 'Dil'
    languageSub: 'Arayüz dilini seçin. Seçiminiz bu cihazda hatırlanır.'
    appearance: 'Görünüm'
    appearanceSub: 'Tema ve çalışma alanı düzeni.'
    theme: 'Tema'
    layout: 'Çalışma alanı düzeni'