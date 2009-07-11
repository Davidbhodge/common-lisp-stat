;;; -*- mode: lisp -*-
;;;
;;; Copyright (c) 2008--, by A.J. Rossini <blindglobe@gmail.com>
;;; See COPYRIGHT file for any additional restrictions (BSD license).
;;; Since 1991, ANSI was finally finished.  Modified to match ANSI
;;; Common Lisp.  

;;; This version uses LAPACK and lisp-matrix for underlying numerics.
;;; No longer contains code from XLispStat.

(in-package :lisp-stat-regression-linear)

;; The general strategy behind the fitting of models using prototypes
;; is that we need to think about want the actual fits are, and then
;; the fits can be used to recompute as components are changes.  One
;; catch here is that we'd like some notion of trace-ability, in
;; particular, there is not necessarily a fixed way to take care of the
;; audit trail.  save-and-die might be a means of recording the final
;; approach, but we are challenged by the problem of using advice and
;; other such features to capture stages and steps that are considered
;; along the goals of estimating a model.

;; In migrating the thought process to R, we use more of a cross
;; between the S3 and prototype approaches, but some of the thinking
;; is CLOSy.

;; statistical-model shuld contain some of the ingredients for
;; traceability and embodiment of statistical characteristics.

(defclass regression-model-class () ; (statistical-model)
  ((dependent-response
    :initform nil
    :initarg  :y
    :accessor dependent-response
    :type     vector-like
    :documentation "univariate responses/dependent var.")
   (predictor-design
    :initform nil
    :initarg  :x
    :accessor design-matrix
    :type matrix-like
    :documentation "design/data matrix, complete.  when interceptp T,
    first column is intercept (ones), and hence special.")
   (interceptp
    :initform nil
    :initarg :interceptp
    :accessor interceptp
    :type boolean
    :documentation "special indicator of first column status.")

   ;; Metadata
   (covariate-names
    :initform nil
    :initarg :covariate-names
    :accessor covariate-names
    :type list
    :documentation "List of strings representing covariate names.
   Might include symbols at some point")
   (response-name
    :initform nil
    :initarg :response-name
    :accessor response-name
    :type list)
   (case-labels
    :initform nil
    :initarg :case-labels
    :accessor case-labels
    :type list)
   (doc-string
    :initform "no doc"
    :initarg :docs
    :accessor doc-string
    :type string))
  (:documentation "Normal Linear Regression Model with CLOS."))

(defclass regression-model-fit-class ()
  ((data-model 
    :initform nil
    :initarg  :data-model
    :accessor data-model
    :type     regression-model-class
    :documentation "data/design")
   (needs-computing
    :initform T
    :initarg  :needs-computing
    :accessor needs-computing
    :documentation "ensure that this is set to TRUE when numerically
  dependent pieces are modified (not metadata, for example).  Check
  before access of results and printouts, so as to recompute if
  necessary.")
   (included
    :initform nil
    :initarg  :included
    :accessor included
    :type     matrix-like)
   (weights
    :initform nil
    :initarg  :weights
    :accessor weights
    :type     matrix-like)
   (weights-types
    :initform nil
    :initarg  :weight-types
    :accessor weight-types
    :type     matrix-like)

   ;; computational artifacts for storage; when NEEDS-COMPUTING is
   ;; NIL, these are up-to-date.
   (basis
    :initform nil
    :accessor basis
    :type     matrix-like)
   (estimates
    :initform nil 
    :initarg  :estimates
    :accessor estimates
    :type     vector-like)
   (estimates-covariance-matrix
    :initform nil
    :initarg  :estimates-covariance-matrix
    :accessor covariance-matrix
    :type     matrix-like)
   (total-sum-of-squares
    :initform 0d0
    :accessor tss
    :type number)
   (residual-sum-of-squares
    :initform 0d0
    :accessor rss
    :type number)
   (doc-string
    :initform "No info given."
    :initarg :doc
    :accessor doc-string
    :type string))
  (:documentation "Normal Linear Regression Model _FIT_ through CLOS."))

;;;;;;;; Helper functions

;;(declaim (ftype (function (matrix-like) matrix-like) xtxinv))

(defun xtxinv (x)
  "In: X      Out: (XtX)^-1 

X is NxP, resulting in PxP.  Represents Var[\hat\beta], the varest for
\hat \beta from Y = X \beta + \eps.  Done by Cholesky decomposition,
with LAPACK's dpotri routine, factorizing with dpotrf.

<example>
  (let ((m1 (rand 7 5)))
     (xtxinv m1))
</example>"
  (check-type x matrix-like)
  (minv-cholesky (m* (transpose x) x)))

#|
  (let ((myx (if intercept
		  (bind2 (ones (matrix-dimension x 0) 1)
			 x :by :column)
		  x)))
|#

;; might add args: (method 'gelsy), or do we want to put a more
;; general front end, linear-least-square, across the range of
;; LAPACK solvers? 
(defun lm (x y &key (intercept T) rcond)
  "fit the linear model:
           y = x \beta + e 

and estimate \beta.  X,Y should be in cases-by-vars form, i.e. X
should be n x p, Y should be n x 1.  Returns estimates, n and p.
Probably should return a form providing the call, as well.

R's lm object returns: coefficients, residuals, effects, rank, fitted,
qr-results for numerical considerations, DF_resid.  Need to
encapsulate into a class or struct."
  (check-type x matrix-like)
  (check-type y vector-like) ; vector-like might be too strict?
  (assert (= (nrows y) (nrows x)) ; same number of obsns/cases
	  (x y) "Can not multiply x:~S by y:~S" x y)
  (let ((x1 (if intercept
		(bind2 (ones (matrix-dimension x 0) 1)
		       x :by :column)
		x)))
    (let ((betahat (gelsy (m* (transpose x1) x1)
			  (m* (transpose x1) y)
			  (if rcond rcond
			      (* (coerce (expt 2 -52) 'double-float)
				 (max (nrows x1)
				      (ncols y))))))
	  (betahat1 (gelsy x1
			   y
			   (if rcond rcond
			       (* (coerce (expt 2 -52) 'double-float)
				  (max (nrows x1)
				       (ncols y)))))))
      (format t "")
      (list betahat  ; LA-SIMPLE-VECTOR-DOUBLE
	    betahat1 ; LA-SLICE-VECVIEW-DOUBLE
	    (xtxinv x1); (sebetahat betahat x y) ; TODO: write me!
	    (nrows x)  ; surrogate for n
	    (ncols x1) ; surrogate for p
	    (v- (first betahat) (first betahat1)) ))))

(defun regression-model
    (x y &key  (intercept T)
     (predictor-names nil) (response-name nil) (case-labels nil)
     (doc "Undocumented Regression Model Instance"))
  "Args: (x y &key (intercept T) (print T) (weights nil)
          included predictor-names response-name case-labels)
X           - list of independent variables or X matrix
Y           - dependent variable.
INTERCEPT   - T to include (default), NIL for no intercept
PRINT       - if not NIL print summary information
WEIGHTS     - if supplied should be the same length as Y; error
              variances are  
              assumed to be inversely proportional to WEIGHTS
PREDICTOR-NAMES, RESPONSE-NAME, CASE-LABELS
            - sequences of strings or symbols.
INCLUDED    - if supplied, should be length Y or 1, with
 	      elements nil to skip or T to include for computing estimates
              (always included in residual analysis).
Returns a regression model object."
  (check-type x matrix-like)
  (check-type y vector-like)
  (let ((newmodel
	 (make-instance 'regression-model-class
			:y y
			:x x
			:interceptp intercept
			:case-labels case-labels
			:covariate-names predictor-names
			:response-name  response-name
			:docs doc )))
    newmodel))

(defun fit-model (model &key (included T) (wgts nil) (docs "No Docs"))
  (let ((result (make-instance 'regression-model-fit-class
		 :data-model model
		 :needs-computing T
		 :included included
		 :weights wgts
		 :estimates (first (lm (design-matrix model)
				       (dependent-response model)
				       :intercept (interceptp model)))
		 :estimates-covariance-matrix
		    (xtxinv (design-matrix model))
		 :doc docs)))
    result))

(defmethod print-object ((obj regression-model-fit-class) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "Estimates: ~%~A~%" (estimates obj))
    (format stream "Covariance: ~%~A~%" (covariance-matrix obj))
    (format stream "Doc: ~%~A~%" (doc-string obj))))

(defmethod print-object ((obj regression-model-class) stream)
  "Need better formatting and output -- clearly this is a WRONG EXAMPLE."
  (print-unreadable-object (obj stream :type t)
    (format stream "Response: ~%~A~%" (dependent-response obj))
    (format stream "Design: ~%~A~%" (design-matrix obj))
    (format stream "Covariates: ~%~A~%" (covariate-names obj))
    (format stream "Doc: ~%~A~%" (doc-string obj))))

;;; Computing and Display Methods

;; [X|Y]t [X|Y]
;; = XtX  XtY
;;   YtX  YtY
;; so with (= (dim X) (list n p))
;; we end up with p x p   p x 1
;;                1 x p   1 x 1
;;
;; and this can be implemented by
#|
  (setf XY (bind2 X Y :by :row))
  (setf XYtXY (m* (transpose XY) XY))
|#
;; which is too procedural.  Sigh, I meant
#|
  (setf XYtXY (let ((XY (bind2 X Y :by :row)))
                 (m*  (transpose XY) XY)))
|#
;; which at least looks lispy.

