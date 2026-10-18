###
# ORNIFLIGHT STUDIO — Japanese message catalog
###
export default
  nav:
    modules:
      basic:    '基本設定'
      profiles: '飛行プロファイル'
      servos:   'サーボ'
      control:  '制御'
      sensors:  'センサー'
      system:   'システム'
      safety:   '安全'
      cli:      'CLI'
    subtabs:
      basic:
        body:    'ボディプラン'
        airframe: '機体'
      profiles:
        profiles: 'プロファイル'
      servos:
        servos: 'サーボ'
      control:
        pid:           'PID'
        schlagdynamik: '羽ばたき力学'
        modes:         'モード'
        receiver:      '受信機'
        adjustments:   '調整'
      sensors:
        hardware: 'センサー'
        gyro:     'ジャイロ'
      system:
        device: 'デバイス'
        ports:  'ポート'
        power:  '電源'
        vtx:    'VTX'
        osd:    'OSD'
        voice:  '音声'
        memory: 'メモリ'
        flash:  '換羽'
        data:   'データ'
        app:    'アプリ'
      safety:
        failsafe: 'フェイルセーフ'
      cli:
        cli: 'CLI'

  chrome:
    skip: '本文へ'
    connect: '接続'
    disconnect: '切断'
    selecting: '選択中…'
    syncing: '同期中…'
    connectTooltip: 'WebSerial で OrniFlight コントローラーを接続'
    connectUnsupported: 'このブラウザでは WebSerial を利用できません'
    liveState: 'ライブ接続状態'
    flapFrequency: '現在の羽ばたき周波数'
    batteryVoltage: '飛行用バッテリー電圧'
    version: 'Studio バージョン'
    commands: 'コマンドパレットを開く · Ctrl/⌘ K'
    state: '状態インスペクター · Ctrl/⌘ Shift D'
    theme: 'ライト/ダークテーマ切替'
    layout: 'ワークスペースレイアウト変更'
    flap: '羽ばたき'
    battery: 'バッテリー'
    commandsLabel: 'コマンド'
    stateLabel: '状態'
    primaryNav: 'メインナビゲーション'
    toolbar: 'Studio ツールバー'

  commands:
    connect: 'デバイスを接続'
    disconnect: 'デバイスを切断'
    toggleTheme: 'テーマ切替'
    placeholder: '移動またはコマンド実行…'
    empty: '一致するコマンドなし'
    footer: '↑↓ 選択 · ↵ 実行 · Ctrl/⌘ K 切替'
    ariaLabel: 'Studio コマンド'

  conn:
    state:
      disconnected: '切断済み'
      scanning: '検索中…'
      handshaking: '同期中…'
      connected: '接続済み'
    breathing: '呼吸中'
    offlineProfile: 'オフラインプロファイル'
    deviceConnected: 'デバイス接続済み'
    controller: 'コントローラー'
    simulation: 'シミュレーション'
    armed: 'アーム済み'
    disarmed: 'ディスアーム済み'

  shell:
    system: 'システム'
    inspector: 'インスペクター'
    module: 'モジュール'
    connection: '接続'
    source: 'ソース'
    device: 'デバイス'
    firmware: 'ファームウェア'
    target: 'ターゲット'
    status: '状態'
    live: 'ライブ'
    voltage: '電圧'
    cpu: 'CPU'

  welcome:
    kicker: 'ORNIFLIGHT STUDIO'
    title: '鳥を設定し、飛行を理解する。'
    subtitle: 'オフラインワークスペースを開くか、OrniFlight コントローラーを接続します。3D プレビューは必要なときだけ読み込まれます。'
    connect: 'コントローラーを接続'
    choosing: 'コントローラーを選択…'
    reading: 'ファームウェアを読み込み…'
    offline: 'オフラインワークスペースを開く'
    webSerialNotice: 'このブラウザは WebSerial を提供しません。オフラインプロファイルは引き続き利用できます。'
    lastController: '前回のコントローラー'
    session: 'セッション'
    noController: '接続されたコントローラーはありません'
    profilesNote: 'プロファイルとログツールはファームウェアなしで動作します。'
    step1: '1 · 接続'
    step2: '2 · 比較'
    step3: '3 · 適用'
    intro_markdown: "## 一羽の鳥、三つの呼吸\n\n**ボディプラン**はカーネル、ミキサー、トリムを整えます。**羽ばたき力学**は飛行プロファイルごとに羽ばたきを形作ります。**サーボ**はギアボックス鳥の操縦面を名付けます。\n\n- *ダイレクトドライブ* — 翼ペアが波形上で振動\n- *ギアボックス* — ラダー、尾翼、モーターをクラシックサーボとして"
    legal_html: '<small>OrniFlight Studio — ヘルメス的飛行計器。心なくして飛行なし。</small>'

  mixer:
    kernel:
      servo: 'ダイレクトドライブ'
      gearbox: 'ギアボックス'
    surface:
      rudder: 'ラダー'
      vtailLeft: 'Vテール左'
      vtailRight: 'Vテール右'
      elevator: 'エレベーター'
      motor: 'モーター'
    trim:
      leftWing: '左翼'
      rightWing: '右翼'
      backLeftWing: '左後翼'

  servo:
    input:
      none: 'なし'
      stabRoll: '安定ロール'
      stabPitch: '安定ピッチ'
      stabYaw: '安定ヨー'
      stabThrottle: '安定スロットル'
      rcRoll: 'RC ロール'
      rcPitch: 'RC ピッチ'
      rcYaw: 'RC ヨー'
      rcThrottle: 'RC スロットル'
      aux1: 'AUX 1（チャンネル 5）'
      aux2: 'AUX 2（チャンネル 6）'
      aux3: 'AUX 3（チャンネル 7）'
      aux4: 'AUX 4（チャンネル 8）'
    channel: 'サーボ {n}'

  servos:
    kicker: '基本設定 · サーボ'
    title: 'サーボ'
    hermes_markdown: "ギアボックス鳥の**操縦面**: ミキサーが宣言する各ラダー、尾翼、モーターに名前付き入力ソースとターゲットチャンネルが与えられます。翼ペア——羽ばたきサーボ——は*羽ばたき力学*で設定します。"
    simulation: 'シミュレーション'
    device: 'デバイス'
    read: 'デバイスを読み込む'
    save: '保存'
    revert: '戻す'
    emptyHeading: '操縦面なし'
    emptySub: 'このミキサーは翼ペアのみです。'
    emptyNote: 'この {mixer} ミキサーの羽ばたきサーボは、羽ばたき力学で翼ペアとして設定します——ここではありません。'
    sectionHeading: '操縦面'
    sectionSub: '面ごとの入力ソースとターゲットチャンネル——このミキサーのサーボのみ（{count}）。'
    inputSource: '入力ソース'
    targetChannel: 'ターゲットチャンネル'

  math:
    layer:
      cadence:
        name: 'ケイデンス'
        role: 'ピッチへの応答として翼の羽ばたき速度を決めます。'
      ferocity:
        name: 'フェロシティ'
        role: '各羽ばたきの硬さを形作ります——パワーと滑空感。'
      balance:
        name: 'バランス'
        role: '水平飛行のため推力を下げと上げの間に分配します。'
      warp:
        name: 'ワープ'
        role: 'ロール制御のため羽ばたき力を左右に分割します。'
      anchor:
        name: 'アンカー'
        role: '羽ばたきが安定するよう振動を減衰します。'
      resonance:
        name: 'レゾナンス'
        role: 'よりクリーンな信号のため羽ばたき周波数の振動を除去します。'
      prescience:
        name: '先見'
        role: '修正が間に合うよう次の羽ばたきを予測します。'
      espelho:
        name: 'エスペーリョ'
        role: 'センサーから翼自身の振動を除去します。'
      saudade:
        name: 'サウダージ'
        role: '各羽ばたきから学び、小さな一定補正を加えます。'
      aeroelastic:
        name: '空力弾性'
        role: '滑空と羽ばたきの間で制御強度を調整します。'
    param:
      cadence_gain:
        label: '位相進み'
        role: 'ピッチ要求を羽ばたきの進みに関連付けます。'
      ferocity_p_gain:
        label: 'フェロシティ P'
        role: 'ピッチ要求が下げをより推力のため硬化します。'
      ferocity_d_gain:
        label: 'フェロシティ D'
        role: 'レート減衰が戻りを和らげます。'
      ferocity_roll_gain:
        label: 'フェロシティ ロール'
        role: 'ロール要求が力を両翼に分配します。'
      ferocity_yaw_gain:
        label: 'フェロシティ ヨー'
        role: 'ヨー要求が力を両翼に分配します。'
      ferocity_downstroke:
        label: '下げ形状'
        role: '下げの鋭さ——1 滑らかな正弦、100 硬いドウェル。'
      ferocity_upstroke:
        label: '上げ形状'
        role: '上げの鋭さ——1 滑らかな正弦、100 硬いドウェル。'
      balance_gain:
        label: '推力バイアス'
        role: '推力を下げと上げの間に分配します。'
      warp_gain:
        label: 'ワープ差動'
        role: 'ロール権限のため力を左右に分割します。'
      warp_yaw_gain:
        label: 'ワープ ヨー'
        role: 'ヨー権限のため力を左右に分割します。'
      anchor_gain:
        label: '減衰アンカー'
        role: '羽ばたきが安定するよう振動を減衰します。'
      resonance_gain:
        label: 'レゾナンスフィルター'
        role: '信号から羽ばたき周波数の振動を除去します。'
      prescience_gain:
        label: '羽ばたき予測'
        role: '周波数から次の羽ばたきを予測します。'
      espelho_gain:
        label: 'ノイズ除去'
        role: '読み取りから翼の自己ノイズを除去します。'
      saudade_gain:
        label: '羽ばたき記憶'
        role: '各羽ばたきから小さな一定補正を学びます。'
      ssff_gain:
        label: 'SSFF'
        role: '羽ばたきに合わせて前送り; 先見が遅延を除去します。'
      aeroelastic_glide_coefficient:
        label: '滑空スケール'
        role: '滑空時の制御応答をスケールします。'
      aeroelastic_flap_coefficient:
        label: '羽ばたきスケール'
        role: '羽ばたき時の制御応答をスケールします。'
    showLayer: '{name} を表示'
    downstroke: '⬇ 下げ'
    upstroke: '⬆ 上げ'
    asymmetry: '非対称 {value}%'

  airframe:
    field:
      wingSpan:
        label: '翼幅'
        hermes: '機体の翼幅。'
      chord:
        label: '翼弦'
        hermes: '平均翼弦。'
      totalMass:
        label: '質量'
        hermes: '離陸質量。'
      cgX:
        label: '重心 前後'
        hermes: '重心位置、+ 機首方向。'
      cgZ:
        label: '重心 上下'
        hermes: '翼面より上の高さ。'
      cgLat:
        label: '重心 左右'
        hermes: 'ロールバランス、+ 右。'
    mount:
      angle:
        label: '取り付け角'
        hermes: 'サーボの迎角。'
      station:
        label: '位置'
        hermes: '重心軸の前後位置。'
      vertical:
        label: '上下'
        hermes: '翼面の上下の高さ。'

  common:
    simulation: 'シミュレーション'
    device: 'デバイス'
    unsaved: '未保存'
    saved: '保存済み'
    read: 'デバイスを読み込む'
    save: '保存'
    revert: '戻す'

  pid:
    kicker: '制御 · 飛行制御'
    title: '飛行制御'
    hermes: '制御の中核: 4軸に12の PID ゲイン、レート、フィルター。ONDAS 安定化は羽ばたき力学に宿ります——唯一の真実。'
    simBanner: 'シミュレーション——値は保存されません'
    bank: 'PID バンク'
    bankSub: '4軸、各3項——各軸ブロックはコントローラーの一羽ばたき。'
    rates: 'レート'
    ratesSub: 'スティック応答を形作る——RC レート、スーパーレート、expo。'
    filters: 'フィルター'
    filtersSub: 'ジャイロとD項のフィルタリング（MSP 92）。'
    ondas: 'ONDAS'
    ondasSub: 'ONDAS 安定化は羽ばたき力学でのみ維持されます——ここには参照のみ。'
    ondasNote: '10の結合段階に18の調整。PID と羽ばたき力学が二重に駆動しないよう、スイートは完全な ONDAS 草案を開きます。'
    ondasCta: 'ONDAS を開く → 羽ばたき力学'
    rcRate: 'RC レート'
    superRate: 'スーパーレート'
    expo: 'Expo'
    gyroDlpf: 'ジャイロ DLPF'
    gyroNotch: 'ジャイロノッチ'
    notchQ: 'ノッチ Q'
    dTermDlpf: 'D項 DLPF'

  profiles:
    kicker: '飛行プロファイル'
    hermes: 'オーニソプタープロファイルモード（AUX ボックス）で選択する4つのプロファイル。それぞれ滑空角と羽ばたき形状を持ちます——羽ばたき力学は常にアクティブなプロファイルに作用します。'
    auxBadge: 'AUX · ボックス選択'
    active: 'アクティブ'
    profile: 'プロファイル {n}'
    glide: '滑空角'
    stroke: '羽ばたき {stroke} · 戻り {ret} · ミックス {mix}'
    editActive: 'このプロファイルを羽ばたき力学で編集 →'
    editInactive: 'アクティブ化して羽ばたき力学を開く →'
    activeNote: 'アクティブなプロファイル——ONDAS ゲインと羽ばたき形状が有効。'
    inactiveNote: '非アクティブ——AUX ボックスがこのプロファイルを選択します。'

  modes:
    kicker: '制御 · 飛行モード'
    title: '飛行モード'
    hermes: 'ライブチャンネル流に対する20の AUX スロット——ボックス、チャンネル、900–2100 µs 帯域。チャンネルが範囲内で行が点灯します。'
    noteHeading: '飛行モード'
    noteSub: 'ライブチャンネル流に対して武装した AUX 範囲。'
    noteAcro: '{name} は暗黙——範囲がアクティブでないときのデフォルト。'
    rangeHeading: '範囲ロジック'
    rangeNote: 'ファームウェアが MSP 238 を公開すると追加列（AND / OR / XOR、リンクボックス）が表示されます。'
    rangeWarn: '旧ファームウェア——ロジックとリンクはデフォルト値。'
    mainHeading: 'AUX モード範囲'
    mainSub: '20のアクティベーションスロット——ボックス、AUX チャンネル、900–2100 µs 帯域。'

  receiver:
    kicker: '制御 · 受信機'
    title: '受信機'
    hermes: '受信機ドキュメント: プロバイダーとパルス境界、チャンネルマッピング、フェイルセーフスロット、マップ済みライブチャンネル流。'
    protocol: 'RX プロトコル'
    protocolSub: 'シリアル受信機プロバイダーとパルス境界（MSP 44）。'
    maxCheck: '最大チェック'
    midRc: '中央 RC'
    minCheck: '最小チェック'
    rxMinPulse: 'RX 最小パルス'
    rxMaxPulse: 'RX 最大パルス'
    airmodeThreshold: 'エアモード閾値'
    channelMap: 'チャンネルマップ'
    channelMapSub: '論理入力から物理チャンネルへ（MSP 64）。'
    failsafeChannels: 'フェイルセーフチャンネル'
    failsafeChannelsSub: 'チャンネルごとの喪失動作——750–2250 µs スロット（MSP 77）。'
    channel: 'チャンネル {n}'
    liveChannels: 'ライブチャンネル'
    liveChannelsSub: '物理チャンネル流——受信機ドキュメントのマップ済みプレビュー。'

  adjustments:
    kicker: '制御 · 調整'
    title: '調整'
    hermes: '飛行中レギュレーター: 30スロット、各6バイト（MSP 52/53）。AUX チャンネルが範囲内でスロットが武装します。'
    heading: '調整スロット'
    sub: 'チャンネル範囲 900 – 2100 µs、25 µs 刻み; 機能はファームウェアテーブルを反映（0 = なし）。'
    note: '保存時に変更スロットのみ SET + EEPROM_WRITE を送信します。'
    slot: 'スロット {n}'
    function: '機能'
    adjustmentSlot: '調整スロット'
    channel: 'チャンネル'
    rangeStart: '範囲開始'
    rangeEnd: '範囲終了'
    switchChannel: '切替チャンネル'

  cli:
    title: 'CLI ターミナル'
    subtitle: 'フライトコントローラーのテキストコンソール'
    live: '● ライブ'
    simulation: '◌ シミュレーション'
    open: 'デバイス CLI を開く'
    exit: 'CLI を終了'
    clear: 'クリア'
    idle: '─ アイドル ─'
    placeholderLive: 'コマンドを入力——tab で補完'
    placeholderSim: 'シミュレーション——help、version、status を試す'
    commandInput: 'CLI コマンド入力'
    output: 'CLI 出力'

  schlagdynamik:
    kicker: '制御 · 羽ばたき力学'
    title: '羽ばたき力学'
    hermes: '羽ばたきの安定化: 10の結合段階に18の調整——制御誤差から位相ロックされた羽ばたき動作まで。各段階は飛行に対して何をするかを説明し、Espelho ミラーが羽ばたきの非対称をライブで読み取ります。'
    profileChip: 'プロファイル {n} · ONDAS ターゲット'
    espelho: '→ Espelho'
    signalChain: '信号チェーン'
    signalChainSub: '飛行方向に10段階——制御誤差から羽ばたき動作まで。クリックで段階を表示します。'
    waveform: '波形'
    waveformSub: '波核からの完全な羽ばたき1周期——段階の固定アンカー。'
    down: '⬇ 下げ {v}%'
    asymmetry: '非対称 {v}%'
    up: '⬆ 上げ {v}%'
    hzLive: '{hz} Hz · ライブ'
    rest: '静止——羽ばたき周波数なし'
    espelhoHeading: 'Espelho スキュー診断'
    espelhoSub: 'ミラー: 羽ばたき動作の |第2高調波| / |基本波|——非対称の指紋。'
    debugEspelho: 'DEBUG_ESPELHO'
    simDerived: 'SIM · 羽ばたき由来'
    phase: '位相'

  ornithopter:
    hermes: 'ボディプラン · 機体。鳥の駆動側、関節ごとのビュー。'
    craftName: '機体名'
    craftNameNote: 'システム名はコントローラーが保持し（MSP_NAME、16文字）、システム → デバイスで管理します。'
    editInSystem: 'システム → デバイスで編集'
    kernel: 'カーネル'
    kernelNote: 'ダイレクトドライブまたはギアボックス。'
    studio: 'STUDIO'
    mixerProfile: 'ミキサープロファイル'
    mixerProfileNote: 'ファームウェアによる GPIO 割り当て。'
    gpioMap: 'GPIO マップ'
    strokeTime: '羽ばたき時間'
    strokeTimeNote: 'ファームウェアの servo_travel_time_ms——60° 羽ばたきあたりのミリ秒（30–500）。'
    tempo: '— テンポ —'
    trims: 'トリム'
    trimsNote: '中立入力時の各関節の静止位置。'
    bodyHermes: 'カーネルとミキサー: 駆動が翼をどう張るか——関節に直接、またはギアボックス経由。'
    airframeHermes: '翼幅、質量、重心——羽ばたきが支える機体。'
    wingArea: '翼面積 {area} cm²'
    aspectRatio: 'アスペクト比 {ratio}'
    servoMount: 'サーボ取り付け'
    servoMountNote: '各翼ペアの位置: 角度、位置、高さ。'
    pair: 'ペア {n}'
    footer: 'ボディプランは Studio · GPIO はファームウェア · 翼は空。'
    mixerOption: '{name} — {n} サーボ'
    simulation: '{name}（シミュレーション）'

  app:
    kicker: 'システム · アプリ'
    title: 'アプリ設定'
    subtitle: '言語とワークスペース設定——このブラウザに保存されます。'
    interface: 'インターフェース'
    interfaceSub: 'これらの設定はブラウザに保存されます。コントローラーには何も書き込まれません。'
    language: '言語'
    languageSub: 'インターフェース言語を選択。選択はこのデバイスに記憶されます。'
    appearance: '外観'
    appearanceSub: 'テーマとワークスペースレイアウト。'
    theme: 'テーマ'
    layout: 'ワークスペースレイアウト'
