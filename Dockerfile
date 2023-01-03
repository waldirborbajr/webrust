# stage 1
FROM rust as planner
WORKDIR /app
RUN cargo install cargo-chef
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# stage 2
FROM rust as cacher
WORKDIR /app
RUN cargo install cargo-chef
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

# stage 3
FROM rust as builder
ENV USER=webrust
ENV UID=1001
RUN adduser \
  --disabled-password \
  --gecos "" \
  --home "/nonexistent" \
  --no-create-home \
  --uid "${UID}" \
  "${USER}"
COPY . /app
WORKDIR /app
COPY --from=cacher /app/target target
COPY --from=cacher /usr/local/cargo /usr/local/cargo
RUN cargo build --release

# stage 4
FROM gcr.io/distroless/cc-debian11
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
COPY --from=builder /app/target/release/webrust /app/webrust
WORKDIR /app
USER webrust:webrust
CMD ["./webrust"]
