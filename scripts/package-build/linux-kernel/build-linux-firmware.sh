#!/bin/bash
set -e

# All selected drivers are then precomfiled "make drivers/foo/bar.i" and we grep for
# the magic word "UNIQUE_ID_firmware" which identifies firmware files.

CWD=$(pwd)
LINUX_FIRMWARE="linux-firmware"
KERNEL_VAR_FILE=${CWD}/kernel-vars
. ${CWD}/common.sh

. ${KERNEL_VAR_FILE}

if [ ! -d ${KERNEL_DIR} ]; then
    echo "Kernel source missing"
    exit 1
fi

if [ ! -d ${LINUX_FIRMWARE} ]; then
    echo "Linux firmware repository missing"
    exit 1
fi

# Retrieve firmware blobs from source files
FW_FILES=$(find ${KERNEL_DIR}/debian/linux-image-${KERNEL_VERSION}${KERNEL_SUFFIX}/lib/modules/${KERNEL_VERSION}${KERNEL_SUFFIX}/kernel/drivers/net -name *.ko* | xargs modinfo | grep "^firmware:" | awk '{print $2}')

# Debian package will use the descriptive Git commit as version
GIT_COMMIT=$(cd ${CWD}/${LINUX_FIRMWARE}; git describe --always)
VYOS_FIRMWARE_NAME="vyos-linux-firmware"
VYOS_FIRMWARE_DIR="${VYOS_FIRMWARE_NAME}_${GIT_COMMIT}-0_all"
if [ -d ${VYOS_FIRMWARE_DIR} ]; then
    # remove Debian package folder and deb file from previous runs
    rm -rf ${VYOS_FIRMWARE_DIR}*
fi
mkdir -p ${VYOS_FIRMWARE_DIR}

# Install firmware files to build directory
LINUX_FIRMWARE_BUILD_DIR="${LINUX_FIRMWARE}_${GIT_COMMIT}"

if [ -d ${LINUX_FIRMWARE_BUILD_DIR} ]; then
    rm -rf "${LINUX_FIRMWARE_BUILD_DIR}"
fi

mkdir -p "${LINUX_FIRMWARE_BUILD_DIR}"

(
    cd ${LINUX_FIRMWARE}
    ./copy-firmware.sh "${CWD}/${LINUX_FIRMWARE_BUILD_DIR}"
)

# Copy firmware file from linux firmware build directory into
# assembly folder for the vyos-firmware package
SED_REPLACE="s@${CWD}/${LINUX_FIRMWARE}/@@"
for FILE_PATTERN in ${FW_FILES}; do
    find "${LINUX_FIRMWARE_BUILD_DIR}" -path "*/${FILE_PATTERN}" -print0 | while IFS= read -r -d $'\0' FILE; do
        TARGET="$(echo "${FILE}" | sed "s/${LINUX_FIRMWARE_BUILD_DIR}\///g")"
        TARGET_DIR="${VYOS_FIRMWARE_DIR}/lib/firmware/$(dirname "${TARGET}")"
        # If file is a symlink install the symlink target as well
        if [ -h "${FILE}" ]; then
            if [ ! -f "${TARGET_DIR}/$(basename "${TARGET}")" ]; then
                if [ -f "${LINUX_FIRMWARE_BUILD_DIR}/${TARGET}" ]; then
                    mkdir -p "${TARGET_DIR}"

                    echo "I: install firmware: ${TARGET}"
                    cp "${CWD}/${LINUX_FIRMWARE_BUILD_DIR}/${TARGET}" "${TARGET_DIR}"
		    # If file links to other folder which this script not cover. Create folder and copy together.
                    if [ -L "${LINUX_FIRMWARE_BUILD_DIR}/${TARGET}" ]; then
                        REALPATH_TARGET=$(realpath --relative-to="${CWD}/${LINUX_FIRMWARE_BUILD_DIR}" "${CWD}/${LINUX_FIRMWARE_BUILD_DIR}/${TARGET}")
                        REALPATH_TARGET_DIR="${VYOS_FIRMWARE_DIR}/lib/firmware/$(dirname "${REALPATH_TARGET}")"
                        mkdir -p "${REALPATH_TARGET_DIR}"
                        echo "I: install firmware: ${REALPATH_TARGET}"
                        cp "${CWD}/${LINUX_FIRMWARE_BUILD_DIR}/${REALPATH_TARGET}" "${REALPATH_TARGET_DIR}"
                    fi
                 else
                    echo "I: firmware file not found: ${TARGET}"
                fi
            fi
        fi

        if [ -f "${FILE}" ]; then
            mkdir -p "${TARGET_DIR}"
            echo "I: install firmware: ${TARGET}"
            cp -P "${CWD}/${LINUX_FIRMWARE_BUILD_DIR}/${TARGET}" "${TARGET_DIR}"
        else
            echo "I: firmware file not found: ${TARGET}"
        fi
    done
done

# Fallback for versioned iwlwifi ucode: MODULE_FIRMWARE declares only the
# API_MAX filename (e.g. iwlwifi-gl-c0-fm-c0-c99.ucode) while linux-firmware
# may only ship other API versions the driver falls back to at runtime
# (e.g. -101/-100). If an iwlwifi ucode pattern matched nothing above (the
# package would otherwise ship no firmware for that device), install the
# shipped versions of that prefix whose API number is >= the declared
# API_MAX number ('c' prefix stripped) -- everything below it is below the
# driver's minimum supported API and can never be loaded. Also install the
# prefix's .pnvm data files, which the driver requires at runtime but does
# not always declare via MODULE_FIRMWARE.
for FILE_PATTERN in ${FW_FILES}; do
    case "${FILE_PATTERN}" in
        iwlwifi-*.ucode)
            BASENAME=$(basename "${FILE_PATTERN}")
            if ! find "${VYOS_FIRMWARE_DIR}/lib/firmware" -name "${BASENAME}" 2>/dev/null | grep -q .; then
                PREFIX=$(echo "${BASENAME}" | sed -E 's/-[a-z]?[0-9]+\.ucode$//')
                MAXV=$(echo "${BASENAME}" | sed -E 's/^.*-[a-z]?([0-9]+)\.ucode$/\1/')
                find "${LINUX_FIRMWARE_BUILD_DIR}" \( -name "${PREFIX}-*.ucode" -o -name "${PREFIX}*.pnvm" \) -print0 | while IFS= read -r -d $'\0' FILE; do
                    case "${FILE}" in
                        *.ucode)
                            V=$(basename "${FILE}" | sed -E 's/^.*-[a-z]?([0-9]+)\.ucode$/\1/')
                            case "${V}" in ''|*[!0-9]*) continue ;; esac
                            [ "${V}" -ge "${MAXV}" ] || continue
                            ;;
                    esac
                    TARGET="$(echo "${FILE}" | sed "s/${LINUX_FIRMWARE_BUILD_DIR}\///g")"
                    TARGET_DIR="${VYOS_FIRMWARE_DIR}/lib/firmware/$(dirname "${TARGET}")"
                    mkdir -p "${TARGET_DIR}"
                    echo "I: install firmware (api fallback): ${TARGET}"
                    cp -P "${FILE}" "${TARGET_DIR}"
                done
            fi
            ;;
    esac
done

echo "I: Create linux-firmware package"
rm -f ${VYOS_FIRMWARE_NAME}_*.deb

PACKAGE_VERSION=$(debian_version "${GIT_COMMIT}")

cd ${VYOS_FIRMWARE_DIR}

debmake -n -y -p ${VYOS_FIRMWARE_NAME} -u ${PACKAGE_VERSION} \
    -e maintainers@vyos.net -f "VyOS Package Maintainers"

cat << EOF > debian/control
Source: ${VYOS_FIRMWARE_NAME}
Section: kernel
Priority: optional
Maintainer: VyOS Package Maintainers <maintainers@vyos.net>
Build-Depends: debhelper-compat (= 13)
Standards-Version: 4.5.1
Rules-Requires-Root: no

Package: ${VYOS_FIRMWARE_NAME}
Architecture: all
Depends: \${misc:Depends}
Description: Binary firmware for various drivers in the Linux kernel
 Firmware blobs assembled from linux-firmware.git for the drivers built
 into the VyOS kernel.
EOF

cat << EOF > debian/rules
#!/usr/bin/make -f
PACKAGE_BUILD_DIR := debian/${VYOS_FIRMWARE_NAME}

%:
	dh \$@

override_dh_auto_build:
	@true

override_dh_auto_install:
	mkdir -p \${PACKAGE_BUILD_DIR}
	cp -a lib \${PACKAGE_BUILD_DIR}/
EOF

debuild

cd ${CWD}

rm -rf "${LINUX_FIRMWARE_BUILD_DIR}"
rm -rf ${VYOS_FIRMWARE_DIR}
