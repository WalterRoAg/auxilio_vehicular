import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SolicitudesAtendiendo } from './solicitudes-atendiendo.component';

describe('SolicitudesAtendiendo', () => {
  let component: SolicitudesAtendiendo;
  let fixture: ComponentFixture<SolicitudesAtendiendo>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SolicitudesAtendiendo],
    }).compileComponents();

    fixture = TestBed.createComponent(SolicitudesAtendiendo);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
