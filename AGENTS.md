# Repository Guidelines

## Preserve the Exercise Before Improving the Code

`private-isu` is an ISUCON practice problem for learning Web application performance tuning. The initial implementations' inefficiency and slowness are part of the exercise, not ordinary technical debt. In this repository, a generally "good" cleanup can be a regression because it removes a bottleneck that participants are meant to discover.

- Unless the user explicitly requests it, do not perform performance tuning, refactoring, architecture changes, or changes to how data is stored.
- Do not helpfully fix known teaching examples such as N+1 queries, SQL without `LIMIT`, images stored in the database, hash calculation through external commands, or parsing templates on every request.
- Distinguish intentionally slow code from code that has actually stopped working after an environment update. If the distinction is unclear, ask the user instead of changing it.
- Make only changes required by the request. Do not include opportunistic fixes, cleanup, formatting, or modernization.

## Cross-Implementation Compatibility

This fork's reference implementation is Rust in `webapp/rust/`. Externally observable features and behavior must stay aligned with the original private-isu problem (routes, HTML DOM, cookies, CSRF, redirects, and time handling).

- Passing the benchmark alone is not evidence that a behavior change is safe.
- Preserve existing behavior rather than reorganizing the implementation into a preferred handler/repository/service architecture.

## Benchmarker Is Part of the Problem

`benchmarker/` contains the exercise's workload and correctness checks. Its scenarios, concurrency, scoring, and validation behavior are part of the existing problem setting.

- Do not improve, reorganize, or otherwise alter the benchmarker unless explicitly requested.
- The benchmarker is not a complete specification. A passing benchmark alone is not evidence that a behavior change is safe.

## Dependency and Environment Updates

For updates to dependencies, language runtimes, the OS, MySQL, nginx, Docker, or Ansible, make only the minimum changes necessary to restore or maintain compatibility. Do not combine unrelated application improvements or exercise changes with an environment update.

## Repository Layout

- `webapp/rust/` contains the Rust reference implementation.
- `webapp/sql/` contains the schema and initial data used by setup (`dump.sql.bz2` is downloaded by `make init`).
- `benchmarker/` contains the Go load generator and correctness checks.
- `provisioning/` contains Ansible configuration for the exercise environment.

## Verified Commands

- `make init`: download the canonical MySQL dump and image fixtures.
- `cd webapp/rust && SQLX_OFFLINE=true cargo build --release`: build the Rust application as `webapp/rust/target/release/private-is-rust`. Run it from `webapp/rust` so templates (`./static`) and static files (`../public`) resolve.
- `cd benchmarker && make`: build `benchmarker/bin/benchmarker`.
- `cd benchmarker && ./bin/benchmarker -t "http://localhost:8080" -u ./userdata`: run the benchmark against the host-native app (port 8080).
- `cd webapp && docker compose up`: start nginx, the app, MySQL, and Memcached. Prefer this on a local Mac, not on Cloud Agent. The Compose stack listens on port 80.

Use the language-native formatter or tests relevant to the requested change, but do not treat their success as authorization to broaden the change. Never commit secrets or downloaded dumps.

## Cursor Cloud specific instructions

Cloud Agents run on Ubuntu. Prefer hosting MySQL, Memcached, and the Rust app directly on the VM. Do not use Docker Compose here: nested Docker plus the CPU/memory limits in `webapp/compose.yml` make the benchmark slower and less representative.

Once per machine:

```sh
sudo apt-get update
sudo apt-get install -y mysql-server memcached bzip2 unzip pkg-config libssl-dev build-essential
sudo systemctl enable --now mysql memcached
make init
bunzip2 -c webapp/sql/dump.sql.bz2 | sudo mysql
sudo mysql <<'SQL'
CREATE USER IF NOT EXISTS 'isuconp'@'localhost' IDENTIFIED BY 'isuconp';
CREATE USER IF NOT EXISTS 'isuconp'@'127.0.0.1' IDENTIFIED BY 'isuconp';
GRANT ALL PRIVILEGES ON *.* TO 'isuconp'@'localhost';
GRANT ALL PRIVILEGES ON *.* TO 'isuconp'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL
```

Install Rust with rustup if `cargo` is missing. Then, from `webapp/rust`:

```sh
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

Benchmark against `http://localhost:8080`. See `README.md` for the full host-native and Docker Compose procedures.
