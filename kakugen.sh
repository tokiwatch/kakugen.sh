#!/bin/bash

# デフォルト設定
NUM_CARDS=1
CONFIG_FILE="$HOME/.kakugenrc"
DATA_FILES=()
FILE_TITLES=() # Bash 3互換のため、パスとタイトルを「パス=タイトル」の形式で配列に保持する
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
            
            # "=" で分割してファイルパスとタイトルを取得
            if [[ "$line" == *"="* ]]; then
                raw_path="${line%%=*}"
                title="${line#*=}"
            else
                raw_path="$line"
                title=""
            fi
            
            # ~ を $HOME に展開
            # eval時のダブルクォートを外すことでチルダ展開を有効にする
            # ただし、スペースを含むパスが誤動作しないように、チルダ展開後に再度クォートで括る処理が理想的だが、
            # 最もシンプルなチルダ置換を利用する (${raw_path/#\~/$HOME})
            expanded_path="${raw_path/#\~/$HOME}"
            
            # 環境変数を展開 (evalを使用)
            eval "expanded_path=\"$expanded_path\""
            
            DATA_FILES+=("$expanded_path")
            if [ -n "$title" ]; then
                FILE_TITLES+=("$expanded_path=$title")
            fi
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
VALID_FILES=()
for file in "${DATA_FILES[@]}"; do
    if [ -f "$file" ]; then
        VALID_FILES+=("$file")
    fi
done

if [ ${#VALID_FILES[@]} -eq 0 ]; then
    rm -f "$TEMP_FILE"
    exit 0
fi

MULTI_FILE=0
if [ ${#VALID_FILES[@]} -gt 1 ]; then
    MULTI_FILE=1
fi

for file in "${VALID_FILES[@]}"; do
    # タイトルが設定されていればそれを使用し、なければファイル名(拡張子なし)を使用
    source_name=""
    for item in "${FILE_TITLES[@]}"; do
        if [[ "$item" == "$file="* ]]; then
            source_name="${item#*=}"
            break
        fi
    done
    
    if [ -z "$source_name" ]; then
        source_name=$(basename "$file")
        source_name="${source_name%.*}" # 拡張子を除外
    fi
    
    # 複数ファイルの場合は出典元がわかるようにタイトル（またはファイル名）を埋め込む
    echo "@@@FNAME=${source_name}@@@" >> "$TEMP_FILE"
    echo "%" >> "$TEMP_FILE"
    
    # ファイルの末尾に改行と % が無い場合に備えて追加しつつテンポラリに結合
    cat "$file" >> "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    echo "%" >> "$TEMP_FILE"
done

# awkを使って % を区切り（RS）としてパースし、各ブロックを配列に格納してからランダムに出力する
# shuf や sort は改行を含むデータに弱いため、awk 内ですべてのランダム抽出処理を完結させる。

awk -v num="$NUM_CARDS" -v search="$SEARCH_QUERY" -v multi="$MULTI_FILE" '
BEGIN {
    RS="(^|\n)%(\n|$)" # %の行をレコードセパレータとする
    srand()
    count = 0
    current_fname = ""
}
{
    # 先頭と末尾の空白/改行をトリム
    gsub(/^[ \t\n]+|[ \t\n]+$/, "", $0)
    
    # ファイル名マーカーの検出
    if (match($0, /^@@@FNAME=.*@@@$/)) {
        current_fname = substr($0, 10, length($0) - 12)
        next
    }
    
    if (length($0) > 0) {
        if (search == "" || index($0, search) > 0) {
            if (multi == 1) {
                cards[count] = $0 "\n-- " current_fname
            } else {
                cards[count] = $0
            }
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
    }
}
' "$TEMP_FILE"

# 一時ファイルの削除
rm -f "$TEMP_FILE"
