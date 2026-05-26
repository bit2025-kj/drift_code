from pydantic_settings import BaseSettings


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
    UPLOAD_DIR: str = "./uploads"
    MAX_FILE_SIZE_MB: int = 50

    class Config:
        env_file = ".env"


settings = Settings()
