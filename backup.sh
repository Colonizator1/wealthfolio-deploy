#!/bin/bash

# Wealthfolio Backup Script
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="wealthfolio_backup_${TIMESTAMP}.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "Creating backup: $BACKUP_FILE"
docker run --rm \
  -v wealthfolio_deploy_wealthfolio-data:/data \
  -v "$(pwd)/$BACKUP_DIR:/backup" \
  alpine tar czf "/backup/$BACKUP_FILE" /data

echo "Backup completed: $BACKUP_DIR/$BACKUP_FILE"
echo "To restore, extract the backup and mount it as a volume."