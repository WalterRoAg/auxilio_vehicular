import { Routes } from '@angular/router';

import { LoginComponent } from './pages/login/login.component';
import { RegistroTallerComponent } from './pages/registro-taller/registro-taller.component';
import { TallerDashboardComponent } from './components/taller-dashboard/taller-dashboard.component';
import { TallerServiciosComponent } from './pages/taller-servicios/taller-servicios.component';
import { SaldoComponent } from './pages/saldo/saldo.component';
import { PerfilTallerComponent } from './pages/perfil-taller/perfil-taller.component';

export const routes: Routes = [
  { path: '', component: LoginComponent },
  { path: 'registro-taller', component: RegistroTallerComponent },
  { path: 'dashboard', component: TallerDashboardComponent },
  { path: 'servicios', component: TallerServiciosComponent },
  { path: 'perfil-taller', component: PerfilTallerComponent },
  { path: 'saldo', component: SaldoComponent },

  // 🔥 NUEVAS RUTAS
  {
  path: 'encargados',
  loadComponent: () => import('./pages/encargados/encargados.component').then(m => m.EncargadosComponent)
},
{
  path: 'solicitudes-atendiendo',
  loadComponent: () => import('./pages/solicitudes-atendiendo/solicitudes-atendiendo.component').then(m => m.SolicitudesAtendiendoComponent)
},
];