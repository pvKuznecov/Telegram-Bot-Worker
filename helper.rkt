#lang racket
(require racket/date json)
(provide getNowDate show-log* typeValue? print_f print_f_t)

(define (getNowDate) (begin (date-display-format 'iso-8601) (date->string(current-date))))
(define (show-log* chatId matcherId)
	(date-display-format 'iso-8601)
	(printf "\n||~a [~a]SCN:: ~a\n" (date->string (current-date) #t) chatId matcherId))

; string name type of value
(define (typeValue? value)
	(cond
		[(string? value) "string"]
		[(number? value) "number"]
		[(symbol? value) "symbol"]
		[(list? value) "list"]
		[(hash? value) "hash"]
		[(cons? value) "cons"]
		[(or (equal? value #f) (equal? value #t)) "boolean"]
		[else "unknown"]))

; show logs
(define (print_f nameText value)
	(printf "\n~a:\n" nameText)
  	(pretty-print value))

; show logs (with type of value)
(define (print_f_t nameText value)
	(printf "\n~a[type:: ~a]:\n" nameText (typeValue? value))
  	(pretty-print value))
