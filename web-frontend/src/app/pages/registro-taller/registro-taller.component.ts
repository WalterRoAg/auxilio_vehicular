import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-registro-taller',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './registro-taller.component.html',
  styleUrls: ['./registro-taller.component.scss']
})
export class RegistroTallerComponent {
  nombre = '';
  email = '';
  telefono = '';
  password = '';
  nombre_taller = '';
  especialidad = '';
  direccion = '';

  constructor(private http: HttpClient, private router: Router) {}

  registrar() {
    this.http.post('http://localhost:8000/api/registrar-taller', {
      nombre: this.nombre,
      email: this.email,
      telefono: this.telefono,
      password: this.password,
      nombre_taller: this.nombre_taller,
      especialidad: this.especialidad,
      direccion: this.direccion
    }).subscribe({
      next: () => {
        alert('Taller registrado correctamente');
        this.router.navigate(['/']);
      },
      error: (err) => {
        console.error(err);
        alert('Error al registrar taller');
      }
    });
  }
}