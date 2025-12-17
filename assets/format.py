import os
import re

# -------------------------
# CONFIGURATION
# -------------------------

INPUT_DIR = "input_rtf"
OUTPUT_DIR = "output_rtf"

BOLD_WORDS = ["Syntax", "Example", "Description"]

PARAMETERS = [
    "var1", "var2", "var8",
    "value1", "value2",
    "x", "y", "G", "x1", "x2", "y1", "y2", "color", "color1", "color2", "fillColor", "borderColor"
    "object", "object1", "object2", "begin", "end",
    "str", "n", "text", "list", "trgtGRB", "trgtG"
]

# -------------------------
# CREATE OUTPUT DIR
# -------------------------

os.makedirs(OUTPUT_DIR, exist_ok=True)

# -------------------------
# PROCESS EACH RTF FILE
# -------------------------

for filename in os.listdir(INPUT_DIR):
    if not filename.lower().endswith(".rtf"):
        continue

    input_path = os.path.join(INPUT_DIR, filename)
    output_path = os.path.join(OUTPUT_DIR, filename)

    with open(input_path, "r", encoding="utf-8") as f:
        rtf = f.read()

    # -------------------------
    # 1. BOLD KEYWORDS
    # -------------------------

    for word in BOLD_WORDS:
        rtf = re.sub(
            rf"\b{re.escape(word)}\b",
            rf"\\b {word}\\b0",
            rtf
        )

    # -------------------------
    # 2. ITALICIZE PARAMETERS IN PARENTHESES
    # -------------------------

    def italicize_params(match):
        content = match.group(1)
        for p in PARAMETERS:
            content = re.sub(
                rf"\b{re.escape(p)}\b",
                rf"\\i {p}\\i0",
                content
            )
        return f"({content})"

    rtf = re.sub(r"\(([^)]*)\)", italicize_params, rtf)

    # -------------------------
    # 3. ITALICIZE PARAMETERS EVERYWHERE
    # -------------------------

    for p in PARAMETERS:
        rtf = re.sub(
            rf"\b{re.escape(p)}\b",
            rf"\\i {p}\\i0",
            rtf
        )

    # -------------------------
    # WRITE OUTPUT
    # -------------------------

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(rtf)

    print(f"Processed: {filename}")

print("All RTF files processed.")
