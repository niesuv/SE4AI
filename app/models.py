from pydantic import BaseModel
from typing import Optional


class QueryRequest(BaseModel):
    """
    Represents the request body for the /query endpoint.
    """

    user_query: str
    # session_id: Optional[str] = None # Future consideration for session management


class AgentResponse(BaseModel):
    """
    Represents the response body from the /query endpoint.
    """

    response_text: str
    mode: str  # Indicates the agent's processing mode for the query
    # e.g., "direct", "advanced_triggered", "declined", "persona_response", "error"
