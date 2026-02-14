---
description: Systematic debugging methodology. Apply when diagnosing errors, investigating failures, or troubleshooting.
---
# Debugging Patterns v1.0.0

## Purpose
Systematic debugging approach.

## Process
1. **Reproduce** - Consistent reproduction
2. **Isolate** - Minimal failing case
3. **Hypothesize** - Potential causes
4. **Test** - Verify hypothesis
5. **Fix** - Apply minimal fix
6. **Verify** - Ensure fix works

## Tools
```python
# Print debugging
print(f"DEBUG: {variable=}")

# Breakpoint
import pdb; pdb.set_trace()

# Logging
import logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)
logger.debug(f"State: {state}")
```

## AWS Lambda Debugging
```bash
# Local testing
sam local invoke -e event.json

# CloudWatch logs
aws logs tail /aws/lambda/function --follow
```

## Patterns
- Binary search for problem location
- Check assumptions with assertions
- Use version control to find breaking change
