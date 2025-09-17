#!/bin/bash

set -euxo pipefail

PYENV_ROOT="$HOME/.pyenv"

if [[ -d "$PYENV_ROOT" ]]; then
    $PYENV_ROOT/bin/pyenv doctor
else
    curl -fsSL https://pyenv.run | bash
fi

echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init - bash)"' >> ~/.bashrc
