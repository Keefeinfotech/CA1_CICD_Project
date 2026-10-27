/*
 * File Name: swagger.ts
 * Description: Configures Swagger UI and OpenAPI documentation for the API.
 * Author: Keefe Chen
 * Date: 27 October 2026
 */

import swaggerUi from "swagger-ui-express";
import type { OpenAPIV3 } from "openapi-types";

export const swaggerDocument: OpenAPIV3.Document = {
  openapi: "3.0.3",
  info: {
    title: "Personal Secretary API",
    version: "1.0.0",
    description: "API documentation for managing tasks and administrative activities."
  },
  servers: [
    {
      url: "http://localhost:3000",
      description: "Local development server"
    }
  ],
  paths: {
    "/api/health": {
      get: {
        summary: "Check API health",
        description: "Checks whether the API is responding.",
        responses: {
          "200": {
            description: "API is running successfully"
          }
        }
      }
    }
  }
};

export { swaggerUi };