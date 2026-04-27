import { Component, OnInit } from '@angular/core';
import { Router, RouterOutlet, RouterLink, RouterLinkActive, NavigationEnd } from '@angular/router';
import { CommonModule } from '@angular/common';
import { filter } from 'rxjs';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './app.html',
  styleUrls: ['./app.scss']
})
export class AppComponent implements OnInit {

  constructor(private router: Router) {}

  ngOnInit(): void {
    this.router.events
      .pipe(filter(event => event instanceof NavigationEnd))
      .subscribe(() => {
        const ruta = this.router.url;
        const token = localStorage.getItem('token');

        const rutasPublicas = ['/', '/registro-taller'];

        if (!token && !rutasPublicas.includes(ruta)) {
          this.router.navigate(['/']);
        }

        if (token && ruta === '/') {
          this.router.navigate(['/dashboard']);
        }
      });
  }

  mostrarLayout(): boolean {
    const ruta = this.router.url;
    return ruta !== '/' && ruta !== '/registro-taller';
  }

  cerrarSesion(): void {
    localStorage.clear();
    this.router.navigate(['/']);
  }
}