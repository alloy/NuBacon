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

; TODO does a macro have an advantage here?
(function describe (name block) (((Context alloc) initWithName:name block:block) run))

(macro-0 it
  (set __description (eval (car margs)))
  (set __block (eval (cdr margs)))
  (self requirement:__description block:__block)
)

(describe "An instance of Should" `(
  (it "compares for equality" (do ()
    (set x ((Should alloc) initWithObject:"foo"))
    (puts (x equal:"foo"))
  ))
))