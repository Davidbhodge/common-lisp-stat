;;; -*- mode: lisp -*-

;;; File:       unittests-data-clos.lisp
;;; Author:     AJ Rossini <blindglobe@gmail.com>
;;; Copyright:  (c)2008, AJ Rossini.  BSD, LLGPL, or GPLv2, depending
;;;             on how it arrives.  
;;; Purpose:    unittests for the data-clos package
;;; Time-stamp: <2009-03-31 08:30:13 tony>
;;; Creation:   <2008-05-09 14:18:19 tony>

;;; What is this talk of 'release'? Klingons do not make software
;;; 'releases'.  Our software 'escapes', leaving a bloody trail of
;;; designers and quality assurance people in its wake.

(in-package :lisp-stat-unittests)

(deftestsuite lisp-stat-ut-dataclos (lisp-stat-ut) ())

;;; Ensure helper-functions work

(addtest (lisp-stat-ut-dataclos) genseq
	 (ensure
	  (equal (lisp-stat-data-clos::gen-seq 4)
		 (list 1 2 3 4))))

(addtest (lisp-stat-ut-dataclos) genseq-null
	 (ensure
	  (equal (lisp-stat-data-clos::gen-seq 0)
		 nil)))

(addtest (lisp-stat-ut-dataclos) genseq-offset
	 (ensure
	  (equal (lisp-stat-data-clos::gen-seq 4 2)
		 (list 2 3 4))))


(addtest (lisp-stat-ut-dataclos) repeatseq
	 (ensure
	  (equal (lisp-stat-data-clos::repeat-seq 3 "d")
		 (list "d" "d" "d")))
	 	 (ensure
	  (equal (lisp-stat-data-clos::repeat-seq 3 'd)
		 (list 'd 'd 'd))))










;;; Dataframe

(addtest (lisp-stat-ut-dataclos) df-equalp
	 (ensure
	  (equalp (dataset (make-instance 'dataframe-array
					  :storage #2A(('a 'b)
						       ('c 'd))))
		  #2A(('a 'b)
		      ('c 'd)))))


;; FAKE DF
(defparameter *my-df-0*
  (make-instance 'dataframe-array
		 :storage #2A((1 2 3 4 5)
			      (10 20 30 40 50))
		 :doc "This is an interesting dataframe-array"
		 :case-labels (list "a" "b" "c" "d" "e")
		 :var-labels (list "x" "y")))

;; WORKING DF
(defparameter *my-df-1*
  (make-instance 'dataframe-array
		 :storage #2A((1 2 3 4 5)
			      (10 20 30 40 50))
		 :doc "This is an interesting dataframe-array"
		 :case-labels (list "x" "y")
		 :var-labels  (list "a" "b" "c" "d" "e")))

(addtest (lisp-stat-ut-dataclos) df-consdata
	 (ensure
	  (consistent-dataframe-p *my-df-1*)))

(addtest (lisp-stat-ut-dataclos) df-access-1
	 (ensure-error
	  (slot-value *my-df-1* 'store)))

(addtest (lisp-stat-ut-dataclos) df-access-2
	 (ensure-error
	  (slot-value *my-df-1* 'store)))

(addtest (lisp-stat-ut-dataclos) df-access-3
	 (ensure
	  (dataset *my-df-1*)))

(addtest (lisp-stat-ut-dataclos) df-access-4
	 (ensure
	  (equalp
	   (slot-value *my-df-1* 'lisp-stat-data-clos::store)
	   (lisp-stat-data-clos::dataset *my-df-1*))))

(addtest (lisp-stat-ut-dataclos) badAccess5
	 (ensure
	  (eq (lisp-stat-data-clos::dataset *my-df-1*)
	      (slot-value *my-df-1* 'lisp-stat-data-clos::store))))


;; NEVER REACH INTO CLASS INTERIORS, NO PROMISE GUARANTEE OF LATER CONSISTENCY... 

(addtest (lisp-stat-ut-dataclos) badAccess6
	 (ensure
	  (lisp-stat-data-clos::doc-string *my-df-1*))
	 (ensure-error 
	  (doc-string *my-df-1*)))

(addtest (lisp-stat-ut-dataclos) badAccess7
	 (ensure
	  (lisp-stat-data-clos::case-labels *my-df-1*))
	 (ensure-error
	  (case-labels *my-df-1*)))

(addtest (lisp-stat-ut-dataclos) badAccess8
	 (ensure
	  (lisp-stat-data-clos::var-labels *my-df-1*))
	 (ensure-error
	  (var-labels *my-df-1*)))

;; need to ensure that for things like the following, that we protect
;; this a bit more so that the results are not going to to be wrong.
;; That would be a bit nasty if the dataframe-array becomes
;; inconsistent.

(addtest (lisp-stat-ut-dataclos) badAccess9
	 (ensure
	  (setf (lisp-stat-data-clos::var-labels *my-df-1*)
		(list "a" "b"))))

(addtest (lisp-stat-ut-dataclos) badAccess10
	 (ensure
	  (progn 
	    ;; no error, but corrupts structure
	    (setf (lisp-stat-data-clos::var-labels *my-df-1*)
		  (list "a" "b" "c"))
	    ;; error happens here
	    (not (consistent-dataframe-like-p *my-df-1*))))) ;; Nil

(addtest (lisp-stat-ut-dataclos) badAccess12
	 (ensure
	  (setf (lisp-stat-data-clos::var-labels *my-df-1*)
		(list "a" "b"))))

(addtest (lisp-stat-ut-dataclos) badAccess13
	 (ensure
	  (consistent-dataframe-like-p *my-df-1*))) ;; T

;; This is now done by:
(addtest (lisp-stat-ut-dataclos) badAccess14
	 (ensure-error
	  (let ((old-varnames (varNames *my-df-1*)))
	    (setf (varNames *my-df-1*) (list "a" "b")) ;; should error
	    (setf (varNames *my-df-1*) old-varnames)
	    (error "don't reach this point in badaccess14"))))

;; break this up.
(defvar origCaseNames nil)

(addtest (lisp-stat-ut-dataclos) badAccess15
	 (ensure
	  (progn
	    (setf origCaseNames (caseNames *my-df-1*))
	    (setf (caseNames *my-df-1*) (list "a" "b" "c" 4 5))
	    (caseNames *my-df-1*)
	    (ignore-errors
	      (setf (caseNames *my-df-1*)
		    (list "a" "b" 4 5)))
	    (setf (caseNames *my-df-1*) origCaseNames))))

;;;
;; (run-tests)
;; (describe (run-tests))
