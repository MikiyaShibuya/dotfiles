#!/bin/bash

mkdir -p $HOME/.config/karabiner/assets/complex_modifications
for FILE_NAME in custom.json esc_to_tila_backquate.json command_en_jp.json
do
    ln -nfs $PWD/${FILE_NAME} $HOME/.config/karabiner/assets/complex_modifications/${FILE_NAME}
done

