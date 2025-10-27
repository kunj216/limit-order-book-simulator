// Copyright (c) 2024
// SPDX-License-Identifier: Apache-2.0

#include "simulator.hpp"

#include <chrono>
#include <fstream>
#include <sstream>
#include <stdexcept>
#include <thread>

namespace lob {

namespace {
Side parse_side(const std::string& token) {
    if (token == "BUY" || token == "B") {
        return Side::Buy;
    }
    if (token == "SELL" || token == "S") {
        return Side::Sell;
    }
    throw std::runtime_error("invalid side token: " + token);
}

EventType parse_event_type(const std::string& token) {
    if (token == "NEW") {
        return EventType::New;
    }
    if (token == "CANCEL") {
        return EventType::Cancel;
    }
    if (token == "MODIFY") {
        return EventType::Modify;
    }
    throw std::runtime_error("invalid event type: " + token);
}
}  // namespace

Simulator::Simulator(MatchingEngine& engine) : engine_(engine) {}

void Simulator::load_events_from_csv(const std::string& path) {
    if (!std::filesystem::exists(path)) {
        throw std::runtime_error("event file not found: " + path);
    }

    events_.clear();
    std::ifstream input(path);
    std::string line;

    while (std::getline(input, line)) {
        if (line.empty() || line[0] == '#') {
            continue;
        }

        std::stringstream ss(line);
        std::string field;
        std::vector<std::string> fields;
        while (std::getline(ss, field, ',')) {
            fields.push_back(field);
        }

        if (fields.size() < 3) {
            continue;
        }

        OrderCommand command{};
        EventType type = parse_event_type(fields[1]);
        command.type = type;

        Order order{};
        order.id = static_cast<OrderId>(std::stoull(fields[2]));
        order.timestamp = Timestamp(std::chrono::nanoseconds(std::stoll(fields[0])));

        switch (type) {
            case EventType::New: {
                if (fields.size() < 7) {
                    throw std::runtime_error("NEW event missing fields");
                }
                order.side = parse_side(fields[3]);
                order.type = fields[4] == "MARKET" ? OrderType::Market : OrderType::Limit;
                order.price = static_cast<Price>(std::stoll(fields[5]));
                order.quantity = static_cast<Quantity>(std::stoull(fields[6]));
                command.order = order;
                break;
            }
            case EventType::Cancel:
                command.order = order;
                break;
            case EventType::Modify: {
                if (fields.size() < 6) {
                    throw std::runtime_error("MODIFY event missing fields");
                }
                command.order = order;
                command.new_quantity = static_cast<Quantity>(std::stoull(fields[3]));
                if (!fields[4].empty()) {
                    command.new_price = static_cast<Price>(std::stoll(fields[4]));
                }
                std::string side_token = fields[5];
                if (!side_token.empty()) {
                    command.order.side = parse_side(side_token);
                }
                break;
            }
        }

        events_.push_back(command);
    }
}

SimulationMetrics Simulator::run(const SimulationConfig& config) {
    if (!config.input_path.empty()) {
        load_events_from_csv(config.input_path);
    }

    SimulationMetrics metrics{};
    if (events_.empty()) {
        return metrics;
    }

    std::atomic<std::size_t> index{0};
    std::atomic<std::size_t> trade_counter{0};

    std::size_t thread_count = std::max<std::size_t>(1, config.threads);
    auto start = Clock::now();

    auto worker = [&]() {
        while (true) {
            std::size_t i = index.fetch_add(1);
            if (i >= events_.size()) {
                break;
            }
            const auto& command = events_[i];
            MatchResult result = engine_.handle(command);
            trade_counter.fetch_add(result.trades.size(), std::memory_order_relaxed);

            if (config.simulate_latency && config.latency_per_event.count() > 0) {
                std::this_thread::sleep_for(config.latency_per_event);
            }
        }
    };

    std::vector<std::thread> workers;
    workers.reserve(thread_count);
    for (std::size_t i = 0; i < thread_count; ++i) {
        workers.emplace_back(worker);
    }
    for (auto& worker_thread : workers) {
        worker_thread.join();
    }

    auto end = Clock::now();
    metrics.events_processed = events_.size();
    metrics.trades_executed = trade_counter.load();
    metrics.elapsed_seconds = std::chrono::duration<double>(end - start).count();
    if (metrics.elapsed_seconds > 0.0) {
        metrics.throughput = static_cast<double>(metrics.events_processed) / metrics.elapsed_seconds;
    }
    return metrics;
}

}  // namespace lob
