;;; -*- mode: lisp -*-

;;; Copyright (c) 2005--2007, by A.J. Rossini <blindglobe@gmail.com>
;;; See COPYRIGHT file for any additional restrictions (BSD license).
;;; Since 1991, ANSI was finally finished.  Edited for ANSI Common Lisp. 

(defpackage :lisp-stat-types
 (:use :common-lisp)
 (:export fixnump check-nonneg-fixnum check-one-fixnum
          check-one-real check-one-number check-sequence))

(in-package #:lisp-stat-types)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;                      Type Checking Functions
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Moved out of lsbasics.lsp

(defun fixnump (x)
  "Args: (x)
Returns T if X is a fixnum; NIL otherwise."
  (declare (inline typep))
  (typep x 'fixnum))

(defun check-nonneg-fixnum (x)
  (if (and (fixnump x) (<= 0 x)) x (error "not a non-negative fixnum")))

(defun check-one-fixnum (x)
  (if (not (fixnump x)) (error "not a fixnum - ~a" x)))

(defun check-one-real (a)
  (if (not (or (rationalp a) (floatp a)))
      (error "not a real number ~s" a)
    t))

(defun check-one-number (a)
  (if (not (numberp a))
      (error "not a number ~s" a)
    t))

(defun check-sequence (a)
  (if (not (or (vectorp a) (consp a))) (error "not a sequence - ~s" a)))
