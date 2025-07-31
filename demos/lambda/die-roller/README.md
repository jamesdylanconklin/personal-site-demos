# die-roller

This will define a lambda, written in python, that will process a provided roll string and either reject it as invalid or simulate rolling the required dice and return the raw rolls and the composite result.

Valid roll strings shall be empty, static whole numbers, rolls expressed as xdy, where x denotes the number of dice, y denotes the size, and omitted dice counts shall be interpreted as 1; or simple arithmetic combinations of numbers and dice rolls.

## Examples

### Valid

| Input | Description |
|-------|-------------|
| (blank) | Roll a single d20 by default |
| `3d6` | Roll 3 six-sided dice, and sum the results. A raw ability score roll |
| `d20+10` | Roll one d20 and add 10. An attack roll or save |
| `d8+4+2d6` | e.g a muscle rogue's sneak attack with a longsword |
| `2d4*2d4` | Valid, but unlikely. Roll 2d4 twice and multiply the results.|

### Invalid

| Input | Description |
|-------|-------------|
| 6 3d6 | Array rolls are not supported yet |
| 3*(4_5) | No parentheticals yet. We're sticking to the MDAS of PEMDAS.
| d20^4 | Seriously, buddy? When does that come up? |
| d20+10, d8+4 | Same thing as array rolls. Not supported yet |

## Implementation

Terraform-defined GW resources should pull the roll string as a path variable and pass it as a string to the lambda handler's event input. The top-level handler should parse the given string down into xdy roll, whole number, or simple arithmetic operator primitives, resolve the rolls, and then calculate the result.