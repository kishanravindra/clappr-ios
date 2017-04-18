import Foundation

open class Container: UIBaseObject {
    internal(set) open var plugins: [UIContainerPlugin] = []
    internal(set) open var options: Options

    fileprivate var loader: Loader

    open var mediaControlEnabled = false {
        didSet {
            let eventToTrigger: Event = mediaControlEnabled ? .enableMediaControl : .disableMediaControl
            trigger(eventToTrigger)
        }
    }

    internal(set) open var playback: Playback?

    public init(loader: Loader = Loader(), options: Options = [:]) {
        Logger.logDebug("loading with \(options)", scope: "\(type(of: self))")
        self.options = options
        self.loader = loader
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor.clear
        loadPlugins()

        if let source = options[kSourceUrl] as? String {
            load(source, mimeType: options[kMimeType] as? String)
        }
    }

    public required init?(coder _: NSCoder) {
        fatalError("Use init(playback: Playback) instead")
    }

    open func load(_ source: String, mimeType: String? = nil) {
        trigger(InternalEvent.willLoadSource.rawValue)

        var playbackOptions = options
        playbackOptions[kSourceUrl] = source
        playbackOptions[kMimeType] = mimeType

        let playbackFactory = PlaybackFactory(loader: loader, options: playbackOptions)

        setPlayback(playbackFactory.createPlayback())

        renderPlayback()

        if playback is NoOpPlayback {
            trigger(InternalEvent.didNotLoadSource.rawValue)
        } else {
            trigger(InternalEvent.didLoadSource.rawValue)
        }
    }

    fileprivate func setPlayback(_ playback: Playback) {
        if self.playback != playback {
            trigger(InternalEvent.willChangePlayback.rawValue)

            self.playback?.removeFromSuperview()
            self.playback = playback
            playback.once(Event.playing.rawValue) { [weak self] _ in self?.options[kStartAt] = 0.0 }

            trigger(InternalEvent.didChangePlayback.rawValue)
        }
    }

    open override func render() {
        plugins.forEach(renderPlugin)
        renderPlayback()
    }

    fileprivate func renderPlayback() {
        guard let playback = playback else {
            return
        }

        addSubviewMatchingConstraints(playback)
        playback.render()
        sendSubview(toBack: playback)
    }

    fileprivate func renderPlugin(_ plugin: UIContainerPlugin) {
        addSubview(plugin)
        plugin.render()
    }

    open func destroy() {
        stopListening()
        playback?.destroy()

        removeFromSuperview()
    }

    fileprivate func loadPlugins() {
        for type in loader.containerPlugins {
            if let plugin = type.init(context: self) as? UIContainerPlugin {
                addPlugin(plugin)
            }
        }
    }

    open func addPlugin(_ plugin: UIContainerPlugin) {
        plugins.append(plugin)
    }

    open func hasPlugin(_ pluginClass: AnyClass) -> Bool {
        return plugins.filter({ $0.isKind(of: pluginClass) }).count > 0
    }
}