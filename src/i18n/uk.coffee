###
# ORNIFLIGHT STUDIO — Ukrainian message catalog
###
export default
  nav:
    modules:
      basic:    'Базова конфігурація'
      profiles: 'Профілі польоту'
      servos:   'Сервоприводи'
      control:  'Керування'
      sensors:  'Датчики'
      system:   'Система'
      safety:   'Безпека'
      cli:      'CLI'
    subtabs:
      basic:
        body:    'План тіла'
        airframe: 'Планер'
      profiles:
        profiles: 'Профілі'
      servos:
        servos: 'Сервоприводи'
      control:
        pid:           'PID'
        schlagdynamik: 'Динаміка помаху'
        modes:         'Режими'
        receiver:      'Приймач'
        adjustments:   'Регулювання'
      sensors:
        hardware: 'Датчики'
        gyro:     'Гіроскоп'
      system:
        device: 'Пристрій'
        ports:  'Порти'
        power:  'Живлення'
        vtx:    'VTX'
        osd:    'OSD'
        voice:  'Голос'
        memory: 'Пам’ять'
        flash:  'Линька'
        data:   'Дані'
        app:    'Застосунок'
      safety:
        failsafe: 'Failsafe'
      cli:
        cli: 'CLI'

  chrome:
    skip: 'До вмісту'
    connect: 'Підключити'
    disconnect: 'Відключити'
    selecting: 'Вибір…'
    syncing: 'Синхронізація…'
    connectTooltip: 'Підключити контролер OrniFlight через WebSerial'
    connectUnsupported: 'WebSerial недоступний у цьому браузері'
    liveState: 'Стан з’єднання наживо'
    flapFrequency: 'Поточна частота помахів'
    batteryVoltage: 'Напруга польотної батареї'
    version: 'Версія Studio'
    commands: 'Відкрити палітру команд · Ctrl/⌘ K'
    state: 'Інспектор стану · Ctrl/⌘ Shift D'
    theme: 'Перемкнути світлу й темну тему'
    layout: 'Змінити розкладку робочої області'
    flap: 'Помах'
    battery: 'Батарея'
    commandsLabel: 'КОМАНДИ'
    stateLabel: 'СТАН'
    primaryNav: 'Основна навігація'
    toolbar: 'Панель інструментів Studio'

  commands:
    connect: 'Підключити пристрій'
    disconnect: 'Відключити пристрій'
    toggleTheme: 'Перемкнути тему'
    placeholder: 'Навігація або виконання команди…'
    empty: 'Немає відповідної команди'
    footer: '↑↓ вибір · ↵ виконати · Ctrl/⌘ K перемкнути'
    ariaLabel: 'Команди Studio'

  conn:
    state:
      disconnected: 'Відключено'
      scanning: 'Пошук…'
      handshaking: 'Синхронізація…'
      connected: 'Підключено'
    breathing: 'ДИХАННЯ'
    offlineProfile: 'ПРОФІЛЬ ОФЛАЙН'
    deviceConnected: 'ПРИСТРІЙ ПІДКЛЮЧЕНО'
    controller: 'Контролер'
    simulation: 'Симуляція'
    armed: 'ОЗБРОЄНО'
    disarmed: 'РОЗЗБРОЄНО'

  shell:
    system: 'Система'
    inspector: 'Інспектор'
    module: 'Модуль'
    connection: 'З’єднання'
    source: 'Джерело'
    device: 'Пристрій'
    firmware: 'Прошивка'
    target: 'Ціль'
    status: 'Стан'
    live: 'Наживо'
    voltage: 'Напруга'
    cpu: 'CPU'

  welcome:
    kicker: 'ORNIFLIGHT STUDIO'
    title: 'Налаштуй птаха. Зрозумій політ.'
    subtitle: 'Відкрийте офлайн-простір або підключіть контролер OrniFlight. 3D-попередній перегляд завантажується лише за потреби.'
    connect: 'Підключити контролер'
    choosing: 'Вибір контролера…'
    reading: 'Читання прошивки…'
    offline: 'Відкрити офлайн-простір'
    webSerialNotice: 'Цей браузер не надає WebSerial. Офлайн-профілі залишаються доступними.'
    lastController: 'ОСТАННІЙ КОНТРОЛЕР'
    session: 'СЕСІЯ'
    noController: 'Контролер не підключено'
    profilesNote: 'Профілі та інструменти журналу працюють без прошивки.'
    step1: '1 · Підключити'
    step2: '2 · Порівняти'
    step3: '3 · Застосувати'
    intro_markdown: "## Один птах, три подихи\n\n**План тіла** впорядковує ядро, мікшер і тримери. **Динаміка помаху** формує помах для кожного профілю польоту. **Сервоприводи** називає поверхні керування птаха з редуктором.\n\n- *Прямий привід* — пари крил коливаються на хвильовій формі\n- *Редуктор* — кермо, хвіст і мотор як класичні сервоприводи"
    legal_html: '<small>OrniFlight Studio — герметичний польотний інструмент. Немає польоту без розуму.</small>'

  mixer:
    kernel:
      servo: 'Прямий привід'
      gearbox: 'Редуктор'
    surface:
      rudder: 'Кермо напрямку'
      vtailLeft: 'V-хвіст лівий'
      vtailRight: 'V-хвіст правий'
      elevator: 'Кермо висоти'
      motor: 'Мотор'
    trim:
      leftWing: 'Крило ліве'
      rightWing: 'Крило праве'
      backLeftWing: 'Крило ліве заднє'

  servo:
    input:
      none: 'Немає'
      stabRoll: 'Стаб. крен'
      stabPitch: 'Стаб. тангаж'
      stabYaw: 'Стаб. рискання'
      stabThrottle: 'Стаб. газ'
      rcRoll: 'RC крен'
      rcPitch: 'RC тангаж'
      rcYaw: 'RC рискання'
      rcThrottle: 'RC газ'
      aux1: 'AUX 1 (Канал 5)'
      aux2: 'AUX 2 (Канал 6)'
      aux3: 'AUX 3 (Канал 7)'
      aux4: 'AUX 4 (Канал 8)'
    channel: 'Сервопривід {n}'

  servos:
    kicker: 'БАЗОВА КОНФІГУРАЦІЯ · СЕРВОПРИВОДИ'
    title: 'Сервоприводи'
    hermes_markdown: "**Поверхні керування** птаха з редуктором: кожне кермо, хвіст або мотор, оголошений мікшером, отримує назване джерело входу й цільовий канал. Пари крил — махальні сервоприводи — налаштовуються в *Динаміці помаху*."
    simulation: 'СИМУЛЯЦІЯ'
    device: 'ПРИСТРІЙ'
    read: 'Прочитати пристрій'
    save: 'Зберегти'
    revert: 'Скасувати'
    emptyHeading: 'Немає поверхонь керування'
    emptySub: 'Цей мікшер має лише пари крил.'
    emptyNote: 'Махальні сервоприводи цього мікшера {mixer} налаштовуються як пари крил у Динаміці помаху — не тут.'
    sectionHeading: 'Поверхні керування'
    sectionSub: 'Джерело входу й цільовий канал на поверхню — лише сервоприводи цього мікшера ({count}).'
    inputSource: 'Джерело входу'
    targetChannel: 'Цільовий канал'

  math:
    layer:
      cadence:
        name: 'Каденція'
        role: 'Визначає швидкість помахів у відповідь на тангаж.'
      ferocity:
        name: 'Лютість'
        role: 'Формує жорсткість кожного помаху — потужність проти планерування.'
      balance:
        name: 'Баланс'
        role: 'Розподіляє тягу між опусканням і підйомом для рівного польоту.'
      warp:
        name: 'Warp'
        role: 'Ділить силу помаху вліво/вправо для керування креном.'
      anchor:
        name: 'Якір'
        role: 'Гасить коливання, щоб помах стабілізувався.'
      resonance:
        name: 'Резонанс'
        role: 'Фільтрує вібрацію на частоті помаху для чистішого сигналу.'
      prescience:
        name: 'Передбачення'
        role: 'Передбачає наступний помах, щоб корекції приходили вчасно.'
      espelho:
        name: 'Espelho'
        role: 'Прибирає власну вібрацію крил із датчиків.'
      saudade:
        name: 'Saudade'
        role: 'Навчається з кожного помаху й вносить малу постійну корекцію.'
      aeroelastic:
        name: 'Аеропружність'
        role: 'Налаштовує силу керування між планеруванням і помахом.'
    param:
      cadence_gain:
        label: 'Випередження фази'
        role: 'Пов’язує запит тангажу з випередженням помаху.'
      ferocity_p_gain:
        label: 'Лютість P'
        role: 'Запит тангажу жорсткіше опускає для більшої тяги.'
      ferocity_d_gain:
        label: 'Лютість D'
        role: 'Демпфування швидкості пом’якшує повернення.'
      ferocity_roll_gain:
        label: 'Лютість крен'
        role: 'Запит крену розподіляє силу між двома крилами.'
      ferocity_yaw_gain:
        label: 'Лютість рискання'
        role: 'Запит рискання розподіляє силу між двома крилами.'
      ferocity_downstroke:
        label: 'Форма опускання'
        role: 'Різкість опускання — 1 м’який синус, 100 жорсткий dwell.'
      ferocity_upstroke:
        label: 'Форма підйому'
        role: 'Різкість підйому — 1 м’який синус, 100 жорсткий dwell.'
      balance_gain:
        label: 'Зсув тяги'
        role: 'Розподіляє тягу між опусканням і підйомом.'
      warp_gain:
        label: 'Диференціал warp'
        role: 'Ділить силу вліво/вправо для авторитету крену.'
      warp_yaw_gain:
        label: 'Warp рискання'
        role: 'Ділить силу вліво/вправо для авторитету рискання.'
      anchor_gain:
        label: 'Якір демпфування'
        role: 'Гасить коливання, щоб помах стабілізувався.'
      resonance_gain:
        label: 'Фільтр резонансу'
        role: 'Фільтрує вібрацію на частоті помаху із сигналу.'
      prescience_gain:
        label: 'Прогноз помаху'
        role: 'Передбачає наступний помах за частотою.'
      espelho_gain:
        label: 'Придушення шуму'
        role: 'Прибирає власний шум крил із показів.'
      saudade_gain:
        label: 'Пам’ять помаху'
        role: 'Навчається малої постійної корекції з кожного помаху.'
      ssff_gain:
        label: 'SSFF'
        role: 'Випереджає з помахом; передбачення прибирає затримку.'
      aeroelastic_glide_coefficient:
        label: 'Масштаб планерування'
        role: 'Масштабує відгук керування під час планерування.'
      aeroelastic_flap_coefficient:
        label: 'Масштаб помаху'
        role: 'Масштабує відгук керування під час помаху.'
    showLayer: 'Показати {name}'
    downstroke: '⬇ Опускання'
    upstroke: '⬆ Підйом'
    asymmetry: 'Асиметрія {value}%'

  airframe:
    field:
      wingSpan:
        label: 'Розмах'
        hermes: 'Розмах крила.'
      chord:
        label: 'Хорда'
        hermes: 'Середня хорда крила.'
      totalMass:
        label: 'Маса'
        hermes: 'Злітна маса.'
      cgX:
        label: 'ЦТ поздовжній'
        hermes: 'Позиція ЦТ, + до носа.'
      cgZ:
        label: 'ЦТ вертикальний'
        hermes: 'Висота над площиною крила.'
      cgLat:
        label: 'ЦТ бічний'
        hermes: 'Баланс крену, + вправо.'
    mount:
      angle:
        label: 'Кут монтажу'
        hermes: 'Кут атаки сервоприводу.'
      station:
        label: 'Позиція'
        hermes: 'Положення попереду/позаду осі ЦТ.'
      vertical:
        label: 'Вертикаль'
        hermes: 'Висота над/під площиною крила.'

  common:
    simulation: 'СИМУЛЯЦІЯ'
    device: 'ПРИСТРІЙ'
    unsaved: 'НЕ ЗБЕРЕЖЕНО'
    saved: 'ЗБЕРЕЖЕНО'
    read: 'Прочитати пристрій'
    save: 'Зберегти'
    revert: 'Скасувати'

  pid:
    kicker: 'КЕРУВАННЯ · КЕРУВАННЯ ПОЛЬОТОМ'
    title: 'Керування польотом'
    hermes: 'Ядро керування: дванадцять PID-коефіцієнтів на чотирьох осях, швидкості та фільтри. Стабілізація ONDAS живе в Динаміці помаху — одна істина.'
    simBanner: 'СИМУЛЯЦІЯ — значення не зберігаються'
    bank: 'Банк PID'
    bankSub: 'Чотири осі, по три члени — кожен блок осі це один помах контролера.'
    rates: 'Швидкості'
    ratesSub: 'Формує відгук стіка — RC rate, super rate, expo.'
    filters: 'Фільтри'
    filtersSub: 'Фільтрація гіроскопа та D-члена (MSP 92).'
    ondas: 'ONDAS'
    ondasSub: 'Стабілізація ONDAS підтримується лише в Динаміці помаху — тут живе посилання.'
    ondasNote: 'Вісімнадцять регулювань у десяти зв’язаних етапах. Щоб PID і Динаміка помаху не керували двічі, набір відкриває повний чернетковий ONDAS.'
    ondasCta: 'Відкрити ONDAS → Динаміка помаху'
    rcRate: 'RC rate'
    superRate: 'Super rate'
    expo: 'Expo'
    gyroDlpf: 'Гіро DLPF'
    gyroNotch: 'Нотч гіро'
    notchQ: 'Q нотча'
    dTermDlpf: 'DLPF D-члена'

  profiles:
    kicker: 'ПРОФІЛІ ПОЛЬОТУ'
    hermes: 'Чотири профілі, що обираються режимом профілю орнітоптера (AUX-бокс). Кожен несе кут планерування та форму помаху — Динаміка помаху діє завжди на активний профіль.'
    auxBadge: 'AUX · БОКС ОБИРАЄ'
    active: 'АКТИВНИЙ'
    profile: 'Профіль {n}'
    glide: 'Кут планерування'
    stroke: 'Помах {stroke} · Повернення {ret} · Мікс {mix}'
    editActive: 'Редагувати цей профіль у Динаміці помаху →'
    editInactive: 'Активувати й відкрити Динаміку помаху →'
    activeNote: 'Активний профіль — коефіцієнти ONDAS і форма помаху діють.'
    inactiveNote: 'Неактивний — AUX-бокс обирає цей профіль.'

  modes:
    kicker: 'КЕРУВАННЯ · РЕЖИМИ ПОЛЬОТУ'
    title: 'Режими польоту'
    hermes: 'Двадцять AUX-слотів проти потоку каналів — бокс, канал і смуга 900–2100 мкс. Рядок світиться, коли канал у діапазоні.'
    noteHeading: 'Режими польоту'
    noteSub: 'AUX-діапазони, зведені проти потоку каналів.'
    noteAcro: '{name} неявний — за замовчуванням, коли жоден діапазон не активний.'
    rangeHeading: 'Логіка діапазону'
    rangeNote: 'Додаткові колонки (AND / OR / XOR, пов’язаний бокс) з’являються за MSP 238.'
    rangeWarn: 'Стара прошивка — логіка та зв’язки на значеннях за замовчуванням.'
    mainHeading: 'Діапазони AUX-режимів'
    mainSub: '20 слотів активації — бокс, AUX-канал і смуга 900–2100 мкс.'

  receiver:
    kicker: 'КЕРУВАННЯ · ПРИЙМАЧ'
    title: 'Приймач'
    hermes: 'Документ приймача: провайдер і межі імпульсу, мапінг каналів, слоти failsafe та мапований потік каналів.'
    protocol: 'Протокол RX'
    protocolSub: 'Провайдер послідовного приймача й межі імпульсу (MSP 44).'
    maxCheck: 'Макс. перевірка'
    midRc: 'Середній RC'
    minCheck: 'Мін. перевірка'
    rxMinPulse: 'Імпульс RX мін.'
    rxMaxPulse: 'Імпульс RX макс.'
    airmodeThreshold: 'Поріг airmode'
    channelMap: 'Карта каналів'
    channelMapSub: 'Логічні входи у фізичні канали (MSP 64).'
    failsafeChannels: 'Канали failsafe'
    failsafeChannelsSub: 'Поведінка втрати на канал — слоти 750–2250 мкс (MSP 77).'
    channel: 'Канал {n}'
    liveChannels: 'Канали наживо'
    liveChannelsSub: 'Потік фізичних каналів — мапований попередній перегляд документа приймача.'

  adjustments:
    kicker: 'КЕРУВАННЯ · РЕГУЛЮВАННЯ'
    title: 'Регулювання'
    hermes: 'Регулятори в польоті: тридцять слотів, по шість байтів (MSP 52/53). Слот зводиться, коли його AUX-канал у діапазоні.'
    heading: 'Слоти регулювання'
    sub: 'Діапазон каналу 900 – 2100 мкс із кроком 25 мкс; функції відображають таблицю прошивки (0 = немає).'
    note: 'Лише змінені слоти шлють SET + EEPROM_WRITE при збереженні.'
    slot: 'Слот {n}'
    function: 'Функція'
    adjustmentSlot: 'Слот регулювання'
    channel: 'Канал'
    rangeStart: 'Початок діапазону'
    rangeEnd: 'Кінець діапазону'
    switchChannel: 'Канал перемикання'

  cli:
    title: 'Термінал CLI'
    subtitle: 'Текстова консоль польотного контролера'
    live: '● НАЖИВО'
    simulation: '◌ СИМУЛЯЦІЯ'
    open: 'Відкрити CLI пристрою'
    exit: 'Вийти з CLI'
    clear: 'Очистити'
    idle: '─ простій ─'
    placeholderLive: 'введіть команду — tab доповнює'
    placeholderSim: 'симуляція — спробуйте help, version, status'
    commandInput: 'Ввід команди CLI'
    output: 'Вивід CLI'

  schlagdynamik:
    kicker: 'КЕРУВАННЯ · ДИНАМІКА ПОМАХУ'
    title: 'Динаміка помаху'
    hermes: 'Стабілізація помаху: вісімнадцять регулювань у десяти зв’язаних етапах — від помилки керування до синхронізованого руху помаху. Кожен етап пояснює, що робить для польоту; дзеркало Espelho читає асиметрію помаху наживо.'
    profileChip: 'Профіль {n} · ціль ONDAS'
    espelho: '→ Espelho'
    signalChain: 'Ланцюг сигналу'
    signalChainSub: 'Десять етапів у напрямку польоту — від помилки керування до руху помаху. Клік виводить етап.'
    waveform: 'Форма хвилі'
    waveformSub: 'Один повний цикл помаху з хвильового ядра — фіксований якір етапів.'
    down: '⬇ Вниз {v}%'
    asymmetry: 'Асиметрія {v}%'
    up: '⬆ Вгору {v}%'
    hzLive: '{hz} Гц · наживо'
    rest: 'Спокій — немає частоти помаху'
    espelhoHeading: 'Діагностика перекосу Espelho'
    espelhoSub: 'Дзеркало: |2-га гармоніка| / |основна| руху помаху — відбиток асиметрії.'
    debugEspelho: 'DEBUG_ESPELHO'
    simDerived: 'SIM · похідне помаху'
    phase: 'ФАЗА'

  ornithopter:
    hermes: 'План тіла · Планер. Приводна сторона птаха, один вид на суглоб.'
    craftName: 'ІМ’Я АПАРАТА'
    craftNameNote: 'Системне ім’я веде контролер (MSP_NAME, 16 символів) і підтримується в Система → Пристрій.'
    editInSystem: 'Редагувати в Система → Пристрій'
    kernel: 'Ядро'
    kernelNote: 'Прямий привід або редуктор.'
    studio: 'STUDIO'
    mixerProfile: 'Профіль мікшера'
    mixerProfileNote: 'Призначення GPIO згідно з прошивкою.'
    gpioMap: 'Карта GPIO'
    strokeTime: 'Час помаху'
    strokeTimeNote: 'servo_travel_time_ms прошивки — мілісекунди на помах 60° (30–500).'
    tempo: '— Темп —'
    trims: 'Тримери'
    trimsNote: 'Положення спокою кожного суглоба при нейтральному вході.'
    bodyHermes: 'Ядро і мікшер: як привід натягує крило — прямо в суглоб або через редуктор.'
    airframeHermes: 'Розмах, маса й центр ваги — планер, який несе помах.'
    wingArea: 'Площа крила {area} см²'
    aspectRatio: 'Подовження {ratio}'
    servoMount: 'Монтаж сервоприводу'
    servoMountNote: 'Положення кожної пари крил: кут, позиція, висота.'
    pair: 'Пара {n}'
    footer: 'План тіла в Studio · GPIO у прошивці · крила в небі.'
    mixerOption: '{name} — {n} сервоприводів'
    simulation: '{name} (Симуляція)'

  app:
    kicker: 'СИСТЕМА · ЗАСТОСУНОК'
    title: 'Налаштування застосунку'
    subtitle: 'Мова та вподобання робочої області — збережені в цьому браузері.'
    interface: 'Інтерфейс'
    interfaceSub: 'Ці налаштування живуть у вашому браузері. Ніщо тут не записується на контролер.'
    language: 'Мова'
    languageSub: 'Оберіть мову інтерфейсу. Вибір запам’ятовується на цьому пристрої.'
    appearance: 'Вигляд'
    appearanceSub: 'Тема та розкладка робочої області.'
    theme: 'Тема'
    layout: 'Розкладка робочої області'
