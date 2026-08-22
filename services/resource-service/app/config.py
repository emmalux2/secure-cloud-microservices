import os

class Settings:
    JWT_ACCESS_SECRET: str = os.environ.get("JWT_ACCESS_SECRET", "dev-only-change-me")

settings = Settings()
