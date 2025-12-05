#!/bin/bash -e

# 移除要替换的包
rm -rf feeds/luci/applications/luci-app-appfilter
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/packages/net/open-app-filter
rm -rf feeds/packages/lang/golang

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# Go 1.25
git clone --depth=1 https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# OpenList 
git clone --depth=1 https://github.com/sbwml/luci-app-openlist2 package/openlist

# Mosdns
git clone --depth=1 -b v5 https://github.com/sbwml/luci-app-mosdns package/mosdns
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# Adguardhome
git clone --depth=1 https://github.com/sirpdboy/luci-app-adguardhome package/luci-app-adguardhome
sed -i "s/\(option enabled '\)1'/\10'/" package/luci-app-adguardhome/luci-app-adguardhome/root/etc/config/AdGuardHome

# 挂载插件
git clone --depth=1 https://github.com/sirpdboy/luci-app-partexp.git package/luci-app-partexp

# 一键唤醒
git_sparse_clone main https://github.com/sbwml/openwrt_pkgs luci-app-wolplus

# Lucky
git clone --depth=1 https://github.com/gdy666/luci-app-lucky package/luci-app-lucky

# OpenAppFilter
git clone --depth=1 https://github.com/destan19/OpenAppFilter.git package/OpenAppFilter

# Argon 主题
git clone --depth=1 https://github.com/QuickWrt/luci-theme-argon package/luci-theme-argon

# luci-app-bandix
git clone https://$github/timsaya/luci-app-bandix package/new/luci-app-bandix

# openwrt-bandix
git clone https://$github/timsaya/openwrt-bandix package/new/openwrt-bandix

./scripts/feeds update -a
./scripts/feeds install -a
