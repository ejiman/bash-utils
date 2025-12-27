#!/usr/bin/env bash

if [[ "$OS" == "macos" ]]; then
  SED="gsed"
  DATE="gdate"
else
  SED="sed"
  DATE="date"
fi

export SED DATE
