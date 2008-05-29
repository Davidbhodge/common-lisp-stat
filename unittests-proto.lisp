;;; -*- mode: lisp -*-
;;; Copyright (c) 2007, by A.J. Rossini <blindglobe@gmail.com>
;;; See COPYRIGHT file for any additional restrictions (BSD license).
;;; Since 1991, ANSI was finally finished.  Edited for ANSI Common Lisp. 

;;; This is semi-external to lispstat core packages.  The dependency
;;; should be that lispstat packages are dependencies for the unit
;;; tests.  However, where they will end up is still to be
;;; determined. 

(in-package :cl-user)

(defpackage :lisp-stat-unittests-proto
  (:use :common-lisp :lift :lisp-stat :lisp-stat-unittests)
  (:shadowing-import-from :lisp-stat
	slot-value call-method call-next-method ;; objects
	expt + - * / ** mod rem abs 1+ 1- log exp sqrt sin cos tan ;; lsmath
	asin acos atan sinh cosh tanh asinh acosh atanh float random
	truncate floor ceiling round minusp zerop plusp evenp oddp 
	< <= = /= >= > ;; complex
	conjugate realpart imagpart phase
	min max logand logior logxor lognot ffloor fceiling
	ftruncate fround signum cis)
  (:export lisp-stat-ut-proto)) ;; unit tests -- rename?

(in-package :lisp-stat-unittests-proto)

;;; Object System tests

(deftestsuite lisp-stat-proto (lisp-stat) ())

;; need to ensure stability of add, display, send, instantiate and
;; similar actions.

(deftestsuite lisp-stat-ut-proto (lisp-stat)
  ()
  (:tests
   (create-proto (ensure  (typep (defproto test-me) 'instance)))
   (instance1 (ensure (send test-me :isnew)))
   (instance2 (ensure (send test-me :has-slot 'new)))
   (instance5 (ensure (send test-me :own-slots 'new)))))

;; (run-tests :suite 'lisp-stat-ut-proto)
