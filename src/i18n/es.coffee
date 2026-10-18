###
# ORNIFLIGHT STUDIO — Spanish message catalog
###
export default
  nav:
    modules:
      basic:    'Configuración básica'
      profiles: 'Perfiles de vuelo'
      servos:   'Servos'
      control:  'Control'
      sensors:  'Sensores'
      system:   'Sistema'
      safety:   'Seguridad'
      cli:      'CLI'
    subtabs:
      basic:
        body:    'Plano corporal'
        airframe: 'Estructura'
      profiles:
        profiles: 'Perfiles'
      servos:
        servos: 'Servos'
      control:
        pid:           'PID'
        schlagdynamik: 'Dinámica de aleteo'
        modes:         'Modos'
        receiver:      'Receptor'
        adjustments:   'Ajustes'
      sensors:
        hardware: 'Sensores'
        gyro:     'Giroscopio'
      system:
        device: 'Dispositivo'
        ports:  'Puertos'
        power:  'Energía'
        vtx:    'VTX'
        osd:    'OSD'
        voice:  'Voz'
        memory: 'Memoria'
        flash:  'La Muda'
        data:   'Datos'
        app:    'App'
      safety:
        failsafe: 'A prueba de fallos'
      cli:
        cli: 'CLI'

  chrome:
    skip: 'Saltar al contenido'
    connect: 'Conectar'
    disconnect: 'Desconectar'
    selecting: 'Seleccionando…'
    syncing: 'Sincronizando…'
    connectTooltip: 'Conectar un controlador OrniFlight por WebSerial'
    connectUnsupported: 'WebSerial no está disponible en este navegador'
    liveState: 'Estado de conexión en vivo'
    flapFrequency: 'Frecuencia de aleteo actual'
    batteryVoltage: 'Voltaje de la batería de vuelo'
    version: 'Versión del Studio'
    commands: 'Abrir paleta de comandos · Ctrl/⌘ K'
    state: 'Alternar inspector de estado · Ctrl/⌘ Shift D'
    theme: 'Cambiar tema claro y oscuro'
    layout: 'Cambiar disposición del espacio de trabajo'
    flap: 'Aleteo'
    battery: 'Batería'
    commandsLabel: 'COMANDOS'
    stateLabel: 'ESTADO'
    primaryNav: 'Navegación principal'
    toolbar: 'Barra de herramientas del Studio'

  commands:
    connect: 'Conectar dispositivo'
    disconnect: 'Desconectar dispositivo'
    toggleTheme: 'Alternar tema'
    placeholder: 'Navegar o ejecutar un comando…'
    empty: 'Sin comando coincidente'
    footer: '↑↓ seleccionar · ↵ ejecutar · Ctrl/⌘ K alternar'
    ariaLabel: 'Comandos del Studio'

  conn:
    state:
      disconnected: 'Desconectado'
      scanning: 'Buscando…'
      handshaking: 'Sincronizando…'
      connected: 'Conectado'
    breathing: 'RESPIRANDO'
    offlineProfile: 'PERFIL SIN CONEXIÓN'
    deviceConnected: 'DISPOSITIVO CONECTADO'
    controller: 'Controlador'
    simulation: 'Simulación'
    armed: 'ARMADO'
    disarmed: 'DESARMADO'

  shell:
    system: 'Sistema'
    inspector: 'Inspector'
    module: 'Módulo'
    connection: 'Conexión'
    source: 'Fuente'
    device: 'Dispositivo'
    firmware: 'Firmware'
    target: 'Destino'
    status: 'Estado'
    live: 'En vivo'
    voltage: 'Voltaje'
    cpu: 'CPU'

  welcome:
    kicker: 'ORNIFLIGHT STUDIO'
    title: 'Configura el pájaro. Entiende el vuelo.'
    subtitle: 'Abre un espacio de trabajo sin conexión o conecta un controlador OrniFlight. La vista 3D se carga solo cuando el espacio la necesita.'
    connect: 'Conectar controlador'
    choosing: 'Elegir controlador…'
    reading: 'Leyendo firmware…'
    offline: 'Abrir espacio de trabajo sin conexión'
    webSerialNotice: 'Este navegador no expone WebSerial. Los perfiles sin conexión siguen disponibles.'
    lastController: 'ÚLTIMO CONTROLADOR'
    session: 'SESIÓN'
    noController: 'Sin controlador conectado'
    profilesNote: 'Los perfiles y las herramientas de registro funcionan sin firmware.'
    step1: '1 · Conectar'
    step2: '2 · Comparar'
    step3: '3 · Aplicar'
    intro_markdown: "## Un pájaro, tres respiros\n\n**Plano corporal** ordena kernel, mezclador y trims. **Dinámica de aleteo** da forma al aleteo por perfil de vuelo. **Servos** nombra las superficies de control del pájaro de engranaje.\n\n- *Accionamiento directo* — pares de alas oscilan en la onda\n- *Engranaje* — timón, cola y motor como servos clásicos"
    legal_html: '<small>OrniFlight Studio — instrumento de vuelo hermético. Sin mente no hay vuelo.</small>'

  mixer:
    kernel:
      servo: 'Accionamiento directo'
      gearbox: 'Engranaje'
    surface:
      rudder: 'Timón'
      vtailLeft: 'Cola en V izq.'
      vtailRight: 'Cola en V der.'
      elevator: 'Elevador'
      motor: 'Motor'
    trim:
      leftWing: 'Ala izq.'
      rightWing: 'Ala der.'
      backLeftWing: 'Ala izq. trasera'

  servo:
    input:
      none: 'Ninguno'
      stabRoll: 'Estab. Roll'
      stabPitch: 'Estab. Pitch'
      stabYaw: 'Estab. Yaw'
      stabThrottle: 'Estab. Acelerador'
      rcRoll: 'RC Roll'
      rcPitch: 'RC Pitch'
      rcYaw: 'RC Yaw'
      rcThrottle: 'RC Acelerador'
      aux1: 'AUX 1 (Canal 5)'
      aux2: 'AUX 2 (Canal 6)'
      aux3: 'AUX 3 (Canal 7)'
      aux4: 'AUX 4 (Canal 8)'
    channel: 'Servo {n}'

  servos:
    kicker: 'CONFIGURACIÓN BÁSICA · SERVOS'
    title: 'Servos'
    hermes_markdown: "**Superficies de control** del pájaro de engranaje: cada timón, cola o motor que el mezclador declara recibe una fuente de entrada con nombre y un canal de destino. Los pares de alas — los servos de aleteo — se configuran en *Dinámica de aleteo*."
    simulation: 'SIMULACIÓN'
    device: 'DISPOSITIVO'
    read: 'Leer dispositivo'
    save: 'Guardar'
    revert: 'Revertir'
    emptyHeading: 'Sin superficies de control'
    emptySub: 'Este mezclador solo lleva pares de alas.'
    emptyNote: 'Los servos de aleteo de este mezclador {mixer} se configuran como pares de alas en Dinámica de aleteo — no aquí.'
    sectionHeading: 'Superficies de control'
    sectionSub: 'Fuente de entrada y canal de destino por superficie — solo los servos de este mezclador ({count}).'
    inputSource: 'Fuente de entrada'
    targetChannel: 'Canal de destino'

  math:
    layer:
      cadence:
        name: 'Cadencia'
        role: 'Define lo rápido que aletean las alas en respuesta al pitch.'
      ferocity:
        name: 'Ferocidad'
        role: 'Da forma a la dureza de cada aleteo — sensación de potencia vs. planeo.'
      balance:
        name: 'Equilibrio'
        role: 'Reparte el empuje entre bajada y subida para un vuelo nivelado.'
      warp:
        name: 'Warp'
        role: 'Divide la fuerza del aleteo izquierda/derecha para el control de roll.'
      anchor:
        name: 'Ancla'
        role: 'Amortigua la oscilación para que el aleteo se asiente en vez de temblar.'
      resonance:
        name: 'Resonancia'
        role: 'Filtra la vibración a la frecuencia de aleteo para una señal más limpia.'
      prescience:
        name: 'Presciencia'
        role: 'Anticipa el siguiente aleteo para que las correcciones lleguen a tiempo.'
      espelho:
        name: 'Espelho'
        role: 'Cancela la vibración propia de las alas en los sensores.'
      saudade:
        name: 'Saudade'
        role: 'Aprende de cada aleteo y recorta una pequeña corrección constante.'
      aeroelastic:
        name: 'Aeroelástico'
        role: 'Ajusta la fuerza de control entre planeo y aleteo.'
    param:
      cadence_gain:
        label: 'Avance de fase'
        role: 'Vincula la demanda de pitch a cuánto empuja el aleteo.'
      ferocity_p_gain:
        label: 'Ferocidad P'
        role: 'La demanda de pitch endurece la bajada para más empuje.'
      ferocity_d_gain:
        label: 'Ferocidad D'
        role: 'La amortiguación de velocidad suaviza el retorno.'
      ferocity_roll_gain:
        label: 'Ferocidad Roll'
        role: 'La demanda de roll reparte la fuerza entre las dos alas.'
      ferocity_yaw_gain:
        label: 'Ferocidad Yaw'
        role: 'La demanda de yaw reparte la fuerza entre las dos alas.'
      ferocity_downstroke:
        label: 'Forma de bajada'
        role: 'Nitidez de la bajada — 1 seno suave, 100 dwell duro.'
      ferocity_upstroke:
        label: 'Forma de subida'
        role: 'Nitidez de la subida — 1 seno suave, 100 dwell duro.'
      balance_gain:
        label: 'Sesgo de empuje'
        role: 'Reparte el empuje entre bajada y subida.'
      warp_gain:
        label: 'Diferencial warp'
        role: 'Divide la fuerza izquierda/derecha para la autoridad de roll.'
      warp_yaw_gain:
        label: 'Warp yaw'
        role: 'Divide la fuerza izquierda/derecha para la autoridad de yaw.'
      anchor_gain:
        label: 'Ancla de amortiguación'
        role: 'Amortigua la oscilación para que el aleteo se asiente.'
      resonance_gain:
        label: 'Filtro de resonancia'
        role: 'Filtra la vibración a la frecuencia de aleteo de la señal.'
      prescience_gain:
        label: 'Predicción de aleteo'
        role: 'Anticipa el siguiente aleteo a partir de la frecuencia.'
      espelho_gain:
        label: 'Cancelación de ruido'
        role: 'Cancela el ruido propio de las alas en la lectura.'
      saudade_gain:
        label: 'Memoria de aleteo'
        role: 'Aprende una pequeña corrección constante de cada aleteo.'
      ssff_gain:
        label: 'SSFF'
        role: 'Se anticipa con el aleteo; la presciencia elimina su retardo.'
      aeroelastic_glide_coefficient:
        label: 'Escala de planeo'
        role: 'Escala la respuesta de control mientras planea.'
      aeroelastic_flap_coefficient:
        label: 'Escala de aleteo'
        role: 'Escala la respuesta de control mientras aletea.'
    showLayer: 'Mostrar {name}'
    downstroke: '⬇ Bajada'
    upstroke: '⬆ Subida'
    asymmetry: 'Asimetría {value}%'

  airframe:
    field:
      wingSpan:
        label: 'Envergadura'
        hermes: 'Envergadura del ala.'
      chord:
        label: 'Cuerda'
        hermes: 'Cuerda media del ala.'
      totalMass:
        label: 'Masa'
        hermes: 'Masa de despegue.'
      cgX:
        label: 'CG longitudinal'
        hermes: 'Estación del CG, + hacia el morro.'
      cgZ:
        label: 'CG vertical'
        hermes: 'Altura sobre el plano del ala.'
      cgLat:
        label: 'CG lateral'
        hermes: 'Equilibrio de roll, + a la derecha.'
    mount:
      angle:
        label: 'Ángulo de montaje'
        hermes: 'Ángulo de incidencia del servo.'
      station:
        label: 'Estación'
        hermes: 'Posición delante/detrás del eje del CG.'
      vertical:
        label: 'Vertical'
        hermes: 'Altura sobre/bajo el plano del ala.'

  common:
    simulation: 'SIMULACIÓN'
    device: 'DISPOSITIVO'
    unsaved: 'SIN GUARDAR'
    saved: 'GUARDADO'
    read: 'Leer dispositivo'
    save: 'Guardar'
    revert: 'Revertir'

  pid:
    kicker: 'CONTROL · CONTROL DE VUELO'
    title: 'Control de vuelo'
    hermes: 'El núcleo de control: doce ganancias PID en cuatro ejes, tasas y filtros. La estabilización ONDAS vive en Dinámica de aleteo — una sola verdad.'
    simBanner: 'SIMULACIÓN — los valores no se guardan'
    bank: 'Banco PID'
    bankSub: 'Cuatro ejes, tres términos cada uno — cada bloque de eje es un aleteo del controlador.'
    rates: 'Tasas'
    ratesSub: 'Da forma a la respuesta del stick — tasa RC, super tasa, expo.'
    filters: 'Filtros'
    filtersSub: 'Filtrado de giro y término D (MSP 92).'
    ondas: 'ONDAS'
    ondasSub: 'La estabilización ONDAS solo se mantiene en Dinámica de aleteo — aquí vive la referencia.'
    ondasNote: 'Dieciocho ajustes en diez etapas acopladas. Para que PID y Dinámica de aleteo no conduzcan dos veces, la suite abre el borrador ONDAS completo.'
    ondasCta: 'Abrir ONDAS → Dinámica de aleteo'
    rcRate: 'Tasa RC'
    superRate: 'Super tasa'
    expo: 'Expo'
    gyroDlpf: 'Giro DLPF'
    gyroNotch: 'Muesca de giro'
    notchQ: 'Q de muesca'
    dTermDlpf: 'DLPF término D'

  profiles:
    kicker: 'PERFILES DE VUELO'
    hermes: 'Cuatro perfiles, seleccionados por el modo de perfil de ornitóptero (caja AUX). Cada uno lleva ángulo de planeo y forma de aleteo — la Dinámica de aleteo actúa siempre sobre el perfil activo.'
    auxBadge: 'AUX · LA CAJA SELECCIONA'
    active: 'ACTIVO'
    profile: 'Perfil {n}'
    glide: 'Ángulo de planeo'
    stroke: 'Aleteo {stroke} · Retorno {ret} · Mezcla {mix}'
    editActive: 'Editar este perfil en Dinámica de aleteo →'
    editInactive: 'Activar y abrir Dinámica de aleteo →'
    activeNote: 'Perfil activo — ganancias ONDAS y forma de aleteo en efecto.'
    inactiveNote: 'Inactivo — la caja AUX selecciona este perfil.'

  modes:
    kicker: 'CONTROL · MODOS DE VUELO'
    title: 'Modos de vuelo'
    hermes: 'Veinte ranuras AUX contra la corriente de canales — caja, canal y banda de 900–2100 µs. Una fila se ilumina cuando su canal está en rango.'
    noteHeading: 'Modos de vuelo'
    noteSub: 'Rangos AUX armados contra la corriente de canales.'
    noteAcro: '{name} es implícito — el predeterminado cuando ningún rango está activo.'
    rangeHeading: 'Lógica de rango'
    rangeNote: 'Las columnas extra (AND / OR / XOR, caja vinculada) aparecen cuando el firmware expone MSP 238.'
    rangeWarn: 'Firmware heredado — lógica y vínculos en sus valores predeterminados.'
    mainHeading: 'Rangos de modo AUX'
    mainSub: '20 ranuras de activación — caja, canal AUX y banda de 900–2100 µs.'

  receiver:
    kicker: 'CONTROL · RECEPTOR'
    title: 'Receptor'
    hermes: 'Documento del receptor: proveedor y límites de pulso, mapeo de canales, ranuras de failsafe y la corriente de canales mapeada.'
    protocol: 'Protocolo RX'
    protocolSub: 'Proveedor del receptor serie y límites de pulso (MSP 44).'
    maxCheck: 'Chequeo máx.'
    midRc: 'RC medio'
    minCheck: 'Chequeo mín.'
    rxMinPulse: 'Pulso RX mín.'
    rxMaxPulse: 'Pulso RX máx.'
    airmodeThreshold: 'Umbral de airmode'
    channelMap: 'Mapa de canales'
    channelMapSub: 'Entradas lógicas a canales físicos (MSP 64).'
    failsafeChannels: 'Canales de failsafe'
    failsafeChannelsSub: 'Comportamiento de pérdida por canal — ranuras de 750–2250 µs (MSP 77).'
    channel: 'Canal {n}'
    liveChannels: 'Canales en vivo'
    liveChannelsSub: 'Corriente de canales físicos — vista previa mapeada del documento del receptor.'

  adjustments:
    kicker: 'CONTROL · AJUSTES'
    title: 'Ajustes'
    hermes: 'Reguladores en vuelo: treinta ranuras, seis bytes cada una (MSP 52/53). Una ranura se arma cuando su canal AUX está en rango.'
    heading: 'Ranuras de ajuste'
    sub: 'Rango de canal 900 – 2100 µs en pasos de 25 µs; las funciones reflejan la tabla del firmware (0 = ninguna).'
    note: 'Solo las ranuras cambiadas envían SET + EEPROM_WRITE al guardar — cada ranura aplica su función por una de cuatro ranuras simultáneas.'
    slot: 'Ranura {n}'
    function: 'Función'
    adjustmentSlot: 'Ranura de ajuste'
    channel: 'Canal'
    rangeStart: 'Inicio de rango'
    rangeEnd: 'Fin de rango'
    switchChannel: 'Canal de conmutación'

  cli:
    title: 'Terminal CLI'
    subtitle: 'Consola de texto del controlador de vuelo'
    live: '● EN VIVO'
    simulation: '◌ SIMULACIÓN'
    open: 'Abrir CLI del dispositivo'
    exit: 'Salir del CLI'
    clear: 'Limpiar'
    idle: '─ inactivo ─'
    placeholderLive: 'escribe un comando — tab completa'
    placeholderSim: 'simulación — prueba help, version, status'
    commandInput: 'Entrada de comando CLI'
    output: 'Salida CLI'

  schlagdynamik:
    kicker: 'CONTROL · DINÁMICA DE ALETEO'
    title: 'Dinámica de aleteo'
    hermes: 'La estabilización del aleteo: dieciocho ajustes en diez etapas acopladas — del error de control al movimiento de aleteo bloqueado en fase. Cada etapa explica lo que hace para el vuelo; el espejo Espelho lee la asimetría del aleteo en vivo.'
    profileChip: 'Perfil {n} · destino ONDAS'
    espelho: '→ Espelho'
    signalChain: 'Cadena de señal'
    signalChainSub: 'Diez etapas en dirección de vuelo — del error de control al movimiento de aleteo. Un clic trae la etapa a la vista.'
    waveform: 'Forma de onda'
    waveformSub: 'Un ciclo de aleteo completo del núcleo de onda — el ancla fija de las etapas.'
    down: '⬇ Baja {v}%'
    asymmetry: 'Asimetría {v}%'
    up: '⬆ Sube {v}%'
    hzLive: '{hz} Hz · en vivo'
    rest: 'Reposo — sin frecuencia de aleteo'
    espelhoHeading: 'Diagnóstico de asimetría Espelho'
    espelhoSub: 'El espejo: |2.ª armónica| / |fundamental| del movimiento de aleteo — la huella de la asimetría.'
    debugEspelho: 'DEBUG_ESPELHO'
    simDerived: 'SIM · derivado del aleteo'
    phase: 'FASE'

  ornithopter:
    hermes: 'Plano corporal · Estructura. El lado del accionamiento del pájaro, una vista por articulación.'
    craftName: 'NOMBRE DEL APARATO'
    craftNameNote: 'El nombre del sistema lo lleva el controlador (MSP_NAME, 16 caracteres) y se mantiene en Sistema → Dispositivo.'
    editInSystem: 'Editar en Sistema → Dispositivo'
    kernel: 'Kernel'
    kernelNote: 'Accionamiento directo o engranaje.'
    studio: 'STUDIO'
    mixerProfile: 'Perfil de mezclador'
    mixerProfileNote: 'Asignación de GPIO según el firmware.'
    gpioMap: 'Mapa GPIO'
    strokeTime: 'Tiempo de aleteo'
    strokeTimeNote: 'servo_travel_time_ms del firmware — milisegundos por aleteo de 60° (30–500).'
    tempo: '— Tempo —'
    trims: 'Trims'
    trimsNote: 'Posición de reposo de cada articulación con entrada neutra.'
    bodyHermes: 'Kernel y mezclador: cómo el accionamiento tensa el ala — directo a la articulación o por un engranaje.'
    airframeHermes: 'Envergadura, masa y centro de gravedad — la estructura que lleva el aleteo.'
    wingArea: 'Superficie alar {area} cm²'
    aspectRatio: 'Alargamiento {ratio}'
    servoMount: 'Montaje del servo'
    servoMountNote: 'Posición de cada par de alas: ángulo, estación, altura.'
    pair: 'Par {n}'
    footer: 'Plano corporal en Studio · GPIOs en el firmware · alas en el cielo.'
    mixerOption: '{name} — {n} servos'
    simulation: '{name} (Simulación)'

  app:
    kicker: 'SISTEMA · APP'
    title: 'Ajustes de la app'
    subtitle: 'Idioma y preferencias del espacio de trabajo — guardados en este navegador.'
    interface: 'Interfaz'
    interfaceSub: 'Estos ajustes viven en tu navegador. Nada de aquí se escribe en el controlador.'
    language: 'Idioma'
    languageSub: 'Elige el idioma de la interfaz. Tu elección se recuerda en este dispositivo.'
    appearance: 'Apariencia'
    appearanceSub: 'Tema y disposición del espacio de trabajo.'
    theme: 'Tema'
    layout: 'Disposición del espacio de trabajo'
