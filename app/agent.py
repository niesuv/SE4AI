# app/agent.py

import logging
from typing import Optional

from app.config import Settings
from app.connectors.gemini_connector import GeminiConnector, LLMConfig

logger = logging.getLogger(__name__)


class AgricultureAgent:
    """
    Main agent orchestrating interactions with LLMs and other services.
    Currently focuses on routing queries using a basic LLM.
    """

    def __init__(self, settings: Settings):
        """
        Initialize the AgricultureAgent.

        Args:
            settings: Application configuration settings.
        """
        self.settings = settings
        self.gemini_connector: Optional[GeminiConnector] = None

        if not self.settings.gemini_api_key or not self.settings.gemini_api_key:
            logger.error("Gemini API key not configured. Agent initialization failed.")
        else:
            try:
                self.gemini_connector = GeminiConnector(
                    api_key=self.settings.gemini_api_key
                )
                logger.info("AgricultureAgent initialized successfully.")
            except (ValueError, ConnectionError) as e:
                logger.error(
                    f"Failed to initialize GeminiConnector: {e}", exc_info=True
                )

        if not self.settings.basic_router_prompt:
            logger.warning("Basic router prompt not loaded. Agent may malfunction.")

        if not self.settings.agent.allowed_topics and "{{allowed_topics}}" in (
            self.settings.basic_router_prompt or ""
        ):
            logger.warning("Allowed topics undefined but required by router prompt.")

    async def handle_query(self, user_query: str) -> str:
        """
        Process incoming user query using basic LLM for routing and responses.

        Args:
            user_query: User's input query string.

        Returns:
            LLM response - direct answer, refusal, or advanced mode marker.
        """
        if not self.gemini_connector:
            logger.error("GeminiConnector unavailable. Cannot process query.")
            return "Sorry, I cannot process your request due to a configuration error."

        if not self.settings.basic_router_prompt:
            logger.error("Basic router prompt unavailable. Cannot process query.")
            return "Sorry, I'm experiencing internal configuration issues. Please try again later."

        if not user_query:
            logger.warning("Empty user query received.")
            return "Please provide your question or request."

        try:
            logger.info(f"Processing query: '{user_query[:100]}...'")

            llm_response = self.gemini_connector.generate_response(
                user_query=user_query,
                llm_config=self.settings.basic_llm,
                system_instruction=self.settings.basic_router_prompt,
            )

            logger.info(f"LLM response generated: '{llm_response[:100]}...'")
            return llm_response

        except ConnectionError as e:
            logger.error(
                f"Connection error during query processing: {e}", exc_info=True
            )
            return "Sorry, I cannot connect to the processing service. Please try again later."
        except TypeError as e:
            logger.error(f"Type error in connector method call: {e}", exc_info=True)
            return "Sorry, there's a configuration issue with the AI service. Please contact support."
        except ValueError as e:
            logger.error(f"Value error during query processing: {e}", exc_info=True)
            return f"Sorry, an error occurred while processing your request: {e}"
        except RuntimeError as e:
            logger.error(f"Runtime error during query processing: {e}", exc_info=True)
            return "Sorry, an unexpected error occurred. Please try again later."
        except Exception as e:
            logger.error(f"Unexpected error in handle_query: {e}", exc_info=True)
            return "Sorry, I encountered an unknown error. Please try again later."
