// Copyright (c) 2024
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <chrono>
#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace lob {

using OrderId = std::uint64_t;
using Quantity = std::uint64_t;
using Price = std::int64_t;
using Clock = std::chrono::high_resolution_clock;
using Timestamp = Clock::time_point;

enum class Side { Buy, Sell };

inline std::string to_string(Side side) {
    return side == Side::Buy ? "BUY" : "SELL";
}

enum class OrderType { Limit, Market };

struct Order {
    OrderId id{};
    std::string symbol{"UNK"};
    Side side{Side::Buy};
    OrderType type{OrderType::Limit};
    Price price{};
    Quantity quantity{};
    Timestamp timestamp{Clock::now()};
};

struct Trade {
    OrderId resting_order{};
    OrderId incoming_order{};
    Price price{};
    Quantity quantity{};
    Timestamp timestamp{Clock::now()};
};

struct BookLevel {
    Price price{};
    Quantity quantity{};
    std::size_t order_count{};
};

struct BookSnapshot {
    std::vector<BookLevel> bids;
    std::vector<BookLevel> asks;
    std::optional<Price> best_bid;
    std::optional<Price> best_ask;
};

}  // namespace lob
