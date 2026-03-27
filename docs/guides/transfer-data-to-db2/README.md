# Transfer Data to DB2 - JCL Utilities

This folder contains JCL utilities for converting between PDS and DB2 formats.

## Folder Structure

```
transfer-data-to-db2/
└── jcl/
    ├── pds-to-db2.jcl      # Convert PDS member to DB2 table
    └── db2-to-pds.jcl      # Unload DB2 table to PDS member
```

## Usage Instructions

### PDS to DB2 (pds-to-db2.jcl)

Converts a PDS member to a sequential dataset, then loads it into a DB2 table.

**Steps:**
1. Edit the JCL and replace placeholders:
   - `YOUR.PDS.LIBRARY(MEMBER)` - Your source PDS and member name
   - `YOURDB2` - Your DB2 subsystem name
   - `YOUR_SCHEMA.YOUR_TABLE` - Target DB2 table
   - `YOUR_DB.YOUR_TABLESPACE` - Target database and tablespace
   - Field positions and types in SYSIN to match your data

2. Submit the job:
   ```
   SUBMIT 'pds-to-db2.jcl'
   ```

### DB2 to PDS (db2-to-pds.jcl)

Unloads a DB2 table to a sequential dataset, then copies it to a PDS member.

**Steps:**
1. Edit the JCL and replace placeholders:
   - `YOUR.PDS.LIBRARY(MEMBER)` - Target PDS and member name
   - `YOURDB2` - Your DB2 subsystem name
   - `YOUR_SCHEMA.YOUR_TABLE` - Source DB2 table
   - `YOUR_DB.YOUR_TABLESPACE` - Source database and tablespace

2. Submit the job:
   ```
   SUBMIT 'db2-to-pds.jcl'
   ```

## Important Notes

- **PDS cannot be read directly by DB2 utilities** - always convert to PS first
- Ensure LRECL matches your DB2 table column definitions
- Use `RESUME YES` to append to existing data, `RESUME NO` to replace
- Adjust SPACE allocations based on your data volume
