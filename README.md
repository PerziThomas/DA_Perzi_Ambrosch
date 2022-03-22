# DA_Perzi_Ambrosch

## Usage of PowerShell Script
- Make sure to have pandoc4all image locally (https://github.com/ingokofler/pandoc4all)
- Rename it using `docker image tag <id of image> pandoc4all:latest`
- Set environmental variable %DA_FOLDER% to the current directory
- Run Script -> Get pdf

## How to run

Important: use `ghcr.io/ingokofler/pandoc4all:feat-support-da-template` image for the moment

```shell

OUTPUTDIR=output
STYLEDIR=style
INPUTDIR=sources

pandoc  \
    --output "$(OUTPUTDIR)/diplomarbeit.tex" \
    --template="$(STYLEDIR)/htl-da/Pandoc_DA.tex" \
    "$(INPUTDIR)/metadata.yml" \
    "$(INPUTDIR)"/*.md \
    --verbose \
    --biblatex \
    --top-level-division=chapter \
    --listings \
    2>htl-latex.log

cd $(OUTPUTDIR)

# Copy sources and template data to output file for
# processing final .tex to pdf
mkdir -p source
cp -rf ../source/figures source
cp -rf ../source/references.bib .
cp -rf ../style/htl-da/chapters ../style/htl-da/includes ../style/htl-da/media .

pdflatex diplomarbeit.tex
bibtex diplomarbeit
pdflatex diplomarbeit.tex
pdflatex diplomarbeit.tex

```
