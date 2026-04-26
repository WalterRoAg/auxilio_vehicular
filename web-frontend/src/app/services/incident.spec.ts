import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable({ providedIn: 'root' })
export class IncidentService {
  API_URL = 'http://localhost:8000/api';

  constructor(private http: HttpClient) {}

  getIncidentesPendientes() {
    return this.http.get(`${this.API_URL}/incidentes/pendientes`);
  }

  enviarOferta(incidenteId: string, precio: number, tiempo: number) {
    return this.http.post(`${this.API_URL}/ofertas`, {
      incidente_id: incidenteId,
      precio_estimado: precio,
      tiempo_llegada: tiempo
    });
  }
}