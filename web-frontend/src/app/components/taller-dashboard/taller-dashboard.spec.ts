import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient, HttpClientModule } from '@angular/common/http';

@Component({
  selector: 'app-taller-dashboard',
  standalone: true,
  imports: [CommonModule, HttpClientModule],
  templateUrl: './taller-dashboard.component.html',
  styleUrls: ['./taller-dashboard.component.scss']
})
export class TallerDashboard implements OnInit {
  incidentes: any[] = [];

  constructor(private http: HttpClient) {}

  ngOnInit() {
    this.cargarIncidentes();
  }

  // Método para cargar incidentes desde el backend
  cargarIncidentes() {
    this.http.get('http://localhost:8000/incidentes')
      .subscribe({
        next: (data: any) => {
          this.incidentes = data;
          console.log('Incidentes cargados:', this.incidentes);
        },
        error: (error) => {
          console.error('Error al cargar incidentes:', error);
        }
      });
  }

  // 🔧 FUNCIÓN DE APOYO PARA LOS COLORES
  getPrioridadClass(prioridad: string): string {
    const clases: any = {
      'Crítica': 'critica',
      'Alta': 'alta',
      'Media': 'media',
      'Baja': 'baja'
    };
    return clases[prioridad] || 'media';
  }

  getBadgeClass(prioridad: string): string {
    return `badge-${this.getPrioridadClass(prioridad)}`;
  }

  // Método para enviar oferta
  ofertar(incidenteId: number, precio: string, tiempo: string) {
    const oferta = {
      incidente_id: incidenteId,
      precio: parseFloat(precio),
      tiempo_minutos: parseInt(tiempo),
      taller_id: 1  // Temporal, después con autenticación
    };

    this.http.post('http://localhost:8000/ofertas', oferta)
      .subscribe({
        next: (response) => {
          alert('✅ Oferta enviada correctamente');
          this.cargarIncidentes(); // Recargar la lista
        },
        error: (error) => {
          console.error('Error al enviar oferta:', error);
          alert('❌ Error al enviar la oferta');
        }
      });
  }

  // Método para refrescar manualmente
  refrescar() {
    this.cargarIncidentes();
  }
}