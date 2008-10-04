;;; -*- mode: lisp -*-

;;; Time-stamp: <2008-10-04 14:46:52 tony>
;;; Creation:   <2008-09-08 08:06:30 tony>
;;; File:       TODO.lisp
;;; Author:     AJ Rossini <blindglobe@gmail.com>
;;; Copyright:  (c) 2007-2008, AJ Rossini <blindglobe@gmail.com>.  BSD.
;;; Purpose:    demonstrations of how one might use CLS.

;;; What is this talk of 'release'? Klingons do not make software
;;; 'releases'.  Our software 'escapes', leaving a bloody trail of
;;; designers and quality assurance people in its wake.

;;; This file contains the current challenges to solve, including a
;;; description of the setup and the work to solve....
 
;;; SET UP

(in-package :cl-user)
(asdf:oos 'asdf:load-op 'lispstat)
(in-package :ls-user)

(progn

  (def iron  (list 61 175 111 124 130 173 169 169 160 224 257 333 199))
  iron
  (def aluminum (list 13 21 24 23 64 38 33 61 39 71 112 88 54))
  aluminum
  (def absorbtion (list 4 18 14 18 26 26 21 30 28 36 65 62 40))
  absorbtion

  ;; LispStat 1 approach to data frames... (list of lists).

  (DEF DIABETES
      (QUOTE ((80 97 105 90 90 86 100 85 97 97 91 87 78 90 86 80 90 99 85 90 90 88 95 90 92 74 98 100 86 98 70 99 75 90 85 99 100 78 106 98 102 90 94 80 93 86 85 96 88 87 94 93 86 86 96 86 89 83 98 100 110 88 100 80 89 91 96 95 82 84 90 100 86 93 107 112 94 93 93 90 99 93 85 89 96 111 107 114 101 108 112 105 103 99 102 110 102 96 95 112 110 92 104 75 92 92 92 93 112 88 114 103 300 303 125 280 216 190 151 303 173 203 195 140 151 275 260 149 233 146 124 213 330 123 130 120 138 188 339 265 353 180 213 328 346)
	      (356 289 319 356 323 381 350 301 379 296 353 306 290 371 312 393 364 359 296 345 378 304 347 327 386 365 365 352 325 321 360 336 352 353 373 376 367 335 396 277 378 360 291 269 318 328 334 356 291 360 313 306 319 349 332 323 323 351 478 398 426 439 429 333 472 436 418 391 390 416 413 385 393 376 403 414 426 364 391 356 398 393 425 318 465 558 503 540 469 486 568 527 537 466 599 477 472 456 517 503 522 476 472 455 442 541 580 472 562 423 643 533 1468 1487 714 1470 1113 972 854 1364 832 967 920 613 857 1373 1133 849 1183 847 538 1001 1520 557 670 636 741 958 1354 1263 1428 923 1025 1246 1568)
	      (124 117 143 199 240 157 221 186 142 131 221 178 136 200 208 202 152 185 116 123 136 134 184 192 279 228 145 172 179 222 134 143 169 263 174 134 182 241 128 222 165 282 94 121 73 106 118 112 157 292 200 220 144 109 151 158 73 81 151 122 117 208 201 131 162 148 130 137 375 146 344 192 115 195 267 281 213 156 221 199 76 490 143 73 237 748 320 188 607 297 232 480 622 287 266 124 297 326 564 408 325 433 180 392 109 313 132 285 139 212 155 120 28 23 232 54 81 87 76 42 102 138 160 131 145 45 118 159 73 103 460 42 13 130 44 314 219 100 10 83 41 77 29 124 15) 
	      (3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 2 3 3 2 2 3 2 2 3 3 3 3 2 3 3 3 3 3 2 3 3 3 3 3 2 3 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1))))
  
  
  (DEF DLABS (QUOTE ("GLUFAST" "GLUTEST" "INSTEST" "CCLASS"))) 
  (format t "loaded data.~%")
  )  ;; eval at this point.

(defvar m nil "holding variable.")
(def m (regression-model (list iron aluminum) absorbtion :print nil))
(send m :compute)
(send m :sweep-matrix)
(format t "~%~A~%" (send m :sweep-matrix))

;;; FIXME

;; need to get multiple-linear regression working (simple linear regr
;; works). 

(send m :basis) ;; this should be positive?
(send m :coef-estimates)

(send m :display)
(def m (regression-model (bind-columns iron aluminum) absorbtion))
(send m :help)
(send m :help :display)
(send m :help :basis)

(send m :plot-residuals)
