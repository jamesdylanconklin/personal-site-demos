# Lambda Source Code

This directory contains the Python source code for the die-roller Lambda function.

## Files

- `handler.py` - Main Lambda handler function

## Functionality

The Lambda function processes dice roll strings and returns:
- Raw dice rolls
- Total sum
- Error messages for invalid inputs

## Supported Roll Formats

- Empty string: Default d20 roll
- Simple dice: `d20`, `3d6`
- Static numbers: `5`, `10`
- Basic arithmetic: `d20+10`, `2d4*2d4` (planned)

## Development

This is a basic implementation. Full parsing of complex roll strings (as described in the main README) would be implemented here.
