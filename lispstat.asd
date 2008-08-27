;;  -*- mode: lisp -*-
;;; Copyright (c) 2005--2008, by AJ Rossini <blindglobe@gmail.com>
;;; ASDF packaging for CommonLisp Stat
;;; License: BSD, see the top level directory file LICENSE for details.
;;; Time-stamp: <2008-08-27 21:16:50 tony>
;;; Created:    <2005-05-30 17:09:47 blindglobe>

;; What package should we be in?  Contaminating cl-user is probably EVIL.
(in-package :cl-user)


(defvar *lispstat-home-dir*
  (directory-namestring
   (truename (asdf:system-definition-pathname :lispstat)))
  "Value considered \"home\" for our data")

#|
  (setf *lispstat-home-dir*
      (directory-namestring (truename (asdf:system-definition-pathname
				       :lispstat))))
|#

(macrolet ((ls-dir (root-str)
	     `(pathname (concatenate 'string
				     (namestring *lispstat-home-dir*) ,root-str)))

	   (ls-defdir (target-dir-var  root-str)
	     `(defvar ,target-dir-var (ls-dir ,root-str))))

  ;;(macroexpand '(ls-defdir *lispstat-asdf-dir* "ASDF"))
  ;;(macroexpand-1 '(ls-defdir *lispstat-asdf-dir* "ASDF"))
  ;;(macroexpand-1 '(ls-dir "ASDF"))

  (ls-defdir *lispstat-asdf-dir* "ASDF/")
  (ls-defdir *lispstat-data-dir* "data/")
  (ls-defdir *lispstat-external-dir* "external/")
  (ls-defdir *lispstat-examples-dir* "examples/"))

(pushnew *lispstat-asdf-dir* asdf:*central-registry*)
;; (pushnew #p"C:/Lisp/libs/" asdf-util:*source-dirs* :test #'equal)

;;; back to our regularly scheduled work...
;;; We should not need these, I think, but?
;; (asdf:oos 'asdf:compile-op :cffi)            ;; FFI
;; (asdf:oos 'asdf:compile-op :lift)            ;; Unit Testing 
;; (asdf:oos 'asdf:load-op :cffi)            ;; FFI
;; (asdf:oos 'asdf:load-op :lift)            ;; Unit Testing 

;;; MAJOR HACK, FIXME!
;;(load "/media/disk/Desktop/sandbox/matlisp.git/start.lisp")

(in-package :cl-user)

(defpackage #:lispstat-system
    (:use :common-lisp :asdf))

(in-package #:lispstat-system)

;;; To avoid renaming everything from *.lsp to *.lisp...
;;; borrowed from Cyrus Harmon's work, for example for the ch-util.
;;; NOT secure against serving multiple architectures/hardwares from
;;; the same file system (i.e. PPC and x86 would not be
;;; differentiated). 

(defclass lispstat-lsp-source-file (cl-source-file) ())
(defparameter *fasl-directory*
   (make-pathname :directory '(:relative
			       #+sbcl "sbcl-fasl"
			       #+openmcl "openmcl-fasl"
			       #+cmu "cmucl-fasl"
			       #+clisp "clisp-fasl"
			       #-(or sbcl openmcl clisp cmucl) "fasl"
			       )))


;;; Handle Luke's *.lsp suffix
(defmethod source-file-type ((c lispstat-lsp-source-file) (s module)) "lsp")
(defmethod asdf::output-files :around ((operation compile-op)
				       (c lispstat-lsp-source-file))
  (list (merge-pathnames *fasl-directory*
			 (compile-file-pathname (component-pathname c)))))
;;; again, thanks to Cyrus for saving me time...


(defsystem "lispstat"
  :version #.(with-open-file
                 (vers (merge-pathnames "version.lisp-expr" *load-truename*))
               (read vers))
  :author "A.J. Rossini <blindglobe@gmail.com>"
  :license "BSD"
  :description "CommonLispStat (CLS): A System for Statistical Computing with Common Lisp;
based on CLS alpha1 by Luke Tierney <luke@stat.uiowa.edu> (originally written when Luke was at CMU, apparently).
Last touched 1991, then in 2005--2008."
  :serial t
  :depends-on (:cffi  :lift) ;; need a matrix library
  :components ((:static-file "version" :pathname #p"version.lisp-expr")
	       (:static-file "LICENSE")
	       (:static-file "README")

	       (:module "proto-objects"
			:pathname "src/objsys/"
			:components
			((:lispstat-lsp-source-file "lsobjects")))

	       (:module "lispstat-core"
			:pathname "src/basics/"
			:serial t
			:depends-on ("proto-objects")
			:components
			((:lispstat-lsp-source-file "defsys")
			 (:lispstat-lsp-source-file "lstypes")
			 (:lispstat-lsp-source-file "lsfloat")
			 
			 (:lispstat-lsp-source-file "compound")
			 (:lispstat-lsp-source-file "lsmacros" 
						    :depends-on ("compound"))
			 
			 (:lispstat-lsp-source-file "lsmath"
						    :depends-on ("compound"
								 "lsmacros"
								 "lsfloat"))))

	       (:module "numerics-internal"
			:pathname "src/numerics/"
			:depends-on ("proto-objects" "lispstat-core")
			:components
			((:lispstat-lsp-source-file "cffiglue")
			 (:lispstat-lsp-source-file "dists"
						    :depends-on ("cffiglue"))
			 (:lispstat-lsp-source-file "matrices"
						    :depends-on ("cffiglue"))
			 (:lispstat-lsp-source-file "ladata"
						    :depends-on ("cffiglue"
								 "matrices"))
			 (:lispstat-lsp-source-file "linalg"
						    :depends-on ("cffiglue"
								 "matrices"
								 "ladata"))))

	       (:module "stat-data"
			:pathname "src/data/"
			:depends-on ("proto-objects"
				     "lispstat-core"
				     "numerics-internal")
			:components
			(;; (:file "data-clos")
			 (:file "data")))

	       ;; there is a circ reference which we need to solve.
	       (:lispstat-lsp-source-file "lsbasics"
					  :depends-on ("proto-objects"
						       "lispstat-core"
						       "numerics-internal" ))

	       (:lispstat-lsp-source-file "statistics"
					  :depends-on ("proto-objects"
						       "lispstat-core"
						       "numerics-internal"
						       "stat-data"
						       "lsbasics"))

	       (:file "optimize" :depends-on ("proto-objects"
					      "lispstat-core"
					      "numerics-internal"))
	       
	       ;; Applications
	       (:lispstat-lsp-source-file "regression"
					  :depends-on ("proto-objects"
						       "lispstat-core"
						       "numerics-internal" 
						       "lsbasics"
						       "statistics"))
;	       (:lispstat-lsp-source-file "nonlin"
;					  :depends-on ("regression"))

;	       (:lispstat-lsp-source-file "bayes"
;					  :depends-on ("proto-objects"
;						       "lsmath"
;						       "dists"))

	       (:module
		"lisp-stat-one"
		:pathname "src/"
		:depends-on  ("proto-objects"
			      "lispstat-core"
			      "numerics-internal" 
			      "lsbasics"
			      "stat-data"
			      "statistics"
			      "regression")
		:components ((:file "ls-user")))

	       (:module
		 "lisp-stat-unittest"
		 :depends-on ( "lisp-stat-one" ) ;; shouldn't need :lift!
		 :pathname "src/unittests/"
		 :components ((:file "unittests")
			      (:file "unittests-lstypes")
			      ;;  "unittests-arrays.lisp"
			      ;;  "unittests-data-clos.lisp"
			      ;;  "unittests-proto.lisp"
			      ;;  "unittests-regression.lisp"
			      ))))
