import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, Integer, Float, Boolean, Text
from sqlalchemy.dialects.postgresql import UUID
from database import Base
import datetime

# --- USUARIOS (CU1, CU2, CU4, CU16) ---
class User(Base):
    __tablename__ = "users"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, index=True)
    password = Column(String)
    role = Column(String)  # 'cliente', 'taller', 'admin'
    full_name = Column(String)
    phone = Column(String)
    token_notificacion = Column(String, nullable=True)

# --- VEHÍCULOS (CU5, CU6) ---
class Vehicle(Base):
    __tablename__ = "vehicles"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    plate = Column(String)
    model = Column(String)
    brand = Column(String)

# --- TALLERES (CU18, CU20) ---
class Taller(Base):
    __tablename__ = "talleres"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    usuario_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    nombre_taller = Column(String)
    especialidad = Column(String)
    direccion = Column(Text)
    latitud = Column(Float)
    longitud = Column(Float)
    rating = Column(Float, default=5.0)
    disponible = Column(Boolean, default=True)
    saldo = Column(Float, default=0)

# --- EMERGENCIAS (CU7 - CU13) ---
class Incidente(Base):
    __tablename__ = "incidentes"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    cliente_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    lat = Column(Float)
    lng = Column(Float)
    descripcion_ia = Column(Text)
    audio_path = Column(String, nullable=True)
    status = Column(String, default="pendiente")
    taller_asignado_id = Column(UUID(as_uuid=True), ForeignKey("talleres.id"), nullable=True)
    fecha_creacion = Column(DateTime, default=datetime.datetime.utcnow)

class ImagenIncidente(Base):
    __tablename__ = "imagenes_incidente"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    incidente_id = Column(UUID(as_uuid=True), ForeignKey("incidentes.id"))
    ruta_imagen = Column(String)
    es_complementaria = Column(Boolean, default=False)

# --- OFERTAS Y PAGOS (CU17, CU23) ---
class OfertaTaller(Base):
    __tablename__ = "ofertas_taller"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    incidente_id = Column(UUID(as_uuid=True), ForeignKey("incidentes.id"))
    taller_id = Column(UUID(as_uuid=True), ForeignKey("talleres.id"))
    precio_estimado = Column(Float, nullable=False)
    tiempo_llegada_minutos = Column(Integer, nullable=False)
    mensaje_taller = Column(Text, nullable=True)
    estado_oferta = Column(String, default="pendiente")
    fecha_oferta = Column(DateTime, default=datetime.datetime.utcnow)

class HistorialServicio(Base):
    __tablename__ = "historial_servicios"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    cliente_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    taller_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    monto_final = Column(Float)
    fecha_finalizacion = Column(DateTime, default=datetime.datetime.utcnow)

# --- NOTIFICACIONES (CU16) - SOLO UNA VEZ ---
class Notificacion(Base):
    __tablename__ = "notificaciones"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    usuario_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    titulo = Column(String)
    mensaje = Column(String)
    leido = Column(Boolean, default=False)
    fecha_creacion = Column(DateTime, default=datetime.datetime.utcnow)