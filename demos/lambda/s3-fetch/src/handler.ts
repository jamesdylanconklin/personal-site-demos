import {
  GetObjectCommand,
  NoSuchKey,
  S3Client,
  S3ServiceException,
} from "@aws-sdk/client-s3";

import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';

const responseEncoder = new TextEncoder();
const response403 = responseEncoder.encode('<!DOCTYPE html><html><head><title>403</title></head><body><h1>403 Forbidden</h1></body></html>');

export const handler = async (
  event: APIGatewayProxyEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {
  try {
    var body : Uint8Array = response403;
    var contentType : string = 'application/octet-stream';
    var httpCode : number = 200;

    // Extract objectKey from path parameters
    var objectKey: string | undefined = event.pathParameters?.objectKey;

    const clientParams : { region?: string } = {}

    if (process.env.AWS_REGION) {
      clientParams.region = process.env.AWS_REGION;
    }

    const s3Client : S3Client = new S3Client(clientParams)

    const params = {
      Bucket: process.env.BUCKET_NAME,
      Key: objectKey
    };

    const resp = await s3Client.send(
      new GetObjectCommand(params)
    ).catch((error) => {
      httpCode = 403;
      contentType = 'text/html';
      body = response403;
      if (error instanceof NoSuchKey) {
        console.log(`Object with key ${params.Key} does not exist in bucket ${params.Bucket}.`);
      } else if (error instanceof S3ServiceException) {
        console.error(`S3 service error: ${error.message}`);
      } else {
        console.error(`Unexpected error: ${error.message}`);
      }
    });

    if (resp && resp.Body) {
      body = await resp.Body.transformToByteArray();
      contentType = resp.ContentType || 'application/octet-stream';
    }
    
    return {
      statusCode: httpCode,
      body: Buffer.from(body).toString('base64'),
      isBase64Encoded: true,
      headers: {
        'Content-Type': contentType,
      },
    };
  } catch (error) {
    console.log('Top-level error occurred:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: 'Internal server error'
      })
    };
  }
};