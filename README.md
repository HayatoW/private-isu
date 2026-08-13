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
└── webapp       # 各言語の参考実装
```

* [manual.md](/manual.md)は当日マニュアル。一部社内イベントを意識した記述があるので注意すること。
* [public_manual.md](/public_manual.md) は事前公開レギュレーション

## OS

Ubuntu 24.04

## 対応言語と状況

本環境では、以下の言語による参考実装が提供されています。
* Ruby (デフォルトで起動)
* Go
* PHP
* Python
* Node.js

## 起動方法

**重要:** 以下のいずれの手順を実行する前にも、まずプロジェクトのルートディレクトリで `make init` を実行して初期データを準備してください。

* Ruby、Go、PHP、Python、Node.jsの5言語の参考実装が用意されており、デフォルトではRubyが起動します。
  * AMIで他の言語の参考実装を動作させる場合は、[`manual.md`](/manual.md)を参照してください。
* 起動方法として、AMI、Docker Composeなどが用意されています。
  * ローカル環境で手軽に動作させることも比較的簡単です。
  * Ansibleを利用すれば、その他の環境でも動作するはずです。
  * cloud-initも利用可能

### 手元で動かす

**注意:** いずれの手順も、ディスク容量に十分な空きがあるマシン上で行ってください。

* アプリケーションは、各言語の実行環境とMySQL、memcachedがインストールされていれば動作するはずです。
* ベンチマーカーは、Goの実行環境と`userdata`ディレクトリがあれば動作します。
* Docker Composeを使用する場合は、メモリを潤沢に搭載したマシンで実行してください。

#### MacやLinux上で適当に動かす

MySQLとmemcachedを起動した上で、以下の手順を実行してください。

* Ruby以外の言語については、それぞれの言語の実行方法を別途確認してください。
* MySQLのrootユーザーにパスワードが設定されていない前提です。設定されている場合は、適宜手順を読み替えてください。

```sh
bunzip2 -c webapp/sql/dump.sql.bz2 | mysql -uroot

cd webapp/ruby
bundle install --path=vendor/bundle
bundle exec ruby prepare_unicorn.rb
bundle exec unicorn -c unicorn_config.rb
cd ../..

cd benchmarker
make
./bin/benchmarker -t "http://localhost:8080" -u ./userdata
# ./bin/benchmarker -t "http://<競技者用インスタンスのグローバルIPアドレス>/" -u ./userdata

# Output
# {"pass":true,"score":1710,"success":1434,"fail":0,"messages":[]}
```

### 競技者用・ベンチマーカーインスタンスのセットアップ方法

自身でインスタンスをセットアップしたい場合は、`provisioning/`ディレクトリ以下のスクリプトを参照してください。

## 事例集

* [インフラ研修 | Progate Path](https://app.path.progate.com/tasks/8ybBQYEXl73ajnNRGc-E0/preview)
  * この問題を新卒研修で利用する場合の事前研修に利用しています
* private-isuのベンチマーカーをLambdaで実行する仕組みを公開しました | PR TIMES 開発者ブログ https://developers.prtimes.jp/2024/01/29/private-isu-bench-lambda/
* 日本CTO協会による合同ISUCON研修の紹介 - Pepabo Tech Portal https://tech.pepabo.com/2024/02/16/isucon-2023/

## 他の言語実装

* Rust実装 https://github.com/Romira915/private-isu-rust
* Scala実装 https://github.com/catatsuy/private-isu/pull/140
