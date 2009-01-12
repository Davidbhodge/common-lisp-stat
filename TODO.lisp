;;; -*- mode: lisp -*-

;;; Time-stamp: <2009-01-11 17:10:57 tony>
;;; Creation:   <2008-09-08 08:06:30 tony>
;;; File:       TODO.lisp
;;; Author:     AJ Rossini <blindglobe@gmail.com>
;;; Copyright:  (c) 2007-2008, AJ Rossini <blindglobe@gmail.com>.  BSD.
;;; Purpose:    Stuff that needs to be made working sits inside the progns...

;;; What is this talk of 'release'? Klingons do not make software
;;; 'releases'.  Our software 'escapes', leaving a bloody trail of
;;; designers and quality assurance people in its wake.

;;; This file contains the current challenges to solve, including a
;;; description of the setup and the work to solve....
 
;;; SET UP

(in-package :cl-user)
;;(asdf:oos 'asdf:compile-op 'lispstat)
;;(asdf:oos 'asdf:load-op 'lispstat)


(in-package :lisp-stat-unittests)

;; tests = 54, failures = 7, errors = 3

(describe (run-tests :suite 'lisp-stat-ut))
(run-tests :suite 'lisp-stat-ut)

(in-package :ls-user)

;;; FIXME: Example: currently not relevant, yet
#|
  (describe 
    (lift::run-test
      :test-case  'lisp-stat-unittests::create-proto
      :suite 'lisp-stat-unittests::lisp-stat-ut-proto))
|#

:;; FIXME: data frames and structural inheritance
;;
;; Serious flaw -- need to consider that we are not really well
;; working with the data structures, in that Luke created compound as
;; a base class, which turns out to be slightly backward if we are to
;; maintain the numerical structures as well as computational
;; efficiency.

;; Currently, we assume that the list-of-list representation is in
;; row-major form, i.e. that lists represent rows and not columns.
;; The original lisp-stat had the other way around.  We could augment
;; the top-level list with a property to check orientation
;; (row-major/column-major), but this hasn't been done yet.

#+nil
(progn ;; FIXME: Regression modeling

  (defparameter m nil
    "holding variable.")
  ;; need to make vectors and matrices from the lists...

  (def m (regression-model (list->vector-like iron)
			   (list->vector-like absorbtion) :print nil))
			   ;;Good
  (send m :print)
  (send m :own-slots)
  (send m :own-methods)
  ;; (lsos::ls-objects-methods m) ; bogus?
  (send m :show)
  
  (def m (regression-model (list->vector-like iron)
			   (list->vector-like absorbtion)))

  (def m (regression-model (listoflists->matrix-like  (list iron aluminum))
			   (list->vector-like  absorbtion) :print nil))


  (documentation 'make-matrix 'function)

  ;; Making data-frames (i.e. cases (rows) by variables (columns))
  ;; takes a bit of getting used to.  For this, it is important to
  ;; realize that we can do the following:
  ;; #1 - consider the possibility of having a row, and transposing
  ;; it, so the list-of-lists is:  ((1 2 3 4 5))     (1 row, 5 columns)
  ;; #2 - naturally list-of-lists: ((1)(2)(3)(4)(5)) (5 rows, 1 column)
  (defparameter *indep-vars-1-matrix*
    (transpose  (make-matrix 1 (length iron)
		 :initial-contents
		 (list (mapcar #'(lambda (x) (coerce x 'double-float))
			       iron))))
    "test param")

  (documentation '*indep-vars-1-matrix* 'variable)
  ;; *indep-vars-1-matrix*

  ;; or directly:
  (defparameter *indep-vars-1a-matrix*
    (make-matrix (length iron)  1 
		 :initial-contents
		 (mapcar #'(lambda (x) (list  (coerce x 'double-float)))
			       iron)))
  ;; *indep-vars-1a-matrix*

  ;; and mathematically, they seem equal:
  (m= *indep-vars-1-matrix* *indep-vars-1a-matrix*) ; => T
  (eql *indep-vars-1-matrix* *indep-vars-1a-matrix*) ; => NIL
  (eq *indep-vars-1-matrix* *indep-vars-1a-matrix*) ; => NIL

  (print *indep-vars-1-matrix*)
  (print *indep-vars-1a-matrix*)

  ;; the weird way  
  (defparameter *indep-vars-2-matrix*
    (transpose (make-matrix  2 (length iron)
			     :initial-contents
			     (list
			      (mapcar #'(lambda (x) (coerce x 'double-float))
				      iron)
			      (mapcar #'(lambda (x) (coerce x 'double-float))
				      aluminum)))))
  ;; *indep-vars-2-matrix*
  
  ;; the "right"? way  
  (defparameter *indep-vars-2-matrix*
    (make-matrix (length iron) 2
		 :initial-contents
		 (mapcar #'(lambda (x y) 
			     (list (coerce x 'double-float)
				   (coerce y 'double-float)))
			 iron aluminum)))
  ;; *indep-vars-2-matrix*

  (defun lists-of-same-size (&rest list-of-list-names)
    "Check to see if the lengths of the lists are equal, to justify
further processing and initial conditions."
    (if (< 0  (reduce #'(lambda (x y) (if  (= x y) y -1))
		(mapcar #'length list-of-list-names)))
	T nil))
    

  ;; (and T T nil T)
  ;; (and T T T)
  ;; (defparameter *x1* (list 1 2 3))
  ;; (defparameter *x2* (list 1 2 3))
  ;; (defparameter *x3* (list 1 2 3 4))
  ;; (defparameter *x4* (list 1 2 3))
#|
  (reduce #'(lambda (x y)
	      (if (= x y) y -1))
	  (mapcar #'length (list *x1* *x2* *x3*)))
  (reduce #'(lambda (x y)
	      (if (= x y) y -1))  (list 2 3 2))
|#
  ;; (lists-of-same-size *x1* *x2* *x4*) ; => T
  ;; (lists-of-same-size *x1* *x3* *x4*) ; => F
  ;; (lists-of-same-size *x1* *x2* *x3*) ; => F
  ;; (lists-of-same-size *x3* *x1* *x3*) ; => F



  (defmacro make-data-set-from-lists (datasetname
				      &optional (force-overwrite nil)
				      &rest lists-of-data-lists)
    "Create a cases-by-variables data frame consisting of numeric data."
    (if (or (not (boundp datasetname))
	    force-overwrite)
	(if (lists-of-same-size lists-of-data-lists)
	    `(defparameter ,datasetname
	       (make-matrix (length iron) 2
			    :initial-contents
			    (mapcar #'(lambda (x y) 
					(list (coerce x 'double-float)
					      (coerce y 'double-float)))
				    @lists-of-data-lists)))
	    (error "make-data-set-from-lists: no combining different length lists"))
	(error "make-data-set-from-lists: proposed name exists")))

  (macroexpand (make-data-set-from-lists
		this-data
		:force-overwrite nil
		aluminum iron))


  (defun transpose-listoflists (listoflists)
    "This function does the moral-equivalent of a matrix transpose on
    a list-of-lists data structure"
    (apply #'mapcar #'list listoflists))

  ;; (defparameter LOL-2by3 (list (list 1 2) (list 3 4) (list 5 6)))
  ;; (values-list LOL-2by3)
  ;; (apply #'mapcar #'list LOL-2by3)
  ;; (transpose-listoflists (transpose-listoflists LOL-2by3))
  ;; => (list (list 1 3 5) (list 2 4 6))
  ;; (mapcar #'list LOL-2by3)

  ;; The below FAILS due to coercion issues; it just isn't lispy, it's R'y.
#|
  (defparameter *dep-var* (make-vector (length absorbtion)
				       :initial-contents (list absorbtion)))
|#
  ;; BUT below, this should be the right type.
  (defparameter *dep-var*
    (make-vector (length absorbtion)
		 :type :row
		 :initial-contents
		 (list 
		  (mapcar #'(lambda (x) (coerce x 'double-float))
			  absorbtion))))
  ;; *dep-var*

  
  (defparameter *dep-var-int*
    (make-vector (length absorbtion)
		 :type :row
		 :element-type 'integer
		 :initial-contents (list absorbtion)))
  
  (typep *dep-var* 'matrix-like)	; => T
  (typep *dep-var* 'vector-like)	; => T
  
  (typep *indep-vars-1-matrix* 'matrix-like) ; => T
  (typep *indep-vars-1-matrix* 'vector-like) ; => T
  (typep *indep-vars-2-matrix* 'matrix-like) ; => T
  (typep *indep-vars-2-matrix* 'vector-like) ; => F

  (def m1 (regression-model-new *indep-vars-1-matrix* *dep-var* ))
  (def m2 (regression-model-new *indep-vars-2-matrix* *dep-var* ))
  
  iron
  ;; following fails, need to ensure that we work on list elts, not just
  ;; elts within a list:
  ;; (coerce iron 'real) 

  ;; the following is a general list-conversion coercion approach -- is
  ;; there a more efficient way?
  (mapcar #'(lambda (x) (coerce x 'double-float)) iron)

  (coerce 1 'real)

  (send m :compute)
  (send m :sweep-matrix)
  (format t "~%~A~%" (send m :sweep-matrix))

  ;; need to get multiple-linear regression working (simple linear regr
  ;; works)... to do this, we need to redo the whole numeric structure,
  ;; I'm keeping these in as example of brokenness...
  
  (send m :basis) ;; this should be positive?
  (send m :coef-estimates)  )

#+nil
(progn ;; FIXME: Need to clean up data examples, licenses, attributions, etc.
  ;; The following breaks because we should use a package to hold
  ;; configuration details, and this would be the only package outside
  ;; of packages.lisp, as it holds the overall defsystem structure.
  (load-data "iris.lsp")  ;; (the above partially fixed).
  (variables)
  diabetes )

#+nil
(progn ;; FIXME: Data.Frames probably deserve to be related to lists --
  ;; either lists of cases, or lists of variables.  We probably do not
  ;; want to mix them, but want to be able to convert between such
  ;; structures.

  (defparameter *my-case-data*
    '((:cases
       (:case1 Y Med  3.4 5)
       (:case2 N Low  3.2 3)
       (:case3 Y High 3.1 4))
      (:var-names (list "Response" "Level" "Pressure" "Size"))))

  *my-case-data*

  (elt *my-case-data* 1)
  (elt *my-case-data* 0)
  (elt *my-case-data* 2) ;; error
  (elt (elt *my-case-data* 0) 1)
  (elt (elt *my-case-data* 0) 0)
  (elt (elt (elt *my-case-data* 0) 1) 0)
  (elt (elt (elt *my-case-data* 0) 1) 1)
  (elt (elt (elt *my-case-data* 0) 1) 2)
  (elt (elt *my-case-data* 0) 3))

#+nil
(progn ;; FIXME: read data from CSV file.  To do.

  ;; challenge is to ensure that we get mixed arrays when we want them,
  ;; and single-type (simple) arrays in other cases.

  (defparameter *csv-num* (read-csv "Data/example-num.csv" :type 'numeric))
  (defparameter *csv-mix* (read-csv "Data/example-mixed.csv" :type 'data))

  ;; The handling of these types should be compariable to what we do for
  ;; matrices, but without the numerical processing.  i.e. mref, bind2,
  ;; make-dataframe, and the class structure should be similar. 
  
  ;; With numerical data, there should be a straightforward mapping from
  ;; the data.frame to a matrix.   With categorical data (including
  ;; dense categories such as doc-strings, as well as sparse categories
  ;; such as binary data), we need to include metadata about ordering,
  ;; coding, and such.  So the structures should probably consider 

  ;; Using the CSV file:
  
  (asdf:oos 'asdf:compile-op 'csv :force t)
  (asdf:oos 'asdf:load-op 'parse-number)
  (asdf:oos 'asdf:load-op 'csv)
  (fare-csv:read-csv-file "Data/example-numeric.csv")

  ;; but I think the cl-csv package is broken, need to use the dsv-style
  ;; package.

  ;; now we've got the DSV code in the codebase, auto-loaded I hope:
  cybertiggyr-dsv:*field-separator*
  (defparameter *example-numeric.csv* 
    (cybertiggyr-dsv:load-escaped "Data/example-numeric.csv"
				  :field-separator #\,))
  *example-numeric.csv*

  ;; the following fails because we've got a bit of string conversion
  ;; to do.   2 thoughts: #1 modify dsv package, but mucking with
  ;; encapsulation.  #2 add a coercion tool (better, but potentially
  ;; inefficient).
  #+nil(coerce  (nth 3 (nth 3 *example-numeric.csv*)) 'double-float)

  ;; cases, simple to not so
  (defparameter *test-string1* "1.2")
  (defparameter *test-string2* " 1.2")
  (defparameter *test-string3* " 1.2 ")

  
  )


#+nil
(progn ;; experiments with GSL and the Lisp interface.
  (asdf:oos 'asdf:load-op 'gsll)
  (asdf:oos 'asdf:load-op 'gsll-tests)

  ;; the following should be equivalent
  (setf *t1*  (LIST 6.18d0 6.647777777777779d0 6.18d0))
  (setf *t2*  (MULTIPLE-VALUE-LIST
	       (LET ((VEC
		      (gsll:make-marray 'DOUBLE-FLOAT
					:INITIAL-CONTENTS '(-3.21d0 1.0d0 12.8d0)))
		     (WEIGHTS
		      (gsll:MAKE-MARRAY 'DOUBLE-FLOAT
					:INITIAL-CONTENTS '(3.0d0 1.0d0 2.0d0))))
		 (LET ((MEAN (gsll:MEAN VEC)))
		   (LIST (gsll:ABSOLUTE-DEVIATION VEC)
			 (gsll:WEIGHTED-ABSOLUTE-DEVIATION VEC WEIGHTS)
			 (gsll:ABSOLUTE-DEVIATION VEC MEAN))))))
  (eql *t1* *t2*)

  ;; from (gsll:examples 'gsll::numerical-integration) ...
  (gsll:integration-qng gsll::one-sine 0.0d0 PI)


  (defun-single axpb (x) (+ (* 2 x) 3)) ;; a<-2, b<-3
  (gsll:integration-qng axpb 1d0 2d0)

  (let ((a 2)
	(b 3))
    (defun-single axpb2 (x) (+ (* a x) b)))
  (gsll:integration-qng axpb2 1d0 2d0)


#| BAD
  (gsll:integration-qng 
   (let ((a 2)
	 (b 3))
     (defun-single axpb2 (x) (+ (* a x) b)))
   1d0 2d0)
|#

  ;; right, but weird expansion...
  (gsll:integration-qng 
   (let ((a 2)
	 (b 3))
     (defun axpb2 (x) (+ (* a x) b))
     (def-single-function axpb2)
     axpb2)
   1d0 2d0)


  )



#+nil
(progn ;; philosophy time
  
  (setf my-model (model :name "ex1"
			:data-slots (list x y z)
			:param-slots (list alpha beta gamma)
			:math-form (regression-model :formula '(= y (+ (* beta x)
								     (* alpha y)
								     (* gamma z)
								     normal-error)))))
  (setf my-dataset (statistical-table :table data-frame-contents
				      :metadata (list (:case-names (list ))
						      (:var-names (list ))
						      (:documentation "string of doc"))))

  (setf my-analysis (analysis
		     :model my-model
		     :data my-dataset
		     :parameter-map (pairing (model-param-slots my-model)
					     (data-var-names my-dataset))))

  ;; ontological implications -- the analysis is an abstract class of
  ;; data, model, and mapping between the model and data.  The fit is
  ;; the instantiation of such.  This provides a statistical object
  ;; computation theory which can be realized as "executable
  ;; statistics" or "computable statistics".
  (setf my-analysis (analyze my-fit
			     :estimation-method 'linear-least-squares-regression))

  ;; one of the tricks here is that one needs to provide the structure
  ;; from which to consider estimation, and more importantly, the
  ;; validity of the estimation.

  ;;
  (setf linear-least-squares-regression
	(estimation-method-definition
	 :variable-defintions ((list 
				;; from MachLearn: supervised,
				;; unsupervised
				:data-response-vars list-drv ; nil if unsup
				;; 
				:param-vars list-pv
				     :data-predictor-vars list-dpv 
				     ;; nil in this case.  these
				     ;; describe "out-of-box" specs
				     :hyper-vars list-hv))
	 :form '(regression-additive-error
		 :central-form (linear-form drv pv dpv)
		 :error-form 'normal-error)
	 :resulting-decision '(point-estimation interval-estimation)
	 :philosophy 'frequentist
	 :documentation "use least squares to fit a linear regression
                         model to data."))

  (defparameter *statistical-philosophies*
    '(frequentist bayesian fiducial decision-analysis)
    "can be combined to build decision-making approaches and
    characterizations")

  (defparameter *decisions*
    '(estimation selection testing)
    "possible results from a...")
  ;; is this really true?  One can embedded hypothesis testing within
  ;; estimation, as the hypothesis estimated to select.  And
  ;; categorical/continuous rear their ugly heads, but not really in
  ;; an essential way.

  (defparameter *ontology-of-decision-procedures*
    (list :decisions
	  (list :estimation
		(list :point
		      (list :maximum-likelihood
			    :minimum-entropy
			    :least-squares
			    :method-of-moments)
		      :interval
		      (list :maximum-likelihood
			    :))
		:testing
		(list :fisherian
		      :neyman-pearson
		      (list :traditional
			    :bioequivalence-inversion)
		      :selection
		      (list :ranking
			    :top-k-of-n-select))
		:parametric
		:partially-parametric))
    "start of ontology")



  )





#+nil
(progn  ;;; QR factorization
  ;; Need to incorporate the xGEQRF routines, to support linear
  ;; regression work.   

  ;; Some issues exist in the LAPACK vs. LINPACK variants, hence R
  ;; uses LINPACK primarily, rather than LAPACK.  See comments in R
  ;; source for issues.  
  
  ;; LAPACK suggests to use the xGELSY driver (GE general matrix, LS
  ;; least squares, need to lookup Y intent (used to be an X alg, see
  ;; release notes).

  ;; Goal is to start from X, Y and then realize that if
  ;; Y = X \beta, then,   i.e. 8x1 = 8xp px1  + 8x1
  ;;      XtX \hat\beta = Xt Y
  ;; so that we can solve the equation  W \beta = Z   where W and Z
  ;; are known, to estimate \beta.
  (defparameter *xv*
    (make-vector
     8
     :initial-contents '((1d0 3d0 2d0 4d0 3d0 5d0 4d0 6d0))))

  (defparameter *xv+1*
    (make-matrix
     8 2
     :initial-contents '((1d0 1d0)
			 (1d0 3d0)
			 (1d0 2d0)
			 (1d0 4d0)
			 (1d0 3d0)
			 (1d0 5d0)
			 (1d0 4d0)
			 (1d0 6d0))))

  (defparameter *xm*
    (make-matrix
     2 8
     :initial-contents '((1d0 3d0 2d0 4d0 3d0 5d0 4d0 6d0)
			 (1d0 2d0 3d0 4d0 5d0 6d0 7d0 8d0))))

  (defparameter *y*
    (make-vector
     8
     :initial-contents '((1d0 2d0 3d0 4d0 5d0 6d0 7d0 8d0))))

  ;; so something like (NOTE: matrices are transposed to begin with, hence the incongruety)
  (defparameter *xtx* (m* *xv* (transpose *xv*)))
  (defparameter *xty* (m* *xv* (transpose  *y*)))
  (defparameter *rcond* 1)
  (defparameter *betahat*  (gelsy *xtx* *xty* *rcond*))
  *betahat*

#|
(#<LA-SIMPLE-VECTOR-DOUBLE (1 x 1)
 1.293103448275862>
 1)

## Test case in R:
x <- c( 1.0, 3.0, 2.0, 4.0, 3.0, 5.0, 4.0, 6.0)
y <- c( 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0)
lm (y ~ x  -1)
## => 
Call:
lm(formula = y ~ x - 1)

Coefficients:
    x  
1.293  
|#


  ;; so something like (NOTE: matrices are transposed to begin with, hence the incongruety)
  (defparameter *xtx* (m* *xv+1* (transpose *xv+1*)))
  (defparameter *xty* (m* *xv+1* (transpose  *y*)))
  (defparameter *rcond* 1)
  (defparameter *betahat*  (gelsy *xtx* *xty* *rcond*))
  *betahat*



  ;; which suggests one might do (modulo ensuring correct orientations)
  (defun lm (x y)
    (let ((betahat (gelsy (m* x (transpose x))
			  (m* x (transpose y)))))
      
      (values betahat (sebetahat betahat x y))))
  ;; to get a results list containing betahat and SEs

  (values-list '(1 3 4))
  )