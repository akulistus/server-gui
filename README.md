# Настройка

1. Необходимо установить путь до директории, содрежащей сигналы.
Для этоо необходимо нажать на кнопку *открыть* в окне debug.

Или можно в модуле *GuiMoD/src/GuiMod.jl* указать путь к директории, прописав его в константу:
``` julia
const PATH = "path/to/your/directory"
```

2. При необходимости можно изменить *USER, PORT, HOST* в модуле *GuiMoD/src/httpRequests.jl*:
``` julia
const USER = "Your username"
const PORT = "Your port"
const HOST = "Your host"
```
Начальные настройки:
``` julia
const USER = "tmp"
const PORT = "8089"
const HOST = "0.0.0.0"
```
3. Там же можно изменить начальные настройки филтрации:
``` julia
const FILTERS = "Your filters"
```
Начальные настройки:
``` julia
const FILTERS = "isoline,50Hz"
```

# "Особенности"

1. Расшифровка цветов ChannelBounds.

![Alt text](screenshots/ColorCoding.png)
