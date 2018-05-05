package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*;
import br.com.kerubin.dsl.mkl.model.BasicTypeReference
import br.com.kerubin.dsl.mkl.model.ObjectTypeReference
import org.eclipse.xtend2.lib.StringConcatenation

abstract class JavaSQLGenerator  extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	protected def String getDatabaseName(); 
	
	override generate() {
		generateSQLForEntities
	}
	
	def generateSQLForEntities() {
		// Based on: https://flywaydb.org/documentation/migrations
		val sqlFileName =  'Entity_Resources/db/migration/V1__Creation_Tables_' + databaseName + '.sql'
		generateFile(sqlFileName, generateSQL)
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
		DROP TABLE IF EXISTS «entity.name.databaseName»;
		'''
	}
	
	def CharSequence createTables() {
		'''
		«entities.map[createTable].join('\r\n')»
		'''
	}
	
	def CharSequence createTable(Entity entity) {
		val builder = new StringConcatenation
		
		builder.append('CREATE TABLE ')
		builder.append(entity.name.databaseName)
		builder.append(' /* ')
		builder.append(entity.name)
		builder.append(' */ (')
		builder.newLine
		
		//Table fields
		var slots = entity.slots.filter[!it.isEntity || it.isOneToOne || it.isManyToOne]
		builder.append(slots.map[generateDatabaseField].join(',\n'))
		
		builder.newLine
		builder.append(');')
		builder.newLine
		
		slots = entity.slots.filter[ (it.isManyToMany && it.isRelationOwner) || (it.isOneToMany && !it.isBidirectional) ]
		slots.forEach[builder.append(it.createIntermediateTable)]			
		
		builder
		
		/*'''
		CREATE TABLE «entity.name.databaseName»  «entity.name»  (
			«entity.slots.map[generateDatabaseField].join(',\n')»
		);
		'''*/
	}
	
	def CharSequence createIntermediateTable(Slot slot) {
		val builder = new StringConcatenation
		
		builder.newLine
		builder.append('CREATE TABLE ')
		builder.append(slot.getRelationIntermediateTableName)
		builder.append(' /* ')
		builder.append(slot.ownerEntity.name + ' + ' + slot.name)
		builder.append(' */ (')
		builder.newLine
		
		//Table fields
		val slots = #[slot.ownerEntity.id, slot.asEntity.id]
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
		if (slot.isEntity) {
			builder.append(slot.slotIdAsFKFieldName)
		}
		else {
			if (isMany) {
				builder.append(slot.ownerEntity.entityIdAsFKFieldName)
			}
			else {
				builder.append(slot.name.databaseName)				
			}
		}
		
		builder.append(' ')
		builder.append(slot.toSQLType)
		
		if (!slot.optional) {
			builder.append(' NOT NULL')
		}
		
		builder.append(' /* ')
		builder.append(slot.name)
		builder.append(' */')
		
		builder
		
		//'''«IF slot.isEntity»«IF slot.isOneToOne»«slot.asEntity.entityIdAsFKFieldName»«ELSE»«slot.slotIdAsFKFieldName»«ENDIF»«ELSE»«slot.name.databaseName»«ENDIF» «slot.toSQLType»«IF !slot.optional» NOT NULL«ENDIF» /* «slot.name» */'''
	}
	
	def CharSequence createPKs() {
		'''
		
		/* PRIMARY KEYS */
		«entities.map[createPK].join»
		'''
	}
	
	def CharSequence mountPK(String tableName, String constraintName, String keyName) {
		'''
		ALTER TABLE «tableName» ADD CONSTRAINT PK_«constraintName» PRIMARY KEY («keyName»);
		'''
		/*val builder = new StringConcatenation
		builder.append('ALTER TABLE ')
		builder.append(tableName)
		builder.append(' ADD CONSTRAINT PK_')
		builder.append(constraintName)
		builder.append(' PRIMARY KEY (')
		builder.append(keyName)
		builder.append(');')
		builder*/
	}
	
	def CharSequence createPK(Entity entity) {
		val tableName = entity.name.databaseName
		var keyName = entity.id.name.databaseName
		if (entity.id.isEntity) {
			/*if (entity.id.isOneToOne) {
				keyName = entity.id.asEntity.entityIdAsFKFieldName
			}
			else {*/
				keyName = entity.id.slotIdAsFKFieldName
			//}
		}
		
		val constraintName = tableName + '_' + keyName
		
		val builder = new StringConcatenation
		builder.append(mountPK(tableName, constraintName, keyName))
		
		// mount intermediaty tables PKs
		val slots = entity.slots.filter[ (it.isManyToMany && it.isRelationOwner) || (it.isOneToMany && !it.isBidirectional) ]
		slots.forEach[slot|
			val tableName_ = slot.getRelationIntermediateTableName
			val constraintName_ = tableName_
			val keyName_ = slot.ownerEntity.entityIdAsFKFieldName + ', ' + slot.asEntity.entityIdAsFKFieldName
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
		ALTER TABLE «table» ADD CONSTRAINT FK_«constraintName» FOREIGN KEY («key») REFERENCES «refTable» («refKey»);
		'''
	}
	
	def CharSequence createFK(Entity entity) {
		entity.slots.filter[it.isEntity].map[createSlotByFK].join
	}
	
	def CharSequence createSlotByFK(Slot slot) {
		val ownerEntity = slot.ownerEntity
		val entity = slot.asEntity
		var String table
		var String constraintName
		var String key
		var String refTable
		var String refKey
		if (slot.isManyToMany || slot.isOneToMany) {
			table = slot.relationIntermediateTableName
			constraintName = table
			key = entity.getEntityIdAsFKFieldName
			refTable = ownerEntity.name.databaseName
			refKey = ownerEntity.id.name.databaseName
		} 
		else {
			table = ownerEntity.name.databaseName
			constraintName = slot.relationIntermediateTableName
			key = slot.getSlotIdAsFKFieldName
			refTable = entity.name.databaseName
			refKey = entity.id.name.databaseName
		}
		
		mountFK(table, constraintName, key, refTable, refKey)
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
		'''
	}
	
}