/*
  Stockfish, a UCI chess playing engine derived from Glaurung 2.1
  Copyright (C) 2004-2025 The Stockfish developers (see AUTHORS file)
  Stockfish is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.
  Stockfish is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef NETWORK_H_INCLUDED
#define NETWORK_H_INCLUDED

#include <cstdint>
#include <functional>
#include <iostream>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <tuple>

#include "../memory.h"
#include "../types.h"
#include "nnue_accumulator.h"
#include "nnue_architecture.h"
#include "nnue_feature_transformer.h"
#include "nnue_misc.h"

namespace Stockfish {

class Position;

namespace Eval::NNUE {

using NetworkOutput = std::tuple<Value, Value>;

class Network {
   public:
    Network(EvalFile file) :
        evalFile(file) {}

    Network(const Network& other);
    Network(Network&& other) = default;

    Network& operator=(const Network& other);
    Network& operator=(Network&& other) = default;

    void load(const std::string& rootDirectory, std::string evalfilePath);
    bool save(const std::optional<std::string>& filename) const;

    NetworkOutput evaluate(const Position& pos, AccumulatorCaches::Cache* cache) const;

    void hint_common_access(const Position& pos, AccumulatorCaches::Cache* cache) const;

    void verify(std::string evalfilePath, const std::function<void(std::string_view)>&) const;
    NnueEvalTrace trace_evaluate(const Position& pos, AccumulatorCaches::Cache* cache) const;

   private:
    void load_user_net(const std::string&, const std::string&);

    void initialize();

    bool                       save(std::ostream&, const std::string&, const std::string&) const;
    std::optional<std::string> load(std::istream&);

    bool read_header(std::istream&, std::uint32_t*, std::string*) const;
    bool write_header(std::ostream&, std::uint32_t, const std::string&) const;

    bool read_parameters(std::istream&, std::string&) const;
    bool write_parameters(std::ostream&, const std::string&) const;

    // Input feature converter
    LargePagePtr<FeatureTransformer> featureTransformer;

    // Evaluation function
    AlignedPtr<NetworkArchitecture[]> network;

    EvalFile evalFile;

    // Hash value of evaluation function structure
    static constexpr std::uint32_t hash =
      FeatureTransformer::get_hash_value() ^ NetworkArchitecture::get_hash_value();

    friend struct AccumulatorCaches::Cache;
};

}  // namespace Stockfish::Eval::NNUE
}  // namespace Stockfish

#endif
