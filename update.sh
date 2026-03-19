#!/bin/bash
echo "Updating Wealthfolio..."
echo "Pulling latest image..."
docker-compose pull wealthfolio

echo "Recreating containers..."
docker-compose up -d --force-recreate wealthfolio

echo "Wealthfolio updated successfully!"