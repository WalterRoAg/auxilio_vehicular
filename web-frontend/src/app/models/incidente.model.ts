export interface Incidente {
  id: string;
  cliente_id: string;
  lat: number;
  lng: number;
  descripcion_ia: string;
  audio_path?: string;
  status: string;
  taller_asignado_id?: string;
  fecha_creacion?: string;
  
  imagen_url?: string | null;
  clasificacion?: string;
  prioridad?: string;
}