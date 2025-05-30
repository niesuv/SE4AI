# app/connectors/search_connector.py

import logging
from typing import List, Dict, Optional
import asyncio

from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from app.config import SearchConfig  # Assuming SearchConfig is in app.config

logger = logging.getLogger(__name__)


class SearchConnector:
    """
    Connector for Google Custom Search Engine API.
    """

    def __init__(self, settings: SearchConfig):
        """
        Initializes the SearchConnector.

        Args:
            settings: Search configuration containing API key and CSE ID.
        """
        self.api_key: Optional[str] = settings.api_key
        self.cse_id: Optional[str] = settings.cse_id
        self.max_results: int = settings.max_results

        if not self.api_key:
            logger.warning("GOOGLE_CSE_API_KEY is not set. Search will not function.")
        if not self.cse_id:
            logger.warning("GOOGLE_CSE_ID is not set. Search will not function.")

        self.service = None
        if self.api_key:  # Only build service if API key is present
            try:
                self.service = build("customsearch", "v1", developerKey=self.api_key)
                logger.info("Google Custom Search service initialized.")
            except Exception as e:
                logger.error(
                    f"Failed to initialize Google Custom Search service: {e}",
                    exc_info=True,
                )
                self.service = None  # Ensure service is None if build fails
        else:
            logger.error(
                "Google Custom Search service could not be initialized due to missing API key."
            )

    def _perform_search_sync(self, query_string: str) -> List[Dict[str, str]]:
        """
        Synchronous method to perform the actual search.
        """
        if not self.service or not self.cse_id:
            logger.error(
                "Search service not available or CSE ID missing. Cannot perform search."
            )
            return []

        results_list: List[Dict[str, str]] = []
        try:
            logger.info(f"Executing search for: '{query_string}'")
            search_response = (
                self.service.cse()
                .list(q=query_string, cx=self.cse_id, num=self.max_results)
                .execute()
            )

            items = search_response.get("items", [])
            for item in items:
                results_list.append(
                    {
                        "title": item.get("title"),
                        "snippet": item.get("snippet"),
                        "link": item.get("link"),
                    }
                )
            logger.info(f"Search returned {len(results_list)} results.")
            return results_list

        except HttpError as e:
            logger.error(
                f"Google CSE API HttpError: {e.resp.status} {e._get_reason()}",
                exc_info=True,
            )
            # You might want to check e.resp.status for specific error codes (e.g., 403 for quota)
            if e.resp.status == 403:
                logger.error("Quota possibly exceeded for Google Custom Search API.")
            return []  # Return empty list on API error
        except Exception as e:
            logger.error(
                f"An unexpected error occurred during Google search: {e}", exc_info=True
            )
            return []

    async def search_google_cse(self, keywords: List[str]) -> List[Dict[str, str]]:
        """
        Performs a search using Google Custom Search Engine API with the given keywords.

        Args:
            keywords: A list of keywords to search for.

        Returns:
            A list of search results, where each result is a dictionary
            containing 'title', 'snippet', and 'link'. Returns an empty list on failure or no results.
        """
        if not self.api_key or not self.cse_id:
            logger.warning(
                "Search API key or CSE ID is missing. Cannot perform search."
            )
            return []
        if not self.service:
            logger.error("Search service not initialized. Cannot perform search.")
            return []
        if not keywords:
            logger.warning("No keywords provided for search.")
            return []

        query_string = " ".join(keywords)  # Combine keywords into a single query string

        try:
            # Run the synchronous Google API client call in a separate thread
            # to avoid blocking the asyncio event loop.
            loop = asyncio.get_running_loop()
            results = await loop.run_in_executor(
                None,  # Uses the default ThreadPoolExecutor
                self._perform_search_sync,
                query_string,
            )
            return results
        except Exception as e:
            logger.error(f"Error running search in executor: {e}", exc_info=True)
            return []
