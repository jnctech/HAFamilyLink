#!/usr/bin/with-contenv bashio
# ==============================================================================
# Start Family Link Auth Service
# ==============================================================================

bashio::log.info "Starting Google Family Link Auth Service..."

# Read configuration from Home Assistant
LOG_LEVEL=$(bashio::config 'log_level' 'info')
AUTH_TIMEOUT=$(bashio::config 'auth_timeout' '300')
SESSION_DURATION=$(bashio::config 'session_duration' '86400')

# Export environment variables
export LOG_LEVEL="${LOG_LEVEL}"
export AUTH_TIMEOUT="${AUTH_TIMEOUT}"
export SESSION_DURATION="${SESSION_DURATION}"

bashio::log.info "Configuration loaded:"
bashio::log.info "  - Log Level: ${LOG_LEVEL}"
bashio::log.info "  - Auth Timeout: ${AUTH_TIMEOUT}s"
bashio::log.info "  - Session Duration: ${SESSION_DURATION}s"

# Ensure shared directory exists
mkdir -p /share/familylink
chmod 700 /share/familylink

bashio::log.info "Shared storage ready at /share/familylink"

# Start Xvfb (virtual display)
# Using 16-bit color depth for better VM compatibility and lower memory usage
bashio::log.info "Starting virtual display (Xvfb)..."
Xvfb :99 -screen 0 1280x1024x16 -ac -nolisten tcp &
export DISPLAY=:99

# Wait for Xvfb to start
sleep 2

# Start window manager
fluxbox &

# Start VNC server (localhost only, used by noVNC)
bashio::log.info "Starting VNC backend on localhost:5900..."
x11vnc -display :99 -forever -shared -rfbport 5900 -passwd familylink -localhost &

# Start noVNC (web-based VNC viewer)
bashio::log.info "Starting noVNC on port 6080..."
websockify --web=/usr/share/novnc 6080 localhost:5900 &
bashio::log.info "noVNC available at http://[HOST]:6080/vnc.html"

bashio::log.info "Starting FastAPI application..."

# Start the FastAPI application with uvicorn directly
cd /app || exit 1
exec uvicorn app.main:app \
    --host 0.0.0.0 \
    --port 8099 \
    --log-level "${LOG_LEVEL}" \
    --no-access-log \
    --workers 1
