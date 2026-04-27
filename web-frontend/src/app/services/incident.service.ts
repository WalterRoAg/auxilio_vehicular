import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Incidente } from '../models/incidente.model';
import { Oferta } from '../models/oferta.model';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class IncidentService {
  private API_URL = environment.apiUrl;

  constructor(private http: HttpClient) {}

  getIncidentesPendientes(tallerId?: string): Observable<Incidente[]> {
    const url = tallerId
      ? `${this.API_URL}/incidentes/pendientes/${tallerId}`
      : `${this.API_URL}/incidentes/pendientes`;
    return this.http.get<Incidente[]>(url);
  }

  enviarOferta(oferta: Oferta): Observable<any> {
    return this.http.post(`${this.API_URL}/taller/enviar-oferta`, oferta);
  }
  aceptarSolicitud(data: any) {
  return this.http.post(`${this.API_URL}/taller/aceptar-solicitud`, data);
  }
}