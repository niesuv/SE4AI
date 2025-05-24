# app/connectors/gemini_connector.py

import logging
from typing import Optional, Dict, Any

from google import genai
from google.genai import types
from google.api_core import exceptions as google_api_exceptions

from app.config import LLMConfig

logger = logging.getLogger(__name__)


class GeminiConnector:
    """
    Connector for interacting with Google Gemini models.
    """

    def __init__(self, api_key: str):
        """
        Initialize the Gemini client.

        Args:
            api_key: The Google Gemini API key.
        """
        if not api_key:
            raise ValueError("GEMINI_API_KEY is required for GeminiConnector.")

        try:
            self.client = genai.Client(api_key=api_key)
            logger.info("GeminiConnector initialized successfully.")
        except Exception as e:
            logger.error(f"Failed to initialize Gemini client: {e}")
            raise ConnectionError(f"Could not initialize Gemini client: {e}") from e

    def generate_response(
        self,
        user_query: str,
        llm_config: LLMConfig,
        system_instruction: Optional[str] = None,
    ) -> str:
        """
        Generate a text response from a Gemini model.

        Args:
            user_query: The user's query or input text.
            llm_config: Configuration for the LLM.
            system_instruction: Optional system-level instructions for the model.

        Returns:
            The generated text response from the model.

        Raises:
            ValueError: If the model fails to generate a response or returns an empty one.
            ConnectionError: If there's an issue communicating with the Gemini API.
        """
        if not user_query:
            logger.warning("User query is empty.")
            return ""

        model_name = llm_config.model_name

        try:
            logger.debug(
                f"Sending request to Gemini model '{model_name}' with query: '{user_query[:100]}...'"
            )

            # Prepare generation config
            generation_config = types.GenerateContentConfig(
                temperature=llm_config.temperature,
                max_output_tokens=llm_config.max_output_tokens,
                top_p=llm_config.top_p,
                top_k=llm_config.top_k,
            )

            # Add system instruction if provided
            if system_instruction:
                generation_config.system_instruction = system_instruction

            # Generate response
            response = self.client.models.generate_content(
                model=model_name,
                contents=[user_query],
                config=generation_config,
            )

            if response and response.text:
                logger.info(
                    f"Successfully received response from Gemini model '{model_name}'."
                )
                return response.text.strip()
            else:
                logger.error(
                    f"Gemini model '{model_name}' returned an empty or invalid response."
                )

                # Check for safety blocks
                if response and response.candidates:
                    for candidate in response.candidates:
                        if (
                            hasattr(candidate, "finish_reason")
                            and candidate.finish_reason.name == "SAFETY"
                        ):
                            logger.warning(
                                f"Content blocked due to safety reasons: {candidate.safety_ratings}"
                            )
                            raise ValueError(
                                f"Content blocked by safety filters. Ratings: {candidate.safety_ratings}"
                            )

                raise ValueError(
                    f"Gemini model '{model_name}' returned an empty response."
                )

        except google_api_exceptions.GoogleAPIError as e:
            logger.error(
                f"Gemini API error for model '{model_name}': {e}", exc_info=True
            )
            raise ConnectionError(f"Gemini API error: {e}") from e
        except Exception as e:
            logger.error(
                f"Unexpected error while calling Gemini model '{model_name}': {e}",
                exc_info=True,
            )
            raise RuntimeError(f"Unexpected error during Gemini API call: {e}") from e
