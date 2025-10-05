import json
import sys
import os
from urllib.parse import unquote

# Import the AST parser
from ast_roller import parser, transformer


def lambda_handler(event, _context):
    """
    AWS Lambda handler for die rolling functionality.
    
    Processes roll strings from API Gateway path parameters and returns
    either the roll results or validation errors.
    """
    path_parameters = event['pathParameters'] or {}
    roll_string = path_parameters.get("rollString", "1d20")
    
    # URL decode the path parameter since API Gateway passes encoded values
    roll_string = unquote(roll_string)

    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'GET,OPTIONS',
        'Content-Type': 'application/json'
    }

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
            "headers": headers,
            "body": json.dumps(result)
        }
    except Exception as e:
        return {
            "statusCode": 400,
            "headers": headers,
            "body": json.dumps({"error": str(e)})
        }


