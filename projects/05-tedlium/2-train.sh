if [[ -e model/001_model_last.bin ]]; then
    cmd="mpirun -n 4 /opt/wav2letter/build/Train continue model --flagsfile flagsfile"
else
    cmd="mpirun -n 4 /opt/wav2letter/build/Train train --flagsfile flagsfile"
    mkdir -p model
    touch model/001_log
fi

tmux new-session \; split-window -v \; split-window -v \; select-pane -t 0 \; split-window -v \; \
    select-pane -t 0 \; send-keys 'htop' C-m \; \
    select-pane -t 1 \; send-keys "$cmd" C-m \; \
    select-pane -t 2 \; send-keys 'tail -qf model/*_log' C-m \; \
    select-pane -t 3 \; send-keys 'watch nvidia-smi' C-m \; \
