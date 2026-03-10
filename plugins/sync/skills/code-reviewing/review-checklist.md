# Review Checklist

## 1. Security (BLOCKING)

Critical security issues that must be fixed before merge.

- [ ] **No hardcoded secrets** - tokens, API keys, passwords, private keys
- [ ] **No PII exposure** - emails, phone numbers, user IDs in logs
- [ ] **No SQL injection** - string concatenation in queries
- [ ] **No command injection** - unsanitized input to shell/exec
- [ ] **No path traversal** - user input in file paths without validation
- [ ] **No XSS vectors** - unescaped user input in HTML/templates
- [ ] **No insecure deserialization** - untrusted data in deserialize calls

## 2. Logic & Correctness (BLOCKING)

Bugs and logical errors that will cause runtime issues.

### Null Safety
- [ ] Are nullable values checked before use?
- [ ] Are optional fields handled correctly?

### Boundary Conditions
- [ ] **Array/slice**: empty, single element, out-of-bounds access
- [ ] **Numbers**: zero, negative, overflow, underflow
- [ ] **Strings**: empty, whitespace-only, unicode, very long

### State & Side Effects
- [ ] Are state mutations intentional?
- [ ] Are there race conditions?
- [ ] Is shared state properly synchronized?

### Error Handling
- [ ] Are errors/nil returns properly handled?
- [ ] Are error messages informative?
- [ ] Is error propagation correct?

### Control Flow
- [ ] Can loops run forever? (missing break/termination)
- [ ] Off-by-one errors in loops?
- [ ] Correct use of break/continue/return?

## 3. Resource Management (BLOCKING for leaks)

Resource leaks cause memory issues and connection exhaustion.

### File & Connection Handling
- [ ] Are opened files/connections closed?
- [ ] Is `defer`/`finally`/`using` used correctly?
- [ ] Are resources closed in error paths?

### Memory Management
- [ ] Large allocations inside loops?
- [ ] Unbounded caches or maps?
- [ ] Circular references preventing GC?

### Concurrency Resources
- [ ] Can goroutines/threads leak?
- [ ] Is there proper cancellation/timeout?
- [ ] Are channels closed appropriately?

## 4. API & Compatibility (WARNING)

Breaking changes that affect callers.

- [ ] **Breaking changes** to public interfaces?
- [ ] **Backward compatibility** maintained?
- [ ] **Deprecated APIs** being introduced or used?
- [ ] **Version compatibility** with dependencies?

## 5. Code Quality (NIT)

Style and maintainability issues.

- [ ] No debug prints left behind (`console.log`, `fmt.Println`, `print`)
- [ ] No dead/commented-out code
- [ ] No magic numbers (use named constants)
- [ ] Consistent naming and formatting
- [ ] Clear variable/function names
- [ ] Appropriate comments for complex logic
