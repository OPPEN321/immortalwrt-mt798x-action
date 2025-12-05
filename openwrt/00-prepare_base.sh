#!/bin/bash -e

# 修复 Rust 错误
sed -i 's/ci-llvm=true/ci-llvm=false/g' feeds/packages/lang/rust/Makefile

# default LAN IP
sed -i "s/192.168.1.1/$LAN/g" package/base-files/files/bin/config_generate

# default password
if [ -n "$ROOT_PASSWORD" ]; then
    # sha256 encryption
    default_password=$(openssl passwd -5 $ROOT_PASSWORD)
    sed -i "s|^root:[^:]*:|root:${default_password}:|" package/base-files/files/etc/shadow
fi

# TTYD
sed -i 's/services/system/g' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i '3 a\\t\t"order": 50,' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i 's/procd_set_param stdout 1/procd_set_param stdout 0/g' feeds/packages/utils/ttyd/files/ttyd.init
sed -i 's/procd_set_param stderr 1/procd_set_param stderr 0/g' feeds/packages/utils/ttyd/files/ttyd.init

# luci-mod extra
pushd feeds/luci
    curl -s $mirror/openwrt/patch/luci/0001-luci-mod-system-add-modal-overlay-dialog-to-reboot.patch | patch -p1
    curl -s $mirror/openwrt/patch/luci/0002-luci-mod-status-displays-actual-process-memory-usage.patch | patch -p1
    curl -s $mirror/openwrt/patch/luci/0003-luci-mod-status-storage-index-applicable-only-to-val.patch | patch -p1
    curl -s $mirror/openwrt/patch/luci/0004-luci-mod-status-firewall-disable-legacy-firewall-rul.patch | patch -p1
    curl -s $mirror/openwrt/patch/luci/0005-luci-mod-system-add-refresh-interval-setting.patch | patch -p1
    curl -s $mirror/openwrt/patch/luci/0006-luci-mod-system-mounts-add-docker-directory-mount-po.patch | patch -p1
    curl -s $mirror/openwrt/patch/luci/0007-luci-mod-system-add-ucitrack-luci-mod-system-zram.js.patch | patch -p1
popd

# Luci diagnostics.js
sed -i "s/openwrt.org/www.qq.com/g" feeds/luci/modules/luci-mod-network/htdocs/luci-static/resources/view/network/diagnostics.js

# profile
sed -i 's#\\u@\\h:\\w\\\$#\\[\\e[32;1m\\][\\u@\\h\\[\\e[0m\\] \\[\\033[01;34m\\]\\W\\[\\033[00m\\]\\[\\e[32;1m\\]]\\[\\e[0m\\]\\\$#g' package/base-files/files/etc/profile
sed -ri 's/(export PATH=")[^"]*/\1%PATH%:\/opt\/bin:\/opt\/sbin:\/opt\/usr\/bin:\/opt\/usr\/sbin/' package/base-files/files/etc/profile
sed -i '/ENV/i\export TERM=xterm-color' package/base-files/files/etc/profile

# bash
sed -i 's#ash#bash#g' package/base-files/files/etc/passwd
sed -i '\#export ENV=/etc/shinit#a export HISTCONTROL=ignoredups' package/base-files/files/etc/profile
mkdir -p files/root
curl -so files/root/.bash_profile $mirror/openwrt/files/root/.bash_profile
curl -so files/root/.bashrc $mirror/openwrt/files/root/.bashrc

# NTP
sed -i 's/0.openwrt.pool.ntp.org/ntp1.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/1.openwrt.pool.ntp.org/ntp2.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/2.openwrt.pool.ntp.org/time1.cloud.tencent.com/g' package/base-files/files/bin/config_generate
sed -i 's/3.openwrt.pool.ntp.org/time2.cloud.tencent.com/g' package/base-files/files/bin/config_generate

# luci-theme-bootstrap
sed -i 's/font-size: 13px/font-size: 14px/g' feeds/luci/themes/luci-theme-bootstrap/htdocs/luci-static/bootstrap/cascade.css
sed -i 's/9.75px/10.75px/g' feeds/luci/themes/luci-theme-bootstrap/htdocs/luci-static/bootstrap/cascade.css

# Status page enhancement: add social and firmware links
cat << 'EOF' >> feeds/luci/modules/luci-mod-status/ucode/template/admin_status/index.ut
<script>
function addLinks() {
    var section = document.querySelector(".cbi-section");
    if (section) {
        // 创建表格容器
        var table = document.createElement('div');
        table.className = 'table';
        
        // 创建行
        var row = document.createElement('div');
        row.className = 'tr';
        
        // 左列：帮助与反馈
        var leftCell = document.createElement('div');
        leftCell.className = 'td left';
        leftCell.style.width = '33%';
        leftCell.textContent = '帮助与反馈';
        
        // 右列：三个按钮
        var rightCell = document.createElement('div');
        rightCell.className = 'td left';
        
        // 创建QQ交流群按钮
        var qqLink = document.createElement('a');
        qqLink.href = 'https://qm.qq.com/q/JbBVnkjzKa';
        qqLink.target = '_blank';
        qqLink.className = 'cbi-button';
        qqLink.style.marginRight = '10px';
        qqLink.textContent = 'QQ交流群';
        
        // 创建TG交流群按钮
        var tgLink = document.createElement('a');
        tgLink.href = 'https://t.me/kejizero';
        tgLink.target = '_blank';
        tgLink.className = 'cbi-button';
        tgLink.style.marginRight = '10px';
        tgLink.textContent = 'TG交流群';
        
        // 创建固件地址按钮
        var firmwareLink = document.createElement('a');
        firmwareLink.href = 'https://openwrt.kejizero.online';
        firmwareLink.target = '_blank';
        firmwareLink.className = 'cbi-button';
        firmwareLink.textContent = '固件地址';
        
        // 组装元素
        rightCell.appendChild(qqLink);
        rightCell.appendChild(tgLink);
        rightCell.appendChild(firmwareLink);
        
        row.appendChild(leftCell);
        row.appendChild(rightCell);
        table.appendChild(row);
        section.appendChild(table);
    } else {
        setTimeout(addLinks, 100);
    }
}

document.addEventListener("DOMContentLoaded", addLinks);
</script>
EOF

# Custom firmware version and author metadata
sed -i "s/DISTRIB_DESCRIPTION='*.*'/DISTRIB_DESCRIPTION='ZeroWrt-$(date +%Y%m%d)'/g"  package/base-files/files/etc/openwrt_release
sed -i "s/DISTRIB_REVISION='*.*'/DISTRIB_REVISION=' By OPPEN321'/g" package/base-files/files/etc/openwrt_release
sed -i "s|^OPENWRT_RELEASE=\".*\"|OPENWRT_RELEASE=\"ZeroWrt 标准版 @R$(date +%Y%m%d) BY OPPEN321\"|" package/base-files/files/usr/lib/os-release
