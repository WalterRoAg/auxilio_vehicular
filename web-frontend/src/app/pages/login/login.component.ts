import { Component } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FormsModule, CommonModule, RouterLink],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent {
  email = '';
  password = '';

  constructor(private http: HttpClient, private router: Router) {}

 login() {
  this.http.post<any>('https://auxilio-vehicular.onrender.com/api/login-web', {
    email: this.email,
    password: this.password
  }).subscribe({
    next: (res) => {
      localStorage.setItem('token', res.token);
      localStorage.setItem('user_id', res.user_id);
      localStorage.setItem('taller_id', res.taller_id);
      localStorage.setItem('role', res.role);

      this.router.navigate(['/dashboard']);
    },
    error: (err) => {
      console.error('ERROR LOGIN:', err);
      alert(err.error?.detail || 'Credenciales incorrectas');
    }
  });
}
}