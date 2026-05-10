from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

_BACKEND_ENV_FILE = Path(__file__).resolve().parents[1] / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=_BACKEND_ENV_FILE,
        env_file_encoding="utf-8",
        extra="ignore",
        populate_by_name=True,
    )

    vertex_project_id: str = Field(default="", alias="VERTEX_PROJECT_ID")
    vertex_location: str = Field(default="us-central1", alias="VERTEX_LOCATION")
    google_application_credentials: str = Field(default="", alias="GOOGLE_APPLICATION_CREDENTIALS")
    gemini_model: str = Field(default="gemini-2.5-flash-lite", alias="GEMINI_MODEL")
    embedding_model: str = Field(default="gemini-embedding-001", alias="EMBEDDING_MODEL")
    embedding_dim: int = Field(default=256, alias="EMBEDDING_DIM")
    embedding_concurrent_limit: int = Field(default=1, alias="EMBEDDING_CONCURRENT_LIMIT")
    embedding_requests_per_minute: int = Field(default=4, alias="EMBEDDING_REQUESTS_PER_MINUTE")
    embedding_max_retries: int = Field(default=5, alias="EMBEDDING_MAX_RETRIES")
    embedding_cache_path: str = Field(default="./data/embedding_cache.pkl", alias="EMBEDDING_CACHE_PATH")
    faiss_index_path: str = Field(default="./data/faiss_index", alias="FAISS_INDEX_PATH")
    debug: bool = Field(default=False, alias="DEBUG")
    cors_origins: str = Field(default="*", alias="CORS_ORIGINS")
    max_pdf_size_mb: int = Field(default=50, alias="MAX_PDF_SIZE_MB")
    rate_limit: str = Field(default="100/minute", alias="RATE_LIMIT")

    @property
    def faiss_index_dir(self) -> Path:
        return Path(self.faiss_index_path).expanduser()

    @property
    def cors_origins_list(self) -> list[str]:
        origins = [origin.strip() for origin in self.cors_origins.split(",")]
        return [origin for origin in origins if origin]


@lru_cache
def get_settings() -> Settings:
    return Settings()
