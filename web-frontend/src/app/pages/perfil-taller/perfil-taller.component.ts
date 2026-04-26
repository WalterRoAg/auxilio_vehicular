import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-perfil-taller',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './perfil-taller.component.html',
  styleUrls: ['./perfil-taller.component.scss']
})
export class PerfilTallerComponent implements OnInit {
  private API_URL = environment.apiUrl;

  loading = true;
  guardando = false;
  error = '';
  exito = '';

  taller: any = {
    id: '',
    nombre_taller: '',
    especialidad: '',
    direccion: '',
    latitud: null,
    longitud: null,
    rating: 0,
    disponible: true
  };

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.cargarPerfil();
  }

  cargarPerfil(): void {
    const userId = localStorage.getItem('user_id');

    if (!userId) {
      this.error = 'No se encontró la sesión del usuario. Inicia sesión nuevamente.';
      this.loading = false;
      return;
    }

    this.http.get<any>(`${this.API_URL}/taller/perfil/${userId}`)
      .subscribe({
        next: (res) => {
          this.taller = {
            ...res,
            latitud: res.latitud ?? null,
            longitud: res.longitud ?? null,
            disponible: res.disponible ?? true
          };

          localStorage.setItem('taller_id', res.id);
          this.loading = false;
        },
        error: (err) => {
          console.error(err);
          this.error = 'No se pudo cargar el perfil del taller.';
          this.loading = false;
        }
      });
  }

  guardar(): void {
    this.error = '';
    this.exito = '';

    if (!this.taller.nombre_taller?.trim()) {
      this.error = 'El nombre del taller es obligatorio.';
      return;
    }

    if (!this.taller.direccion?.trim()) {
      this.error = 'La dirección es obligatoria.';
      return;
    }

    if (!this.taller.id) {
      this.error = 'No se encontró el ID del taller.';
      return;
    }

    this.guardando = true;

    const payload = {
      nombre_taller: this.taller.nombre_taller.trim(),
      especialidad: this.taller.especialidad?.trim() || 'Mecánica general',
      direccion: this.taller.direccion.trim(),
      latitud: this.taller.latitud ? Number(this.taller.latitud) : null,
      longitud: this.taller.longitud ? Number(this.taller.longitud) : null,
      disponible: Boolean(this.taller.disponible)
    };

    this.http.put(`${this.API_URL}/taller/perfil/${this.taller.id}`, payload)
      .subscribe({
        next: () => {
          this.exito = 'Perfil actualizado correctamente.';
          this.guardando = false;
        },
        error: (err) => {
          console.error(err);
          this.error = 'Error al guardar el perfil.';
          this.guardando = false;
        }
      });
  }
}