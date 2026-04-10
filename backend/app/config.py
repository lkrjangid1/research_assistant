from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    vertex_project_id: str = ""
    vertex_location: str = "us-central1"
    google_application_credentials: str = ""
    gemini_model: str = "gemini-1.5-pro"
    embedding_model: str = "text-embedding-004"
    faiss_index_path: str = "./data/faiss_index"
    debug: bool = False
    cors_origins: str = "*"
    max_pdf_size_mb: int = 50
    rate_limit: str = "100/minute"


@lru_cache
def get_settings() -> Settings:
    return Settings()
