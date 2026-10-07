# Mygame: Tycoon

Un juego Tycoon para Roblox hecho con [Rojo](https://rojo.space).

## Cómo se juega
1. Apareces en el centro del mapa. Hay 4 tycoons alrededor.
2. Camina hasta la **puerta verde** de uno libre y tócala para reclamarlo.
3. Pisa el botón azul **"Gotero (GRATIS)"** para tu primera máquina.
4. El gotero suelta bloques en la cinta, y el **recolector rojo** los convierte en dinero.
5. Pisa el **botón verde "Cobrar"** para pasar ese dinero a tu cuenta.
6. Compra más cosas con los botones verdes. Aparecen nuevos botones al comprar.

Lo que se puede comprar: Goteros 2, 3 y 4, Paredes, Cinta rápida, Mejorador x2,
Techo, Gotero de oro y la Estatua de Magnate (el premio final).

Tu dinero y tus compras se guardan cuando sales del juego.

## Abrir el juego en Roblox Studio

### Forma fácil
Descarga `Mygame.rbxl` y ábrelo en Roblox Studio (**File → Open from File**). Dale a **Play**.

### Con Rojo (para recibir cambios automáticamente)
1. Instala Rojo: https://rojo.space/docs/v7/getting-started/installation/
2. En Roblox Studio instala el plugin de Rojo.
3. En la carpeta `Mygame` ejecuta:
   ```bash
   rojo serve
   ```
4. En Studio, abre el plugin de Rojo y haz clic en **Connect**.

Para volver a crear el archivo `Mygame.rbxl`:
```bash
rojo build -o Mygame.rbxl
```

## Para que se guarden los datos
1. Publica el juego (**File → Publish to Roblox**).
2. En **Game Settings → Security**, activa **Enable Studio Access to API Services**.

Si no lo activas, el juego funciona igual, pero el progreso no se guarda al probar en Studio.

## Dónde está cada cosa
| Archivo | Qué hace |
|---|---|
| `src/shared/TycoonConfig.luau` | **Precios, valores y posiciones.** Cambia los números aquí. |
| `src/shared/Format.luau` | Muestra el dinero bonito (`$12,500`) |
| `src/server/init.server.luau` | Script principal: crea los tycoons y maneja a los jugadores |
| `src/server/Tycoon.luau` | Reclamar, comprar, cobrar |
| `src/server/PlotBuilder.luau` | Construye el terreno: piso, puerta, cinta y recolector |
| `src/server/ItemBuilders.luau` | Construye cada cosa que compras |
| `src/server/PlayerData.luau` | Guarda el dinero y las compras |
| `src/client/init.client.luau` | Pantalla del jugador: dinero y mensajes |
