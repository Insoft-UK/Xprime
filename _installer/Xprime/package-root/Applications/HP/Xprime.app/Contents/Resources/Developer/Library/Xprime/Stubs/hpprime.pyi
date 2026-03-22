"""Type stubs for the HP Prime hpprime MicroPython module."""

from typing import Any, Union, overload

# ---------------------------------------------------------------------------
# Core
# ---------------------------------------------------------------------------

def eval(ppl_string: str) -> Any:
    """Execute a PPL command string and return its result."""
    ...

def keyboard() -> int:
    """Return raw keyboard state bitmask."""
    ...

def mouse() -> list[list[int]]:
    """Return touch data: [[x,y,xOrig,yOrig,type],[]] for two fingers."""
    ...

# ---------------------------------------------------------------------------
# GROB graphics primitives
# ---------------------------------------------------------------------------

def dimgrob(gr: int, w: int, h: int, color: int) -> None:
    """Create / resize an off-screen GROB buffer filled with *color*."""
    ...

def fillrect(gr: int, x: int, y: int, w: int, h: int,
             border_color: int, fill_color: int) -> None:
    """Draw a filled rectangle (x, y, width, height)."""
    ...

def rect(gr: int, x: int, y: int, w: int, h: int, color: int) -> None:
    """Draw a rectangle outline."""
    ...

def line(gr: int, x1: int, y1: int, x2: int, y2: int, color: int) -> None:
    """Draw a line."""
    ...

def pixon(gr: int, x: int, y: int, color: int) -> None:
    """Set a single pixel."""
    ...

def getpix(gr: int, x: int, y: int) -> int:
    """Get the color of a pixel."""
    ...

def textout(gr: int, x: int, y: int, text: str, font: int,
            color: int, width: int = ...) -> None:
    """Draw text (limited; prefer TEXTOUT_P via eval for full options)."""
    ...

def arc(gr: int, x: int, y: int, r: int,
        a1: float, a2: float, color: int) -> None:
    """Draw an arc."""
    ...

def circle(gr: int, x: int, y: int, r: int, color: int) -> None:
    """Draw a circle."""
    ...

def blit(gr: int, dx: int, dy: int, dw: int, dh: int,
         src_gr: int, sx: int, sy: int, sw: int, sh: int) -> None:
    """Copy a region between GROBs."""
    ...

def strblit(dest_g: int, dx: int, dy: int, dw: int, dh: int,
            src_g: int, sx: int, sy: int, sw: int, sh: int) -> None:
    """Buffer-to-buffer pixel copy."""
    ...

def grobw(gr: int) -> int:
    """Return the width of a GROB buffer in pixels."""
    ...

def grobh(gr: int) -> int:
    """Return the height of a GROB buffer in pixels."""
    ...

def grob(gr: int, data: Any) -> None:
    """Create GROB from raw data."""
    ...

# ---------------------------------------------------------------------------
# Cartesian variants (suffix _c)
# ---------------------------------------------------------------------------

def fillrect_c(gr: int, x: int, y: int, w: int, h: int,
               border_color: int, fill_color: int) -> None: ...
def line_c(gr: int, x1: float, y1: float, x2: float, y2: float,
           color: int) -> None: ...
def textout_c(gr: int, x: float, y: float, text: str, font: int,
              color: int, width: int = ...) -> None: ...
def arc_c(gr: int, x: float, y: float, r: float,
          a1: float, a2: float, color: int) -> None: ...
def circle_c(gr: int, x: float, y: float, r: float, color: int) -> None: ...
def pixon_c(gr: int, x: float, y: float, color: int) -> None: ...

def set_cartesian(gr: int, x_min: float, x_max: float,
                  y_min: float, y_max: float) -> None:
    """Set the Cartesian coordinate system for _c variants."""
    ...

def get_cartesian(gr: int) -> list[float]:
    """Return [x_min, x_max, y_min, y_max] for a GROB."""
    ...
