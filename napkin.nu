(class Context is NSObject
  (ivar (id) name
        (id) requirements)
  
  (- (id) initWithName:(id)name requirements:(id)requirements is
    (self init)
    (set @name name)
    (set @requirements requirements)
    self
  )
  
  (- (id) run is
    (puts @name)
    (@requirements each: (do (x) (eval x)))
  )
  
  (- (id) requirement:(id)description block:(id)block is
    (puts description)
    (try
      (eval block)
      (catch (e)
        (puts (e reason))
      )
    )
  )
)

; TODO How should I subclass NSException?
(class BaconError is NSObject
  (ivar (id) description)
  
  (- (id) initWithDescription:(id)description is
    (self init)
    (set @description description)
    self
  )
  
  (- (id) name is "BaconError")
  (- (id) reason is @description)
)

(class Should is NSObject
  (ivar (id) object)
  
  (- (id) initWithObject:(id)object is
    (self init) ;; TODO check if it's nil
    ;; (puts (object description))
    (set @object object)
    self
  )
  
  (- (id) equal:(id)value is
    (unless (eq @object value)
      (set d "`#{@object}' does not equal `#{value}'")
      (throw ((BaconError alloc) initWithDescription:d))
    )
  )
  
  ; (- (id) ==:(id)value is
  ;   (eq @object value))
)

; TODO does a macro have an advantage here?
(function describe (name requirements) (((Context alloc) initWithName:name requirements:requirements) run))

(macro-0 it
  (set __description (car margs))
  (set __block (cdr margs))
  (self requirement:__description block:__block)
)

(describe "An instance of Should" `(
  (it "raises an exception if the assertion fails" (do ()
    (set x ((Should alloc) initWithObject:"foo"))
    (puts (x equal:"bar"))
  ))
  
  (it "compares for equality" (do ()
    (set x ((Should alloc) initWithObject:"foo"))
    (puts (x equal:"foo"))
  ))
))