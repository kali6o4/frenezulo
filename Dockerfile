FROM ghcr.io/rust-lang/rust:nightly-slim as dependencies

WORKDIR /usr/src/app

RUN mkdir -p src/services

COPY Cargo.toml .
COPY services/ ./services
COPY crates/ ./crates

#   RUN mkdir -p services && \
#   mkdir -p services/hello-world-service && \
#   echo "fn main() {}" > services/hello-world-service/src/main.rs && \
#   cargo build --workspace -Z unstable-options --out-dir /output/services/hello-world-service

RUN mkdir -p src && \
	echo "fn main() {}" > src/main.rs && \
    rustup target add wasm32-wasi && \
    cargo build --release --target=wasm32-wasi -Z unstable-options --out-dir /output

FROM ghcr.io/rust-lang/rust:nightly-slim as planner

# Those are the lines instructing this image to reuse the files 
# from the previous image that was aliased as "dependencies" 
COPY --from=dependencies /usr/src/app/Cargo.toml .
COPY --from=dependencies /usr/src/app/services/ ./services
COPY --from=dependencies /usr/src/app/crates/ ./crates
COPY --from=dependencies /usr/local/cargo /usr/local/cargo

COPY src/ src/

VOLUME /output

# RUN  && \
RUN rustup target add wasm32-wasi && \
    cargo build --release --target=wasm32-wasi -Z unstable-options --out-dir /output


FROM rust as builder
WORKDIR /usr/src/app
RUN curl -L https://github.com/lunatic-solutions/lunatic/releases/download/v0.10.1/lunatic-linux-amd64.tar.gz | tar -xz

FROM scratch
COPY --from=planner /output /output
COPY --from=builder /usr/src/app/lunatic .
USER 1000
CMD ["./lunatic", "/output/frenezulo.wasm"]