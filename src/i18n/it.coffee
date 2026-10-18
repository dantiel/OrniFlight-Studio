###
# ORNIFLIGHT STUDIO — Italian message catalog
###
export default
  nav:
    modules:
      basic:    'Configurazione base'
      profiles: 'Profili di volo'
      servos:   'Servi'
      control:  'Controllo'
      sensors:  'Sensori'
      system:   'Sistema'
      safety:   'Sicurezza'
      cli:      'CLI'
    subtabs:
      basic:
        body:    'Piano corporeo'
        airframe: 'Cellula'
      profiles:
        profiles: 'Profili'
      servos:
        servos: 'Servi'
      control:
        pid:           'PID'
        schlagdynamik: 'Dinamica del battito'
        modes:         'Modalità'
        receiver:      'Ricevente'
        adjustments:   'Regolazioni'
      sensors:
        hardware: 'Sensori'
        gyro:     'Giroscopio'
      system:
        device: 'Dispositivo'
        ports:  'Porte'
        power:  'Alimentazione'
        vtx:    'VTX'
        osd:    'OSD'
        voice:  'Voce'
        memory: 'Memoria'
        flash:  'La Muta'
        data:   'Dati'
        app:    'App'
      safety:
        failsafe: 'Sicurezza integrata'
      cli:
        cli: 'CLI'

  chrome:
    skip: 'Vai al contenuto'
    connect: 'Connetti'
    disconnect: 'Disconnetti'
    selecting: 'Selezione…'
    syncing: 'Sincronizzazione…'
    connectTooltip: 'Connetti un controller OrniFlight via WebSerial'
    connectUnsupported: 'WebSerial non è disponibile in questo browser'
    liveState: 'Stato connessione in tempo reale'
    flapFrequency: 'Frequenza di battito attuale'
    batteryVoltage: 'Tensione batteria di volo'
    version: 'Versione Studio'
    commands: 'Apri la tavolozza comandi · Ctrl/⌘ K'
    state: 'Attiva ispettore di stato · Ctrl/⌘ Maiusc D'
    theme: 'Cambia tema chiaro e scuro'
    layout: 'Cambia layout dell’area di lavoro'
    flap: 'Battito'
    battery: 'Batteria'
    commandsLabel: 'COMANDI'
    stateLabel: 'STATO'
    primaryNav: 'Navigazione principale'
    toolbar: 'Barra degli strumenti Studio'

  commands:
    connect: 'Connetti dispositivo'
    disconnect: 'Disconnetti dispositivo'
    toggleTheme: 'Cambia tema'
    placeholder: 'Naviga o esegui un comando…'
    empty: 'Nessun comando corrispondente'
    footer: '↑↓ seleziona · ↵ esegui · Ctrl/⌘ K attiva/disattiva'
    ariaLabel: 'Comandi Studio'

  conn:
    state:
      disconnected: 'Disconnesso'
      scanning: 'Ricerca…'
      handshaking: 'Sincronizzazione…'
      connected: 'Connesso'
    breathing: 'RESPIRAZIONE'
    offlineProfile: 'PROFILO OFFLINE'
    deviceConnected: 'DISPOSITIVO CONNESSO'
    controller: 'Controller'
    simulation: 'Simulazione'
    armed: 'ARMATO'
    disarmed: 'DISARMATO'

  shell:
    system: 'Sistema'
    inspector: 'Ispettore'
    module: 'Modulo'
    connection: 'Connessione'
    source: 'Sorgente'
    device: 'Dispositivo'
    firmware: 'Firmware'
    target: 'Target'
    status: 'Stato'
    live: 'In tempo reale'
    voltage: 'Tensione'
    cpu: 'CPU'

  welcome:
    kicker: 'ORNIFLIGHT STUDIO'
    title: 'Configura l’uccello. Comprendi il volo.'
    subtitle: 'Apri uno spazio di lavoro offline o connetti un controller OrniFlight. L’anteprima 3D si carica solo quando uno spazio la richiede.'
    connect: 'Connetti controller'
    choosing: 'Scegli controller…'
    reading: 'Lettura firmware…'
    offline: 'Apri spazio di lavoro offline'
    webSerialNotice: 'Questo browser non espone WebSerial. I profili offline restano disponibili.'
    lastController: 'ULTIMO CONTROLLER'
    session: 'SESSIONE'
    noController: 'Nessun controller connesso'
    profilesNote: 'Profili e strumenti di log funzionano senza firmware.'
    step1: '1 · Connetti'
    step2: '2 · Confronta'
    step3: '3 · Applica'
    intro_markdown: "## Un uccello, tre respiri\n\n**Piano corporeo** ordina kernel, mixer e trim. **Dinamica del battito** plasma il battito per profilo di volo. **Servi** nomina le superfici di controllo dell’uccello a ingranaggio.\n\n- *Azionamento diretto* — le coppie di ali oscillano sulla forma d’onda\n- *Ingranaggio* — timone, coda e motore come servi classici"
    legal_html: '<small>OrniFlight Studio — strumento di volo ermetico. Nessun volo senza mente.</small>'

  mixer:
    kernel:
      servo: 'Azionamento diretto'
      gearbox: 'Ingranaggio'
    surface:
      rudder: 'Timone'
      vtailLeft: 'Coda a V sx'
      vtailRight: 'Coda a V dx'
      elevator: 'Elevatore'
      motor: 'Motore'
    trim:
      leftWing: 'Ala sx'
      rightWing: 'Ala dx'
      backLeftWing: 'Ala sx posteriore'

  servo:
    input:
      none: 'Nessuno'
      stabRoll: 'Stab. Rollio'
      stabPitch: 'Stab. Beccheggio'
      stabYaw: 'Stab. Imbardata'
      stabThrottle: 'Stab. Gas'
      rcRoll: 'RC Rollio'
      rcPitch: 'RC Beccheggio'
      rcYaw: 'RC Imbardata'
      rcThrottle: 'RC Gas'
      aux1: 'AUX 1 (Canale 5)'
      aux2: 'AUX 2 (Canale 6)'
      aux3: 'AUX 3 (Canale 7)'
      aux4: 'AUX 4 (Canale 8)'
    channel: 'Servo {n}'

  servos:
    kicker: 'CONFIGURAZIONE BASE · SERVI'
    title: 'Servi'
    hermes_markdown: "**Superfici di controllo** dell’uccello a ingranaggio: ogni timone, coda o motore dichiarato dal mixer riceve una sorgente di input con nome e un canale di destinazione. Le coppie di ali — i servi di battito — si configurano in *Dinamica del battito*."
    simulation: 'SIMULAZIONE'
    device: 'DISPOSITIVO'
    read: 'Leggi dispositivo'
    save: 'Salva'
    revert: 'Annulla'
    emptyHeading: 'Nessuna superficie di controllo'
    emptySub: 'Questo mixer porta solo coppie di ali.'
    emptyNote: 'I servi di battito di questo mixer {mixer} si configurano come coppie di ali in Dinamica del battito — non qui.'
    sectionHeading: 'Superfici di controllo'
    sectionSub: 'Sorgente di input e canale di destinazione per superficie — solo i servi di questo mixer ({count}).'
    inputSource: 'Sorgente di input'
    targetChannel: 'Canale di destinazione'

  math:
    layer:
      cadence:
        name: 'Cadenza'
        role: 'Definisce la velocità del battito in risposta al beccheggio.'
      ferocity:
        name: 'Ferocia'
        role: 'Plasma la durezza di ogni battito — sensazione di potenza vs. planata.'
      balance:
        name: 'Equilibrio'
        role: 'Ripartisce la spinta tra discesa e salita per un volo livellato.'
      warp:
        name: 'Warp'
        role: 'Divide la forza del battito sinistra/destra per il controllo del rollio.'
      anchor:
        name: 'Ancora'
        role: 'Smorza l’oscillazione affinché il battito si stabilizzi.'
      resonance:
        name: 'Risonanza'
        role: 'Filtra la vibrazione alla frequenza di battito per un segnale più pulito.'
      prescience:
        name: 'Prescienza'
        role: 'Anticipa il battito successivo per correzioni puntuali.'
      espelho:
        name: 'Espelho'
        role: 'Cancella la vibrazione propria delle ali nei sensori.'
      saudade:
        name: 'Saudade'
        role: 'Impara da ogni battito e regola una piccola correzione costante.'
      aeroelastic:
        name: 'Aeroelastico'
        role: 'Regola la forza di controllo tra planata e battito.'
    param:
      cadence_gain:
        label: 'Avanzamento di fase'
        role: 'Lega la richiesta di beccheggio all’anticipo del battito.'
      ferocity_p_gain:
        label: 'Ferocia P'
        role: 'La richiesta di beccheggio indurisce la discesa per più spinta.'
      ferocity_d_gain:
        label: 'Ferocia D'
        role: 'Lo smorzamento di velocità ammorbidisce il ritorno.'
      ferocity_roll_gain:
        label: 'Ferocia Rollio'
        role: 'La richiesta di rollio ripartisce la forza tra le due ali.'
      ferocity_yaw_gain:
        label: 'Ferocia Imbardata'
        role: 'La richiesta di imbardata ripartisce la forza tra le due ali.'
      ferocity_downstroke:
        label: 'Forma di discesa'
        role: 'Nettezza della discesa — 1 seno morbido, 100 dwell duro.'
      ferocity_upstroke:
        label: 'Forma di salita'
        role: 'Nettezza della salita — 1 seno morbido, 100 dwell duro.'
      balance_gain:
        label: 'Bias di spinta'
        role: 'Ripartisce la spinta tra discesa e salita.'
      warp_gain:
        label: 'Differenziale warp'
        role: 'Divide la forza sinistra/destra per l’autorità di rollio.'
      warp_yaw_gain:
        label: 'Warp imbardata'
        role: 'Divide la forza sinistra/destra per l’autorità di imbardata.'
      anchor_gain:
        label: 'Ancora di smorzamento'
        role: 'Smorza l’oscillazione affinché il battito si stabilizzi.'
      resonance_gain:
        label: 'Filtro di risonanza'
        role: 'Filtra la vibrazione alla frequenza di battito dal segnale.'
      prescience_gain:
        label: 'Predizione del battito'
        role: 'Anticipa il battito successivo dalla frequenza.'
      espelho_gain:
        label: 'Cancellazione del rumore'
        role: 'Cancella il rumore proprio delle ali nella lettura.'
      saudade_gain:
        label: 'Memoria del battito'
        role: 'Impara una piccola correzione costante da ogni battito.'
      ssff_gain:
        label: 'SSFF'
        role: 'Anticipa col battito; la prescienza ne elimina il ritardo.'
      aeroelastic_glide_coefficient:
        label: 'Scala di planata'
        role: 'Scala la risposta di controllo in planata.'
      aeroelastic_flap_coefficient:
        label: 'Scala di battito'
        role: 'Scala la risposta di controllo in battito.'
    showLayer: 'Mostra {name}'
    downstroke: '⬇ Discesa'
    upstroke: '⬆ Salita'
    asymmetry: 'Asimmetria {value}%'

  airframe:
    field:
      wingSpan:
        label: 'Apertura'
        hermes: 'Apertura alare della cellula.'
      chord:
        label: 'Corda'
        hermes: 'Corda alare media.'
      totalMass:
        label: 'Massa'
        hermes: 'Massa al decollo.'
      cgX:
        label: 'CG longitudinale'
        hermes: 'Posizione del CG, + verso il muso.'
      cgZ:
        label: 'CG verticale'
        hermes: 'Altezza sopra il piano alare.'
      cgLat:
        label: 'CG laterale'
        hermes: 'Equilibrio di rollio, + a destra.'
    mount:
      angle:
        label: 'Angolo di montaggio'
        hermes: 'Angolo di incidenza del servo.'
      station:
        label: 'Posizione'
        hermes: 'Posizione avanti/indietro dell’asse del CG.'
      vertical:
        label: 'Verticale'
        hermes: 'Altezza sopra/sotto il piano alare.'

  common:
    simulation: 'SIMULAZIONE'
    device: 'DISPOSITIVO'
    unsaved: 'NON SALVATO'
    saved: 'SALVATO'
    read: 'Leggi dispositivo'
    save: 'Salva'
    revert: 'Annulla'

  pid:
    kicker: 'CONTROLLO · CONTROLLO DI VOLO'
    title: 'Controllo di volo'
    hermes: 'Il nucleo di controllo: dodici guadagni PID su quattro assi, rate e filtri. La stabilizzazione ONDAS vive in Dinamica del battito — una sola verità.'
    simBanner: 'SIMULAZIONE — i valori non vengono salvati'
    bank: 'Banca PID'
    bankSub: 'Quattro assi, tre termini ciascuno — ogni blocco d’asse è un battito del controllore.'
    rates: 'Rate'
    ratesSub: 'Plasma la risposta dello stick — rate RC, super rate, expo.'
    filters: 'Filtri'
    filtersSub: 'Filtraggio giroscopio e termine D (MSP 92).'
    ondas: 'ONDAS'
    ondasSub: 'La stabilizzazione ONDAS è mantenuta solo in Dinamica del battito — qui vive il riferimento.'
    ondasNote: 'Diciotto regolazioni in dieci stadi accoppiati. Perché PID e Dinamica del battito non pilotino due volte, la suite apre la bozza ONDAS completa.'
    ondasCta: 'Apri ONDAS → Dinamica del battito'
    rcRate: 'Rate RC'
    superRate: 'Super rate'
    expo: 'Expo'
    gyroDlpf: 'Giro DLPF'
    gyroNotch: 'Notch giro'
    notchQ: 'Q notch'
    dTermDlpf: 'DLPF termine D'

  profiles:
    kicker: 'PROFILI DI VOLO'
    hermes: 'Quattro profili, selezionati dal modo profilo ornitottero (box AUX). Ognuno porta angolo di planata e forma di battito — la Dinamica del battito agisce sempre sul profilo attivo.'
    auxBadge: 'AUX · IL BOX SELEZIONA'
    active: 'ATTIVO'
    profile: 'Profilo {n}'
    glide: 'Angolo di planata'
    stroke: 'Battito {stroke} · Ritorno {ret} · Mix {mix}'
    editActive: 'Modifica questo profilo in Dinamica del battito →'
    editInactive: 'Attiva e apri Dinamica del battito →'
    activeNote: 'Profilo attivo — guadagni ONDAS e forma di battito in vigore.'
    inactiveNote: 'Inattivo — il box AUX seleziona questo profilo.'

  modes:
    kicker: 'CONTROLLO · MODALITÀ DI VOLO'
    title: 'Modalità di volo'
    hermes: 'Venti slot AUX contro il flusso di canali — box, canale e banda 900–2100 µs. Una riga si accende quando il suo canale è nel range.'
    noteHeading: 'Modalità di volo'
    noteSub: 'Range AUX armati contro il flusso di canali.'
    noteAcro: '{name} è implicita — il default quando nessun range è attivo.'
    rangeHeading: 'Logica di range'
    rangeNote: 'Le colonne extra (AND / OR / XOR, box collegato) appaiono quando il firmware espone MSP 238.'
    rangeWarn: 'Firmware legacy — logica e collegamenti ai valori predefiniti.'
    mainHeading: 'Range modalità AUX'
    mainSub: '20 slot di attivazione — box, canale AUX e banda 900–2100 µs.'

  receiver:
    kicker: 'CONTROLLO · RICEVENTE'
    title: 'Ricevente'
    hermes: 'Documento della ricevente: provider e limiti di impulso, mappatura canali, slot di sicurezza e flusso di canali mappato.'
    protocol: 'Protocollo RX'
    protocolSub: 'Provider della ricevente seriale e limiti di impulso (MSP 44).'
    maxCheck: 'Controllo max'
    midRc: 'RC medio'
    minCheck: 'Controllo min'
    rxMinPulse: 'Impulso RX min'
    rxMaxPulse: 'Impulso RX max'
    airmodeThreshold: 'Soglia airmode'
    channelMap: 'Mappa canali'
    channelMapSub: 'Ingressi logici verso canali fisici (MSP 64).'
    failsafeChannels: 'Canali di sicurezza'
    failsafeChannelsSub: 'Comportamento di perdita per canale — slot 750–2250 µs (MSP 77).'
    channel: 'Canale {n}'
    liveChannels: 'Canali in tempo reale'
    liveChannelsSub: 'Flusso di canali fisici — anteprima mappata del documento ricevente.'

  adjustments:
    kicker: 'CONTROLLO · REGOLAZIONI'
    title: 'Regolazioni'
    hermes: 'Regolatori in volo: trenta slot, sei byte ciascuno (MSP 52/53). Uno slot si arma quando il suo canale AUX è nel range.'
    heading: 'Slot di regolazione'
    sub: 'Range canale 900 – 2100 µs in passi da 25 µs; le funzioni rispecchiano la tabella del firmware (0 = nessuna).'
    note: 'Solo gli slot modificati inviano SET + EEPROM_WRITE al salvataggio.'
    slot: 'Slot {n}'
    function: 'Funzione'
    adjustmentSlot: 'Slot di regolazione'
    channel: 'Canale'
    rangeStart: 'Inizio range'
    rangeEnd: 'Fine range'
    switchChannel: 'Canale di commutazione'

  cli:
    title: 'Terminale CLI'
    subtitle: 'Console di testo del controllore di volo'
    live: '● IN TEMPO REALE'
    simulation: '◌ SIMULAZIONE'
    open: 'Apri CLI dispositivo'
    exit: 'Esci dal CLI'
    clear: 'Pulisci'
    idle: '─ inattivo ─'
    placeholderLive: 'digita un comando — tab completa'
    placeholderSim: 'simulazione — prova help, version, status'
    commandInput: 'Input comando CLI'
    output: 'Output CLI'

  schlagdynamik:
    kicker: 'CONTROLLO · DINAMICA DEL BATTITO'
    title: 'Dinamica del battito'
    hermes: 'La stabilizzazione del battito: diciotto regolazioni in dieci stadi accoppiati — dall’errore di controllo al movimento di battito agganciato in fase. Ogni stadio spiega cosa fa per il volo; lo specchio Espelho legge l’asimmetria del battito in tempo reale.'
    profileChip: 'Profilo {n} · obiettivo ONDAS'
    espelho: '→ Espelho'
    signalChain: 'Catena di segnale'
    signalChainSub: 'Dieci stadi nella direzione di volo — dall’errore di controllo al movimento di battito. Un clic porta lo stadio in vista.'
    waveform: 'Forma d’onda'
    waveformSub: 'Un ciclo di battito completo dal nucleo d’onda — l’ancora fissa degli stadi.'
    down: '⬇ Discesa {v}%'
    asymmetry: 'Asimmetria {v}%'
    up: '⬆ Salita {v}%'
    hzLive: '{hz} Hz · in tempo reale'
    rest: 'Riposo — nessuna frequenza di battito'
    espelhoHeading: 'Diagnostica di asimmetria Espelho'
    espelhoSub: 'Lo specchio: |2ª armonica| / |fondamentale| del movimento di battito — l’impronta dell’asimmetria.'
    debugEspelho: 'DEBUG_ESPELHO'
    simDerived: 'SIM · derivato dal battito'
    phase: 'FASE'

  ornithopter:
    hermes: 'Piano corporeo · Cellula. Il lato di azionamento dell’uccello, una vista per articolazione.'
    craftName: 'NOME DELL’APPARECCHIO'
    craftNameNote: 'Il nome di sistema è portato dal controllore (MSP_NAME, 16 caratteri) e mantenuto in Sistema → Dispositivo.'
    editInSystem: 'Modifica in Sistema → Dispositivo'
    kernel: 'Kernel'
    kernelNote: 'Azionamento diretto o ingranaggio.'
    studio: 'STUDIO'
    mixerProfile: 'Profilo mixer'
    mixerProfileNote: 'Assegnazione GPIO secondo il firmware.'
    gpioMap: 'Mappa GPIO'
    strokeTime: 'Tempo di battito'
    strokeTimeNote: 'servo_travel_time_ms del firmware — millisecondi per battito di 60° (30–500).'
    tempo: '— Tempo —'
    trims: 'Trim'
    trimsNote: 'Posizione di riposo di ogni articolazione con input neutro.'
    bodyHermes: 'Kernel e mixer: come l’azionamento tende l’ala — dritto nell’articolazione o tramite un ingranaggio.'
    airframeHermes: 'Apertura, massa e centro di gravità — la cellula che porta il battito.'
    wingArea: 'Superficie alare {area} cm²'
    aspectRatio: 'Allungamento {ratio}'
    servoMount: 'Montaggio servo'
    servoMountNote: 'Posizione di ogni coppia di ali: angolo, posizione, altezza.'
    pair: 'Coppia {n}'
    footer: 'Piano corporeo in Studio · GPIO nel firmware · ali nel cielo.'
    mixerOption: '{name} — {n} servi'
    simulation: '{name} (Simulazione)'

  app:
    kicker: 'SISTEMA · APP'
    title: 'Impostazioni app'
    subtitle: 'Lingua e preferenze dell’area di lavoro — salvate in questo browser.'
    interface: 'Interfaccia'
    interfaceSub: 'Queste impostazioni vivono nel tuo browser. Niente qui viene scritto sul controllore.'
    language: 'Lingua'
    languageSub: 'Scegli la lingua dell’interfaccia. La scelta viene ricordata su questo dispositivo.'
    appearance: 'Aspetto'
    appearanceSub: 'Tema e layout dell’area di lavoro.'
    theme: 'Tema'
    layout: 'Layout dell’area di lavoro'
