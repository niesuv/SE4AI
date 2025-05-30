import logging
from typing import Optional, List, Dict, Set, Tuple
import asyncio
import re

from app.config import Settings
from app.connectors.gemini_connector import GeminiConnector, LLMConfig
from app.connectors.search_connector import SearchConnector
from app.connectors.content_scraper import ContentScraper

logger = logging.getLogger(__name__)

MAX_LINKS_TO_SCRAPE_PER_ITERATION = 3


class AgricultureAgent:
    """
    Main agent orchestrating interactions with LLMs and other services.
    Supports basic routing and advanced mode with iterative search and evaluation.
    """

    def __init__(self, settings: Settings):
        self.settings = settings
        self.llm_connector: Optional[GeminiConnector] = None
        self.search_connector: Optional[SearchConnector] = None
        self.content_scraper: ContentScraper = ContentScraper()

        # Initialize Connectors
        if self.settings.gemini_api_key:
            try:
                self.llm_connector = GeminiConnector(
                    api_key=self.settings.gemini_api_key
                )
                logger.info("GeminiConnector initialized.")
            except Exception as e:
                logger.error(
                    f"Failed to initialize GeminiConnector: {e}", exc_info=True
                )
        else:
            logger.error("Gemini API key not configured.")

        if self.settings.search.api_key and self.settings.search.cse_id:
            try:
                self.search_connector = SearchConnector(settings=self.settings.search)
                logger.info("SearchConnector initialized.")
            except Exception as e:
                logger.error(
                    f"Failed to initialize SearchConnector: {e}", exc_info=True
                )
        else:
            logger.warning("Search API key or CSE ID missing. Search disabled.")

        # Load prompts
        if not self.settings.basic_router_prompt:
            logger.warning("Basic router prompt missing.")
        if not self.settings.initial_search_query_prompt:
            logger.warning("Initial search query prompt missing.")
        if not self.settings.information_evaluation_and_refinement_prompt:
            logger.warning("Info eval & refinement prompt missing.")
        if not self.settings.advanced_rag_prompt:
            logger.warning("Advanced RAG prompt missing.")

    async def _generate_llm_response(
        self, full_prompt: str, llm_config: LLMConfig
    ) -> str:
        if not self.llm_connector:
            return ""
        try:
            return await asyncio.to_thread(
                self.llm_connector.generate_response,
                user_query=full_prompt,
                llm_config=llm_config,
                system_instruction=None,
            )
        except Exception as e:
            logger.error(f"Error during LLM call: {e}", exc_info=True)
            return ""

    async def _generate_initial_search_queries(self, user_query: str) -> List[str]:
        if not self.settings.initial_search_query_prompt:
            return []
        prompt = self.settings.initial_search_query_prompt.replace(
            "{{user_query}}", user_query
        ).replace(
            "{{initial_search_queries_count}}",
            str(self.settings.agent.initial_search_queries_count),
        )
        response = await self._generate_llm_response(prompt, self.settings.basic_llm)
        return [q.strip() for q in response.splitlines() if q.strip()]

    async def _evaluate_and_refine_information(
        self, user_query: str, search_context: str, attempted_queries: Set[str]
    ) -> Tuple[str, List[str]]:
        new_suggested_queries: List[str] = []
        if not self.settings.information_evaluation_and_refinement_prompt:
            return "<<INSUFFICIENT>>", "Evaluation prompt missing.", []

        prompt = (
            self.settings.information_evaluation_and_refinement_prompt.replace(
                "{{user_query}}", user_query
            )
            .replace(
                "{{search_context}}",
                search_context if search_context else "No information found yet.",
            )
            .replace(
                "{{attempted_queries}}",
                (
                    "\n".join(sorted(list(attempted_queries)))
                    if attempted_queries
                    else "None yet."
                ),
            )
        )

        response_text = await self._generate_llm_response(
            prompt, self.settings.advanced_llm
        )

        response_text = response_text.strip()

        if "<<SUFFICIENT>>" in response_text:
            status_marker = "<<SUFFICIENT>>"
            # Extract content after the marker
            return status_marker, []
        elif "<<INSUFFICIENT>>" in response_text:
            status_marker = "<<INSUFFICIENT>>"
            # Extract content after the marker
            marker_match = re.search(
                r"<<INSUFFICIENT>>\s*(.*)", response_text, re.DOTALL
            )
            content_after_marker = marker_match.group(1).strip() if marker_match else ""

            if not content_after_marker:
                return status_marker, "No additional feedback provided.", []

            parts = re.split(
                r"suggested next search queries[:\s]*",
                content_after_marker,
                flags=re.IGNORECASE,
            )
            if len(parts) > 1 and parts[1].strip():
                raw_queries_part = parts[1].strip()
                if (
                    "no further productive search queries"
                    not in raw_queries_part.lower()
                ):
                    new_suggested_queries = [
                        q.strip() for q in raw_queries_part.splitlines() if q.strip()
                    ]
            return (
                status_marker,
                new_suggested_queries,
            )
        else:
            logger.warning(
                f"Evaluation LLM did not return expected marker. Response: '{response_text[:200]}'"
            )
            return (
                "<<INSUFFICIENT>>",
                [],
            )

    async def _perform_rag(self, user_query: str, final_search_context: str) -> str:
        if not self.settings.advanced_rag_prompt:
            logger.error(
                "Advanced RAG prompt is not available for final answer generation."
            )
            return "Xin lỗi, tôi đã thu thập thông tin nhưng không thể tạo câu trả lời cuối cùng do lỗi cấu hình."
        if not self.llm_connector:
            return "Xin lỗi, không thể tạo câu trả lời cuối cùng do lỗi kết nối dịch vụ AI."

        rag_prompt_filled = self.settings.advanced_rag_prompt.replace(
            "{{user_query}}", user_query
        ).replace(
            "{{search_results_context}}",
            (
                final_search_context
                if final_search_context
                else "Không có thông tin tìm kiếm nào được tìm thấy."
            ),
        )
        logger.info("Generating final RAG response using Advanced LLM.")
        try:
            final_response = await self._generate_llm_response(
                rag_prompt_filled, self.settings.advanced_llm
            )
            return (
                final_response
                if final_response
                else "Xin lỗi, tôi không thể tạo câu trả lời dựa trên thông tin hiện có."
            )
        except Exception as e_rag:
            logger.error(
                f"Error generating RAG response with advanced LLM: {e_rag}",
                exc_info=True,
            )
            return "Xin lỗi, tôi đã gặp sự cố khi tổng hợp thông tin tìm được. Vui lòng thử lại."

    async def _scrape_content_from_links(
        self, search_results: List[Dict[str, str]]
    ) -> List[Dict[str, any]]:
        """Scrapes content from search result links."""
        if not search_results:
            return []

        updated_results_with_content = []
        scrape_tasks = []
        scraped_count = 0

        for res_item in search_results:
            link = res_item.get("link")
            if link and scraped_count < MAX_LINKS_TO_SCRAPE_PER_ITERATION:
                logger.info(f"Queueing scrape for: {link}")
                scrape_tasks.append(
                    asyncio.to_thread(
                        self.content_scraper.extract_main_content_with_readability, link
                    )
                )
                scraped_count += 1

            updated_results_with_content.append(
                {
                    **res_item,
                    "scraped_title": None,
                    "scraped_content": None,
                }
            )

        if not scrape_tasks:
            return updated_results_with_content

        logger.info(f"Scraping content from {len(scrape_tasks)} links")
        scraped_data_list = await asyncio.gather(*scrape_tasks, return_exceptions=True)

        scraped_idx = 0
        for i, res_item_orig in enumerate(updated_results_with_content):
            if (
                res_item_orig.get("link")
                and scraped_idx < len(scraped_data_list)
                and updated_results_with_content[i]["scraped_content"] is None
            ):
                scraped_data_or_exc = scraped_data_list[scraped_idx]
                if isinstance(scraped_data_or_exc, Exception):
                    logger.error(
                        f"Scraping failed for {res_item_orig.get('link')}: {scraped_data_or_exc}"
                    )
                elif scraped_data_or_exc:
                    title, content = scraped_data_or_exc
                    updated_results_with_content[i]["scraped_title"] = title
                    updated_results_with_content[i]["scraped_content"] = content
                scraped_idx += 1

        return updated_results_with_content

    async def run_advanced_mode_iterations(self, original_user_query: str) -> str:
        accumulated_search_results_with_content: List[Dict[str, any]] = []
        attempted_search_queries: Set[str] = set()
        unique_processed_links: Set[str] = set()
        current_queries_to_search: List[str] = []

        for i in range(self.settings.agent.max_search_iterations):
            logger.info(
                f"Search Iteration {i+1}/{self.settings.agent.max_search_iterations}"
            )

            if i == 0:
                if not self.settings.initial_search_query_prompt:
                    logger.warning("Initial search query prompt missing")
                    break
                current_queries_to_search = await self._generate_initial_search_queries(
                    original_user_query
                )

            new_queries_this_iteration = [
                q
                for q in current_queries_to_search
                if q and q not in attempted_search_queries
            ]

            if new_queries_this_iteration:
                attempted_search_queries.update(new_queries_this_iteration)
                if self.search_connector:
                    logger.info(f"Searching with queries: {new_queries_this_iteration}")
                    new_search_results = await self.search_connector.search_google_cse(
                        new_queries_this_iteration
                    )

                    links_not_yet_processed = [
                        res
                        for res in new_search_results
                        if res.get("link")
                        and res.get("link") not in unique_processed_links
                    ]

                    if links_not_yet_processed:
                        logger.info(
                            f"Found {len(links_not_yet_processed)} new unique links to scrape"
                        )
                        scraped_results = await self._scrape_content_from_links(
                            links_not_yet_processed
                        )
                        logger.info(f"Scraped content {scraped_results}")

                        for sr_item in scraped_results:
                            link = sr_item.get("link")
                            if link:
                                accumulated_search_results_with_content.append(sr_item)
                                unique_processed_links.add(link)
                else:
                    logger.warning("SearchConnector not available, skipping search")

            current_context_parts = []
            for idx, res_item in enumerate(accumulated_search_results_with_content):
                title = res_item.get("scraped_title") or res_item.get("title", "N/A")
                content_to_use = res_item.get("scraped_content") or res_item.get(
                    "snippet", "No detailed content"
                )

                MAX_CONTENT_LENGTH_FOR_EVAL = 1500
                if len(content_to_use) > MAX_CONTENT_LENGTH_FOR_EVAL:
                    content_to_use = (
                        content_to_use[:MAX_CONTENT_LENGTH_FOR_EVAL] + "..."
                    )

                current_context_parts.append(
                    f"Context {idx+1}: {title}\n{content_to_use}\n(Source: {res_item.get('link', 'N/A')})"
                )
            current_formatted_context = "\n\n".join(current_context_parts)

            if not self.settings.information_evaluation_and_refinement_prompt:
                logger.error("Information evaluation prompt missing")
                break

            sufficiency_status, suggested_next_queries = (
                await self._evaluate_and_refine_information(
                    original_user_query,
                    current_formatted_context,
                    attempted_search_queries,
                )
            )
            logger.info(
                f"Iteration {i+1} Evaluation: {sufficiency_status}, Queries: {suggested_next_queries}"
            )

            if sufficiency_status == "<<SUFFICIENT>>":
                return await self._perform_rag(
                    original_user_query, current_formatted_context
                )

            if (
                not suggested_next_queries
                or i == self.settings.agent.max_search_iterations - 1
            ):
                logger.info(
                    "No more queries or max iterations reached. Proceeding to RAG"
                )
                break

            current_queries_to_search = suggested_next_queries

        logger.info("Iterative search finished. Performing final RAG")
        final_context_parts = []
        for idx, res_item in enumerate(accumulated_search_results_with_content):
            title = res_item.get("scraped_title") or res_item.get("title", "N/A")
            content_to_use = res_item.get("scraped_content") or res_item.get(
                "snippet", "No detailed content"
            )

            MAX_CONTENT_LENGTH_FOR_RAG = 3000
            if len(content_to_use) > MAX_CONTENT_LENGTH_FOR_RAG:
                content_to_use = content_to_use[:MAX_CONTENT_LENGTH_FOR_RAG] + "..."

            final_context_parts.append(
                f"Context {idx+1}: {title}\n{content_to_use}\n(Source: {res_item.get('link', 'N/A')})"
            )
        final_formatted_context = "\n\n".join(final_context_parts)
        return await self._perform_rag(original_user_query, final_formatted_context)

    async def handle_query(self, user_query: str) -> str:
        if not self.llm_connector:
            return "Xin lỗi, dịch vụ AI hiện không khả dụng."
        if not user_query.strip():
            return "Vui lòng cung cấp câu hỏi của bạn."

        if not self.settings.basic_router_prompt:
            logger.error("Basic router prompt is missing. Cannot route query.")
            return await self.run_advanced_mode_iterations(user_query)

        router_response_text = await asyncio.to_thread(
            self.llm_connector.generate_response,
            user_query=user_query,
            llm_config=self.settings.basic_llm,
            system_instruction=self.settings.basic_router_prompt,
        )

        if self.settings.agent.advanced_mode_marker not in router_response_text:
            return router_response_text

        logger.info(
            "Advanced mode triggered. Starting iterative search, evaluation, and refinement."
        )
        return await self.run_advanced_mode_iterations(user_query)
