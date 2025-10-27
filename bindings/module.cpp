#include <pybind11/chrono.h>
#include <pybind11/pybind11.h>
#include <pybind11/stl.h>

#include "matching_engine.hpp"
#include "order_book.hpp"

namespace py = pybind11;

PYBIND11_MODULE(lob_cpp, m) {
    m.doc() = "C++ limit order book simulator bindings";

    py::enum_<lob::Side>(m, "Side")
        .value("BUY", lob::Side::Buy)
        .value("SELL", lob::Side::Sell);

    py::enum_<lob::OrderType>(m, "OrderType")
        .value("LIMIT", lob::OrderType::Limit)
        .value("MARKET", lob::OrderType::Market);

    py::class_<lob::Order>(m, "Order")
        .def(py::init<>())
        .def_readwrite("id", &lob::Order::id)
        .def_readwrite("symbol", &lob::Order::symbol)
        .def_readwrite("side", &lob::Order::side)
        .def_readwrite("type", &lob::Order::type)
        .def_readwrite("price", &lob::Order::price)
        .def_readwrite("quantity", &lob::Order::quantity)
        .def_readwrite("timestamp", &lob::Order::timestamp);

    py::class_<lob::Trade>(m, "Trade")
        .def_readonly("resting_order", &lob::Trade::resting_order)
        .def_readonly("incoming_order", &lob::Trade::incoming_order)
        .def_readonly("price", &lob::Trade::price)
        .def_readonly("quantity", &lob::Trade::quantity)
        .def_readonly("timestamp", &lob::Trade::timestamp);

    py::class_<lob::OrderBook>(m, "OrderBook")
        .def(py::init<>())
        .def("add_order", &lob::OrderBook::add_order)
        .def("cancel_order", &lob::OrderBook::cancel_order)
        .def("modify_order", &lob::OrderBook::modify_order)
        .def("best_bid", &lob::OrderBook::best_bid)
        .def("best_ask", &lob::OrderBook::best_ask)
        .def("snapshot", &lob::OrderBook::snapshot);

    py::class_<lob::MatchResult>(m, "MatchResult")
        .def(py::init<>())
        .def_readwrite("trades", &lob::MatchResult::trades)
        .def_readwrite("residual", &lob::MatchResult::residual);

    py::class_<lob::MatchingEngine>(m, "MatchingEngine")
        .def(py::init<>())
        .def("process", &lob::MatchingEngine::process)
        .def("cancel", &lob::MatchingEngine::cancel)
        .def("modify", &lob::MatchingEngine::modify)
        .def("order_book", &lob::MatchingEngine::order_book, py::return_value_policy::reference_internal);
}
