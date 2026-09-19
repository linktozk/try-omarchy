import Foundation
import Testing

@Suite("Native scroll device contract")
struct ScrollNativeContractTests {
    @Test("Launcher wires explicit scroll devices into Cocoa")
    func launcherContract() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let runner = try String(
            contentsOf: root.appendingPathComponent("run-qemu-gpu.sh"),
            encoding: .utf8
        )

        #expect(runner.contains("virtio-scroll-touchpad-pci,id=omarchy-scroll-touchpad"))
        #expect(runner.contains("virtio-hires-wheel-pci,id=omarchy-hires-wheel"))
        #expect(runner.contains("scroll-touchpad=omarchy-scroll-touchpad"))
        #expect(runner.contains("scroll-wheel=omarchy-hires-wheel"))
        #expect(runner.contains("scroll-mode=$scroll_mode"))
        #expect(runner.contains("OMARCHY_SCROLL_MODE must be auto, trackpad, or wheel"))
    }

    @Test("Build applies the three decoupled QEMU patches")
    func buildContract() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let builder = try String(
            contentsOf: root.appendingPathComponent("build-qemu-gpu-runtime.sh"),
            encoding: .utf8
        )

        #expect(builder.contains("qemu-scroll-gesture-sink.patch"))
        #expect(builder.contains("qemu-virtio-scroll-devices.patch"))
        #expect(builder.contains("qemu-cocoa-scroll-routing.patch"))
    }
}
