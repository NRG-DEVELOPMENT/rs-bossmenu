# rs-bossmenu

Premium boss menu resource with a modern NUI inspired by premium management menus.

## Features

- High quality dark glass UI
- QBCore + ESX support
- Society banking support:
  - Renewed-Banking
  - qb-management
  - qb-banking
  - esx_addonaccount
  - SQL fallback
- Employee management:
  - hire nearby
  - promote
  - demote
  - fire
- Online and offline employee support
- Recent activity logs
- Search and sort employees
- Command open and optional ox_target support
- Config layout designed for quick server-side customization

## Dependencies

- ox_lib
- oxmysql

## Optional integrations

- Renewed-Banking
- qb-management
- qb-banking
- esx_addonaccount
- ox_target
- qb-target
- ox_inventory
- qb-inventory

## Command

`/bossmenu`

## Export

```lua
exports['rs-bossmenu']:OpenBossMenu('police')
```

## Notes

Inventory support is intentionally limited to ox_inventory and qb-inventory.
