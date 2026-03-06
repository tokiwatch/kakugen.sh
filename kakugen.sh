#!/bin/bash

# デフォルト設定
NUM_CARDS=1
CONFIG_FILE="$HOME/.kakugenrc"
DATA_FILES=()
SEARCH_QUERY=""

# 引数のパース
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--number) NUM_CARDS="$2"; shift ;;
        -f|--file)
            # カンマ区切りのファイルパスを配列に変換
            IFS=',' read -ra FILES_ARG <<< "$2"
            for f in "${FILES_ARG[@]}"; do
                DATA_FILES+=("$f")
            done
            shift
            ;;
        -c|--config) CONFIG_FILE="$2"; shift ;;
        -s|--search) SEARCH_QUERY="$2"; shift ;;
        -h|--help)
            echo "Usage: kakugen [-n number] [-f file1,file2...] [-c config_file] [-s search_query]"
            echo "Options:"
            echo "  -n, --number <int>    表示する格言の個数 (デフォルト: 1)"
            echo "  -f, --file <paths>    読み込むファイル(カンマ区切り)。指定時は設定ファイルを無視。"
            echo "  -c, --config <path>   設定ファイルのパス (デフォルト: ~/.kakugenrc)"
            echo "  -s, --search <str>    指定した文字列を含む格言のみを抽出"
            exit 0
            ;;
        *)
            echo "Unknown parameter passed: $1" >&2
            exit 1
            ;;
    esac
    shift
done

# -fオプションでファイルが指定されていない場合、設定ファイルを読み込む
if [ ${#DATA_FILES[@]} -eq 0 ]; then
    if [ -f "$CONFIG_FILE" ]; then
        # 設定ファイルから有効なファイルパスを読み込む（空行と#から始まるコメント行を除外、環境変数を展開）
        while IFS= read -r line || [ -n "$line" ]; do
            # コメントと空行をスキップ
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${line// }" ]] && continue
            
            # ~ を $HOME に展開、環境変数を展開 (evalを使用)
            eval "expanded_path=\"$line\""
            DATA_FILES+=("$expanded_path")
        done < "$CONFIG_FILE"
    else
        # ~/.kakugenrc が無い場合のフォールバック（初回実行用・手軽にテストできるようにするため）
        SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
        if [ -f "$SCRIPT_DIR/sample_ja.txt" ]; then
            DATA_FILES+=("$SCRIPT_DIR/sample_ja.txt")
        fi
    fi
fi

# 有効なファイルの存在確認と結合
TEMP_FILE=$(mktemp)
for file in "${DATA_FILES[@]}"; do
    if [ -f "$file" ]; then
        # ファイルの末尾に改行と % が無い場合に備えて追加しつつテンポラリに結合
        cat "$file" >> "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
        echo "%" >> "$TEMP_FILE"
    fi
done

# テンポラリファイルが空（読み込めるファイルが一つもない）場合は終了
if [ ! -s "$TEMP_FILE" ]; then
    rm -f "$TEMP_FILE"
    exit 0
fi

# awkを使って % を区切り（RS）としてパースし、各ブロックを配列に格納してからランダムに出力する
# shuf や sort は改行を含むデータに弱いため、awk 内ですべてのランダム抽出処理を完結させる。

awk -v num="$NUM_CARDS" -v search="$SEARCH_QUERY" '
BEGIN {
    RS="(^|\n)%(\n|$)" # %の行をレコードセパレータとする
    srand()
    count = 0
}
{
    # 先頭と末尾の空白/改行をトリム
    gsub(/^[ \t\n]+|[ \t\n]+$/, "", $0)
    if (length($0) > 0) {
        if (search == "" || index($0, search) > 0) {
            cards[count] = $0
            count++
        }
    }
}
END {
    if (count == 0) exit;
    if (num > count) num = count;
    
    # 配列をシャッフル（Fisher-Yatesシャッフル）
    for (i = count - 1; i > 0; i--) {
        j = int(rand() * (i + 1))
        temp = cards[i]
        cards[i] = cards[j]
        cards[j] = temp
    }
    
    # 指定個数を出力
    for (i = 0; i < num; i++) {
        print cards[i]
        if (i < num - 1) {
            print "" # 複数表示する場合の空行
        }
    }
}
' "$TEMP_FILE"

# 一時ファイルの削除
rm -f "$TEMP_FILE"
