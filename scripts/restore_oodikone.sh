docker exec -i kone-db /bin/bash -c "pg_restore --username=postgres --format=custom --dbname=kone-db --no-owner" < "anonyymioodi/kone-db.sqz"
docker exec -i user-db /bin/bash -c "psql --username=postgres --dbname=user-db" < "anonyymioodi/user_db_localhost-2024_07_10_12_16_44-dump.sql"
docker exec -i sis-importer-db /bin/bash -c "psql --username=dev --dbname=importer-db" < "anonyymioodi/importer_db_localhost-2024_07_10_12_15_21-dump.sql"
docker exec -i sis-db /bin/bash -c "psql --username=postgres --dbname=sis-db" < "anonyymioodi/sis_db_localhost-2024_07_10_12_09_44-dump.sql"
