#lang racket
(require json net/http-client
		 "helper.rkt" "config.rkt")
(provide apiReq-get apiReq-post apiReq-sendMsg apiReq-botInfo api-get-updates make-get-updates-with-offset
		 apiReq-answerMsg-full)

(define b-token (get-from-config "tlg/token"))
(define b-uri (format "/bot~a/" b-token))
(define tlg-host (get-from-config "tlg/apihost"))

(define (mkReq-options options) (jsexpr->string options))

(define (apiReq method action [options '()])
	(define-values (status header json-encoded-response)
		(http-sendrecv tlg-host
      			   	   (format "~a~a" b-uri action)
      			   	   #:ssl? #t
      			   	   #:data (mkReq-options options)
      			   	   #:headers (list "Content-Type: application/json")))
	(let ([response (read-json json-encoded-response)])
    	(cond [(hash-ref response 'ok) (cons 'ok  (hash-ref response 'result))]
    	  	  [else (cons 'err (cons (hash-ref response 'description) (hash-ref response 'error_code)))])))

(define (apiReq-get action [options (list)]) (apiReq "GET" action options))
(define (apiReq-post action [options (list)]) (apiReq "POST" action options))

; chk connect to tlg api (get bot info)
(define (apiReq-botInfo) (apiReq-get "getMe"))

(define (mkMsgHash chatId text)
	(hash
		'chat_id chatId
		'text text
  		'parse_mode "HTML"))

; send simple text msg
(define (apiReq-sendMsg chatId text)
  (let* ([msgHash (mkMsgHash chatId text)]
         [response (apiReq-post "sendMessage" msgHash)])
    response))

; send msg with optional keys
(define (apiReq-sendMsg-full chatId text keys)
	(let* ([msgHash (hash-set* (mkMsgHash chatId text) 'reply_markup keys)]
		   [response (apiReq-post "sendMessage" msgHash)]
		   [result (pretty-print msgHash)])
		response))

(define (apiReq-answerMsg-full msg text keys)
	(apiReq-sendMsg-full (hash-ref (hash-ref msg 'chat) 'id) text keys))

(define (api-get-updates (offset 0) (limit 100) (timeout 0) (allowed-updates '()))
	(let* ([options (hash 'offset offset
                          'limit limit
                          'timeout timeout
                          'allowed-updates allowed-updates)]
           [response (apiReq-get "getUpdates" options)])
		(values
			(car response)
      		(cdr response)
      		(make-get-updates-with-offset
      			(cond [(empty? (cdr response)) offset]
              	  	  [(eq? 'ok (car response)) (+ 1 (hash-ref (last (cdr response)) 'update_id))]
              	  	  [(eq? 'err (car response)) offset])))))

(define (make-get-updates-with-offset offset [default-limit 100] [default-timeout 0] [default-allowed-updates (list)])
	(lambda ([limit default-limit]
			 [timeout default-timeout]
			 [allowed-updates default-allowed-updates])
		(api-get-updates offset limit timeout allowed-updates)))