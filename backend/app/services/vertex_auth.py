import asyncio
from pathlib import Path

import google.auth
from google.auth.credentials import Credentials
from google.auth.exceptions import GoogleAuthError
from google.auth.transport.requests import Request
from google.oauth2 import service_account

_VERTEX_AI_SCOPE = "https://www.googleapis.com/auth/cloud-platform"


class VertexAuthError(RuntimeError):
    """Raised when Vertex AI Application Default Credentials are unavailable."""


class VertexAuth:
    """Application Default Credentials helper for Vertex AI REST calls."""

    def __init__(
        self,
        project_id: str = "",
        credentials: Credentials | None = None,
        credentials_path: str = "",
    ):
        self.project_id = project_id.strip()
        self._credentials = credentials
        self._credentials_path = credentials_path.strip()
        self._lock = asyncio.Lock()

    async def project(self) -> str:
        if self.project_id:
            return self.project_id

        await self._ensure_credentials()
        if not self.project_id:
            raise VertexAuthError(
                "Vertex AI project ID is not configured. Set VERTEX_PROJECT_ID "
                "or configure Application Default Credentials with a default project."
            )
        return self.project_id

    async def headers(self) -> dict[str, str]:
        credentials = await self._valid_credentials()
        return {"Authorization": f"Bearer {credentials.token}"}

    async def _ensure_credentials(self) -> Credentials:
        if self._credentials is not None:
            return self._credentials

        async with self._lock:
            if self._credentials is not None:
                return self._credentials

            try:
                if self._credentials_path:
                    credentials = await asyncio.to_thread(
                        service_account.Credentials.from_service_account_file,
                        str(Path(self._credentials_path).expanduser()),
                        scopes=[_VERTEX_AI_SCOPE],
                    )
                    discovered_project = getattr(credentials, "project_id", None)
                else:
                    credentials, discovered_project = await asyncio.to_thread(
                        google.auth.default,
                        scopes=[_VERTEX_AI_SCOPE],
                    )
            except GoogleAuthError as exc:
                raise VertexAuthError(
                    "Vertex AI credentials are not configured. Set "
                    "GOOGLE_APPLICATION_CREDENTIALS or run "
                    "`gcloud auth application-default login`."
                ) from exc
            except (OSError, ValueError) as exc:
                raise VertexAuthError(
                    "Vertex AI service account file could not be loaded. Check "
                    "GOOGLE_APPLICATION_CREDENTIALS points to the JSON key file."
                ) from exc

            self._credentials = credentials
            if not self.project_id and discovered_project:
                self.project_id = discovered_project
            return credentials

    async def _valid_credentials(self) -> Credentials:
        credentials = await self._ensure_credentials()
        async with self._lock:
            if not credentials.valid:
                try:
                    await asyncio.to_thread(credentials.refresh, Request())
                except GoogleAuthError as exc:
                    raise VertexAuthError("Failed to refresh Vertex AI credentials.") from exc

            if not credentials.token:
                raise VertexAuthError("Vertex AI credentials did not return an access token.")
            return credentials
