#!/usr/bin/env bash

export SECRET_KEY_BASE=your-secret-key
export MIX_ENV=prod
export PORT=4000

echo "==> Getting deps"
mix do deps.get, deps.compile, compile

echo "==> Generating release"
mix release

echo "==> Starting server"
_build/prod/rel/bunny/bin/bunny console
