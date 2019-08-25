ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

ANCILLA_CMD="docker run --rm -it -v=${ROOT_DIR}:${ROOT_DIR} -w=${ROOT_DIR} ankoh/ancilla:latest ancilla"

GAME_VERSION="1_11_2929_2"

PKG_BUILD_DIR="${ROOT_DIR}/build"
PKG_DIFF_DIR="${PKG_BUILD_DIR}/diff"
PKG_BUNDLE_DIR="${PKG_BUILD_DIR}/GTS/${GAME_VERSION}_active"

PKG_BASE_COMMIT="e87309ebe815e69c497604eeff3b7e4088c38244"
PKG_DATA_EXTENSIONS='\.xml$|\.cfg$|\.ddx$'
PKG_DATA_FILES=$(git diff --name-only HEAD ${PKG_BASE_COMMIT} | egrep ${PKG_DATA_EXTENSIONS})

PKG_FILE_NAME="maethrillian.pkg"
PKG_FILE_PATH="${PKG_BUNDLE_DIR}/${PKG_FILE_NAME}"
PKG_FILE_MANIFEST="${PKG_BUNDLE_DIR}/${GAME_VERSION}_file_manifest.xml"
PKG_ARCHIVE="maethrillian.zip"

set -x
set -e

cd ${ROOT_DIR}

rm -rf ${PKG_BUILD_DIR}
mkdir -p ${PKG_DIFF_DIR} ${PKG_BUNDLE_DIR}
cp --parents ${PKG_DATA_FILES} ${PKG_DIFF_DIR}

${ANCILLA_CMD} package -o ${PKG_FILE_PATH} ${PKG_DIFF_DIR}

PKG_PUBLISHED_UTC=$(date +%s)
PKG_PUBLISHED_UTC_TEXT=$(date -u)
PKG_FILE_CHECKSUM=$((16#$(crc32 ${PKG_FILE_PATH})))

cat >${PKG_FILE_MANIFEST} <<EOF
<manifest published_utc="${PKG_PUBLISHED_UTC}" published_utc_str="${PKG_PUBLISHED_UTC_TEXT}">
	<file action="replace" crc32="${PKG_FILE_CHECKSUM}" new="${PKG_FILE_NAME}" old="${PKG_FILE_NAME}" size="0" time="0" version="1" />
</manifest>
EOF

cd ${PKG_BUILD_DIR} && zip -r ${PKG_ARCHIVE} GTS
