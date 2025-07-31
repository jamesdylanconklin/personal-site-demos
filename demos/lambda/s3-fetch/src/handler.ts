import { S3Client } from '@aws-sdk/client-s3';
import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

// Initialize S3 client - no credentials needed, inherits from execution role
const s3Client = new S3Client({ 
  region: process.env.AWS_REGION || 'us-east-1' 
});

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Hello from S3 Fetch Lambda!',
        timestamp: new Date().toISOString(),
        requestId: event.requestContext.requestId
      })
    };
  } catch (error) {
    console.log('Error occurred:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: 'Internal server error'
      })
    };
  }
};