// Copyright (c) 2024
// SPDX-License-Identifier: Apache-2.0

#include "analytics.hpp"
#include "matching_engine.hpp"
#include "simulator.hpp"

#include <iomanip>
#include <iostream>
#include <string>
#include <thread>

namespace {

void print_usage() {
    std::cout << "Usage: lob_simulator --events <path> [--threads <n>] [--latency-us <n>]\n";
}

}  // namespace

int main(int argc, char** argv) {
    lob::SimulationConfig config{};
    config.threads = std::max<std::size_t>(1, std::thread::hardware_concurrency() / 2);

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--events" && i + 1 < argc) {
            config.input_path = argv[++i];
        } else if (arg == "--threads" && i + 1 < argc) {
            config.threads = std::stoull(argv[++i]);
        } else if (arg == "--latency-us" && i + 1 < argc) {
            config.simulate_latency = true;
            config.latency_per_event = std::chrono::microseconds(std::stoll(argv[++i]));
        } else if (arg == "--help") {
            print_usage();
            return 0;
        } else {
            std::cerr << "Unknown argument: " << arg << "\n";
            print_usage();
            return 1;
        }
    }

    if (config.input_path.empty()) {
        print_usage();
        return 1;
    }

    lob::MatchingEngine engine;
    lob::Simulator simulator(engine);

    try {
        lob::SimulationMetrics metrics = simulator.run(config);
        std::cout << "[INFO] Processed " << metrics.events_processed << " events in "
                  << std::fixed << std::setprecision(3) << metrics.elapsed_seconds << " seconds\n";
        std::cout << "[INFO] Throughput: " << static_cast<std::size_t>(metrics.throughput)
                  << " events/sec | Trades executed: " << metrics.trades_executed << "\n";

        auto spread = lob::analytics::spread(engine.order_book());
        auto mid = lob::analytics::mid_price(engine.order_book());
        auto imbalance = lob::analytics::imbalance(engine.order_book());

        std::cout << "[BOOK] Size: " << engine.order_book().size();
        if (spread.has_value()) {
            std::cout << " | Spread: " << spread.value();
        }
        if (mid.has_value()) {
            std::cout << " | Mid: " << mid.value();
        }
        if (imbalance.has_value()) {
            std::cout << " | Imbalance: " << imbalance.value();
        }
        std::cout << "\n";

        auto snapshot = engine.order_book().snapshot(5);
        if (!snapshot.bids.empty() || !snapshot.asks.empty()) {
            std::cout << "Top of book (5 levels):\n";
            std::cout << "  Bids:\n";
            for (const auto& level : snapshot.bids) {
                std::cout << "    " << level.price << " x " << level.quantity << " (" << level.order_count << ")\n";
            }
            std::cout << "  Asks:\n";
            for (const auto& level : snapshot.asks) {
                std::cout << "    " << level.price << " x " << level.quantity << " (" << level.order_count << ")\n";
            }
        }
    } catch (const std::exception& ex) {
        std::cerr << "[ERROR] " << ex.what() << "\n";
        return 2;
    }

    return 0;
}
