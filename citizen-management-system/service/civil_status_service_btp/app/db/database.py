from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.config import get_settings

settings = get_settings()

# Chuỗi kết nối SQL Server
SQLALCHEMY_DATABASE_URL = (
    f"mssql+pyodbc://{settings.DB_USER_BTP}:{settings.DB_PASSWORD_BTP}@"
    f"{settings.DB_SERVER_BTP},{settings.DB_PORT_BTP}/{settings.DB_NAME_BTP}?"
    f"driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes" 
)
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Dependency để lấy database session
def get_btp_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()