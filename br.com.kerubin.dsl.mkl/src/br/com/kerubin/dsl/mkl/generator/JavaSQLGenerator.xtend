package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*;
import br.com.kerubin.dsl.mkl.model.BasicTypeReference
import br.com.kerubin.dsl.mkl.model.ObjectTypeReference
import org.eclipse.xtend2.lib.StringConcatenation
//import static br.com.kerubin.dsl.mkl.generator.Utils.*

abstract class JavaSQLGenerator  extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	protected def String getDatabaseName(); 
	
	override generate() {
		generateSQLForEntities
	}
	
	override getEntities() {
		baseGenerator.entities.filter[canGenerateSQLDDL]
	}
	
	def generateSQLForEntities() {
		// Based on: https://flywaydb.org/documentation/migrations
		val sqlFileName =  'Entity_Resources/db/migration/V1__Creation_Tables_' + databaseName + '.sql'
		val sqlGenerated = generateSQL
		generateFile(sqlFileName, sqlGenerated)
		
		/*val basePakage = getServerTestResourceGenSourceFolder
		val sqlFileNameForTest = basePakage + 'db/migration/test/V1__Creation_Tables_' + databaseName + '.sql'
		generateFile(sqlFileNameForTest, sqlGenerated)*/
	}
	
	def CharSequence generateSQL() {
		'''
		«dropTables»
		«createTables»
		«createPKs»
		«createFKs»
		«createUKs»
		«createIndexes»
		'''
	}
	
	def CharSequence dropTables() {
		'''
		/**************** WARNING WILL DELETE ALL TABLES *********
		«entities.map[dropTable].join»
		**********************************************************/
		
		'''
	}
	
	def CharSequence dropTable(Entity entity) {
		'''
		DROP TABLE IF EXISTS «entity.databaseName» CASCADE;
		'''
	}
	
	def CharSequence createTables() {
		'''
		«entities.map[createTable].join('\r\n')»
		'''
	}
	
	def CharSequence createTable(Entity entity) {
		val builder = new StringConcatenation
		val table = entity.databaseName
		
		builder.append('CREATE TABLE ')
		builder.append(table)
		
		if (table != entity.name) {
			builder.append(' /* ')
			builder.append(entity.name)
			builder.append(' */ ')			
		}
		
		builder.append(' (')			
		builder.newLine
		
		//Table fields
		var slots = entity.slots.filter[!it.isEntity || (it.isOneToOne && it.isRelationRefers) || it.isManyToOne].filter[!it.isTransient]
		builder.append(slots.map[generateDatabaseField].join(',\n'))
		
		builder.newLine
		builder.append(');')
		builder.newLine
		
		slots = entity.slots.filter[ (it.isManyToMany && it.isRelationOwner) || (it.isOneToMany && !it.isBidirectional) ].filter[!it.isTransient]
		slots.forEach[builder.append(it.createIntermediateTable)]			
		
		builder
	}
	
	def CharSequence createIntermediateTable(Slot slot) {
		val builder = new StringConcatenation
		
		builder.newLine
		builder.append('CREATE TABLE ')
		builder.append(slot.getRelationIntermediateTableName)
		builder.append(' /* ')
		builder.append(slot.ownerEntity.name + ' + ' + slot.name)
		builder.append(' */')
		builder.append(' (')
		builder.newLine
		
		//Table fields
		var Slot[] slots
		
		slots = #[slot.ownerEntity.id, slot.asEntity.id]
		builder.append(slots.map[generateDatabaseField(true)].join(',\n'))
		
		builder.newLine
		builder.append(');')
		builder.newLine
		
		builder
	}
	
	def CharSequence generateDatabaseField(Slot slot) {
		slot.generateDatabaseField(false)
	}
	
	def CharSequence generateDatabaseField(Slot slot, boolean isMany) {		
		val builder = new StringConcatenation
		builder.append('\t')
		
		var String fieldName
		
		if (isMany) {
			fieldName = slot.getSlotAsOwnerEntityIdFK
		}
		else {
			fieldName = slot.databaseName	
		}
		
		builder.append(fieldName)	
		
		
		builder.append(' ')
		builder.append(slot.toSQLType)
		
		if (!slot.optional) {
			builder.append(' NOT NULL')
		}
		
		if (slot.hasDefaultValue) {
			builder.append(' DEFAULT ' + slot.defaultValue)
		}
		
		if (fieldName != slot.name) {
			builder.append(' /* ')
			builder.append(slot.name)
			builder.append(' */')
		}
		
		builder
	}
	
	def CharSequence createPKs() {
		'''
		
		/* PRIMARY KEYS */
		«entities.map[createPK].join»
		'''
	}
	
	def CharSequence mountPK(String tableName, String constraintName, String keyName) {
		'''
		ALTER TABLE «tableName» ADD CONSTRAINT pk_«constraintName» PRIMARY KEY («keyName»);
		'''
	}
	
	def CharSequence createPK(Entity entity) {
		val tableName = entity.databaseName
		var keyName = entity.getEntityIdAsKey
		val constraintName = tableName + '_' + keyName
		
		val builder = new StringConcatenation
		builder.append(mountPK(tableName, constraintName, keyName))
		
		// mount intermediate table PKs
		val slots = entity.slots.filter[ (it.isManyToMany && it.isRelationOwner) || (it.isOneToMany && !it.isBidirectional) ]
		slots.forEach[slot|
			val tableName_ = slot.getRelationIntermediateTableName
			val constraintName_ = tableName_
			val keyName_ = slot.getSlotAsOwnerEntityIdFK + ', ' + slot.getSlotAsEntityIdFK
			builder.append(mountPK(tableName_, constraintName_, keyName_))
		]
		
		builder
	}
	
	def CharSequence createFKs() {
		val builder = new StringConcatenation
		builder.newLine
		builder.append('/* FOREIGN KEYS */')
		builder.newLine
		entities.forEach[builder.append(it.createFK)]
		builder.newLine
		
		builder
	}
	
	def CharSequence mountFK(String table, String constraintName, String key, String refTable, String refKey) {
		'''
		ALTER TABLE «table» ADD CONSTRAINT fk_«constraintName» FOREIGN KEY («key») REFERENCES «refTable» («refKey»);
		'''
	}
	
	def CharSequence createFK(Entity entity) {
		entity.slots
			.filter[(it.isOneToOne && it.isRelationRefers) || 
					it.isManyToOne || 
					(it.isManyToMany && it.isRelationOwner) || 
					(it.isOneToMany && !it.isBidirectional)
			]
			.map[createSlotFK].join
	}
	
	def CharSequence createSlotFK(Slot slot) {
		val ownerEntity = slot.ownerEntity
		val entity = slot.asEntity
		var String table
		var String constraintName
		var String key
		var String refTable
		var String refKey
		
		val builder = new StringConcatenation
		
		if (slot.isManyToMany || slot.isOneToMany) {
			// Gets owner side
			table = slot.relationIntermediateTableName
			key = slot.getSlotAsOwnerEntityIdFK
			constraintName = table + '_' + key
			refTable = ownerEntity.databaseName
			refKey = ownerEntity.entityIdAsKey
			builder.append(mountFK(table, constraintName, key, refTable, refKey))
			
			// Gets opposite side
			key = slot.getSlotAsEntityIdFK
			constraintName = table + '_' + key
			refTable = entity.databaseName
			refKey = entity.entityIdAsKey
			builder.append(mountFK(table, constraintName, key, refTable, refKey))
		}
		else {
			table = ownerEntity.databaseName
			key = slot.databaseName				
			constraintName = table + '_' + key 
			refTable = entity.databaseName
			refKey = entity.entityIdAsKey
			builder.append(mountFK(table, constraintName, key, refTable, refKey))
		}
		
		builder
	}
	
	
	
	def private String toSQLType(Slot slot) {
		if (slot.slotType instanceof BasicTypeReference) {
			val SqlBasicType = (slot.slotType as BasicTypeReference).toSQLBasicType
			return SqlBasicType
		}
		
		if (slot.slotType instanceof ObjectTypeReference) {
			val SqlObjectType = (slot.slotType as ObjectTypeReference).toSQLObjectType
			return SqlObjectType
		}
		
		"<UNKNOWN1>"
	}
	
	def String toSQLObjectType(ObjectTypeReference reference)
	
	def String toSQLBasicType(BasicTypeReference reference)
	
	def CharSequence createUKs() {
		'''
		'''
	}
	
	def CharSequence createIndexes() {
		'''
		
		/* INDEXES */
		«entities.filter[it.hasIndex].map[it.createEntityIndexes].join»
		'''
	}
	
	def CharSequence createEntityIndexes(Entity entity) {
		val slots = entity.slots.filter[it.hasIndex]
		'''
		«slots.map[it.buildSlotIndex].join»
		'''
	}
	
	def CharSequence buildSlotIndex(Slot slot) {
		val index = slot.index
		val indexName = index.name ?: slot.toSlotIndexName
		val tableName = slot.ownerEntity.databaseName
		val columnName = slot.databaseName
		val expression = index.expression
		val hasExpression = expression !== null && !expression.trim.isEmpty
		val isUnique = index.unique
		
		'''
		CREATE«IF isUnique» UNIQUE«ENDIF» INDEX «indexName» ON «tableName» «IF hasExpression»(«expression»)«ELSE»(«columnName»)«ENDIF»;
		'''
	}
	
	
	
	
	
	
	
}