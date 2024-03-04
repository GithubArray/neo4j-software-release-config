### display all SCR
MATCH (Software_Config_Release) RETURN Software_Config_Release

-----------------------------------------------
### delete all SCR and upgrade paths
MATCH (Software_Config_Release) DETACH DELETE Software_Config_Release

-----------------------------------------------
### positive dataset p1
CREATE 
(a: Software_Config_Release {os: "rhel", version_year: 2024, version_release_num: 2, status: "PREFERRED"}),
(b: Software_Config_Release {os: "rhel", version_year: 2024, version_release_num: 1, status: "ACTIVE"}),
(c: Software_Config_Release {os: "rhel", version_year: 2023, version_release_num: 1, status: "DEPRECATED"}),
(d: Software_Config_Release {os: "rhel", version_year: 2022, version_release_num: 1, status: "INACTIVE"}),
(b)-[:UPGRADES_TO]->(a),
(c)-[:UPGRADES_TO]->(b),
(e: Software_Config_Release {os: "windows", version_year: 2024, version_release_num: 2, status: "PREFERRED"}),
(f: Software_Config_Release {os: "windows", version_year: 2024, version_release_num: 1, status: "ACTIVE"}),
(f)-[:UPGRADES_TO]->(e)

-----------------------------------------------

## rule 1: All SCRs should only have status in ["PREFERRED", "ACTIVE", "DEPRECATED", "INACTIVE"]

### negative dataset r1n1
CREATE 
(r1n1: Software_Config_Release {os: "r1n1", version_year: 2024, version_release_num: 2, status: "PREFERRED"}),
(r1n2: Software_Config_Release {os: "r1n1", version_year: 2024, version_release_num: 1, status: "DINGLED"})

### test for rule 1
MATCH (Software_Config_Release) 
WHERE NOT(Software_Config_Release.status IN ["PREFERRED", "ACTIVE", "DEPRECATED", "INACTIVE"])
RETURN Software_Config_Release

expected return: 0

-----------------------------------------------

## rule 2: All upgrade paths should have at least 1 PREFERRED destination

### negative dataset r2n1
CREATE 
(r2n1: Software_Config_Release {os: "r2n1", version_year: 2024, version_release_num: 1, status: "ACTIVE"}),
(r2n2: Software_Config_Release {os: "r2n1", version_year: 2024, version_release_num: 2, status: "ACTIVE"}),
(r2n1)-[:UPGRADES_TO]->(r2n2)


### test for rule 2
MATCH (dest_scr) WHERE NOT EXISTS ((dest_scr)-[]->())
WITH dest_scr
MATCH (src_scr)-[]->(dest_scr)
WHERE dest_scr.status <> "PREFERRED"
RETURN src_scr, dest_scr


MATCH (dest_scr) WHERE NOT EXISTS ((dest_scr)-[]->())
WITH dest_scr
MATCH (src_scr)-[]->(dest_scr)
WITH src_scr, dest_scr, COLLECT(dest_scr) as destinations_cnt
WHERE SIZE(destinations_cnt) > 1
RETURN src_scr, dest_scr

expected return: 0

-----------------------------------------------

## rule 3: All upgrade paths should have only 1 PREFERRED destination

### negative dataset r3n1
CREATE 
(r3n1: Software_Config_Release {os: "r3n1", version_year: 2024, version_release_num: 1, status: "ACTIVE"}),
(r3n2: Software_Config_Release {os: "r3n1", version_year: 2024, version_release_num: 2, status: "ACTIVE"}),
(r3n1)-[:UPGRADES_TO]->(r3n2)


### test for rule 3
MATCH (dest_scr) WHERE NOT EXISTS ((dest_scr)-[]->())
WITH dest_scr
MATCH (src_scr)-[]->(dest_scr)
WHERE dest_scr.status <> "PREFERRED"
RETURN src_scr, dest_scr

expected return: 0

-----------------------------------------------

## rule 4: DEPRECATED SCRs must have an upgrade path

### negative dataset r4n1
CREATE 
(r4n1: Software_Config_Release {os: "r4n1", version_year: 2024, version_release_num: 1, status: "DEPRECATED"})

### test for rule 4
MATCH (src_scr) 
WHERE NOT EXISTS ((src_scr)-[]->()) AND src_scr.status = "DEPRECATED"
RETURN src_scr

expected return: 0

-----------------------------------------------

## rule 5: There should have no cycle in upgrade paths

### negative dataset r5n1
CREATE 
(r5n1: Software_Config_Release {os: "r5n1", version_year: 2024, version_release_num: 1, status: "ACTIVE"}),
(r5n2: Software_Config_Release {os: "r5n1", version_year: 2024, version_release_num: 1, status: "ACTIVE"}),
(r5n1)-[:UPGRADES_TO]->(r5n2),
(r5n2)-[:UPGRADES_TO]->(r5n1)

### test for rule 5
MATCH scr=(scr1)-[*]->(scr1) 
RETURN nodes(scr)

MATCH scr=(scr1)-[*1..15]->(scr1) 
RETURN nodes(scr)

expected return: 0

-----------------------------------------------

## rule 6: For 1 os_family, we should have only 1 upgrade path

### negative dataset r6n1
CREATE 
(r6n1: Software_Config_Release {os: "r6n1", version_year: 2024, version_release_num: 1, status: "ACTIVE"}),
(r6n2: Software_Config_Release {os: "r6n1", version_year: 2024, version_release_num: 1, status: "ACTIVE"}),
(r6n1)-[:UPGRADES_TO]->(r6n2),
(r6n3: Software_Config_Release {os: "r6n1", version_year: 2024, version_release_num: 1, status: "ACTIVE"})

### test for rule 6
MATCH (scr1) 
WHERE NOT EXISTS { (scr1)-[]-(scr2) WHERE scr1.os = scr2.os AND id(scr1) > id(scr2) }
AND scr1.status <> "INACTIVE"
WITH scr1.os AS os, count(*) AS numClusters
WHERE numClusters > 1
RETURN os, numClusters

expected return: 0

-----------------------------------------------

## rule 7: For 1 upgrade path, we should have only 1 os_family version along the way.

### negative dataset r7n1
CREATE 
(r7n1: Software_Config_Release {os: "r7n1", version_year: 2024, version_release_num: 1, status: "ACTIVE"}),
(r7n2: Software_Config_Release {os: "r7n2", version_year: 2024, version_release_num: 1, status: "ACTIVE"}),
(r7n1)-[:UPGRADES_TO]->(r7n2)

### test for rule 7
MATCH (scr1)-[]-(scr2)
WHERE scr1.os <> scr2.os
RETURN scr1

expected return: 0

-----------------------------------------------

## rule 8: There is only 1 upgrade destination for a SCR

### negative dataset r8n1
CREATE 
(r8n1: Software_Config_Release {os: "r8n1", version_year: 2024, version_release_num: 1, status: "ACTIVE"}),
(r8n2: Software_Config_Release {os: "r8n1", version_year: 2024, version_release_num: 2, status: "PREFERRED"}),
(r8n3: Software_Config_Release {os: "r8n1", version_year: 2024, version_release_num: 3, status: "ACTIVE"}),
(r8n1)-[:UPGRADES_TO]->(r8n2),
(r8n1)-[:UPGRADES_TO]->(r8n3)


### test for rule 8
MATCH (scr1)-->(scr2)
WITH scr1, COLLECT(scr2) AS destinations
WHERE SIZE(destinations) > 1
RETURN scr1, destinations

expected return: 0

-----------------------------------------------

## rule 9: version should be strictly increasing in an upgrade path

### negative dataset r9n1
CREATE 
(r9n1: Software_Config_Release {os: "r9n1", version_year: 2024, version_release_num: 1, status: "ACTIVE"}),
(r9n2: Software_Config_Release {os: "r9n1", version_year: 2023, version_release_num: 2, status: "PREFERRED"}),
(r9n1)-[:UPGRADES_TO]->(r9n2),
(r9n3: Software_Config_Release {os: "r9n1", version_year: 2024, version_release_num: 2, status: "ACTIVE"}),
(r9n4: Software_Config_Release {os: "r9n1", version_year: 2024, version_release_num: 1, status: "PREFERRED"}),
(r9n3)-[:UPGRADES_TO]->(r9n4)


### test for rule 9
MATCH (scr1)-[]->(scr2)
WITH scr1, scr2, COLLECT(scr2) AS destinations
WHERE scr1.version_year > scr2.version_year OR (scr1.version_year <= scr2.version_year AND scr1.version_release_num > scr2.version_release_num)
RETURN scr1, destinations

expected return: 0


-----------------------------------------------

## rule 10: INACTIVE SCR should have no upgrade path

### negative dataset r10n1
CREATE 
(r10n1: Software_Config_Release {os: "r10n1", version_year: 2024, version_release_num: 1, status: "INACTIVE"}),
(r10n2: Software_Config_Release {os: "r10n1", version_year: 2024, version_release_num: 2, status: "PREFERRED"}),
(r10n1)-[:UPGRADES_TO]->(r10n2)


### test for rule 10
MATCH (scr1)-[]->(scr2)
WITH scr1, collect(scr2) AS destinations
WHERE scr1.status = "INACTIVE"
RETURN scr1, destinations

expected return: 0