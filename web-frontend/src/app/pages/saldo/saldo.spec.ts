import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Saldo } from './saldo';

describe('Saldo', () => {
  let component: Saldo;
  let fixture: ComponentFixture<Saldo>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Saldo],
    }).compileComponents();

    fixture = TestBed.createComponent(Saldo);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
