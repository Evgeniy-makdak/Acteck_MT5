# ASmart 4.23 — изменения

## 2026-10-19 — КЗ и Z строго с M15 (критично для Снайпера)

### Проблема (4.22 и ранее)
- `DetectCorrectionZones_IKI` вызывался на **барах ТФ графика** (часто M5).
- M15-структуры считались опционально (`UseVirtualTF`), но при `ShowSlowTFStructures=false`
  **не рисовались**, а торговля могла брать смесь зон.
- На M5 «растянутое» продолженное движение дробилось микро-ИКИ → **ложные новые КЗ**.
- Z / «30» (`FindContinuedMove`) тоже строились с ТФ графика.

### Правило Снайпера (зафиксировано)
1. **Разметка КЗ всегда с M15** (`StructureTF=PERIOD_M15`), независимо от рабочего ТФ (M5 и т.д.).
2. При переключении ТФ графика уровни КЗ **не меняются**.
3. **Z (продолженное)** — растянутое плечо без новых КЗ, пока нет действительного ИКИ
   на M15 (откат + обновление экстремума). Новая КЗ — при развороте / новом ИКИ на M15.
4. Рабочий ТФ (M5) — точки входа / РМ / фильтры; якорь зон — M15.

### Код
- EA: `MQL5/Experts/ASmart 4.23.mq5` (`ASmart423_`).
- Input `StructureTF` (дефолт M15).
- `UpdateSniperStructures`: КЗ только через `LoadStructureRates` → `DetectCorrectionZones_IKI`.
- `FindTradeableIKI_KZ`: только зоны с тегом StructureTF.
- `DrawFib30Line` / Z: `FindContinuedMove` на барах StructureTF.
- Пресеты `Acteck_v4.21_*.set` без переименования (совместимы; появится input StructureTF=M15).

### Документы
- `README.md`, `UserGuide_ASmart_4.23_RU.txt`, `ASmart_4.23_Manual_RU.txt`
- `docs/SNIPER_PARITY_V4_RU.md`
