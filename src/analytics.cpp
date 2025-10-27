// Copyright (c) 2024
// SPDX-License-Identifier: Apache-2.0

#include "analytics.hpp"

#include <cmath>

namespace lob::analytics {

std::optional<double> spread(const OrderBook& book) {
    auto bid = book.best_bid();
    auto ask = book.best_ask();
    if (!bid.has_value() || !ask.has_value()) {
        return std::nullopt;
    }
    return static_cast<double>(ask.value() - bid.value());
}

std::optional<double> mid_price(const OrderBook& book) {
    auto bid = book.best_bid();
    auto ask = book.best_ask();
    if (!bid.has_value() || !ask.has_value()) {
        return std::nullopt;
    }
    return (static_cast<double>(bid.value()) + static_cast<double>(ask.value())) / 2.0;
}

Quantity depth(const OrderBook& book, Side side, std::size_t levels) {
    BookSnapshot snap = book.snapshot(levels);
    const auto& rows = side == Side::Buy ? snap.bids : snap.asks;
    Quantity total = 0;
    for (const auto& level : rows) {
        total += level.quantity;
    }
    return total;
}

std::optional<double> imbalance(const OrderBook& book, std::size_t levels) {
    Quantity bid_depth = depth(book, Side::Buy, levels);
    Quantity ask_depth = depth(book, Side::Sell, levels);
    if (bid_depth == 0 && ask_depth == 0) {
        return std::nullopt;
    }
    double total = static_cast<double>(bid_depth + ask_depth);
    return static_cast<double>(bid_depth) / total;
}

double realized_volatility(const std::vector<double>& mid_prices) {
    if (mid_prices.size() < 2) {
        return 0.0;
    }
    double sum_sq = 0.0;
    for (std::size_t i = 1; i < mid_prices.size(); ++i) {
        double ret = std::log(mid_prices[i] / mid_prices[i - 1]);
        sum_sq += ret * ret;
    }
    return std::sqrt(sum_sq);
}

}  // namespace lob::analytics
