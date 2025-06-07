from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.config import get_settings

settings = get_settings()

# Chuỗi kết nối SQL Server
SQLALCHEMY_DATABASE_URL = f"mssql+pyodbc://{settings.DB_USER_BTP}:{settings.DB_PASSWORD_BTP}@{settings.DB_SERVER_BTP}:{settings.DB_PORT_BTP}/{settings.DB_NAME_BTP}?driver=ODBC+Driver+17+for+SQL+Server"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Dependency để lấy database session
def get_btp_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()