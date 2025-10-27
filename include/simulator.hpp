// Copyright (c) 2024
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "matching_engine.hpp"

#include <atomic>
#include <cstddef>
#include <filesystem>
#include <optional>
#include <string>
#include <thread>
#include <vector>

namespace lob {

struct SimulationConfig {
    std::string input_path;
    std::size_t threads{1};
    bool simulate_latency{false};
    std::chrono::microseconds latency_per_event{0};
};

struct SimulationMetrics {
    std::size_t events_processed{0};
    std::size_t trades_executed{0};
    double elapsed_seconds{0.0};
    double throughput{0.0};
};

class Simulator {
  public:
    explicit Simulator(MatchingEngine& engine);
    void load_events_from_csv(const std::string& path);
    SimulationMetrics run(const SimulationConfig& config);

    [[nodiscard]] const std::vector<OrderCommand>& events() const noexcept { return events_; }

  private:
    MatchingEngine& engine_;
    std::vector<OrderCommand> events_;
};

}  // namespace lob
