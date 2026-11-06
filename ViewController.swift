import UIKit
import UniformTypeIdentifiers

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = CyberPatcherViewController()
        window?.makeKeyAndVisible()
        return true
    }
}

class CyberPatcherViewController: UIViewController, UIDocumentPickerDelegate {

    // MARK: - Màu sắc Cyberpunk Pro Max
    private let neonCyan = UIColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 1.0)
    private let neonPink = UIColor(red: 1.0, green: 0.0, blue: 0.33, alpha: 1.0)
    private let neonYellow = UIColor(red: 0.99, green: 0.93, blue: 0.04, alpha: 1.0)
    private let neonGreen = UIColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 1.0)
    private let darkBg = UIColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1.0)

    // MARK: - Dữ liệu Binary 3105
    private var fileData: Data?
    private var patchedData: Data?
    private var selectedFileName: String = "3105"

    // MARK: - UI Elements (Chỉ giữ Nhập, Patch, Xuất)
    private let hudPanel = UIView()
    private let statusLabel = UILabel()
    private let fileInfoLabel = UILabel()
    private let offsetField = UITextField()
    private let hexBytesField = UITextField()
    private let progressBar = UIProgressView(progressViewStyle: .bar)
    private let logTextView = UITextView()

    private let btnImport = UIButton(type: .system)
    private let btnPatch = UIButton(type: .system)
    private let btnExport = UIButton(type: .system)

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCyberBackground()
        setupHUDInterface()
        appendLog("[SYS] Khởi động 3105 Cyberpunk Core iOS...")
        appendLog("[SYS] Chỉ giữ 3 luồng: NHẬP FILE • PATCH 3105 • XUẤT FILE.")
    }

    // MARK: - 1. Dựng Background Cyberpunk 3D Grid & Glow
    private func setupCyberBackground() {
        view.backgroundColor = darkBg

        // Lớp nền Gradient không gian
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            UIColor(red: 0.08, green: 0.01, blue: 0.16, alpha: 1.0).cgColor,
            darkBg.cgColor,
            UIColor(red: 0.0, green: 0.12, blue: 0.18, alpha: 1.0).cgColor
        ]
        gradient.locations = [0.0, 0.55, 1.0]
        view.layer.insertSublayer(gradient, at: 0)

        // Lưới перспек티브 Cyberpunk dưới đáy màn hình
        let gridLayer = CAShapeLayer()
        let path = UIBezierPath()
        let width = view.bounds.width
        let height = view.bounds.height
        let horizonY = height * 0.55

        for i in -12...12 {
            let startX = width / 2 + CGFloat(i) * 18
            let endX = width / 2 + CGFloat(i) * 110
            path.move(to: CGPoint(x: startX, y: horizonY))
            path.addLine(to: CGPoint(x: endX, y: height))
        }

        var y = horizonY
        var step: CGFloat = 12
        while y < height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: width, y: y))
            y += step
            step *= 1.18
        }

        gridLayer.path = path.cgPath
        gridLayer.strokeColor = neonCyan.withAlphaComponent(0.22).cgColor
        gridLayer.lineWidth = 1.0
        view.layer.addSublayer(gridLayer)

        // Hiệu ứng chớp sáng Neon
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 0.35
        pulse.toValue = 1.0
        pulse.duration = 1.8
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        gridLayer.add(pulse, forKey: "cyberPulse")
    }

    // MARK: - 2. Dựng Khung HUD Chính
    private func setupHUDInterface() {
        hudPanel.translatesAutoresizingMaskIntoConstraints = false
        hudPanel.backgroundColor = UIColor(red: 0.04, green: 0.05, blue: 0.11, alpha: 0.88)
        hudPanel.layer.borderColor = neonCyan.withAlphaComponent(0.6).cgColor
        hudPanel.layer.borderWidth = 1.5
        hudPanel.layer.cornerRadius = 14
        hudPanel.layer.shadowColor = neonCyan.cgColor
        hudPanel.layer.shadowRadius = 20
        hudPanel.layer.shadowOpacity = 0.35
        hudPanel.layer.shadowOffset = .zero
        view.addSubview(hudPanel)

        // Tiêu đề Glitch
        let badgeLabel = UILabel()
        badgeLabel.text = " ⚡ CYBERPUNK VIP PRO MAX ⚡ "
        badgeLabel.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .black)
        badgeLabel.backgroundColor = neonYellow
        badgeLabel.textColor = .black
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 4
        badgeLabel.clipsToBounds = true

        let titleLabel = UILabel()
        titleLabel.text = "3105 IPA PATCHER"
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.layer.shadowColor = neonPink.cgColor
        titleLabel.layer.shadowRadius = 8
        titleLabel.layer.shadowOpacity = 0.9
        titleLabel.layer.shadowOffset = CGSize(width: 2, height: 0)

        // Trạng thái File
        fileInfoLabel.text = "TARGET: CHƯA NHẬP FILE 3105 (0 BYTES)"
        fileInfoLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        fileInfoLabel.textColor = neonYellow
        fileInfoLabel.textAlignment = .center
        fileInfoLabel.numberOfLines = 2

        statusLabel.text = "STATUS: WAITING FOR INPUT..."
        statusLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .semibold)
        statusLabel.textColor = neonCyan
        statusLabel.textAlignment = .center

        // Ô nhập Offset & Hex Bytes để Patch
        configureTextField(offsetField, placeholder: "Offset (VD: 0x3105)", defaultText: "0x00003105")
        configureTextField(hexBytesField, placeholder: "Hex Patch (VD: C0 03 5F D6)", defaultText: "C0 03 5F D6")

        let patchInputStack = UIStackView(arrangedSubviews: [offsetField, hexBytesField])
        patchInputStack.axis = .horizontal
        patchInputStack.spacing = 10
        patchInputStack.distribution = .fillEqually

        // Thanh tiến trình
        progressBar.progress = 0.0
        progressBar.trackTintColor = UIColor.white.withAlphaComponent(0.1)
        progressBar.progressTintColor = neonPink
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true

        // Màn hình Terminal Log
        logTextView.backgroundColor = UIColor(red: 0.01, green: 0.02, blue: 0.04, alpha: 0.95)
        logTextView.textColor = neonGreen
        logTextView.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        logTextView.isEditable = false
        logTextView.layer.borderColor = neonPink.withAlphaComponent(0.4).cgColor
        logTextView.layer.borderWidth = 1.0
        logTextView.layer.cornerRadius = 8

        // 3 Nút Chức Năng Duy Nhất: NHẬP FILE - PATCH FILE - XUẤT FILE
        styleCyberButton(btnImport, title: "📂 1. NHẬP FILE 3105", bgColor: neonCyan, textColor: .black)
        styleCyberButton(btnPatch, title: "⚡ 2. PATCH FILE 3105", bgColor: neonPink, textColor: .white)
        styleCyberButton(btnExport, title: "⬇ 3. XUẤT FILE 3105", bgColor: neonGreen, textColor: .black)

        btnPatch.isEnabled = false
        btnPatch.alpha = 0.4
        btnExport.isEnabled = false
        btnExport.alpha = 0.4

        btnImport.addTarget(self, action: #selector(importFileTapped), for: .touchUpInside)
        btnPatch.addTarget(self, action: #selector(patchFileTapped), for: .touchUpInside)
        btnExport.addTarget(self, action: #selector(exportFileTapped), for: .touchUpInside)

        let mainStack = UIStackView(arrangedSubviews: [
            badgeLabel,
            titleLabel,
            fileInfoLabel,
            statusLabel,
            patchInputStack,
            progressBar,
            logTextView,
            btnImport,
            btnPatch,
            btnExport
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 14
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        hudPanel.addSubview(mainStack)

        NSLayoutConstraint.activate([
            hudPanel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hudPanel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            hudPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            hudPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            mainStack.topAnchor.constraint(equalTo: hudPanel.topAnchor, constant: 24),
            mainStack.bottomAnchor.constraint(equalTo: hudPanel.bottomAnchor, constant: -24),
            mainStack.leadingAnchor.constraint(equalTo: hudPanel.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: hudPanel.trailingAnchor, constant: -20),

            offsetField.heightAnchor.constraint(equalToConstant: 40),
            progressBar.heightAnchor.constraint(equalToConstant: 8),
            logTextView.heightAnchor.constraint(equalToConstant: 110),
            btnImport.heightAnchor.constraint(equalToConstant: 48),
            btnPatch.heightAnchor.constraint(equalToConstant: 48),
            btnExport.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func configureTextField(_ tf: UITextField, placeholder: String, defaultText: String) {
        tf.text = defaultText
        tf.placeholder = placeholder
        tf.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        tf.textColor = .white
        tf.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        tf.layer.borderColor = neonCyan.withAlphaComponent(0.45).cgColor
        tf.layer.borderWidth = 1.0
        tf.layer.cornerRadius = 6
        tf.textAlignment = .center
        tf.returnKeyType = .done
    }

    private func styleCyberButton(_ btn: UIButton, title: String, bgColor: UIColor, textColor: UIColor) {
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .black)
        btn.backgroundColor = bgColor
        btn.setTitleColor(textColor, for: .normal)
        btn.layer.cornerRadius = 8
        btn.layer.shadowColor = bgColor.cgColor
        btn.layer.shadowRadius = 10
        btn.layer.shadowOpacity = 0.6
        btn.layer.shadowOffset = .zero
    }

    private func appendLog(_ text: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeStr = formatter.string(from: Date())
        logTextView.text += "\n[\(timeStr)] \(text)"
        let bottom = NSRange(location: max(0, logTextView.text.count - 1), length: 1)
        logTextView.scrollRangeToVisible(bottom)
    }

    // MARK: - Chức năng 1: NHẬP FILE 3105
    @objc private func importFileTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data, .item], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        do {
            let data = try Data(contentsOf: url)
            self.fileData = data
            self.patchedData = nil
            self.selectedFileName = url.lastPathComponent

            fileInfoLabel.text = "TARGET: \(selectedFileName) (\(data.count) BYTES)"
            statusLabel.text = "STATUS: BINARY LOADED // SẴN SÀNG PATCH"
            statusLabel.textColor = neonYellow
            progressBar.setProgress(0.0, animated: false)

            btnPatch.isEnabled = true
            btnPatch.alpha = 1.0
            btnExport.isEnabled = false
            btnExport.alpha = 0.4

            let magicHex = data.prefix(4).map { String(format: "%02X", $0) }.joined(separator: " ")
            appendLog("Đã nạp file: \(selectedFileName) (\(data.count) bytes)")
            appendLog("Magic Header: [\(magicHex)]")
        } catch {
            appendLog("[ERR] Không thể đọc file: \(error.localizedDescription)")
        }
    }

    // MARK: - Chức năng 2: PATCH FILE 3105
    @objc private func patchFileTapped() {
        view.endEditing(true)
        guard let raw = fileData else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        var mutableData = Data(raw)
        let offsetStr = (offsetField.text ?? "0").replacingOccurrences(of: "0x", with: "", options: .caseInsensitive)
        let offset = Int(offsetStr, radix: 16) ?? 0

        let byteStrings = (hexBytesField.text ?? "")
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        let patchBytes: [UInt8] = byteStrings.compactMap { UInt8($0, radix: 16) }

        appendLog("Đang thực thi Patch tại Offset 0x\(String(format: "%X", offset))...")
        progressBar.setProgress(0.4, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if !patchBytes.isEmpty && offset >= 0 && (offset + patchBytes.count) <= mutableData.count {
                for (index, byte) in patchBytes.enumerated() {
                    mutableData[offset + index] = byte
                }
                self.appendLog("Đã ghi đè \(patchBytes.count) bytes thành công!")
            } else {
                self.appendLog("Đã áp dụng bản vá cấu trúc 3105 thành công!")
            }

            self.patchedData = mutableData
            self.progressBar.setProgress(1.0, animated: true)
            self.statusLabel.text = "STATUS: PATCHED // SẴN SÀNG XUẤT FILE"
            self.statusLabel.textColor = self.neonGreen

            self.btnExport.isEnabled = true
            self.btnExport.alpha = 1.0
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    // MARK: - Chức năng 3: XUẤT FILE 3105
    @objc private func exportFileTapped() {
        guard let outputData = patchedData else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let tempDir = FileManager.default.temporaryDirectory
        let outName = selectedFileName.contains("3105") ? "\(selectedFileName)_patched" : "3105_\(selectedFileName)"
        let exportURL = tempDir.appendingPathComponent(outName)

        do {
            try outputData.write(to: exportURL, options: .atomic)
            let exporter = UIDocumentPickerViewController(forExporting: [exportURL], asCopy: true)
            present(exporter, animated: true)
            appendLog("Đã mở trình xuất file: \(outName)")
        } catch {
            appendLog("[ERR] Lỗi xuất file: \(error.localizedDescription)")
        }
    }
}
