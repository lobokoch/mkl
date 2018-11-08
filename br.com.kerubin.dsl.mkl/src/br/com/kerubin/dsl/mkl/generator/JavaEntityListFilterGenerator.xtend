package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.FilterOperatorEnum
import br.com.kerubin.dsl.mkl.model.ManyToMany
import br.com.kerubin.dsl.mkl.model.ManyToOne
import br.com.kerubin.dsl.mkl.model.OneToMany
import br.com.kerubin.dsl.mkl.model.OneToOne
import br.com.kerubin.dsl.mkl.model.Slot

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class JavaEntityListFilterGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	private val final BETWEEN_START = 'Start'
	private val final BETWEEN_END = 'End'
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateListFilter]
	}
	
	def generateListFilter(Entity entity) {
		if (entity.hasListFilter) {
			val basePakage = clientGenSourceFolder
			val entityFile = basePakage + entity.packagePath + '/' + entity.toEntityListFilterName + '.java'
			generateFile(entityFile, entity.generateEntityListFilter)
		}
	}
	
	def CharSequence generateEntityListFilter(Entity entity) {
		entity.initializeEntityImports
		val slots = entity.slots.filter[it.hasListFilter]
		
		val package = '''
		package «entity.package»;
		
		'''
		
		val body = '''
		
		public class «entity.toEntityListFilterName» {
		
			«slots.generateFields»
		
		}
		'''
		
		val imports = '''
		«entity.imports.map[it].join('\r\n')»
		'''
		
		package + imports + body 
	}
	
	
	def CharSequence generateFields(Iterable<Slot> slots) {
		'''
		«slots.map[generateField].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateField(Slot slot) {
		val entity = slot.ownerEntity
		/*if (slot.isUUID) {
			entity.addImport("import java.util.UUID;")
		}*/
		
		if (slot.isDate) {
			//entity.addImport("import java.time.LocalDate;")
			entity.addImport("import org.springframework.format.annotation.DateTimeFormat;")
		}
		
		val isNotNull = slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.IS_NOT_NULL) ||
			slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.IS_NOT_NULL_IS_NULL)
			
		val isNull = slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.IS_NULL) ||
			slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.IS_NOT_NULL_IS_NULL)
			
		val isMany = slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.MANY)
		
		val isBetween = slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.BETWEEN) 
		
		'''
		«IF isMany»
		«IF slot.isDate»
		@DateTimeFormat(pattern = "yyyy-MM-dd")
		«ENDIF»
		private java.util.List<«slot.toJavaType»> «slot.name.toFirstLower»;
		«ELSEIF isNotNull && isNull»
		private Boolean «slot.name.toFirstLower»«FilterOperatorEnum.IS_NOT_NULL.getName.toFirstUpper»;
		
		private Boolean «slot.name.toFirstLower»«FilterOperatorEnum.IS_NULL.getName.toFirstUpper»;
		«ELSEIF isNotNull»
		private Boolean «slot.name.toFirstLower»«FilterOperatorEnum.IS_NOT_NULL.getName.toFirstUpper»;
		«ELSEIF isNull»
		private Boolean «slot.name.toFirstLower»«FilterOperatorEnum.IS_NULL.getName.toFirstUpper»;
		«ELSEIF isBetween»
		«IF slot.isDate»
		@DateTimeFormat(pattern = "yyyy-MM-dd")
		«ENDIF»
		private «slot.toJavaType» «slot.name.toFirstLower»«BETWEEN_START»;
		
		«IF slot.isDate»
		@DateTimeFormat(pattern = "yyyy-MM-dd")
		«ENDIF»
		private «slot.toJavaType» «slot.name.toFirstLower»«BETWEEN_END»;
		«ENDIF»
		'''
	}
	
	def CharSequence generateGetters(Iterable<Slot> slots) {
		'''
		
		«slots.map[generateGetter].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateGetter(Slot slot) {
		
		'''
		«IF slot.isToMany»
		public java.util.List<«slot.toJavaTypeDTO»> get«slot.name.toFirstUpper»() {
		«ELSE»
		public «slot.toJavaTypeDTO» get«slot.name.toFirstUpper»() {
		«ENDIF»
			return «slot.name.toFirstLower»;
		}
		'''
	}
	
	def CharSequence generateSetters(Iterable<Slot> slots) {
		'''
		
		«slots.map[generateSetter].join('\r\n')»
		'''
	}
	
	def CharSequence generateSetter(Slot slot) {
		
		'''
		«IF slot.many && slot.isToMany»
		public void set«slot.name.toFirstUpper»(java.util.List<«slot.toJavaTypeDTO»> «slot.name.toFirstLower») {
		«ELSE»
		public void set«slot.name.toFirstUpper»(«slot.toJavaTypeDTO» «slot.name.toFirstLower») {
		«ENDIF»
			this.«slot.name.toFirstLower» = «slot.name.toFirstLower»;
		}
		'''
	}
	
	//From https://vladmihalcea.com/the-best-way-to-implement-equals-hashcode-and-tostring-with-jpa-and-hibernate/
	def CharSequence generateEquals(Entity entity) {
		val isOneToManyWithMapsId = entity.id.isOneToOne && entity.id.isRelationRefers
		val id = if (!isOneToManyWithMapsId && entity.id.isEntity) entity.id.asEntity.name + '.get' + entity.id.asEntity.id.name.toFirstUpper + '()' else entity.id.name
		
		'''
		
		@Override
		public boolean equals(Object obj) {
			if (this == obj)
				return true;
			if (obj == null)
				return false;
			if (getClass() != obj.getClass())
				return false;
			«entity.toEntityLookupResultDTOName» other = («entity.toEntityLookupResultDTOName») obj;
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
		entity.imports.clear
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
	
	/*def boolean isUUID(Slot slot) {
		if (slot.slotType instanceof BasicTypeReference) {
			val basicType = (slot.slotType as BasicTypeReference).basicType
			return basicType instanceof UUIDType
		}
		
		false
	}*/
	
}