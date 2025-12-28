library(DBI)
library(RSQLite)

cat("Testing RSQLite...\n")

# Try to create a test database
con <- dbConnect(RSQLite::SQLite(), "test.sqlite")
cat("✓ Connection created\n")

# Create a test table
dbExecute(con, "CREATE TABLE IF NOT EXISTS test (id INTEGER, value TEXT)")
cat("✓ Table created\n")

# Insert test data
dbExecute(con, "INSERT INTO test VALUES (1, 'hello')")
cat("✓ Data inserted\n")

# Query
result <- dbGetQuery(con, "SELECT * FROM test")
cat(sprintf("✓ Query result: %s\n", result$value[1]))

# Disconnect
dbDisconnect(con)
cat("✓ Disconnected\n")

# Clean up
unlink("test.sqlite")
cat("✓ Test passed!\n")
