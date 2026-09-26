#!/bin/bash
#
# DIY script - part 2 (runs inside openwrt/ source dir)


# 1. 默认 root 密码设为 password
[ -f package/base-files/files/etc/shadow ] && sed -i 's#^root:[^:]*:.*#root:$1$wEehtjxj$YBu4quNfVUxvTRkVw7Ql/:0:0:99999:7:::#' package/base-files/files/etc/shadow


# 2. 首次开机默认设置：中文 + Argon 主题
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/zzz-default-settings <<'UCI_EOF'
#!/bin/sh
uci set luci.main.lang='zh_cn'
uci set luci.main.mediaurlbase='/luci-static/argon'
uci commit luci
exit 0
UCI_EOF
chmod +x files/etc/uci-defaults/zzz-default-settings


# 3. 预置 OpenClash Meta（mihomo）内核
mkdir -p files/etc/openclash/core
# 优先从 GitHub API 取最新版；API 限流/失败时回退到固定版本，保证内核一定能预置
MIHOMO_URL="$(curl -sL --max-time 30 https://api.github.com/repos/MetaCubeX/mihomo/releases/latest | grep '"browser_download_url":' | grep 'linux-amd64' | grep '\.gz"' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')"
[ -z "$MIHOMO_URL" ] && MIHOMO_URL="https://github.com/MetaCubeX/mihomo/releases/download/v1.19.31/mihomo-linux-amd64-compatible-v1.19.31.gz"
if [ -n "$MIHOMO_URL" ]; then
  if curl -sL "$MIHOMO_URL" -o /tmp/mihomo.gz; then
    if gunzip -c /tmp/mihomo.gz > files/etc/openclash/core/clash_meta 2>/dev/null; then
      chmod +x files/etc/openclash/core/clash_meta
      if ! ./files/etc/openclash/core/clash_meta -v >/dev/null 2>&1; then
        echo "mihomo core test failed, removing"
        rm -f files/etc/openclash/core/clash_meta
      fi
    fi
    rm -f /tmp/mihomo.gz
  fi
fi


# 4. 预置 OpenClash Geo 数据库
mkdir -p files/etc/openclash
curl -sL --max-time 120 https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb -o files/etc/openclash/Country.mmdb
curl -sL --max-time 120 https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -o files/etc/openclash/GeoIP.dat
curl -sL --max-time 120 https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -o files/etc/openclash/GeoSite.dat
find files/etc/openclash -size 0 -delete
