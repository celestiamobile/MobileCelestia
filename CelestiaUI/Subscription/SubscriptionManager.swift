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
        case verified(originalTransactionID: UInt64, productID: String, cycle: Plan.Cycle, expirationDate: Date?, environment: SubscriptionEnvironment)
        case expired
        case revoked
    }

    public enum SubscriptionEnvironment: Sendable {
        case production
        case sandbox
        case xcode
    }

    public struct Plan {
        public enum Cycle: Int, Hashable, Sendable {
            case yearly = 2
            case monthly = 1
            case weekly = 0

            init?(id: String) {
                switch id {
                case "space.celestia.mobilecelestia.plus.weekly":
                    self = .weekly
                case "space.celestia.mobilecelestia.plus.monthly":
                    self = .monthly
                case "space.celestia.mobilecelestia.plus.yearly":
                    self = .yearly
                default:
                    return nil
                }
            }

            var name: String {
                switch self {
                case .yearly:
                    CelestiaString("Yearly", comment: "Yearly subscription")
                case .monthly:
                    CelestiaString("Monthly", comment: "Monthly subscription")
                case .weekly:
                    CelestiaString("Weekly", comment: "Weekly subscription")
                }
            }

            var id: String {
                switch self {
                case .yearly:
                    "space.celestia.mobilecelestia.plus.yearly"
                case .monthly:
                    "space.celestia.mobilecelestia.plus.monthly"
                case .weekly:
                    "space.celestia.mobilecelestia.plus.weekly"
                }
            }
        }

        let product: Product
        let name: String
        let formattedPriceLine1: AttributedString
        let formattedPriceLine2: AttributedString?
        let cycle: Cycle
        let offersFreeTrial: Bool

        init(product: Product, subscription: Product.SubscriptionInfo, cycle: Cycle, name: String, stringProvider: StringProvider) async {
            self.product = product
            self.cycle = cycle
            self.name = name
            self.formattedPriceLine1 = await stringProvider.formattedPriceLine1(for: product, subscription: subscription)
            self.formattedPriceLine2 = await stringProvider.formattedPriceLine2(for: product, subscription: subscription)
            if let introductoryOffer = subscription.introductoryOffer, await subscription.isEligibleForIntroOffer {
                offersFreeTrial = introductoryOffer.price == 0
            } else {
                offersFreeTrial = false
            }
        }
    }

    private(set) var status: SubscriptionStatus = .unknown
    private let userDefaults: UserDefaults
    private let requestHandler: RequestHandler

    private var transactionInfoCache: CacheTransactionInfo?

    private struct CacheTransactionInfo: Codable {
        let originalTransactionID: UInt64
        let isSandbox: Bool
    }

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
        let weeklyStatus = subscriptionStatus(for: await Transaction.currentEntitlement(for: Plan.Cycle.weekly.id), cycle: .weekly)
        let monthlyStatus = subscriptionStatus(for: await Transaction.currentEntitlement(for: Plan.Cycle.monthly.id), cycle: .monthly)
        let yearlyStatus = subscriptionStatus(for: await Transaction.currentEntitlement(for: Plan.Cycle.yearly.id), cycle: .yearly)

        var newStatus: SubscriptionStatus = yearlyStatus // Fallback to yearly status
        var expiration: Date?
        for status in [yearlyStatus, monthlyStatus, weeklyStatus] {
            if case SubscriptionStatus.verified(_, _, _, let newExpiration, _) = status {
                if let newExpiration {
                    // Prefer status with latest expiration date
                    if let currentExpiration = expiration {
                        if newExpiration > currentExpiration {
                            newStatus = status
                            expiration = newExpiration
                        }
                    } else {
                        newStatus = status
                        expiration = newExpiration
                    }
                }
                else {
                    // If no expiration date is given, set it to the last verified status
                    if expiration == nil {
                        newStatus = status
                    }
                }
            }
        }

        if case SubscriptionStatus.verified(let originalTransactionID, _, _, _, let environment) = newStatus {
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
                    guard let cycle = Plan.Cycle(id: transaction.productID) else {
                        continue
                    }
                    await transaction.finish()
                    await self.updateStatus(.verified(originalTransactionID: transaction.originalID, productID: transaction.productID, cycle: cycle, expirationDate: transaction.expirationDate, environment: SubscriptionEnvironment(transaction: transaction)))
                }
            }
        }
    }

    private func updateStatus(_ status: SubscriptionStatus) {
        guard status != self.status else { return }

        let newTransactionInfo: CacheTransactionInfo?
        switch status {
        case .verified(let originalTransactionID, _, _, _, let environment):
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

    func fetchSubscriptionProducts(stringProvider: StringProvider) async throws -> [Plan] {
        let products = try await Product.products(for: [Plan.Cycle.yearly.id, Plan.Cycle.monthly.id, Plan.Cycle.weekly.id])
        var yearlyPlan: Plan?
        var monthlyPlan: Plan?
        var weeklyPlan: Plan?
        for product in products {
            guard let subscription = product.subscription else { continue }
            guard let cycle = Plan.Cycle(id: product.id) else { continue }

            let plan = await Plan(product: product, subscription: subscription, cycle: cycle, name: cycle.name, stringProvider: stringProvider)
            switch cycle {
            case .yearly:
                yearlyPlan = plan
            case .monthly:
                monthlyPlan = plan
            case .weekly:
                weeklyPlan = plan
            }
        }
        return [yearlyPlan, monthlyPlan, weeklyPlan].compactMap { $0 }
    }

    func purchase(_ product: Product, cycle: Plan.Cycle, scene: UIWindowScene) async throws -> SubscriptionStatus {
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
                updateStatus(.verified(originalTransactionID: transaction.originalID, productID: transaction.productID, cycle: cycle, expirationDate: transaction.expirationDate, environment: SubscriptionEnvironment(transaction: transaction)))
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
        return try await requestHandler.getSubscriptionValidity(originalTransactionID: originalTransactionID, sandbox: environment != .production)
    }

    private func subscriptionStatus(for entitlement: VerificationResult<Transaction>?, cycle: Plan.Cycle) -> SubscriptionStatus {
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
            return .verified(originalTransactionID: transaction.originalID, productID: transaction.productID, cycle: cycle, expirationDate: transaction.expirationDate, environment: SubscriptionEnvironment(transaction: transaction))
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
