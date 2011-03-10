(load "bacon_summary")
(load "bacon_specification")
(load "bacon_context")
(load "bacon_should")
(load "bacon_macros")

(class Bacon is NSObject
  (ivars (id) contexts
         (id) currentContextIndex)

  (+ sharedInstance is $BaconSharedInstance)

  (- init is
    (super init)
    (set @contexts (NSMutableArray array))
    (set @currentContextIndex 0)
    self
  )

  (- addContext:(id)context is
    (@contexts addObject:context)
  )

  (- (id) run is
    (if (> (@contexts count) 0)
      (then
        (set context (self currentContext))
        (context setDelegate:self)
        (context performSelector:"run" withObject:nil afterDelay:0)
        ; Ensure the runloop has started
        (try
          ((NSApplication sharedApplication) run)
          (catch (e))
        )
      )
      (else
        ; DONE
        (self contextDidFinish:nil)
      )
    )
  )

  (- (id) currentContext is
    (@contexts objectAtIndex:@currentContextIndex)
  )

  (- (id) contextDidFinish:(id)context is
    (if (< (+ @currentContextIndex 1) (@contexts count))
      (then
        (set @currentContextIndex (+ @currentContextIndex 1))
        (self run)
      )
      (else
        ; DONE!
        ($BaconSummary print)
        (exit (+ ($BaconSummary failures) ($BaconSummary errors)))
      )
    )
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

  (- (id) stringValue is
    (set description (self description))
    (set className ((self class) name))
    (if (description hasPrefix:"<#{className}")
      (then description)
      (else "#{className}: #{description}")
    )
  )

  (- (id) should is ((BaconShould alloc) initWithObject:self))
  (- (id) should:(id)block is (((BaconShould alloc) initWithObject:self) satisfy:nil block:block))
)
