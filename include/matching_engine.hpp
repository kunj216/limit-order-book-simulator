// Copyright (c) 2024
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "order_book.hpp"

#include <mutex>
#include <optional>
#include <vector>

namespace lob {

enum class EventType { New, Cancel, Modify };

struct OrderCommand {
    EventType type{EventType::New};
    Order order{};
    std::optional<Quantity> new_quantity{};
    std::optional<Price> new_price{};
};

class MatchingEngine {
  public:
    MatchResult process(const Order& order);
    bool cancel(OrderId id);
    bool modify(OrderId id, Quantity new_quantity, std::optional<Price> new_price = std::nullopt);

    MatchResult handle(const OrderCommand& command);

    [[nodiscard]] const OrderBook& order_book() const noexcept { return book_; }
    [[nodiscard]] const std::vector<Trade>& trades() const noexcept { return trade_log_; }
    [[nodiscard]] std::size_t processed_events() const noexcept { return processed_events_; }

  private:
    OrderBook book_;
    std::vector<Trade> trade_log_;
    std::size_t processed_events_{0};
    std::mutex mutex_;
};

}  // namespace lob
