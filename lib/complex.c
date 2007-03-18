/* complex - Complex number functions                                  */
/* Copyright (c) 1990, by Luke Tierney                                 */

/* patched up and semi-ansified, (c) 2006, AJ Rossini, blindglobe@gmail.com */

#include "xmath.h"
#include "complex.h"

extern void xlfail(char *);

/*static */
double 
phase(Complex c)
{
  double phi;
  
  if (c.real == 0.0) {
    if (c.imag > 0.0) phi = PI / 2;
    else if (c.imag == 0.0) phi = 0.0;
    else phi = -PI / 2;
  } else {
    phi = atan(c.imag / c.real);
    if (c.real < 0.0) {
      if (c.imag > 0.0) {
	phi += PI;
      } else { 
	if (c.imag < 0.0) {
	  phi -= PI;
	} else { 
	  phi = PI;
	}
      }
    }
  }
  return(phi);
}

double 
modulus(Complex c)
{
  return(sqrt(c.real * c.real + c.imag * c.imag));
}

Complex
cart2complex(double real, double imag)
{
  Complex val;
  val.real = real;
  val.imag = imag;
  return(val);
}

Complex
polar2complex(double mod, double phi) 
{
  Complex val;
  double cs, sn;
  
  if (phi == 0) {
    cs = 1.0;
    sn = 0.0;
  } else {
    if (phi == PI / 2) {
      cs = 0.0;
      sn = 1.0;
    } else {
      if (phi == PI) {
	cs = -1.0;
	sn = 0.0;
      } else { 
	if (phi == -PI / 2) {
	  cs = 0.0;
	  sn = -1.0;
	} else {
	  cs = cos(phi);
	  sn = sin(phi);
	}
      }
    }
  }
  val.real = mod * cs;
  val.imag = mod * sn;
  return(val);
}
 
Complex
cadd(Complex c1,
     Complex c2)
{
  return(cart2complex(c1.real + c2.real, c1.imag + c2.imag));
}

Complex
csub(Complex c1,
     Complex c2)
{
  return(cart2complex(c1.real - c2.real, c1.imag - c2.imag));
}

Complex
cmul(Complex c1, Complex c2) 
{
  double m1, m2, p1, p2;
  
  m1 = modulus(c1);
  p1 = phase(c1);
  m2 = modulus(c2);
  p2 = phase(c2);
  return(polar2complex(m1 * m2, p1 + p2));
}

static void
checkfzero(double x) 
{
  if (x == 0.0) {
    xlfail("division by zero");
  }
}

Complex
cdiv(Complex c1, Complex c2)
{
  double m1, m2, p1, p2;
  
  m1 = modulus(c1);
  p1 = phase(c1);
  m2 = modulus(c2);
  p2 = phase(c2);
  checkfzero(m2);
  return(polar2complex(m1 / m2, p1 - p2));
}
