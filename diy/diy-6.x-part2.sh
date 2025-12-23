#!/bin/bash -e
#===============================================
# Description: DIY script
# File name: diy-script.sh
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#===============================================

# 集成设备无线
mkdir -p package/base-files/files/lib/firmware/brcm
cp -a $GITHUB_WORKSPACE/configfiles/firmware/brcm/* package/base-files/files/lib/firmware/brcm/

# ================================================================
# 移植RK3399示例，其他RK3399可模仿
# ================================================================
# 增加am40设备
echo -e "\\ndefine Device/smart_am40
  DEVICE_VENDOR := SMART
  DEVICE_MODEL := AM40
  SOC := rk3399
  UBOOT_DEVICE_NAME := am40-rk3399
  DEVICE_PACKAGES := wpad-mbedtls kmod-rtw88-8822be kmod-bluetooth kmod-usb-dwc3 \
  kmod-sound-soc-simple-card kmod-sound-soc-rockchip kmod-sound-soc-hdmi-codec \
  kmod-drm-rockchip kmod-drm-panfrost kmod-extcon-usbc-virtual-pd rockchip-cdn-dp-firmware
  DEVICE_DTS_DIR := ../dts
  DEVICE_DTS = rk3399/rk3399-am40
  KERNEL = kernel-bin | lzma | fit lzma $$(KDIR)/image-rk3399-am40.dtb
endef
TARGET_DEVICES += smart_am40" >> target/linux/rockchip/image/armv8.mk

# 替换package/boot/uboot-rockchip/Makefile
cp -f $GITHUB_WORKSPACE/configfiles/uboot-rockchip/Makefile package/boot/uboot-rockchip/Makefile

# 复制dts与配置文件到package/boot/uboot-rockchip
cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3399/{rk3399.dtsi,rk3399-opp.dtsi,rk3399-am40.dts} package/boot/uboot-rockchip/src/arch/arm/dts/
cp -f $GITHUB_WORKSPACE/configfiles/uboot-rockchip/rk3399-am40-u-boot.dtsi package/boot/uboot-rockchip/src/arch/arm/dts/
cp -f $GITHUB_WORKSPACE/configfiles/uboot-rockchip/am40-rk3399_defconfig package/boot/uboot-rockchip/src/configs/

# 复制dts到files/arch/arm64/boot/dts/rockchip
cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3399/{rk3399.dtsi,rk3399-opp.dtsi,rk3399-am40.dts} target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/
cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3399/{rk3399.dtsi,rk3399-opp.dtsi,rk3399-am40.dts} target/linux/rockchip/dts/rk3399/
cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3399/{rk3399.dtsi,rk3399-opp.dtsi,rk3399-am40.dts} package/boot/uboot-rockchip/src/dts/upstream/src/arm64/rockchip/

# 添加dtb补丁到target/linux/rockchip/patches-6.6
cp -f $GITHUB_WORKSPACE/configfiles/patch/800-add-rk3399-am40-dtb-to-makefile.patch target/linux/rockchip/patches-6.6/
# ================================================================
# RK3399示例结束
# ================================================================



# ================================================================
# DIY部分
# ================================================================
# 移除要替换的包
rm -rf feeds/packages/net/adguardhome
rm -rf feeds/third_party/luci-app-LingTiGameAcc
rm -rf feeds/luci/applications/luci-app-filebrowser

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package/new
  cd .. && rm -rf $repodir
}

# 常见插件
git clone -b master https://github.com/w9315273/luci-app-adguardhome package/new/luci-app-adguardhome
git_sparse_clone main https://github.com/sbwml/openwrt_pkgs filebrowser luci-app-filebrowser-go luci-app-ramfree
