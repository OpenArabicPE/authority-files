# Workflow named entities: persons

- location and file names
    + main folder/repository: `OpenArabicPE/authority-files/`
        * sub-folder for tools: `xslt/`
        * sub-folder for viaf data: `viaf/`
        * sub-folder for TEI files: `tei/`
    + copies of SRU results from VIAF queries: `viaf_id.SRW.xml`

1. Query all TEI files for `persName`
    + check if information is already present in a **local** authority file
    + check if it already has a reference to VIAF
2. Query VIAF through SRU using
    + VIAF ID or
    + name
3. Save VIAF results as individual copy.
    + naming scheme: `viaf_id.SRW.xml`