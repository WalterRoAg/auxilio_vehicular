import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-encargados',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './encargados.component.html',
  styleUrls: ['./encargados.component.scss']
})
export class EncargadosComponent implements OnInit {
  nombre = '';
  email = '';
  telefono = '';
  password = '';

  encargados: any[] = [];
  esDueno = false;
  loading = true;
  guardando = false;

  private API_URL = environment.apiUrl;

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.verificarPermiso();
  }

  verificarPermiso(): void {
    const userId = localStorage.getItem('user_id');

    if (!userId) {
      this.loading = false;
      return;
    }

    this.http.get<any>(`${this.API_URL}/taller/perfil/${userId}`).subscribe({
      next: (res) => {
        this.esDueno = res.es_dueno === true;
        localStorage.setItem('taller_id', res.id);

        if (this.esDueno) {
          this.cargarEncargados(res.id);
        } else {
          this.loading = false;
        }
      },
      error: () => {
        this.loading = false;
      }
    });
  }

  cargarEncargados(tallerId: string): void {
    this.http.get<any[]>(`${this.API_URL}/taller/encargados/${tallerId}`).subscribe({
      next: (res) => {
        this.encargados = res || [];
        this.loading = false;
      },
      error: () => {
        this.encargados = [];
        this.loading = false;
      }
    });
  }

  registrarEncargado(): void {
    const tallerId = localStorage.getItem('taller_id');

    if (!this.esDueno) {
      alert('Solo el dueño del taller puede registrar encargados.');
      return;
    }

    if (!tallerId) {
      alert('No se encontró el taller asociado.');
      return;
    }

    if (!this.nombre || !this.email || !this.password) {
      alert('Completa nombre, email y contraseña.');
      return;
    }

    this.guardando = true;

    this.http.post(`${this.API_URL}/taller/encargados`, {
      taller_id: tallerId,
      nombre: this.nombre,
      email: this.email,
      telefono: this.telefono,
      password: this.password
    }).subscribe({
      next: () => {
        alert('Encargado registrado correctamente');
        this.nombre = '';
        this.email = '';
        this.telefono = '';
        this.password = '';
        this.guardando = false;
        this.cargarEncargados(tallerId);
      },
      error: (err) => {
        console.error(err);
        alert('Error al registrar encargado');
        this.guardando = false;
      }
    });
  }
}