# css-enhancer-src

**Compile the core into an executable using the following command:**

```
pyinstaller --noconsole --onefile css_enhancer.py ^ 
--hidden-import=colorsys ^
--hidden-import=tkinter.font ^
--hidden-import=win32gui ^
--hidden-import=win32process ^
--hidden-import=watchdog.observers ^
--hidden-import=watchdog.events ^
--hidden-import=psutil ^
--hidden-import=pydirectinput ^
--add-data "site-packages\watchdog;watchdog" ^
--add-data "site-packages\pywin32_system32;pywin32_system32" ^
--add-data "site-packages\psutil;psutil" ^
--add-data "site-packages\pydirectinput;pydirectinput" ^
--add-data "lang;lang" ^
--noupx --icon=icon.ico --add-data "csench.ico;."
```

**Keep the icon file next to the .py to compile** 
