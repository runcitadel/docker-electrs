ARG VERSION=master

FROM rust:1.55.0-slim-bullseye as electrs-build

ARG VERSION

RUN apt-get update
RUN apt-get install -qq -y clang cmake git
RUN rustup component add rustfmt

# Build, test and install electrs
WORKDIR /build/electrs
RUN git clone --depth=1 --branch $VERSION https://github.com/romanz/electrs .
RUN echo "1.55.0" > rust-toolchain
RUN cargo fmt -- --check
RUN cargo build --locked --release --all
RUN cargo test --locked --release --all
RUN cargo install --locked --path .

FROM debian:11-slim as final

RUN apt update && apt dist-upgrade -y && apt clean

COPY --from=electrs-build /usr/local/cargo/bin/electrs /usr/bin/electrs

RUN groupadd -r user && adduser --disabled-login --system --shell /bin/false --uid 1000 --ingroup user user

USER user

# Electrum RPC
EXPOSE 50001

# Prometheus monitoring
EXPOSE 4224

STOPSIGNAL SIGINT

HEALTHCHECK CMD curl -fSs http://localhost:4224/ || exit 1

ENTRYPOINT ["/usr/bin/electrs"]
