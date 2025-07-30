import json
import random
import re

PRIMITIVE_ROLL_PATTERN = r"^(\d*)d(\d+)$"


def lambda_handler(event, _context):
    """
    AWS Lambda handler for die rolling functionality.
    
    Processes roll strings from API Gateway path parameters and returns
    either the roll results or validation errors.
    """
    # Handle case where pathParameters is None (no path params in request)
    path_params = event.get("pathParameters") or {}
    roll_string = path_params.get("rollString", "1d20")

    try:
        result = evaluate_roll_string(roll_string)
        return {
            "statusCode": 200,
            "body": json.dumps(result)
        }
    except ValueError as e:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": str(e)})
        }


def roll(num_dice, num_sides):
    """
    Roll a specified number of dice with a given number of sides.
    
    Args:
        num_dice (int): Number of dice to roll
        num_sides (int): Number of sides on each die
        
    Returns:
        List of per-die roll results.
    """
    return [random.randint(1, num_sides) for _ in range(num_dice)]


def combine_results(left_result, right_result, operator):
    """
    Combine two roll results based on the specified operator.
    
    Args:
        left_result (dict): Left operand result
        right_result (dict): Right operand result
        operator (str): Operator to apply ('+', '-', '*', '/')
        
    Returns:
       Dictionary of total => int and rolls => dict of roll strings to a list of their raw rolls.
       e.g. {'total': 17, 'rolls': {'d8': [[3]], '3d6': [[2, 4, 5]]}}
    """

    left_total = left_result.get("total")
    right_total = right_result.get("total") 

    combined_rolls = {}

    for raw_rolls in map(lambda result: result['rolls'], [left_result, right_result]):
        for die, rolls in raw_rolls.items():
            if die in combined_rolls:
                combined_rolls[die].extend(rolls)
            else:
                combined_rolls[die] = rolls

    match operator:
        case '+':
            total = left_total + right_total
        case '-':
            total = left_total - right_total
        case '*':
            total = left_total * right_total
        case '/':
            total = left_total // right_total

    return {
        "total": total,
        "rolls": combined_rolls
    }

def evaluate_roll_string(roll_string):
    """
    Parse and execute a roll string.
    
    Args:
        roll_string (str): Roll string like "3d6", "d20+10", etc.
        
    Returns:
        dict: Contains 'total' and 'rolls' mapping
              e.g. {'total': 17, 'rolls': {'d8': [[3]], '3d6': [[2, 4, 5]]}}
        
        rolls mappings are lists of lists to allow for duplicate sub-rolls.
        Should such exist, they will be ordered by their position in the roll string.      
    Raises:
        ValueError: For invalid roll strings
    """ 
    if re.match(PRIMITIVE_ROLL_PATTERN, roll_string):
        num_dice, num_sides = re.match(PRIMITIVE_ROLL_PATTERN, roll_string).groups()
        if not num_dice:
            num_dice = 1
        else:
            num_dice = int(num_dice)
        
        num_sides = int(num_sides)

        roll_result = roll(num_dice, num_sides)

        return {
            "total": sum(roll_result),
            "rolls": { roll_string: [roll_result] }
        }
    
    if re.match(r"^\d+$", roll_string):
        return {
            "total": int(roll_string),
            "rolls": {}
        }
    
    operator_match = re.search(r"[+-]", roll_string)

    if operator_match is None:
        operator_match = re.search(r"[/*]", roll_string)

    if operator_match is None:    
        raise ValueError(f"Invalid roll string: {roll_string}")
    
    split_index = operator_match.start()
    left_part = roll_string[:split_index]
    right_part = roll_string[split_index + 1:]  

    return combine_results(
        evaluate_roll_string(left_part),
        evaluate_roll_string(right_part),
        roll_string[split_index]
    )

