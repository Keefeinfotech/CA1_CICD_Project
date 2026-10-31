/*
 * File Name: swagger.ts
 * Description: Configures Swagger UI and OpenAPI documentation for the API.
 * Author: Keefe Chen
 * Date: 27 October 2026
 */

import swaggerUi from "swagger-ui-express";
import type { OpenAPIV3 } from "openapi-types";

const userSchema: OpenAPIV3.SchemaObject = {
  type: "object",
  properties: {
    id: { type: "string" },
    name: { type: "string", nullable: true },
    email: { type: "string", format: "email" },
  },
};

export const swaggerDocument: OpenAPIV3.Document = {
  openapi: "3.0.3",
  info: {
    title: "Personal Secretary API",
    version: "1.0.0",
    description: "API documentation for authentication and the AI assistant.",
  },
  servers: [
    {
      url: "http://localhost:3000",
      description: "Local development server",
    },
  ],
  components: {
    securitySchemes: {
      bearerAuth: { type: "http", scheme: "bearer", bearerFormat: "JWT" },
    },
    schemas: {
      User: userSchema,
      Error: {
        type: "object",
        properties: {
          error: { type: "string" },
          code: { type: "string" },
        },
      },
    },
  },
  paths: {
    "/api/health": {
      get: {
        summary: "Check API health",
        responses: { "200": { description: "API is running successfully" } },
      },
    },
    "/api/auth/signup": {
      post: {
        summary: "Create an account",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                required: ["email", "password"],
                properties: {
                  name: { type: "string", maxLength: 80 },
                  email: { type: "string", format: "email" },
                  password: { type: "string", minLength: 8, maxLength: 128 },
                  captchaToken: {
                    type: "string",
                    description:
                      "Cloudflare Turnstile token. Required when CAPTCHA_ENABLED=true.",
                  },
                },
              },
            },
          },
        },
        responses: {
          "201": {
            description: "Account created",
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    token: { type: "string" },
                    user: { $ref: "#/components/schemas/User" },
                  },
                },
              },
            },
          },
          "400": { description: "Validation failed" },
          "409": { description: "Email already registered" },
        },
      },
    },
    "/api/auth/login": {
      post: {
        summary: "Sign in",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                required: ["email", "password"],
                properties: {
                  email: { type: "string", format: "email" },
                  password: { type: "string" },
                  captchaToken: {
                    type: "string",
                    description:
                      "Cloudflare Turnstile token. Required when CAPTCHA_ENABLED=true.",
                  },
                },
              },
            },
          },
        },
        responses: {
          "200": {
            description: "Signed in",
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    token: { type: "string" },
                    user: { $ref: "#/components/schemas/User" },
                  },
                },
              },
            },
          },
          "400": { description: "Validation failed or CAPTCHA rejected" },
          "401": { description: "Invalid credentials" },
          "429": { description: "Too many attempts" },
        },
      },
    },
    "/api/auth/me": {
      get: {
        summary: "Get the signed-in user",
        security: [{ bearerAuth: [] }],
        responses: {
          "200": {
            description: "Current user",
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: { user: { $ref: "#/components/schemas/User" } },
                },
              },
            },
          },
          "401": {
            description:
              "Missing/expired token, or the session was replaced by a newer login",
          },
        },
      },
    },
    "/api/auth/logout": {
      post: {
        summary: "End the current session",
        security: [{ bearerAuth: [] }],
        responses: {
          "204": { description: "Session ended" },
          "401": { description: "Authentication required" },
        },
      },
    },
    "/api/ai/chat": {
      post: {
        summary: "Send a message to the assistant",
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                required: ["message"],
                properties: {
                  message: { type: "string", maxLength: 1000 },
                },
              },
            },
          },
        },
        responses: {
          "200": { description: "Assistant reply" },
          "401": { description: "Authentication required" },
        },
      },
    },
  },
};

export { swaggerUi };
