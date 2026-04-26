import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

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
    this.tallerId = localStorage.getItem('user_id') || '';

    this.http.get<any[]>('http://localhost:8000/api/servicios')
      .subscribe(data => {
        this.servicios = data.map(s => ({
          ...s,
          checked: false
        }));
      });
  }

  guardar() {
    const seleccionados = this.servicios
      .filter(s => s.checked)
      .map(s => s.id);

    this.http.post('http://localhost:8000/api/taller/servicios', {
      taller_id: this.tallerId,
      servicios: seleccionados
    }).subscribe(() => {
      alert('Servicios guardados');
    });
  }
}