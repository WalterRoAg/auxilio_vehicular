import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { IncidentService } from '../../services/incident.service';
import { Subscription, interval } from 'rxjs';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';

import { Incidente } from '../../models/incidente.model';
import { Oferta } from '../../models/oferta.model';

@Component({
  selector: 'app-taller-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './taller-dashboard.component.html',
  styleUrls: ['./taller-dashboard.component.scss']
})
export class TallerDashboardComponent implements OnInit, OnDestroy {

  incidentes: Incidente[] = [];
  loading = true;
  ofertasEnviadas: string[] = [];

  tallerId = localStorage.getItem('taller_id') || '';

  private pollingSub?: Subscription;
  private relojIntervalo?: any;

  constructor(
    private incidentService: IncidentService,
    private sanitizer: DomSanitizer
  ) {}

  ngOnInit(): void {
    this.cargarIncidentes();

    this.pollingSub = interval(5000).subscribe(() => {
      this.cargarIncidentes(false);
    });

    this.relojIntervalo = setInterval(() => {
      this.incidentes = [...this.incidentes];
    }, 1000);
  }

  ngOnDestroy(): void {
    this.pollingSub?.unsubscribe();

    if (this.relojIntervalo) {
      clearInterval(this.relojIntervalo);
    }
  }

  getMapaUrl(lat: number, lng: number): SafeResourceUrl {
    const url = `https://maps.google.com/maps?q=${lat},${lng}&z=15&output=embed`;
    return this.sanitizer.bypassSecurityTrustResourceUrl(url);
  }

  cargarIncidentes(mostrarLoading: boolean = true): void {
    if (mostrarLoading) {
      this.loading = true;
    }

    this.incidentService.getIncidentesPendientes(this.tallerId).subscribe({
      next: (data) => {
        console.log('INCIDENTES RECIBIDOS:', data);
        this.incidentes = [...(data || [])];
        this.loading = false;
      },
      error: (err) => {
        console.error('ERROR CARGANDO INCIDENTES:', err);
        this.incidentes = [];
        this.loading = false;
      }
    });
  }

  enviarOferta(id: string, precio: string, tiempo: string): void {
    if (!precio || !tiempo) {
      alert('Completa precio y tiempo');
      return;
    }

    if (!this.tallerId) {
      alert('No se encontró el taller asociado a esta cuenta');
      return;
    }

    const payload: Oferta = {
      incidente_id: id,
      taller_id: this.tallerId,
      precio: parseFloat(precio),
      tiempo: parseInt(tiempo, 10)
    };

    this.incidentService.enviarOferta(payload).subscribe({
      next: () => {
        this.ofertasEnviadas.push(id);
        alert('Oferta enviada correctamente');
        this.cargarIncidentes(false);
      },
      error: () => alert('Error de conexión')
    });
  }

  aceptarSolicitud(item: any, precio: string, tiempo: any): void {
    if (!this.tallerId) {
      alert('No se encontró el taller asociado a esta cuenta');
      return;
    }

    if (!precio || !tiempo) {
      alert('Completa precio y tiempo');
      return;
    }

    const payload = {
      incidente_id: item.id,
      taller_id: this.tallerId,
      precio: parseFloat(precio),
      tiempo: parseInt(tiempo, 10)
    };

    this.incidentService.aceptarSolicitud(payload).subscribe({
      next: () => {
        alert('Solicitud aceptada correctamente');
        this.cargarIncidentes(false);
      },
      error: (err) => {
        console.error(err);
        alert('Error al aceptar solicitud');
      }
    });
  }

  getBadgeClass(prioridad: string): string {
    const p = prioridad?.toLowerCase();

    if (p === 'alta' || p === 'critica' || p === 'crítica') return 'danger';
    if (p === 'media') return 'warning';
    return 'normal';
  }

  tiempoTranscurrido(fecha: string): string {
    const ahora = new Date().getTime();
    const creado = new Date(fecha).getTime();

    const diff = Math.floor((ahora - creado) / 1000);

    if (diff < 10) return 'Justo ahora';
    if (diff < 60) return `Hace ${diff} seg`;

    const min = Math.floor(diff / 60);
    if (min < 60) return `Hace ${min} min`;

    const horas = Math.floor(min / 60);
    return `Hace ${horas} h`;
  }
}