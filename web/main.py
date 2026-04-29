from fastapi import FastAPI, Depends, HTTPException, UploadFile, File, Form
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from sqlalchemy import func, text
from fastapi.middleware.cors import CORSMiddleware
import models, auth
import uuid
import os
import math
from fastapi import Form
from dotenv import load_dotenv

from database import get_db, engine
import schemas

from datetime import datetime, timedelta

MAX_INTENTOS = 3
BLOQUEO_MINUTOS = 3

intentos_login = {}  # { email: { "intentos": int, "bloqueado_hasta": datetime } }

def calcular_distancia_km(lat1, lon1, lat2, lon2):
    R = 6371  # radio de la tierra en km

    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)

    a = (
        math.sin(dlat/2)**2 +
        math.cos(math.radians(lat1)) *
        math.cos(math.radians(lat2)) *
        math.sin(dlon/2)**2
    )

    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    return R * c


def verificar_bloqueo(email: str):
    data = intentos_login.get(email)

    if data:
        bloqueado_hasta = data.get("bloqueado_hasta")

        if bloqueado_hasta and datetime.utcnow() < bloqueado_hasta:
            minutos_restantes = int((bloqueado_hasta - datetime.utcnow()).total_seconds() / 60)
            raise HTTPException(
                status_code=403,
                detail=f"Cuenta bloqueada. Intenta en {minutos_restantes} min"
            )
        
def registrar_fallo(email: str):
    data = intentos_login.get(email, {"intentos": 0, "bloqueado_hasta": None})

    data["intentos"] += 1

    if data["intentos"] >= MAX_INTENTOS:
        data["bloqueado_hasta"] = datetime.utcnow() + timedelta(minutes=BLOQUEO_MINUTOS)
        data["intentos"] = 0  # reinicia

    intentos_login[email] = data

def resetear_intentos(email: str):
    if email in intentos_login:
        del intentos_login[email]

    
# Load environment variables
load_dotenv()

# --- INICIALIZACIÓN ---
# Crear tablas en la DB
models.Base.metadata.create_all(bind=engine)

with engine.begin() as conn:
    conn.execute(text("""
        CREATE TABLE IF NOT EXISTS servicios (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            nombre VARCHAR(100) UNIQUE NOT NULL
        )
    """))

    conn.execute(text("""
        CREATE TABLE IF NOT EXISTS taller_servicios (
            taller_id UUID NOT NULL,
            servicio_id UUID NOT NULL,
            PRIMARY KEY (taller_id, servicio_id)
        )
    """))

    conn.execute(text("""
        CREATE TABLE IF NOT EXISTS taller_encargados (
            taller_id UUID NOT NULL,
            user_id UUID NOT NULL,
            PRIMARY KEY (taller_id, user_id),
            FOREIGN KEY (taller_id) REFERENCES talleres(id),
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
    """))

    conn.execute(text("""
        ALTER TABLE incidentes 
        ADD COLUMN IF NOT EXISTS clasificacion VARCHAR(100)
    """))

    conn.execute(text("""
        ALTER TABLE incidentes 
        ADD COLUMN IF NOT EXISTS prioridad VARCHAR(50)
    """))

app = FastAPI(title="Auxilio Vehicular API")

# Configuración de CORS
cors_origins = os.getenv("CORS_ORIGINS", "http://localhost:3000,http://localhost:4200").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://auxilio-vehicular-frontend.onrender.com"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Asegurar directorios de carga
Directorios = ["uploads/audios", "archivos/imagenes"]
for directorio in Directorios:
    os.makedirs(directorio, exist_ok=True)

app.mount("/archivos", StaticFiles(directory="archivos"), name="archivos")

# --- USUARIOS (CU1, CU2, CU4, CU16) ---

# En main.py, asegúrate de que registrar_usuario acepte el dict
@app.post("/api/registrar")
def registrar_usuario(user_data: dict, db: Session = Depends(get_db)):
    try:
        email = user_data.get("email", "").strip().lower()
        password = str(user_data.get("password", ""))

        full_name = (
            user_data.get("full_name")
            or user_data.get("nombre")
            or user_data.get("name")
            or ""
        )

        phone = (
            user_data.get("phone")
            or user_data.get("telefono")
            or "00000000"
        )

        if not email or not password or not full_name:
            raise HTTPException(
                status_code=400,
                detail="Faltan datos obligatorios: email, password o nombre"
            )

        existe = db.query(models.User).filter(models.User.email == email).first()

        if existe:
            raise HTTPException(status_code=400, detail="El correo ya existe")

        nuevo_usuario = models.User(
            id=uuid.uuid4(),
            email=email,
            password=auth.get_password_hash(password),
            role="cliente",
            full_name=full_name,
            phone=phone
        )

        db.add(nuevo_usuario)
        db.commit()
        db.refresh(nuevo_usuario)

        return {
            "status": "ok",
            "message": "Usuario registrado",
            "user_id": str(nuevo_usuario.id)
        }

    except HTTPException:
        raise

    except Exception as e:
        db.rollback()
        print("ERROR REGISTRO:", e)
        raise HTTPException(
            status_code=500,
            detail="Error interno al registrar usuario"
        )
    
@app.post("/api/login")
def login(data: dict, db: Session = Depends(get_db)):
    try:
        email = (
            data.get("email")
            or data.get("correo")
            or data.get("username")
            or ""
        ).strip().lower()

        password = str(
            data.get("password")
            or data.get("clave")
            or data.get("contrasena")
            or ""
        )

        if not email or not password:
            raise HTTPException(
                status_code=400,
                detail="Faltan email o password"
            )

        verificar_bloqueo(email)

        user = db.query(models.User).filter(
            models.User.email == email
        ).first()

        if not user or not auth.verify_password(password, user.password):
            registrar_fallo(email)
            raise HTTPException(status_code=400, detail="Credenciales incorrectas")

        if user.role != "cliente":
            raise HTTPException(status_code=403, detail="Solo app móvil")

        resetear_intentos(email)

        token = auth.create_access_token({
            "sub": str(user.id),
            "role": user.role
        })

        return {
            "token": token,
            "user_id": str(user.id),
            "name": user.full_name,
            "role": user.role
        }

    except HTTPException:
        raise

    except Exception as e:
        print("ERROR LOGIN:", e)
        raise HTTPException(status_code=500, detail="Error interno en login")

@app.post("/api/login-movil")
def login_movil(data: dict, db: Session = Depends(get_db)):
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")

    verificar_bloqueo(email)

    user = db.query(models.User).filter(
        models.User.email == email
    ).first()

    if not user or not auth.verify_password(
        password,
        user.password
    ):
        registrar_fallo(email)
        raise HTTPException(status_code=400, detail="Credenciales incorrectas")

    if user.role != "cliente":
        raise HTTPException(
            status_code=403,
            detail="Solo clientes en app móvil"
        )

    resetear_intentos(email)

    token = auth.create_access_token({
        "sub": str(user.id),
        "role": user.role
    })

    return {
        "token": token,
        "user_id": str(user.id),
        "role": user.role,
        "name": user.full_name
    }

@app.post("/api/login-web")
def login_web(data: dict, db: Session = Depends(get_db)):
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")

    verificar_bloqueo(email)

    user = db.query(models.User).filter(models.User.email == email).first()

    if not user or not auth.verify_password(password, user.password):
        registrar_fallo(email)
        raise HTTPException(status_code=400, detail="Credenciales incorrectas")

    if user.role not in ["taller", "admin"]:
        raise HTTPException(status_code=403, detail="Acceso solo panel web")

    resetear_intentos(email)

    token = auth.create_access_token({
        "sub": str(user.id),
        "role": user.role
    })

    taller = db.query(models.Taller).filter(
        models.Taller.usuario_id == user.id
    ).first()

    taller_id = None

    if taller:
        taller_id = str(taller.id)
    else:
        result = db.execute(
            text("SELECT taller_id FROM taller_encargados WHERE user_id = :user_id LIMIT 1"),
            {"user_id": str(user.id)}
        ).fetchone()

        if result:
            taller_id = str(result[0])

    if not taller_id and user.role == "taller":
        raise HTTPException(
            status_code=404,
            detail="Este usuario no está asociado a ningún taller"
        )

    return {
        "token": token,
        "user_id": str(user.id),
        "taller_id": taller_id,
        "role": user.role,
        "name": user.full_name
    }

@app.put("/api/usuarios/token-notificacion")
def actualizar_token(usuario_id: str, token: str, db: Session = Depends(get_db)):
    usuario = db.query(models.User).filter(models.User.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    usuario.token_notificacion = token
    db.commit()
    return {"mensaje": "Token de notificación actualizado"}

# --- VEHÍCULOS (CU5, CU6) ---

@app.post("/api/vehiculos")
def registrar_vehiculo(data: dict, db: Session = Depends(get_db)):
    nuevo_v = models.Vehicle(
        id=uuid.uuid4(),
        user_id=data['user_id'],
        plate=data['plate'],
        brand=data['brand'],
        model=data['model']
    )
    db.add(nuevo_v)
    db.commit()
    return {"status": "ok", "id": str(nuevo_v.id)}

@app.get("/api/vehiculos/usuario/{usuario_id}")
def listar_vehiculos(usuario_id: str, db: Session = Depends(get_db)):
    return db.query(models.Vehicle).filter(models.Vehicle.user_id == usuario_id).all()

# --- EMERGENCIAS (CU7 - CU13) ---

@app.post("/api/emergencia")
async def crear_emergencia(
    cliente_id: str = Form(...),
    lat: float = Form(...),
    lng: float = Form(...),
    descripcion: str = Form("Emergencia"),
    audio: UploadFile = File(None),   # 👈 NUEVO
    db: Session = Depends(get_db)
):
    try:
        import uuid
        from uuid import UUID
        import os

        # validar UUID cliente
        try:
            cliente_uuid = UUID(cliente_id)
        except:
            raise HTTPException(
                status_code=400,
                detail="cliente_id inválido"
            )

        # ---------------------------
        # GUARDAR AUDIO SI EXISTE
        # ---------------------------
        ruta_audio = None

        if audio:
            os.makedirs("uploads/audios", exist_ok=True)

            nombre_archivo = f"{uuid.uuid4()}_{audio.filename}"
            ruta_audio = f"uploads/audios/{nombre_archivo}"

            with open(ruta_audio, "wb") as buffer:
                buffer.write(await audio.read())

        # ---------------------------
        # GUARDAR INCIDENTE
        # ---------------------------
        clasificacion, prioridad = clasificar_emergencia(descripcion)

        nuevo_incidente = models.Incidente(
            id=uuid.uuid4(),
            cliente_id=cliente_uuid,
            lat=lat,
            lng=lng,
            descripcion_ia=descripcion,
            clasificacion=clasificacion,
            prioridad=prioridad,
            audio_path=ruta_audio,   # 👈 NUEVO
            status="pendiente"
        )

        db.add(nuevo_incidente)
        db.commit()
        db.refresh(nuevo_incidente)

        return {
            "status": "ok",
            "incidente_id": str(nuevo_incidente.id),
            "message": "Emergencia registrada"
        }

    except Exception as e:
        db.rollback()
        print("ERROR:", e)

        raise HTTPException(
            status_code=500,
            detail="Error al registrar emergencia"
        )

@app.post("/api/emergencia/subir-imagen")
async def subir_imagen(
    incidente_id: str = Form(...), 
    es_complementaria: bool = Form(False),
    archivo: UploadFile = File(...), 
    db: Session = Depends(get_db)
):
    nombre_archivo = f"{incidente_id}_{archivo.filename}"
    ruta_final = os.path.join("archivos/imagenes", nombre_archivo)
    
    with open(ruta_final, "wb") as buffer:
        buffer.write(await archivo.read())
        
    nueva_imagen = models.ImagenIncidente(
        id=uuid.uuid4(),
        incidente_id=incidente_id,
        ruta_imagen=ruta_final,
        es_complementaria=es_complementaria
    )
    db.add(nueva_imagen)
    db.commit()
    return {"mensaje": "Imagen guardada", "ruta": ruta_final}

# --- FLUJO TALLERES (CU15, CU21, CU23, CU24, CU26) ---

@app.get("/api/incidentes/pendientes")
def obtener_incidentes_pendientes(db: Session = Depends(get_db)):
    return db.query(models.Incidente).filter(
        models.Incidente.status == "pendiente"
    ).all()

@app.get("/api/incidentes/pendientes/{taller_id}")
def incidentes_filtrados(taller_id: str, db: Session = Depends(get_db)):
    servicios = db.execute(
        text(
            "SELECT s.nombre FROM servicios s "
            "JOIN taller_servicios ts ON ts.servicio_id = s.id "
            "WHERE ts.taller_id = :taller_id"
        ),
        {"taller_id": taller_id}
    ).fetchall()

    if not servicios:
        return []

    taller = db.query(models.Taller).filter(
        models.Taller.id == taller_id
    ).first()

    def servicio_a_clasificacion(nombre: str) -> str:
        nombre_l = nombre.lower()
        if "llanta" in nombre_l:
            return "Llanta"
        if "grúa" in nombre_l or "grua" in nombre_l:
            return "Grúa"
        if "batería" in nombre_l or "bateria" in nombre_l:
            return "Batería"
        if "eléctrico" in nombre_l or "electrico" in nombre_l:
            return "Eléctrico"
        if "aceite" in nombre_l:
            return "Cambio de aceite"
        if "mecánica" in nombre_l or "mecanica" in nombre_l:
            return "Mecánica general"
        return nombre

    clasificaciones = {servicio_a_clasificacion(row[0]) for row in servicios}

    incidentes = db.query(models.Incidente).filter(
        models.Incidente.status == "pendiente",
        models.Incidente.clasificacion.in_(list(clasificaciones))
    ).all()

    resultado = []

    for inc in incidentes:
        imagen = db.query(models.ImagenIncidente).filter(
            models.ImagenIncidente.incidente_id == inc.id
        ).first()

        imagen_url = None
        if imagen:
            base_url = os.getenv("BASE_URL", "https://auxilio-vehicular.onrender.com")
            imagen_url = f"{base_url}/{imagen.ruta_imagen.replace('\\', '/')}"

        distancia_km = None
        tiempo_estimado_minutos = None

        if taller and taller.latitud and taller.longitud and inc.lat and inc.lng:
            distancia_km = calcular_distancia_km(
                taller.latitud,
                taller.longitud,
                inc.lat,
                inc.lng
            )

            velocidad_promedio = 40  # km/h
            tiempo_estimado_minutos = max(
                1,
                int((distancia_km / velocidad_promedio) * 60)
            )

        resultado.append({
            "id": str(inc.id),
            "cliente_id": str(inc.cliente_id),
            "descripcion_ia": inc.descripcion_ia,
            "clasificacion": inc.clasificacion,
            "prioridad": inc.prioridad,
            "status": inc.status,
            "lat": inc.lat,
            "lng": inc.lng,
            "fecha_creacion": inc.fecha_creacion,
            "imagen_url": imagen_url,
            "distancia_km": round(distancia_km, 2) if distancia_km is not None else None,
            "tiempo_estimado_minutos": tiempo_estimado_minutos
        })

    return resultado

@app.post("/api/taller/enviar-oferta")
def enviar_oferta(datos: dict, db: Session = Depends(get_db)):
    incidente = db.query(models.Incidente).filter(
        models.Incidente.id == datos["incidente_id"]
    ).first()

    if not incidente:
        raise HTTPException(status_code=404, detail="Incidente no encontrado")

    taller = db.query(models.Taller).filter(
        models.Taller.id == datos["taller_id"]
    ).first()

    if not taller:
        raise HTTPException(status_code=404, detail="Taller no encontrado")

    distancia = calcular_distancia_km(
        taller.latitud,
        taller.longitud,
        incidente.lat,
        incidente.lng
    )

    velocidad_promedio = 40  # km/h ciudad
    tiempo_min = int((distancia / velocidad_promedio) * 60)

    nueva_oferta = models.OfertaTaller(
        id=uuid.uuid4(),
        incidente_id=datos["incidente_id"],
        taller_id=datos["taller_id"],
        precio_estimado=datos["precio"],
        tiempo_llegada_minutos=tiempo_min,
        mensaje_taller=datos.get("mensaje", "Oferta enviada por el taller"),
        estado_oferta="pendiente"
    )

    incidente.status = "ofertado"

    nueva_notificacion = models.Notificacion(
        id=uuid.uuid4(),
        usuario_id=incidente.cliente_id,
        titulo="Nueva oferta recibida",
        mensaje=f"{taller.nombre_taller} envió una oferta de Bs. {datos['precio']}",
        leido=False
    )

    db.add(nueva_oferta)
    db.add(nueva_notificacion)
    db.commit()
    db.refresh(nueva_oferta)

    return {
        "status": "oferta_enviada",
        "oferta_id": str(nueva_oferta.id),
        "mensaje": "Oferta registrada y notificación creada"
    }

@app.post("/api/emergencia/confirmar-taller")
def confirmar_taller(datos: dict, db: Session = Depends(get_db)):
    incidente = db.query(models.Incidente).filter(models.Incidente.id == datos['incidente_id']).first()
    if not incidente:
        raise HTTPException(status_code=404, detail="Incidente no encontrado")
        
    incidente.taller_asignado_id = datos['taller_id']
    incidente.status = "en_camino"
    db.commit()
    return {"status": "Taller confirmado, técnico en camino"}

@app.get("/api/emergencia/trazabilidad/{incidente_id}")
def obtener_trazabilidad(incidente_id: str, db: Session = Depends(get_db)):
    incidente = db.query(models.Incidente).filter(models.Incidente.id == incidente_id).first()
    if not incidente or not incidente.taller_asignado_id:
        return {"error": "No hay técnico asignado aún"}
        
    taller = db.query(models.Taller).filter(models.Taller.id == incidente.taller_asignado_id).first()
    return {
        "lat": taller.latitud  if taller else 0,
        "lng": taller.longitud  if taller else 0,
        "status": incidente.status
    }

# --- NOTIFICACIONES (CU16) ---

@app.get("/api/notificaciones/{usuario_id}")
def obtener_notificaciones(usuario_id: str, db: Session = Depends(get_db)):
    try:
        # Validamos si es un UUID válido antes de consultar
        from uuid import UUID
        val_id = UUID(usuario_id)
        
        return db.query(models.Notificacion).filter(
            models.Notificacion.usuario_id == val_id,
            models.Notificacion.leido == False
        ).all()
    except Exception as e:
        # Si el ID es basura (como "usuario-prueba-123"), devolvemos lista vacía
        return []

@app.put("/api/notificaciones/leer/{notificacion_id}")
def marcar_leida(notificacion_id: str, db: Session = Depends(get_db)):
    notif = db.query(models.Notificacion).filter(models.Notificacion.id == notificacion_id).first()
    if notif:
        notif.leido = True
        db.commit()
    return {"status": "ok"}

# --- REPORTES Y ADMIN (CU25, CU28) ---

@app.get("/api/historial/{usuario_id}")
def obtener_historial(usuario_id: str, db: Session = Depends(get_db)):
    return db.query(models.HistorialServicio).filter(
        (models.HistorialServicio.cliente_id == usuario_id) | 
        (models.HistorialServicio.taller_id == usuario_id)
    ).all()

@app.get("/api/admin/reportes")
def reportes_generales(db: Session = Depends(get_db)):
    total = db.query(models.HistorialServicio).count()
    # Uso correcto de func.sum
    ingresos = db.query(func.sum(models.HistorialServicio.monto_final)).scalar()
    return {
        "servicios_realizados": total,
        "recaudacion": ingresos or 0
    }

@app.get("/api/incidentes/pendientes")
def obtener_incidentes_pendientes(db: Session = Depends(get_db)):
    return db.query(models.Incidente).filter(models.Incidente.status == "pendiente").all()

@app.get("/api/perfil/{user_id}")
def obtener_perfil(user_id: str, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()

    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    return {
        "id": str(user.id),
        "name": user.full_name,
        "email": user.email,
        "phone": user.phone
    }

@app.put("/api/perfil/{user_id}")
def actualizar_perfil(user_id: str, data: dict, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()

    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    user.full_name = data["name"]
    user.phone = data["phone"]

    db.commit()

    return {"status": "ok"}


@app.get("/api/ofertas/incidente/{incidente_id}")
def obtener_ofertas_incidente(incidente_id: str, db: Session = Depends(get_db)):
    ofertas = db.query(models.OfertaTaller).filter(
        models.OfertaTaller.incidente_id == incidente_id
    ).all()

    resultado = []

    for oferta in ofertas:
        taller = db.query(models.Taller).filter(
            models.Taller.id == oferta.taller_id
        ).first()

        resultado.append({
            "id": str(oferta.id),
            "incidente_id": str(oferta.incidente_id),
            "taller_id": str(oferta.taller_id),
            "nombre_taller": taller.nombre_taller if taller else "Taller",
            "precio_estimado": oferta.precio_estimado,
            "tiempo_llegada_minutos": oferta.tiempo_llegada_minutos,
            "mensaje_taller": oferta.mensaje_taller,
            "estado_oferta": oferta.estado_oferta,
            "fecha_oferta": oferta.fecha_oferta
        })

    return resultado

@app.post("/api/registrar-taller")
def registrar_taller(data: dict, db: Session = Depends(get_db)):
    try:
        email = data["email"].strip().lower()

        existe = db.query(models.User).filter(models.User.email == email).first()
        if existe:
            raise HTTPException(status_code=400, detail="El correo ya existe")

        nuevo_user = models.User(
            id=uuid.uuid4(),
            email=email,
            password=auth.get_password_hash(data["password"]),
            role="taller",
            full_name=data["nombre"],
            phone=data.get("telefono", "")
        )

        db.add(nuevo_user)
        db.commit()
        db.refresh(nuevo_user)

        nuevo_taller = models.Taller(
            id=uuid.uuid4(),
            usuario_id=nuevo_user.id,
            nombre_taller=data["nombre_taller"],
            especialidad=data.get("especialidad", ""),
            direccion=data.get("direccion", ""),
            latitud=data.get("latitud", -17.7833),
            longitud=data.get("longitud", -63.1821),
            rating=0,
            disponible=True,
            saldo=0
        )

        db.add(nuevo_taller)
        db.commit()
        db.refresh(nuevo_taller)

        return {
            "status": "ok",
            "user_id": str(nuevo_user.id),
            "taller_id": str(nuevo_taller.id)
        }

    except HTTPException:
        raise

    except Exception as e:
        db.rollback()
        print("ERROR REGISTRAR TALLER:", e)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/servicios")
def obtener_servicios(db: Session = Depends(get_db)):
    servicios_base = [
        "Llanta",
        "Batería",
        "Grúa",
        "Mecánica general",
        "Cambio de aceite",
        "Auxilio eléctrico"
    ]
    for nombre in servicios_base:
        existe = db.execute(
            text("SELECT id FROM servicios WHERE nombre = :nombre"),
            {"nombre": nombre}
        ).fetchone()

        if not existe:
            db.execute(
                text("INSERT INTO servicios (nombre) VALUES (:nombre)"),
                {"nombre": nombre}
            )

    db.commit()

    filas = db.execute(
        text("SELECT id, nombre FROM servicios ORDER BY nombre")
    ).fetchall()

    return [
        {
            "id": str(f[0]),
            "nombre": f[1]
        }
        for f in filas
    ]
""" 
@app.post("/api/taller/servicios")
def guardar_servicios(data: dict, db: Session = Depends(get_db)):
    db.execute(
        "DELETE FROM taller_servicios WHERE taller_id = :tid",
        {"tid": data["taller_id"]}
    )

    for sid in data["servicios"]:
        db.execute(
            "INSERT INTO taller_servicios (taller_id, servicio_id) VALUES (:t, :s)",
            {"t": data["taller_id"], "s": sid}
        )

    db.commit()
    return {"status": "ok"}"""

@app.post("/api/taller/servicios")
def guardar_servicios(data: dict, db: Session = Depends(get_db)):
    taller_id = data["taller_id"]
    servicios = data.get("servicios", [])

    db.execute(
        text("DELETE FROM taller_servicios WHERE taller_id = :tid"),
        {"tid": taller_id}
    )

    for sid in servicios:
        db.execute(
            text("""
                INSERT INTO taller_servicios (taller_id, servicio_id)
                VALUES (:taller_id, :servicio_id)
            """),
            {
                "taller_id": taller_id,
                "servicio_id": sid
            }
        )

    db.commit()

    return {
        "status": "ok",
        "mensaje": "Servicios actualizados correctamente"
    }

@app.get("/api/taller/saldo/{taller_id}")
def saldo_taller(taller_id: str, db: Session = Depends(get_db)):
    taller = db.query(models.Taller).filter(
        models.Taller.id == taller_id
    ).first()

    if not taller:
        raise HTTPException(status_code=404, detail="Taller no encontrado")

    ofertas = db.query(models.OfertaTaller).filter(
        models.OfertaTaller.taller_id == taller_id,
        models.OfertaTaller.estado_oferta == "aceptada"
    ).all()

    total_servicios = sum(float(o.precio_estimado or 0) for o in ofertas)
    comision = total_servicios * 0.10

    return {
        "saldo": float(taller.saldo or 0),
        "total_servicios": total_servicios,
        "comision": comision
    }

@app.get("/api/taller/perfil/{user_id}")
def obtener_perfil_taller(user_id: str, db: Session = Depends(get_db)):
    taller = db.query(models.Taller).filter(
        models.Taller.usuario_id == user_id
    ).first()

    es_dueno = True

    if not taller:
        result = db.execute(
            text("SELECT taller_id FROM taller_encargados WHERE user_id = :user_id LIMIT 1"),
            {"user_id": user_id}
        ).fetchone()

        if not result:
            raise HTTPException(status_code=404, detail="Taller no encontrado")

        taller = db.query(models.Taller).filter(
            models.Taller.id == result[0]
        ).first()

        es_dueno = False

    return {
        "id": str(taller.id),
        "usuario_id": str(taller.usuario_id),
        "nombre_taller": taller.nombre_taller,
        "especialidad": taller.especialidad,
        "direccion": taller.direccion,
        "latitud": taller.latitud,
        "longitud": taller.longitud,
        "rating": float(taller.rating or 0),
        "disponible": taller.disponible,
        "es_dueno": es_dueno
    }


@app.put("/api/taller/perfil/{taller_id}")
def actualizar_perfil_taller(taller_id: str, data: dict, db: Session = Depends(get_db)):
    taller = db.query(models.Taller).filter(
        models.Taller.id == taller_id
    ).first()

    if not taller:
        raise HTTPException(status_code=404, detail="Taller no encontrado")

    taller.nombre_taller = data.get("nombre_taller", taller.nombre_taller)
    taller.especialidad = data.get("especialidad", taller.especialidad)
    taller.direccion = data.get("direccion", taller.direccion)
    taller.latitud = data.get("latitud", taller.latitud)
    taller.longitud = data.get("longitud", taller.longitud)
    taller.disponible = data.get("disponible", taller.disponible)

    db.commit()
    db.refresh(taller)

    return {
        "status": "ok",
        "mensaje": "Perfil actualizado correctamente"
    }





    
@app.put("/api/incidentes/cancelar/{incidente_id}")
def cancelar_incidente(incidente_id: str, db: Session = Depends(get_db)):
    incidente = db.query(models.Incidente).filter(
        models.Incidente.id == incidente_id
    ).first()

    if not incidente:
        raise HTTPException(status_code=404, detail="Incidente no encontrado")

    if incidente.status in ["en_camino", "finalizado"]:
        raise HTTPException(
            status_code=400,
            detail="No se puede cancelar un servicio que ya fue atendido"
        )

    incidente.status = "cancelado"
    db.commit()

    return {
        "status": "ok",
        "mensaje": "Solicitud cancelada correctamente"
    }


@app.post("/api/taller/aceptar-solicitud")
def aceptar_solicitud(datos: dict, db: Session = Depends(get_db)):
    incidente = db.query(models.Incidente).filter(
        models.Incidente.id == datos["incidente_id"]
    ).first()

    if not incidente:
        raise HTTPException(status_code=404, detail="Incidente no encontrado")

    if incidente.status not in ["pendiente", "ofertado"]:
        raise HTTPException(
            status_code=400,
            detail="La solicitud ya fue atendida o cancelada"
        )

    taller = db.query(models.Taller).filter(
        models.Taller.id == datos["taller_id"]
    ).first()

    if not taller:
        raise HTTPException(status_code=404, detail="Taller no encontrado")

    precio = float(datos["precio"])
    comision = precio * 0.10

    distancia = calcular_distancia_km(
        taller.latitud,
        taller.longitud,
        incidente.lat,
        incidente.lng
    )

    velocidad_promedio = 40
    tiempo_min = max(1, int((distancia / velocidad_promedio) * 60))

    saldo_actual = float(taller.saldo or 0)

    if saldo_actual < comision:
        raise HTTPException(
            status_code=400,
            detail=f"Saldo insuficiente. Comisión requerida: Bs. {comision:.2f}"
        )

    taller.saldo = saldo_actual - comision

    nueva_oferta = models.OfertaTaller(
        id=uuid.uuid4(),
        incidente_id=incidente.id,
        taller_id=taller.id,
        precio_estimado=precio,
        tiempo_llegada_minutos=tiempo_min,
        mensaje_taller=datos.get("mensaje", "Solicitud aceptada por el taller"),
        estado_oferta="aceptada"
    )

    incidente.taller_asignado_id = taller.id
    incidente.status = "en_camino"

    notificacion = models.Notificacion(
        id=uuid.uuid4(),
        usuario_id=incidente.cliente_id,
        titulo="Solicitud aceptada",
        mensaje=f"{taller.nombre_taller} aceptó tu solicitud de auxilio.",
        leido=False
    )

    db.add(nueva_oferta)
    db.add(notificacion)
    db.commit()
    db.refresh(nueva_oferta)

    return {
        "status": "ok",
        "mensaje": "Solicitud aceptada correctamente",
        "incidente_id": str(incidente.id),
        "oferta_id": str(nueva_oferta.id)
    }


@app.get("/api/incidentes/detalle/{incidente_id}")
def detalle_incidente(incidente_id: str, db: Session = Depends(get_db)):
    incidente = db.query(models.Incidente).filter(
        models.Incidente.id == incidente_id
    ).first()

    if not incidente:
        raise HTTPException(status_code=404, detail="Incidente no encontrado")

    taller = None
    oferta = None

    if incidente.taller_asignado_id:
        taller = db.query(models.Taller).filter(
            models.Taller.id == incidente.taller_asignado_id
        ).first()

        oferta = db.query(models.OfertaTaller).filter(
            models.OfertaTaller.incidente_id == incidente.id,
            models.OfertaTaller.taller_id == incidente.taller_asignado_id
        ).order_by(models.OfertaTaller.fecha_oferta.desc()).first()

    return {
        "id": str(incidente.id),
        "cliente_id": str(incidente.cliente_id),
        "lat": incidente.lat,
        "lng": incidente.lng,
        "descripcion": incidente.descripcion_ia,
        "status": incidente.status,
        "taller": {
            "id": str(taller.id),
            "nombre_taller": taller.nombre_taller,
            "especialidad": taller.especialidad,
            "direccion": taller.direccion,
            "latitud": taller.latitud,
            "longitud": taller.longitud,
            "rating": float(taller.rating or 0)
        } if taller else None,
        "oferta": {
            "id": str(oferta.id),
            "precio_estimado": float(oferta.precio_estimado),
            "tiempo_llegada_minutos": oferta.tiempo_llegada_minutos,
            "estado_oferta": oferta.estado_oferta
        } if oferta else None
    }


@app.get("/api/incidentes/activa/cliente/{cliente_id}")
def solicitud_activa_cliente(cliente_id: str, db: Session = Depends(get_db)):
    incidente = db.query(models.Incidente).filter(
        models.Incidente.cliente_id == cliente_id,
        models.Incidente.status.in_(["pendiente", "ofertado", "en_camino"])
    ).order_by(models.Incidente.fecha_creacion.desc()).first()

    if not incidente:
        return {"activa": False}

    return {
        "activa": True,
        "incidente_id": str(incidente.id),
        "status": incidente.status
    }

def clasificar_emergencia(texto: str):
    t = texto.lower()

    if "llanta" in t or "pinchada" in t:
        return "Llanta", "Baja"

    if "bateria" in t or "arranca" in t:
        return "Eléctrico", "Media"

    if "grua" in t or "choque" in t or "accidente" in t:
        return "Grúa", "Alta"

    if "electrico" in t or "eléctrico" in t or "electricidad" in t or "luces" in t:
        return "Auxilio eléctrico", "Media"

    return "Mecánica general", "Baja"

@app.post("/api/incidentes/crear-ia")
def crear_incidente_ia(data: dict, db: Session = Depends(get_db)):
    descripcion = data.get("descripcion", "Emergencia")
    clasificacion, prioridad = clasificar_emergencia(descripcion)

    nuevo = models.Incidente(
        id=uuid.uuid4(),
        cliente_id=data["cliente_id"],
        lat=data["lat"],
        lng=data["lng"],
        descripcion_ia=descripcion,
        clasificacion=clasificacion,
        prioridad=prioridad,
        status="pendiente"
    )

    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)

    return {
        "status": "ok",
        "incidente_id": str(nuevo.id),
        "descripcion": descripcion,
        "clasificacion": clasificacion,
        "prioridad": prioridad
    }

@app.get("/api/emergencia/trazabilidad/{incidente_id}")
def obtener_trazabilidad(incidente_id: str, db: Session = Depends(get_db)):
    incidente = db.query(models.Incidente).filter(
        models.Incidente.id == incidente_id
    ).first()

    if not incidente:
        raise HTTPException(status_code=404, detail="Incidente no encontrado")

    if not incidente.taller_asignado_id:
        return {
            "error": "No hay técnico asignado aún",
            "status": incidente.status
        }

    taller = db.query(models.Taller).filter(
        models.Taller.id == incidente.taller_asignado_id
    ).first()

    return {
        "lat": taller.latitud if taller else 0,
        "lng": taller.longitud if taller else 0,
        "status": incidente.status
    }

@app.put("/api/incidentes/finalizar/{incidente_id}")
def finalizar_incidente(incidente_id: str, db: Session = Depends(get_db)):
    incidente = db.query(models.Incidente).filter(
        models.Incidente.id == incidente_id
    ).first()

    if not incidente:
        raise HTTPException(status_code=404, detail="Incidente no encontrado")

    incidente.status = "finalizado"
    db.commit()

    return {"status": "ok", "mensaje": "Servicio finalizado"}


@app.put("/api/incidentes/cancelar-no-llego/{incidente_id}")
def cancelar_no_llego(incidente_id: str, db: Session = Depends(get_db)):
    incidente = db.query(models.Incidente).filter(
        models.Incidente.id == incidente_id
    ).first()

    if not incidente:
        raise HTTPException(status_code=404, detail="Incidente no encontrado")

    if incidente.status != "en_camino":
        raise HTTPException(status_code=400, detail="Solo se puede cancelar si está en camino")

    incidente.status = "cancelado_no_llego"
    db.commit()

    return {"status": "ok", "mensaje": "Solicitud cancelada porque el auxilio no llegó"}

@app.post("/api/taller/recargar-saldo")
def recargar_saldo(data: dict, db: Session = Depends(get_db)):
    taller = db.query(models.Taller).filter(
        models.Taller.id == data["taller_id"]
    ).first()

    if not taller:
        raise HTTPException(status_code=404, detail="Taller no encontrado")

    monto = float(data["monto"])

    if monto <= 0:
        raise HTTPException(status_code=400, detail="Monto inválido")

    taller.saldo = float(taller.saldo or 0) + monto
    db.commit()

    return {
        "status": "ok",
        "saldo": taller.saldo
    }

@app.post("/api/taller/encargados")
def registrar_encargado(data: dict, db: Session = Depends(get_db)):
    taller = db.query(models.Taller).filter(
        models.Taller.id == data["taller_id"]
    ).first()

    if not taller:
        raise HTTPException(status_code=404, detail="Taller no encontrado")

    existe = db.query(models.User).filter(
        models.User.email == data["email"].strip().lower()
    ).first()

    if existe:
        raise HTTPException(status_code=400, detail="El correo ya existe")

    nuevo_user = models.User(
        id=uuid.uuid4(),
        email=data["email"].strip().lower(),
        password=auth.get_password_hash(data["password"]),
        role="taller",
        full_name=data["nombre"],
        phone=data.get("telefono", "")
    )

    db.add(nuevo_user)
    db.commit()
    db.refresh(nuevo_user)

    db.execute(
     text("INSERT INTO taller_encargados (taller_id, user_id) VALUES (:taller_id, :user_id)"),
    {
        "taller_id": str(taller.id),
        "user_id": str(nuevo_user.id)
    }
)

    db.commit()

    return {
    "status": "ok",
    "mensaje": "Encargado registrado correctamente",
    "user_id": str(nuevo_user.id),
    "taller_id": str(taller.id)
    }

@app.get("/api/taller/solicitudes-atendiendo/{taller_id}")
def solicitudes_atendiendo(taller_id: str, db: Session = Depends(get_db)):
    incidentes = db.query(models.Incidente).filter(
        models.Incidente.taller_asignado_id == taller_id,
        models.Incidente.status == "en_camino"
    ).all()

    resultado = []

    for inc in incidentes:
        oferta = db.query(models.OfertaTaller).filter(
            models.OfertaTaller.incidente_id == inc.id,
            models.OfertaTaller.taller_id == taller_id
        ).order_by(models.OfertaTaller.fecha_oferta.desc()).first()

        imagen = db.query(models.ImagenIncidente).filter(
            models.ImagenIncidente.incidente_id == inc.id
        ).first()

        imagen_url = None
        if imagen:
            base_url = os.getenv("BASE_URL", "https://auxilio-vehicular.onrender.com")
            imagen_url = f"{base_url}/{imagen.ruta_imagen.replace('\\', '/')}"

        resultado.append({
            "id": str(inc.id),
            "descripcion": inc.descripcion_ia,
            "lat": inc.lat,
            "lng": inc.lng,
            "status": inc.status,
            "precio": float(oferta.precio_estimado) if oferta else 0,
            "tiempo": oferta.tiempo_llegada_minutos if oferta else 0,
            "fecha": inc.fecha_creacion,
            "imagen_url": imagen_url
        })

    return resultado

@app.get("/api/taller/encargados/{taller_id}")
def listar_encargados(taller_id: str, db: Session = Depends(get_db)):
    filas = db.execute(
        text("""
            SELECT u.id, u.full_name, u.email, u.phone
            FROM taller_encargados te
            JOIN users u ON u.id = te.user_id
            WHERE te.taller_id = :taller_id
        """),
        {"taller_id": taller_id}
    ).fetchall()

    return [
        {
            "id": str(f[0]),
            "nombre": f[1],
            "email": f[2],
            "telefono": f[3]
        }
        for f in filas
    ]

@app.get("/api/taller/servicios/{taller_id}")
def obtener_servicios_taller(taller_id: str, db: Session = Depends(get_db)):
    filas = db.execute(
        text("""
            SELECT servicio_id
            FROM taller_servicios
            WHERE taller_id = :taller_id
        """),
        {"taller_id": taller_id}
    ).fetchall()

    return [str(f[0]) for f in filas]