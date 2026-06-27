# Owl — Planificación hacia v1.0

Gestor de paquetes y proyectos para el lenguaje Mire / compilador Avenys.

---

## Índice

1. [Filosofía y principios](#1-filosofía-y-principios)
2. [Referencia completa de flags](#2-referencia-completa-de-flags)
3. [Comportamientos implícitos](#3-comportamientos-implícitos)
4. [Roadmap v0.15 → v1.0](#4-roadmap-v015--v10)
5. [Estructura de `~/.owl/`](#5-estructura-de-owl)
6. [Formato de archivos clave](#6-formato-de-archivos-clave)
7. [Flujo de seguridad](#7-flujo-de-seguridad)
8. [Protocolo de registro](#8-protocolo-de-registro)

---

## 1. Filosofía y principios

| Principio | Descripción |
|-----------|-------------|
| **Correcto antes que rápido** | El comportamiento correcto no se puede optimizar después de que el ecosistema crece. Primero funciona bien, luego funciona rápido. |
| **Seguridad no opcional** | SHA-256 y firma Ed25519 están presentes desde el primer `owl -S`. No existe una versión donde se instale sin verificar. |
| **Protocolo sobre implementación** | El formato del registro, el lockfile y los manifiestos se especifican antes de que nadie publique librerías. Cambiar el formato después tiene coste de migración real. |
| **Sin magia** | Nada ocurre de forma silenciosa. Los errores son claros, los fallbacks no existen: un campo faltante en `owl.toml` produce un error, no un valor por defecto. |
| **Build system congelado en v0.15** | La compilación se toca una sola vez. El resto del roadmap no modifica el build system. |

---

## 2. Referencia completa de flags

### Compilación y ejecución

| Flag | Descripción |
|------|-------------|
| `build` / `-B` | Compila el proyecto actual según `owl.toml` |
| `run` | Compila y ejecuta |
| `run <archivo.mire>` | Ejecuta un archivo suelto sin proyecto — delega a `mire run` |
| `test` / `-T` | Ejecuta la suite de tests |
| `test --filter <patrón>` | Solo los tests cuyo nombre coincide con el patrón |
| `check` / `-K` | Análisis estático. Rápido por defecto, completo con `--all --strict` |
| `debug` / `-D` | Build de debug con emisión de IR |

### Flags de build

| Flag | Descripción |
|------|-------------|
| `-r` / `--release` | Perfil release (O2 por defecto) |
| `-O0` … `-O3` / `-Os` | Nivel de optimización explícito |
| `--emit-ir` | Emite el IR de LLVM junto al binario |
| `--target <triple>` | Cross-compilación a un target específico |
| `--no-cache` | Ignora la caché incremental y recompila todo |
| `--timings` | Imprime tiempos de compilación por módulo |

### Proyecto

| Flag | Descripción |
|------|-------------|
| `new <nombre>` | Crea un proyecto nuevo con estructura estándar |
| `clean` / `-C` | Elimina artefactos de build y caché del proyecto |
| `profile` | Métricas de build: tiempos, tamaño, módulos compilados, hits de caché |
| `info` | Información del proyecto y entorno (todo leído en vivo, nada hardcodeado) |
| `doctor` | Diagnóstico completo del entorno de desarrollo |

### Paquetes — Sync (`-S`)

| Flag | Descripción |
|------|-------------|
| `-S <pkg>` | Instala un paquete desde los registros activos |
| `-S <pkg>@<ver>` | Instala una versión exacta |
| `-Ss <término>` | Busca paquetes en el índice local |
| `-Si <pkg>` | Muestra detalles de un paquete del registro |
| `-Sy` | Actualiza los índices de todos los registros activos |
| `-Syy` | Fuerza refresco aunque el índice parezca actual |
| `-Syu` | Sincroniza índices y actualiza todos los paquetes instalados |
| `-Syyu` | Igual pero forzando refresco de índices |

### Paquetes — Remove (`-R`)

| Flag | Descripción |
|------|-------------|
| `-R <pkg>` | Elimina un paquete del proyecto actual |
| `-Rs <pkg>` | Elimina el paquete y su caché global en `~/.owl/lib/` |
| `-Rns <pkg>` | Elimina sin confirmación y purga |

### Paquetes — Query (`-Q`)

| Flag | Descripción |
|------|-------------|
| `-Qi <pkg>` | Información de un paquete instalado localmente |
| `-Ql <pkg>` | Lista archivos instalados de un paquete |
| `-Qe` | Lista paquetes instalados explícitamente (no transitivos) |
| `-Qdt` | Lista dependencias transitivas ya no requeridas |

### Registros

| Flag | Descripción |
|------|-------------|
| `-Si <url>` | Añade un registro: descarga `registry.json`, verifica firma, aplica TOFU |
| `-SR <nombre>` | Elimina un registro de la lista activa |
| `-Sl` | Lista registros activos con prioridad y estado |
| `-Sd <nombre>` | Desactiva un registro sin eliminarlo |
| `-Se <nombre>` | Reactiva un registro desactivado |
| `-Sp <nombre> <n>` | Cambia la prioridad de un registro (menor número = más prioritario) |

### Publicación

| Flag | Descripción |
|------|-------------|
| `-e` | Valida, empaqueta, firma y genera artefactos para publicar |
| `-e --dry-run` | Valida y empaqueta sin generar la firma final |
| `-e --check` | Solo valida: compila en release y comprueba el manifiesto |

### Mantenimiento

| Flag | Descripción |
|------|-------------|
| `gc` | Elimina versiones de paquetes no referenciadas por ningún lockfile activo |
| `tree` | Árbol de dependencias del proyecto actual con versiones resueltas |
| `tree --all` | Árbol completo incluyendo dependencias transitivas |
| `-V` / `--version` | Versión de owl y del compilador Avenys (siempre en vivo) |
| `-h` / `--help` | Ayuda. Sin subcomando: lista todos los comandos disponibles |
| `-y` / `--noconfirm` | Suprime confirmaciones interactivas (útil en CI) |

---

## 3. Comportamientos implícitos

Esta sección documenta decisiones de comportamiento que no son inmediatamente obvias pero que deben estar especificadas para evitar ambigüedad en la implementación.

### 3.1 `owl build` / `owl run` con dependencias sin lockfile

Si `owl.toml` declara dependencias y no existe `owl.lock`:

```
owl build
  → detecta dependencias en owl.toml
  → detecta ausencia de owl.lock
  → resuelve dependencias (como haría owl -S)
  → descarga, verifica (SHA-256 + firma) e instala
  → genera owl.lock
  → continúa con la compilación
```

**Esto no es opcional.** Un proyecto con dependencias declaradas pero sin lockfile no puede compilar de forma reproducible. Owl no falla silenciosamente ni ignora las dependencias: las instala.

Si el usuario está en un entorno sin red y no existe lockfile, owl falla con un error claro:

```
error: owl.lock not found and network is unavailable
  → run `owl -S` in a network-connected environment first
```

### 3.2 `owl build` / `owl run` con lockfile existente

Si existe `owl.lock`, owl lo usa como fuente de verdad sin tocar la red:

```
owl build
  → lee owl.lock
  → comprueba que las versiones están en ~/.owl/lib/
  → si falta alguna: descarga, verifica e instala esa versión exacta
  → si todas presentes: compila directamente
```

El lockfile nunca se modifica automáticamente durante un build. Solo cambia con `owl -Syu` o con `owl -S <pkg>` explícito.

### 3.3 `owl build` con lockfile desactualizado respecto a `owl.toml`

Si `owl.toml` declara una dependencia que no aparece en `owl.lock`, o declara una versión fuera del rango del lockfile:

```
error: owl.toml and owl.lock are out of sync
  dependency 'kioto-strings' in owl.toml is not in owl.lock
  → run `owl -S kioto-strings` to add it, or `owl -Syu` to update all
```

Owl nunca resuelve este conflicto automáticamente durante un build. El usuario decide.

### 3.4 `owl run <archivo.mire>` sin proyecto

Si no hay `owl.toml` en el directorio ni en ningún directorio padre:

```
owl run file.mire
  → delega directamente a: mire run file.mire
  → no busca dependencias
  → no genera lockfile
  → no lee ningún owl.toml
```

Es un modo de ejecución rápida para scripts sueltos. Sin overhead de gestión de proyecto.

### 3.5 `owl -S <pkg>` y el lockfile

Instalar un paquete nuevo siempre actualiza el lockfile:

```
owl -S kioto-strings
  → resuelve la versión más reciente compatible con owl.toml
  → descarga el tarball
  → verifica SHA-256
  → verifica firma Ed25519 del autor
  → extrae en ~/.owl/lib/kioto-strings/<versión>/src/
  → añade la entrada a owl.lock con hash exacto
  → añade la dependencia a owl.toml si no estaba declarada
```

Si el paquete ya estaba en `~/.owl/lib/` con el hash correcto, no se vuelve a descargar. La verificación de integridad sigue ocurriendo sobre los archivos locales.

### 3.6 `owl -Sy` vs cambios en `owl.lock`

`owl -Sy` actualiza los índices locales (`~/.owl/registries/*/index.toml`) pero **nunca modifica `owl.lock`**. Actualizar el índice no significa actualizar los paquetes instalados. Son dos operaciones distintas e independientes.

Para actualizar paquetes instalados: `owl -Syu`.

### 3.7 `~/.owl/lib/` es de solo lectura después del install

Una vez que owl extrae un paquete en `~/.owl/lib/<nombre>/<versión>/src/`, esa ruta no vuelve a ser escrita. Ni por owl, ni por el compilador, ni por ninguna otra herramienta del toolchain. Es una propiedad estructural, no una convención.

El compilador referencia esa ruta directamente desde el lockfile. Si la ruta no existe o el contenido no coincide con el hash registrado en `meta.toml`, owl falla con un error de integridad antes de compilar.

### 3.8 Resolución de conflictos de versión

Si dos dependencias piden versiones incompatibles de un mismo paquete:

```
error: version conflict for 'kioto-strings'
  foo requires ^1.2  (resolved: 1.2.4)
  bar requires ^2.0  (resolved: 2.1.0)
  → these ranges do not overlap
  → update foo or bar to compatible versions
```

Owl no intenta resolver esto automáticamente. No hay SAT solver silencioso. El usuario decide qué cambiar.

### 3.9 TOFU en claves de autor

La primera vez que owl encuentra una clave Ed25519 de un autor desconocido:

```
warning: unknown author key for 'kioto-strings' by 'evelyn'
  key fingerprint: ed25519:abc123...
  → trust this key? [y/N]
```

Si el usuario acepta, la clave se guarda en `~/.owl/keys/trusted.toml`. Las instalaciones siguientes del mismo autor no preguntan. Con `--noconfirm` (`-y`), owl rechaza claves desconocidas con un error en lugar de preguntar.

### 3.10 ABI incompatible (v0.19+)

Si una dependencia declara un ABI distinto al del entorno actual:

```
owl build
  → detecta que kioto-strings@1.2.0 fue compilado con abi=1
  → el entorno actual tiene abi=2
  → si el paquete tiene fuente disponible: recompila automáticamente
  → si no es recompilable: error con instrucciones para actualizar
```

### 3.11 `owl checkup` — qué comprueba

`owl checkup` no es un comando de build ni de análisis de código. Es un diagnóstico del entorno y del proyecto:

```
owl checkup
  ✓ owl v0.15.0
  ✓ mire (Avenys) v0.15.0  →  /usr/bin/mire
  ✓ LLVM 17.0.6
  ✓ registries: 1 active (mire-registry, last sync: 2h ago)
  ✓ ~/.owl/keys: 3 trusted keys
  ✓ ~/.owl/lib: 12 packages, 0 integrity errors
  ✓ network: reachable (raw.githubusercontent.com)
  ✓ filesystem permissions: ~/.owl/ writable

  project (./):
  ✓ owl.toml: valid
  ✓ owl.lock: in sync with owl.toml
  ✗ bin/.cache: corrupted entries detected  →  run `owl clean` to fix
```

`owl checkup --fix` regenera `owl.toml` con valores por defecto, preservando el nombre del proyecto.

Si `owl checkup` pasa sin errores, el entorno está en estado correcto para compilar e instalar. Es el primer comando a ejecutar cuando algo no funciona.

### 3.12 `owl info` — qué muestra

`owl info` lee todo en vivo en tiempo de ejecución. Ningún valor hardcodeado:

```
owl info

project:     myproject v0.1.0
entry:       code/main.mire
profile:     debug
output:      bin/debug/
cache:       bin/.cache/
target:      x86_64-linux-gnu

compiler:    Avenys v0.16.0
owl:         v0.16.0
LLVM:        17.0.6
language:    Mire v0.16.0
abi:         1

dependencies:
  kioto-strings   1.2.0   (mire-registry)
  kioto-math      0.4.1   (mire-registry)
```

Sin proyecto activo (`owl info` desde un directorio sin `owl.toml`), muestra solo la sección de entorno (compiler, owl, LLVM, abi).

### 3.13 `owl clean` — alcance

`owl clean` (o `-C`) limpia solo el proyecto actual:

```
owl clean
  → elimina bin/debug/
  → elimina bin/release/
  → elimina bin/.cache/
  → no toca ~/.owl/
  → no toca owl.lock
  → no toca owl.toml
```

Para limpiar la caché global de paquetes: `owl gc`. Son operaciones distintas con alcances distintos.

---

## 4. Roadmap v0.15 → v1.0

### v0.15 — Núcleo: build system

**Objetivo:** Owl como frontend sólido del compilador. Una vez estable, el build system no vuelve a cambiar.

- `owl build` y `owl run` como únicos comandos de compilación
- Lectura completa de `owl.toml`: entry, profile, opt-level, paths, flags — sin fallbacks silenciosos
- Perfiles debug / release con flags de optimización configurables
- Build incremental: detección de cambios por hash, no por timestamp
- Caché incremental en `bin/.cache/` — en frío ~60ms, en caliente ~2ms
- `owl run <archivo.mire>` sin proyecto delega directamente a `mire run`
- Errores claros en campos faltantes de `owl.toml`
- `owl checkup`: validación de `owl.toml` con `--fix` para regenerarlo con defaults
- `owl new`, `owl clean`: gestión básica de proyectos

> **Principio:** Una vez estable, el build system no vuelve a cambiar hasta la 1.0. Ninguna fase posterior modifica la compilación.

---

### v0.16 — Introspección: info + checkup

**Objetivo:** Visibilidad del entorno. Sin tocar el build system.

- `owl info`: todo leído en vivo — proyecto, compilador, owl, LLVM, perfil, output, caché, target, dependencias
- `owl checkup`: diagnóstico completo del entorno — compilador, LLVM, permisos, configuración, caché, registros, claves, integridad de paquetes
- `owl checkup --fix`: regenera `owl.toml` con valores por defecto preservando el nombre del proyecto
- `owl checkup` detecta: lockfile desactualizado, caché corrupta, firma desconocida, `owl.toml` malformado
- Ningún valor hardcodeado en ninguno de los dos comandos

> **Por qué `checkup` aquí:** Es el comando con mejor ROI de soporte. Resuelve el 80% de los problemas de configuración sin intervención manual. Llega antes de que el ecosistema exista para que esté disponible desde el primer día de uso real.

---

### v0.17 — Registros: protocolo e índices

**Objetivo:** Introducir el concepto de registro. Solo gestión de fuentes, sin instalar paquetes todavía.

- `owl -Si <url>`: añade un registro — descarga `registry.json`, verifica firma, aplica TOFU a la clave pública
- `owl -Sy` / `-Syy`: sincronización de índices
- `owl -Sl`, `-SR`, `-Sd`, `-Se`, `-Sp`: gestión completa de registros activos
- Estructura local: `~/.owl/registries/<nombre>/` con `registry.json` + `index.toml` + `index.toml.sig` + `last_sync`
- `registry.json` expone: `name`, `protocol`, `public-key`, `mirrors`, `packages` — owl lo usa para verificar compatibilidad antes de parsear el índice
- Registro oficial inicial: `raw.githubusercontent.com/mire-lang/registry` — sustituible sin cambiar el protocolo ni `owl.toml`
- `owl -Ss <término>`: búsqueda en el índice local ya disponible desde aquí

> **Principio de desacoplamiento:** El protocolo funciona con cualquier servidor HTTP que sirva la estructura correcta. GitHub es la implementación inicial, no el destino permanente. Dentro de cinco años, cambiar la URL del registro oficial no requiere cambiar nada más.

---

### v0.18 — Dependencias + Seguridad: primer `owl -S`

**Objetivo:** Instalar paquetes con seguridad desde el primer día. Seguridad y dependencias van juntas — no existe un estado intermedio donde se instale sin verificar.

**Flujo irrenunciable:**
```
Descargar → SHA-256 → Firma Ed25519 → Extraer → Registrar → Instalar
```

- `owl -S <pkg>`: instala con verificación completa en el mismo paso
- Resolución SemVer: `^1.2` → `>=1.2.0 <2.0.0`, escoge la más reciente que satisface el rango
- Dependencias transitivas: owl resuelve el grafo completo antes de descargar nada
- Conflictos: error claro con la ubicación exacta del conflicto — sin resolución automática
- `owl.lock` generado en la raíz del proyecto, junto a `owl.toml` — nunca en `~/.owl/`
- `~/.owl/lib/<nombre>/<versión>/src/` de solo lectura después del install
- TOFU para claves nuevas: primera vez pregunta, después confía hasta revocación explícita
- `owl build` / `owl run` con dependencias instala automáticamente si no hay lockfile (ver §3.1)

> **Por qué seguridad aquí y no en v0.19:** Un gestor de paquetes con una versión que instala sin verificar crea deuda de seguridad que no se puede eliminar. Aunque esa versión sea marcada como "experimental", queda en el historial, en los tutoriales, en los entornos de CI. La verificación es parte del protocolo desde el principio.

---

### v0.19 — ABI: compatibilidad binaria declarada

**Objetivo:** Cada paquete sabe con qué versión del compilador y del lenguaje fue construido. Obligatorio antes de abrir la publicación.

- Cada paquete declara en su manifiesto: `compiler` (versión mínima de Avenys), `abi` (versión del ABI de Mire), `language` (versión del lenguaje)
- `owl build` detecta ABI distinta y recompila automáticamente lo necesario
- ABI incompatible no resoluble → error claro antes de tocar ningún archivo
- `owl info` muestra la ABI del entorno actual
- Estos campos son obligatorios en el manifiesto desde esta versión

> **Por qué ABI antes de publicación:** Si alguien publica librerías antes de que el campo `abi` sea obligatorio, la primera migración del ecosistema toca paquetes de terceros. El orden correcto es fijar el formato antes de abrirlo.

---

### v0.20 — Publicación: `owl -e`

**Objetivo:** El otro lado del ecosistema — no solo consumir, también publicar.

- `owl -e`: valida `owl.toml` (incluyendo `abi`, `compiler`, `language`), compila en release, empaqueta `src/`, calcula SHA-256, firma con clave Ed25519 local del autor
- Artefactos generados: `<nombre>-<versión>.tar.zst`, `<nombre>-<versión>.tar.zst.sig`, `publish.toml`
- `publish.toml` es la entrada lista para incorporar al `index.toml` de cualquier registro compatible
- `owl -e --dry-run`: valida y empaqueta sin firmar
- `owl -e --check`: solo valida, sin empaquetar (útil en CI)
- Owl no tiene credenciales de escritura a ningún servidor — la publicación al registro es responsabilidad del mantenedor del registro
- Doble firma: el autor firma el tarball (autoría), el registro firma el índice (moderación) — claves distintas, propósitos distintos
- Si una librería supera `owl -e`, cualquier usuario puede instalarla

---

### v0.21 — Optimización: rendimiento del gestor

**Objetivo:** Hacer rápido lo que ya funciona correctamente.

- Caché de resolución: el grafo de dependencias resuelto se cachea e invalida solo cuando cambia el índice o `owl.toml`
- Descargas paralelas: N paquetes → N hilos
- Verificación paralela: SHA-256 y firma en paralelo con la extracción del siguiente paquete
- Resolución paralela: subgrafos independientes se resuelven en paralelo cuando no hay conflictos
- Índice local comprimido: `index.toml` cacheado en formato binario para búsquedas instantáneas con `-Ss`

> **Por qué aquí:** Optimizar antes de que el comportamiento sea correcto es optimizar sobre arena. Esta fase llega cuando install, resolve y export son estables y probados bajo uso real.

---

### v0.22 — Calidad de vida: herramientas de mantenimiento

- `owl gc`: elimina versiones en `~/.owl/lib/` no referenciadas por ningún lockfile activo
- `owl tree`: árbol de dependencias con versiones resueltas y origen por registro
- `owl tree --all`: árbol completo incluyendo transitivas
- `-Qdt`: lista dependencias transitivas candidatas a gc
- `owl profile`: métricas de build por módulo — tiempo, tamaño, hits de caché
- `owl clean --global`: limpia caché de build global además de la del proyecto

---

### v0.23 — Especificación: REGISTRY_PROTOCOL_v1

**Objetivo:** Convertir el protocolo en un estándar real, no en "lo que hace owl".

- `REGISTRY_PROTOCOL_v1.md` commiteado en el repo oficial de Mire
- Define: formato de `index.toml`, campos obligatorios, algoritmo de resolución SemVer, verificación de firma, formato de empaquetado, formato del lockfile, formato del manifiesto, proceso de publicación
- Cualquier persona puede leer el documento e implementar un registro compatible sin mirar el código de owl
- A partir de aquí el protocolo no cambia en versiones menores — solo evoluciona con un nuevo número de protocolo (`protocol: 2`) con migración explícita
- El campo `protocol` en `registry.json` permite detectar registros incompatibles antes de parsear nada

> **Criterio de madurez:** Si puedes escribir la especificación completa sin mirar el código, el diseño está maduro.

---

### v0.24 – v0.99 — Estabilización

**Objetivo:** Eliminar problemas, no añadir comandos.

- Bugs, edge cases, UX, mensajes de error, documentación
- Compatibilidad con nuevas versiones del compilador Avenys
- Sin funcionalidades nuevas excepto parches de funcionalidades conjuntas con el compilador
- Tests de regresión exhaustivos para cada comportamiento especificado en §3

> Muchos proyectos llegan a la 1.0 añadiendo features hasta el final. En un compilador y su ecosistema, las últimas versiones pre-1.0 deben dedicarse a eliminar problemas y validar que el diseño resiste el uso real.

---

### v1.0

**Criterio:** Todo lo que un desarrollador necesita para crear, publicar, consumir y mantener una librería existe, está especificado y es estable.

| Área | Estado en v1.0 |
|------|----------------|
| Build | Incremental, determinista, sin recompilaciones innecesarias |
| Registry | Múltiples registros, protocolo estable, sin dependencia de un servidor propio |
| Dependencias | Resolver transitivo, lockfile, versiones múltiples, caché global |
| Seguridad | SHA-256 obligatorio, firma obligatoria, claves de confianza, verificación pre-install |
| Publicación | Empaquetado estándar, validación automática, exportación reproducible |
| Compatibilidad | ABI, versión mínima del compilador, versión del lenguaje, comprobaciones pre-build |
| Mantenimiento | `gc`, `info`, `doctor`, `tree` |

---

## 5. Estructura de `~/.owl/`

```
~/.owl/
  registries/
    mire-registry/
      registry.json          ← metadatos del registro (protocol, public-key, mirrors)
      index.toml             ← índice completo de paquetes
      index.toml.sig         ← firma del registro sobre el índice
      last_sync              ← timestamp del último -Sy
  lib/
    <nombre>/
      <versión>/
        src/                 ← código fuente extraído (readonly post-install)
        meta.toml            ← hash verificado, fecha, registro de origen, firma
  cache/
    resolve/                 ← grafo de dependencias resuelto (cacheado)
    tarballs/                ← tarballs descargados pre-verificación
  keys/
    trusted.toml             ← claves de autores vistos y aprobados (TOFU)
    revoked.toml             ← claves revocadas

proyecto/
  owl.toml                   ← manifiesto del proyecto
  owl.lock                   ← lockfile: versiones exactas + hashes (se commitea)
  code/
  tests/
  bin/
    debug/
    release/
    .cache/                  ← caché incremental de build
```

**Separación estricta:** `~/.owl/` son datos globales compartidos entre proyectos. `owl.lock` y `owl.toml` son datos de proyecto y viven siempre en la raíz del proyecto. Los dos mundos no se mezclan nunca.

---

## 6. Formato de archivos clave

### `registry.json`

Primer archivo que owl descarga al añadir un registro. Define el protocolo y la clave pública para verificar el índice.

```json
{
  "name": "mire-registry",
  "protocol": 1,
  "generated": "2025-06-01T00:00:00Z",
  "public-key": "ed25519:BASE64...",
  "mirrors": [],
  "packages": 138
}
```

### Entrada en `index.toml`

Cada versión de cada paquete tiene su propia entrada. Las versiones antiguas permanecen para garantizar reproducibilidad.

```toml
[[packages]]
name        = "kioto-strings"
version     = "1.2.0"
description = "String utilities for Mire"
author      = "evelyn"
author-key  = "ed25519:BASE64..."
tarball     = "https://example.com/kioto-strings-1.2.0.tar.zst"
sha256      = "a3f9..."
signature   = "BASE64..."      # firma del autor sobre el tarball
compiler    = ">=0.15.0"       # versión mínima de Avenys
abi         = 1                # versión del ABI de Mire
language    = ">=0.15.0"
published   = "2025-06-01"
```

### `owl.lock`

Fija hashes exactos. Se commitea siempre. `owl -Sy` no lo modifica.

```toml
# Generado por owl — no editar manualmente

[[package]]
name     = "kioto-strings"
version  = "1.2.0"
sha256   = "a3f9..."
registry = "mire-registry"
abi      = 1
```

### `owl.toml` (proyecto)

```toml
[project]
name        = "myproject"
version     = "0.1.0"
description = ""
entry       = "code/main.mire"
author      = "evelyn"

[build]
profile   = "debug"
opt-level = 0

[abi]
compiler = ">=0.15.0"
abi      = 1
language = ">=0.15.0"

[paths]
sources = "code"
tests   = "tests"
output  = "bin"
cache   = "bin/.cache"

[dependencies]
kioto-strings = "^1.2"
```

### `publish.toml` (generado por `owl -e`)

Entrada lista para incorporar al `index.toml` de cualquier registro.

```toml
# Generado por owl -e — verificar antes de enviar al registro

[[packages]]
name       = "mi-libreria"
version    = "0.1.0"
author     = "evelyn"
author-key = "ed25519:BASE64..."
tarball    = "https://..."
sha256     = "..."
signature  = "BASE64..."
compiler   = ">=0.15.0"
abi        = 1
language   = ">=0.15.0"
published  = "2025-06-26"
```

---

## 7. Flujo de seguridad

### Invariantes (no negociables)

| Invariante | Descripción |
|------------|-------------|
| **SHA-256 obligatorio** | Se verifica antes de extraer cualquier tarball. Un hash incorrecto aborta la instalación sin dejar archivos parciales. |
| **Firma Ed25519 obligatoria** | Se verifica la firma del autor antes de instalar. Un registro comprometido no puede falsificar paquetes de autores con clave distinta. |
| **Doble firma** | El autor firma el tarball (autoría). El registro firma el índice (moderación). Son claves distintas con propósitos distintos. |
| **TOFU para claves nuevas** | Primera vez: pregunta. Siguientes: confianza automática. Revocación: explícita mediante `~/.owl/keys/revoked.toml`. |
| **`~/.owl/lib/` readonly** | Una vez instalado, el código fuente no se modifica. Owl nunca escribe en esa ruta después del install inicial. |
| **`owl.lock` estable** | `owl -Sy` actualiza índices pero nunca modifica el lockfile. Builds siempre reproducibles. |
| **Sin scripts de instalación** | Owl solo extrae código fuente. No ejecuta código del paquete durante install. La seguridad es estructural. |

### Flujo de instalación

```
owl -S kioto-strings

  1. Busca en registros activos por orden de prioridad
  2. Resuelve versión más reciente compatible con owl.toml
  3. Descarga tarball desde la URL en index.toml
  4. Verifica SHA-256 del tarball contra el hash del índice
     → si falla: error, elimina el tarball descargado
  5. Verifica firma Ed25519 del autor
     → clave desconocida: TOFU (pregunta o -y rechaza)
     → clave revocada: error inmediato
     → firma inválida: error inmediato
  6. Extrae en ~/.owl/lib/<nombre>/<versión>/src/
  7. Marca el directorio como readonly
  8. Escribe meta.toml con hash, fecha, registro, firma
  9. Actualiza owl.lock con la versión exacta y el hash
 10. Añade la dependencia a owl.toml si no estaba declarada
```

---

## 8. Protocolo de registro

### Estructura de una URL de registro

```
https://example.com/owl/
  registry.json        ← metadatos + clave pública
  index.toml           ← índice de paquetes
  index.toml.sig       ← firma del registro sobre el índice
```

Owl no requiere ninguna infraestructura especial. Un repositorio git con `raw.githubusercontent.com`, un servidor de archivos estático, o cualquier CDN que sirva estos tres archivos es un registro válido.

### Compatibilidad de protocolo

Cuando owl añade un registro con `-Si <url>`, el primer paso es descargar `registry.json` y comprobar el campo `protocol`. Si el número de protocolo es mayor que la versión que owl conoce:

```
error: registry 'example-registry' uses protocol v2
  this version of owl only supports protocol v1
  → update owl to add this registry
```

Esto permite que el protocolo evolucione sin romper versiones antiguas de owl que todavía funcionan con registros v1.

### Múltiples registros y prioridad

Owl puede tener varios registros activos simultáneamente. Cuando busca un paquete, los consulta en orden de prioridad (menor número = más prioritario). Si el mismo paquete existe en varios registros, se instala desde el de mayor prioridad.

```
owl -Sl

  1  mire-registry   (oficial)   synced 2h ago   138 packages
  2  empresa         (privado)   synced 1h ago    42 packages
  3  universidad     (privado)   synced 3d ago     8 packages
```

Un paquete en `empresa` con prioridad 2 no sobrescribe nunca un paquete del mismo nombre en `mire-registry` con prioridad 1, a menos que el usuario cambie explícitamente las prioridades.
