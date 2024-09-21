#lang racket
(require net/http-client json yaml racket/hash xml racket/date
		 "helper.rkt" "config.rkt" "telegram_api.rkt")

(define-namespace-anchor a)
(define ns (namespace-anchor->namespace a))

(define (search_cont) #f)
(define (search_stop) #t)
(define (h-merge a b) (hash-union a b #:combine/key (lambda (k v1 v2) v2)))

(define b_name (get-from-config "tlg/name"))
(define scnPathPref (get-from-config "scenario/pathpref"))
(define authPathPref (get-from-config "auth/pathpref"))
(define sessionPathPref (get-from-config "session/pathpref"))
(define scnPathStr (format "~a~a/" scnPathPref b_name))
(define authPathStr (format "~a~a/" authPathPref b_name))
(define sessionPathStr (format "~a~a/" sessionPathPref b_name))

; automatically creates a directory for scn, auth and session
(let ([chkDirList (list scnPathStr authPathStr sessionPathStr)])
	(map
		(lambda (dpVal)
			(cond
				[(not (directory-exists? dpVal))
					(make-directory dpVal)
					(printf "\n||CHKBOT_DIRECTORY:: Auto-create '~a' directory" dpVal)
				]
				[else (printf "\n||CHKBOT_DIRECTORY:: '~a' is exists" dpVal)])
		) chkDirList))

(define scn-path (make-parameter scnPathStr))
(define auth-path (make-parameter authPathStr))
(define session-path (make-parameter sessionPathStr))

(define r-format ~r)
(struct ~matcher (id match-proc handle-proc))

(define matcher-raw-list
	(let ([sFileList (parameterize ([current-directory (scn-path)])
						(map
							(lambda (x)
                         		(cons x (file->string x))
                       		) (sort
                       			(filter-not
                       				(lambda (x)
                       					(or (directory-exists? x)
                       						(not (string-suffix? (path->string x) ".rkt" )))
                       				) (sequence->list (in-directory)))
                       			#:key path->string string<?)))
		  ])
		(map (lambda (x) (cons (path->string (car x)) (string-split (cdr x) ";@BODY"))) sFileList)))

(define matcher-list
	(map
		(lambda (x)
      		(~matcher (first x)
        			  (eval (call-with-input-string (format "(lambda(m text s a ucId) ~a)" (second x) ) read) ns)
        			  (eval (call-with-input-string (format "(lambda(m send new update s a ucId) ~a)" (third x)) read) ns))
      	) matcher-raw-list))

(define (send-function m)
	(λ (text [h #f])
		(cond [(and (string? text) h) (apiReq-answerMsg-full m text h)]
          	  [(string? text) (apiReq-sendMsg (hash-ref (hash-ref m 'chat (hash)) 'id) text)]
          	  [(and (symbol? text) h) (apiReq-post (symbol->string text) h)])))

(define (NEW filename)
	(λ (h [type 'session])
		(parameterize ([current-directory (match type ['auth (auth-path)]
    												  [_ (session-path)])
					   ])
			(write-to-file (jsexpr->string h) filename #:mode 'text #:exists 'replace))))

(define (UPDATE old-value filename)
	(λ (h [type 'session])
		(let ([result (h-merge old-value h)])
			(parameterize ([current-directory (match type ['permission (auth-path)]
														  [_ (session-path)])])
				(write-to-file (jsexpr->string result) filename #:mode 'text #:exists 'replace)))))

(define (handle-message m matchers)
	(define id (hash-ref (hash-ref m 'chat (hash)) 'id))
  	(define filename (format "chat_~a.json" id))
  	(define session
  		(parameterize ([current-directory (session-path)])
  			(cond [(file-exists? filename) (string->jsexpr (string->jsexpr (file->string filename)))]
  				  [else (hash)])))

	(define auth
  		(parameterize ([current-directory (auth-path)])
  			(cond [(file-exists? filename) (string->jsexpr (string->jsexpr (file->string filename)))]
  				  [else (hash)])))

	(define update
		(lambda (h [type 'session])
			(let ([result (h-merge (match type ['auth auth] [_ session]) h)])
				(match type ['auth (set! auth result)]
	        				[_ (set! session result)])
				(parameterize ([current-directory (match type ['auth (auth-path)] [_ (session-path)])])
      				(write-to-file (jsexpr->string result) filename #:mode 'text #:exists 'replace)))))

	(ormap
		(lambda (matcher)
			(and ((~matcher-match-proc matcher) m (hash-ref m 'text) session auth id)
				 (show-log* id (~matcher-id matcher))
				 ((~matcher-handle-proc matcher) m (send-function m) (NEW filename) update session auth id))
    	) matchers))

(define (sanitize-command t)
  (cond [(not t) t]
        [(regexp-match? (regexp (format "/(.*?)@~a" b_name)) t) (cadr (regexp-match #rx"/(.*?)@" t))]
        [(char=? #\/ (string-ref t 0)) (substring t 1)]
        [else t]))

(define (run-bot proc matchers)
	(define-values (status result get-updates-proc) (proc))
  	(case status
  		['err
      		(begin
      			(printf "\nERROR: [~a] ~a" (second result) (first result))
        		(sleep 10))
    	]
    	['ok
    		(map
    			(lambda (update)
	          		(let ([m (hash-ref update 'message #f)]
	                	  [c (hash-ref update 'callback_query #f)])
	          			(cond
	          				[m
	          					(handle-message
	          						(hash-set m 'text (sanitize-command (hash-ref m 'text)))
	          						matchers)
	          				]
	                  		[c
	                  			(handle-message
	                  				(hash-set* (hash-ref c 'message) 'callback_data (hash-ref c 'data)
	                  												 'callback_query_id (hash-ref c 'id))
	                  				matchers)
	                  		]
	                  		[else (printf "\nERROR:???")]))
        		) result)
    	])
  	(run-bot get-updates-proc matchers))

(run-bot (λ () (api-get-updates)) matcher-list)
