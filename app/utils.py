import asyncio
import hashlib
import logging
from typing import List, Dict, Tuple, Optional
import re
from collections import defaultdict
import time

logger = logging.getLogger(__name__)


class ContentCache:
    """Simple in-memory cache for search results and scraped content."""

    def __init__(self, max_size: int = 1000, ttl_seconds: int = 3600):
        self.cache: Dict[str, Dict] = {}
        self.access_times: Dict[str, float] = {}
        self.max_size = max_size
        self.ttl_seconds = ttl_seconds

    def _generate_key(self, query: str) -> str:
        """Generate cache key from query."""
        return hashlib.md5(query.lower().encode()).hexdigest()

    def _is_expired(self, key: str) -> bool:
        """Check if cache entry is expired."""
        if key not in self.access_times:
            return True
        return time.time() - self.access_times[key] > self.ttl_seconds

    def get(self, query: str) -> Optional[Dict]:
        """Get cached result for query."""
        key = self._generate_key(query)
        if key in self.cache and not self._is_expired(key):
            self.access_times[key] = time.time()  # Update access time
            return self.cache[key]
        return None

    def set(self, query: str, result: Dict):
        """Set cache result for query."""
        key = self._generate_key(query)

        # Clean expired entries
        self._cleanup_expired()

        # Remove oldest entries if cache is full
        if len(self.cache) >= self.max_size:
            oldest_key = min(
                self.access_times.keys(), key=lambda k: self.access_times[k]
            )
            del self.cache[oldest_key]
            del self.access_times[oldest_key]

        self.cache[key] = result
        self.access_times[key] = time.time()

    def _cleanup_expired(self):
        """Remove expired entries."""
        expired_keys = [k for k in self.cache.keys() if self._is_expired(k)]
        for key in expired_keys:
            del self.cache[key]
            del self.access_times[key]


class ContentProcessor:
    """Utility class for processing and optimizing content for LLM consumption."""

    @staticmethod
    def extract_relevant_chunks(
        content: str, query: str, max_chunks: int = 3, chunk_size: int = 500
    ) -> List[str]:
        """Extract most relevant chunks of content based on query keywords."""
        if not content or not query:
            return []

        # Extract query keywords (simple approach)
        query_words = set(re.findall(r"\b\w+\b", query.lower()))

        # Split content into sentences/paragraphs
        sentences = re.split(r"[.!?]\s+", content)

        # Score each sentence based on keyword overlap
        scored_sentences = []
        for sentence in sentences:
            if len(sentence.strip()) < 50:  # Skip very short sentences
                continue

            sentence_words = set(re.findall(r"\b\w+\b", sentence.lower()))
            score = len(query_words.intersection(sentence_words))

            if score > 0:
                scored_sentences.append((sentence.strip(), score))

        # Sort by score and take top sentences
        scored_sentences.sort(key=lambda x: x[1], reverse=True)
        top_sentences = [s[0] for s in scored_sentences[: max_chunks * 3]]

        # Group sentences into chunks
        chunks = []
        current_chunk = ""

        for sentence in top_sentences:
            if len(current_chunk) + len(sentence) <= chunk_size:
                current_chunk += sentence + " "
            else:
                if current_chunk:
                    chunks.append(current_chunk.strip())
                current_chunk = sentence + " "

                if len(chunks) >= max_chunks:
                    break

        if current_chunk and len(chunks) < max_chunks:
            chunks.append(current_chunk.strip())

        return chunks[:max_chunks]

    @staticmethod
    def summarize_content(content: str, max_length: int = 1000) -> str:
        """Summarize content to fit within max_length while preserving important info."""
        if len(content) <= max_length:
            return content

        # Split into paragraphs
        paragraphs = [p.strip() for p in content.split("\n\n") if p.strip()]

        # If only one long paragraph, split by sentences
        if len(paragraphs) == 1:
            paragraphs = [
                s.strip() for s in re.split(r"[.!?]\s+", content) if s.strip()
            ]

        # Take first few paragraphs/sentences that fit within limit
        summary = ""
        for para in paragraphs:
            if len(summary) + len(para) + 2 <= max_length:
                summary += para + "\n\n"
            else:
                # Add partial paragraph if space allows
                remaining_space = max_length - len(summary) - 10
                if remaining_space > 100:
                    summary += para[:remaining_space] + "..."
                break

        return summary.strip()

    @staticmethod
    def filter_agricultural_content(content: str) -> str:
        """Filter content to focus on agricultural information."""
        agricultural_keywords = [
            "agriculture",
            "farming",
            "crop",
            "plant",
            "soil",
            "fertilizer",
            "irrigation",
            "pest",
            "disease",
            "harvest",
            "seed",
            "cultivation",
            "livestock",
            "cattle",
            "farm",
            "field",
            "weather",
            "climate",
            "nông nghiệp",
            "cây trồng",
            "giống",
            "đất",
            "phân bón",
            "tưới",
            "sâu bệnh",
            "thu hoạch",
            "gieo trồng",
            "chăn nuôi",
            "thời tiết",
        ]

        # Split content into sentences
        sentences = re.split(r"[.!?]\s+", content)

        # Filter sentences containing agricultural keywords
        relevant_sentences = []
        for sentence in sentences:
            sentence_lower = sentence.lower()
            if any(keyword in sentence_lower for keyword in agricultural_keywords):
                relevant_sentences.append(sentence.strip())

        # If we have relevant sentences, use them; otherwise return original (truncated)
        if relevant_sentences:
            return ". ".join(relevant_sentences[:10])  # Limit to 10 sentences
        else:
            return ContentProcessor.summarize_content(content, 800)


class PerformanceTracker:
    """Track performance metrics for optimization analysis."""

    def __init__(self):
        self.metrics = defaultdict(list)

    def track_time(self, operation: str, duration: float):
        """Track operation duration."""
        self.metrics[f"{operation}_time"].append(duration)

    def track_tokens(self, operation: str, token_count: int):
        """Track token usage."""
        self.metrics[f"{operation}_tokens"].append(token_count)

    def get_average(self, metric: str) -> float:
        """Get average value for a metric."""
        values = self.metrics.get(metric, [])
        return sum(values) / len(values) if values else 0.0

    def log_summary(self):
        """Log performance summary."""
        for metric, values in self.metrics.items():
            if values:
                avg = sum(values) / len(values)
                logger.info(
                    f"Performance - {metric}: avg={avg:.2f}, count={len(values)}"
                )


# Global instances
content_cache = ContentCache()
content_processor = ContentProcessor()
performance_tracker = PerformanceTracker()
