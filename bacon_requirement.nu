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
    (@before each:(do (x) (@context instanceEval:x)))
  )

  (- (id) runAfterFiltersAndThrow:(id)shouldThrow is
    (try
      (@after each:(do (x) (@context instanceEval:x)))
      (catch (e)
        (if (shouldThrow) (throw e))
      )
    )
  )

  (- (id) run is
    (if (@report)
      ($BaconSummary addSpecification)
      (print "- #{@description}")
    )
    
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
          ($BaconSummary addToErrorLog:e context:(@context name) specification:@description type:type)
        )
      )
    )
    
    (if (@report) (print "\n"))
  )
)