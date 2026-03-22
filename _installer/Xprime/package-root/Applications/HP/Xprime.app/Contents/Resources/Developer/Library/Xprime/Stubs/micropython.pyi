"""Type stubs for the HP Prime micropython module."""

from typing import Any

def const(value: int) -> int:
    """Declare a compile-time integer constant (saves RAM)."""
    ...

def mem_info(verbose: int = ...) -> None:
    """Print memory usage information."""
    ...

def opt_level(level: int = ...) -> int:
    """Get or set the optimisation level (0–3)."""
    ...

def heap_lock() -> None:
    """Lock the heap — prevent garbage collection."""
    ...

def heap_unlock() -> None:
    """Unlock the heap."""
    ...

def stack_use() -> int:
    """Return current C-stack usage in bytes."""
    ...

def pystack_use() -> int:
    """Return current Python-stack usage in bytes."""
    ...

def kbd_intr(chr: int) -> None:
    """Set the character that raises KeyboardInterrupt (-1 to disable)."""
    ...

def qstr_info(verbose: int = ...) -> None:
    """Print interned-string information."""
    ...
