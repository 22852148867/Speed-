# Speed Script

Скрипт для Roblox с поддержкой Delta Injector.

## Использование

### Через Delta Injector:

```lua
local Settings = {
    JoinTeam = "Pirates"; -- Pirates / Marines
    Translator = true;   -- true / false
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/22852148867/Speed-/main/main.luau"))(Settings)
```

### Или использовать loader:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/22852148867/Speed-/main/loader.lua"))()
```

## Настройки

- **JoinTeam**: "Pirates" или "Marines" - выбор команды при загрузке
- **Translator**: true/false - включение режима переводчика

## Файлы

- `main.luau` - основной скрипт
- `loader.lua` - загрузчик для Delta Injector
