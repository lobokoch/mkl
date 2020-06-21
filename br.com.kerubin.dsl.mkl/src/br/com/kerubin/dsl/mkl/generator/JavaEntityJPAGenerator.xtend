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
import br.com.kerubin.dsl.mkl.model.EnumType
import br.com.kerubin.dsl.mkl.model.HibFilterDef
import br.com.kerubin.dsl.mkl.model.HibParamDef
import br.com.kerubin.dsl.mkl.model.HibFilters
import br.com.kerubin.dsl.mkl.model.HibFilter
import java.util.List
import java.util.Collections

class JavaEntityJPAGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateEntities
	}
	
	def generateEntities() {
		entities.filter[it.canGenerateEntityJPA].forEach[generateEntity]
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
		«IF entity.hasHibFilterDef»
		«entity.hibFilterDefList.map[it.generateHibFilterDef].join»
		«ENDIF»
		«IF entity.hasHibFilters»
		«entity.hibFiltersList.map[it.generateHibFilters].join»
		«ENDIF»
		public class «entity.toEntityName» «IF entity.isAuditing»extends AuditingEntity«ENDIF» {
		
			«entity.generateFields»
			«entity.generateGetters»
			«entity.generateSetters»
			«entity.generateAssignMethod»
			«entity.generateCloneMethod»
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
	
	def CharSequence generateHibFilters(HibFilters filters) {
		'''
		
		@Filters( {
		    «filters.filterList.map[it.generateHibFilter].join(',\r\n')»
		} )
		
		'''
	}
	
	def CharSequence generateHibFilter(HibFilter filter) {
		'''@Filter(name = "«filter.name»", condition = "«filter.condition»")'''
	}
	
	def CharSequence generateHibFilterDef(HibFilterDef filterDef) {
		'''
		
		@FilterDef(name = "«filterDef.name»", parameters = {
			«filterDef.parameters.map[it.generateHibParamDef].join(',\r\n')»
		})
		
		'''
	}
	
	def CharSequence generateHibParamDef(HibParamDef paramDef) {
		'''@ParamDef(name = "«paramDef.name»", type = "«paramDef.type»")'''
	}
	
	def CharSequence generateFields(Entity entity) {
		'''
		«entity.slots.filter[!mapped].map[generateField(entity)].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateField(Slot slot, Entity entity) {
		var List<String> validationAnnotations = Collections.emptyList
		if (!slot.isTransient) { // No apply bean validations on @Entity, only in DTO for validate inputs.
			slot.resolveBeanValidationImports
			validationAnnotations = slot.resolveBeanValidationAnnotations
		}
		
		val isOneToManyWithMapsId = slot.isOneToOne && slot.isRelationRefers
		if (slot.isEntity) {
			entity.addImport('import ' + slot.asEntity.package + '.' + slot.asEntity.toEntityName + ';')
		}
		else if (slot.isEnum) { 
			entity.addImport('import javax.persistence.EnumType;')
			entity.addImport('import javax.persistence.Enumerated;')
			entity.addImport('import ' + slot.asEnum.enumPackage + ';')
		}
		
		
		'''
		«IF !validationAnnotations.isEmpty»
		«validationAnnotations.map[it.toString].join('\r')»
		«ENDIF»
		«IF isOneToManyWithMapsId»
		@Id /* OneTone will be PK and FK pointing to «slot.asEntity.toEntityName» */
		@Column(name="«slot.databaseName»")
		private «slot.asEntity.id.toJavaType» «slot.asEntity.id.name.toFirstLower»;
		
		«ENDIF»
		«slot.generateAnnotations(entity)»
		«IF slot.isOneToMany»
		«entity.addImport('import java.util.Set;')»
		«entity.addImport('import java.util.HashSet;')»
		private Set<«slot.toJavaType»> «slot.name.toFirstLower» = new HashSet<>();
		«ELSEIF slot.isManyToMany»
		«entity.addImport('import java.util.Set;')»
		«IF slot.isRelationContains»
		«entity.addImport('import java.util.LinkedHashSet;')»
		private Set<«slot.toJavaType»> «slot.name.toFirstLower» = new LinkedHashSet<>();
		«ELSE»
		«entity.addImport('import java.util.HashSet;')»
		private Set<«slot.toJavaType»> «slot.name.toFirstLower» = new HashSet<>();
		«ENDIF»
		«ELSE»
		private «slot.toJavaType» «slot.name.toFirstLower»«IF slot.hasDefaultValue» = «slot.defaultValue»«ENDIF»;
		«ENDIF»
		'''
	}
	
	def CharSequence generateAnnotations(Slot slot, Entity entity) {
		val isOneToOne = slot.isOneToOne && slot.isRelationRefers
		
		'''
		«slot.annotations.join('\r\n')»
		«IF slot.isTransient»
		@Transient
		«ELSE»
		«IF slot == entity.id»
		«IF slot.isUUID && !isOneToOne && !entity.isExternalEntity»
		«entity.addImport('import javax.persistence.GeneratedValue;')»
		«entity.addImport('import org.hibernate.annotations.GenericGenerator;')»
		@GeneratedValue(generator = "uuid2")
		@GenericGenerator(name = "uuid2", strategy = "uuid2")
		«ENDIF»
		«IF !isOneToOne»
		@Id
		«ENDIF»
		«ENDIF»
		«IF slot.isEnum»
		«IF EnumType.ORDINAL.equals(slot.enumType)»@Enumerated(EnumType.ORDINAL)«ELSE»@Enumerated(EnumType.STRING)«ENDIF»
		«ENDIF»
		«IF slot.hasRelationship»
		«slot.getRelationAnnotation(entity)»
		«ELSE»
		@Column(name="«slot.databaseName»")
		«ENDIF»
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
		
		
		var cascade = slot.relationship.cascadeType
		if (cascade === null || cascade.isEmpty) {
				cascade = ', cascade = CascadeType.ALL '
		}
		
		if (cascade !== null && !cascade.isEmpty) {
			entity.addImport('import javax.persistence.CascadeType;')
			builder.append(cascade)			
		}
		
		builder.append(')')
		
		if (slot.isRelationRefers) {
			//https://vard-lokkur.blogspot.com.br/2014/05/onetoone-with-shared-primary-key.html
			entity.addImport('import javax.persistence.MapsId;')
			entity.addImport('import javax.persistence.JoinColumn;')
			builder.newLine
			builder.append('@JoinColumn(name = "')
			builder.append(slot.databaseName)
			builder.append('")')
			
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
				cascade = ', cascade = CascadeType.ALL '
			}
			else if (slot.isRelationRefers && !isBidirectional) {
				// not necessary for OneToMany: https://docs.jboss.org/hibernate/orm/3.6/reference/en-US/html_single/#example-one-to-many-with-join-table
				// cascade = ', cascade = {CascadeType.PERSIST, CascadeType.MERGE}' aparenteli not necessary
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
			builder.append(entity.getEntityAsEntityIdFK)
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
			//cascade = ', cascade = {CascadeType.PERSIST, CascadeType.MERGE}' // O CascadeType.PERSIST causa erro: org.hibernate.PersistentObjectException: detached entity passed to persist
			cascade = ', cascade = {CascadeType.MERGE}'
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
		builder.append(entity.id.getSlotAsOwnerEntityIdFK)
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
		
		«entity.slots.filter[!mapped].map[generateGetter].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateGetter(Slot slot) {
		// toMany não bi-direcional use set.
		'''
		«IF slot.isToMany»
		public java.util.Set<«slot.toJavaType»> get«slot.name.toFirstUpper»() {
		«ELSE»
		public «slot.toJavaType» get«slot.name.toFirstUpper»() {
		«ENDIF»
			return «slot.name.toFirstLower»;
		}
		«IF slot.isBoolean»
		
		public boolean is«slot.name.toFirstUpper»() {
			return Boolean.TRUE.equals(«slot.fieldName»);
		}
		«ENDIF»
		'''
	}
	
	def CharSequence generateCloneMethod(Entity entity) {
		'''
		
		public «entity.toEntityName» clone() {
			return clone(new java.util.HashMap<>());
		}
		
		public «entity.toEntityName» clone(java.util.Map<Object, Object> visited) {
			if (visited.containsKey(this)) {
				return («entity.toEntityName») visited.get(this);
			}
					
			«entity.toEntityName» theClone = new «entity.toEntityName»();
			visited.put(this, theClone);
			
			«entity.slots.map[generateCloneSlot].join»
			
			return theClone;
		}
		'''
	}
	
	def CharSequence generateCloneSlot(Slot slot) {
		'''
		«slot.buildMethodSet('theClone', slot.buildMethodGetWithClone('this'))»;
		'''
	}
	
	def CharSequence generateAssignMethod(Entity entity) {
		'''
		
		public void assign(«entity.toEntityName» source) {
			if (source != null) {
				«entity.slots.map[generateAssignSlot].join»
			}
		}
		'''
	}
	
	def CharSequence generateAssignSlot(Slot slot) {
		'''
		«slot.buildMethodSet('this', slot.buildMethodGet('source'))»;
		'''
	}
	
	def CharSequence generateSetters(Entity entity) {
		'''
		
		«entity.slots.filter[!mapped].map[generateSetter].join('\r\n')»
		'''
	}
	
	def CharSequence generateSetter(Slot slot) {
		val slotName = slot.name.toFirstLower
		
		'''
		«IF slot.isToMany»
		public void set«slot.name.toFirstUpper»(java.util.Set<«slot.toJavaType»> «slotName») {
		«ELSEIF ! slot.isManyToMany»
		public void set«slot.name.toFirstUpper»(«slot.toJavaType» «slotName») {
		«ENDIF»
			«IF slot.many && slot.isToMany /*&& slot.isRelationContains*/»
			// First remove existing items.
			if (this.«slotName» != null) {
				this.«slotName».clear();
			}
			
			if («slotName» != null) {
				«slotName».forEach(this::add«slot.relationFieldNameToAddRemoveMethod.toFirstUpper»);
			}
			«ELSEIF slot.isOneToOne && slot.relationContains && slot.isBidirectional»
			if («slotName» == null) {
				if (this.«slotName» != null) {
			    	this.«slotName».set«slot.getRelationOppositeSlot.name.toFirstUpper»(null);
			    }
			}
			else {
				«slotName».set«slot.getRelationOppositeSlot.name.toFirstUpper»(this);
			}
			«ENDIF»
			«IF !slot.isToMany»
			«IF slot.isString»
			this.«slotName» = «slotName» != null ? «slotName».trim() : «slotName»; // Chamadas REST fazem trim.
			«ELSE»
			this.«slotName» = «slotName»;
			«ENDIF»
			«ENDIF»
		«IF !(slot.isManyToMany && slot.isRelationRefers)»
		}
		«ENDIF»
		«IF slot.isOneToMany || (slot.isManyToMany && slot.isRelationContains)»
		
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
		// Não lembro mais pra que usa isso: val id = if (entity.id.isEntity) 'id' else entity.id.name
		val slots = entity.slots
		
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
				
			«slots.map[buildSlotEquals].join»
			
			return true;
		}
		'''
		
	}
	
	def CharSequence buildSlotEquals(Slot slot) {
		val name = slot.fieldName
		val isEntity = slot.isEntity
		val isMany = isEntity && (slot.isOneToMany || slot.isManyToMany)
		val getId = if (isEntity) slot.asEntity.buildIdGetMethod else null
		
		'''
		
		// Field: «name»
		«IF slot.isSmallint»
		if («name» != other.«name»)
			return false;
		«ELSE»
		if («name» == null) {
			if (other.«name» != null) {
				return false;
			}
		«IF isEntity»
		«IF isMany»
		} else if («name».size() != other.«name».size()) {
			return false;
		} else if (!«name».stream().allMatch(it1 -> other.«name».stream().anyMatch(it2 -> it1.«getId».equals(it2.«getId»)))) {
			return false;
		}
		«ELSE»
		} else if («name».«getId» == null) {
			if (other.«name».«getId» != null)
				return false;
		} else if (!«name».«getId».equals(other.«name».«getId»)) 
			return false;
		«ENDIF»
		«ELSE»
		} else if (!«name».equals(other.«name»))
			return false;
		«ENDIF»
		«ENDIF»
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
		if (entity.isAuditing) {
			entity.addImport('import br.com.kerubin.api.database.entity.AuditingEntity;')
		}
		
		// Hibernate filters
		if (entity.hasHibFilterDef) {
			entity.addImport('import org.hibernate.annotations.FilterDef;')
			entity.addImport('import org.hibernate.annotations.ParamDef;')
		}
		
		if (entity.hasHibFilters) {
			entity.addImport('import org.hibernate.annotations.Filters;')
			entity.addImport('import org.hibernate.annotations.Filter;')
		}
		
		if (entity.hasTransient) {
			entity.addImport('import javax.persistence.Transient;')
		}
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