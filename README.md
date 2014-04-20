Varios
=============

Small pieces of code that I find useful.

HTML grid
-------

A simple HTML grid with embedded styles, so I can use it in any CMS even if I don't have access to the system's CSS.

Maintenance page
-------

A simple maintenance page. Includes both an Apache VirtualHost and the index.html page, with embedded CSS Styles to easier the deployment.

Reverse proxy
-------

A simple apache2 reverse proxy.

NIFvalidator
-------
Java class to validate an Spanish identification number (NIF).

Nodejs web scrapong
-------
nodejs sample script that gets the news from www.inap.es.

Backup scripts
-------

Incremental backup script. It uses complete and incremental backups, with 
hard links to simulate snapshots. $FULL_BACKUP_LIMIT controls the frecuency 
of full backups.It accepts at least one source directory and a single destination directory as arguments. Usage:

    incremental_backup.sh SOURCE_DIRECTORY_1 [SOURCE_DIRECTORY_2..N] DESTINATION_DIRECTORY

Database backup script. Simple script that performs a mysqldump on a given database, storing an specified number
of past backups.

Recursive OCR script
-------

Recursive script that uses tesseract-ocr and Geza Kovacs's pdfocr to recurse into a directory, trying to perform
OCR in every PDF file.
