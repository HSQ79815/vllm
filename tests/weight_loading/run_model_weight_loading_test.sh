#!/bin/bash
SUCCESS=0

while getopts "c:" OPT; do
  case ${OPT} in
    c )
        CONFIG="$OPTARG"
        ;;
    \? )
        usage
        exit 1
        ;;
  esac
done


IFS=$'\n' read -d '' -r -a MODEL_CONFIGS < "$CONFIG"

for MODEL_CONFIG in "${MODEL_CONFIGS[@]}"
do
    if [[ $MODEL_CONFIG == \#* ]]; then
        echo "=== SKIPPING MODEL: $MODEL_CONFIG ==="
        continue
    fi

    LOCAL_SUCCESS=0
    IFS=', ' read -r -a array <<< "$MODEL_CONFIG"

    echo "=== RUNNING MODEL: $MODEL_CONFIG ==="

    export QUANTIZATION=${array[0]}
    export MODEL_NAME=${array[1]}
    export REVISION=${array[2]}
    # If array length is larger than 3, then MIN_CAPABILITY is provided
    if [ ${#array[@]} -gt 3 ]; then
        export MIN_CAPABILITY=${array[3]}
    fi
    pytest -s weight_loading/test_weight_loading.py || LOCAL_SUCCESS=$?

    if [[ $LOCAL_SUCCESS == 0 ]]; then
        echo "=== PASSED MODEL: ${MODEL_CONFIG} ==="
    else
        echo "=== FAILED MODEL: ${MODEL_CONFIG} ==="
    fi

    SUCCESS=$((SUCCESS + LOCAL_SUCCESS))

done

if [ "${SUCCESS}" -eq "0" ]; then
    exit 0
else
    exit 1
fi
