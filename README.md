# IS2 Kata 5 — Balanceo de carga dinámico con NGINX y Consul

### Objetivo

El objetivo de esta kata es configurar **NGINX** como punto de entrada (reverse proxy) con enrutamiento por ruta hacia distintos grupos de réplicas (`upstream`), integrando **Consul** para el registro de servicios, comprobación de salud (`/health`) y descubrimiento dinámico mediante registros **DNS SRV**. Se busca comprobar cómo se adapta el reparto de peticiones en tiempo real al dar de baja e incorporar nuevas réplicas sin necesidad de editar la configuración ni recargar NGINX, manteniendo intactas las URLs públicas consumidas por el cliente.

---

### Cómo compilar, desplegar y ejecutar

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/TextBox75/kata5.git
   cd kata5
   ```

2. **Compilar el proyecto Java (si aplica compilación previa al despliegue):**
   Abrir la carpeta con **IntelliJ IDEA** utilizando **JDK 21** (o superior) o ejecutar desde terminal:
   ```bash
   mvn clean package
   ```

3. **Arrancar la infraestructura (NGINX, Consul y réplicas de los servicios):**
   Levantar el entorno completo mediante Docker Compose:
   ```bash
   docker compose up -d --build
   ```

4. **Ejecutar el cliente / script de verificación:**
   Ejecutar la clase `Main` del cliente desde IntelliJ IDEA o mediante Maven/script para lanzar ráfagas de peticiones contra las rutas públicas y observar la cabecera `X-Node` devuelta por cada réplica.

**Requisitos y dependencias:**
- **JDK 21** (o superior) y **Maven** (`pom.xml`).
- **Docker** y **Docker Compose**.
- **NGINX** (`1.27.3` o superior, requerido para soporte de resolución dinámica DNS SRV en `upstream`).
- **HashiCorp Consul** (agente servidor con interfaz DNS habilitada en el puerto `8600` UDP/TCP y API HTTP en `8500`).

---

### Arquitectura, topología de red y correspondencia de rutas

Todos los contenedores operan dentro de una misma red interna compartida de Docker Compose para garantizar que las direcciones anunciadas en Consul sean alcanzables directamente desde NGINX.

| Ruta pública (NGINX) | Bloque `upstream` | Servicio en Consul | Descripción / Dominio |
| :--- | :--- | :--- | :--- |
| `GET /api/v1/...` *(ajustar ruta)* | `upstream_v1` | `service-v1` | Primer grupo de réplicas con descubrimiento vía DNS SRV de Consul |
| `GET /api/v2/...` *(ajustar ruta)* | `upstream_v2` | `service-v2` | Segundo grupo de réplicas aislado con su propio pool dinámico |

*(Nota: Ajusta los nombres exactos de las rutas públicas, bloques `upstream` y nombres de servicio de Consul según tu `nginx.conf`).*

**Estructura del proyecto:**
- `src/`: Código fuente en Java del servicio web (endpoints de negocio, endpoint `/health` y cabecera identificativa `X-Node`) y del cliente de pruebas.
- `nginx/nginx.conf`: Configuración de NGINX con bloques `zone`, directiva `resolver` apuntando al DNS de Consul y servidores definidos con `service=... resolve`.
- `docker-compose.yml`: Orquestación de Consul, NGINX y las réplicas iniciales de cada upstream.

---

### Estructura de la entrega y repeticiones de la kata

Para cumplir con la dinámica de repetición deliberada requerida, la kata se ha replicado en **3 ramas** con arquitectura equivalente pero variando el dominio matemático expuesto por los servicios, los identificadores de las réplicas y la configuración de puertos/rutas:

- **Rama `master` (Versión final evaluable — Potencias de dos):**
  Implementación principal donde los servicios calculan y sirven sucesiones/operaciones de **potencias de dos** ($2^n$). Incluye la configuración completa de balanceo dinámico con NGINX, registro automático en Consul y verificación de alta/baja de nodos.

- **Rama `impares` (Segunda repetición — Números impares):**
  Réplica completa del despliegue aplicando el mismo esquema de enrutamiento por ruta, descubrimiento DNS SRV y chequeos de salud, orientada al cálculo y entrega de **números impares** ($2n + 1$), introduciendo variaciones en los identificadores de nodo y puertos expuestos.

- **Rama `pares` (Tercera repetición — Números pares):**
  Tercera iteración equivalente centrada en el servicio de **números pares** ($2n$), consolidando la configuración de caché DNS, intervalos de *health check* en Consul y pruebas de tolerancia a fallos ante la caída de réplicas.

---

### Enlace al vídeo explicativo

https://www.youtube.com/watch?v=Dwny4EU64NY *(Actualizar con el enlace al vídeo de máximo 7 minutos de la Kata 5)*

---

### Verificación y pruebas de elasticidad

Se ha verificado el funcionamiento dinámico del sistema sin reiniciar ni recargar NGINX en ningún momento mediante los siguientes escenarios:

1. **Enrutamiento y reparto inicial:**
   Ejecución del cliente enviando múltiples peticiones consecutivas a ambas rutas públicas (`v1` y `v2`), comprobando mediante la cabecera `X-Node` que NGINX alterna las respuestas entre las réplicas activas de cada grupo y que los resultados son consistentes.
   ```bash
   # Ejemplo de comprobación manual por consola
   for i in {1..6}; do curl -i -s http://localhost:8080/api/v1/compute | grep -E "HTTP/|X-Node"; done
   ```

2. **Baja de una réplica (Tolerancia a fallos):**
   Detención controlada de una de las réplicas de un grupo (`docker stop <contenedor_replica>`). Tras superar el intervalo del *health check* de Consul y expirar el TTL de la caché DNS en NGINX, las peticiones dejan de enrutarse al nodo caído sin errores hacia el cliente, mientras el segundo grupo (`v2`) continúa operando con normalidad.

3. **Alta de una nueva réplica en caliente:**
   Incorporación de una nueva instancia registrada en Consul bajo el mismo nombre de servicio (`docker compose up -d --scale ...` o arranque de un nuevo contenedor). Una vez que Consul valida su `/health`, NGINX la descubre automáticamente vía DNS SRV y comienza a incluirla en el balanceo de carga.