CXX := g++
CXXFLAGS := -std=c++11 -Wall -Wextra -O2 -I../src

SRC_DIR := ../src
BUILD_DIR := build

COMMON_SRCS := $(wildcard $(SRC_DIR)/*.cpp)
COMMON_OBJS := $(patsubst $(SRC_DIR)/%.cpp,$(BUILD_DIR)/src_%.o,$(COMMON_SRCS))

TEST_SRCS := test_ldpcdec_ms.cpp test_ldpcdec_sp.cpp
TARGETS := $(TEST_SRCS:.cpp=)

.PHONY: all clean

all: $(TARGETS)

test_ldpcdec_ms: $(BUILD_DIR)/test_ldpcdec_ms.o $(COMMON_OBJS)
	$(CXX) $(CXXFLAGS) $^ -o $@

test_ldpcdec_sp: $(BUILD_DIR)/test_ldpcdec_sp.o $(COMMON_OBJS)
	$(CXX) $(CXXFLAGS) $^ -o $@

$(BUILD_DIR)/%.o: %.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/src_%.o: $(SRC_DIR)/%.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR) $(TARGETS)
