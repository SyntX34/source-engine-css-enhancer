# [EN]
***[ANY] WinterFX | Snow on the ground:***
- Instantly transforms any map into a winter scene by replacing ground surfaces with snow-covered textures.
- Works automatically on every installed map.
- Detects up-facing surfaces (floors, terrain, rooftops, etc.) and applies a custom snow texture for realistic coverage.
<img src="../../snowfx.png" alt="SnowFX" width="300">

**Installation:**
- Place the module inside the modules folder.
- Create a folder named WinterFX inside modules, and put the snowfloor.vtf texture file inside it.
- Run the core executable and wait for it to generate snow textures for all installed maps.
- Once the console prints that it’s finished, launch the game.

- By default, it generates snow textures only for maps starting with "de_" and "cs_".
- If you want to modify this, open modules/configs/winterfx_config.json and add the full map name or mode prefix (e.g., "mg_").
- After editing the config, delete the maps.txt file inside modules/WinterFX and run the core executable again so it can regenerate textures using the new settings.
- Deleting maps.txt is required after any configuration change.

# [RU]
***[ANY] WinterFX | Snow on the ground:***

- Мгновенно превращает любую карту в зимнюю сцену, заменяя поверхности земли текстурами, покрытыми снегом.
- Работает автоматически на каждой установленной карте.
- Определяет поверхности, направленные вверх (полы, грунт, крыши и т. д.), и применяет пользовательскую снеговую текстуру для реалистичного покрытия.
<img src="../../snowfx.png" alt="SnowFX" width="300">

Установка:
- Поместите модуль в папку modules.
- Создайте внутри modules папку WinterFX и положите в неё файл текстуры snowfloor.vtf.
- Запустите основной исполняемый файл и дождитесь, пока он сгенерирует снеговые текстуры для всех установленных карт.
- После того как в консоли появится сообщение о завершении, запустите игру.

- По умолчанию текстуры создаются только для карт, начинающихся с "de_" и "cs_".
- Если вы хотите изменить это, откройте modules/configs/winterfx_config.json и добавьте полное название карты или префикс режима (например, "mg_").
- После изменения конфигурации удалите файл maps.txt в modules/WinterFX и снова запустите основной исполняемый файл, чтобы текстуры были сгенерированы заново с учётом новых настроек.
- Удаление maps.txt является обязательным после любых изменений конфигурации.
