#!/bin/bash
# Judgels Management Script
# Location: ~/judgels-compose/manage.sh
# Usage: ./manage.sh [start|stop|restart|logs|status|shell]

set -e
COMPOSE_DIR="$(dirname "$(realpath "$0")")"

case "$1" in
  start)
    echo "▶  Starting Judgels..."
    docker compose -f "$COMPOSE_DIR/docker-compose.yml" up -d
    echo ""
    echo "✅ Judgels is running!"
    echo "   Frontend:  http://localhost"
    echo "   API:       http://localhost/api/v2"
    echo "   RabbitMQ:  http://localhost:15672  (user: judgelsuser / password)"
    echo "   MailHog:   http://localhost:8025   (view registration & activation emails)"
    echo ""
    echo "   Default admin login: superadmin / superadminpass"
    ;;
  stop)
    echo "⏹  Stopping Judgels..."
    docker compose -f "$COMPOSE_DIR/docker-compose.yml" down
    echo "✅ Judgels stopped."
    ;;
  restart)
    echo "🔄 Restarting Judgels..."
    docker compose -f "$COMPOSE_DIR/docker-compose.yml" down
    docker compose -f "$COMPOSE_DIR/docker-compose.yml" up -d
    echo "✅ Judgels restarted!"
    ;;
  logs)
    SERVICE="${2:-}"
    if [ -n "$SERVICE" ]; then
      docker compose -f "$COMPOSE_DIR/docker-compose.yml" logs -f "$SERVICE"
    else
      docker compose -f "$COMPOSE_DIR/docker-compose.yml" logs -f
    fi
    ;;
  status)
    docker compose -f "$COMPOSE_DIR/docker-compose.yml" ps
    ;;
  shell)
    SERVICE="${2:-judgels-server}"
    docker exec -it "$SERVICE" /bin/sh
    ;;
  pull)
    echo "📥 Pulling latest images..."
    docker compose -f "$COMPOSE_DIR/docker-compose.yml" pull
    echo "✅ Images updated! Run './manage.sh restart' to apply."
    ;;
  verify-user)
    TARGET_USER="${2:-}"
    if [ -z "$TARGET_USER" ]; then
      echo "❌ Usage: $0 verify-user <username>"
      exit 1
    fi
    if [ -f "$COMPOSE_DIR/.env" ]; then
      set -a
      . "$COMPOSE_DIR/.env"
      set +a
    fi
    docker compose -f "$COMPOSE_DIR/docker-compose.yml" exec -e MYSQL_PWD="${DB_PASSWORD:-password}" judgels-db mysql -u "${DB_USER:-judgelsuser}" "${DB_NAME:-judgels}" -e "UPDATE jophiel_user_registration_email r JOIN jophiel_user u ON r.userJid = u.jid SET r.verified = 1 WHERE u.username = '$TARGET_USER';"
    echo "✅ User '$TARGET_USER' has been verified!"
    ;;
  rebuild-client)
    echo "🔨 Rebuilding Judgels Client (React SPA)..."
    (cd "$COMPOSE_DIR/../judgels/judgels-client" && npm run build)
    docker compose -f "$COMPOSE_DIR/docker-compose.yml" restart judgels-client
    echo "✅ Judgels Client rebuilt and reloaded!"
    ;;
  *)
    echo "╔══════════════════════════════════════╗"
    echo "║      Judgels Management Script       ║"
    echo "╚══════════════════════════════════════╝"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  start          Start all services"
    echo "  stop           Stop all services"
    echo "  restart        Restart all services"
    echo "  logs [svc]     Follow logs (optionally for a specific service)"
    echo "  status         Show container status"
    echo "  shell [svc]    Open a shell in a container"
    echo "  pull           Pull latest Docker images"
    echo "  verify-user <u> Directly verify/activate a registered user"
    echo "  rebuild-client Rebuild Judgels Client SPA from source"
    echo ""
    echo "Services: mysql, rabbitmq, judgels-server, judgels-client, judgels-grader, nginx, mailhog"
    echo ""
    echo "Access URLs:"
    echo "  Frontend:  http://localhost"
    echo "  API:       http://localhost/api/v2"
    echo "  RabbitMQ:  http://localhost:15672"
    echo "  MailHog:   http://localhost:8025"
    ;;
esac
