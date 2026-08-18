import AppKit

struct ASCIIMotionProject: Codable {
    var fps: Double
    var frames: [String]
}

final class MainWindowController:
    NSWindowController,
    NSTableViewDataSource,
    NSTableViewDelegate,
    NSTextViewDelegate
{
    private var frames: [String] = [
"""
   O
  /|\\
  / \\
"""
    ]

    private var currentFrame = 0
    private var playbackFrame = 0
    private var playbackTimer: Timer?
    private var fps: Double = 4.0

    private let tableView = NSTableView()
    private let textView = NSTextView()

    private let frameCounter = NSTextField(
        labelWithString: "Frame 1 / 1"
    )

    private let fpsLabel = NSTextField(
        labelWithString: "FPS: 4"
    )

    private let fpsSlider = NSSlider(
        value: 4,
        minValue: 1,
        maxValue: 20,
        target: nil,
        action: nil
    )

    private let playButton = NSButton(
        title: "▶ Play",
        target: nil,
        action: nil
    )

    private let stopButton = NSButton(
        title: "■ Stop",
        target: nil,
        action: nil
    )

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: 950,
                height: 650
            ),
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
                .resizable
            ],
            backing: .buffered,
            defer: false
        )

        window.title = "ASCIIMotion v0.1"
        window.center()
        window.minSize = NSSize(
            width: 720,
            height: 500
        )

        self.init(window: window)

        buildInterface()
        refreshEverything()
        selectCurrentFrame()
    }

    private func buildInterface() {
        guard let contentView = window?.contentView else {
            return
        }

        let root = NSStackView()
        root.orientation = .vertical
        root.spacing = 14
        root.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 16
            ),
            root.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -16
            ),
            root.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 16
            ),
            root.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -16
            )
        ])

        let titleLabel = NSTextField(
            labelWithString: "ASCIIMotion"
        )

        titleLabel.font = NSFont.systemFont(
            ofSize: 26,
            weight: .bold
        )

        root.addArrangedSubview(titleLabel)

        let subtitle = NSTextField(
            labelWithString:
                "Create frame-by-frame ASCII animations."
        )

        subtitle.textColor = .secondaryLabelColor

        root.addArrangedSubview(subtitle)

        let mainArea = NSStackView()
        mainArea.orientation = .horizontal
        mainArea.spacing = 16

        let framePanel = makeFramePanel()
        let editorPanel = makeEditorPanel()

        mainArea.addArrangedSubview(framePanel)
        mainArea.addArrangedSubview(editorPanel)

        root.addArrangedSubview(mainArea)

        let playbackControls = makePlaybackControls()
        root.addArrangedSubview(playbackControls)

        let fileControls = makeFileControls()
        root.addArrangedSubview(fileControls)
    }

    private func makeFramePanel() -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.spacing = 8

        let label = NSTextField(
            labelWithString: "Frames"
        )

        label.font = NSFont.systemFont(
            ofSize: 16,
            weight: .semibold
        )

        container.addArrangedSubview(label)

        let column = NSTableColumn(
            identifier: NSUserInterfaceItemIdentifier(
                "FrameColumn"
            )
        )

        column.width = 180

        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 30
        tableView.allowsEmptySelection = false

        let scroll = NSScrollView()
        scroll.documentView = tableView
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder

        container.addArrangedSubview(scroll)

        scroll.widthAnchor.constraint(
            equalToConstant: 190
        ).isActive = true

        scroll.heightAnchor.constraint(
            greaterThanOrEqualToConstant: 350
        ).isActive = true

        let addButton = makeButton(
            "+ Add Frame",
            action: #selector(addFrame)
        )

        let duplicateButton = makeButton(
            "Duplicate",
            action: #selector(duplicateFrame)
        )

        let deleteButton = makeButton(
            "Delete",
            action: #selector(deleteFrame)
        )

        container.addArrangedSubview(addButton)
        container.addArrangedSubview(duplicateButton)
        container.addArrangedSubview(deleteButton)

        return container
    }

    private func makeEditorPanel() -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.spacing = 8

        let header = NSStackView()
        header.orientation = .horizontal

        let label = NSTextField(
            labelWithString: "ASCII Canvas"
        )

        label.font = NSFont.systemFont(
            ofSize: 16,
            weight: .semibold
        )

        header.addArrangedSubview(label)

        header.addArrangedSubview(NSView())

        header.addArrangedSubview(frameCounter)

        container.addArrangedSubview(header)

        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.allowsUndo = true
        textView.delegate = self

        textView.font = NSFont.monospacedSystemFont(
            ofSize: 22,
            weight: .regular
        )

        textView.textContainerInset = NSSize(
            width: 18,
            height: 18
        )

        let scroll = NSScrollView()
        scroll.documentView = textView
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = true
        scroll.autohidesScrollers = true
        scroll.borderType = .bezelBorder

        container.addArrangedSubview(scroll)

        scroll.heightAnchor.constraint(
            greaterThanOrEqualToConstant: 400
        ).isActive = true

        scroll.widthAnchor.constraint(
            greaterThanOrEqualToConstant: 450
        ).isActive = true

        return container
    }

    private func makePlaybackControls() -> NSView {
        let controls = NSStackView()
        controls.orientation = .horizontal
        controls.spacing = 10

        let previousButton = makeButton(
            "◀ Previous",
            action: #selector(previousFrame)
        )

        let nextButton = makeButton(
            "Next ▶",
            action: #selector(nextFrame)
        )

        playButton.target = self
        playButton.action = #selector(playAnimation)

        stopButton.target = self
        stopButton.action = #selector(stopAnimation)
        stopButton.isEnabled = false

        fpsSlider.target = self
        fpsSlider.action = #selector(fpsChanged)
        fpsSlider.numberOfTickMarks = 20
        fpsSlider.allowsTickMarkValuesOnly = true

        controls.addArrangedSubview(previousButton)
        controls.addArrangedSubview(playButton)
        controls.addArrangedSubview(stopButton)
        controls.addArrangedSubview(nextButton)

        controls.addArrangedSubview(NSView())

        controls.addArrangedSubview(fpsLabel)
        controls.addArrangedSubview(fpsSlider)

        fpsSlider.widthAnchor.constraint(
            equalToConstant: 170
        ).isActive = true

        return controls
    }

    private func makeFileControls() -> NSView {
        let controls = NSStackView()
        controls.orientation = .horizontal
        controls.spacing = 10

        let newButton = makeButton(
            "New Project",
            action: #selector(newProject)
        )

        let openButton = makeButton(
            "Open",
            action: #selector(openProject)
        )

        let saveButton = makeButton(
            "Save",
            action: #selector(saveProject)
        )

        controls.addArrangedSubview(newButton)

        controls.addArrangedSubview(NSView())

        controls.addArrangedSubview(openButton)
        controls.addArrangedSubview(saveButton)

        return controls
    }

    private func makeButton(
        _ title: String,
        action: Selector
    ) -> NSButton {
        let button = NSButton(
            title: title,
            target: self,
            action: action
        )

        button.bezelStyle = .rounded

        return button
    }

    func numberOfRows(
        in tableView: NSTableView
    ) -> Int {
        frames.count
    }

    func tableView(
        _ tableView: NSTableView,
        viewFor tableColumn: NSTableColumn?,
        row: Int
    ) -> NSView? {
        let identifier =
            NSUserInterfaceItemIdentifier("FrameCell")

        var cell = tableView.makeView(
            withIdentifier: identifier,
            owner: self
        ) as? NSTableCellView

        if cell == nil {
            cell = NSTableCellView()
            cell?.identifier = identifier

            let text = NSTextField(
                labelWithString: ""
            )

            text.translatesAutoresizingMaskIntoConstraints = false

            cell?.textField = text
            cell?.addSubview(text)

            if let cell = cell {
                NSLayoutConstraint.activate([
                    text.leadingAnchor.constraint(
                        equalTo: cell.leadingAnchor,
                        constant: 8
                    ),
                    text.centerYAnchor.constraint(
                        equalTo: cell.centerYAnchor
                    )
                ])
            }
        }

        cell?.textField?.stringValue =
            "Frame \(row + 1)"

        return cell
    }

    func tableViewSelectionDidChange(
        _ notification: Notification
    ) {
        let selected = tableView.selectedRow

        guard selected >= 0,
              selected < frames.count
        else {
            return
        }

        currentFrame = selected
        loadCurrentFrame()
    }

    func textDidChange(
        _ notification: Notification
    ) {
        guard !isPlaying else {
            return
        }

        frames[currentFrame] = textView.string
    }

    private var isPlaying: Bool {
        playbackTimer != nil
    }

    @objc
    private func addFrame() {
        stopPlayback()

        frames[currentFrame] = textView.string

        let copy = frames[currentFrame]

        let newIndex = currentFrame + 1

        frames.insert(
            copy,
            at: newIndex
        )

        currentFrame = newIndex

        refreshEverything()
        selectCurrentFrame()
    }

    @objc
    private func duplicateFrame() {
        addFrame()
    }

    @objc
    private func deleteFrame() {
        stopPlayback()

        if frames.count == 1 {
            frames[0] = ""
            currentFrame = 0
        } else {
            frames.remove(
                at: currentFrame
            )

            if currentFrame >= frames.count {
                currentFrame = frames.count - 1
            }
        }

        refreshEverything()
        selectCurrentFrame()
    }

    @objc
    private func previousFrame() {
        stopPlayback()

        currentFrame -= 1

        if currentFrame < 0 {
            currentFrame = frames.count - 1
        }

        selectCurrentFrame()
    }

    @objc
    private func nextFrame() {
        stopPlayback()

        currentFrame += 1

        if currentFrame >= frames.count {
            currentFrame = 0
        }

        selectCurrentFrame()
    }

    @objc
    private func playAnimation() {
        guard frames.count > 0 else {
            return
        }

        frames[currentFrame] = textView.string

        stopPlayback()

        playbackFrame = 0

        textView.isEditable = false
        tableView.isEnabled = false

        playButton.isEnabled = false
        stopButton.isEnabled = true

        showPlaybackFrame()

        playbackTimer = Timer.scheduledTimer(
            timeInterval: 1.0 / fps,
            target: self,
            selector: #selector(playbackTick),
            userInfo: nil,
            repeats: true
        )
    }

    @objc
    private func playbackTick() {
        playbackFrame += 1

        if playbackFrame >= frames.count {
            playbackFrame = 0
        }

        showPlaybackFrame()
    }

    private func showPlaybackFrame() {
        textView.string =
            frames[playbackFrame]

        frameCounter.stringValue =
            "Playing \(playbackFrame + 1) / \(frames.count)"
    }

    @objc
    private func stopAnimation() {
        stopPlayback()
        loadCurrentFrame()
        selectCurrentFrame()
    }

    private func stopPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil

        textView.isEditable = true
        tableView.isEnabled = true

        playButton.isEnabled = true
        stopButton.isEnabled = false
    }

    @objc
    private func fpsChanged() {
        fps = fpsSlider.doubleValue.rounded()

        fpsLabel.stringValue =
            "FPS: \(Int(fps))"

        if isPlaying {
            playbackTimer?.invalidate()

            playbackTimer = Timer.scheduledTimer(
                timeInterval: 1.0 / fps,
                target: self,
                selector: #selector(playbackTick),
                userInfo: nil,
                repeats: true
            )
        }
    }

    @objc
    private func newProject() {
        stopPlayback()

        frames = [""]
        currentFrame = 0
        fps = 4

        fpsSlider.doubleValue = 4
        fpsLabel.stringValue = "FPS: 4"

        refreshEverything()
        selectCurrentFrame()
    }

    @objc
    private func saveProject() {
        stopPlayback()

        frames[currentFrame] = textView.string

        let panel = NSSavePanel()

        panel.title = "Save ASCIIMotion Project"
        panel.nameFieldStringValue =
            "Untitled.asciimotion"

        panel.allowedFileTypes = [
            "asciimotion"
        ]

        guard panel.runModal() == .OK,
              let url = panel.url
        else {
            return
        }

        let project = ASCIIMotionProject(
            fps: fps,
            frames: frames
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [
                .prettyPrinted
            ]

            let data =
                try encoder.encode(project)

            try data.write(
                to: url,
                options: .atomic
            )

        } catch {
            showError(
                "Save Failed",
                error.localizedDescription
            )
        }
    }

    @objc
    private func openProject() {
        stopPlayback()

        let panel = NSOpenPanel()

        panel.title =
            "Open ASCIIMotion Project"

        panel.allowedFileTypes = [
            "asciimotion"
        ]

        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK,
              let url = panel.url
        else {
            return
        }

        do {
            let data =
                try Data(contentsOf: url)

            let project =
                try JSONDecoder().decode(
                    ASCIIMotionProject.self,
                    from: data
                )

            frames =
                project.frames.isEmpty
                ? [""]
                : project.frames

            fps = max(
                1,
                min(
                    20,
                    project.fps
                )
            )

            currentFrame = 0

            fpsSlider.doubleValue = fps
            fpsLabel.stringValue =
                "FPS: \(Int(fps))"

            refreshEverything()
            selectCurrentFrame()

        } catch {
            showError(
                "Open Failed",
                error.localizedDescription
            )
        }
    }

    private func refreshEverything() {
        tableView.reloadData()
        loadCurrentFrame()
    }

    private func loadCurrentFrame() {
        guard currentFrame >= 0,
              currentFrame < frames.count
        else {
            return
        }

        textView.string =
            frames[currentFrame]

        frameCounter.stringValue =
            "Frame \(currentFrame + 1) / \(frames.count)"
    }

    private func selectCurrentFrame() {
        tableView.selectRowIndexes(
            IndexSet(
                integer: currentFrame
            ),
            byExtendingSelection: false
        )

        tableView.scrollRowToVisible(
            currentFrame
        )
    }

    private func showError(
        _ title: String,
        _ message: String
    ) {
        let alert = NSAlert()

        alert.alertStyle = .critical
        alert.messageText = title
        alert.informativeText = message

        alert.runModal()
    }
}

final class AppDelegate:
    NSObject,
    NSApplicationDelegate
{
    private var windowController:
        MainWindowController?

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {
        windowController =
            MainWindowController()

        windowController?.showWindow(nil)

        NSApp.activate(
            ignoringOtherApps: true
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()

app.delegate = delegate
app.setActivationPolicy(.regular)

app.run()
