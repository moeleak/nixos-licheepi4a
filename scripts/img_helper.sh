find_default_img() {
    find ./result-sdImage/sd-image ./result/sd-image ./release \
        -maxdepth 1 -type f -name "*.img" -print 2>/dev/null \
        | sort \
        | tail -n 1
}

select_img() {
    local DEFAULT_IMAGE
    DEFAULT_IMAGE=$(find_default_img)

    if [ -n "${DEFAULT_IMAGE}" ]; then
        echo "Choose image to flash (${DEFAULT_IMAGE}):"
    else
        echo "Choose image to flash:"
    fi
    read -r IMAGE

    IMAGE=${IMAGE:-${DEFAULT_IMAGE}}
    if [ -z "${IMAGE}" ] || [ ! -f "${IMAGE}" ]; then
        echo "No such image: ${IMAGE}"
        exit 1
    fi

    case "${IMAGE}" in
        *.img) ;;
        *)
            echo "Image must be an uncompressed .img file: ${IMAGE}"
            exit 1
            ;;
    esac

    export IMAGE
}
