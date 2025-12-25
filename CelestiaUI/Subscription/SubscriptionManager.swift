// SubscriptionManager.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import Foundation
import StoreKit

public extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("SubscriptionStatusChanged")
}

@MainActor
public class SubscriptionManager {
    public enum SubscriptionStatus: Hashable, Sendable {
        case unknown
        case empty
        case pending
        case verified(originalTransactionID: UInt64, productID: String, expirationDate: Date?, environment: SubscriptionEnvironment)
        case expired
        case revoked
    }

    public enum SubscriptionEnvironment: Sendable {
        case production
        case sandbox
        case xcode
    }

    public struct Plan {
        let product: Product
        let name: String
    }

    private(set) var status: SubscriptionStatus = .unknown
    private let userDefaults: UserDefaults
    private let requestHandler: RequestHandler

    private var transactionInfoCache: CacheTransactionInfo?

    private struct CacheTransactionInfo: Codable {
        let originalTransactionID: UInt64
        let isSandbox: Bool
    }

    private let monthlySubscriptionId = "space.celestia.mobilecelestia.plus.monthly"
    private let yearlySubscriptionId = "space.celestia.mobilecelestia.plus.yearly"
    private let cacheKey = "celestia-plus"

    public init(userDefaults: UserDefaults, requestHandler: RequestHandler) {
        self.userDefaults = userDefaults
        self.requestHandler = requestHandler
        if let data: Data = userDefaults.data(forKey: cacheKey), let decoded = try? JSONDecoder().decode(CacheTransactionInfo.self, from: data) {
            transactionInfoCache = decoded
        }
    }

    public func transactionInfo() -> (originalTransactionID: UInt64, isSandbox: Bool)? {
        if let transactionInfoCache {
            return (transactionInfoCache.originalTransactionID, transactionInfoCache.isSandbox)
        }
        return nil
    }

    @discardableResult public func checkSubscriptionStatus() async -> SubscriptionStatus {
        let monthlyStatus = subscriptionStatus(for: await Transaction.currentEntitlement(for: monthlySubscriptionId))
        let yearlyStatus = subscriptionStatus(for: await Transaction.currentEntitlement(for: yearlySubscriptionId))
        var newStatus: SubscriptionStatus
        if case SubscriptionStatus.verified(_, _, let yearlyExpiration, _) = yearlyStatus, case SubscriptionStatus.verified(_, _, let monthlyExpiration, _) = monthlyStatus, let yearlyExpiration, let monthlyExpiration, monthlyExpiration > yearlyExpiration {
            newStatus = monthlyStatus
        } else if case SubscriptionStatus.verified(_, _, _, _) = monthlyStatus {
            newStatus = monthlyStatus
        } else {
            // Prefer yearly status when only one status exists
            newStatus = yearlyStatus
        }
        if case SubscriptionStatus.verified(let originalTransactionID, _, _, let environment) = newStatus {
            do {
                if try await !performServerVerification(originalTransactionID: originalTransactionID, environment: environment) {
                    // Server verification failure, reset to empty
                    newStatus = .empty
                }
            } catch {
                // Ignore the errors that might occur due to server issues
            }
        }
        updateStatus(newStatus)
        return newStatus
    }

    nonisolated public func checkPurchaseUpdates() -> Task<Void, Error> {
        return .detached {
            for await verificationResult in Transaction.updates {
                switch verificationResult {
                case .unverified:
                    break
                case .verified(let transaction):
                    if transaction.productID != self.monthlySubscriptionId && transaction.productID != self.yearlySubscriptionId {
                        continue
                    }
                    await transaction.finish()
                    await self.updateStatus(.verified(originalTransactionID: transaction.originalID, productID: transaction.productID, expirationDate: transaction.expirationDate, environment: SubscriptionEnvironment(transaction: transaction)))
                }
            }
        }
    }

    private func updateStatus(_ status: SubscriptionStatus) {
        guard status != self.status else { return }

        let newTransactionInfo: CacheTransactionInfo?
        switch status {
        case .verified(let originalTransactionID, _, _, let environment):
            newTransactionInfo = CacheTransactionInfo(originalTransactionID: originalTransactionID, isSandbox: environment != .production)
        default:
            newTransactionInfo = nil
        }
        if newTransactionInfo?.isSandbox != transactionInfoCache?.isSandbox || newTransactionInfo?.originalTransactionID != transactionInfoCache?.originalTransactionID {
            transactionInfoCache = newTransactionInfo
            if let newTransactionInfo {
                userDefaults.setValue(try? JSONEncoder().encode(newTransactionInfo), forKey: cacheKey)
            } else {
                userDefaults.setValue(nil, forKey: cacheKey)
            }
        }
        self.status = status
        NotificationCenter.default.post(name: .subscriptionStatusChanged, object: self)
    }

    func fetchSubscriptionProducts() async throws -> [Plan] {
        let products = try await Product.products(for: [yearlySubscriptionId, monthlySubscriptionId])
        return products.compactMap { product in
            if product.id == yearlySubscriptionId {
                return Plan(product: product, name: CelestiaString("Yearly", comment: "Yearly subscription"))
            } else if product.id == monthlySubscriptionId {
                return Plan(product: product, name: CelestiaString("Monthly", comment: "Monthly subscription"))
            } else {
                return nil
            }
        }
    }

    func purchase(_ product: Product, scene: UIWindowScene) async throws -> SubscriptionStatus {
        #if os(visionOS)
        let result = try await product.purchase(confirmIn: scene)
        #else
        let result: Product.PurchaseResult
        if #available(iOS 17, *) {
            result = try await product.purchase(confirmIn: scene)
        } else {
            result = try await product.purchase()
        }
        #endif
        switch result {
        case .success(let verificationResult):
            switch verificationResult {
            case .unverified:
                break
            case .verified(let transaction):
                await transaction.finish()
                updateStatus(.verified(originalTransactionID: transaction.originalID, productID: transaction.productID, expirationDate: transaction.expirationDate, environment: SubscriptionEnvironment(transaction: transaction)))
            }
        case .userCancelled:
            break
        case .pending:
            updateStatus(.pending)
            break
        @unknown default:
            break
        }
        return status
    }

    private func performServerVerification(originalTransactionID: UInt64, environment: SubscriptionEnvironment) async throws -> Bool {
        return try await requestHandler.getSubscriptionValidity(originalTransactionID: originalTransactionID, sandbox: environment == .production)
    }

    private func subscriptionStatus(for entitlement: VerificationResult<Transaction>?) -> SubscriptionStatus {
        switch entitlement {
        case .unverified:
            return .empty
        case .verified(let transaction):
            if transaction.revocationDate != nil {
                return .revoked
            }
            if let expirationDate = transaction.expirationDate, expirationDate < Date() {
                return .expired
            }
            return .verified(originalTransactionID: transaction.originalID, productID: transaction.productID, expirationDate: transaction.expirationDate, environment: SubscriptionEnvironment(transaction: transaction))
        case .none:
            return .empty
        }
    }
}

extension SubscriptionManager.SubscriptionEnvironment {
    init(transaction: Transaction) {
        if #available(iOS 16, *) {
            switch transaction.environment {
            case .production:
                self = .production
                return
            case .sandbox:
                self = .sandbox
                return
            case .xcode:
                self = .xcode
                return
            default:
                break
            }
        }
        let hasSandboxReceipt = Bundle.main.appStoreReceiptURL?.path.contains("sandboxReceipt") ?? false
        if hasSandboxReceipt {
            self = .sandbox
        } else {
            self = .production
        }
    }
}
