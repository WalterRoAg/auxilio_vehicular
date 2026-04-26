from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

# User schemas
class UserBase(BaseModel):
    email: EmailStr
    full_name: str = Field(..., min_length=2, max_length=100)
    phone: str = Field(..., min_length=7, max_length=15)
    role: str = Field(default="user", pattern="^(user|taller|admin)$")

class UserCreate(UserBase):
    password: str = Field(..., min_length=8)

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(UserBase):
    id: str
    created_at: datetime
    is_active: bool

    class Config:
        from_attributes = True

# Workshop schemas
class TallerBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    address: str = Field(..., min_length=10, max_length=200)
    phone: str = Field(..., min_length=7, max_length=15)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    specialties: str = Field(default="", max_length=500)

class TallerCreate(TallerBase):
    pass

class TallerResponse(TallerBase):
    id: str
    owner_id: str
    rating: float
    is_active: bool

    class Config:
        from_attributes = True

# Incident schemas
class IncidenteCreate(BaseModel):
    description: str = Field(..., min_length=10, max_length=1000)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    vehicle_type: str = Field(..., max_length=50)
    vehicle_model: str = Field(..., max_length=50)

class IncidenteResponse(BaseModel):
    id: str
    user_id: str
    description: str
    latitude: float
    longitude: float
    status: str
    category: str
    priority: str
    created_at: datetime

    class Config:
        from_attributes = True