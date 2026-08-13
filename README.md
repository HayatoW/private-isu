# private-isu

「[ISUCON](https://isucon.net)」は、LINE株式会社の商標または登録商標です。

本リポジトリが書籍の題材になりました。詳しくは以下のURLをご覧ください。

* [達人が教えるWebパフォーマンスチューニング 〜ISUCONから学ぶ高速化の実践：書籍案内｜技術評論社](https://gihyo.jp/book/2022/978-4-297-12846-3)
* [tatsujin-web-performance/tatsujin-web-performance: 達人が教えるWebパフォーマンスチューニング〜ISUCONから学ぶ高速化の実践](https://github.com/tatsujin-web-performance/tatsujin-web-performance)

ハッシュタグ： `#ISUCON本`

## タイムライン

2016年に作成した社内ISUCONリポジトリを2021年に手直ししました。2022年に書籍の題材になりました。

［2016年開催時のブログ］

* ISUCON6出題チームが社内ISUCONを開催！AMIも公開！！ - pixiv inside [archive] https://devpixiv.hatenablog.com/entry/2016/05/18/115206
* 社内ISUCONを公開したら広く使われた話 - pixiv inside [archive] https://devpixiv.hatenablog.com/entry/2016/09/26/130112

過去ISUCON公式で練習問題として推奨されたことがある。

* ISUCON初心者のためのISUCON7予選対策 : ISUCON公式Blog https://isucon.net/archives/50697356.html

［2021年開催時のブログ］

* 社内ISUCON “TIMES-ISUCON” を開催しました！ | PR TIMES 開発者ブログ https://developers.prtimes.jp/2021/06/04/times-isucon-1/

## ディレクトリ構成

```
├── benchmarker  # ベンチマーカーのソースコード
├── provisioning # 競技者用・ベンチマーカーインスタンスセットアップ用ansible
└── webapp       # 参考実装（Rust）
```

* [manual.md](/manual.md) は当日マニュアル。一部社内イベントを意識した記述があるので注意すること。
* [public_manual.md](/public_manual.md) は事前公開レギュレーション

## OS

Ubuntu 24.04

## 対応言語と状況

本環境では、以下の言語による参考実装が提供されています。

* Rust（デフォルトで起動）

## 起動方法

Cursor Cloud Agent（Ubuntu）では、MySQL と memcached をホストに入れて Rust 実装を直接起動してください。 Docker Compose は手元の Mac など向けです。

**重要:** いずれの手順の前にも、プロジェクトのルートディレクトリで `make init` を実行して初期データを準備してください。

* Rust の参考実装は `webapp/rust` にあり、ホスト直接起動時は 8080 番ポートで待ち受けます。
* 競技者用・ベンチマーカーインスタンスを自分で用意する場合は、`provisioning/` を参照してください。

### Linux 上で動かす（推奨）

Cloud Agent や Ubuntu ではこの手順を使います。入れ子の Docker Compose よりディスク I/O が安定し、`compose.yml` の CPU / メモリ制限もかかりません。

**注意:** 初期データが大きいため、ディスク容量に十分な空きがあるマシン上で行ってください。

必要なパッケージの例（Ubuntu 24.04）:

```sh
sudo apt-get update
sudo apt-get install -y mysql-server memcached bzip2 unzip pkg-config libssl-dev build-essential
sudo systemctl enable --now mysql memcached
```

Rust のツールチェインは [rustup](https://rustup.rs/) で入れてください。ベンチマーカーには Go が必要です。

```sh
make init

# root は unix_socket 認証のままで初期データを流し込む
bunzip2 -c webapp/sql/dump.sql.bz2 | sudo mysql

# アプリが TCP でつながるユーザを作る
sudo mysql <<'SQL'
CREATE USER IF NOT EXISTS 'isuconp'@'localhost' IDENTIFIED BY 'isuconp';
CREATE USER IF NOT EXISTS 'isuconp'@'127.0.0.1' IDENTIFIED BY 'isuconp';
GRANT ALL PRIVILEGES ON *.* TO 'isuconp'@'localhost';
GRANT ALL PRIVILEGES ON *.* TO 'isuconp'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL
```

アプリケーションは `webapp/rust` で起動します。テンプレートが `./static`、静的ファイルが `../public` にあるためです。 `--release` ビルドでは `ISUCONP_DB_PASSWORD` が必須です。

```sh
cd webapp/rust
export SQLX_OFFLINE=true
cargo build --release

export ISUCONP_DB_HOST=127.0.0.1
export ISUCONP_DB_PORT=3306
export ISUCONP_DB_USER=isuconp
export ISUCONP_DB_PASSWORD=isuconp
export ISUCONP_DB_NAME=isuconp
export ISUCONP_MEMCACHED_ADDRESS=127.0.0.1:11211
./target/release/private-is-rust
```

別ターミナルでベンチマーカーを実行します。アプリは 8080 番ポートで待ち受けるため、ターゲットは `http://localhost:8080` です。

```sh
cd benchmarker
make
./bin/benchmarker -t "http://localhost:8080" -u ./userdata
# ./bin/benchmarker -t "http://<競技者用インスタンスのグローバルIPアドレス>/" -u ./userdata

# Output
# {"pass":true,"score":1710,"success":1434,"fail":0,"messages":[]}
```

### Docker Compose

手元の Mac など、ホストに MySQL を入れたくない場合に使います。 Cloud Agent 上では入れ子の Docker になるため推奨しません。

起動前に `webapp/sql/dump.sql.bz2` が配置されていないと MySQL に初期データがインポートされないため注意してください。 `make init` で取得できます。

```sh
cd webapp
docker compose up
```

この環境では TCP のポート 80 と 3306 をホストにマッピングします。ホスト側でこれらのポートが使われている場合は、該当プロセスを止めるか `compose.yml` の `ports` を変更してください。

`compose.yml` やアプリケーションの変更を反映するには、`docker compose down` のあと `docker compose up --build` で起動し直してください。

nginx はホストの 80 番ポートで待ち受けるため、ベンチマーカーのターゲットは `http://localhost` です。

```sh
cd benchmarker
make
./bin/benchmarker -t "http://localhost" -u ./userdata
```

### 競技者用・ベンチマーカーインスタンスのセットアップ方法

自身でインスタンスをセットアップしたい場合は、`provisioning/` ディレクトリ以下のスクリプトを参照してください。

## 事例集

* [インフラ研修 | Progate Path](https://app.path.progate.com/tasks/8ybBQYEXl73ajnNRGc-E0/preview)
  * この問題を新卒研修で利用する場合の事前研修に利用しています
* private-isuのベンチマーカーをLambdaで実行する仕組みを公開しました | PR TIMES 開発者ブログ https://developers.prtimes.jp/2024/01/29/private-isu-bench-lambda/
* 日本CTO協会による合同ISUCON研修の紹介 - Pepabo Tech Portal https://tech.pepabo.com/2024/02/16/isucon-2023/

## 他の言語実装

本リポジトリの参考実装は Rust です。元になった実装は [Romira915/private-isu-rust](https://github.com/Romira915/private-isu-rust) です。

Ruby / Go / PHP / Python / Node.js の参考実装は [catatsuy/private-isu](https://github.com/catatsuy/private-isu) を参照してください。

* Scala実装 https://github.com/catatsuy/private-isu/pull/140
