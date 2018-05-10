package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.BasicTypeReference
import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.ManyToMany
import br.com.kerubin.dsl.mkl.model.ManyToOne
import br.com.kerubin.dsl.mkl.model.OneToMany
import br.com.kerubin.dsl.mkl.model.OneToOne
import br.com.kerubin.dsl.mkl.model.Relationship
import br.com.kerubin.dsl.mkl.model.RelationshipFeatured
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.model.UUIDType

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import org.eclipse.xtend2.lib.StringConcatenation

class JavaEntityJPAGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateEntities
	}
	
	def generateEntities() {
		entities.forEach[generateEntity]
	}
	
	def generateEntity(Entity entity) {
		val basePakage = serverGenSourceFolder
		val entityFile = basePakage + entity.packagePath + '/' + entity.toEntityName + '.java'
		generateFile(entityFile, entity.generateEntityJPA)
		entity.imports.clear
	}
	
	def CharSequence generateEntityJPA(Entity entity) {
		entity.initializeEntityImports
		
		val package = '''
		package «entity.package»;
		
		'''
		
		val body = '''
		
		@Entity
		@Table(name = "«entity.databaseName»")
		public class «entity.toEntityName» {
		
			«entity.generateFields»
			«entity.generateGetters»
			«entity.generateSetters»
			«entity.generateEquals»
			«entity.generateHashCode»
			«entity.generateToString»
		
		}
		'''
		
		val imports = '''
		«entity.imports.map[it].join('\r\n')»
		'''
		
		package + imports + body 
	}
	
	
	
	def CharSequence generateFields(Entity entity) {
		'''
		«entity.slots.map[generateField(entity)].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateField(Slot slot, Entity entity) {
		if (slot.isEntity) {
			entity.addImport('import ' + slot.asEntity.package + '.' + slot.asEntity.toEntityName + ';')
		}
		'''
		«IF slot.isOneToOne && slot.isRelationRefers»
		@Id /* OneTone will be PK and FK pointing to «slot.asEntity.toEntityName» */
		@Column(name="«slot.databaseName»")
		private «slot.asEntity.id.toJavaType» «slot.asEntity.id.name.toFirstLower»;
		
		«ENDIF»
		«slot.generateAnnotations(entity)»
		«IF slot.isOneToMany»
		private java.util.List<«slot.toJavaType»> «slot.name.toFirstLower»;
		«ELSEIF slot.isManyToMany»
		private java.util.Set<«slot.toJavaType»> «slot.name.toFirstLower»;
		«ELSE»
		private «slot.toJavaType» «slot.name.toFirstLower»;
		«ENDIF»
		'''
	}
	
	def CharSequence generateAnnotations(Slot slot, Entity entity) {
		val isOneToOne = slot.isOneToOne && slot.isRelationRefers
		
		'''
		«IF slot == entity.id»
		«IF slot.isUUID && !isOneToOne»
		«entity.addImport('import javax.persistence.GeneratedValue;')»
		«entity.addImport('import org.hibernate.annotations.GenericGenerator;')»
		@GeneratedValue(generator = "uuid2")
		@GenericGenerator(name = "uuid2", strategy = "uuid2")
		«ENDIF»
		«IF !isOneToOne»
		@Id
		«ENDIF»
		«ENDIF»
		«IF slot.hasRelationship»
		«slot.getRelationAnnotation(entity)»
		«IF false/*isOneToOne*/»
		@Column(name="«slot.databaseName»")
		«ENDIF»
		«ELSE»
		@Column(name="«slot.databaseName»")
		«ENDIF»
		'''
	}
	
	//OneToOne maps only in the child side using the same parent id: 
	//https://vladmihalcea.com/the-best-way-to-map-a-onetoone-relationship-with-jpa-and-hibernate/
	def CharSequence getRelationAnnotation(Slot slot, Entity entity) {
		if (slot.isOneToOne) {
			return slot.getOneToOneRelationAnnotation
		}
		else if (slot.isManyToOne) {
			return slot.getManyToOneRelationAnnotation
		}
		else if (slot.isOneToMany) {
			return slot.getOneToManyRelationAnnotation
		}
		else if (slot.isManyToMany) {
			return slot.getManyToManyRelationAnnotation
		}
		''''''
	}
	
	def CharSequence getOneToOneRelationAnnotation(Slot slot) {
		val entity = slot.ownerEntity
		entity.addImport('import javax.persistence.OneToOne;')
		entity.addImport('import javax.persistence.FetchType;')
		
		val builder = new StringConcatenation()
		builder.append('@OneToOne(')
		
		if (slot.isRelationContains && slot.isBidirectional) {
			builder.append('mappedBy = "')	
			builder.append(slot.relationOppositeSlot.name)
			builder.append('", ')
		}
		
		builder.append('fetch = FetchType.')
		builder.append(slot.relationship.getFetchType)
		
		val cascade = slot.relationship.cascadeType
		if (cascade !== null && !cascade.isEmpty) {
			entity.addImport('import javax.persistence.CascadeType;')
			builder.append(cascade)			
		}
		
		builder.append(')')
		
		if (slot.isRelationRefers) {
			entity.addImport('import javax.persistence.MapsId;')
			builder.newLine
			builder.append('@MapsId')
		}
		
		builder
	}
	
	def CharSequence getManyToOneRelationAnnotation(Slot slot) {
		val entity = slot.ownerEntity
		entity.addImport('import javax.persistence.ManyToOne;')
		entity.addImport('import javax.persistence.FetchType;')
		entity.addImport('import javax.persistence.JoinColumn;')
		
		'''
		@ManyToOne(fetch = FetchType.«slot.relationship.getFetchType»)
		@JoinColumn(name = "«slot.databaseName»")
		'''
	}
	
	def CharSequence getOneToManyRelationAnnotation(Slot slot) {
		val entity = slot.ownerEntity
		val isBidirectional = slot.isBidirectional
		
		entity.addImport('import javax.persistence.OneToMany;')
		entity.addImport('import javax.persistence.FetchType;')
		
		val builder = new StringConcatenation()
		
		builder.append('@OneToMany(')
		
		if (slot.isRelationContains && isBidirectional) {
			builder.append('mappedBy = "')	
			builder.append(slot.relationOppositeSlot.name)
			builder.append('", ')
		}
		
		builder.append('fetch = FetchType.')
		builder.append(slot.relationship.getFetchType)
		
		var cascade = slot.relationship.cascadeType
		if (cascade === null || cascade.isEmpty) {
			if (slot.isRelationContains && isBidirectional) {
				cascade = ', cascade = CascadeType.ALL, '
			}
			else if (slot.isRelationRefers && !isBidirectional) {
				cascade = ', cascade = {CascadeType.PERSIST, CascadeType.MERGE}'
			}
		}
		
		if (cascade !== null && !cascade.isEmpty) {
			entity.addImport('import javax.persistence.CascadeType;')
			builder.append(cascade)			
		}
		
		if (slot.isOrphanRemoval || (slot.isRelationContains && isBidirectional)) {
			builder.append(', orphanRemoval = true')
		}
		
		builder.append(')')
		
		//Intermediate table
		if (!isBidirectional) {
			entity.addImport('import javax.persistence.JoinColumn;')
			entity.addImport('import javax.persistence.JoinTable;')
			
			builder.newLine
			builder.append('@JoinTable(name = "')
			builder.append(slot.getRelationIntermediateTableName)
			builder.append('",')
			builder.newLine
			builder.append('\t')
			builder.append('joinColumns = @JoinColumn(name = "')
			builder.append(entity.getEntityIdAsKey)
			builder.append('"),')
			builder.newLine
			builder.append('\t')
			builder.append('inverseJoinColumns = @JoinColumn(name = "')
			builder.append(slot.getSlotAsEntityIdFK)
			builder.append('")')
			builder.newLine
			builder.append(')')
		}
		
		builder
	}
	
	def CharSequence getManyToManyRelationAnnotation(Slot slot) {
		val entity = slot.ownerEntity
		entity.addImport('import javax.persistence.ManyToMany;')
		
		val builder = new StringConcatenation
		
		if (!slot.isRelationOwner) {
			builder.append('@ManyToMany(mappedBy = "')	
			builder.append(slot.relationOppositeSlot.name)
			builder.append('")')
			
			return builder
		}
		
		entity.addImport('import javax.persistence.FetchType;')
		
		builder.append('@ManyToMany(')
		
		builder.append('fetch = FetchType.')
		builder.append(slot.relationship.getFetchType)
		
		var cascade = slot.relationship.cascadeType
		if ((cascade === null || cascade.isEmpty) && slot.isRelationOwner) {
			cascade = ', cascade = {CascadeType.PERSIST, CascadeType.MERGE}'
		}
		
		if (cascade !== null && !cascade.isEmpty) {
			entity.addImport('import javax.persistence.CascadeType;')
			builder.append(cascade)			
		}
		
		builder.append(')')
		
		entity.addImport('import javax.persistence.JoinColumn;')
		entity.addImport('import javax.persistence.JoinTable;')
		
		builder.newLine
		builder.append('@JoinTable(name = "')
		builder.append(slot.getRelationIntermediateTableName)
		builder.append('",')
		builder.newLine
		builder.append('\t')
		builder.append('joinColumns = @JoinColumn(name = "')
		builder.append(entity.getEntityIdAsKey)
		builder.append('"),')
		builder.newLine
		builder.append('\t')
		builder.append('inverseJoinColumns = @JoinColumn(name = "')
		builder.append(slot.getSlotAsEntityIdFK)
		builder.append('")')
		builder.newLine
		builder.append(')')
		
		builder
	}
	
	
	def CharSequence getRelationAnnotation2(Slot slot, Entity entity) {
		'''
		«IF slot.relationship instanceof OneToOne»
		«entity.addImport('import javax.persistence.OneToOne;')»
		«entity.addImport('import javax.persistence.FetchType;')»
		@OneToOne(fetch = FetchType.«slot.relationship.getFetchType»)
		«IF slot.isBidirectional»
		
		«ELSE»
		«entity.addImport('import javax.persistence.MapsId;')»
		@MapsId
		«ENDIF»
		«ELSEIF slot.relationship instanceof ManyToOne»
		«entity.addImport('import javax.persistence.ManyToOne;')»
		«entity.addImport('import javax.persistence.FetchType;')»
		«entity.addImport('import javax.persistence.JoinColumn;')»
		@ManyToOne(fetch = FetchType.«slot.relationship.getFetchType»)
		@JoinColumn(name = "«slot.asEntity.getEntityIdAsKey»")
		«ELSEIF slot.relationship instanceof OneToMany»
		«entity.addImport('import javax.persistence.OneToMany;')»
		«entity.addImport('import javax.persistence.FetchType;')»
		«entity.addImport('import javax.persistence.JoinColumn;')»
		@OneToMany(mappedBy = "«slot.asEntity.name.toLowerCase»"«slot.relationship.getCascadeType», orphanRemoval = true, fetch = FetchType.«slot.relationship.getFetchType»)
		@JoinColumn(name = "«slot.asEntity.getEntityIdAsKey»")
		«ELSEIF slot.relationship instanceof ManyToMany»
		«entity.addImport('import javax.persistence.ManyToMany;')»
		«IF (slot.isRelationOwner)»
		«entity.addImport('import javax.persistence.JoinColumn;')»
		«entity.addImport('import javax.persistence.JoinTable;')»
		«entity.addImport('import javax.persistence.CascadeType;')»
		@ManyToMany(cascade = {CascadeType.PERSIST, CascadeType.MERGE})
		    @JoinTable(name = "«slot.getRelationIntermediateTableName»",
		        joinColumns = @JoinColumn(name = "«entity.getEntityIdAsKey»"),
		        inverseJoinColumns = @JoinColumn(name = "«slot.getSlotAsEntityIdFK»")
		    )
		«ELSE»
		@ManyToMany(mappedBy = "«(slot.relationship as RelationshipFeatured).field.name»")
		«ENDIF»
		«ENDIF»
		'''
	}
	
	
	
	def String getFetchType(Relationship relationship) {
		(relationship as RelationshipFeatured).fetchType?.toString.toUpperCase ?: 'LAZY'
	}
	
	def String getCascadeType(Relationship relationShip) {
		val relationshipFeatured = (relationShip as RelationshipFeatured)
		if (relationshipFeatured !== null && relationshipFeatured.cascadeType !== null) {
			val result = relationshipFeatured?.cascadeType?.map[it | 'CascadeType.' + it.getName.toUpperCase].join(', ') ?: null
			if (result !== null && !result.trim.isEmpty) {
				return ', cascade = {' + result + '}'
			}
		}
		return ''
	}
	
	def CharSequence generateGetters(Entity entity) {
		'''
		
		«entity.slots.map[generateGetter].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateGetter(Slot slot) {
		'''
		«IF slot.isOneToMany»
		public java.util.List<«slot.toJavaType»> get«slot.name.toFirstUpper»() {
		«ELSEIF slot.isManyToMany»
		public java.util.Set<«slot.toJavaType»> get«slot.name.toFirstUpper»() {
		«ELSE»
		public «slot.toJavaType» get«slot.name.toFirstUpper»() {
		«ENDIF»
			return «slot.name.toFirstLower»;
		}
		'''
	}
	
	def CharSequence generateSetters(Entity entity) {
		'''
		
		«entity.slots.map[generateSetter].join('\r\n')»
		'''
	}
	
	def CharSequence generateSetter(Slot slot) {
		'''
		«IF slot.many && slot.isOneToMany»
		public void set«slot.name.toFirstUpper»(java.util.List<«slot.toJavaType»> «slot.name.toFirstLower») {
		«ELSEIF slot.many && slot.isManyToMany»
		public void set«slot.name.toFirstUpper»(java.util.Set<«slot.toJavaType»> «slot.name.toFirstLower») {
		«ELSE»
		public void set«slot.name.toFirstUpper»(«slot.toJavaType» «slot.name.toFirstLower») {
		«ENDIF»
			this.«slot.name.toFirstLower» = «slot.name.toFirstLower»;
		}
		«IF slot.isOneToMany || slot.isManyToMany»
		
		public void add«slot.relationFieldNameToAddRemoveMethod.toFirstUpper»(«slot.toJavaType» «slot.relationFieldNameToAddRemoveMethod») {
			this.«slot.name.toFirstLower».add(«slot.relationFieldNameToAddRemoveMethod»);
			«IF slot.isBidirectional»
			«IF slot.isOneToMany»
			«slot.relationFieldNameToAddRemoveMethod».set«slot.getRelationOppositeSlot.name.toFirstUpper»(this);
			«ELSEIF slot.isManyToMany»
			«slot.relationFieldNameToAddRemoveMethod».get«slot.getRelationOppositeSlot.name.toFirstUpper»().add(this);
			«ENDIF»
			«ENDIF»
		}
		
		public void remove«slot.relationFieldNameToAddRemoveMethod.toFirstUpper»(«slot.toJavaType» «slot.relationFieldNameToAddRemoveMethod») {
			this.«slot.name.toFirstLower».remove(«slot.relationFieldNameToAddRemoveMethod»);
			«IF slot.isBidirectional»
			«IF slot.isOneToMany»
			«slot.relationFieldNameToAddRemoveMethod».set«slot.getRelationOppositeSlot.name.toFirstUpper»(null);
			«ELSEIF slot.isManyToMany»
			«slot.relationFieldNameToAddRemoveMethod».get«slot.getRelationOppositeSlot.name.toFirstUpper»().remove(this);
			«ENDIF»
			«ENDIF»
		}
		«ENDIF»
		'''
	}
	
	def String relationFieldNameToAddRemoveMethod(Slot slot) {
		val name = slot.name.toFirstLower.trim
		if (name.endsWith('s')) {
			return name.substring(0, name.length - 1)
		}
		name
	}
	
	
	//From https://vladmihalcea.com/the-best-way-to-implement-equals-hashcode-and-tostring-with-jpa-and-hibernate/
	def CharSequence generateEquals(Entity entity) {
		val id = if (entity.id.isEntity) 'id' else entity.id.name
		'''
		
		@Override
		public boolean equals(Object obj) {
			if (this == obj)
				return true;
			if (obj == null)
				return false;
			if (getClass() != obj.getClass())
				return false;
			«entity.toEntityName» other = («entity.toEntityName») obj;
			if («id» == null) {
				if (other.«id» != null)
					return false;
			} else if (!«id».equals(other.«id»))
				return false;
			
			return true;
		}
		'''
		
	}
	
	//From: https://vladmihalcea.com/the-best-way-to-implement-equals-hashcode-and-tostring-with-jpa-and-hibernate/
	def CharSequence generateHashCode(Entity entity) {
		'''
		
		@Override
		public int hashCode() {
			return 31;
		}
		'''
		
	}
	
	def CharSequence generateToString(Entity entity) {
		'''
		
		/* 
		@Override
		public String toString() {
			// Enabling toString for JPA entities will implicitly trigger lazy loading on all fields.
		}
		*/
		'''
	}
	
	def void initializeEntityImports(Entity entity) {
		entity.addImport('import javax.persistence.Entity;')
		entity.addImport('import javax.persistence.Table;')
		entity.addImport('import javax.persistence.Id;')
		entity.addImport('import javax.persistence.Column;')
	}
	
	def CharSequence getSlotsEntityImports(Entity entity) {
		'''
		«entity.slots.filter[it.isEntity].map[it | 
			val slotEntity = it.asEntity
			return "import " + slotEntity.package + "." + slotEntity.toEntityName + ";"
			].join('\r\n')»
		'''
	}
	
	def boolean hasRelationship(Slot slot) {
		if (slot.isEntity) {
			return slot.relationship !== null
		}
		false
	}
	
	def boolean existsRelationOneToOne(Entity entity) {
		val exists = entity.slots.exists[it.relationship instanceof OneToOne]
		exists
	}
	
	def boolean existsRelationManyToOne(Entity entity) {
		val exists = entity.slots.exists[it.relationship instanceof ManyToOne]
		exists
	}
	
	def boolean existsRelationOneToMany(Entity entity) {
		val exists = entity.slots.exists[it.relationship instanceof OneToMany]
		exists
	}
	
	def boolean existsRelationManyToMany(Entity entity) {
		val exists = entity.slots.exists[it.relationship instanceof ManyToMany]
		exists
	}
	
	def boolean existsRelation(Entity entity) {
		entity.slots.exists[it.isEntity]
	}
	
	def boolean isUUID(Slot slot) {
		if (slot.slotType instanceof BasicTypeReference) {
			val basicType = (slot.slotType as BasicTypeReference).basicType
			return basicType instanceof UUIDType
		}
		
		false
	}
	
}