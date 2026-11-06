#!/usr/bin/env python3
"""Build the base Word (docx) version of manuscript_final.tex.

Pipeline:
  1. preprocess the LaTeX (resolve natbib citations to author-year text,
     resolve \\ref to table/figure numbers, rebuild the bibliography as
     plain paragraphs, strip the end-matter Tables/Figures sections)
  2. LaTeX -> markdown via pandoc
  3. swap PAGEBREAKMARKER paragraphs for raw OpenXML page breaks
     (pandoc cannot convert \\newpage straight from LaTeX)
  4. markdown -> docx via pandoc

Run scripts/build_manuscript_docx.R afterwards to append the flextable
tables and PNG figures.
"""
import datetime
import re
import subprocess
import sys

PROJ = "/home/omarlizardo/projects/SOCIAL PSYCH/patriotism-choice-process"
TEX = f"{PROJ}/manuscript_final.tex"
WORK = "/tmp/pa-1000/05492a04-605d-46df-b8b8-002fbae8bbfb"
OUT_DOCX = f"{PROJ}/word_port/manuscript_final.docx"

PAGEBREAK_OPENXML = (
    "```{=openxml}\n"
    '<w:p><w:r><w:br w:type="page"/></w:r></w:p>\n'
    "```\n"
)

src = open(TEX).read()

# ---- bibliography labels: key -> "Adorno et~al., 1950"
label_map = {key: label for label, key in re.findall(r"\\bibitem\[([^\]]*)\]\{([^}]*)\}", src)}

def ay(key):
    label = label_map[key].replace("~", " ").strip()
    if "," in label:
        author, year = label.rsplit(",", 1)
        return author.strip(), year.strip()
    return label, ""

def cite_str(key):
    a, y = ay(key)
    return f"{a} {y}"

def pages(opt):
    opt = opt.replace("~", " ").replace("--", "\u2013")
    if re.fullmatch(r"\d+", opt.strip()):
        return ":" + opt.strip()
    return ", " + opt

# ---- citations (bracketed forms first)
def r_citealp_opt(m):
    keys = [k.strip() for k in m.group(2).split(",")]
    return "; ".join(cite_str(k) for k in keys) + pages(m.group(1))

def r_citep_opt(m):
    keys = [k.strip() for k in m.group(2).split(",")]
    inner = "; ".join(cite_str(k) for k in keys) + pages(m.group(1))
    return f"({inner})"

def r_citet(m):
    keys = [k.strip() for k in m.group(1).split(",")]
    parts = []
    for k in keys:
        a, y = ay(k)
        parts.append(f"{a} ({y})")
    return " and ".join(parts)

def r_citeyearpar(m):
    keys = [k.strip() for k in m.group(1).split(",")]
    return "(" + ay(keys[0])[1] + ")"

def r_citealp(m):
    keys = [k.strip() for k in m.group(1).split(",")]
    return "; ".join(cite_str(k) for k in keys)

def r_citep(m):
    keys = [k.strip() for k in m.group(1).split(",")]
    return "(" + "; ".join(cite_str(k) for k in keys) + ")"

src = re.sub(r"\\citealp\[([^\]]*)\]\{([^}]*)\}", r_citealp_opt, src)
src = re.sub(r"\\citep\[([^\]]*)\]\{([^}]*)\}", r_citep_opt, src)
src = re.sub(r"\\citet\{([^}]*)\}", r_citet, src)
src = re.sub(r"\\citeyearpar\{([^}]*)\}", r_citeyearpar, src)
src = re.sub(r"\\citealp\{([^}]*)\}", r_citealp, src)
src = re.sub(r"\\citep\{([^}]*)\}", r_citep, src)

# ---- cross-references
ref_nums = {
    "tab:descriptives": "1", "tab:nationalism": "2",
    "tab:educ": "3", "tab:full2004": "4",
    "fig:logistic_pride": "1", "fig:pride_bar": "2",
    "fig:marginal_educ": "3", "fig:membership_forest": "4",
}
src = re.sub(r"~\\ref\{([^}]*)\}", lambda m: " " + ref_nums.get(m.group(1), "??"), src)
src = re.sub(r"\\ref\{([^}]*)\}", lambda m: ref_nums.get(m.group(1), "??"), src)

# ---- strip end matter (Tables / Figures sections, rebuilt via flextable)
end_matter_start = src.find("\\section*{Tables}")
end_doc = src.find("\\end{document}")
src = src[:end_matter_start] + src[end_doc:]

# ---- rebuild bibliography as plain paragraphs
m = re.search(r"\\begin\{thebibliography\}\{\}\n(.*?)\\end\{thebibliography\}", src, re.DOTALL)
if not m:
    sys.exit("thebibliography not found")
bib = m.group(1)
entries = []
for chunk in re.split(r"\\bibitem\[[^\]]*\]\{[^}]*\}", bib)[1:]:
    t = chunk.replace("\\newblock", "").replace("{\\em ", "\\emph{")
    t = re.sub(r"\s+", " ", t).strip()
    entries.append(t)
bibblock = "\n\n" + "\n\n".join(entries) + "\n\n"
src = src[:m.start()] + bibblock + src[m.end():]
if "\\section*{References}" not in src:
    src = src.replace(bibblock, "\n\\section*{References}" + bibblock, 1)

# ---- \thanks in title: move into the title as a real footnote
m = re.search(r"\\title\{([^{}]*)\\thanks\{(.*?)\}\}", src, re.DOTALL)
title_text, thanks_text = m.group(1), m.group(2)
src = src[:m.start()] + src[m.end():]

# ---- explicit title block (title page): centered title + author +
# affiliation + date; the Running Head / Word Count block stays with it
title_block = (
    "\\begin{center}\n"
    "\\textbf{" + title_text + "\\footnote{" + thanks_text + "}}\\\\\n"
    "Omar Lizardo\\\\\n"
    "Department of Sociology, University of California, Los Angeles\\\\\n"
    "\\today\n"
    "\\end{center}\n"
)
src = re.sub(r"\\author\{[^}]*\}\n\\affil\{[^}]*\}\n\\date\{[^}]*\}\n", "", src)
src = src.replace("\\maketitle", title_block)

# ---- \begin{abstract} is moved into metadata by the LaTeX reader and then
# dropped by the markdown writer; make it an explicit section instead
src = re.sub(r"\\begin\{abstract\}\n?(.*?)\\end\{abstract\}",
             lambda m: "\\section*{Abstract}\n\n" + m.group(1).strip() + "\n",
             src, flags=re.DOTALL)

# ---- literal date (\today is dropped by the LaTeX reader)
src = src.replace("\\today", datetime.date.today().strftime("%B %-d, %Y"))

# ---- page breaks: \newpage / \clearpage -> marker paragraphs
src = re.sub(r"\\(clearpage|newpage)", "\n\nPAGEBREAKMARKER\n\n", src)
# collapse runs of consecutive markers (e.g. stray blank paragraphs between
# \newpage commands) so no blank pages appear in the docx
src = re.sub(r"PAGEBREAKMARKER(?:\s*PAGEBREAKMARKER)+", "PAGEBREAKMARKER", src)
src = re.sub(r"\\vspace\{[0-9.]+em\}\n?", "", src)

open(f"{WORK}/manuscript_pre.tex", "w").write(src)

# ---- step 2: LaTeX -> markdown
subprocess.run(["pandoc", f"{WORK}/manuscript_pre.tex", "-f", "latex",
                "-t", "markdown", "--wrap=none", "-o", f"{WORK}/manuscript_pre.md"],
               check=True)

# ---- step 3: markers -> raw OpenXML page breaks
md = open(f"{WORK}/manuscript_pre.md").read()
n = md.count("PAGEBREAKMARKER")
md = re.sub(r"^\s*PAGEBREAKMARKER\s*$", PAGEBREAK_OPENXML, md, flags=re.MULTILINE)
open(f"{WORK}/manuscript_pre.md", "w").write(md)
print(f"page breaks inserted: {n}")

# ---- step 4: markdown -> docx
subprocess.run(["pandoc", f"{WORK}/manuscript_pre.md", "-f", "markdown",
                "-t", "docx", "-o", OUT_DOCX], check=True)

# ---- sanity report
leftover = re.findall(r"\\cite[pt]|\\ref\{|\\input\{|\\includegraphics|PAGEBREAKMARKER", src)
print("preprocessed OK")
print("leftover latex commands:", leftover if leftover else "none")
print("written:", OUT_DOCX)
