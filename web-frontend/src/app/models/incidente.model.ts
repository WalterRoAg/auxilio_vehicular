export interface Incidente {
  id: string;
  cliente_id?: string;
  descripcion_ia?: string;
  audio_path?: string;
  lat: number;
  lng: number;
  status: string;
  taller_asignado_id?: string;
  fecha_creacion?: string;
  prioridad?: string;
  clasificacion?: string;
  imagen_url?: string | null;

  // 👇 NUEVOS
  tiempo_estimado_minutos?: number;
  distancia_km?: number;

  // existente
  tiempo_llegada_minutos?: number;
  
}