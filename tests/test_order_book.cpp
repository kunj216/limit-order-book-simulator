#include "order_book.hpp"

#include "catch_amalgamated.hpp"

using namespace lob;

TEST_CASE("OrderBook maintains best bid/ask") {
    OrderBook book;

    Order bid{
        .id = 1,
        .symbol = "ABC",
        .side = Side::Buy,
        .type = OrderType::Limit,
        .price = 100000,
        .quantity = 200,
        .timestamp = Clock::now(),
    };

    Order ask{
        .id = 2,
        .symbol = "ABC",
        .side = Side::Sell,
        .type = OrderType::Limit,
        .price = 100500,
        .quantity = 200,
        .timestamp = Clock::now(),
    };

    book.add_order(bid);
    book.add_order(ask);

    REQUIRE(book.best_bid().has_value());
    REQUIRE(book.best_ask().has_value());
    CHECK(book.best_bid().value() == 100000);
    CHECK(book.best_ask().value() == 100500);
}

TEST_CASE("Limit orders match and generate trades") {
    OrderBook book;

    Order resting{
        .id = 10,
        .symbol = "XYZ",
        .side = Side::Sell,
        .type = OrderType::Limit,
        .price = 101000,
        .quantity = 300,
        .timestamp = Clock::now(),
    };

    book.add_order(resting);

    Order incoming{
        .id = 11,
        .symbol = "XYZ",
        .side = Side::Buy,
        .type = OrderType::Limit,
        .price = 101500,
        .quantity = 200,
        .timestamp = Clock::now(),
    };

    MatchResult result = book.add_order(incoming);
    REQUIRE(result.trades.size() == 1);
    CHECK(result.trades.front().quantity == 200);
    CHECK(result.trades.front().price == 101000);
    CHECK(book.size() == 1);
    CHECK(book.best_ask().has_value());
    CHECK(book.best_ask().value() == 101000);
}

TEST_CASE("Cancel removes orders") {
    OrderBook book;

    Order order{
        .id = 20,
        .symbol = "XYZ",
        .side = Side::Buy,
        .type = OrderType::Limit,
        .price = 99000,
        .quantity = 150,
        .timestamp = Clock::now(),
    };

    book.add_order(order);
    REQUIRE(book.size() == 1);
    REQUIRE(book.cancel_order(20));
    CHECK(book.size() == 0);
    CHECK_FALSE(book.best_bid().has_value());
}
