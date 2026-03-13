#!/bin/bash

# ==================== 配置项 ====================
WEB_DIR="/webroot"
BACKUP_DIR="/backup/web"
LOG_FILE="/var/log/deploy/deploy.log"
NGINX_SERVICE="nginx"
TEST_URL="http://localhost"
# =================================================

# 时间戳
DATE=$(date +%Y%m%d_%H%M%S)

# 日志函数
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

# ==================== 1. 参数/环境检查 ====================
if [ $EUID -ne 0 ]; then
  echo "请用 root 运行！"
  exit 1
fi

log "===== 开始部署 ====="

# ==================== 2. 备份当前版本 ====================
BACKUP_FILE="$BACKUP_DIR/web_$DATE.tar.gz"
log "备份当前网站到 $BACKUP_FILE"
tar -zcf $BACKUP_FILE -C / webroot

if [ $? -ne 0 ]; then
  log "备份失败，退出部署"
  exit 1
fi

# ==================== 3. 部署新版本 ====================
# 这里模拟拉取新版本，你也可以改成 scp/rsync/git pull
log "开始部署新版本"
echo "<h1>New Version 2.0 - Deploy Success</h1>" > $WEB_DIR/index.html

# ==================== 4. 重启 Nginx ====================
log "重启 $NGINX_SERVICE"
systemctl restart $NGINX_SERVICE

if [ $? -ne 0 ]; then
  log "Nginx 启动失败，开始回滚"
  tar -zxf $BACKUP_FILE -C /
  systemctl restart $NGINX_SERVICE
  log "回滚完成"
  exit 1
fi

# ==================== 5. 检查部署是否成功 ====================
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $TEST_URL)

if [ "$HTTP_CODE" == "200" ]; then
  log "部署成功！HTTP 状态码：$HTTP_CODE"
else
  log "部署失败！HTTP 状态码：$HTTP_CODE，开始回滚"
  tar -zxf $BACKUP_FILE -C /
  systemctl restart $NGINX_SERVICE
  log "回滚完成"
  exit 1
fi

log "===== 部署完成 ====="
