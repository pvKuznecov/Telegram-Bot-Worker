#lang racket
(require "helper.rkt")
(provide get-from-config)

(define name_configFile "config_data.rkt")
(define cur_configFile (make-parameter name_configFile))

(printf "||CHKBOT_CONFIG:: ...\n")

(cond [(file-exists? name_configFile) (void)]
      [else (error 'config-loader "failed because ~a" (format "could not found config file (./~a)" name_configFile))])

(define-namespace-anchor dna)

(define nsa (namespace-anchor->namespace dna))
(define config (eval (call-with-input-string (file->string (cur_configFile)) read) nsa))
(define current-stage (if (getenv "CONFIG_STAGE") (getenv "CONFIG_STAGE") "defaults"))
(define (get-config [stage current-stage]) (hash-ref config stage))
(define current-config-hash (get-config))
(define (get-from-config #:failure-result [failure-result 'notset] . args)
    (let/cc
        return
        (apply
            values
  		    (map
                (lambda (arg)
                    (foldl
                        (lambda (v l)
                            (cond [(eq? 'notset failure-result) (hash-ref l v)]
  							      [else (hash-ref l v (λ() (return  failure-result)))])
  					    ) current-config-hash (string-split arg "/"))
  			    ) args))))

(let ([b_name (and current-config-hash (hash? current-config-hash) (get-from-config "tlg/name"))])
    (printf "||CHKBOT_CONFIG[~a]:: OK." (or b_name "WORKER")))
