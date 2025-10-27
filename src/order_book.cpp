// Copyright (c) 2024
// SPDX-License-Identifier: Apache-2.0

#include "order_book.hpp"

#include <algorithm>
#include <stdexcept>

namespace lob {

namespace {
bool crosses(const Order& incoming, Price resting_price) {
    if (incoming.type == OrderType::Market) {
        return true;
    }
    if (incoming.side == Side::Buy) {
        return resting_price <= incoming.price;
    }
    return resting_price >= incoming.price;
}
}  // namespace

MatchResult OrderBook::add_order(const Order& order) {
    if (order.quantity == 0) {
        return {};
    }

    MatchResult result = match_against_resting(order);
    if (result.residual.has_value()) {
        Order resting = *result.residual;
        if (resting.type == OrderType::Market || resting.quantity == 0) {
            result.residual.reset();
            return result;
        }

        PriceLevel& level = get_or_create_level(resting.side, resting.price);
        auto it = level.orders.emplace(level.orders.end(), resting);
        level.total_quantity += resting.quantity;
        order_lookup_[resting.id] = Locator{resting.side, resting.price, &level, it};
        result.residual = *it;
    }
    return result;
}

bool OrderBook::cancel_order(OrderId id) {
    auto locator_it = order_lookup_.find(id);
    if (locator_it == order_lookup_.end()) {
        return false;
    }

    auto& locator = locator_it->second;
    PriceLevel* level = locator.level;
    if (level == nullptr) {
        return false;
    }

    level->total_quantity -= locator.iterator->quantity;
    level->orders.erase(locator.iterator);
    cleanup_level(locator.side, locator.price);
    order_lookup_.erase(locator_it);
    return true;
}

bool OrderBook::modify_order(OrderId id, Quantity new_quantity, std::optional<Price> new_price) {
    auto locator_it = order_lookup_.find(id);
    if (locator_it == order_lookup_.end()) {
        return false;
    }

    if (new_quantity == 0) {
        return cancel_order(id);
    }

    auto locator = locator_it->second;
    Order& existing = *locator.iterator;
    if (!new_price.has_value() || new_price.value() == existing.price) {
        locator.level->total_quantity -= existing.quantity;
        existing.quantity = new_quantity;
        locator.level->total_quantity += existing.quantity;
        return true;
    }

    Order updated = existing;
    updated.price = *new_price;
    updated.quantity = new_quantity;
    updated.timestamp = Clock::now();

    cancel_order(id);

    MatchResult result = add_order(updated);
    return true;
}

std::optional<Price> OrderBook::best_bid() const {
    if (bids_.empty()) {
        return std::nullopt;
    }
    return bids_.begin()->first;
}

std::optional<Price> OrderBook::best_ask() const {
    if (asks_.empty()) {
        return std::nullopt;
    }
    return asks_.begin()->first;
}

BookSnapshot OrderBook::snapshot(std::size_t depth) const {
    BookSnapshot snap{};
    snap.best_bid = best_bid();
    snap.best_ask = best_ask();

    std::size_t count = 0;
    for (auto it = bids_.begin(); it != bids_.end() && count < depth; ++it, ++count) {
        snap.bids.push_back(BookLevel{it->first, it->second.total_quantity, it->second.orders.size()});
    }

    count = 0;
    for (auto it = asks_.begin(); it != asks_.end() && count < depth; ++it, ++count) {
        snap.asks.push_back(BookLevel{it->first, it->second.total_quantity, it->second.orders.size()});
    }

    return snap;
}

MatchResult OrderBook::match_against_resting(Order order) {
    MatchResult result;

    auto process_side = [&](auto& contra_side) {
        while (order.quantity > 0 && !contra_side.empty()) {
            auto level_it = contra_side.begin();
            Price level_price = level_it->first;
            if (!crosses(order, level_price)) {
                break;
            }

            PriceLevel& level = level_it->second;
            auto resting_it = level.orders.begin();
            while (resting_it != level.orders.end() && order.quantity > 0) {
                Order& resting = *resting_it;

                Quantity traded = std::min(order.quantity, resting.quantity);
                order.quantity -= traded;
                resting.quantity -= traded;
                level.total_quantity -= traded;

                result.trades.push_back(Trade{
                    .resting_order = resting.id,
                    .incoming_order = order.id,
                    .price = resting.price,
                    .quantity = traded,
                    .timestamp = Clock::now(),
                });

                if (resting.quantity == 0) {
                    auto locator_it = order_lookup_.find(resting.id);
                    if (locator_it != order_lookup_.end()) {
                        order_lookup_.erase(locator_it);
                    }
                    resting_it = level.orders.erase(resting_it);
                } else {
                    ++resting_it;
                }
            }

            if (level.orders.empty()) {
                contra_side.erase(level_it);
            }
        }
    };

    if (order.side == Side::Buy) {
        process_side(asks_);
    } else {
        process_side(bids_);
    }

    if (order.quantity > 0 && order.type == OrderType::Limit) {
        result.residual = order;
    }

    return result;
}

OrderBook::PriceLevel& OrderBook::get_or_create_level(Side side, Price price) {
    if (side == Side::Buy) {
        auto [it, inserted] = bids_.try_emplace(price);
        return it->second;
    }

    auto [it, inserted] = asks_.try_emplace(price);
    return it->second;
}

void OrderBook::cleanup_level(Side side, Price price) {
    if (side == Side::Buy) {
        auto it = bids_.find(price);
        if (it != bids_.end() && it->second.orders.empty()) {
            bids_.erase(it);
        }
        return;
    }
    auto it = asks_.find(price);
    if (it != asks_.end() && it->second.orders.empty()) {
        asks_.erase(it);
    }
}

}  // namespace lob
