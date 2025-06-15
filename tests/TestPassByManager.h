#pragma once

#include "PassBy/PassBy.h"

namespace PassBy {

// テスト用継承クラス
class TestPassByManager : public PassByManager {
public:
    // シングルトンリセット機能
    static void resetForTesting() {
        std::lock_guard<std::mutex> lock(s_mutex);
        s_instance.reset();
    }
};

} // namespace PassBy