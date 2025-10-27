// Copyright (c) 2024
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "order_book.hpp"

#include <optional>
#include <vector>

namespace lob::analytics {

[[nodiscard]] std::optional<double> spread(const OrderBook& book);
[[nodiscard]] std::optional<double> mid_price(const OrderBook& book);
[[nodiscard]] Quantity depth(const OrderBook& book, Side side, std::size_t levels = 5);
[[nodiscard]] std::optional<double> imbalance(const OrderBook& book, std::size_t levels = 5);
[[nodiscard]] double realized_volatility(const std::vector<double>& mid_prices);

}  // namespace lob::analytics
