(class BaconSummary is NSObject
  (ivar (id) counters
        (id) errorLog
  )
  
  (- (id) init is
    (super init)
    (set @errorLog "")
    (set @counters (NSMutableDictionary dictionaryWithList:`("specifications" 0 "requirements" 0 "failures" 0 "errors" 0)))
    (self)
  )
  
  (- (id) specifications is
    (@counters valueForKey:"specifications")
  )
  
  (- (id) addSpecification is
    (@counters setValue:(+ (self specifications) 1) forKey:"specifications")
  )
  
  (- (id) requirements is
    (@counters valueForKey:"requirements")
  )
  
  (- (id) addRequirement is
    (@counters setValue:(+ (self requirements) 1) forKey:"requirements")
  )
  
  (- (id) failures is
    (@counters valueForKey:"failures")
  )
  
  (- (id) addFailure is
    (@counters setValue:(+ (self failures) 1) forKey:"failures")
  )
  
  (- (id) errors is
    (@counters valueForKey:"errors")
  )
  
  (- (id) addError is
    (@counters setValue:(+ (self errors) 1) forKey:"errors")
  )
  
  (- (id) addToErrorLog:(id)e context:(id)name specification:(id)description type:(id)type is
    (@errorLog appendString:"#{name} - #{description}: ")
    (if (e respondsToSelector:"reason")
      (then (@errorLog appendString:(e reason)))
      (else (@errorLog appendString:(e description)))
    )
    (@errorLog appendString:"#{type}\n")
  )
  
  (- (id) print is
    (print "\n")
    (puts @errorLog)
    (puts "#{(self specifications)} specifications (#{(self requirements)} requirements), #{(self failures)} failures, #{(self errors)} errors")
  )
)

(set $BaconSummary ((BaconSummary alloc) init))

(class BaconRequirement is NSObject
  (ivars (id) context
         (id) description
         (id) block
         (id) before
         (id) after
         (id) report)

  (- (id) initWithContext:(id)context description:(id)description block:(id)block before:(id)beforeFilters after:(id)afterFilters report:(id)report is
    (self init)
    (set @context context)
    (set @description description)
    (set @block block)
    (set @report report)
    ; create copies so that when the given arrays change later on, they don't change these
    (set @before (beforeFilters copy))
    (set @after (afterFilters copy))
    self
  )

  (- (id) runBeforeFilters is
    ((@before list) each: (do (x) (@context instanceEval:x)))
  )

  (- (id) runAfterFiltersAndThrow:(id)shouldThrow is
    (try
      ((@after list) each: (do (x) (@context instanceEval:x)))
      (catch (e)
        (if (shouldThrow) (throw e))
      )
    )
  )

  (- (id) run is
    ;(if (@report)
      ;(unless (@printedName)
        ;(set @printedName t)
        ;(puts "\n#{@name}")
      ;)
      ;($BaconSummary addSpecification)
      ;(print "- #{description}")
    ;)
    
    (set numberOfRequirementsBefore ($BaconSummary requirements))
    
    (try
      (try ; wrap before/requirement/after
        (self runBeforeFilters)
        (@context instanceEval:@block)
        (if (eq numberOfRequirementsBefore ($BaconSummary requirements))
          ; the requirement did not contain any assertions, so it flunked
          (throw ((BaconError alloc) initWithDescription:"flunked"))
        )
        (catch (e)
          ; don't allow after filters to throw, as it could result in an endless loop
          (self runAfterFiltersAndThrow:nil)
          (throw e)
        )
        ; ensure the after filters are always run, these however may throw, as we already ran the requirement
        (self runAfterFiltersAndThrow:t)
      )
      (catch (e) ; now really handle the bubbled exception
        (if (@report)
          (if (eq (e class) BaconError)
            (then
              ($BaconSummary addFailure)
              (set type " [FAILURE]")
            )
            (else
              ($BaconSummary addError)
              (set type " [ERROR]")
            )
          )
          (print type)
          ($BaconSummary addToErrorLog:e context:(@context name) specification:description type:type)
        )
      )
    )
    
    (if (@report) (print "\n"))
  )
)

(class Bacon is NSObject
  (ivars (id) contexts)

  (+ sharedInstance is $BaconSharedInstance)

  (- init is
    (super init)
    (set @contexts (NSMutableArray array))
    self
  )

  (- addContext:(id)context is
    (@contexts addObject:context)
    (puts (@contexts description))
  )
)
(set $BaconSharedInstance ((Bacon alloc) init))

(class BaconContext is NSObject
  ; use the dynamic `ivars' so the user can add ivars in before/after
  (ivars (id) name
         (id) before
         (id) after
         (id) requirements
         (id) printedName)
  
  (- (id) initWithName:(id)name requirements:(id)requirements is
    (self init)
    (set @before (NSMutableArray array))
    (set @after (NSMutableArray array))
    (set @name name)
    (set @printedName nil)
    (set @requirements requirements)
    ((Bacon sharedInstance) addContext:self)
    self
  )
  
  (- (id) childContextWithName:(id)childName requirements:(id)requirements is
    (set child ((BaconContext alloc) initWithName:"#{@name} #{childName}" requirements:requirements))
    ((@before list) each: (do (x) (child before:x)))
    ((@after list) each: (do (x) (child after:x)))
    child
  )
  
  (- (id) name is @name)
  
  (- (id) run is
    (@requirements each: (do (x) (eval x)))
  )
  
  (- (id) before:(id)block is
    (@before addObject:block)
  )
  
  (- (id) after:(id)block is
    (@after addObject:block)
  )
  
  (- (id) requirement:(id)description block:(id)block report:(id)report is
    (set requirement ((BaconRequirement alloc) initWithContext:self description:description block:block before:@before after:@after report:report))

    ; TODO move?
    (if (report)
      (unless (@printedName)
        (set @printedName t)
        (puts "\n#{@name}")
      )
      ($BaconSummary addSpecification)
      (print "- #{description}")
    )

    (requirement run)
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

(class BaconShould is NSObject
  (ivar (id) object
        (id) negated
        (id) descriptionBuffer
  )
  
  (- (id) initWithObject:(id)object is
    (self init) ;; TODO check if it's nil
    (set @object object)
    (set @negated nil)
    (set @descriptionBuffer "")
    self
  )
  
  (- (id) object is
    @object
  )
  
  (- (id) should is
    self
  )
  
  (- (id) should:(id)block is
    (self satisfy:nil block:block)
  )
  
  (- (id) not is
    (set @negated t)
    (@descriptionBuffer appendString:" not")
    self
  )
  
  (- (id) not:(id)block is
    (set @negated t)
    (@descriptionBuffer appendString:" not")
    (self satisfy:nil block:block)
  )
  
  (- (id) be is
    (@descriptionBuffer appendString:" be")
    self
  )
  
  (- (id) a is
    (@descriptionBuffer appendString:" a")
    self
  )
  
  (- (id) an is
    (@descriptionBuffer appendString:" an")
    self
  )
  
  (- (id) satisfy:(id)description block:(id)block is
    ($BaconSummary addRequirement)
    (unless description (set description "satisfy `#{block}'"))
    (set description "expected `#{@object}' to#{@descriptionBuffer} #{description}")
    (set passed (block @object))
    (if (passed)
      (then
        (if (@negated)
          (throw ((BaconError alloc) initWithDescription:description))
        )
      )
      (else
        (unless (@negated)
          (throw ((BaconError alloc) initWithDescription:description))
        )
      )
    )
  )
  
  (- (id) be:(id)value is
    (if (send value isKindOfClass:NuBlock)
      (then
        (self satisfy:"be `#{value}'" block:value)
      )
      (else
        (self satisfy:"be `#{value}'" block:(do (object)
          (eq object value)
        ))
      )
    )
  )
  
  (- (id) a:(id)value is
    (if (send value isKindOfClass:NuBlock)
      (then
        (self satisfy:"a `#{value}'" block:value)
      )
      (else
        (self satisfy:"a `#{value}'" block:(do (object)
          (eq object value)
        ))
      )
    )
  )
  
  (- (id) equal:(id)value is
    (self satisfy:"equal `#{value}'" block:(do (object)
      (eq object value)
    ))
  )
  
  (- (id) closeTo:(id)otherValue is
    (self closeTo:otherValue delta:0.00001)
  )
  
  (- (id) closeTo:(id)otherValue delta:(id)delta is
    (if (eq (otherValue class) NuCell)
      (then
        (set otherValues (otherValue array))
        (self satisfy:"close to `#{otherValue}'" block:(do (values)
          (set result t)
          (values eachWithIndex:(do (value index)
            (set otherValue (otherValues objectAtIndex:index))
            (set result (and result (and (>= otherValue (- value delta)) (<= otherValue (+ value delta)))))
          ))
          result
        ))
      )
      (else
        (self satisfy:"close to `#{otherValue}'" block:(do (value)
          (and (>= otherValue (- value delta)) (<= otherValue (+ value delta)))
        ))
      )
    )
  )
  
  (- (id) match:(id)regexp is
    (self satisfy:"match /#{(regexp pattern)}/" block:(do (string)
      (regexp findInString:string)
    ))
  )
  
  (- (id) change:(id)valueBlock by:(id)delta is
    (self satisfy:"change `#{(send valueBlock body)}' by `#{delta}'" block:(do (changeBlock)
      (set before (call valueBlock))
      (call changeBlock)
      (eq (+ before delta) (call valueBlock))
    ))
  )
  
  (- (id) change:(id)valueBlock is
    (self satisfy:"change `#{(send valueBlock body)}'" block:(do (changeBlock)
      (set before (call valueBlock))
      (call changeBlock)
      (not (eq before (call valueBlock)))
    ))
  )
  
  (- (id) raise is
    (set result nil)
    (self satisfy:"raise any exception" block:(do (block)
      (try
        (call block)
        (catch (e)
          (set result e)
          t
        )
        nil
      )
    ))
    result
  )
  
  (- (id) raise:(id)exceptionName is
    (set result nil)
    (self satisfy:"raise an exception of type `#{exceptionName}'" block:(do (block)
      (try
        (call block)
        (catch (e)
          (set result e)
          (eq (e name) exceptionName)
        )
      )
    ))
    result
  )
  
  (- (id) handleUnknownMessage:(id)methodName withContext:(id)context is
    (set name ((first methodName) stringValue))
    (set args (cdr methodName))
    (set description name)
    (if (args) (then (set description "#{description}#{args}")))
    (if (@object respondsToSelector:name)
      (then
        ; forward the message as-is
        (self satisfy:description block:(do (object)
          (object sendMessage:methodName withContext:context)
        ))
      )
      (else
        (set predicate "is#{((name substringToIndex:1) uppercaseString)}#{(name substringFromIndex:1)}")
        (if (@object respondsToSelector:predicate)
          (then
            ; forward the predicate version of the message with the args
            (self satisfy:description block:(do (object)
              (set symbol ((NuSymbolTable sharedSymbolTable) symbolWithString:predicate))
              (sendMessageWithList object (append (list symbol) (cdr methodName)))
            ))
          )
          (else
            (set parts ((regex "([A-Z][a-z]*)") splitString:name))
            (set firstPart (parts objectAtIndex:0))
            (set firstPart (firstPart stringByAppendingString:"s"))
            (parts replaceObjectAtIndex:0 withObject:firstPart)
            (set thirdPersonForm (parts componentsJoinedByString:""))
            (if (@object respondsToSelector:thirdPersonForm)
              (then
                ; example: respondsToSelector: is matched as respondToSelector:
                (self satisfy:description block:(do (object)
                  (set symbol ((NuSymbolTable sharedSymbolTable) symbolWithString:thirdPersonForm))
                  (sendMessageWithList object (append (list symbol) (cdr methodName)))
                ))
              )
              (else
                ; the object does not respond to any of the messages
                (super handleUnknownMessage:methodName withContext:context)
              )
            )
          )
        )
      )
    )
  )
)

(class NSObject
  (- (id) instanceEval:(id)block is
    (set c (send block context))
    (send block evalWithArguments:nil context:c self:self)
  )

  (- (id) should is ((BaconShould alloc) initWithObject:self))
  (- (id) should:(id)block is (((BaconShould alloc) initWithObject:self) satisfy:nil block:block))
)

(macro -> (blockBody *extraMessages)
  (if (> (*extraMessages count) 0)
    (then
      `(~ (send (do () ,blockBody) should) ,@*extraMessages)
    )
    (else
      `(send (do () ,blockBody) should)
    )
  )
)

(macro sendMessageWithList (object *body)
  (set __body (eval *body))
  (if (not (__body isKindOfClass:NuCell))
    (set __body (list __body))
  )
  `(,object ,@__body)
)

(macro ~ (*objectAndMessages)
  (set __object (eval (car *objectAndMessages)))
  (set __messages (cdr *objectAndMessages))

  (set __messagesWithoutArgs (NSMutableArray array))
  (set __lastMessageWithArgs nil)

  (while (> (__messages count) 0)
    (set __message (car __messages))
    (if (and (__message isKindOfClass:NuSymbol) ((__message stringValue) hasSuffix:":"))
      (then
        ; once we find the first NuSymbol that ends with a colon, i.e. part of a selector with args,
        ; then we take it and the rest as the last message
        (set __lastMessageWithArgs __messages)
        (set __messages `())
      )
      (else
        ; this is a selector without args, so remove it from the messages list and continue
        (__messagesWithoutArgs << __message)
        (set __messages (cdr __messages))
      )
    )
  )

  ; first dispatch all messages without arguments, if there are any
  ((__messagesWithoutArgs list) each:(do (__message)
    (set __object (sendMessageWithList __object __message))
  ))

  ; then either dispatch the last message with arguments, or return the BaconShould instance
  (if (__lastMessageWithArgs)
    (then (sendMessageWithList __object __lastMessageWithArgs))
    (else (__object))
  )
)

(macro describe (name requirements)
  `(try
    (set parent self)
    ((parent childContextWithName:,name requirements:,requirements) run)
    (catch (e)
      (if (eq (e reason) "undefined symbol self while evaluating expression (set parent self)")
        (then
          ; not running inside a context
          (((BaconContext alloc) initWithName:,name requirements:,requirements) run)
        )
        ; another type of exception occured
        (else (throw e))
      )
    )
  )
)

(macro it (description block)
  `(self requirement:,description block:,block report:t)
)

(macro before (block)
  `(self before:,block)
)
(macro after (block)
  `(self after:,block)
)

; shared contexts

(set $BaconShared (NSMutableDictionary dictionary))

(macro shared (name requirements)
  `($BaconShared setValue:,requirements forKey:,name)
)

(macro behaves_like (name)
  (set context ($BaconShared valueForKey:name))
  (if (context)
    ; each requirement is a complete `it' block
    (then (context each: (do (requirement) (eval requirement))))
    (else (throw "No such context `#{name}'"))
  )
)

