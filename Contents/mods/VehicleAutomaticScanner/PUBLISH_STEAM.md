# Publishing Vehicle Diagnostic Scanner to Steam Workshop

Follow these steps to publish (or update) your mod on the Steam Workshop.

---

## 1. Use the Workshop folder (required for in-game uploader)

The **in-game uploader only sees mods in the Workshop folder**, not in `Zomboid/mods/`.

- **Your current mod path:** `C:\Users\Jongwan\Zomboid\mods\VehicleDiagnosticScanner\`
- **Workshop path (cache folder):** `C:\Users\Jongwan\Zomboid\Workshop\`

Create this structure and put a **copy** of your mod inside it:

```
C:\Users\Jongwan\Zomboid\Workshop\
└── VehicleDiagnosticScanner\          ← Workshop item folder (any name)
    ├── Contents\
    │   └── mods\
    │       └── VehicleDiagnosticScanner\   ← Your mod (must match mod id)
    │           ├── media\
    │           │   ├── lua\...
    │           │   ├── scripts\...
    │           │   └── textures\...
    │           ├── mod.info
    │           └── poster.png
    └── preview.png                     ← 256×256 PNG (Steam preview)
```

**Steps:**
1. Create `C:\Users\Jongwan\Zomboid\Workshop\VehicleDiagnosticScanner\Contents\mods\`.
2. Copy the entire **VehicleDiagnosticScanner** folder (with `media`, `mod.info`, `poster.png`) into `Contents\mods\` so the mod lives at `Workshop\VehicleDiagnosticScanner\Contents\mods\VehicleDiagnosticScanner\`.
3. Add **preview.png** (256×256) in `Workshop\VehicleDiagnosticScanner\`. You can resize `poster.png` to 256×256 and save as `preview.png` if you like. The game uses this for the Workshop thumbnail.

**Important:** Do **not** subscribe to your own mod on Steam while developing. Keep only this local copy in the Workshop folder to avoid conflicts.

---

## 2. Upload from the game

1. Launch **Project Zomboid** (with Steam running and logged in).
2. From the **main menu**, open **Workshop** → **"Create and update items"**.
3. Select **Vehicle Diagnostic Scanner** from the list.
4. Set:
   - **Title** (e.g. "Vehicle Diagnostic Scanner")
   - **Description** (what the mod does; you can use BBCode)
   - **Tags** (e.g. Items, Quality of Life, Vehicles)
   - **Visibility** (Public / Friends only / Private / Unlisted)
   - **Patch note** (optional; shown on the Workshop page for this update)
5. If this is the **first upload**, the game will ask to **create a new Workshop ID** (or use an existing one). Choose "Create new".
6. Click **"Upload to Steam Workshop now!"**.

After upload, the game will append to your description:
- **Workshop ID:** (numeric)
- **Mod ID:** VehicleDiagnosticScanner

Server admins and players use these to enable the mod.

---

## 3. Updating the mod later

1. Copy your **latest mod files** from `Zomboid\mods\VehicleDiagnosticScanner\` into `Zomboid\Workshop\VehicleDiagnosticScanner\Contents\mods\VehicleDiagnosticScanner\` (overwrite).
2. In-game: **Workshop** → **Create and update items** → select the mod.
3. Edit the **patch note** (and description/tags if needed), then **Upload to Steam Workshop now!**.

**Note:** The in-game uploader **overwrites** the full Workshop description with what you set in the uploader. If you edit the description on Steam in a browser, copy it and paste it into the uploader before the next update, or it will be replaced.

---

## 4. Optional: workshop.txt

You don’t need to create `workshop.txt` by hand; the game generates it when you upload. If you want to pre-fill title/description/tags, you can add `workshop.txt` next to `Contents\` with:

- `version=1`
- `title=Vehicle Diagnostic Scanner`
- `description=...` (each new line as another `description=...`)
- `tags=...` (use the tags offered in the uploader)
- `visibility=0` (0=public, 1=friends, 2=private, 3=unlisted)
- Omit `id` for a new item; set `id=<Workshop ID>` after the first upload to keep updating the same Workshop page.

---

## 5. Checklist before first publish

- [ ] Mod is in `Zomboid\Workshop\VehicleDiagnosticScanner\Contents\mods\VehicleDiagnosticScanner\` with `mod.info`, `media\`, and `poster.png`.
- [ ] `preview.png` (256×256) is in `Zomboid\Workshop\VehicleDiagnosticScanner\`.
- [ ] Not subscribed to your own mod on Steam.
- [ ] Steam is running and you’re logged in.
- [ ] Description and tags are ready in the in-game uploader.

For more detail, see: [PZwiki – Uploading mods](https://pzwiki.net/wiki/Uploading_mods), [Mod structure](https://pzwiki.net/wiki/Mod_structure).
