import os
from pathlib import Path
from dotenv import load_dotenv
from pydantic import BaseModel
from typing import Optional, List

# --- Load environment variables ---
# Directory
BASE_DIR = Path(__file__).resolve().parent.parent

# Load environment
dotenv_path = BASE_DIR / ".env"
load_dotenv(dotenv_path=dotenv_path)


# --- Helper function to load prompts from files ---
def load_prompt_from_file(file_path_str: Optional[str]) -> Optional[str]:
    """Loads a prompt from a file if the path is provided."""
    if not file_path_str:
        return None
    # Assume file_path_str is relative to the 'app' directory
    prompt_file_path = Path(__file__).resolve().parent / file_path_str
    if prompt_file_path.exists():
        with open(prompt_file_path, "r", encoding="utf-8") as f:
            return f.read().strip()

    # print(f"Warning: Prompt file not found at {prompt_file_path}")
    return None


# --- Model Configuration ---
class LLMConfig(BaseModel):
    """Configuration for a specific LLM."""

    model_name: str
    temperature: float
    max_input_tokens: int
    max_output_tokens: int
    top_p: float
    top_k: int


class BasicLLMSettings(LLMConfig):
    """Settings for the basic LLM (router/simple tasks)."""

    model_name: str = "gemini-2.0-flash-lite"
    temperature: float = 0.5
    max_input_tokens: int = 2048
    max_output_tokens: int = 512
    top_p: float = 0.9
    top_k: int = 30


class AdvancedLLMSettings(LLMConfig):
    """Settings for the advanced LLM (RAG, complex tasks)."""

    model_name: str = "gemini-2.5-pro-preview-05-06"
    temperature: float = 0.7
    max_input_tokens: int = 8192
    max_output_tokens: int = 8192
    top_p: float = 0.95
    top_k: int = 50


class SearchConfig(BaseModel):
    """Configuration for Search API."""

    api_key: Optional[str] = os.getenv("GOOGLE_CSE_API_KEY")
    cse_id: Optional[str] = os.getenv("GOOGLE_CSE_ID")
    max_results: int = 10


class AgentConfig(BaseModel):
    """General Agent Configuration."""

    # If you want to restrict topics, define them here
    allowed_topics: Optional[List[str]] = [
        "agriculture",
        "plant",
        "weather",
        "disaster",
        "disease",
        "crop",
        "pest",
        "farming",
        "irrigation",
        "fertilizer",
        "agriculture prices",
    ]
    log_level: str = "INFO"

    # Special response markers (can be useful for initial simple parsing)
    advanced_mode_marker: str = "<<[ADVANCED MODE]>>"


class Settings(BaseModel):
    """Main application settings."""

    # --- LLMs ---

    # API keys
    gemini_api_key: Optional[str] = os.getenv("GEMINI_API_KEY")

    # LLM settings
    basic_llm: BasicLLMSettings = BasicLLMSettings()
    advanced_llm: AdvancedLLMSettings = AdvancedLLMSettings()
    search: SearchConfig = SearchConfig()
    agent: AgentConfig = AgentConfig()

    # --- Prompts ---

    # Prompt file paths (relative to the 'app' directory)
    PROMPT_BASIC_ROUTER_FILE: Optional[str] = "prompts/basic_router_prompt.md"
    PROMPT_KEYWORD_EXTRACTION_FILE: Optional[str] = (
        "prompts/keyword_extraction_prompt.md"
    )
    PROMPT_ADVANCED_RAG_FILE: Optional[str] = "prompts/advanced_rag_prompt.md"

    # Loaded prompts
    basic_router_prompt: Optional[str] = None
    keyword_extraction_prompt: Optional[str] = None
    advanced_rag_prompt: Optional[str] = None

    def __init__(self, **data):
        super().__init__(**data)
        # Load prompts from files after Pydantic initialization
        self.basic_router_prompt = load_prompt_from_file(self.PROMPT_BASIC_ROUTER_FILE)
        if self.basic_router_prompt:
            if self.agent.allowed_topics:
                self.basic_router_prompt = self.basic_router_prompt.replace(
                    "{{allowed_topics}}", ", ".join(self.agent.allowed_topics)
                )
            else:
                self.basic_router_prompt = self.basic_router_prompt.replace(
                    "{{allowed_topics}}", ""
                )
        else:
            print(
                f"Warning: Basic router prompt file not found at {self.PROMPT_BASIC_ROUTER_FILE}"
            )

        self.keyword_extraction_prompt = load_prompt_from_file(
            self.PROMPT_KEYWORD_EXTRACTION_FILE
        )
        self.advanced_rag_prompt = load_prompt_from_file(self.PROMPT_ADVANCED_RAG_FILE)

        # Validate required API keys
        if not self.gemini_api_key:
            print("Warning: GEMINI_API_KEY is not set in .env file.")
        if not self.search.api_key or not self.search.cse_id:
            print(
                "Warning: GOOGLE_CSE_API_KEY or GOOGLE_CSE_ID is not set in .env file for search functionality."
            )


settings = Settings()
