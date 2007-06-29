;;; -*- mode: lisp -*-
;;; Copyright (c) 2005--2007, by A.J. Rossini <blindglobe@gmail.com>
;;; See COPYRIGHT file for any additional restrictions (BSD license).
;;; Since 1991, ANSI was finally finished.  Edited for ANSI Common Lisp. 

;;; File:       data.lisp
;;; Author:     AJ Rossini <blindglobe@gmail.com>
;;; Copyright:  (c)2007, AJ Rossini.  BSD, LLGPL, or GPLv2, depending on how it arrives. 
;;; Purpose:    data package for lispstat
;;; Time-stamp: <2006-05-19 12:33:41 rossini> 
;;; Creation:   <2006-05-17 21:34:07 rossini> 

;;; What is this talk of 'release'? Klingons do not make software
;;; 'releases'.  Our software 'escapes', leaving a bloody trail of
;;; designers and quality assurance people in its wake.

;;; This organization and structure is new to the 21st Century
;;; version.


(in-package :cl-user)

(defpackage :lisp-stat-data
  (:documentation "Data I/O, management, other data technologies.")
  (:nicknames :ls-data)
  (:use :common-lisp
	:cxml
	:lisp-stat-object-system
	:lisp-stat-compound-data
	:lisp-stat-matrix
	:lisp-stat-linalg
	:lisp-stat-sequence)
  (:shadowing-import-from :lisp-stat-object-system
			  slot-value call-method call-next-method)
  (:export
   ;;; from statistics.lsp
          open-file-dialog read-data-file read-data-columns load-data 
          load-example *variables* *ask-on-redefine* def variables savevar
          undef  ))

(in-package :lisp-stat-data)

;;; The purpose of this package is to manage data which will be
;;; processed by LispStat.  In particular, it willbe importnat to
;;; register variables, datasets, relational structures, and other
;;; objects which could be the target for statistical modeling and
;;; inference.

(defvar *lisp-stat-data-table* (make-hash-table)
  "Marks up the data the could be used by.")

(defvar *lisp-stat-data-count* 0
  "number of items currently recorded.")

;;; Data Types:
;;;
;;; Data types are the representation of data from a computer-science
;;; perspective, i.e. what it is that they contain.  These types
;;; include particular forms of compound types (i.e. dataframe,
;;; relationdata are compounds of arrays of different types where the
;;; difference is row-wise, while array is a compound of elements of
;;; the same type.

;;Examples:
;;  (defun equidimensional (a)
;;    (or (< (array-rank a) 2)
;;        (apply #'= (array-dimensions a)))) =>  EQUIDIMENSIONAL
;;  (deftype square-matrix (&optional type size)
;;    `(and (array ,type (,size ,size))
;;          (satisfies equidimensional))) =>  SQUARE-MATRIX

(deftype dt-scalar (&optional type)
  `(or integer double complex))

(deftype dt-array (&optional type)
  `(satisfies equal-type))

(deftype dt-dataframe ()
  `(satisfies equal-type-within-column))

(deftype dt-relationdata ()
  `(satisfies (foreach unit in relationalUnit
	       (typep unit 'dt-dataframe)))) 




;;; Statistical Variable Classes
;;(deftype sv-nominal )
;;(deftype sv-ordinal )
;;(deftype sv-categorical (or 'sv-nominal 'sv-ordinal))
;;(deftype sv-integer )
;;(deftype sv-real )
;;(deftype sv-rational )
;;(deftype sv-complex )
;;(deftype sv-continuous (or 'sv-integer 'sv-real 'sv-rational 'sv-complex))


;;; Data I/O

;; We can read 2 types of data -- those which are pure data, and those
;; which are imprue (lisp-enables).

(defparameter *lisp-stat-data-formats*
  '(csv tsv))

;; (defgeneric data-read (srce frmt)
;;   "read data from stream srce, in format frmt.")

;; (defgeneric data-write (srce frmt)
;;   "read data from stream srce, in format frmt.")

;; (defmacro with-data (body)
;;   "Stream-handling, maintaining I/O through object typing.")

;; design-wise should these be replaced with a "with-data" form? 


;; DSV processing

;; XML processing

;;; Data Management

;; the goal is to have 2 operations which can be used to create new
;; data formats out of old ones.

;; (defgeneric data-subset (ds description) 
;;   "Take a dataset and make it smaller.")

;; (defgeneric data-relate (ds description) 
;;   "Take 2 or more datasets, and grow them into a bigger one through
;; relating them (i.e. merge is one example).")

;;; Data tools from "statistics.lsp" 

;;;;
;;;; Data File Reading 
;;;;

(defun count-file-columns (fname)
"Args: (fname)
Returns the number of lisp items on the first nonblank line of file FNAME."
  (with-open-file (f fname)
    (if f
        (let ((line (do ((line (read-line f) (read-line f))) 
                        ((or (null line) (< 0 (length line))) line))))
          (if line
              (with-input-from-string (s line)
                (do ((n 0 (+ n 1)) (eof (gensym))) 
                    ((eq eof (read s nil eof)) n))))))))

#+xlisp (defvar *xlisptable* *readtable*)

(if (not (fboundp 'open-file-dialog))
  #+dialogs
  (defun open-file-dialog (&optional set)
    (get-string-dialog "Enter a data file name:"))
  #-dialogs
  (defun open-file-dialog (&optional set)
    (error "You must provide a file name explicitly")))

(defun read-data-file (&optional (file (open-file-dialog t)))
"Args:  (file)
Returns a list of all lisp objects in FILE. FILE can be a string or a symbol,
in which case the symbol'f print name is used."
  (if file
      (let ((eof (gensym)))
        (with-open-file (f file)
          (if f
	      (do* ((r (read f nil eof) (read f nil eof))
		    (x (list nil))
		    (tail x (cdr tail)))
		   ((eq r eof) (cdr x))
		   (setf (cdr tail) (list r))))))))

;;; New definition to avoid stack size limit in apply
(defun read-data-columns (&optional (file (open-file-dialog t))
                                    (cols (if file 
                                              (count-file-columns file))))
"Args: (&optional file cols)
Reads the data in FILE as COLS columns and returns a list of lists representing the columns."
  (if (and file cols)
      (transpose (split-list (read-data-file file) cols))))


;;; FIXME:AJR:  ALL THE FOLLOWING ARE SOLVED BY PLATFORM-INDEP PATHNAME WORK! 

#+unix
(defun load-data (file)
"Args: (file)
Read in data file from the data examples library."
  (if (load (format nil "~aData/~a" *default-path* file))
      t
      (load (format nil "~aExamples/~a" *default-path* file))))

#+unix
(defun load-example (file)
"Args: (file)
Read in lisp example file from the examples library."
  (if (load (format nil "~aExamples/~a" *default-path* file))
      t
      (load (format nil "~aData/~a" *default-path* file))))
#+macintosh
(defun load-data (s) (require s (concatenate 'string ":Data:" s)))
#+macintosh
(defun load-example (s) (require s (concatenate 'string ":Examples:" s)))

#+msdos
(defun load-data (file)
"Args: (file)
Read in data file from the data examples library."
  (load (format nil "~aData\\~a" *default-path* file)))

#+msdos
(defun load-example (file)
"Args: (file)
Read in lisp example file from the examples library."
  (load (format nil "~aExamples\\~a" *default-path* file)))

;;;;
;;;; Listing and Saving Variables and Functions
;;;;

(defvar *variables* nil)
(defvar *ask-on-redefine* nil)

(defmacro def (symbol value)
"Syntax: (def var form)
VAR is not evaluated and must be a symbol.  Assigns the value of FORM to
VAR and adds VAR to the list *VARIABLES* of def'ed variables. Returns VAR.
If VAR is already bound and the global variable *ASK-ON-REDEFINE*
is not nil then you are asked if you want to redefine the variable."
  `(unless (and *ask-on-redefine*
                (boundp ',symbol)
                (not (y-or-n-p "Variable has a value. Redefine?")))
           (pushnew ',symbol *variables*)
           (setf ,symbol ,value)
           ',symbol))
  
(defun variables-list () 
    (mapcar #'intern (sort-data (mapcar #'string *variables*))))

(defun variables ()
"Args:()
Returns a list of the names of all def'ed variables to STREAM"
  (if *variables*
      (mapcar #'intern (sort-data (mapcar #'string *variables*)))))
  
(defun savevar (vars file)
"Args: (vars file-name-root)
VARS is a symbol or a list of symbols. FILE-NAME-ROOT is a string (or a symbol
whose print name is used) not endinf in .lsp. The VARS and their current values
are written to the file FILE-NAME-ROOT.lsp in a form suitable for use with the
load command."
  (with-open-file (f (strcat (string file) ".lsp") :direction :output)
    (let ((vars (if (consp vars) vars (list vars))))
      (flet ((save-one (x)
	       (let ((v (symbol-value x)))
		 (if (objectp v) 
		     (format f "(def ~s ~s)~%" x (send v :save))
		   (format f "(def ~s '~s)~%" x v)))))
	    (mapcar #'save-one vars))
      vars)))

(defun undef (v)
"Args: (v)
If V is the symbol of a defined variable the variable it is unbound and
removed from the list of defined variables. If V is a list of variable
names each is unbound and removed. Returns V."
  (dolist (s (if (listp v) v (list v)))
          (when (member s *variables*)
                (setq *variables* (delete s *variables*))
                (makunbound s)))
  v)
        
;;;;
;;;; Miscellaneous Routines
;;;;

(defun split-list (x n)
"Args: (list cols)
Returns a list of COLS lists of equal length of the elements of LIST.
Example: (split-list '(1 2 3 4 5 6) 2) returns ((1 2 3) (4 5 6))"
  (check-one-fixnum n)
  (if (/= (rem (length x) n) 0) (error "length not divisible by ~a" n))
  (flet ((next-split ()
           (let ((result nil)
                 (end nil))
             (dotimes (i n result)
               (declare (fixnum i))
               (let ((c-elem (list (first x))))
                 (cond ((null result)
                        (setf result c-elem)
                        (setf end result))
                       (t 
                        (setf (rest end) c-elem)
                        (setf end (rest end)))))
               (setf x (rest x))))))
    (let ((result nil)
          (end nil)
          (k (/ (length x) n)))
      (declare (fixnum k))
      (dotimes (i k result)
        (declare (fixnum i))
        (let ((c-sub (list (next-split))))
          (cond ((null result)
                 (setf result c-sub)
                 (setf end result))
                (t 
                 (setf (rest end) c-sub)
                 (setf end (rest end)))))))))
