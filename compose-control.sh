#!/bin/bash
set -e

ACTION=${1:-start}

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"

case "$ACTION" in
    start)
        echo "🚀 Khoi dong he thong QuickBite qua Docker Compose..."
        docker compose up -d --build

        echo "⏳ Kiem tra trang thai Database (PostgreSQL)..."
        TIMEOUT=10
        ELAPSED=0
        DB_READY=false

        while [ $ELAPSED -lt $TIMEOUT ]; do
            if docker compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
                DB_READY=true
                break
            fi
            sleep 2
            ELAPSED=$((ELAPSED + 2))
        done

        if [ "$DB_READY" = false ]; then
            echo -e "${RED}[ERROR] Timeout 10s: Database chua san sang!${NC}"
            echo "--- 20 DONG LOG CUOI CUA BACKEND ---"
            docker compose logs --tail=20 backend
            docker compose down
            exit 1
        fi

        echo "🔍 Kiem tra Backend Health Check (/actuator/health)..."
        sleep 2
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/actuator/health || true)

        if [ "$HTTP_CODE" = "200" ]; then
            echo -e "${GREEN}HỆ THỐNG QUICKBITE HOẠT ĐỘNG ỔN ĐỊNH!${NC}"
            exit 0
        else
            echo -e "${RED}[ERROR] Backend health check that bai (HTTP Code: $HTTP_CODE)!${NC}"
            echo "--- 20 DONG LOG CUOI CUA BACKEND ---"
            docker compose logs --tail=20 backend
            docker compose down
            exit 1
        fi
        ;;

    stop)
        echo "⏹️ Tam dung tat ca containers..."
        docker compose stop
        ;;

    clean)
        echo "🧹 Don dep sach se containers va volumes..."
        docker compose down -v
        ;;

    *)
        echo "Su dung: ./compose-control.sh [start | stop | clean]"
        exit 1
        ;;
esac
