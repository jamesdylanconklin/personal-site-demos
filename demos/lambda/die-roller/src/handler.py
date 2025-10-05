import json
import sys
import os

# Import the AST parser
from ast_roller import parser, transformer


def lambda_handler(event, _context):
    """
    AWS Lambda handler for die rolling functionality.
    
    Processes roll strings from API Gateway path parameters and returns
    either the roll results or validation errors.
    """
    roll_string = event.get("pathParameters", {}).get("rollString", "1d20")

    try:
        # Parse and evaluate using the AST parser
        parsed_tree = parser.parse(roll_string)
        transformed = transformer.transform(parsed_tree)
        roll_result = transformed.evaluate()
        
        # Convert to our expected format
        result = {
            "roll_result": roll_result.raw_result,
            # TODO: When ast_roller exposes results tree, show roll breakdown.
        }
        
        return {
            "statusCode": 200,
            "body": json.dumps(result)
        }
    except Exception as e:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": str(e)})
        }


