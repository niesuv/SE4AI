import logging
import uvicorn
from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field

from app.config import Settings
from app.agent import AgricultureAgent

# --- Logging Configuration ---
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


# --- Pydantic Models for API ---
class QueryRequest(BaseModel):
    user_query: str = Field(
        ...,
        min_length=1,
        max_length=5000,  # Adjust as needed
        description="The user's query for the Agriculture Agent.",
    )
    # session_id: Optional[str] = None # For future context management


class QueryResponse(BaseModel):
    agent_response: str = Field(..., description="The agent's response to the query.")
    # session_id: Optional[str] = None
    # debug_info: Optional[dict] = None # For returning additional debug info if needed


# --- FastAPI Application Setup ---
app = FastAPI(
    title="Agriculture AI Agent API",
    description="API for interacting with the Agriculture AI Agent.",
    version="0.1.0",
)

# --- Global Objects ---
# It's generally better to initialize these within a startup event or manage their lifecycle
# if they involve complex setup (like database connections). For this case, direct init is okay.
try:
    settings = Settings()
    # Override log level from settings if it's more specific
    logging.getLogger().setLevel(settings.agent.log_level.upper())
    logger.info(f"Application log level set to: {settings.agent.log_level.upper()}")

    agent = AgricultureAgent(settings=settings)
    logger.info(
        "FastAPI application started with initialized Settings and AgricultureAgent."
    )

except Exception as e:
    logger.fatal(
        f"CRITICAL: Failed to initialize Settings or AgricultureAgent at startup: {e}",
        exc_info=True,
    )
    agent = None  # Ensure agent is None if initialization fails


@app.on_event("startup")
async def startup_event():
    if agent is None:
        logger.error(
            "AgricultureAgent was not initialized. API may not function correctly."
        )
    else:
        logger.info("AgricultureAgent is ready.")
    if not settings.gemini_api_key:
        logger.warning(
            "GEMINI_API_KEY is not set. Basic LLM functionality will be unavailable."
        )
    if not settings.search.api_key or not settings.search.cse_id:
        logger.warning(
            "GOOGLE_CSE_API_KEY or GOOGLE_CSE_ID is not set. Search functionality will be unavailable for advanced mode."
        )


# --- API Endpoints ---
@app.get("/", summary="Health Check", description="Basic health check endpoint.")
async def root():
    return {"status": "healthy", "message": "Welcome to the Agriculture AI Agent API!"}


@app.post(
    "/query",
    response_model=QueryResponse,
    summary="Submit a query to the Agriculture Agent",
    description="Receives a user query and returns the agent's response. Currently uses the basic LLM router.",
)
async def handle_agent_query(request: QueryRequest):
    """
    Endpoint to process user queries via the AgricultureAgent.
    """
    if agent is None:
        logger.error("Attempted to handle query, but agent is not initialized.")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="The agent is not available due to an initialization error. Please check server logs.",
        )

    if not request.user_query.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="user_query cannot be empty.",
        )

    try:
        logger.info(f"Received query via API: '{request.user_query[:100]}...'")
        response_from_agent = await agent.handle_query(user_query=request.user_query)
        logger.info(f"Sending API response: '{response_from_agent[:100]}...'")
        return QueryResponse(agent_response=response_from_agent)

    except HTTPException:
        # Re-raise HTTPException if it's already one (e.g. from validation)
        raise
    except Exception as e:
        logger.error(f"Unhandled exception in /query endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An unexpected internal server error occurred: {str(e)}",
        )


# --- To run the application (for local development) ---.
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
