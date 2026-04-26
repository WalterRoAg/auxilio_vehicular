import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-solicitudes-atendiendo',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './solicitudes-atendiendo.component.html',
  styleUrls: ['./solicitudes-atendiendo.component.scss']
})
export class SolicitudesAtendiendoComponent implements OnInit, OnDestroy {
  solicitudes: any[] = [];
  loading = true;

  private API_URL = 'http://localhost:8000/api';
  intervalId: any;

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.cargarSolicitudes();

    // 🔄 refresca cada 5 segundos
    this.intervalId = setInterval(() => {
      this.cargarSolicitudes();
    }, 5000);
  }

  cargarSolicitudes(): void {
    const tallerId = localStorage.getItem('taller_id');

    if (!tallerId) {
      this.loading = false;
      return;
    }

    this.http.get<any[]>(`${this.API_URL}/taller/solicitudes-atendiendo/${tallerId}`)
      .subscribe({
        next: (res) => {
          this.solicitudes = res || [];
          this.loading = false;
        },
        error: () => {
          this.solicitudes = [];
          this.loading = false;
        }
      });
  }

  finalizarServicio(id: string): void {
  if (!confirm('¿Confirmas que el servicio fue finalizado?')) return;

  this.http.put(`${this.API_URL}/incidentes/finalizar/${id}`, {})
    .subscribe({
      next: () => {
        alert('Servicio finalizado correctamente');
        this.solicitudes = this.solicitudes.filter(s => s.id !== id);
      },
      error: () => alert('No se pudo finalizar el servicio')
    });
  }

  ngOnDestroy(): void {
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }
  }
}