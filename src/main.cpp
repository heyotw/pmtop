// hny.sh likes to code //
// SPDX-License-Identifier: Apache-2.0

#include "btop.hpp"

#include <string_view>
#include <vector>

auto main(int argc, const char* argv[]) -> int {
	std::vector<std::string_view> args;
	if (argc > 1) {
		args.reserve(argc - 1);
		for (int i = 1; i < argc; ++i) {
			args.emplace_back(argv[i]);
		}
	}
	return btop_main(args);
}
