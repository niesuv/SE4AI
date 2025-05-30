import logging
import requests
from bs4 import BeautifulSoup
from readability import Document
from typing import Optional, Tuple, List

logger = logging.getLogger(__name__)

REQUEST_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 AgriminiAI/1.0"
}
REQUEST_TIMEOUT = 15

# Content selectors for common website structures
CONTENT_SELECTORS = [
    "article",
    "main",
    '[role="main"]',
    ".main-content",
    ".content",
    ".post-content",
    ".entry-content",
    ".article-content",
    ".news-content",
    ".story-body",
    ".article-body",
    "#content",
    "#main-content",
]

# Common noise elements to remove
NOISE_SELECTORS = [
    "nav",
    "header",
    "footer",
    "aside",
    ".sidebar",
    ".menu",
    ".navigation",
    ".ads",
    ".advertisement",
    ".social-share",
    ".comments",
    ".related-posts",
    ".author-bio",
    ".tags",
    ".categories",
    "iframe",
    ".popup",
    ".modal",
]


class ContentScraper:
    """Scrapes and extracts main textual content from URLs."""

    def _fetch_html(self, url: str) -> Optional[str]:
        """Fetches HTML content from a URL."""
        try:
            response = requests.get(
                url,
                headers=REQUEST_HEADERS,
                timeout=REQUEST_TIMEOUT,
                allow_redirects=True,
            )
            response.raise_for_status()

            content_type = response.headers.get("content-type", "").lower()
            if "html" not in content_type and "text" not in content_type:
                logger.warning(f"Non-HTML content type from {url}: {content_type}")
                return None

            response.encoding = response.apparent_encoding or "utf-8"
            return response.text
        except requests.exceptions.HTTPError as e:
            logger.error(f"HTTP {e.response.status_code} error fetching {url}")
        except requests.exceptions.ConnectionError:
            logger.error(f"Connection error fetching {url}")
        except requests.exceptions.Timeout:
            logger.error(f"Timeout fetching {url} after {REQUEST_TIMEOUT}s")
        except requests.exceptions.RequestException as e:
            logger.error(f"Request error fetching {url}: {e}")
        return None

    def _extract_with_selectors(self, soup: BeautifulSoup) -> str:
        """Extract content using CSS selectors for common content areas."""
        for selector in CONTENT_SELECTORS:
            elements = soup.select(selector)
            if elements:
                content_parts = []
                for element in elements[:3]:  # Limit to first 3 matches
                    # Remove noise elements within content
                    for noise in element.select(", ".join(NOISE_SELECTORS)):
                        noise.decompose()

                    text = element.get_text(separator=" ", strip=True)
                    if len(text) > 100:  # Only include substantial content
                        content_parts.append(text)

                if content_parts:
                    combined_text = "\n\n".join(content_parts)
                    logger.info(
                        f"Extracted content using selector '{selector}': {len(combined_text)} chars"
                    )
                    return combined_text
        return ""

    def _extract_by_text_density(self, soup: BeautifulSoup) -> str:
        """Extract content by analyzing text density in paragraphs."""
        paragraphs = soup.find_all(["p", "div", "section"])
        content_blocks = []

        for para in paragraphs:
            text = para.get_text(strip=True)
            if len(text) > 50:  # Minimum text length
                # Calculate text density (text vs HTML ratio)
                html_len = len(str(para))
                text_len = len(text)
                density = text_len / html_len if html_len > 0 else 0

                if density > 0.3:  # Good text-to-HTML ratio
                    content_blocks.append((text, density, text_len))

        # Sort by density and length, take top content blocks
        content_blocks.sort(key=lambda x: (x[1], x[2]), reverse=True)
        selected_content = [block[0] for block in content_blocks[:10]]

        if selected_content:
            combined_text = "\n\n".join(selected_content)
            logger.info(
                f"Extracted content by text density: {len(combined_text)} chars"
            )
            return combined_text
        return ""

    def _extract_fallback(self, soup: BeautifulSoup) -> str:
        """Fallback extraction method - get all meaningful text."""
        # Remove unwanted elements
        for element in soup(NOISE_SELECTORS + ["script", "style", "head"]):
            element.decompose()

        # Get all text content
        all_text = soup.get_text(separator=" ", strip=True)

        # Clean up: remove excessive whitespace and short lines
        lines = [line.strip() for line in all_text.splitlines()]
        meaningful_lines = [line for line in lines if len(line) > 20]

        if meaningful_lines:
            cleaned_text = "\n".join(meaningful_lines)
            logger.info(
                f"Extracted content using fallback method: {len(cleaned_text)} chars"
            )
            return cleaned_text
        return ""

    def _clean_and_format_text(self, text: str) -> str:
        """Clean and format extracted text."""
        if not text:
            return ""

        # Remove excessive whitespace
        lines = [line.strip() for line in text.splitlines() if line.strip()]

        # Remove very short lines that are likely navigation/UI elements
        filtered_lines = []
        for line in lines:
            if len(line) > 15 or any(
                word in line.lower()
                for word in [
                    "agriculture",
                    "farming",
                    "crop",
                    "plant",
                    "soil",
                    "fertilizer",
                ]
            ):
                filtered_lines.append(line)

        return "\n".join(filtered_lines)

    def extract_main_content_with_readability(
        self, url: str
    ) -> Optional[Tuple[str, str]]:
        """
        Extracts main content and title using multiple strategies.

        Args:
            url: The URL to scrape.

        Returns:
            Tuple of (title, main_content_text) or None if extraction fails.
        """
        html_content = self._fetch_html(url)
        if not html_content:
            return None

        try:
            # Strategy 1: Try readability-lxml first
            doc = Document(html_content)
            title = doc.title()
            main_content_html = doc.summary(html_partial=True)

            soup_readability = BeautifulSoup(main_content_html, "html.parser")
            for script_or_style in soup_readability(["script", "style"]):
                script_or_style.decompose()

            readability_text = soup_readability.get_text(separator=" ", strip=True)
            readability_text = self._clean_and_format_text(readability_text)

            if len(readability_text) > 200:
                logger.info(
                    f"Readability extraction successful for {url}: {len(readability_text)} chars"
                )
                return title, readability_text

            logger.warning(
                f"Readability extraction insufficient for {url}, trying alternatives"
            )

            # Strategy 2: CSS selector-based extraction
            soup_full = BeautifulSoup(html_content, "html.parser")
            selector_text = self._extract_with_selectors(soup_full)
            selector_text = self._clean_and_format_text(selector_text)

            if len(selector_text) > 200:
                return title, selector_text

            # Strategy 3: Text density analysis
            soup_full = BeautifulSoup(html_content, "html.parser")
            density_text = self._extract_by_text_density(soup_full)
            density_text = self._clean_and_format_text(density_text)

            if len(density_text) > 200:
                return title, density_text

            # Strategy 4: Fallback method
            soup_full = BeautifulSoup(html_content, "html.parser")
            fallback_text = self._extract_fallback(soup_full)
            fallback_text = self._clean_and_format_text(fallback_text)

            if len(fallback_text) > 100:
                logger.warning(
                    f"Using fallback extraction for {url}: {len(fallback_text)} chars"
                )
                return title, fallback_text

            logger.warning(f"All extraction strategies failed for {url}")
            return None

        except Exception as e:
            logger.error(f"Content extraction failed for {url}: {e}", exc_info=True)
        return None
