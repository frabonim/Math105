#!/usr/bin/env python3
from __future__ import annotations

import re
import shutil
import subprocess
import sys
from pathlib import Path


BLANK_TEXT = "[blank]"
IMAGE_MAGICK_BIN = shutil.which("magick") or shutil.which("convert")


def replace_layout_artifacts(text: str) -> str:
    text = re.sub(
        r"\\text\{([^}]*)\\hskip\s*[^\s}]+([^}]*)\}",
        lambda m: "\\text{" + (m.group(1) + " " + m.group(2)).strip() + "}",
        text,
    )
    text = re.sub(
        r"\\underline\{([^}]*)\\hskip\s*[^\s}]+\}",
        lambda m: m.group(1).strip() + f" {BLANK_TEXT}",
        text,
    )
    text = re.sub(r"\\begin\{multicols\}\{[^}]+\}", "", text)
    text = text.replace(r"\end{multicols}", "")

    text = re.sub(r"\\underline\{\\hskip[^}]+\}", BLANK_TEXT, text)
    text = text.replace(r"\hrulefill", BLANK_TEXT)
    text = text.replace(r"\phantom{.}", "")
    text = text.replace(r"\vfill", "")
    text = re.sub(r"\\vskip\s*[^\s]+", "\n", text)
    text = text.replace(r"\hfill", "")

    text = re.sub(r"\\text\{\\hskip[^}]*or\\hskip[^}]*\}", r"\\text{or}", text)
    text = text.replace(r"\Large{", r"\textbf{")

    return text


def tikz_alt_text(body: str) -> str:
    if "grid" in body and "-- (10.5,0)" in body and "-- (0,10.5)" in body:
        return "Blank coordinate grid with x-axis and y-axis arrows for plotting data."
    return "Diagram generated from a TikZ drawing in the lesson."


def render_tikz(match: re.Match[str], work_prefix: Path, index: int) -> str:
    tikz_block = match.group(0)
    tikz_body = match.group(1)
    safe_stem = work_prefix.name.replace(".html-prep", "").lstrip("._")
    tex_path = work_prefix.with_name(f"{safe_stem}_tikz_{index}.tex")
    pdf_path = tex_path.with_suffix(".pdf")
    png_path = tex_path.with_suffix(".png")

    tex_path.write_text(
        "\\documentclass{standalone}\n"
        "\\usepackage{tikz}\n"
        "\\usepackage{pgfplots}\n"
        "\\pgfplotsset{compat=1.18}\n"
        "\\begin{document}\n"
        f"{tikz_block}\n"
        "\\end{document}\n"
    )

    subprocess.run(
        [
            "pdflatex",
            "-interaction=nonstopmode",
            "-halt-on-error",
            f"-output-directory={tex_path.parent}",
            tex_path.name,
        ],
        check=True,
        cwd=tex_path.parent,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    subprocess.run(
        [
            IMAGE_MAGICK_BIN,
            "-density",
            "200",
            str(pdf_path),
            "-quality",
            "100",
            str(png_path),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    alt = tikz_alt_text(tikz_body)
    return f"\\includegraphics[alt={{{alt}}}, width=4in]{{{png_path.name}}}"


def preprocess(source_path: Path, output_path: Path) -> None:
    text = source_path.read_text()
    text = replace_layout_artifacts(text)

    def replacer(match: re.Match[str]) -> str:
        replacer.count += 1
        return render_tikz(match, output_path.with_suffix(""), replacer.count)

    replacer.count = 0
    text = re.sub(
        r"\\begin\{tikzpicture\}(.*?)\\end\{tikzpicture\}",
        replacer,
        text,
        flags=re.DOTALL,
    )

    output_path.write_text(text)


def cleanup(prefix: Path) -> None:
    for path in prefix.parent.glob(f"{prefix.name}*"):
        if path.is_file():
            path.unlink()


def main() -> int:
    if len(sys.argv) < 3:
        print(
            "usage: prepare_html_source.py <input.tex> <output.tex> [--clean]",
            file=sys.stderr,
        )
        return 1

    source_path = Path(sys.argv[1]).resolve()
    output_path = Path(sys.argv[2]).resolve()

    if IMAGE_MAGICK_BIN is None:
        print(
            "error: neither 'magick' nor 'convert' was found in PATH", file=sys.stderr
        )
        return 1

    if len(sys.argv) > 3 and sys.argv[3] == "--clean":
        cleanup(output_path.with_suffix(""))
        return 0

    preprocess(source_path, output_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
