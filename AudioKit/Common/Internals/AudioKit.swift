//
//  AudioKit.swift
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2017 Aurelius Prochazka. All rights reserved.
//

#if !os(tvOS)
import CoreAudioKit
#endif

#if !os(macOS)
import UIKit
#endif
import Dispatch

public typealias AKCallback = () -> Void

/// Adding connection between nodes with default format
extension AVAudioEngine {
    open func connect(_ node1: AVAudioNode, to node2: AVAudioNode) {
        connect(node1, to: node2, format: AudioKit.format)
    }
}

/// Top level AudioKit managing class
@objc open class AudioKit: NSObject {

    // MARK: Global audio format (44.1K, Stereo)

    /// Format of AudioKit Nodes
    @objc open static var format = AKSettings.audioFormat

    // MARK: - Internal audio engine mechanics

    /// Reference to the AV Audio Engine
    @objc open static let engine = AVAudioEngine()

    @objc static var shouldBeRunning = false

    @objc static var finalMixer = AKMixer()

    /// An audio output operation that most applications will need to use last
    @objc open static var output: AKNode? {
        didSet {
            output?.connect(to: finalMixer)
            engine.connect(finalMixer.avAudioNode, to: engine.outputNode)
        }
    }

    // MARK: - Device Management

    /// Enumerate the list of available input devices.
    @objc open static var inputDevices: [AKDevice]? {
        #if os(macOS)
            EZAudioUtilities.setShouldExitOnCheckResultFail(false)
            return EZAudioDevice.inputDevices().map {
                AKDevice(name: ($0 as AnyObject).name, deviceID: ($0 as AnyObject).deviceID)
            }
        #else
            var returnDevices = [AKDevice]()
            if let devices = AVAudioSession.sharedInstance().availableInputs {
                for device in devices {
                    if device.dataSources == nil || device.dataSources!.isEmpty {
                        returnDevices.append(AKDevice(name: device.portName, deviceID: device.uid))
                    } else {
                        for dataSource in device.dataSources! {
                            returnDevices.append(AKDevice(name: device.portName,
                                                          deviceID: "\(device.uid) \(dataSource.dataSourceName)"))
                        }
                    }
                }
                return returnDevices
            }
            return nil
        #endif
    }

    /// Enumerate the list of available output devices.
    @objc open static var outputDevices: [AKDevice]? {
        #if os(macOS)
            EZAudioUtilities.setShouldExitOnCheckResultFail(false)
            return EZAudioDevice.outputDevices().map {
                AKDevice(name: ($0 as AnyObject).name, deviceID: ($0 as AnyObject).deviceID)
            }
        #else
            let devs = AVAudioSession.sharedInstance().currentRoute.outputs
            if devs.isNotEmpty {
                var outs = [AKDevice]()
                for dev in devs {
                    outs.append(AKDevice(name: dev.portName, deviceID: dev.uid))
                }
                return outs
            }
            return nil
        #endif
    }

    /// The name of the current input device, if available.
    @objc open static var inputDevice: AKDevice? {
        #if os(macOS)
            if let dev = EZAudioDevice.currentInput() {
                return AKDevice(name: dev.name, deviceID: dev.deviceID)
            }
        #else
            if let dev = AVAudioSession.sharedInstance().preferredInput {
                return AKDevice(name: dev.portName, deviceID: dev.uid)
            } else {
                let inputDevices = AVAudioSession.sharedInstance().currentRoute.inputs
                if inputDevices.isNotEmpty {
                    for device in inputDevices {
                        let dataSourceString = device.selectedDataSource?.description ?? ""
                        let id = "\(device.uid) \(dataSourceString)".trimmingCharacters(in: [" "])
                        return AKDevice(name: device.portName, deviceID: id)
                    }
                }
            }
        #endif
        return nil
    }

    /// The name of the current output device, if available.
    @objc open static var outputDevice: AKDevice? {
        #if os(macOS)
            if let dev = EZAudioDevice.currentOutput() {
                return AKDevice(name: dev.name, deviceID: dev.deviceID)
            }
        #else
            let devs = AVAudioSession.sharedInstance().currentRoute.outputs
            if devs.isNotEmpty {
                return AKDevice(name: devs[0].portName, deviceID: devs[0].uid)
            }

        #endif
        return nil
    }

    /// Change the preferred input device, giving it one of the names from the list of available inputs.
    @objc open static func setInputDevice(_ input: AKDevice) throws {
        #if os(macOS)
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultInputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMaster)
            var devid = input.deviceID
            AudioObjectSetPropertyData(
                AudioObjectID(kAudioObjectSystemObject),
                &address, 0, nil, UInt32(MemoryLayout<AudioDeviceID>.size), &devid)
        #else
            if let devices = AVAudioSession.sharedInstance().availableInputs {
                for device in devices {
                    if device.dataSources == nil || device.dataSources!.isEmpty {
                        if device.uid == input.deviceID {
                            do {
                                try AVAudioSession.sharedInstance().setPreferredInput(device)
                            } catch {
                                AKLog("Could not set the preferred input to \(input)")
                            }
                        }
                    } else {
                        for dataSource in device.dataSources! {
                            if input.deviceID == "\(device.uid) \(dataSource.dataSourceName)" {
                                do {
                                    try AVAudioSession.sharedInstance().setInputDataSource(dataSource)
                                } catch {
                                    AKLog("Could not set the preferred input to \(input)")
                                }
                            }
                        }
                    }
                }
            }

            if let devices = AVAudioSession.sharedInstance().availableInputs {
                for dev in devices {
                    if dev.uid == input.deviceID {
                        do {
                            try AVAudioSession.sharedInstance().setPreferredInput(dev)
                        } catch {
                            AKLog("Could not set the preferred input to \(input)")
                        }
                    }
                }
            }
        #endif
    }

    /// Change the preferred output device, giving it one of the names from the list of available output.
    @objc open static func setOutputDevice(_ output: AKDevice) throws {
        #if os(macOS)
            var id = output.deviceID
            if let audioUnit = AudioKit.engine.outputNode.audioUnit {
                AudioUnitSetProperty(audioUnit,
                                     kAudioOutputUnitProperty_CurrentDevice,
                                     kAudioUnitScope_Global, 0,
                                     &id,
                                     UInt32(MemoryLayout<DeviceID>.size))
            }
        #else
            //not available on ios
        #endif
    }

    // MARK: - Start/Stop

    /// Start up the audio engine with periodic functions
    open static func start(withPeriodicFunctions functions: AKPeriodicFunction...) {
        for function in functions {
            function.connect(to: finalMixer)
        }
        start()
    }

    /// Start up the audio engine
    @objc open static func start() {
        if output == nil {
            AKLog("AudioKit: No output node has been set yet, no processing will happen.")
        }
        // Start the engine.
        do {
            engine.prepare()

            #if os(iOS)

                if AKSettings.enableRouteChangeHandling {
                    NotificationCenter.default.addObserver(
                        self,
                        selector: #selector(AudioKit.restartEngineAfterRouteChange),
                        name: .AVAudioSessionRouteChange,
                        object: nil)
                }

                if AKSettings.enableCategoryChangeHandling {
                    NotificationCenter.default.addObserver(
                        self,
                        selector: #selector(AudioKit.restartEngineAfterConfigurationChange),
                        name: .AVAudioEngineConfigurationChange,
                        object: engine)
                }

            #endif
            #if !os(macOS)
                if AKSettings.audioInputEnabled {

                #if os(iOS)

                    var options: AVAudioSessionCategoryOptions = [.mixWithOthers]

                    if #available(iOS 10.0, *) {
                        // Blueooth Options
                        // .allowBluetooth can only be set with the categories .playAndRecord and .record
                        // .allowBluetoothA2DP comes for free if the category is .ambient, .soloAmbient, or
                        // .playback. This option is cleared if the category is .record, or .multiRoute. If this
                        // option and .allowBluetooth are set and a device supports Hands-Free Profile (HFP) and the
                        // Advanced Audio Distribution Profile (A2DP), the Hands-Free ports will be given a higher
                        // priority for routing.
                        if AKSettings.bluetoothOptions.isNotEmpty {
                            options = options.union(AKSettings.bluetoothOptions)
                        } else if AKSettings.useBluetooth {
                            // If bluetoothOptions aren't specified
                            // but useBluetooth is then we will use these defaults
                            options = options.union([.allowBluetooth,
                                                     .allowBluetoothA2DP])
                        }

                        // AirPlay
                        if AKSettings.allowAirPlay {
                            options = options.union(.allowAirPlay)
                        }
                    } else if AKSettings.bluetoothOptions.isNotEmpty ||
                              AKSettings.useBluetooth ||
                              AKSettings.allowAirPlay {
                        AKLog("Some of the specified AKSettings are not supported by iOS 9 and were ignored.")
                    }

                    // Default to Speaker
                    if AKSettings.defaultToSpeaker {
                        options = options.union(.defaultToSpeaker)
                    }

                    try AKSettings.setSession(category: .playAndRecord,
                                              with: options)

                #elseif os(tvOS)
                    // tvOS
                    try AKSettings.setSession(category: .playAndRecord)

                #endif

                } else if AKSettings.playbackWhileMuted {
                    try AKSettings.setSession(category: .playback)
                } else {
                    try AKSettings.setSession(category: .ambient)
                }

                #if os(iOS)
                    try AVAudioSession.sharedInstance().setActive(true)
                #endif

            #endif

            try engine.start()
            shouldBeRunning = true

        } catch {
            fatalError("AudioKit: Could not start engine. error: \(error).")
        }
    }

    /// Stop the audio engine
    @objc open static func stop() {
        // Stop the engine.
        engine.stop()
        shouldBeRunning = false
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            AKLog("couldn't stop session \(error)")
        }
        #endif
    }

    // MARK: - Testing

    /// Testing AKNode
    @objc open static var tester: AKTester?

    /// Test the output of a given node
    ///
    /// - Parameters:
    ///   - node: AKNode to test
    ///   - duration: Number of seconds to test (accurate to the sample)
    ///
    @objc open static func test(node: AKNode, duration: Double, afterStart: () -> Void = {}) {
        #if swift(>=3.2)
        if #available(iOS 11, macOS 10.13, tvOS 11, *) {
            let samples = Int(duration * AKSettings.sampleRate)

            tester = AKTester(node, samples: samples)
            output = tester

            do {
                // maximum number of frames the engine will be asked to render in any single render call
                let maxNumberOfFrames: AVAudioFrameCount = 4_096
                engine.reset()
                try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: maxNumberOfFrames)
                try engine.start()
            } catch {
                fatalError("could not enable manual rendering mode, \(error)")
            }
            afterStart()
            tester?.play()

            let buffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat,
                                                            frameCapacity: engine.manualRenderingMaximumFrameCount)!

            while engine.manualRenderingSampleTime < samples {
                do {
                    let framesToRender = buffer.frameCapacity
                    let status = try engine.renderOffline(framesToRender, to: buffer)
                    switch status {
                    case .success:
                        // data rendered successfully
                        break

                    case .insufficientDataFromInputNode:
                        // applicable only if using the input node as one of the sources
                        break

                    case .cannotDoInCurrentContext:
                        // engine could not render in the current render call, retry in next iteration
                        break

                    case .error:
                        // error occurred while rendering
                        fatalError("render failed")
                    }
                } catch {
                    fatalError("render failed, \(error)")
                }
            }
            tester?.stop()
        }
        #endif
    }

    /// Audition the test to hear what it sounds like
    ///
    /// - Parameters:
    ///   - node: AKNode to test
    ///   - duration: Number of seconds to test (accurate to the sample)
    ///
    @objc open static func auditionTest(node: AKNode, duration: Double) {
        output = node
        start()
        if let playableNode = node as? AKToggleable {
            playableNode.play()
        }
        usleep(UInt32(duration * 1_000_000))
        stop()
        start()
    }

    // MARK: - Configuration Change Response

    // Listen to changes in audio configuration
    // and restart the audio engine if it stops and should be playing
    @objc fileprivate static func restartEngineAfterConfigurationChange(_ notification: Notification) {
        DispatchQueue.main.async {
            if shouldBeRunning && !engine.isRunning {
                do {

                    #if !os(macOS)
                        let appIsNotActive = UIApplication.shared.applicationState != .active
                        let appDoesNotSupportBackgroundAudio = !AKSettings.appSupportsBackgroundAudio

                        if appIsNotActive && appDoesNotSupportBackgroundAudio {
                            AKLog("engine not restarted after configuration change since app was not active and does not support background audio")
                            return
                        }
                    #endif

                    try engine.start()

                    // Sends notification after restarting the engine, so it is safe to resume AudioKit functions.
                    if AKSettings.notificationsEnabled {
                        NotificationCenter.default.post(
                            name: .AKEngineRestartedAfterConfigurationChange,
                            object: nil,
                            userInfo: notification.userInfo)
                    }

                } catch {
                    AKLog("couldn't start engine after configuration change \(error)")
                }
            }
        }
    }

    // Restarts the engine after audio output has been changed, like headphones plugged in.
    @objc fileprivate static func restartEngineAfterRouteChange(_ notification: Notification) {
        DispatchQueue.main.async {
            if shouldBeRunning && !engine.isRunning {
                do {

                    #if !os(macOS)
                    let appIsNotActive = UIApplication.shared.applicationState != .active
                    let appDoesNotSupportBackgroundAudio = !AKSettings.appSupportsBackgroundAudio

                    if appIsNotActive && appDoesNotSupportBackgroundAudio {
                        AKLog("engine not restarted after route change since app was not active and does not support background audio")
                        return
                    }
                    #endif

                    try engine.start()

                    // Sends notification after restarting the engine, so it is safe to resume AudioKit functions.
                    if AKSettings.notificationsEnabled {
                        NotificationCenter.default.post(
                            name: .AKEngineRestartedAfterRouteChange,
                            object: nil,
                            userInfo: notification.userInfo)
                    }
                } catch {
                    AKLog("error restarting engine after route change")
                }
            }
        }
    }

    // MARK: - Disconnect node inputs

    /// Disconnect all inputs
    @objc open static func disconnectAllInputs() {
        engine.disconnectNodeInput(finalMixer.avAudioNode)
    }

    // MARK: - Deinitialization

    deinit {
        #if os(iOS)
            NotificationCenter.default.removeObserver(
                self,
                name: .AKEngineRestartedAfterRouteChange,
                object: nil)
        #endif
    }
}

//This extension makes connect calls shorter, and safer by attaching nodes if not already attached.
extension AudioKit {

    private static func safeAttach(_ nodes: [AVAudioNode]) {
        _ = nodes.filter { $0.engine == nil }.map { engine.attach($0) }
    }

    @objc open static func connect(_ sourceNode: AVAudioNode,
                                   to destNodes: [AVAudioConnectionPoint],
                                   fromBus sourceBus: AVAudioNodeBus,
                                   format: AVAudioFormat?) {
        let connectionsWithNodes = destNodes.filter { $0.node != nil }
        safeAttach([sourceNode] + connectionsWithNodes.map { $0.node! })
        engine.connect(sourceNode, to: connectionsWithNodes, fromBus: sourceBus, format: format)
    }

    @objc open static func connect(_ node1: AVAudioNode,
                                   to node2: AVAudioNode,
                                   fromBus bus1: AVAudioNodeBus,
                                   toBus bus2: AVAudioNodeBus,
                                   format: AVAudioFormat?) {
        safeAttach([node1, node2])
        engine.connect(node1, to: node2, fromBus: bus1, toBus: bus2, format: format)
    }

    @objc open static func connect(_ node1: AVAudioNode, to node2: AVAudioNode, format: AVAudioFormat?) {
        connect(node1, to: node2, fromBus: 0, toBus: 0, format: format)
    }

    //Convenience
    @objc open static func detach(nodes: [AVAudioNode]) {
        for node in nodes {
            engine.detach(node)
        }
    }
}
