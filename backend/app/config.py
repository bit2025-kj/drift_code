from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import field_validator


class Settings(BaseSettings):
    APP_NAME: str = "Nafa Edu API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True

    DATABASE_URL: str = "postgresql+asyncpg://kjuser:kjuser67@127.0.0.1:5432/nafa_edu_base"
    REDIS_URL: str = "redis://localhost:6379"

    SECRET_KEY: str = "nafa-edu-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    MISTRAL_API_KEY: str = ""
    CLOUDINARY_URL: str = ""
    UPLOAD_DIR: str = "./uploads"
    MAX_FILE_SIZE_MB: int = 50

    ADMIN_EMAIL: str = "admin@nafaedu.bf"
    ADMIN_PASSWORD: str = "Admin@NafaEdu2025!"

    @field_validator("DATABASE_URL", mode="before")
    @classmethod
    def normalize_db_url(cls, v: str) -> str:
        # Render / Heroku provide postgres:// or postgresql:// — asyncpg needs postgresql+asyncpg://
        if v.startswith("postgres://"):
            return v.replace("postgres://", "postgresql+asyncpg://", 1)
        if v.startswith("postgresql://") and "+asyncpg" not in v:
            return v.replace("postgresql://", "postgresql+asyncpg://", 1)
        return v

    model_config = SettingsConfigDict(env_file=".env")


settings = Settings()
