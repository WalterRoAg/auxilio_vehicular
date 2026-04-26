import { ComponentFixture, TestBed } from '@angular/core/testing';
import { RegistroTallerComponent } from './registro-taller.component';

describe('RegistroTallerComponent', () => {
  let component: RegistroTallerComponent;
  let fixture: ComponentFixture<RegistroTallerComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [RegistroTallerComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(RegistroTallerComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});