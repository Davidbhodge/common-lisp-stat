;;; Basic initialization for LispStat
;;; Time-stamp: <2007-06-25 19:58:14 ROSSIAN6>
;;; Created: <2007-05-30 17:09:47 ROSSIAN6>

;; Goal:
;; 
;; Associate ASDF directory for loading.
;; Make sure that we have initialized any locally defined global variables
;; ensure appropriate tools are linked in for loading.
;; i.e. if features don't exist, load from particular locations in
;; this directory structure.


;; What package should we be in?  Contaminating cl-user is probably EVIL.

;; Need to replace this with some form of self-referential structure. 

;; Add the critical paths to the ASDF facility and set up other
;; things; currently this will not do the other setups.

(progn
  
  (defvar *lispstat-home-dir*
    ;; #p"/cygdrive/c/local/sandbox/Lisp/CommonLispStat/"w
    #p"/home/tony/sandbox/CommonLispStat.git/"
    "Value considered \"home\" for our data")
  
  
  (defmacro ls-dir (root-str)
    `(pathname (concatenate 'string (namestring *lispstat-home-dir*) ,root-str)))
  
  (defmacro ls-defdir (target-dir-var  root-str)
    `(defvar ,target-dir-var (ls-dir ,root-str)))
  
  ;;(macroexpand '(ls-defdir *lispstat-asdf-dir* "ASDF"))
  ;;(macroexpand-1 '(ls-defdir *lispstat-asdf-dir* "ASDF"))
  ;;(macroexpand-1 '(ls-dir "ASDF"))
  
  (ls-defdir *lispstat-asdf-dir* "ASDF/")
  (ls-defdir *lispstat-data-dir* "data/")
  (ls-defdir *lispstat-external-dir* "external/")
  (ls-defdir *lispstat-examples-dir* "examples/")
  
  ;; Load ASDF if it isn't loaded
  #-asdf(load (pathname (concatenate 'string (namestring *lispstat-external-dir*) "asdf")))
  
  ;; (pushnew #p"C:/Lisp/libs/" asdf-util:*source-dirs* :test #'equal)
  (pushnew  *lispstat-asdf-dir*  asdf:*central-registry*))

;; Load the packages that we will need.
(progn 

  ;; FFI
  (asdf:oos 'asdf:load-op :cffi)

  ;; Unit Testing 
  (asdf:oos 'asdf:load-op :lift)

  ;;(asdf:oos 'asdf:load-op :lisp-unit)

  (asdf:oos 'asdf:load-op :clem)
  #+nil(asdf:oos 'asdf:load-op :clem-test)
  #+nil(asdf:oos 'asdf:load-op :clem-benchmark)

  ;; Constraint System
  ;;(asdf:oos 'asdf:load-op :cells)

  ;; Finally...
  #+nil(asdf:oos 'asdf:load-op :lispstat)
  )

#+nil(progn
       (asdf:oos 'asdf:compile-op :cffi)
       (asdf:oos 'asdf:compile-op :lisp-unit)
       (asdf:oos 'asdf:compile-op :lift)
       (asdf:oos 'asdf:compile-op :rclg)
       (asdf:oos 'asdf:compile-op :cl-cairo2)
       (asdf:oos 'asdf:load-op :celtk))
