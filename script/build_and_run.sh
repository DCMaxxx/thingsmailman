#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Things Mailman"
BUNDLE_ID="com.maximedechalendar.ThingsMailman"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$ROOT_DIR/.build/RunBuild"
BUILD_INTERMEDIATES="$ROOT_DIR/.build/RunIntermediates"
HOST_ARCH="$(uname -m)"
APP_BUNDLE="$BUILD_ROOT/Debug/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

usage() {
  echo "usage: $0 [run|--debug|--logs|--telemetry|--verify] [--clear]"
}

MODE="run"
CLEAR_STATE=false

for argument in "$@"; do
  case "$argument" in
    run)
      MODE="run"
      ;;
    --debug|debug)
      MODE="debug"
      ;;
    --logs|logs)
      MODE="logs"
      ;;
    --telemetry|telemetry)
      MODE="telemetry"
      ;;
    --verify|verify)
      MODE="verify"
      ;;
    --clear)
      CLEAR_STATE=true
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

if [[ "$CLEAR_STATE" == true ]]; then
  /usr/bin/defaults delete "$BUNDLE_ID" >/dev/null 2>&1 || true
  /usr/bin/tccutil reset AppleEvents "$BUNDLE_ID"
  echo "Cleared $APP_NAME preferences and Apple Events authorization"
fi

xcodebuild build \
  -project "$ROOT_DIR/ThingsMailman.xcodeproj" \
  -target ThingsMailman \
  -configuration Debug \
  -sdk macosx \
  ONLY_ACTIVE_ARCH=YES \
  ARCHS="$HOST_ARCH" \
  SYMROOT="$BUILD_ROOT" \
  OBJROOT="$BUILD_INTERMEDIATES"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  debug)
    lldb -- "$APP_BINARY"
    ;;
  logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  verify)
    open_app
    for _ in {1..20}; do
      if pgrep -x "$APP_NAME" >/dev/null; then
        echo "$APP_NAME launched successfully"
        exit 0
      fi
      /bin/sleep 0.25
    done
    echo "$APP_NAME did not remain running" >&2
    exit 1
    ;;
esac
