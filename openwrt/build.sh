#!/bin/bash -e
export RED_COLOR='\e[1;31m'
export GREEN_COLOR='\e[1;32m'
export YELLOW_COLOR='\e[1;33m'
export BLUE_COLOR='\e[1;34m'
export PINK_COLOR='\e[1;35m'
export SHAN='\e[1;33;5m'
export RES='\e[0m'

GROUP=
group() {
    endgroup
    echo "::group::  $1"
    GROUP=1
}
endgroup() {
    if [ -n "$GROUP" ]; then
        echo "::endgroup::"
    fi
    GROUP=
}

# script url
export mirror=http://127.0.0.1:8080

# private gitea
export gitea="gitea.kejizero.xyz"

# github mirror
export github="github.com"

# Check root
if [ "$(id -u)" = "0" ]; then
    export FORCE_UNSAFE_CONFIGURE=1 FORCE=1
fi

# Start time
starttime=`date +'%Y-%m-%d %H:%M:%S'`
CURRENT_DATE=$(date +%s)

# Cpus
cores=`expr $(nproc --all) + 1`

# CURL_BAR
if curl --help | grep progress-bar >/dev/null 2>&1; then
    CURL_BAR="--progress-bar";
fi

# SUPPORTED_BOARDS
SUPPORTED_BOARDS=$(curl -fsSL $mirror/boards.txt)
if [ -z "$1" ] || ! echo "$SUPPORTED_BOARDS" | grep -qw "$1"; then
    echo -e "\n${RED_COLOR}Unsupported or missing board: '$1'.${RES}\n"
    echo -e "Usage:\n"

    for board in $SUPPORTED_BOARDS; do
        echo -e "$board: ${GREEN_COLOR}bash build.sh $board${RES}"
    done
    echo
    exit 1
fi

# lan
[ -n "$LAN" ] && export LAN=$LAN || export LAN=10.0.0.1

# platform
platform="$1"
toolchain_arch="aarch64_cortex-a53"
export platform toolchain_arch

# build.sh flags
export ROOT_PASSWORD=$ROOT_PASSWORD
export WIFI_NAME=$WIFI_NAME
export WIFI_PASSWORD=$WIFI_PASSWORD

# print version
echo -e "\r\n${GREEN_COLOR}Building $platform${RES}\r\n"
case "$platform" in
    cetron-ct3003)
        echo -e "${GREEN_COLOR}Model: Cetron CT3003 (U-Boot mod)${RES}"
        model="ct3003"
        ;;
    cmcc-a10)
        echo -e "${GREEN_COLOR}Model: CMCC A10 (U-Boot mod)${RES}"
        model="cmcc-a10"
        ;;
    cmcc-rax3000m-emmc)
        echo -e "${GREEN_COLOR}Model: CMCC RAX3000M EMMC${RES}"
        model="cmcc-rax3000m-emmc"
        ;;
    cmcc-rax3000m-nand)
        echo -e "${GREEN_COLOR}Model: CMCC RAX3000M NAND${RES}"
        model="cmcc-rax3000m-nand"
        ;;
    cmcc-rax3000me-nand)
        echo -e "${GREEN_COLOR}Model: CMCC RAX3000ME NAND${RES}"
        model="cmcc-rax3000me-nand"
        ;;        
    umi-uax3000e)
        echo -e "${GREEN_COLOR}Model: UMI-UAX3000E${RES}"
        model="uax3000e"
        ;;        
    h3c-magic-nx30-pro)
        echo -e "${GREEN_COLOR}Model: H3C Magic NX30 Pro${RES}"
        model="nx30-pro"
        ;;
    imou-lc-hx3001)
        echo -e "${GREEN_COLOR}Model: Imou LC-HX3001${RES}"
        model="hx3001"
        ;;
    nokia-ea0326gmp)
        echo -e "${GREEN_COLOR}Model: Nokia EA0326GMP${RES}"
        model="ea0326gmp"
        ;;
    philips-hy3000)
        echo -e "${GREEN_COLOR}Model: Philips HY3000${RES}"
        model="hy3000"
        ;;    
    qihoo-360t7)
        echo -e "${GREEN_COLOR}Model: 360 T7${RES}"
        model="360t7"
        ;;
    xiaomi-mi-router-ax3000t)
        echo -e "${GREEN_COLOR}Model: Xiaomi-Mi-Router-AX3000T${RES}"
        model="mi-ax300t"
        ;;        
    newland-nl-wr8103)
        echo -e "${GREEN_COLOR}Model: Newland-NL-WR8103${RES}"
        model="nl-wr8103"
        ;;
    clx-s20p)
        echo -e "${GREEN_COLOR}Model: CLX S20P${RES}"
        model="s20p"
        ;;
    netcore-n60-pro)
        echo -e "${GREEN_COLOR}Model: Netcore N60 Pro${RES}"
        model="n60-pro"
        ;;
    netcore-n60-pro-512rom)
        echo -e "${GREEN_COLOR}Model: Netcore N60 Pro (512MB ROM)${RES}"
        model="n60-pro-512"
        ;;
    xiaomi-redmi-router-ax6000)
        echo -e "${GREEN_COLOR}Model: Xiaomi-Redmi-Router-AX6000${RES}"
        model="redmi-ax6000"
        ;;
    xiaomi-redmi-router-ax6000-512rom)
        echo -e "${GREEN_COLOR}Model: Xiaomi-Redmi-Router-AX6000 (512MB ROM)${RES}"
        model="redmi-ax6000-512rom"
        ;;        
    jdcloud-re-cp-03)
        echo -e "${GREEN_COLOR}Model: JDCloud RE-CP-03${RES}"
        model="re-cp-03"
        ;;
    all-mt7981-devices)
        echo -e "${GREEN_COLOR}Model: ALL MT7981 Devices${RES}"
        model="all-mt7981-devices"
        ;;
    all-mt7986-devices)
        echo -e "${GREEN_COLOR}Model: ALL MT7986 Devices${RES}"
        model="all-mt7986-devices"
        ;;
    all-high-power-devices)
        echo -e "${GREEN_COLOR}Model: ALL High Power Devices${RES}"
        model="all-high-power-devices"
        ;;
esac

# print build opt
get_kernel_version=$(curl -s $mirror/tags/kernel-6.6)
kmod_hash=$(echo -e "$get_kernel_version" | awk -F'HASH-' '{print $2}' | awk '{print $1}' | tail -1 | md5sum | awk '{print $1}')
kmodpkg_name=$(echo $(echo -e "$get_kernel_version" | awk -F'HASH-' '{print $2}' | awk '{print $1}')~$(echo $kmod_hash)-r1)
echo -e "${GREEN_COLOR}Kernel: $kmodpkg_name ${RES}"
echo -e "${GREEN_COLOR}Date: $CURRENT_DATE${RES}\r\n"
echo -e "${GREEN_COLOR}SCRIPT_URL:${RES} ${BLUE_COLOR}$mirror${RES}\r\n"
echo -e "${GREEN_COLOR}GCC VERSION: 13${RES}"
print_status() {
    local name="$1"
    local value="$2"
    local true_color="${3:-$GREEN_COLOR}"
    local false_color="${4:-$YELLOW_COLOR}"
    local newline="${5:-}"
    if [ "$value" = "y" ]; then
        echo -e "${GREEN_COLOR}${name}:${RES} ${true_color}true${RES}${newline}"
    else
        echo -e "${GREEN_COLOR}${name}:${RES} ${false_color}false${RES}${newline}"
    fi
}
[ -n "$LAN" ] && echo -e "${GREEN_COLOR}LAN:${RES} $LAN" || echo -e "${GREEN_COLOR}LAN:${RES} 10.0.0.1"
[ -n "$ROOT_PASSWORD" ] \
    && echo -e "${GREEN_COLOR}ROOT PASSWORD:${RES} ${BLUE_COLOR}$ROOT_PASSWORD${RES}" \
    || echo -e "${GREEN_COLOR}ROOT PASSWORD:${RES} (${YELLOW_COLOR}No password${RES})"
[ -n "$WIFI_NAME" ] \
    && echo -e "${GREEN_COLOR}WIFI NAME:${RES} ${BLUE_COLOR}$WIFI_NAME${RES}" \
    || echo -e "${GREEN_COLOR}WIFI NAME:${RES} (${YELLOW_COLOR}No WIFI NAME${RES})"
[ -n "$WIFI_PASSWORD" ] \
    && echo -e "${GREEN_COLOR}WIFI NAME:${RES} ${BLUE_COLOR}$WIFI_PASSWORD${RES}" \
    || echo -e "${GREEN_COLOR}WIFI NAME:${RES} (${YELLOW_COLOR}No WIFI PASSWORD${RES})"
print_status "ENABLE_BPF"        "$ENABLE_BPF" "$GREEN_COLOR" "$RED_COLOR"
print_status "BUILD_FAST"        "$BUILD_FAST"
print_status "ENABLE_DOCKER"     "$ENABLE_DOCKER"
print_status "ENABLE_SAMBA4"     "$ENABLE_SAMBA4"

# clean old files
rm -rf openwrt

# openwrt - releases
[ "$(whoami)" = "runner" ] && group "source code"
git clone --depth=1 -b openwrt-24.10 https://$github/QuickWrt/immortalwrt-mt798x.git openwrt

if [ -d openwrt ]; then
    cd openwrt
    curl -Os $mirror/openwrt/patch/key.tar.gz && tar zxf key.tar.gz && rm -f key.tar.gz
else
    echo -e "${RED_COLOR}Failed to download source code${RES}"
    exit 1
fi

# tags
git branch | awk '{print $2}' > version.txt

# Init feeds
[ "$(whoami)" = "runner" ] && group "feeds update -a"
./scripts/feeds update -a
[ "$(whoami)" = "runner" ] && endgroup

[ "$(whoami)" = "runner" ] && group "feeds install -a"
./scripts/feeds install -a
[ "$(whoami)" = "runner" ] && endgroup

# loader dl
if [ -f ../dl.gz ]; then
    tar xf ../dl.gz -C .
fi

###############################################
echo -e "\n${GREEN_COLOR}Patching ...${RES}\n"

# scripts
scripts=(
  00-prepare_base.sh
  01-prepare_package.sh
  02-convert_translation.sh
  10-custom.sh
)
for script in "${scripts[@]}"; do
  curl -sO "$mirror/openwrt/scripts/$script"
done
chmod 0755 *sh
[ "$(whoami)" = "runner" ] && group "patching openwrt"
bash 00-prepare_base.sh
bash 01-prepare_package.sh
bash 10-custom.sh
find feeds -type f -name "*.orig" -exec rm -f {} \;
[ "$(whoami)" = "runner" ] && endgroup

rm -f 0*-*.sh 10-custom.sh

# Load devices Config
case "$platform" in
    cetron-ct3003)
        curl -s $mirror/openwrt/24-config-musl-ct3003 > .config
        ;;
    cmcc-a10)
        curl -s $mirror/openwrt/24-config-musl-a10 > .config
        ;;
    cmcc-rax3000m-emmc)
        curl -s $mirror/openwrt/24-config-musl-rax3000m-emmc > .config
        ;;
    cmcc-rax3000m-nand)
        curl -s $mirror/openwrt/24-config-musl-rax3000m-nand > .config
        ;;
    cmcc-rax3000me-nand)
        curl -s $mirror/openwrt/24-config-musl-rax3000me-nand > .config
        ;;
    umi-uax3000e)
        curl -s $mirror/openwrt/24-config-musl-uax3000e > .config
        ;;
    h3c-magic-nx30-pro)
        curl -s $mirror/openwrt/24-config-musl-nx30-pro > .config
        ;;
    imou-lc-hx3001)
        curl -s $mirror/openwrt/24-config-musl-hx3001 > .config
        ;;
    nokia-ea0326gmp)
        curl -s $mirror/openwrt/24-config-musl-ea0326gmp > .config
        ;;
    philips-hy3000)
        curl -s $mirror/openwrt/24-config-musl-hy3000 > .config
        ;;
    qihoo-360t7)
        curl -s $mirror/openwrt/24-config-musl-360t7 > .config
        ;;
    newland-nl-wr8103)
        curl -s $mirror/openwrt/24-config-musl-nl-wr8103 > .config
        ;;
    xiaomi-mi-router-ax3000t)
        curl -s $mirror/openwrt/24-config-musl-xiaomi-ax3000t > .config
        ;;        
    clx-s20p)
        curl -s $mirror/openwrt/24-config-musl-s20p > .config
        ;;
    netcore-n60-pro)
        curl -s $mirror/openwrt/24-config-musl-n60pro > .config
        ;;
    netcore-n60-pro-512rom)
        curl -s $mirror/openwrt/24-config-musl-n60pro-512rom > .config
        ;;
    xiaomi-redmi-router-ax6000)
        curl -s $mirror/openwrt/24-config-musl-redmi-ax6000 > .config
        ;;
    xiaomi-redmi-router-ax6000-512rom)
        curl -s $mirror/openwrt/24-config-musl-redmi-ax6000-512rom > .config
        ;;
    jdcloud-re-cp-03)
        curl -s $mirror/openwrt/24-config-musl-re-cp-03 > .config
        ;;
    all-mt7981-devices)
        curl -s $mirror/openwrt/24-config-musl-all-mt7981-devices > .config
        ;;
    all-mt7986-devices)
        curl -s $mirror/openwrt/24-config-musl-all-mt7986-devices > .config
        ;;
    all-high-power-devices)
        curl -s $mirror/openwrt/24-config-musl-all-high-power-devices > .config
        ;;
esac

# config-common
case "$platform" in
    cetron-ct3003|cmcc-a10|cmcc-rax3000m-emmc|umi-uax3000e|h3c-magic-nx30-pro|imou-lc-hx3001|nokia-ea0326gmp|philips-hy3000|qihoo-360t7|newland-nl-wr8103|xiaomi-mi-router-ax3000t|all-mt7981-devices)
        curl -s "$mirror/openwrt/24-config-ax3000-common" >> .config
        ;;
    jdcloud-re-cp-03|xiaomi-redmi-router-ax6000|xiaomi-redmi-router-ax6000-512rom|all-mt7986-devices)
        curl -s "$mirror/openwrt/24-config-ax6000-common" >> .config
        ;;
    clx-s20p|netcore-n60-pro|netcore-n60-pro-512rom|all-high-power-devices)
        curl -s "$mirror/openwrt/24-config-ipailna-high-power" >> .config
        ;;
esac

# config-general
curl -s "$mirror/openwrt/24-config-general" >> .config

# bpf
[ "$ENABLE_BPF" = "y" ] && curl -s $mirror/openwrt/generic/config-bpf >> .config

# docker
[ "$ENABLE_DOCKER" = "y" ] && curl -s $mirror/openwrt/generic/config-docker >> .config

# samba4
[ "$ENABLE_SAMBA4" = "y" ] && curl -s $mirror/openwrt/generic/config-samba4 >> .config
    
# Toolchain Cache
if [ "$BUILD_FAST" = "y" ]; then
    echo -e "\n${GREEN_COLOR}Download Toolchain ...${RES}"
    [ -f /etc/os-release ] && source /etc/os-release
    if [ "$(whoami)" = "zhao" ]; then
        TOOLCHAIN_URL="http://127.0.0.1:8080/openwrt_caches"
    else
        TOOLCHAIN_URL="https://github.com/QuickWrt/openwrt_caches/releases/download/openwrt-24.10"
    fi
    curl -L ${TOOLCHAIN_URL}/toolchain_musl_${toolchain_arch}_gcc-13.tar.zst -o toolchain.tar.zst $CURL_BAR
    echo -e "\n${GREEN_COLOR}Process Toolchain ...${RES}"
    tar -I "zstd" -xf toolchain.tar.zst
    rm -f toolchain.tar.zst
    mkdir bin
    find ./staging_dir/ -name '*' -exec touch {} \; >/dev/null 2>&1
    find ./tmp/ -name '*' -exec touch {} \; >/dev/null 2>&1
fi

# init openwrt config
rm -rf tmp/*
make defconfig

# Compile
if [ "$BUILD_TOOLCHAIN" = "y" ]; then
    echo -e "\r\n${GREEN_COLOR}Building Toolchain ...${RES}\r\n"
    make -j$cores toolchain/compile || make -j$cores toolchain/compile V=s || exit 1
    mkdir -p toolchain-cache
    tar -I "zstd -19 -T$(nproc --all)" -cf toolchain-cache/toolchain_musl_${toolchain_arch}_gcc-13.tar.zst ./{build_dir,dl,staging_dir,tmp}
    echo -e "\n${GREEN_COLOR} Build success! ${RES}"
    exit 0
else
    echo -e "\r\n${GREEN_COLOR}Building OpenWrt ...${RES}\r\n"
    sed -i "/BUILD_DATE/d" package/base-files/files/usr/lib/os-release
    sed -i "/BUILD_ID/aBUILD_DATE=\"$CURRENT_DATE\"" package/base-files/files/usr/lib/os-release
    make -j$cores IGNORE_ERRORS="n m"
fi

# Compile time
endtime=`date +'%Y-%m-%d %H:%M:%S'`
start_seconds=$(date --date="$starttime" +%s);
end_seconds=$(date --date="$endtime" +%s);
SEC=$((end_seconds-start_seconds));

if [ -f bin/targets/*/*/sha256sums ]; then
    echo -e "${GREEN_COLOR} Build success! ${RES}"
    echo -e " Build time: $(( SEC / 3600 ))h,$(( (SEC % 3600) / 60 ))m,$(( (SEC % 3600) % 60 ))s"
else
    echo -e "\n${RED_COLOR} Build error... ${RES}"
    echo -e " Build time: $(( SEC / 3600 ))h,$(( (SEC % 3600) / 60 ))m,$(( (SEC % 3600) % 60 ))s"
    echo
    exit 1
fi
