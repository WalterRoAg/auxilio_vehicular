import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-saldo',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './saldo.component.html',
  styleUrls: ['./saldo.component.scss']
})
export class SaldoComponent implements OnInit {
  saldo = 0;
  totalServicios = 0;
  comision = 0;
  loading = true;

  private API_URL = environment.apiUrl;

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    const tallerId = localStorage.getItem('taller_id') || '05eed4ee-b1a6-4937-b3ab-39c723e3f711';

    this.http.get<any>(`${this.API_URL}/taller/saldo/${tallerId}`)
      .subscribe({
        next: (res) => {
          this.saldo = res.saldo || 0;
          this.totalServicios = res.total_servicios || 0;
          this.comision = res.comision || 0;
          this.loading = false;
        },
        error: () => {
          this.loading = false;
        }
      });
  }

  recargarSaldo(): void {
    const tallerId = localStorage.getItem('taller_id');

    if (!tallerId) {
      alert('ID de taller no encontrado');
      return;
    }

    // Aquí iría la lógica de recarga
    alert('Funcionalidad de recarga pendiente de implementar');
  }
}
