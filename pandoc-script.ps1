docker run --rm -it -v $env:DA_FOLDER/:/data `
pandoc4all:da `
DA.md `
-o da.pdf `
--listings `
--from markdown `
--toc `
--number-sections `
--template eisvogel.tex