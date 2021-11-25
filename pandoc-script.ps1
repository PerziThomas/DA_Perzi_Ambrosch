docker run --rm -it -v $env:DA_FOLDER/:/data `
pandoc4all `
DA.md `
-o da.pdf `
-V header-center="DA" `
--listings `
--from markdown `
--toc `
--number-sections `
--template eisvogel.tex