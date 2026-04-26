import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Encargados } from './encargados.component';

describe('Encargados', () => {
  let component: Encargados;
  let fixture: ComponentFixture<Encargados>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Encargados],
    }).compileComponents();

    fixture = TestBed.createComponent(Encargados);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
