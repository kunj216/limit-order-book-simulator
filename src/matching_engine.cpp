// Copyright (c) 2024
// SPDX-License-Identifier: Apache-2.0

#include "matching_engine.hpp"

namespace lob {

MatchResult MatchingEngine::process(const Order& order) {
    std::scoped_lock lock(mutex_);
    MatchResult result = book_.add_order(order);
    trade_log_.insert(trade_log_.end(), result.trades.begin(), result.trades.end());
    ++processed_events_;
    return result;
}

bool MatchingEngine::cancel(OrderId id) {
    std::scoped_lock lock(mutex_);
    bool success = book_.cancel_order(id);
    processed_events_ += success ? 1 : 0;
    return success;
}

bool MatchingEngine::modify(OrderId id, Quantity new_quantity, std::optional<Price> new_price) {
    std::scoped_lock lock(mutex_);
    bool success = book_.modify_order(id, new_quantity, new_price);
    processed_events_ += success ? 1 : 0;
    return success;
}

MatchResult MatchingEngine::handle(const OrderCommand& command) {
    switch (command.type) {
        case EventType::New:
            return process(command.order);
        case EventType::Cancel:
            cancel(command.order.id);
            return {};
        case EventType::Modify:
            modify(command.order.id,
                   command.new_quantity.value_or(command.order.quantity),
                   command.new_price);
            return {};
    }
    return {};
}

}  // namespace lob
