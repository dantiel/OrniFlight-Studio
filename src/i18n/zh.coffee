###
# ORNIFLIGHT STUDIO — Chinese (Simplified) message catalog
###
export default
  nav:
    modules:
      basic:    '基本设置'
      profiles: '飞行配置'
      servos:   '舵机'
      control:  '控制'
      sensors:  '传感器'
      system:   '系统'
      safety:   '安全'
      cli:      'CLI'
    subtabs:
      basic:
        body:    '机体布局'
        airframe: '机身'
      profiles:
        profiles: '配置'
      servos:
        servos: '舵机'
      control:
        pid:           'PID'
        schlagdynamik: '扑翼动力学'
        modes:         '模式'
        receiver:      '接收机'
        adjustments:   '调节'
      sensors:
        hardware: '传感器'
        gyro:     '陀螺仪'
      system:
        device: '设备'
        ports:  '端口'
        power:  '电源'
        vtx:    'VTX'
        osd:    'OSD'
        voice:  '语音'
        memory: '存储'
        flash:  '换羽'
        data:   '数据'
        app:    '应用'
      safety:
        failsafe: '失控保护'
      cli:
        cli: 'CLI'

  chrome:
    skip: '跳到内容'
    connect: '连接'
    disconnect: '断开'
    selecting: '选择中…'
    syncing: '同步中…'
    connectTooltip: '通过 WebSerial 连接 OrniFlight 控制器'
    connectUnsupported: '此浏览器不支持 WebSerial'
    liveState: '实时连接状态'
    flapFrequency: '当前扑翼频率'
    batteryVoltage: '飞行电池电压'
    version: 'Studio 版本'
    commands: '打开命令面板 · Ctrl/⌘ K'
    state: '切换状态检查器 · Ctrl/⌘ Shift D'
    theme: '切换明暗主题'
    layout: '更改工作区布局'
    flap: '扑翼'
    battery: '电池'
    commandsLabel: '命令'
    stateLabel: '状态'
    primaryNav: '主导航'
    toolbar: 'Studio 工具栏'

  commands:
    connect: '连接设备'
    disconnect: '断开设备'
    toggleTheme: '切换主题'
    placeholder: '导航或执行命令…'
    empty: '无匹配命令'
    footer: '↑↓ 选择 · ↵ 执行 · Ctrl/⌘ K 切换'
    ariaLabel: 'Studio 命令'

  conn:
    state:
      disconnected: '已断开'
      scanning: '搜索中…'
      handshaking: '同步中…'
      connected: '已连接'
    breathing: '呼吸中'
    offlineProfile: '离线配置'
    deviceConnected: '设备已连接'
    controller: '控制器'
    simulation: '模拟'
    armed: '已解锁'
    disarmed: '已上锁'

  shell:
    system: '系统'
    inspector: '检查器'
    module: '模块'
    connection: '连接'
    source: '来源'
    device: '设备'
    firmware: '固件'
    target: '目标'
    status: '状态'
    live: '实时'
    voltage: '电压'
    cpu: 'CPU'

  welcome:
    kicker: 'ORNIFLIGHT STUDIO'
    title: '配置飞鸟。理解飞行。'
    subtitle: '打开离线工作区或连接 OrniFlight 控制器。3D 飞行预览仅在需要时加载。'
    connect: '连接控制器'
    choosing: '选择控制器…'
    reading: '读取固件…'
    offline: '打开离线工作区'
    webSerialNotice: '此浏览器不提供 WebSerial。离线配置仍可用。'
    lastController: '上次的控制器'
    session: '会话'
    noController: '未连接控制器'
    profilesNote: '配置与日志工具无需固件即可工作。'
    step1: '1 · 连接'
    step2: '2 · 对比'
    step3: '3 · 应用'
    intro_markdown: "## 一只鸟，三次呼吸\n\n**机体布局** 整理内核、混控与微调。**扑翼动力学** 为每个飞行配置塑造扑翼。**舵机** 命名齿轮鸟的操纵面。\n\n- *直接驱动* — 翼对在波形上振荡\n- *齿轮箱* — 方向舵、尾翼与电机作为经典舵机"
    legal_html: '<small>OrniFlight Studio — 赫尔墨斯式飞行仪器。无心灵则无飞行。</small>'

  mixer:
    kernel:
      servo: '直接驱动'
      gearbox: '齿轮箱'
    surface:
      rudder: '方向舵'
      vtailLeft: 'V 尾左'
      vtailRight: 'V 尾右'
      elevator: '升降舵'
      motor: '电机'
    trim:
      leftWing: '左翼'
      rightWing: '右翼'
      backLeftWing: '左后翼'

  servo:
    input:
      none: '无'
      stabRoll: '稳定横滚'
      stabPitch: '稳定俯仰'
      stabYaw: '稳定偏航'
      stabThrottle: '稳定油门'
      rcRoll: 'RC 横滚'
      rcPitch: 'RC 俯仰'
      rcYaw: 'RC 偏航'
      rcThrottle: 'RC 油门'
      aux1: 'AUX 1（通道 5）'
      aux2: 'AUX 2（通道 6）'
      aux3: 'AUX 3（通道 7）'
      aux4: 'AUX 4（通道 8）'
    channel: '舵机 {n}'

  servos:
    kicker: '基本设置 · 舵机'
    title: '舵机'
    hermes_markdown: "齿轮鸟的**操纵面**：混控声明的每个方向舵、尾翼或电机都获得命名输入源与目标通道。翼对——扑翼舵机——在*扑翼动力学*中配置。"
    simulation: '模拟'
    device: '设备'
    read: '读取设备'
    save: '保存'
    revert: '还原'
    emptyHeading: '无操纵面'
    emptySub: '此混控仅包含翼对。'
    emptyNote: '此 {mixer} 混控的扑翼舵机作为翼对在扑翼动力学中配置——不在此处。'
    sectionHeading: '操纵面'
    sectionSub: '每个面的输入源与目标通道——仅此混控的舵机（{count}）。'
    inputSource: '输入源'
    targetChannel: '目标通道'

  math:
    layer:
      cadence:
        name: '节奏'
        role: '决定翅膀响应俯仰的拍动速度。'
      ferocity:
        name: '猛烈度'
        role: '塑造每次拍动的力度——动力与滑翔感。'
      balance:
        name: '平衡'
        role: '在下扑与上扑之间分配推力以保持水平飞行。'
      warp:
        name: 'Warp'
        role: '左右分割拍动力以控制横滚。'
      anchor:
        name: '锚定'
        role: '抑制振荡使拍动稳定。'
      resonance:
        name: '共振'
        role: '滤除拍频振动以获得更干净的信号。'
      prescience:
        name: '预判'
        role: '预判下一次拍动使修正及时到位。'
      espelho:
        name: 'Espelho'
        role: '从传感器中消除机翼自身振动。'
      saudade:
        name: 'Saudade'
        role: '从每次拍动学习并施加小幅恒定修正。'
      aeroelastic:
        name: '气动弹性'
        role: '在滑翔与扑翼之间调整控制强度。'
    param:
      cadence_gain:
        label: '相位超前'
        role: '将俯仰需求与拍动超前关联。'
      ferocity_p_gain:
        label: '猛烈度 P'
        role: '俯仰需求硬化下扑以获得更大推力。'
      ferocity_d_gain:
        label: '猛烈度 D'
        role: '速率阻尼软化回程。'
      ferocity_roll_gain:
        label: '猛烈度横滚'
        role: '横滚需求在两翼之间分配力量。'
      ferocity_yaw_gain:
        label: '猛烈度偏航'
        role: '偏航需求在两翼之间分配力量。'
      ferocity_downstroke:
        label: '下扑形状'
        role: '下扑锐度——1 平滑正弦，100 硬驻留。'
      ferocity_upstroke:
        label: '上扑形状'
        role: '上扑锐度——1 平滑正弦，100 硬驻留。'
      balance_gain:
        label: '推力偏置'
        role: '在下扑与上扑之间分配推力。'
      warp_gain:
        label: 'Warp 差动'
        role: '左右分割力量以获得横滚权限。'
      warp_yaw_gain:
        label: 'Warp 偏航'
        role: '左右分割力量以获得偏航权限。'
      anchor_gain:
        label: '阻尼锚定'
        role: '抑制振荡使拍动稳定。'
      resonance_gain:
        label: '共振滤波'
        role: '滤除信号中的拍频振动。'
      prescience_gain:
        label: '拍动预测'
        role: '根据频率预判下一次拍动。'
      espelho_gain:
        label: '降噪'
        role: '从读数中消除机翼自身噪声。'
      saudade_gain:
        label: '拍动记忆'
        role: '从每次拍动学习小幅恒定修正。'
      ssff_gain:
        label: 'SSFF'
        role: '随拍动前馈；预判消除其延迟。'
      aeroelastic_glide_coefficient:
        label: '滑翔缩放'
        role: '滑翔时缩放控制响应。'
      aeroelastic_flap_coefficient:
        label: '扑翼缩放'
        role: '扑翼时缩放控制响应。'
    showLayer: '显示 {name}'
    downstroke: '⬇ 下扑'
    upstroke: '⬆ 上扑'
    asymmetry: '不对称 {value}%'

  airframe:
    field:
      wingSpan:
        label: '翼展'
        hermes: '机翼翼展。'
      chord:
        label: '弦长'
        hermes: '平均翼弦。'
      totalMass:
        label: '质量'
        hermes: '起飞质量。'
      cgX:
        label: '重心纵向'
        hermes: '重心位置，+ 朝机头。'
      cgZ:
        label: '重心垂直'
        hermes: '翼平面以上高度。'
      cgLat:
        label: '重心横向'
        hermes: '横滚平衡，+ 向右。'
    mount:
      angle:
        label: '安装角'
        hermes: '舵机安装角。'
      station:
        label: '站位'
        hermes: '重心轴前后位置。'
      vertical:
        label: '垂直'
        hermes: '翼平面上下高度。'

  common:
    simulation: '模拟'
    device: '设备'
    unsaved: '未保存'
    saved: '已保存'
    read: '读取设备'
    save: '保存'
    revert: '还原'

  pid:
    kicker: '控制 · 飞行控制'
    title: '飞行控制'
    hermes: '控制核心：四个轴上的十二个 PID 增益、速率与滤波。ONDAS 稳定生活在扑翼动力学中——单一真相。'
    simBanner: '模拟——数值不会保存'
    bank: 'PID 组'
    bankSub: '四轴，各三个项——每个轴块是控制器的一次扑翼。'
    rates: '速率'
    ratesSub: '塑造摇杆响应——RC 速率、超级速率、expo。'
    filters: '滤波'
    filtersSub: '陀螺与 D 项滤波（MSP 92）。'
    ondas: 'ONDAS'
    ondasSub: 'ONDAS 稳定仅在扑翼动力学中维护——这里只有引用。'
    ondasNote: '十八项调节，十个耦合阶段。为使 PID 与扑翼动力学不会双重驱动，套件打开完整的 ONDAS 草稿。'
    ondasCta: '打开 ONDAS → 扑翼动力学'
    rcRate: 'RC 速率'
    superRate: '超级速率'
    expo: 'Expo'
    gyroDlpf: '陀螺 DLPF'
    gyroNotch: '陀螺陷波'
    notchQ: '陷波 Q'
    dTermDlpf: 'D 项 DLPF'

  profiles:
    kicker: '飞行配置'
    hermes: '四个配置，由扑翼配置模式（AUX 盒）选择。每个都携带滑翔角与拍动形状——扑翼动力学始终作用于活动配置。'
    auxBadge: 'AUX · 盒选择'
    active: '活动'
    profile: '配置 {n}'
    glide: '滑翔角'
    stroke: '拍动 {stroke} · 回程 {ret} · 混合 {mix}'
    editActive: '在扑翼动力学中编辑此配置 →'
    editInactive: '激活并打开扑翼动力学 →'
    activeNote: '活动配置——ONDAS 增益与拍动形状生效。'
    inactiveNote: '非活动——AUX 盒选择此配置。'

  modes:
    kicker: '控制 · 飞行模式'
    title: '飞行模式'
    hermes: '二十个 AUX 槽对应实时通道流——盒、通道与 900–2100 µs 频带。通道在范围内时该行点亮。'
    noteHeading: '飞行模式'
    noteSub: '针对实时通道流武装的 AUX 范围。'
    noteAcro: '{name} 为隐式——无范围激活时的默认。'
    rangeHeading: '范围逻辑'
    rangeNote: '固件暴露 MSP 238 时显示额外列（AND / OR / XOR、关联盒）。'
    rangeWarn: '旧固件——逻辑与关联处于默认值。'
    mainHeading: 'AUX 模式范围'
    mainSub: '20 个激活槽——盒、AUX 通道与 900–2100 µs 频带。'

  receiver:
    kicker: '控制 · 接收机'
    title: '接收机'
    hermes: '接收机文档：供应商与脉冲边界、通道映射、失控保护槽与映射后的实时通道流。'
    protocol: 'RX 协议'
    protocolSub: '串行接收机供应商与脉冲边界（MSP 44）。'
    maxCheck: '最大检查'
    midRc: '中间 RC'
    minCheck: '最小检查'
    rxMinPulse: 'RX 最小脉冲'
    rxMaxPulse: 'RX 最大脉冲'
    airmodeThreshold: 'Airmode 阈值'
    channelMap: '通道映射'
    channelMapSub: '逻辑输入到物理通道（MSP 64）。'
    failsafeChannels: '失控保护通道'
    failsafeChannelsSub: '每通道丢失行为——750–2250 µs 槽（MSP 77）。'
    channel: '通道 {n}'
    liveChannels: '实时通道'
    liveChannelsSub: '物理通道流——接收机文档的映射预览。'

  adjustments:
    kicker: '控制 · 调节'
    title: '调节'
    hermes: '飞行中调节器：三十个槽，各六字节（MSP 52/53）。AUX 通道在范围内时槽武装。'
    heading: '调节槽'
    sub: '通道范围 900 – 2100 µs，步进 25 µs；功能反映固件表（0 = 无）。'
    note: '保存时仅变更槽发送 SET + EEPROM_WRITE。'
    slot: '槽 {n}'
    function: '功能'
    adjustmentSlot: '调节槽'
    channel: '通道'
    rangeStart: '范围起点'
    rangeEnd: '范围终点'
    switchChannel: '切换通道'

  cli:
    title: 'CLI 终端'
    subtitle: '飞控的文本控制台'
    live: '● 实时'
    simulation: '◌ 模拟'
    open: '打开设备 CLI'
    exit: '退出 CLI'
    clear: '清除'
    idle: '─ 空闲 ─'
    placeholderLive: '输入命令——tab 补全'
    placeholderSim: '模拟——试试 help、version、status'
    commandInput: 'CLI 命令输入'
    output: 'CLI 输出'

  schlagdynamik:
    kicker: '控制 · 扑翼动力学'
    title: '扑翼动力学'
    hermes: '扑翼稳定：十八项调节，十个耦合阶段——从控制误差到相位锁定的拍动。每个阶段说明它对飞行的作用；Espelho 镜实时读取拍动不对称。'
    profileChip: '配置 {n} · ONDAS 目标'
    espelho: '→ Espelho'
    signalChain: '信号链'
    signalChainSub: '飞行方向上的十个阶段——从控制误差到拍动。单击将阶段带入视野。'
    waveform: '波形'
    waveformSub: '来自波核的完整拍动周期——各阶段的固定锚。'
    down: '⬇ 下 {v}%'
    asymmetry: '不对称 {v}%'
    up: '⬆ 上 {v}%'
    hzLive: '{hz} Hz · 实时'
    rest: '静止——无拍动频率'
    espelhoHeading: 'Espelho 偏斜诊断'
    espelhoSub: '镜：拍动的 |2 次谐波| / |基波|——不对称的指纹。'
    debugEspelho: 'DEBUG_ESPELHO'
    simDerived: 'SIM · 拍动导出'
    phase: '相位'

  ornithopter:
    hermes: '机体布局 · 机身。鸟的驱动侧，每个关节一个视图。'
    craftName: '机体名称'
    craftNameNote: '系统名由控制器承载（MSP_NAME，16 字符），在系统 → 设备中维护。'
    editInSystem: '在系统 → 设备中编辑'
    kernel: '内核'
    kernelNote: '直接驱动或齿轮箱。'
    studio: 'STUDIO'
    mixerProfile: '混控配置'
    mixerProfileNote: '按固件的 GPIO 分配。'
    gpioMap: 'GPIO 图'
    strokeTime: '拍动时间'
    strokeTimeNote: '固件 servo_travel_time_ms——每 60° 拍动的毫秒数（30–500）。'
    tempo: '— 节奏 —'
    trims: '微调'
    trimsNote: '中性输入时各关节的静止位置。'
    bodyHermes: '内核与混控：驱动如何张紧机翼——直接进入关节或通过齿轮箱。'
    airframeHermes: '翼展、质量与重心——拍动所承载的机身。'
    wingArea: '机翼面积 {area} cm²'
    aspectRatio: '展弦比 {ratio}'
    servoMount: '舵机安装'
    servoMountNote: '每个翼对的位置：角度、站位、高度。'
    pair: '翼对 {n}'
    footer: '机体布局在 Studio · GPIO 在固件 · 翅膀在天空。'
    mixerOption: '{name} — {n} 个舵机'
    simulation: '{name}（模拟）'

  app:
    kicker: '系统 · 应用'
    title: '应用设置'
    subtitle: '语言与工作区偏好——保存在此浏览器中。'
    interface: '界面'
    interfaceSub: '这些设置存在于你的浏览器中。此处任何内容都不会写入控制器。'
    language: '语言'
    languageSub: '选择界面语言。你的选择会在本设备上记住。'
    appearance: '外观'
    appearanceSub: '主题与工作区布局。'
    theme: '主题'
    layout: '工作区布局'
