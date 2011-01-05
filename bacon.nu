(load "bacon_summary")
(load "bacon_requirement")
(load "bacon_context")
(load "bacon_should")
(load "bacon_macros")

(class Bacon is NSObject
  (ivars (id) contexts)

  (+ sharedInstance is $BaconSharedInstance)

  (- init is
    (super init)
    (set @contexts (NSMutableArray array))
    self
  )

  (- addContext:(id)context is
    (@contexts << context)
    ;(puts (@contexts description))
  )

  (- (id) run is
    (@contexts each:(do (context) (context run)))
  )
)
(set $BaconSharedInstance ((Bacon alloc) init))

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

(class NSObject
  (- (id) instanceEval:(id)block is
    (set c (send block context))
    (send block evalWithArguments:nil context:c self:self)
  )

  (- (id) should is ((BaconShould alloc) initWithObject:self))
  (- (id) should:(id)block is (((BaconShould alloc) initWithObject:self) satisfy:nil block:block))
)
