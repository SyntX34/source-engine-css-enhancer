# [EN]
***[ANY] WinterFX | Snow on the ground:***
- Instantly transforms any map into a winter scene by replacing ground surfaces with snow-covered textures.
- Works automatically on every installed map.
- Detects up-facing surfaces (floors, terrain, rooftops, etc.) and applies a custom snow texture for realistic coverage.
<img src="../../snowfx.png" alt="SnowFX" width="300">

**Warning:**
- You can add "all" to the config to generate snow textures for every map.
- This may cause some walls or other non-ground surfaces to also be covered in snow, because some maps use the same texture for both floors and walls.
- The more maps you include, the higher the chance that snow will be applied incorrectly in certain places.

**Installation:**
- Place the module inside the modules folder.
- Create a folder named WinterFX inside modules, and put the snowfloor.vtf texture file inside it.
- Run the core executable and wait for it to generate snow textures for all installed maps.
- Once the console prints that it’s finished, launch the game.

- By default, it generates snow textures only for maps starting with "de_" and "cs_".
- If you want to modify this, open modules/configs/winterfx_config.json and add the full map name or mode prefix (e.g., "mg_").
- After editing the config, delete the maps.txt file inside modules/WinterFX and run the core executable again so it can regenerate textures using the new settings.
- Deleting maps.txt is required after any configuration change.

**Credits:**
- [@Feykich](https://github.com/Feykich) – providing maps, testing, and advice
- [@Moltard](https://github.com/Moltard) – advice on texture face recognition
- @ficool2 – suggesting an optimal route by calculating texture face points

# [RU]
***[ANY] WinterFX | Snow on the ground:***

- Мгновенно превращает любую карту в зимнюю сцену, заменяя поверхности земли текстурами, покрытыми снегом.
- Работает автоматически на каждой установленной карте.
- Определяет поверхности, направленные вверх (полы, грунт, крыши и т. д.), и применяет пользовательскую снеговую текстуру для реалистичного покрытия.
<img src="../../snowfx.png" alt="SnowFX" width="300">

**Внимание:**
- Вы можете добавить "all" в конфигурацию, чтобы сгенерировать снеговые текстуры для всех карт.
- Это может привести к тому, что некоторые стены или другие поверхности, не являющиеся полом, также будут покрыты снегом, так как на некоторых картах одна и та же текстура используется и для пола, и для стен.
- Чем больше карт включено, тем выше вероятность того, что снег будет применён некорректно в некоторых местах.

**Установка:**
- Поместите модуль в папку modules.
- Создайте внутри modules папку WinterFX и положите в неё файл текстуры snowfloor.vtf.
- Запустите основной исполняемый файл и дождитесь, пока он сгенерирует снеговые текстуры для всех установленных карт.
- После того как в консоли появится сообщение о завершении, запустите игру.

- По умолчанию текстуры создаются только для карт, начинающихся с "de_" и "cs_".
- Если вы хотите изменить это, откройте modules/configs/winterfx_config.json и добавьте полное название карты или префикс режима (например, "mg_").
- После изменения конфигурации удалите файл maps.txt в modules/WinterFX и снова запустите основной исполняемый файл, чтобы текстуры были сгенерированы заново с учётом новых настроек.
- Удаление maps.txt является обязательным после любых изменений конфигурации.

**Благодарности:**
- [@Feykich](https://github.com/Feykich) – предоставление карт, тестирование и советы
- [@Moltard](https://github.com/Moltard) – советы по распознаванию сторон текстур
- @ficool2 – предложение оптимального решения с расчётом точек сторон текстур
