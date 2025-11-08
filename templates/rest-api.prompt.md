# REST API Endpoint Template

## Objective
Create a RESTful API endpoint with proper error handling, validation, and documentation.

## Endpoint Details
- **Path**: /api/v1/[RESOURCE]
- **Method**: [GET|POST|PUT|DELETE]
- **Authentication**: [Required|Optional|None]

## Requirements

### Request
- **URL Parameters**:
  - Describe any URL parameters

- **Query Parameters**:
  - Describe query parameters

- **Request Body** (if applicable):
```json
{
  "field1": "type and description",
  "field2": "type and description"
}
```

### Response
- **Success Response** (200/201):
```json
{
  "status": "success",
  "data": {}
}
```

- **Error Responses**:
  - 400: Bad Request
  - 401: Unauthorized
  - 404: Not Found
  - 500: Server Error

## Implementation Requirements
1. Input validation for all parameters
2. Proper error handling with descriptive messages
3. Rate limiting (if applicable)
4. Logging for debugging
5. Unit tests covering success and error cases
6. API documentation (OpenAPI/Swagger)

## Technology Stack
- Language: [Python/Node.js/Go/etc.]
- Framework: [Express/Flask/FastAPI/etc.]
- Database: [PostgreSQL/MongoDB/etc.]

## Best Practices
- Follow RESTful conventions
- Use appropriate HTTP status codes
- Implement CORS if needed
- Add request/response logging
- Include API versioning
