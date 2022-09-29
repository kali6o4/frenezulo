FROM ghcr.io/rust-lang/rust:nightly-slim as dependencies

WORKDIR /usr/src/app
VOLUME /output

COPY Cargo.toml .
COPY services/ ./services
COPY crates/ ./crates

RUN mkdir -p src && \
	echo "fn main() {}" > src/main.rs && \
    rustup target add wasm32-wasi && \
    cargo install lunatic-runtime && \
    cargo build --release --target=wasm32-wasi -Z unstable-options

FROM ghcr.io/rust-lang/rust:nightly-buster as builder

WORKDIR /usr/src/app
VOLUME /output

RUN git clone https://github.com/lunatic-solutions/lunatic.git .
# Jump into the cloned folder
RUN mkdir -p src && \
	echo "fn main() {}" > src/main.rs && \
    cargo build --release -Z unstable-options

FROM debian:stable-slim as application

VOLUME /output
WORKDIR /service

COPY --from=dependencies /usr/src/app/target/wasm32-wasi/release/frenezulo.wasm /service/frenezulo.wasm
COPY --from=builder /usr/src/app/target/release/lunatic /service/lunatic

# CMD ["sleep", "infinity"]
# CMD ["lunatic", "/service/frenezulo.wasm"]
CMD ./lunatic /service/frenezulo.wasm