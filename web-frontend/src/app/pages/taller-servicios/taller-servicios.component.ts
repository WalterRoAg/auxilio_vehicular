import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-taller-servicios',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './taller-servicios.component.html'
})
export class TallerServiciosComponent implements OnInit {

  servicios: any[] = [];
  tallerId = '';

  constructor(private http: HttpClient) {}

  ngOnInit() {
  this.tallerId = localStorage.getItem('taller_id') || '';

  this.http.get<any[]>(`${environment.apiUrl}/servicios`)
    .subscribe({
      next: (servicios) => {
        this.http.get<string[]>(`${environment.apiUrl}/taller/servicios/${this.tallerId}`)
          .subscribe({
            next: (seleccionados) => {
              this.servicios = servicios.map(s => ({
                ...s,
                checked: seleccionados.includes(String(s.id))
              }));
            },
            error: () => {
              this.servicios = servicios.map(s => ({
                ...s,
                checked: false
              }));
            }
          });
      },
      error: (err) => {
        console.error('ERROR CARGANDO SERVICIOS:', err);
        alert(err.error?.detail || 'Error cargando servicios');
      }
    });
}

  guardar() {
    const seleccionados = this.servicios
      .filter(s => s.checked)
      .map(s => s.id);

    this.http.post(`${environment.apiUrl}/taller/servicios`, {
      taller_id: this.tallerId,
      servicios: seleccionados
    }).subscribe(() => {
      alert('Servicios guardados');
    });
  }
}