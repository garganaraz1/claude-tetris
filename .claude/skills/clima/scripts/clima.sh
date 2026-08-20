#!/usr/bin/env bash
# Consulta el clima actual de una ciudad usando APIs públicas, sin API key,
# y lo muestra en un cuadro prolijo con colores.
# Uso: clima.sh ["Ciudad,Pais"]   (default: Queretaro,Mexico)

set -uo pipefail

CIUDAD="${1:-Queretaro,Mexico}"
CIUDAD_URL="${CIUDAD// /+}"

ANCHO=46

# Colores (desactivables con NO_COLOR=1)
if [[ -z "${NO_COLOR:-}" ]]; then
  C_BORDE=$'\033[36m'    # cian
  C_TITULO=$'\033[1;37m' # blanco negrita
  C_DATO=$'\033[1;33m'   # amarillo negrita
  C_RESET=$'\033[0m'
else
  C_BORDE=''; C_TITULO=''; C_DATO=''; C_RESET=''
fi

borde() {
  printf '%s' "$C_BORDE$1"
  printf -- '─%.0s' $(seq 1 "$ANCHO")
  printf '%s\n' "$2$C_RESET"
}

caja() {
  local titulo="$1"; shift
  borde '╭' '╮'
  printf '%s│%s %s%s%s\n' "$C_BORDE" "$C_RESET" "$C_TITULO" "$titulo" "$C_RESET"
  printf '%s│%s\n' "$C_BORDE" "$C_RESET"
  for l in "$@"; do
    printf '%s│%s %s\n' "$C_BORDE" "$C_RESET" "$l"
  done
  borde '╰' '╯'
}

caja_error() {
  borde '╭' '╮'
  printf '%s│%s %s⚠ %s%s\n' "$C_BORDE" "$C_RESET" $'\033[1;31m' "$1" "$C_RESET"
  borde '╰' '╯'
}

# Pronóstico 3 días vía wttr.in JSON (j1), requiere jq
pronostico_lineas=()
forecast_json=$(curl -s --max-time 8 "https://wttr.in/${CIUDAD_URL}?format=j1" 2>/dev/null)
if [[ -n "$forecast_json" ]] && echo "$forecast_json" | jq -e '.weather' >/dev/null 2>&1; then
  nombres_dia=("Hoy" "Mañana" "Pasado mañana")
  for i in 0 1 2; do
    dia_json=$(echo "$forecast_json" | jq -c ".weather[$i] // empty" 2>/dev/null)
    [[ -z "$dia_json" || "$dia_json" == "null" ]] && continue
    tmax=$(echo "$dia_json" | jq -r '.maxtempC')
    tmin=$(echo "$dia_json" | jq -r '.mintempC')
    desc=$(echo "$dia_json" | jq -r '.hourly[4].weatherDesc[0].value // .hourly[0].weatherDesc[0].value // "N/D"')
    pronostico_lineas+=("${nombres_dia[$i]}: ${desc}, ${C_DATO}${tmin}°C/${tmax}°C${C_RESET}")
  done
fi

# Intento 1: wttr.in (rápido, sin dependencias)
resultado=$(curl -s --max-time 8 "https://wttr.in/${CIUDAD_URL}?format=%l|%c|%C|%t|%f|%h|%w&M" 2>/dev/null)

if [[ -n "$resultado" && "$resultado" != *"Unknown location"* && "$resultado" != *"ERROR"* && "$resultado" == *"|"* ]]; then
  IFS='|' read -r loc icon cond temp feels hum wind <<< "$resultado"
  lineas=(
    "${C_DATO}${cond}${C_RESET}"
    "🌡️  Temperatura: ${C_DATO}${temp}${C_RESET}  (sensación ${feels})"
    "💧 Humedad: ${C_DATO}${hum}${C_RESET}"
    "💨 Viento: ${C_DATO}${wind}${C_RESET}"
  )
  if (( ${#pronostico_lineas[@]} > 0 )); then
    lineas+=("" "📅 Pronóstico:" "${pronostico_lineas[@]}")
  fi
  caja "${icon}  Clima en ${loc}" "${lineas[@]}"
  exit 0
fi

# Intento 2 (fallback): Open-Meteo (geocoding + forecast), requiere jq
geo=$(curl -s --max-time 8 "https://geocoding-api.open-meteo.com/v1/search?name=${CIUDAD}&count=1&language=es")
lat=$(echo "$geo" | jq -r '.results[0].latitude // empty')
lon=$(echo "$geo" | jq -r '.results[0].longitude // empty')
nombre=$(echo "$geo" | jq -r '.results[0].name // empty')
pais=$(echo "$geo" | jq -r '.results[0].country // empty')

if [[ -z "$lat" || -z "$lon" ]]; then
  caja_error "No se pudo obtener el clima para '${CIUDAD}'."
  exit 1
fi

clima=$(curl -s --max-time 8 "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,wind_speed_10m&daily=weathercode,temperature_2m_max,temperature_2m_min&forecast_days=3&timezone=auto")

temp=$(echo "$clima" | jq -r '.current.temperature_2m // "N/A"')
hum=$(echo "$clima" | jq -r '.current.relative_humidity_2m // "N/A"')
viento=$(echo "$clima" | jq -r '.current.wind_speed_10m // "N/A"')

lineas=(
  "🌡️  Temperatura: ${C_DATO}${temp}°C${C_RESET}"
  "💧 Humedad: ${C_DATO}${hum}%${C_RESET}"
  "💨 Viento: ${C_DATO}${viento} km/h${C_RESET}"
)

pronostico_lineas=()
nombres_dia=("Hoy" "Mañana" "Pasado mañana")
for i in 0 1 2; do
  tmax=$(echo "$clima" | jq -r ".daily.temperature_2m_max[$i] // empty")
  tmin=$(echo "$clima" | jq -r ".daily.temperature_2m_min[$i] // empty")
  [[ -z "$tmax" || -z "$tmin" ]] && continue
  pronostico_lineas+=("${nombres_dia[$i]}: ${C_DATO}${tmin}°C/${tmax}°C${C_RESET}")
done
if (( ${#pronostico_lineas[@]} > 0 )); then
  lineas+=("" "📅 Pronóstico:" "${pronostico_lineas[@]}")
fi

caja "🌎  Clima en ${nombre}, ${pais}" "${lineas[@]}"
