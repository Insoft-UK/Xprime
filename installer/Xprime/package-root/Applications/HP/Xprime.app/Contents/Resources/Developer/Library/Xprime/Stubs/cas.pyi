"""Type stubs for the HP Prime cas module."""

from typing import Any

def caseval(expr: str) -> Any:
    """Evaluate a CAS expression string and return the result."""
    ...

def eval_expr(expr: str) -> Any:
    """Evaluate a CAS expression."""
    ...

def get_key() -> int:
    """Return the current keycode (-1 if none)."""
    ...

def xcas(command: str) -> Any:
    """Execute an Xcas command."""
    ...
