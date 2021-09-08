ARG VERSION=p2p

FROM rust:1.48.0-slim as electrs-build

ARG VERSION

RUN apt-get update
RUN apt-get install -qq -y clang cmake git
RUN rustup component add rustfmt

# Build, test and install electrs
WORKDIR /build/electrs
RUN git clone --depth=1 --branch $VERSION https://github.com/romanz/electrs .
RUN echo "1.48.0" > rust-toolchain
RUN cargo fmt -- --check
RUN cargo build --locked --release --all
RUN cargo test --locked --release --all
RUN cargo install --locked --path .

FROM debian:bullseye-slim as final

COPY --from=electrs-build /usr/local/cargo/bin/electrs /usr/bin/electrs

RUN groupadd -r user \
    && adduser --disabled-login --system --shell /bin/false --uid 1000 --ingroup user user \
    && chown -R user:user /app

USER user

# Electrum RPC
EXPOSE 50001

# Prometheus monitoring
EXPOSE 4224

STOPSIGNAL SIGINT

HEALTHCHECK CMD curl -fSs http://localhost:4224/ || exit 1

ENTRYPOINT ["/usr/bin/electrs"]
