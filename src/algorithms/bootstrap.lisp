;;; -*- mode: lisp -*-

;;; Time-stamp: <2009-03-12 17:46:34 tony>
;;; Creation:   <2008-03-11 19:18:34 user> 
;;; File:       bootstrap.lisp
;;; Author:     AJ Rossini <blindglobe@gmail.com>
;;; Copyright:  (c)2009--, AJ Rossini.  BSD, LLGPL, or GPLv2, depending
;;;             on how it arrives.  
;;; Purpose:    bootstrapping algorithms for lispstat

;;; What is this talk of 'release'? Klingons do not make software
;;; 'releases'.  Our software 'escapes', leaving a bloody trail of
;;; designers and quality assurance people in its wake.

(in-package :cls-algorithms-bootstrap)

;;; implememented through general macros for a lispy approach.  There
;;; could be a functional approach as well, i.e.
;;;            (bootstrap data #'function args) 
;;;

(defmacro with-data-bootstrap (n (list-of-sources-and-vars) @body)
  "A proposed lispy implementation, such as:
     (with-data-bootstrap n 
                          ((a dataset1)
                           (b dataset2))
        (some-form-with-inputs a b c))
where there could be multiple datasets, with a and b, etc, being
bootstrap realizations of dataset1 and dataset2."
  (Destructure list-of-sources-and-var)
  (loop repeat n
        (progn (pull-samples sources)
	       @body)
     accumulate in result-list))

;; (defmacro with-correlated-data-bootstrap ())

;; The point of this goes away when we have assurance that
;; observations are independent.  And by being able to embed complex
;; objects (temporal / spatial / network structures) into the dataset
;; as typed variables, we now are able to assure such a probability
;; structure. 
 
;;; functional approach

(defgeneric bootstrap-sample (data &optional n replace)
  (:documentation "generate a dataset of N obs from DATA either with
  or without replace(ment)")
  (:default-method (data &optional n replace)))

(defgeneric bootstrap (data function args)
  (:documentation  "used such as: (bootstrap dataset t-test :significance 0.5)")
  (:default-method (funcall #'function (bootstrap-sample data) (values args))))


#|
  2 possible paradigms:

   (with-data-bootstrap ((a dataset1))
      (t-test a :significance 0.05))

   (bootstrap #'t-test a :significance 0.05)
|#
