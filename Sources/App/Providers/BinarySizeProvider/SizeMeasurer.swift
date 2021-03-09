//
//  Measure.swift
//  
//
//  Created by Marino Felipe on 29.12.20.
//

import Foundation
import Core

final class SizeMeasurer {
    private var appManager: AppManager
    private let console: Console
    private let verbose: Bool

    public convenience init(verbose: Bool) {
        self.init(appManager: .init(verbose: verbose), verbose: verbose)
    }

    init(
        appManager: AppManager = .init(verbose: true),
        console: Console = .default,
        verbose: Bool
    ) {
        self.appManager = appManager
        self.console = console
        self.verbose = verbose
    }

    private static let stepsCount = 7
    private var currentStep = 1
    private static let second: Double = 1_000_000

    deinit {
        try? appManager.cleanUp()
    }

    public func formattedBinarySize(
        for swiftPackage: SwiftPackage,
        isDynamic: Bool
    ) throws -> String {
        console.lineBreak()

        let emptyAppSize = try measureEmptyAppSize()
        let appSizeWithDependencyAdded = try measureAppSize(
            with: swiftPackage,
            isDynamic: isDynamic
        )

        completeLoading()
        let increasedSize = appSizeWithDependencyAdded.amount - emptyAppSize.amount
        return URL.fileByteCountFormatter
            .string(for: increasedSize) ?? "\(increasedSize)"
    }
}

// MARK: - Private

private extension SizeMeasurer {
    func measureEmptyAppSize() throws -> SizeOnDisk {
        if verbose == false { showOrUpdateLoading(withText: "Cleaning up empty app directory...") }
        try appManager.cleanUp()

        if verbose {
            console.lineBreakAndWrite("Cloning empty app")
        } else {
            showOrUpdateLoading(withText: "Cloning empty app...")
        }
        try appManager.cloneEmptyApp()

        if verbose {
            console.lineBreakAndWrite(
                .init(
                    text: "Measuring empty app size",
                    color: .green,
                    isBold: true
                )
            )
        }

        if verbose == false { showOrUpdateLoading(withText: "Generating archive for empty app...") }
        try appManager.generateArchive()
        if verbose == false { showOrUpdateLoading(withText: "Calculating binary size...") }
        return try appManager.calculateBinarySize()
    }

    func measureAppSize(
        with swiftPackage: SwiftPackage,
        isDynamic: Bool
    ) throws -> SizeOnDisk {
        if verbose {
            console.lineBreakAndWrite(
                .init(
                    text: "Measuring app size with \(swiftPackage.product) added as dependency",
                    color: .green,
                    isBold: true
                )
            )
        }

        if verbose == false { showOrUpdateLoading(withText: "Adding \(swiftPackage.product) as dependency...") }
        try appManager.add(
            asDependency: swiftPackage,
            isDynamic: isDynamic
        )
        if verbose == false { showOrUpdateLoading(withText: "Generating archive for updated app...") }
        try appManager.generateArchive()
        if verbose == false { showOrUpdateLoading(withText: "Calculating updated binary size...") }
        return try appManager.calculateBinarySize()
    }

    func showOrUpdateLoading(withText text: String) {
        usleep(UInt32(Self.second * 0.5))
        console.showLoading(step: currentStep, total: Self.stepsCount, text: text)
        currentStep += 1
    }

    func completeLoading() {
        console.completeLoading(success: true)
        currentStep = 0
    }
}
