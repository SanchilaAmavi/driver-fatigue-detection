from sqlalchemy import Column, Integer, String, Float, DateTime
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()


class TripRecord(Base):
    __tablename__ = "trip_records"

    id = Column(Integer, primary_key=True, index=True)
    trip_id = Column(String, unique=True, index=True, nullable=False)
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime, nullable=False)
    fatigue_score = Column(Float, nullable=False)
    alerts = Column(String, nullable=True)
