#ifdef LOB_ENABLE_GOOGLE_BENCHMARK

#include <benchmark/benchmark.h>

#include "order_book.hpp"

static void BM_AddLimitOrders(benchmark::State& state) {
    for (auto _ : state) {
        lob::OrderBook book;
        for (std::uint64_t i = 0; i < 1000; ++i) {
            lob::Order order{
                .id = i,
                .symbol = "BENCH",
                .side = (i % 2 == 0) ? lob::Side::Buy : lob::Side::Sell,
                .type = lob::OrderType::Limit,
                .price = static_cast<lob::Price>(100000 + static_cast<int>(i % 50) * ((i % 2 == 0) ? -1 : 1)),
                .quantity = 100,
                .timestamp = lob::Clock::now(),
            };
            book.add_order(order);
        }
        benchmark::ClobberMemory();
    }
}

BENCHMARK(BM_AddLimitOrders);

BENCHMARK_MAIN();

#endif
