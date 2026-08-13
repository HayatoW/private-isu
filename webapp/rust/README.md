# private-isu Rust実装

本リポジトリの参考実装です。起動手順はリポジトリルートの [README.md](../../README.md) を参照してください。

Cursor Cloud Agent や Ubuntu では、ホストに MySQL と memcached を入れてこのディレクトリから直接起動してください。 Docker Compose は手元の Mac 向けです。

スキーマを変えたあとに sqlx のオフラインキャッシュを更新する場合:

```sh
cd webapp/rust
echo 'DATABASE_URL=mysql://isuconp:isuconp@127.0.0.1:3306/isuconp' > .env
cargo sqlx prepare
```
