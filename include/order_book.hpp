// Copyright (c) 2024
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "order.hpp"

#include <list>
#include <map>
#include <optional>
#include <unordered_map>
#include <vector>

namespace lob {

struct MatchResult {
    std::vector<Trade> trades;
    std::optional<Order> residual;
};

class OrderBook {
  public:
    MatchResult add_order(const Order& order);
    bool cancel_order(OrderId id);
    bool modify_order(OrderId id, Quantity new_quantity, std::optional<Price> new_price = std::nullopt);

    [[nodiscard]] std::optional<Price> best_bid() const;
    [[nodiscard]] std::optional<Price> best_ask() const;
    [[nodiscard]] BookSnapshot snapshot(std::size_t depth = 5) const;

    [[nodiscard]] std::size_t size() const noexcept { return order_lookup_.size(); }

  private:
    struct PriceLevel {
        std::list<Order> orders;
        Quantity total_quantity{0};
    };

    struct BidComparator {
        bool operator()(Price lhs, Price rhs) const { return lhs > rhs; }
    };

    using BidMap = std::map<Price, PriceLevel, BidComparator>;
    using AskMap = std::map<Price, PriceLevel, std::less<Price>>;

    struct Locator {
        Side side{Side::Buy};
        Price price{};
        PriceLevel* level{nullptr};
        std::list<Order>::iterator iterator;
    };

    BidMap bids_;
    AskMap asks_;
    std::unordered_map<OrderId, Locator> order_lookup_;

    MatchResult match_against_resting(Order order);
    PriceLevel& get_or_create_level(Side side, Price price);
    void cleanup_level(Side side, Price price);
};

}  // namespace lob
