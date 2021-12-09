# [NMRiH] Electrified Keypads
When a player enters a keypad PIN incorrectly they receive an electric shock in an attempt to deter brute force attacks. 
By default, the damage increases in increments of 5 (starting at 5 damage) for every failed attempt

![image](https://user-images.githubusercontent.com/11559683/145389544-b4703c75-03b3-49f5-a582-a074cbf7453d.png)

## CVars

Cvars are saved to `cfg/sourcemod/plugin.electrified-keypads.cfg`

- `sm_keypad_shock_damage_enabled` (Default: 1)
  - Enables the plugin

- `sm_keypad_shock_damage_base` (Default: 5)
  - Base damage to deal on each wrong attempt
  
- `sm_keypad_shock_damage_multiplier` (Default: 5)
  - Scale base damage by this amount on each new wrong attempt
  
- `sm_keypad_shock_viewpunch` (Default: -5.0)
  - Viewpunch Z angles on a wrong attempt, negative is upward force.
