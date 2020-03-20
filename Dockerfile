FROM elixir:1.9
LABEL maintainer "Christophe De Troyer <christophe@call-cc.be>"

# Install  Hex, Rebar, and Phoenix.
RUN mix local.hex --force &&                                  \
    mix local.rebar --force

# Add the source code. 
ADD . /app

# Build the application.
ENV MIX_ENV=prod
WORKDIR /app 
RUN mix deps.get --only prod &&                          \
    mix compile

# ENTRYPOINT ["mix"]
ENTRYPOINT ["iex", "-S", "mix"]

# -e DB_NAME=exbindb -e DB_PASS=supersecretpassword -e DB_USER=postgres -e DB_HOST=localhost