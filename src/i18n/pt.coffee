###
# ORNIFLIGHT STUDIO — Portuguese message catalog
###
export default
  nav:
    modules:
      basic:    'Configuração básica'
      profiles: 'Perfis de voo'
      servos:   'Servos'
      control:  'Controlo'
      sensors:  'Sensores'
      system:   'Sistema'
      safety:   'Segurança'
      cli:      'CLI'
    subtabs:
      basic:
        body:    'Plano corporal'
        airframe: 'Estrutura'
      profiles:
        profiles: 'Perfis'
      servos:
        servos: 'Servos'
      control:
        pid:           'PID'
        schlagdynamik: 'Dinâmica de batimento'
        modes:         'Modos'
        receiver:      'Recetor'
        adjustments:   'Ajustes'
      sensors:
        hardware: 'Sensores'
        gyro:     'Giroscópio'
      system:
        device: 'Dispositivo'
        ports:  'Portas'
        power:  'Energia'
        vtx:    'VTX'
        osd:    'OSD'
        voice:  'Voz'
        memory: 'Memória'
        flash:  'A Muda'
        data:   'Dados'
        app:    'App'
      safety:
        failsafe: 'Proteção contra falhas'
      cli:
        cli: 'CLI'

  chrome:
    skip: 'Saltar para o conteúdo'
    connect: 'Ligar'
    disconnect: 'Desligar'
    selecting: 'A selecionar…'
    syncing: 'A sincronizar…'
    connectTooltip: 'Ligar um controlador OrniFlight por WebSerial'
    connectUnsupported: 'WebSerial não está disponível neste navegador'
    liveState: 'Estado da ligação em direto'
    flapFrequency: 'Frequência de batimento atual'
    batteryVoltage: 'Tensão da bateria de voo'
    version: 'Versão do Studio'
    commands: 'Abrir paleta de comandos · Ctrl/⌘ K'
    state: 'Alternar inspetor de estado · Ctrl/⌘ Shift D'
    theme: 'Alternar tema claro e escuro'
    layout: 'Mudar disposição da área de trabalho'
    flap: 'Batimento'
    battery: 'Bateria'
    commandsLabel: 'COMANDOS'
    stateLabel: 'ESTADO'
    primaryNav: 'Navegação principal'
    toolbar: 'Barra de ferramentas do Studio'

  commands:
    connect: 'Ligar dispositivo'
    disconnect: 'Desligar dispositivo'
    toggleTheme: 'Alternar tema'
    placeholder: 'Navegar ou executar um comando…'
    empty: 'Nenhum comando correspondente'
    footer: '↑↓ selecionar · ↵ executar · Ctrl/⌘ K alternar'
    ariaLabel: 'Comandos do Studio'

  conn:
    state:
      disconnected: 'Desligado'
      scanning: 'A procurar…'
      handshaking: 'A sincronizar…'
      connected: 'Ligado'
    breathing: 'A RESPIRAR'
    offlineProfile: 'PERFIL OFFLINE'
    deviceConnected: 'DISPOSITIVO LIGADO'
    controller: 'Controlador'
    simulation: 'Simulação'
    armed: 'ARMADO'
    disarmed: 'DESARMADO'

  shell:
    system: 'Sistema'
    inspector: 'Inspetor'
    module: 'Módulo'
    connection: 'Ligação'
    source: 'Fonte'
    device: 'Dispositivo'
    firmware: 'Firmware'
    target: 'Alvo'
    status: 'Estado'
    live: 'Em direto'
    voltage: 'Tensão'
    cpu: 'CPU'

  welcome:
    kicker: 'ORNIFLIGHT STUDIO'
    title: 'Configura o pássaro. Compreende o voo.'
    subtitle: 'Abre um espaço de trabalho offline ou liga um controlador OrniFlight. A pré-visualização 3D só carrega quando um espaço precisa dela.'
    connect: 'Ligar controlador'
    choosing: 'Escolher controlador…'
    reading: 'A ler firmware…'
    offline: 'Abrir espaço de trabalho offline'
    webSerialNotice: 'Este navegador não expõe WebSerial. Os perfis offline continuam disponíveis.'
    lastController: 'ÚLTIMO CONTROLADOR'
    session: 'SESSÃO'
    noController: 'Nenhum controlador ligado'
    profilesNote: 'Perfis e ferramentas de registo funcionam sem firmware.'
    step1: '1 · Ligar'
    step2: '2 · Comparar'
    step3: '3 · Aplicar'
    intro_markdown: "## Um pássaro, três respiros\n\n**Plano corporal** ordena kernel, misturador e trims. **Dinâmica de batimento** molda o batimento por perfil de voo. **Servos** nomeia as superfícies de controlo do pássaro de engrenagem.\n\n- *Acionamento direto* — pares de asas oscilam na forma de onda\n- *Engrenagem* — leme, cauda e motor como servos clássicos"
    legal_html: '<small>OrniFlight Studio — instrumento de voo hermético. Sem mente não há voo.</small>'

  mixer:
    kernel:
      servo: 'Acionamento direto'
      gearbox: 'Engrenagem'
    surface:
      rudder: 'Leme'
      vtailLeft: 'Cauda em V esq.'
      vtailRight: 'Cauda em V dir.'
      elevator: 'Elevador'
      motor: 'Motor'
    trim:
      leftWing: 'Asa esq.'
      rightWing: 'Asa dir.'
      backLeftWing: 'Asa esq. traseira'

  servo:
    input:
      none: 'Nenhum'
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
    kicker: 'CONFIGURAÇÃO BÁSICA · SERVOS'
    title: 'Servos'
    hermes_markdown: "**Superfícies de controlo** do pássaro de engrenagem: cada leme, cauda ou motor que o misturador declara recebe uma fonte de entrada com nome e um canal de destino. Os pares de asas — os servos de batimento — configuram-se em *Dinâmica de batimento*."
    simulation: 'SIMULAÇÃO'
    device: 'DISPOSITIVO'
    read: 'Ler dispositivo'
    save: 'Guardar'
    revert: 'Reverter'
    emptyHeading: 'Sem superfícies de controlo'
    emptySub: 'Este misturador só tem pares de asas.'
    emptyNote: 'Os servos de batimento deste misturador {mixer} configuram-se como pares de asas em Dinâmica de batimento — não aqui.'
    sectionHeading: 'Superfícies de controlo'
    sectionSub: 'Fonte de entrada e canal de destino por superfície — apenas os servos deste misturador ({count}).'
    inputSource: 'Fonte de entrada'
    targetChannel: 'Canal de destino'

  math:
    layer:
      cadence:
        name: 'Cadência'
        role: 'Define a velocidade do batimento em resposta ao pitch.'
      ferocity:
        name: 'Ferocidade'
        role: 'Molda a dureza de cada batimento — sensação de potência vs. planar.'
      balance:
        name: 'Equilíbrio'
        role: 'Distribui o impulso entre descida e subida para um voo nivelado.'
      warp:
        name: 'Warp'
        role: 'Divide a força do batimento esquerda/direita para o controlo de roll.'
      anchor:
        name: 'Âncora'
        role: 'Amortece a oscilação para que o batimento assente.'
      resonance:
        name: 'Ressonância'
        role: 'Filtra a vibração na frequência de batimento para um sinal mais limpo.'
      prescience:
        name: 'Presciência'
        role: 'Antecipa o batimento seguinte para correções atempadas.'
      espelho:
        name: 'Espelho'
        role: 'Cancela a vibração própria das asas nos sensores.'
      saudade:
        name: 'Saudade'
        role: 'Aprende com cada batimento e ajusta uma pequena correção constante.'
      aeroelastic:
        name: 'Aeroelástico'
        role: 'Ajusta a força de controlo entre planar e bater.'
    param:
      cadence_gain:
        label: 'Avanço de fase'
        role: 'Liga o comando de pitch ao avanço do batimento.'
      ferocity_p_gain:
        label: 'Ferocidade P'
        role: 'O comando de pitch endurece a descida para mais impulso.'
      ferocity_d_gain:
        label: 'Ferocidade D'
        role: 'O amortecimento de velocidade suaviza o retorno.'
      ferocity_roll_gain:
        label: 'Ferocidade Roll'
        role: 'O comando de roll distribui a força entre as duas asas.'
      ferocity_yaw_gain:
        label: 'Ferocidade Yaw'
        role: 'O comando de yaw distribui a força entre as duas asas.'
      ferocity_downstroke:
        label: 'Forma de descida'
        role: 'Nitidez da descida — 1 seno suave, 100 dwell duro.'
      ferocity_upstroke:
        label: 'Forma de subida'
        role: 'Nitidez da subida — 1 seno suave, 100 dwell duro.'
      balance_gain:
        label: 'Viés de impulso'
        role: 'Distribui o impulso entre descida e subida.'
      warp_gain:
        label: 'Diferencial warp'
        role: 'Divide a força esquerda/direita para a autoridade de roll.'
      warp_yaw_gain:
        label: 'Warp yaw'
        role: 'Divide a força esquerda/direita para a autoridade de yaw.'
      anchor_gain:
        label: 'Âncora de amortecimento'
        role: 'Amortece a oscilação para que o batimento assente.'
      resonance_gain:
        label: 'Filtro de ressonância'
        role: 'Filtra a vibração na frequência de batimento do sinal.'
      prescience_gain:
        label: 'Predição de batimento'
        role: 'Antecipa o batimento seguinte a partir da frequência.'
      espelho_gain:
        label: 'Cancelamento de ruído'
        role: 'Cancela o ruído próprio das asas na leitura.'
      saudade_gain:
        label: 'Memória de batimento'
        role: 'Aprende uma pequena correção constante de cada batimento.'
      ssff_gain:
        label: 'SSFF'
        role: 'Antecipa com o batimento; a presciência elimina o seu atraso.'
      aeroelastic_glide_coefficient:
        label: 'Escala de planar'
        role: 'Escala a resposta de controlo ao planar.'
      aeroelastic_flap_coefficient:
        label: 'Escala de batimento'
        role: 'Escala a resposta de controlo ao bater.'
    showLayer: 'Mostrar {name}'
    downstroke: '⬇ Descida'
    upstroke: '⬆ Subida'
    asymmetry: 'Assimetria {value}%'

  airframe:
    field:
      wingSpan:
        label: 'Envergadura'
        hermes: 'Envergadura da asa.'
      chord:
        label: 'Corda'
        hermes: 'Corda média da asa.'
      totalMass:
        label: 'Massa'
        hermes: 'Massa à descolagem.'
      cgX:
        label: 'CG longitudinal'
        hermes: 'Posição do CG, + para o nariz.'
      cgZ:
        label: 'CG vertical'
        hermes: 'Altura acima do plano da asa.'
      cgLat:
        label: 'CG lateral'
        hermes: 'Equilíbrio de roll, + à direita.'
    mount:
      angle:
        label: 'Ângulo de montagem'
        hermes: 'Ângulo de incidência do servo.'
      station:
        label: 'Estação'
        hermes: 'Posição à frente/atrás do eixo do CG.'
      vertical:
        label: 'Vertical'
        hermes: 'Altura acima/abaixo do plano da asa.'

  common:
    simulation: 'SIMULAÇÃO'
    device: 'DISPOSITIVO'
    unsaved: 'NÃO GUARDADO'
    saved: 'GUARDADO'
    read: 'Ler dispositivo'
    save: 'Guardar'
    revert: 'Reverter'

  pid:
    kicker: 'CONTROLO · CONTROLO DE VOO'
    title: 'Controlo de voo'
    hermes: 'O núcleo de controlo: doze ganhos PID em quatro eixos, taxas e filtros. A estabilização ONDAS vive em Dinâmica de batimento — uma só verdade.'
    simBanner: 'SIMULAÇÃO — os valores não são guardados'
    bank: 'Banco PID'
    bankSub: 'Quatro eixos, três termos cada — cada bloco de eixo é um batimento do controlador.'
    rates: 'Taxas'
    ratesSub: 'Molda a resposta do stick — taxa RC, super taxa, expo.'
    filters: 'Filtros'
    filtersSub: 'Filtragem de giroscópio e termo D (MSP 92).'
    ondas: 'ONDAS'
    ondasSub: 'A estabilização ONDAS só é mantida em Dinâmica de batimento — aqui vive a referência.'
    ondasNote: 'Dezoito ajustes em dez etapas acopladas. Para que PID e Dinâmica de batimento nunca conduzam duas vezes, a suite abre o rascunho ONDAS completo.'
    ondasCta: 'Abrir ONDAS → Dinâmica de batimento'
    rcRate: 'Taxa RC'
    superRate: 'Super taxa'
    expo: 'Expo'
    gyroDlpf: 'Giro DLPF'
    gyroNotch: 'Notch de giro'
    notchQ: 'Q de notch'
    dTermDlpf: 'DLPF termo D'

  profiles:
    kicker: 'PERFIS DE VOO'
    hermes: 'Quatro perfis, selecionados pelo modo de perfil de ornitóptero (caixa AUX). Cada um tem ângulo de planar e forma de batimento — a Dinâmica de batimento age sempre no perfil ativo.'
    auxBadge: 'AUX · A CAIXA SELECIONA'
    active: 'ATIVO'
    profile: 'Perfil {n}'
    glide: 'Ângulo de planar'
    stroke: 'Batimento {stroke} · Retorno {ret} · Mix {mix}'
    editActive: 'Editar este perfil em Dinâmica de batimento →'
    editInactive: 'Ativar e abrir Dinâmica de batimento →'
    activeNote: 'Perfil ativo — ganhos ONDAS e forma de batimento em vigor.'
    inactiveNote: 'Inativo — a caixa AUX seleciona este perfil.'

  modes:
    kicker: 'CONTROLO · MODOS DE VOO'
    title: 'Modos de voo'
    hermes: 'Vinte slots AUX contra o fluxo de canais — caixa, canal e banda 900–2100 µs. Uma linha acende quando o seu canal está no intervalo.'
    noteHeading: 'Modos de voo'
    noteSub: 'Intervalos AUX armados contra o fluxo de canais.'
    noteAcro: '{name} é implícito — o padrão quando nenhum intervalo está ativo.'
    rangeHeading: 'Lógica de intervalo'
    rangeNote: 'As colunas extra (AND / OR / XOR, caixa ligada) aparecem quando o firmware expõe MSP 238.'
    rangeWarn: 'Firmware legado — lógica e ligações nos valores padrão.'
    mainHeading: 'Intervalos de modo AUX'
    mainSub: '20 slots de ativação — caixa, canal AUX e banda 900–2100 µs.'

  receiver:
    kicker: 'CONTROLO · RECETOR'
    title: 'Recetor'
    hermes: 'Documento do recetor: fornecedor e limites de pulso, mapeamento de canais, slots de proteção e o fluxo de canais mapeado.'
    protocol: 'Protocolo RX'
    protocolSub: 'Fornecedor do recetor série e limites de pulso (MSP 44).'
    maxCheck: 'Verificação máx.'
    midRc: 'RC médio'
    minCheck: 'Verificação mín.'
    rxMinPulse: 'Pulso RX mín.'
    rxMaxPulse: 'Pulso RX máx.'
    airmodeThreshold: 'Limiar de airmode'
    channelMap: 'Mapa de canais'
    channelMapSub: 'Entradas lógicas para canais físicos (MSP 64).'
    failsafeChannels: 'Canais de proteção'
    failsafeChannelsSub: 'Comportamento de perda por canal — slots 750–2250 µs (MSP 77).'
    channel: 'Canal {n}'
    liveChannels: 'Canais em direto'
    liveChannelsSub: 'Fluxo de canais físicos — pré-visualização mapeada do documento do recetor.'

  adjustments:
    kicker: 'CONTROLO · AJUSTES'
    title: 'Ajustes'
    hermes: 'Reguladores em voo: trinta slots, seis bytes cada (MSP 52/53). Um slot arma-se quando o seu canal AUX está no intervalo.'
    heading: 'Slots de ajuste'
    sub: 'Intervalo de canal 900 – 2100 µs em passos de 25 µs; as funções refletem a tabela do firmware (0 = nenhuma).'
    note: 'Apenas os slots alterados enviam SET + EEPROM_WRITE ao guardar.'
    slot: 'Slot {n}'
    function: 'Função'
    adjustmentSlot: 'Slot de ajuste'
    channel: 'Canal'
    rangeStart: 'Início do intervalo'
    rangeEnd: 'Fim do intervalo'
    switchChannel: 'Canal de comutação'

  cli:
    title: 'Terminal CLI'
    subtitle: 'Consola de texto do controlador de voo'
    live: '● EM DIRETO'
    simulation: '◌ SIMULAÇÃO'
    open: 'Abrir CLI do dispositivo'
    exit: 'Sair do CLI'
    clear: 'Limpar'
    idle: '─ inativo ─'
    placeholderLive: 'escreve um comando — tab completa'
    placeholderSim: 'simulação — experimenta help, version, status'
    commandInput: 'Entrada de comando CLI'
    output: 'Saída CLI'

  schlagdynamik:
    kicker: 'CONTROLO · DINÂMICA DE BATIMENTO'
    title: 'Dinâmica de batimento'
    hermes: 'A estabilização do batimento: dezoito ajustes em dez etapas acopladas — do erro de controlo ao movimento de batimento em fase. Cada etapa explica o que faz pelo voo; o espelho Espelho lê a assimetria do batimento em direto.'
    profileChip: 'Perfil {n} · alvo ONDAS'
    espelho: '→ Espelho'
    signalChain: 'Cadeia de sinal'
    signalChainSub: 'Dez etapas na direção de voo — do erro de controlo ao movimento de batimento. Um clique traz a etapa à vista.'
    waveform: 'Forma de onda'
    waveformSub: 'Um ciclo de batimento completo do núcleo de onda — a âncora fixa das etapas.'
    down: '⬇ Desce {v}%'
    asymmetry: 'Assimetria {v}%'
    up: '⬆ Sobe {v}%'
    hzLive: '{hz} Hz · em direto'
    rest: 'Repouso — sem frequência de batimento'
    espelhoHeading: 'Diagnóstico de assimetria Espelho'
    espelhoSub: 'O espelho: |2.ª harmónica| / |fundamental| do movimento de batimento — a impressão digital da assimetria.'
    debugEspelho: 'DEBUG_ESPELHO'
    simDerived: 'SIM · derivado do batimento'
    phase: 'FASE'

  ornithopter:
    hermes: 'Plano corporal · Estrutura. O lado de acionamento do pássaro, uma vista por articulação.'
    craftName: 'NOME DO APARELHO'
    craftNameNote: 'O nome de sistema é gerido pelo controlador (MSP_NAME, 16 caracteres) e mantido em Sistema → Dispositivo.'
    editInSystem: 'Editar em Sistema → Dispositivo'
    kernel: 'Kernel'
    kernelNote: 'Acionamento direto ou engrenagem.'
    studio: 'STUDIO'
    mixerProfile: 'Perfil de misturador'
    mixerProfileNote: 'Atribuição GPIO segundo o firmware.'
    gpioMap: 'Mapa GPIO'
    strokeTime: 'Tempo de batimento'
    strokeTimeNote: 'servo_travel_time_ms do firmware — milissegundos por batimento de 60° (30–500).'
    tempo: '— Tempo —'
    trims: 'Trims'
    trimsNote: 'Posição de repouso de cada articulação com entrada neutra.'
    bodyHermes: 'Kernel e misturador: como o acionamento estica a asa — direto na articulação ou por engrenagem.'
    airframeHermes: 'Envergadura, massa e centro de gravidade — a estrutura que o batimento carrega.'
    wingArea: 'Área alar {area} cm²'
    aspectRatio: 'Alongamento {ratio}'
    servoMount: 'Montagem do servo'
    servoMountNote: 'Posição de cada par de asas: ângulo, estação, altura.'
    pair: 'Par {n}'
    footer: 'Plano corporal no Studio · GPIO no firmware · asas no céu.'
    mixerOption: '{name} — {n} servos'
    simulation: '{name} (Simulação)'

  app:
    kicker: 'SISTEMA · APP'
    title: 'Definições da app'
    subtitle: 'Idioma e preferências da área de trabalho — guardadas neste navegador.'
    interface: 'Interface'
    interfaceSub: 'Estas definições vivem no teu navegador. Nada aqui é escrito no controlador.'
    language: 'Idioma'
    languageSub: 'Escolhe o idioma da interface. A escolha é lembrada neste dispositivo.'
    appearance: 'Aparência'
    appearanceSub: 'Tema e disposição da área de trabalho.'
    theme: 'Tema'
    layout: 'Disposição da área de trabalho'
