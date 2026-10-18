###
# ORNIFLIGHT STUDIO — French message catalog
###
export default
  nav:
    modules:
      basic:    'Configuration de base'
      profiles: 'Profils de vol'
      servos:   'Servos'
      control:  'Contrôle'
      sensors:  'Capteurs'
      system:   'Système'
      safety:   'Sécurité'
      cli:      'CLI'
    subtabs:
      basic:
        body:    'Plan corporel'
        airframe: 'Cellule'
      profiles:
        profiles: 'Profils'
      servos:
        servos: 'Servos'
      control:
        pid:           'PID'
        schlagdynamik: 'Dynamique de battement'
        modes:         'Modes'
        receiver:      'Récepteur'
        adjustments:   'Réglages'
      sensors:
        hardware: 'Capteurs'
        gyro:     'Gyroscope'
      system:
        device: 'Appareil'
        ports:  'Ports'
        power:  'Énergie'
        vtx:    'VTX'
        osd:    'OSD'
        voice:  'Voix'
        memory: 'Mémoire'
        flash:  'La Mue'
        data:   'Données'
        app:    'App'
      safety:
        failsafe: 'Sécurité intégrée'
      cli:
        cli: 'CLI'

  chrome:
    skip: 'Aller au contenu'
    connect: 'Connecter'
    disconnect: 'Déconnecter'
    selecting: 'Sélection…'
    syncing: 'Synchronisation…'
    connectTooltip: 'Connecter un contrôleur OrniFlight via WebSerial'
    connectUnsupported: 'WebSerial n’est pas disponible dans ce navigateur'
    liveState: 'État de la connexion en direct'
    flapFrequency: 'Fréquence de battement actuelle'
    batteryVoltage: 'Tension de la batterie de vol'
    version: 'Version du Studio'
    commands: 'Ouvrir la palette de commandes · Ctrl/⌘ K'
    state: 'Basculer l’inspecteur d’état · Ctrl/⌘ Maj D'
    theme: 'Basculer thème clair et sombre'
    layout: 'Changer la disposition de l’espace de travail'
    flap: 'Battement'
    battery: 'Batterie'
    commandsLabel: 'COMMANDES'
    stateLabel: 'ÉTAT'
    primaryNav: 'Navigation principale'
    toolbar: 'Barre d’outils du Studio'

  commands:
    connect: 'Connecter l’appareil'
    disconnect: 'Déconnecter l’appareil'
    toggleTheme: 'Basculer le thème'
    placeholder: 'Naviguer ou exécuter une commande…'
    empty: 'Aucune commande correspondante'
    footer: '↑↓ sélectionner · ↵ exécuter · Ctrl/⌘ K basculer'
    ariaLabel: 'Commandes du Studio'

  conn:
    state:
      disconnected: 'Déconnecté'
      scanning: 'Recherche…'
      handshaking: 'Synchronisation…'
      connected: 'Connecté'
    breathing: 'RESPIRATION'
    offlineProfile: 'PROFIL HORS LIGNE'
    deviceConnected: 'APPAREIL CONNECTÉ'
    controller: 'Contrôleur'
    simulation: 'Simulation'
    armed: 'ARMÉ'
    disarmed: 'DÉSARMÉ'

  shell:
    system: 'Système'
    inspector: 'Inspecteur'
    module: 'Module'
    connection: 'Connexion'
    source: 'Source'
    device: 'Appareil'
    firmware: 'Firmware'
    target: 'Cible'
    status: 'État'
    live: 'Direct'
    voltage: 'Tension'
    cpu: 'CPU'

  welcome:
    kicker: 'ORNIFLIGHT STUDIO'
    title: 'Configurez l’oiseau. Comprenez le vol.'
    subtitle: 'Ouvrez un espace hors ligne ou connectez un contrôleur OrniFlight. La prévisualisation 3D ne se charge que si un espace en a besoin.'
    connect: 'Connecter le contrôleur'
    choosing: 'Choisir le contrôleur…'
    reading: 'Lecture du firmware…'
    offline: 'Ouvrir un espace hors ligne'
    webSerialNotice: 'Ce navigateur n’expose pas WebSerial. Les profils hors ligne restent disponibles.'
    lastController: 'DERNIER CONTRÔLEUR'
    session: 'SESSION'
    noController: 'Aucun contrôleur connecté'
    profilesNote: 'Les profils et les outils de journalisation fonctionnent sans firmware.'
    step1: '1 · Connecter'
    step2: '2 · Comparer'
    step3: '3 · Appliquer'
    intro_markdown: "## Un oiseau, trois souffles\n\n**Plan corporel** ordonne noyau, mixeur et trims. **Dynamique de battement** façonne le battement par profil de vol. **Servos** nomme les surfaces de contrôle de l’oiseau à engrenage.\n\n- *Entraînement direct* — les paires d’ailes oscillent sur la forme d’onde\n- *Engrenage* — gouverne, queue et moteur en servos classiques"
    legal_html: '<small>OrniFlight Studio — instrument de vol hermétique. Pas de vol sans esprit.</small>'

  mixer:
    kernel:
      servo: 'Entraînement direct'
      gearbox: 'Engrenage'
    surface:
      rudder: 'Gouverne'
      vtailLeft: 'Queue en V gauche'
      vtailRight: 'Queue en V droite'
      elevator: 'Profondeur'
      motor: 'Moteur'
    trim:
      leftWing: 'Aile gauche'
      rightWing: 'Aile droite'
      backLeftWing: 'Aile gauche arrière'

  servo:
    input:
      none: 'Aucun'
      stabRoll: 'Stab. Roulis'
      stabPitch: 'Stab. Tangage'
      stabYaw: 'Stab. Lacet'
      stabThrottle: 'Stab. Gaz'
      rcRoll: 'RC Roulis'
      rcPitch: 'RC Tangage'
      rcYaw: 'RC Lacet'
      rcThrottle: 'RC Gaz'
      aux1: 'AUX 1 (Canal 5)'
      aux2: 'AUX 2 (Canal 6)'
      aux3: 'AUX 3 (Canal 7)'
      aux4: 'AUX 4 (Canal 8)'
    channel: 'Servo {n}'

  servos:
    kicker: 'CONFIGURATION DE BASE · SERVOS'
    title: 'Servos'
    hermes_markdown: "**Surfaces de contrôle** de l’oiseau à engrenage : chaque gouverne, queue ou moteur déclaré par le mixeur reçoit une source d’entrée nommée et un canal cible. Les paires d’ailes — les servos de battement — se configurent dans *Dynamique de battement*."
    simulation: 'SIMULATION'
    device: 'APPAREIL'
    read: 'Lire l’appareil'
    save: 'Enregistrer'
    revert: 'Annuler'
    emptyHeading: 'Aucune surface de contrôle'
    emptySub: 'Ce mixeur ne porte que des paires d’ailes.'
    emptyNote: 'Les servos de battement de ce mixeur {mixer} se configurent comme paires d’ailes dans Dynamique de battement — pas ici.'
    sectionHeading: 'Surfaces de contrôle'
    sectionSub: 'Source d’entrée et canal cible par surface — uniquement les servos de ce mixeur ({count}).'
    inputSource: 'Source d’entrée'
    targetChannel: 'Canal cible'

  math:
    layer:
      cadence:
        name: 'Cadence'
        role: 'Définit la vitesse de battement en réponse au tangage.'
      ferocity:
        name: 'Férocité'
        role: 'Façonne la dureté de chaque battement — sensation de puissance vs. plané.'
      balance:
        name: 'Équilibre'
        role: 'Répartit la poussée entre descente et montée pour un vol stable.'
      warp:
        name: 'Warp'
        role: 'Divise la force du battement gauche/droite pour le contrôle du roulis.'
      anchor:
        name: 'Ancre'
        role: 'Amortit l’oscillation pour que le battement se stabilise.'
      resonance:
        name: 'Résonance'
        role: 'Filtre la vibration à la fréquence de battement pour un signal plus propre.'
      prescience:
        name: 'Prescience'
        role: 'Anticipe le battement suivant pour des corrections à temps.'
      espelho:
        name: 'Espelho'
        role: 'Annule la vibration propre des ailes dans les capteurs.'
      saudade:
        name: 'Saudade'
        role: 'Apprend de chaque battement et ajuste une petite correction constante.'
      aeroelastic:
        name: 'Aéroélastique'
        role: 'Ajuste la force de contrôle entre plané et battement.'
    param:
      cadence_gain:
        label: 'Avance de phase'
        role: 'Lie la demande de tangage à l’avance du battement.'
      ferocity_p_gain:
        label: 'Férocité P'
        role: 'La demande de tangage durcit la descente pour plus de poussée.'
      ferocity_d_gain:
        label: 'Férocité D'
        role: 'L’amortissement de vitesse adoucit le retour.'
      ferocity_roll_gain:
        label: 'Férocité Roulis'
        role: 'La demande de roulis répartit la force entre les deux ailes.'
      ferocity_yaw_gain:
        label: 'Férocité Lacet'
        role: 'La demande de lacet répartit la force entre les deux ailes.'
      ferocity_downstroke:
        label: 'Forme de descente'
        role: 'Netteté de la descente — 1 sinus doux, 100 dwell dur.'
      ferocity_upstroke:
        label: 'Forme de montée'
        role: 'Netteté de la montée — 1 sinus doux, 100 dwell dur.'
      balance_gain:
        label: 'Biais de poussée'
        role: 'Répartit la poussée entre descente et montée.'
      warp_gain:
        label: 'Différentiel warp'
        role: 'Divise la force gauche/droite pour l’autorité en roulis.'
      warp_yaw_gain:
        label: 'Warp lacet'
        role: 'Divise la force gauche/droite pour l’autorité en lacet.'
      anchor_gain:
        label: 'Ancre d’amortissement'
        role: 'Amortit l’oscillation pour que le battement se stabilise.'
      resonance_gain:
        label: 'Filtre de résonance'
        role: 'Filtre la vibration à la fréquence de battement du signal.'
      prescience_gain:
        label: 'Prédiction du battement'
        role: 'Anticipe le battement suivant à partir de la fréquence.'
      espelho_gain:
        label: 'Annulation du bruit'
        role: 'Annule le bruit propre des ailes dans la lecture.'
      saudade_gain:
        label: 'Mémoire du battement'
        role: 'Apprend une petite correction constante de chaque battement.'
      ssff_gain:
        label: 'SSFF'
        role: 'Anticipe avec le battement ; la prescience supprime son retard.'
      aeroelastic_glide_coefficient:
        label: 'Échelle de plané'
        role: 'Échelle la réponse de contrôle en vol plané.'
      aeroelastic_flap_coefficient:
        label: 'Échelle de battement'
        role: 'Échelle la réponse de contrôle en vol battu.'
    showLayer: 'Afficher {name}'
    downstroke: '⬇ Descente'
    upstroke: '⬆ Montée'
    asymmetry: 'Asymétrie {value}%'

  airframe:
    field:
      wingSpan:
        label: 'Envergure'
        hermes: 'Envergure de l’aile.'
      chord:
        label: 'Corde'
        hermes: 'Corde moyenne de l’aile.'
      totalMass:
        label: 'Masse'
        hermes: 'Masse au décollage.'
      cgX:
        label: 'CG longitudinal'
        hermes: 'Position du CG, + vers le nez.'
      cgZ:
        label: 'CG vertical'
        hermes: 'Hauteur au-dessus du plan de l’aile.'
      cgLat:
        label: 'CG latéral'
        hermes: 'Équilibre en roulis, + à droite.'
    mount:
      angle:
        label: 'Angle de montage'
        hermes: 'Angle d’incidence du servo.'
      station:
        label: 'Position'
        hermes: 'Position avant/arrière de l’axe du CG.'
      vertical:
        label: 'Vertical'
        hermes: 'Hauteur au-dessus/sous le plan de l’aile.'

  common:
    simulation: 'SIMULATION'
    device: 'APPAREIL'
    unsaved: 'NON ENREGISTRÉ'
    saved: 'ENREGISTRÉ'
    read: 'Lire l’appareil'
    save: 'Enregistrer'
    revert: 'Annuler'

  pid:
    kicker: 'CONTRÔLE · CONTRÔLE DE VOL'
    title: 'Contrôle de vol'
    hermes: 'Le cœur du contrôle : douze gains PID sur quatre axes, taux et filtres. La stabilisation ONDAS vit dans Dynamique de battement — une seule vérité.'
    simBanner: 'SIMULATION — les valeurs ne sont pas enregistrées'
    bank: 'Banque PID'
    bankSub: 'Quatre axes, trois termes chacun — chaque bloc d’axe est un battement du contrôleur.'
    rates: 'Taux'
    ratesSub: 'Façonne la réponse du manche — taux RC, super taux, expo.'
    filters: 'Filtres'
    filtersSub: 'Filtrage gyro et terme D (MSP 92).'
    ondas: 'ONDAS'
    ondasSub: 'La stabilisation ONDAS n’est maintenue que dans Dynamique de battement — ici vit la référence.'
    ondasNote: 'Dix-huit réglages en dix étages couplés. Pour que PID et Dynamique de battement ne pilotent pas deux fois, la suite ouvre le brouillon ONDAS complet.'
    ondasCta: 'Ouvrir ONDAS → Dynamique de battement'
    rcRate: 'Taux RC'
    superRate: 'Super taux'
    expo: 'Expo'
    gyroDlpf: 'Gyro DLPF'
    gyroNotch: 'Encoche gyro'
    notchQ: 'Q d’encoche'
    dTermDlpf: 'DLPF terme D'

  profiles:
    kicker: 'PROFILS DE VOL'
    hermes: 'Quatre profils, sélectionnés par le mode profil ornithoptère (boîte AUX). Chacun porte angle de plané et forme de battement — la Dynamique de battement agit toujours sur le profil actif.'
    auxBadge: 'AUX · LA BOÎTE SÉLECTIONNE'
    active: 'ACTIF'
    profile: 'Profil {n}'
    glide: 'Angle de plané'
    stroke: 'Battement {stroke} · Retour {ret} · Mix {mix}'
    editActive: 'Modifier ce profil dans Dynamique de battement →'
    editInactive: 'Activer et ouvrir Dynamique de battement →'
    activeNote: 'Profil actif — gains ONDAS et forme de battement en vigueur.'
    inactiveNote: 'Inactif — la boîte AUX sélectionne ce profil.'

  modes:
    kicker: 'CONTRÔLE · MODES DE VOL'
    title: 'Modes de vol'
    hermes: 'Vingt créneaux AUX contre le flux de canaux — boîte, canal et bande 900–2100 µs. Une ligne s’allume quand son canal est dans la plage.'
    noteHeading: 'Modes de vol'
    noteSub: 'Plages AUX armées contre le flux de canaux.'
    noteAcro: '{name} est implicite — le défaut quand aucune plage n’est active.'
    rangeHeading: 'Logique de plage'
    rangeNote: 'Les colonnes supplémentaires (AND / OR / XOR, boîte liée) apparaissent quand le firmware expose MSP 238.'
    rangeWarn: 'Firmware hérité — logique et liens à leurs valeurs par défaut.'
    mainHeading: 'Plages de mode AUX'
    mainSub: '20 créneaux d’activation — boîte, canal AUX et bande 900–2100 µs.'

  receiver:
    kicker: 'CONTRÔLE · RÉCEPTEUR'
    title: 'Récepteur'
    hermes: 'Document du récepteur : fournisseur et bornes de pulsation, mappage des canaux, créneaux de sécurité et flux de canaux mappé.'
    protocol: 'Protocole RX'
    protocolSub: 'Fournisseur du récepteur série et bornes de pulsation (MSP 44).'
    maxCheck: 'Contrôle max'
    midRc: 'RC milieu'
    minCheck: 'Contrôle min'
    rxMinPulse: 'Pulsation RX min'
    rxMaxPulse: 'Pulsation RX max'
    airmodeThreshold: 'Seuil airmode'
    channelMap: 'Mappage des canaux'
    channelMapSub: 'Entrées logiques vers canaux physiques (MSP 64).'
    failsafeChannels: 'Canaux de sécurité'
    failsafeChannelsSub: 'Comportement de perte par canal — créneaux 750–2250 µs (MSP 77).'
    channel: 'Canal {n}'
    liveChannels: 'Canaux en direct'
    liveChannelsSub: 'Flux de canaux physiques — aperçu mappé du document du récepteur.'

  adjustments:
    kicker: 'CONTRÔLE · RÉGLAGES'
    title: 'Réglages'
    hermes: 'Régulateurs en vol : trente créneaux, six octets chacun (MSP 52/53). Un créneau s’arme dès que son canal AUX est dans la plage.'
    heading: 'Créneaux de réglage'
    sub: 'Plage de canal 900 – 2100 µs par pas de 25 µs ; les fonctions reflètent la table du firmware (0 = aucune).'
    note: 'Seuls les créneaux modifiés envoient SET + EEPROM_WRITE à l’enregistrement.'
    slot: 'Créneau {n}'
    function: 'Fonction'
    adjustmentSlot: 'Créneau de réglage'
    channel: 'Canal'
    rangeStart: 'Début de plage'
    rangeEnd: 'Fin de plage'
    switchChannel: 'Canal de commutation'

  cli:
    title: 'Terminal CLI'
    subtitle: 'Console texte du contrôleur de vol'
    live: '● DIRECT'
    simulation: '◌ SIMULATION'
    open: 'Ouvrir le CLI de l’appareil'
    exit: 'Quitter le CLI'
    clear: 'Effacer'
    idle: '─ inactif ─'
    placeholderLive: 'tapez une commande — tab complète'
    placeholderSim: 'simulation — essayez help, version, status'
    commandInput: 'Entrée de commande CLI'
    output: 'Sortie CLI'

  schlagdynamik:
    kicker: 'CONTRÔLE · DYNAMIQUE DE BATTEMENT'
    title: 'Dynamique de battement'
    hermes: 'La stabilisation du battement : dix-huit réglages en dix étages couplés — de l’erreur de contrôle au mouvement de battement verrouillé en phase. Chaque étage explique ce qu’il fait pour le vol ; le miroir Espelho lit l’asymétrie du battement en direct.'
    profileChip: 'Profil {n} · cible ONDAS'
    espelho: '→ Espelho'
    signalChain: 'Chaîne de signal'
    signalChainSub: 'Dix étages dans le sens du vol — de l’erreur de contrôle au mouvement de battement. Un clic amène l’étage en vue.'
    waveform: 'Forme d’onde'
    waveformSub: 'Un cycle de battement complet du noyau d’onde — l’ancre fixe des étages.'
    down: '⬇ Descente {v}%'
    asymmetry: 'Asymétrie {v}%'
    up: '⬆ Montée {v}%'
    hzLive: '{hz} Hz · direct'
    rest: 'Repos — aucune fréquence de battement'
    espelhoHeading: 'Diagnostic d’asymétrie Espelho'
    espelhoSub: 'Le miroir : |2e harmonique| / |fondamentale| du mouvement de battement — l’empreinte de l’asymétrie.'
    debugEspelho: 'DEBUG_ESPELHO'
    simDerived: 'SIM · dérivé du battement'
    phase: 'PHASE'

  ornithopter:
    hermes: 'Plan corporel · Cellule. Le côté entraînement de l’oiseau, une vue par articulation.'
    craftName: 'NOM DE L’APPAREIL'
    craftNameNote: 'Le nom du système est porté par le contrôleur (MSP_NAME, 16 caractères) et maintenu dans Système → Appareil.'
    editInSystem: 'Modifier dans Système → Appareil'
    kernel: 'Noyau'
    kernelNote: 'Entraînement direct ou engrenage.'
    studio: 'STUDIO'
    mixerProfile: 'Profil de mixeur'
    mixerProfileNote: 'Affectation GPIO selon le firmware.'
    gpioMap: 'Carte GPIO'
    strokeTime: 'Temps de battement'
    strokeTimeNote: 'servo_travel_time_ms du firmware — millisecondes par battement de 60° (30–500).'
    tempo: '— Tempo —'
    trims: 'Trims'
    trimsNote: 'Position de repos de chaque articulation à entrée neutre.'
    bodyHermes: 'Noyau et mixeur : comment l’entraînement tend l’aile — directement dans l’articulation ou via un engrenage.'
    airframeHermes: 'Envergure, masse et centre de gravité — la cellule que porte le battement.'
    wingArea: 'Surface alaire {area} cm²'
    aspectRatio: 'Allongement {ratio}'
    servoMount: 'Montage du servo'
    servoMountNote: 'Position de chaque paire d’ailes : angle, position, hauteur.'
    pair: 'Paire {n}'
    footer: 'Plan corporel dans Studio · GPIO dans le firmware · ailes dans le ciel.'
    mixerOption: '{name} — {n} servos'
    simulation: '{name} (Simulation)'

  app:
    kicker: 'SYSTÈME · APP'
    title: 'Réglages de l’app'
    subtitle: 'Langue et préférences de l’espace de travail — enregistrées dans ce navigateur.'
    interface: 'Interface'
    interfaceSub: 'Ces réglages vivent dans votre navigateur. Rien ici n’est écrit sur le contrôleur.'
    language: 'Langue'
    languageSub: 'Choisissez la langue de l’interface. Votre choix est mémorisé sur cet appareil.'
    appearance: 'Apparence'
    appearanceSub: 'Thème et disposition de l’espace de travail.'
    theme: 'Thème'
    layout: 'Disposition de l’espace de travail'
