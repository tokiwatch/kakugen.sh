#!/bin/bash

# デフォルト設定
NUM_CARDS=1
SERIES="sample"
LANG="ja"
DATA_DIR="$HOME/.config/kakugen"

# 引数のパース
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--number) NUM_CARDS="$2"; shift ;;
        -s|--series) SERIES="$2"; shift ;;
        -l|--lang) LANG="$2"; shift ;;
        -d|--dir) DATA_DIR="$2"; shift ;;
        -h|--help)
            echo "Usage: kakugen [-n number] [-s series] [-l lang] [-d dir]"
            echo "Options:"
            echo "  -n, --number <int>    表示する格言の個数 (デフォルト: 1)"
            echo "  -s, --series <string> 格言のシリーズ名 (デフォルト: sample)"
            echo "  -l, --lang <string>   言語 (デフォルト: ja)"
            echo "  -d, --dir <string>    データファイルのディレクトリ (デフォルト: ~/.config/kakugen)"
            exit 0
            ;;
        *)
            echo "Unknown parameter passed: $1" >&2
            exit 1
            ;;
    esac
    shift
done

# ~/.config/kakugen が無い場合のフォールバック（手軽にテストできるようにするため）
# スクリプト本体が置かれているディレクトリにデータファイルがあればそこを参照する
if [ ! -d "$DATA_DIR" ]; then
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    if [ -f "$SCRIPT_DIR/${SERIES}_${LANG}.txt" ]; then
        DATA_DIR="$SCRIPT_DIR"
    fi
fi

FILE_PATH="$DATA_DIR/${SERIES}_${LANG}.txt"

# ファイルが存在しない場合は、何も出力せずに終了する（ターミナル起動を妨げないため）
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# macOSとLinuxでのシャッフルコマンドの違いを吸収する
# 1. shuf コマンド（Linux標準）があるか
# 2. gshuf コマンド（macOSでcoreutilsを入れている場合）があるか
# 3. どちらも無い場合は awk の乱数機能で代用する
if command -v shuf >/dev/null 2>&1; then
    grep -v '^\s*$\|^\s*#' "$FILE_PATH" | shuf -n "$NUM_CARDS"
elif command -v gshuf >/dev/null 2>&1; then
    grep -v '^\s*$\|^\s*#' "$FILE_PATH" | gshuf -n "$NUM_CARDS"
else
    # awkで各行の先頭に乱数を付与 -> sortで数値順に並び替え -> 先頭の乱数を削除 -> 指定行数取得
    grep -v '^\s*$\|^\s*#' "$FILE_PATH" | awk 'BEGIN{srand()} {print rand() "\t" $0}' | sort -k1,1n | cut -f2- | head -n "$NUM_CARDS"
fi
