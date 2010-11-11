(class Context is NSObject
  (ivar (id) name
        (id) block)
  
  (- (id) initWithName:(id)name block:(id)block is
    (self init)
    (set @name name)
    (set @block block)
    self)
  
  (- run is
    (puts @name)
    (@block each: (do (x) (eval x))))
  
  (- requirement:(id)description block:(id)block is
    (puts description)
    (block call))
)

(class Should is NSObject
  (ivar (id) object)
  
  (- (id) initWithObject:(id)object is
    (self init) ;; TODO check if it's nil
    ;; (puts (object description))
    (set @object object)
    self)
  
  (- (id) equal:(id)value is
    (eq @object value))
  
  ; (- (id) ==:(id)value is
  ;   (eq @object value))
)

;; STEP 1
; (set x ((Should alloc) initWithObject:"foo"))
; (puts (x equal:"foo"))
; (puts (x == "foo"))

;; STEP 2
; (set context ((Context alloc) initWithName:"An instance of Should" block:(do (*args)
;   (set x ((Should alloc) initWithObject:"foo"))
;   (puts (x equal:"foo"))
; )))
; (context run)

;; STEP 3
; TODO should probably become a macro
(function describe (name block) (((Context alloc) initWithName:name block:block) run))

; (describe "An instance of Should" (do (*args)
;   (set x ((Should alloc) initWithObject:"foo"))
;   (puts (x equal:"foo"))
; ))

;; STEP 4
(macro-0 it
  (set __description (eval (car margs)))
  (set __block (eval (cdr margs)))
  (self requirement:__description block:__block)
)

(describe "An instance of Should" `(
  (it "compares for equality" (do (*args)
    (set x ((Should alloc) initWithObject:"foo"))
    (puts (x equal:"foo"))
    (puts (self description))
  ))
))