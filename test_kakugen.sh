#!/bin/bash

# テスト用の簡易フレームワーク
assert_eq() {
  local expected="$1"
  local actual="$2"
  local msg="$3"
  if [ "$expected" = "$actual" ]; then
    echo "✅ PASS: $msg"
  else
    echo "❌ FAIL: $msg"
    echo "  Expected: '$expected'"
    echo "  Actual  : '$actual'"
    exit 1
  fi
}

echo "Running tests..."

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

cat << 'QUOTE' > "$TEST_DIR/test1.txt"
Quote A
%
Quote B
Line 2
%
Quote C
QUOTE

cat << 'QUOTE' > "$TEST_DIR/test2.txt"
Quote D
%
Quote E
QUOTE

# 1件取得
actual=$(./kakugen.sh -n 1 -f "$TEST_DIR/test1.txt")
if [[ "$actual" == "Quote A" || "$actual" == "Quote B"$'\n'"Line 2" || "$actual" == "Quote C" ]]; then
    echo "✅ PASS: Single quote extraction from specified file"
else
    echo "❌ FAIL: Single quote extraction from specified file"
    echo "  Actual: '$actual'"
    exit 1
fi

# 複数ファイルからの取得（出典元が追加されること）
actual_multi=$(./kakugen.sh -n 1 -f "$TEST_DIR/test1.txt","$TEST_DIR/test2.txt")
if [[ "$actual_multi" == *"Quote "* && "$actual_multi" == *"-- test"* ]]; then
    echo "✅ PASS: Multiple files append source filename"
else
    echo "❌ FAIL: Multiple files append source filename"
    echo "  Actual: '$actual_multi'"
    exit 1
fi

# 複数件（全件）取得
actual_lines=$(./kakugen.sh -n 3 -f "$TEST_DIR/test1.txt" | wc -l | tr -d ' ')
assert_eq "4" "$actual_lines" "Extract multiple quotes with blank line separator"

# 存在しないファイル
actual_empty=$(./kakugen.sh -n 1 -f "$TEST_DIR/not_exist.txt")
assert_eq "" "$actual_empty" "Handle non-existent file gracefully"

# ~/.kakugenrc （設定ファイル）のパーステスト
cat << 'CONFIG' > "$TEST_DIR/test_rc"
# comment

$TEST_DIR/test1.txt
CONFIG

export TEST_DIR
actual_rc=$(./kakugen.sh -n 1 -c "$TEST_DIR/test_rc")
if [[ "$actual_rc" == "Quote A" || "$actual_rc" == "Quote B"$'\n'"Line 2" || "$actual_rc" == "Quote C" ]]; then
    echo "✅ PASS: Read config file and expand variables"
else
    echo "❌ FAIL: Read config file and expand variables"
    echo "  Actual: '$actual_rc'"
    exit 1
fi

# 設定ファイルでタイトル付きのパーステスト
cat << 'CONFIG_TITLE' > "$TEST_DIR/test_rc_title"
$TEST_DIR/test1.txt=Custom Title 1
$TEST_DIR/test2.txt=Custom Title 2
CONFIG_TITLE

actual_rc_title=$(./kakugen.sh -n 1 -c "$TEST_DIR/test_rc_title" -s "Quote A")
if [[ "$actual_rc_title" == *"-- Custom Title 1" ]]; then
    echo "✅ PASS: Read config file with custom titles"
else
    echo "❌ FAIL: Read config file with custom titles"
    echo "  Actual: '$actual_rc_title'"
    exit 1
fi

# 検索機能 (-s) のテスト
actual_search=$(./kakugen.sh -n 1 -f "$TEST_DIR/test1.txt" -s "Line 2")
assert_eq "Quote B"$'\n'"Line 2" "$actual_search" "Search and extract specific quote"

echo "🎉 All tests passed!"
