---
name: clima
description: >
  Consulta el clima actual y el pronóstico de los próximos 3 días (hoy, mañana,
  pasado mañana) de una ciudad ejecutando un script local (scripts/clima.sh) que
  llama a APIs públicas gratuitas (wttr.in, con fallback a Open-Meteo), sin
  necesidad de WebSearch ni API keys. Ciudad por defecto: Querétaro, México.
  Usar cuando el usuario pregunte por el clima, la temperatura, el pronóstico,
  o invoque /clima.
---

Ejecutá el script local `scripts/clima.sh` (relativo a esta skill) para obtener el
clima actual, en vez de usar WebSearch.

## Uso

```bash
.claude/skills/clima/scripts/clima.sh ["Ciudad,Pais"]
```

- Sin argumentos, consulta **Queretaro,Mexico** (ciudad del usuario).
- Con argumento, consulta la ciudad indicada, formato `"Ciudad,Pais"` (ej. `"Buenos Aires,Argentina"`).

## Cómo responder

1. Corré el script con Bash.
2. El script ya imprime un cuadro prolijo (bordes Unicode + colores) con
   temperatura actual, sensación térmica, humedad, viento y, debajo, el
   pronóstico (mín/máx) de hoy, mañana y pasado mañana. Mostrá esa salida tal
   cual, sin reformatearla en prosa ni resumirla. Podés agregar un comentario
   breve en español argentino después, si corresponde (ej. "llevate paraguas").
3. Si el script falla (sin conexión, ciudad no encontrada), avisá el motivo en
   vez de inventar un dato. Si el pronóstico no está disponible pero sí el
   clima actual, el cuadro se muestra igual, solo sin la sección de pronóstico.

## Notas técnicas

- Intenta primero `wttr.in` (rápido, no requiere dependencias): clima actual vía
  `?format=...` y pronóstico de 3 días vía `?format=j1` (requiere `jq`).
- Si falla, hace fallback a la API de geocoding + forecast de `open-meteo.com`
  (requiere `jq`, instalado en este entorno), pidiendo `forecast_days=3` para
  el pronóstico.
- No requiere API key en ningún caso.
