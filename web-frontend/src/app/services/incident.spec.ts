import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable({ providedIn: 'root' })
export class IncidentService {
  API_URL = 'http://localhost:8000/api';

  constructor(private http: HttpClient) {}

  getIncidentesPendientes(tallerId?: string) {
    const url = tallerId
      ? `${this.API_URL}/incidentes/pendientes/${tallerId}`
      : `${this.API_URL}/incidentes/pendientes`;
    return this.http.get(url);
  }

  enviarOferta(incidenteId: string, precio: number, tiempo: number) {
    return this.http.post(`${this.API_URL}/ofertas`, {
      incidente_id: incidenteId,
      precio_estimado: precio,
      tiempo_llegada: tiempo
    });
  }
}