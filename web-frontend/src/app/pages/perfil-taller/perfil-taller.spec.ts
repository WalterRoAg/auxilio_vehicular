import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PerfilTaller } from './perfil-taller';

describe('PerfilTaller', () => {
  let component: PerfilTaller;
  let fixture: ComponentFixture<PerfilTaller>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [PerfilTaller],
    }).compileComponents();

    fixture = TestBed.createComponent(PerfilTaller);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
