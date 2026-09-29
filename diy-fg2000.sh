#!/bin/bash

# 移除要替换的包
# 移除luci-app-attendedsysupgrade软件包
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# 添加额外插件
#git clone --depth=1 https://github.com/kongfl888/luci-app-adguardhome package/luci-app-adguardhome
#git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash
git_sparse_clone master https://github.com/kenzok8/openwrt-packages luci-app-adguardhome adguardhome
#git_sparse_clone main https://github.com/kenzok8/small-package luci-app-floatip floatip
git clone https://github.com/eamonxg/luci-theme-aurora.git package/luci-theme-aurora
git clone https://github.com/eamonxg/luci-app-aurora-config.git package/luci-app-aurora-config

# 加入新储存库
#echo "src-git rtp2httpd https://github.com/stackia/rtp2httpd.git" >> "feeds.conf.default"

echo "
# 插件
CONFIG_PACKAGE_luci-app-adguardhome=y
CONFIG_PACKAGE_luci-app-adguardhome_INCLUDE_binary=y
CONFIG_PACKAGE_luci-app-wechatpush=y
CONFIG_PACKAGE_luci-app-keepalived=y
CONFIG_PACKAGE_luci-app-sqm=y
CONFIG_PACKAGE_luci-app-watchcat=y
CONFIG_PACKAGE_luci-theme-aurora=y
CONFIG_PACKAGE_luci-app-aurora-config=y

# === 内核模块（本机增量，2026-09-29）===
# ① 必需：sing-box / Open-Box 的 TUN 透明代理需要 tun 驱动。
#    官方 configs/fg2000.config 里没有它，导致 TUN 模式无法使用。
CONFIG_PACKAGE_kmod-tun=y
# ② 建议：TProxy 模式（比 TUN 少一层转发、性能更好）。三项一起开才会导出内核符号
#    （否则会出现 Unknown symbol udp4_lib_lookup / nf_tproxy_laddr4 之类的加载失败）。
CONFIG_PACKAGE_kmod-nft-tproxy=y
CONFIG_PACKAGE_kmod-nf-tproxy=y
CONFIG_PACKAGE_kmod-nft-socket=y
CONFIG_PACKAGE_kmod-nft-queue=y
# === 内核模块 END ===
" >> .config

# 修改默认IP
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# 更改默认 Shell 为 zsh
# sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd

# TTYD 免登录
# sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 修改默认主题
sed -i 's/luci-theme-design/luci-theme-aurora/g' feeds/luci/collections/luci/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-aurora/g' feeds/luci/collections/luci/Makefile

# 更改 Argon 主题背景
# cp -f $GITHUB_WORKSPACE/images/bg1.jpg package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg

# 加入OpenClash核心
#chmod -R a+x $GITHUB_WORKSPACE/preset-clash-core.sh
#$GITHUB_WORKSPACE/preset-clash-core.sh

./scripts/feeds update -a
./scripts/feeds install -a
