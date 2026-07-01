#!/bin/bash
# Ports from ENV (passed via docker run -e)
GRPC_PORT="${GRPC_PORT:-8554}"
ENVOY_PORT="${ENVOY_PORT:-8080}"
ENVOY_ADMIN_PORT="${ENVOY_ADMIN_PORT:-8001}"
NGINX_PORT="${NGINX_PORT:-3000}"

# Generate envoy.yaml
sed -e "s/GRPC_PORT_PLACEHOLDER/${GRPC_PORT}/g" \
    -e "s/ENVOY_PORT_PLACEHOLDER/${ENVOY_PORT}/g" \
    -e "s/ENVOY_ADMIN_PORT_PLACEHOLDER/${ENVOY_ADMIN_PORT}/g" \
    /etc/envoy/envoy.yaml.template > /etc/envoy/envoy.yaml

# Generate nginx config
cat > /etc/nginx/sites-available/default << EOF
server {
    listen ${NGINX_PORT};
    root /var/www/html;
    index index.html;
    location / {
        try_files \$uri /index.html;
    }
}
EOF

echo "Starting nginx on port ${NGINX_PORT}..."
nginx &

# base-id for Envoy to avoid shared memory conflicts
ENVOY_BASE_ID="${ENVOY_BASE_ID:-$((ENVOY_PORT - 8080))}"

echo "Starting envoy: ENVOY_PORT=${ENVOY_PORT} -> GRPC_PORT=${GRPC_PORT} (admin: ${ENVOY_ADMIN_PORT}, base-id: ${ENVOY_BASE_ID})"
envoy -c /etc/envoy/envoy.yaml --base-id ${ENVOY_BASE_ID} &

exec /entrypoint.sh
