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
    (@block call))
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

; (set x ((Should alloc) initWithObject:"foo"))
; (puts (x equal:"foo"))
; (puts (x == "foo"))

(set context ((Context alloc) initWithName:"An instance of Should" block:(do (*args)
  (set x ((Should alloc) initWithObject:"foo"))
  (puts (x equal:"foo"))
)))

(context run)