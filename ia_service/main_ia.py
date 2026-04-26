from fastapi import FastAPI, UploadFile, File, Form
import whisper
import os
import shutil
import requests
import uuid
import concurrent.futures

app = FastAPI(title="IA Service")

model = whisper.load_model("tiny")

BACKEND_URL = "http://localhost:8000/api/incidentes/crear-ia"


def clasificar(texto):
    t = texto.lower()

    if "llanta" in t or "pinchada" in t or "neumático" in t:
        return "Llanta", "Baja"

    if "bateria" in t or "batería" in t or "arranca" in t or "eléctrico" in t:
        return "Eléctrico", "Media"

    if "grua" in t or "grúa" in t or "choque" in t or "accidente" in t:
        return "Grúa", "Alta"

    return "Mecánica general", "Baja"


def transcribir_audio(audio_path):
    resultado = model.transcribe(
        audio_path,
        language="es",
        fp16=False
    )
    return resultado.get("text", "").strip()


@app.post("/ia/procesar-auxilio")
async def procesar(
    cliente_id: str = Form(...),
    lat: float = Form(...),
    lng: float = Form(...),
    descripcion: str = Form("Emergencia"),
    file: UploadFile | None = File(None)
):
    audio_path = None

    try:
        texto = descripcion.strip() if descripcion else "Emergencia"

        if file is not None and file.filename:
            os.makedirs("temp_audio", exist_ok=True)

            audio_path = f"temp_audio/{uuid.uuid4()}.m4a"

            with open(audio_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)

            try:
                with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
                    future = executor.submit(transcribir_audio, audio_path)
                    texto_transcrito = future.result(timeout=25)

                if texto_transcrito:
                    texto = texto_transcrito

            except Exception as e:
                print("ERROR O TIMEOUT TRANSCRIPCION:", e)

            finally:
                if audio_path and os.path.exists(audio_path):
                    os.remove(audio_path)

        categoria, prioridad = clasificar(texto)

        payload = {
            "cliente_id": cliente_id,
            "lat": lat,
            "lng": lng,
            "descripcion": texto,
            "clasificacion": categoria,
            "prioridad": prioridad
        }

        r = requests.post(BACKEND_URL, json=payload, timeout=15)

        if r.status_code != 200:
            return {
                "error": "Backend no aceptó el incidente",
                "status_code": r.status_code,
                "detalle": r.text
            }

        return r.json()

    except Exception as e:
        if audio_path and os.path.exists(audio_path):
            os.remove(audio_path)

        return {"error": str(e)}
